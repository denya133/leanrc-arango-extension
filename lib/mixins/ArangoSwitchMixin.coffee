# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# здесь должна быть реализация интерфейса SwitchInterface работающая с Foxx роутером.

_             = require 'lodash'
inflect       = do require 'i'
methods       = require 'methods'
FoxxRouter    = require '@arangodb/foxx/router'
{ db }        = require '@arangodb'
statuses      = require 'statuses'
{ errors }    = require '@arangodb'
EventEmitter  = require 'events'
pathToRegexp  = require 'path-to-regexp'

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
    SyntheticRequest
    SyntheticResponse
    LogMessage: {  ERROR, DEBUG, LEVELS, SEND_TO_LOG }
    Utils: {
      co
      genRandomAlphaNumbers
    }
  } = Module::

  Module.defineMixin Module::Switch, (BaseClass) ->
    class ArangoSwitchMixin extends BaseClass
      @inheritProtected()
      iphEventNames = @private 'eventNames': Object
      @public middlewaresHandler: LAMBDA

      # from https://github.com/koajs/route/blob/master/index.js ###############
      decode = (val)-> # чистая функция
        decodeURIComponent val if val
      matches = (ctx, method)->
        return yes unless method
        return yes if ctx.method is method
        if method is 'GET' and ctx.method is 'HEAD'
          return yes
        return no
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

              keys = []
              re = pathToRegexp path, keys

              @facade.sendNotification SEND_TO_LOG, "
                #{method ? 'ALL'} #{path} -> #{re} has been defined
              ", LEVELS[DEBUG]

              @use co.wrap (ctx)=>
                unless matches ctx, method
                  yield return
                m = re.exec ctx.path
                if m
                  pathParams = m[1..]
                    .map decode
                    .reduce (prev, item, index)->
                      prev[keys[index].name] = item
                      prev
                    , {}
                  ctx.routePath = path
                  @facade.sendNotification SEND_TO_LOG, "#{ctx.method} #{path} matches #{ctx.path} #{JSON.stringify pathParams}", LEVELS[DEBUG]
                  ctx.pathParams = pathParams
                  ctx.req.pathParams = pathParams
                  return yield routeFunc.call @, ctx
                yield return

              voEndpoint = voRouter[originMethodName]? path, co.wrap (req, res)=>
                res.statusCode = 404
                voContext = ArangoContext.new req, res, @
                voContext.routePath = path
                @facade.sendNotification SEND_TO_LOG, "#{voContext.method} #{path} matches #{voContext.path} #{JSON.stringify req.pathParams}", LEVELS[DEBUG]
                voContext.pathParams = req.pathParams
                try
                  yield routeFunc.call @, voContext
                  @respond voContext
                catch err
                  voContext.onerror err
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

      @public @async callback: Function,
        args: []
        return: LAMBDA
        default: (req, res)->
          res.statusCode = 404
          voContext = ArangoContext.new req, res, @
          voContext.isPerformExecution = yes
          try
            yield @middlewaresHandler voContext
            @respond voContext
          catch err
            console.log '>>> ArangoSwitchMixin::callback catch err', err.stack
            voContext.onerror err
          yield return

      @public @async perform: Function,
        default: (method, url, options)->
          req = SyntheticRequest.new @Module.context()
          res = SyntheticResponse.new @Module.context()
          req.method = method
          req.url = url
          req.initialUrl = url
          req.headers = options.headers
          if options.body?
            req.body = options.body
            req.rawBody = new Buffer JSON.stringify options.body
          yield @callback req, res
          {
            statusCode: status
            statusMessage: message
            body
            headers
            cookies
          } = res
          yield return {status, message, headers, cookies, body}

      @public onRegister: Function,
        default: -> # super не вызываем
          voEmitter = new EventEmitter()
          @middlewaresHandler = @constructor.compose @middlewares
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

      @public respond: Function,
        default: (ctx)->
          return if ctx.respond is no
          return unless ctx.writable
          body = ctx.body
          code = ctx.status
          console.log '>>> ArangoSwitchMixin::respond body, code', body, code
          if statuses.empty[code]
            ctx.body = null
            return ctx.res.send()
          if 'HEAD' is ctx.method
            return ctx.res.send()
          unless body?
            body = ctx.message ? String code
            return ctx.res.send body
          console.log '>>> ArangoSwitchMixin::respond before ctx.res.send body'
          ctx.res.send body
          return

      @public @async sendHttpResponse: Function,
        default: (ctx, aoData, resource, opts)->
          if opts.action is 'create'
            ctx.status = 201
          console.log '>>> ArangoSwitchMixin::sendHttpResponse ctx.headers?.accept?', ctx.headers?.accept?
          unless ctx.headers?.accept?
            yield return
          console.log '>>> ArangoSwitchMixin::sendHttpResponse ctx.accepts @responseFormats', ctx.accepts @responseFormats
          switch (vsFormat = ctx.accepts @responseFormats)
            when no
            else
              if @["#{vsFormat}RendererName"]?
                voRenderer = @rendererFor vsFormat
                voRendered = yield voRenderer
                  .render ctx, aoData, resource, opts
                ctx.body = voRendered
          yield return

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
            @sendNotification resourceName, aoMessage, action
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

          [voRouter, voEndpoint] = @[method]? path, co.wrap (context)=>
            yield Module::Promise.new (resolve, reject)=>
              try
                reverse = genRandomAlphaNumbers 32
                @getViewComponent().once reverse, co.wrap ({error, result, resource})=>
                  console.log '>>> ArangoSwitchMixin::createNativeRoute', {error, result, resource}
                  if error?
                    reject error
                    yield return
                  try
                    yield @sendHttpResponse context, result, resource, opts
                    resolve()
                    yield return
                  catch err
                    reject err
                    yield return
                @sender resourceName, {context, reverse}, opts
              catch err
                reject err
              return
            yield return
          @defineSwaggerEndpoint voEndpoint, opts.resource, opts.action
          @Module.context().use voRouter
          return

    ArangoSwitchMixin.initializeMixin()
