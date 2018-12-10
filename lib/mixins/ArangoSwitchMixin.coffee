# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# здесь должна быть реализация интерфейса SwitchInterface работающая с Foxx роутером.

methods       = require 'methods'
FoxxRouter    = require '@arangodb/foxx/router'
{ db }        = require '@arangodb'
{ errors }    = require '@arangodb'
EventEmitter  = require 'events'
pathToRegexp  = require 'path-to-regexp'

ARANGO_NOT_FOUND  = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code
ARANGO_DUPLICATE  = errors.ERROR_ARANGO_UNIQUE_CONSTRAINT_VIOLATED.code
ARANGO_CONFLICT   = errors.ERROR_ARANGO_CONFLICT.code


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
    APPLICATION_GATEWAY
    AnyT, NilT, PointerT, AsyncFunctionT, LambdaT
    FuncG, ListG, MaybeG, InterfaceG, StructG, TupleG, DictG, EnumG
    SwitchInterface, ContextInterface, NotificationInterface
    Mixin
    Switch
    ArangoContext
    SyntheticRequest
    SyntheticResponse
    LogMessage: {  ERROR, DEBUG, LEVELS, SEND_TO_LOG }
    Utils: {
      _
      inflect
      co
      genRandomAlphaNumbers
      statuses
    }
  } = Module::

  HTTP_NOT_FOUND    = statuses 'not found'
  HTTP_CONFLICT     = statuses 'conflict'

  Module.defineMixin Mixin 'ArangoSwitchMixin', (BaseClass = Switch) ->
    class extends BaseClass
      @inheritProtected()

      iphEventNames = PointerT @private eventNames: Object

      @public middlewaresHandler: LambdaT

      # from https://github.com/koajs/route/blob/master/index.js ###############
      decode = FuncG([MaybeG String], MaybeG String) (val)-> # чистая функция
        decodeURIComponent val if val

      matches = FuncG([ContextInterface, String], Boolean) (ctx, method)->
        return yes unless method
        return yes if ctx.method is method
        if method is 'GET' and ctx.method is 'HEAD'
          return yes
        return no

      ################

      @public @static createMethod: FuncG([MaybeG String], NilT),
        default: (method)->
          originMethodName = method
          if method
            method = method.toUpperCase()
          else
            originMethodName = 'all'

          @public "#{originMethodName}": FuncG([String, Function], TupleG Object, Object),
            default: (path, routeFunc)->
              voRouter = FoxxRouter()
              unless routeFunc
                throw new Error 'handler is required'

              keys = []
              re = pathToRegexp path, keys

              @sendNotification SEND_TO_LOG, "
                #{method ? 'ALL'} #{path} -> #{re} has been defined
              ", LEVELS[DEBUG]

              self = @
              @use keys.length, co.wrap (ctx)->
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
                  self.sendNotification SEND_TO_LOG, "#{ctx.method} #{path} matches #{ctx.path} #{JSON.stringify pathParams}", LEVELS[DEBUG]
                  ctx.pathParams = pathParams
                  ctx.req.pathParams = pathParams
                  return yield routeFunc.call self, ctx
                yield return

              voEndpoint = voRouter[originMethodName]? path, @callback path, routeFunc
              return [voRouter, voEndpoint]
          return

      Class = @
      methods.forEach (method)->
        Class.createMethod method

      @public del: Function,
        default: (args...)->
          @delete args...

      @createMethod() # create @public all:...
      ##########################################################################

      @public @async perform: FuncG(StructG({
        method: String
        url: String
        options: InterfaceG {
          json: EnumG [yes]
          headers: DictG String, String
          body: MaybeG Object
        }
      }), StructG {
        body: MaybeG AnyT
        headers: DictG String, String
        status: Number
        message: MaybeG String
      }),
        default: (method, url, options)->
          @sendNotification SEND_TO_LOG, '>>>>>> START PERFORM-REQUEST HANDLING', LEVELS[DEBUG]
          req = SyntheticRequest.new @Module.context()
          res = SyntheticResponse.new @Module.context()
          req.method = method
          req.url = url
          req.initialUrl = url
          req.headers = options.headers
          if options.body?
            req.body = options.body
            req.rawBody = new Buffer JSON.stringify options.body

          res.statusCode = 404
          voContext = ArangoContext.new req, res, @
          voContext.isPerformExecution = yes
          try
            yield @middlewaresHandler voContext
            @respond voContext
          catch err
            voContext.onerror err

          {
            statusCode: status
            statusMessage: message
            body
            headers
            cookies
          } = res
          @sendNotification SEND_TO_LOG, '>>>>>> END PERFORM-REQUEST HANDLING', LEVELS[DEBUG]
          yield return {status, message, headers, cookies, body}

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
          @serverListen()
          return

      @public onRemove: Function,
        default: -> # super не вызываем
          voEmitter = @getViewComponent()
          eventNames = voEmitter.eventNames?() ? Object.keys @[iphEventNames] ? {}
          eventNames.forEach (eventName)->
            voEmitter.removeAllListeners eventName
          return

      @public serverListen: Function,
        default: ->
          @middlewaresHandler = @constructor.compose @middlewares, @handlers
          return

      @public callback: FuncG([], AsyncFunctionT),
        default: (path, routeFunc)->
          self = @
          handleRequest = co.wrap (req, res)->
            t1 = Date.now()
            { ERROR, DEBUG, LEVELS, SEND_TO_LOG } = Module::LogMessage
            self.sendNotification SEND_TO_LOG, '>>>>>> START REQUEST HANDLING', LEVELS[DEBUG]
            res.statusCode = 404
            voContext = ArangoContext.new req, res, self
            voContext.routePath = path
            self.sendNotification SEND_TO_LOG, "#{voContext.method} #{path} matches #{voContext.path} #{JSON.stringify req.pathParams}", LEVELS[DEBUG]
            voContext.pathParams = req.pathParams
            try
              yield routeFunc.call self, voContext
              self.respond voContext
            catch err
              voContext.onerror err
            self.sendNotification SEND_TO_LOG, '>>>>>> END REQUEST HANDLING', LEVELS[DEBUG]
            reqLength = voContext.request.length
            resLength = voContext.response.length
            time = Date.now() - t1
            yield self.handleStatistics reqLength, resLength, time, voContext
            yield return
          handleRequest

      @public respond: FuncG(ContextInterface, NilT),
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
          ctx.res.send body
          return

      @public defineSwaggerEndpoint: FuncG([Object, InterfaceG {
        method: String
        path: String
        resource: String
        action: String
        tag: String
        template: String
        keyName: MaybeG String
        entityName: String
        recordName: MaybeG String
      }], NilT),
        default: (aoSwaggerEndpoint, {resource, action, tag:resourceTag, options, keyName, entityName, recordName})->
          voGateway = @facade.retrieveProxy APPLICATION_GATEWAY
          unless voGateway?
            throw new Error "#{APPLICATION_GATEWAY} is absent in code"
          voSwaggerDefinition = voGateway.swaggerDefinitionFor resource, action, {
            keyName, entityName, recordName
          }
          unless voSwaggerDefinition?
            # throw new Error "#{gatewayName}::#{action} is absent in code"
            throw new Error "Endpoint for #{resource}##{action} is absent in code"
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
          } = voSwaggerDefinition
          if resourceTag?
            aoSwaggerEndpoint.tag resourceTag
          if tags?.length
            aoSwaggerEndpoint.tag tags...
          headers?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.header name, schema, description
          pathParams?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.pathParam name, schema, description
          queryParams?.forEach ({name, schema, description})->
            aoSwaggerEndpoint.queryParam name, schema, description
          if payload?
            aoSwaggerEndpoint.body payload.schema, payload.mimes, payload.description
          responses?.forEach ({status, schema, mimes, description})->
          # responses?.forEach (args)->
            aoSwaggerEndpoint.response status, schema, mimes, description
            # aoSwaggerEndpoint.response args...
          errors?.forEach ({status, description})->
            aoSwaggerEndpoint.error status, description
          aoSwaggerEndpoint.summary title            if title?
          aoSwaggerEndpoint.description synopsis     if synopsis?
          aoSwaggerEndpoint.deprecated isDeprecated  if isDeprecated?
          return

      @public sender: FuncG([String, StructG({
        context: ContextInterface
        reverse: String
      }), InterfaceG {
        method: String
        path: String
        resource: String
        action: String
        tag: String
        template: String
        keyName: MaybeG String
        entityName: String
        recordName: MaybeG String
      }], NilT),
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

      @public createNativeRoute: FuncG([InterfaceG {
        method: String
        path: String
        resource: String
        action: String
        tag: String
        template: String
        keyName: MaybeG String
        entityName: String
        recordName: MaybeG String
      }], NilT),
        default: (opts)->
          {method, path} = opts
          resourceName = inflect.camelize inflect.underscore "#{opts.resource.replace /[/]/g, '_'}Resource"
          self = @
          [voRouter, voEndpoint] = @[method]? path, co.wrap (context)->
            yield Module::Promise.new (resolve, reject)->
              try
                reverse = genRandomAlphaNumbers 32
                self.getViewComponent().once reverse, co.wrap ({error, result, resource})->
                  self.sendNotification SEND_TO_LOG, "
                    ArangoSwitchMixin::createNativeRoute <result from resource>
                    isError #{error?} #{if error? then error.stack}
                    result: #{JSON.stringify result}
                    resource: #{resource.constructor.name}
                  ", LEVELS[DEBUG]
                  if error?
                    reject error
                    yield return
                  try
                    yield self.sendHttpResponse context, result, resource, opts
                    resolve()
                    yield return
                  catch err
                    reject err
                    yield return
                self.sender resourceName, {context, reverse}, opts
              catch err
                reject err
              return
            yield return yes
          @defineSwaggerEndpoint voEndpoint, opts
          @Module.context().use voRouter
          return


      @initializeMixin()
