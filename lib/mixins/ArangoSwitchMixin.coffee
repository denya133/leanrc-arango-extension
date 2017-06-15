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
  } = Module::
  {  ERROR, DEBUG, LEVELS, SEND_TO_LOG } = LogMessage

  Module.defineMixin (BaseClass) ->
    class ArangoSwitchMixin extends BaseClass
      @inheritProtected()

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
            return: NILL
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
              @defineSwaggerEndpoint voEndpoint

              module.context.use voRouter
              return
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
          if voEmitter.listeners('error').length is 0
            voEmitter.on 'error', @onerror.bind @
          @setViewComponent voEmitter
          @defineRoutes()
          return

      @public onRemove: Function,
        default: -> # super не вызываем
          voEmitter = @getViewComponent()
          voEmitter.eventNames().forEach (eventName)->
            voEmitter.removeAllListeners eventName
          return

      @public getLocks: Function,
        args: []
        return: Object
        default: ->
          vrCollectionPrefix = new RegExp "^#{module.context.collectionPrefix}"
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

      @public sender: Function,
        default: (resourceName, aoMessage, {method, path, resource, action})->
          {context} = aoMessage
          try
            if method is 'get'
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


    ArangoSwitchMixin.initializeMixin()
