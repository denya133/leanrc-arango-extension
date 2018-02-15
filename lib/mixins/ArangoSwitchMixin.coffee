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
    ANY
    NILL
    LAMBDA

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

  Module.defineMixin 'ArangoSwitchMixin', (BaseClass = Switch) ->
    class extends BaseClass
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

              @sendNotification SEND_TO_LOG, "
                #{method ? 'ALL'} #{path} -> #{re} has been defined
              ", LEVELS[DEBUG]

              self = @
              @use co.wrap (ctx)->
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

              voEndpoint = voRouter[originMethodName]? path, co.wrap (req, res)->
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
                yield return
              return [voRouter, voEndpoint]
          return

      self = @
      methods.forEach (method)->
        self.createMethod method

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
            voContext.onerror err
          yield return

      @public @async perform: Function,
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
          yield @callback req, res
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

      @public defineSwaggerEndpoint: Function,
        args: [Object, Object]
        return: NILL
        default: (aoSwaggerEndpoint, {resource, action, tag:resourceTag, options})->
          gatewayName = inflect.camelize inflect.underscore "#{resource.replace /[/]/g, '_'}Gateway"
          voGateway = @facade.retrieveProxy gatewayName
          unless voGateway?
            throw new Error "#{gatewayName} is absent in code"
          voSwaggerDefinition = voGateway.swaggerDefinitionFor action
          ###
          voSwaggerDefinition = voGateway.swaggerDefinitionFor resource, action, options.crud
          ###
          unless voSwaggerDefinition?
            throw new Error "#{gatewayName}::#{action} is absent in code"
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
          } = voSwaggerDefinition#options.swaggerDefinitions
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
            yield return
          @defineSwaggerEndpoint voEndpoint, opts
          @Module.context().use voRouter
          return

      @initializeMixin()
