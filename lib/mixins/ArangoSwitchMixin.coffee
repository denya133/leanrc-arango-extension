# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# здесь должна быть реализация интерфейса SwitchInterface работающая с Foxx роутером.

_             = require 'lodash'
inflect       = do require 'i'
methods       = require 'methods'
FoxxRouter    = require '@arangodb/foxx/router'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'
statuses      = require 'statuses'
{ errors }    = require '@arangodb'
EventEmitter  = require 'events'

ARANGO_NOT_FOUND  = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code
ARANGO_DUPLICATE  = errors.ERROR_ARANGO_UNIQUE_CONSTRAINT_VIOLATED.code
ARANGO_CONFLICT   = errors.ERROR_ARANGO_CONFLICT.code
HTTP_NOT_FOUND    = statuses 'not found'
HTTP_CONFLICT     = statuses 'conflict'


# здесь (наверху) надо привести пример использования в приложении
###
```coffee
module.exports = (Module)->
  class HttpSwitch extends Module::Switch
    @inheritProtected()
    @include Module::ArangoSwitchMixin

    @module Module

    @public routerName: String,
      default: 'ApplicationRouter'
    @public jsonRendererName: String,
      default: 'JsonRenderer'  # or 'ApplicationRenderer'
  HttpSwitch.initialize()
```
###


module.exports = (Module)->
  {
    ANY
    NILL
    LAMBDA

    ArangoContext
    LogMessage
    Utils
  } = Module::
  { co, genRandomAlphaNumbers } = Utils
  {  ERROR, DEBUG, LEVELS, SEND_TO_LOG } = LogMessage

  Module.defineMixin Module::Switch, (BaseClass) ->
    class ArangoSwitchMixin extends BaseClass
      @inheritProtected()
      iphEventNames = @private 'eventNames': Object

      ################
      @public @static createMethod: Function,
        default: (method)->
          originMethodName = method
          if method
            method = method.toUpperCase()
          else
            originMethodName = 'all'

          @public "#{originMethodName}": Function,
            args: [String, LAMBDA]
            return: Array
            default: (path, routeFunc)->
              voRouter = FoxxRouter()
              unless routeFunc
                throw new Error 'handler is required'

              @facade.sendNotification SEND_TO_LOG, "
                #{method ? 'ALL'} #{path} has been defined
              ", LEVELS[DEBUG]

              voEndpoint = voRouter[originMethodName]? path, co.wrap (req, res)=>
                res.statusCode = 404
                voContext = ArangoContext.new req, res, @
                voContext.routePath = path
                @facade.sendNotification SEND_TO_LOG, "#{voContext.method} #{path} matches #{voContext.path} #{req.pathParams}", LEVELS[DEBUG]
                voContext.pathParams = req.pathParams
                try
                  yield routeFunc.call @, voContext
                  @respond voContext
                catch err
                  voContext.onerror err
                  return
                yield return
              return [voRouter, voEndpoint]
          return

      methods.forEach (method)=>
        @createMethod method

      @public del: Function,
        default: (args...)->
          @delete args...

      @createMethod() # create @public all:...
      ##########################################################################

      @public onRegister: Function,
        default: -> # super не вызываем
          voEmitter = new EventEmitter()
          unless _.isFunction voEmitter.eventNames
            eventNames = @[iphEventNames] = {}
            FILTER = [ 'newListener', 'removeListener' ]
            voEmitter.on 'newListener', (event, listener) ->
              unless event in FILTER
                eventNames[event] ?= 0
                ++eventNames[event]
              return
            voEmitter.on 'removeListener', (event, listener) ->
              unless event in FILTER
                if eventNames[event] > 0
                  --eventNames[event]
              return
          if voEmitter.listeners('error').length is 0
            voEmitter.on 'error', @onerror.bind @
          @setViewComponent voEmitter
          @defineRoutes()
          return

      @public onRemove: Function,
        default: -> # super не вызываем
          voEmitter = @getViewComponent()
          eventNames = voEmitter.eventNames?() ? Object.keys @[iphEventNames] ? {}
          eventNames.forEach (eventName)->
            voEmitter.removeAllListeners eventName
          return

      @public getLocks: Function,
        args: []
        return: Object
        default: ->
          vrCollectionPrefix = new RegExp "^#{inflect.underscore @Module.name}_"
          vlCollectionNames = db._collections().reduce (alResults, aoCollection) ->
            if vrCollectionPrefix.test name = aoCollection.name()
              alResults.push name
            alResults
          , []
          return read: vlCollectionNames, write: vlCollectionNames

      @public respond: Function,
        default: (ctx)->
          return if ctx.respond is no
          return unless ctx.writable
          body = ctx.body
          code = ctx.status
          if statuses.empty[code]
            ctx.body = null
            return ctx.res.send()
          if 'HEAD' is ctx.method
            return ctx.res.send()
          unless body?
            body = ctx.message ? String code
            return ctx.res.send body
          if _.isBuffer(body) or _.isString body
            return ctx.res.send body
          body = JSON.stringify body
          ctx.res.send body
          return

      @public defineSwaggerEndpoint: Function,
        args: [Object, String, String]
        return: NILL
        default: (aoSwaggerEndpoint, resource, action)->
          gatewayName = inflect.camelize inflect.underscore "#{resource.replace /[/]/g, '_'}Gateway"
          voGateway = @facade.retrieveProxy gatewayName
          {
            tags
            headers
            pathParams
            queryParams
            payload
            responses
            errors
            title
            synopsis
            isDeprecated
          } = voGateway.swaggerDefinitionFor action
          tags?.forEach (tag)->
            aoSwaggerEndpoint.tag tag
          headers?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.header name, schema, description
          pathParams?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.pathParam name, schema, description
          queryParams?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.queryParam name, schema, description
          if payload?
            aoSwaggerEndpoint.body payload.schema, payload.mimes, payload.description
          responses?.forEach ({status, schema, mimes, description})->
            aoSwaggerEndpoint.response status, schema, mimes, description
          errors?.forEach ({status, description})->
            aoSwaggerEndpoint.error status, description
          aoSwaggerEndpoint.summary title            if title?
          aoSwaggerEndpoint.description synopsis     if synopsis?
          aoSwaggerEndpoint.deprecated isDeprecated  if isDeprecated?
          return

      @public sender: Function,
        default: (resourceName, aoMessage, {method, path, resource, action})->
          {context} = aoMessage
          try
            if method.toLowerCase() is 'get'
              @sendNotification resourceName, aoMessage, action
            else
              {read, write} = @getLocks()
              self = @
              db._executeTransaction
                waitForSync: yes
                collections:
                  read: read
                  write: write
                  allowImplicit: yes
                action: (params)->
                  params.self.sendNotification params.resourceName, params.message, params.action
                params: {resourceName, action, message: aoMessage, self}
            queues._updateQueueDelay()
          catch err
            console.log '???????????????????!!', JSON.stringify err
            if err.isArangoError and err.errorNum is ARANGO_NOT_FOUND
              context.throw HTTP_NOT_FOUND, err.message
              return
            if err.isArangoError and err.errorNum is ARANGO_CONFLICT
              context.throw HTTP_CONFLICT, err.message
              return
            else if err.statusCode?
              console.error 'kkkkkkkk1111', err.message, err.stack
              context.throw err.statusCode, err.message
            else
              console.error 'kkkkkkkk2222', err.message, err.stack
              context.throw 500, err.message, err.stack
              return
          return

      @public createNativeRoute: Function,
        default: (opts)->
          {method, path} = opts
          resourceName = inflect.camelize inflect.underscore "#{opts.resource.replace /[/]/g, '_'}Resource"

          [voRouter, voEndpoint] = @[method]? path, co.wrap (context, next)=>
            yield Module::Promise.new (resolve, reject)=>
              try
                reverse = genRandomAlphaNumbers 32
                @getViewComponent().once reverse, co.wrap ({result, resource})=>
                  try
                    yield @sendHttpResponse context, result, resource, opts
                    yield return resolve()
                  catch error
                    reject error
                @sender resourceName, {context, reverse}, opts
              catch err
                reject err
              return
            yield return next?()
          @defineSwaggerEndpoint voEndpoint, opts.resource, opts.action
          console.log '>>> IN ArangoSwitchMixin::createNativeRoute', @Module.name, @Module.context()?
          @Module.context().use voRouter
          return

    ArangoSwitchMixin.initializeMixin()
