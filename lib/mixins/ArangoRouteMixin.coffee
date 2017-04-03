# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# здесь должна быть реализация интерфейса RouteInterface работающая с Foxx роутером.

_             = require 'lodash'
inflect       = require('i')()
FoxxRouter    = require '@arangodb/foxx/router'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'
crypto        = require '@arangodb/crypto'
status        = require 'statuses'
{ errors }    = require '@arangodb'
RC            = require 'RC'
LeanRC        = require 'LeanRC'

ARANGO_NOT_FOUND  = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code
ARANGO_DUPLICATE  = errors.ERROR_ARANGO_UNIQUE_CONSTRAINT_VIOLATED.code
ARANGO_CONFLICT   = errors.ERROR_ARANGO_CONFLICT.code
HTTP_NOT_FOUND    = status 'not found'
HTTP_CONFLICT     = status 'conflict'
UNAUTHORIZED      = status 'unauthorized'

# здесь (наверху) надо привести пример использования в приложении
###
```coffee
LeanRC = require 'LeanRC'

module.exports = (App)->
  class App::FoxxMediator extends LeanRC::Mediator
    @inheritProtected()
    @include LeanRC::ArangoRouteMixin

    @Module: App

    @public routerName: String,
      default: 'ApplicationRouter'
    @public jsonRendererName: String,
      default: 'JsonRenderer'  # or 'ApplicationRenderer'
  return App::FoxxMediator.initialize()
```
###


# class FoxxRouterMixinInterface extends Interface
#   @include RouterMixinInterface

# TODO: надо подумать над тем, что возможно стоит создать класс LeanRC::Route - от которого наследоваться и куда подмешивать ArangoRouteMixin
# это будет оправдано, если наберется много общей платформонезависимой логики здесь.

# TODO: надо подобрать правильное (подходящее) название для `App::FoxxMediator`

module.exports = (ArangoExtension)->
  class ArangoExtension::ArangoRouteMixin extends RC::Mixin
    @inheritProtected()
    # @implements LeanRC::RouteInterface # или вообще не указывать

    @Module: ArangoExtension

    @public @virtual routerName: String

    @public responseFormats: Array,
      get: -> ['json', 'html', 'xml', 'atom']

    @public @virtual jsonRendererName: String
    @public @virtual htmlRendererName: String
    @public @virtual xmlRendererName: String
    @public @virtual atomRendererName: String

    @public listNotificationInterests: Function,
      default: ->
        [
          LeanRC::Constants.HANDLER_RESULT
        ]

    @public handleNotification: Function,
      default: (aoNotification)->
        vsName = aoNotification.getName()
        voBody = aoNotification.getBody()
        vsType = aoNotification.getType()
        switch vsName
          when LeanRC::Constants.HANDLER_RESULT
            @getViewComponent().emit vsType, voBody
        return

    @public onRegister: Function, # навешивают листенеры на @viewComponent
      # в express и koa тут можно создать сервер и положить его приватную перем.
      default: ->
        EventEmitter = require 'events'
        @setViewComponent new EventEmitter()
        @defineRoutes()
        return

    @public onRemove: Function, # удаляют ивент-листенеры на @viewComponent
      default: ->
        voEmitter = @getViewComponent()
        voEmitter.eventNames().forEach (eventName)->
          voEmitter.removeAllListeners eventName
        return

    @public getLocks: Function,
      args: []
      return: Object
      default: ->
        # не учитываются имена коллекций, вызываемые из других сервисов.
        vrCollectionPrefix = new RegExp "^#{module.collectionPrefix}"
        vlCollectionNames = db._collections().reduce (aoCollection, alResults)->
          if vrCollectionPrefix.test aoCollection.name
            alResults.push aoCollection.name
          alResults
        , []
        return read: vlCollectionNames, write: vlCollectionNames

    ipoRenderers = @private renderers: Object

    @public rendererFor: Function,
      args: [String]
      return: LeanRC::RendererInterface
      default: (asFormat)->
        @[ipoRenderers] ?= {}
        @[ipoRenderers][asFormat] ?= do (asFormat)=>
          voRenderer = if @["#{asFormat}RendererName"]?
            @facade.retrieveProxy @["#{asFormat}RendererName"]
          voRenderer ?= LeanRC::Renderer.new()
          voRenderer
        @[ipoRenderers][asFormat]

    @public sendResponse: Function,
      args: [Object, Object, Object, Object]
      return: RC::Constants.NILL
      default: (req, res, aoData, {path, resource, action})->
        if aoData?.constructor?.name is 'SyntheticResponse'
          return # ничего не делаем, если `res.send` уже был вызван ранее
        switch (vsFormat = req.accepts @responseFormats)
          when 'json', 'html', 'xml', 'atom'
            if @["#{vsFormat}RendererName"]?
              voRendered = @rendererFor vsFormat
                .render aoData, {path, resource, action}
            else
              res.setHeader 'Content-Type', 'text/plain'
              voRendered = JSON.stringify aoData
            res.send voRendered
          else
            res.setHeader 'Content-Type', 'text/plain'
            res.send JSON.stringify aoData
        return

    @public defineRoutes: Function,
      args: []
      return: RC::Constants.NILL
      default: ->
        voRouter = @facade.retrieveProxy @routerName
        voRouter.routes.forEach (aoRoute)=>
          @createNativeRoute aoRoute
        return

    @public createNativeRoute: Function,
      args: [Object]
      return: RC::Constants.NILL
      default: ({method, path, resource, action})->
        voRouter = FoxxRouter()
        resourceName = inflect.camelize inflect.underscore "#{resource.replace /[/]/g, '_'}Stock"

        voEndpoint = voRouter[method]? [path, (req, res)=>
          reverse = crypto.genRandomAlphaNumbers 32
          @getViewComponent().once reverse, (voData)=>
            @sendResponse req, res, voData, {method, path, resource, action}
          try
            if method is 'get'
              @sendNotification resourceName, {req, res, reverse}, action
            else
              {read, write} = @getLocks()
              self = @
              db._executeTransaction
                waitForSync: yes
                collections:
                  read: read
                  write: write
                  allowImplicit: no
                action: (params)->
                  currentUserId = params.req.session.uid
                  {
                    queryParams
                    pathPatams
                    headers
                    body
                  } = params.req
                  voMessage = {
                    queryParams
                    pathPatams
                    currentUserId
                    headers
                    body
                  }
                  voMessage.reverse = params.reverse
                  params.self.sendNotification params.resourceName, voMessage, params.action
                params: {resourceName, action, req, res, reverse, self}
            queues._updateQueueDelay()
          catch err
            console.log '???????????????????!!', JSON.stringify err
            if err.isArangoError and err.errorNum is ARANGO_NOT_FOUND
              res.throw HTTP_NOT_FOUND, err.message
              return
            if err.isArangoError and err.errorNum is ARANGO_CONFLICT
              res.throw HTTP_CONFLICT, err.message
              return
            else if err.statusCode?
              console.error err.message, err.stack
              res.throw err.statusCode, err.message
            else
              console.error 'kkkkkkkk', err.message, err.stack
              res.throw 500, err.message, err.stack
              return
        , action]...

        voGateway = @facade.retrieveProxy "#{resourceName}Gateway"
        {
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
        headers?.forEach ({name, schema, description})->
          voEndpoint.header name, schema, description
        pathParams?.forEach ({name, schema, description})->
          voEndpoint.pathParam name, schema, description
        queryParams?.forEach ({name, schema, description})->
          voEndpoint.queryParam name, schema, description
        if payload?
          voEndpoint.body payload.schema, payload.mimes, payload.description
        responses?.forEach ({status, schema, mimes, description})->
          voEndpoint.response status, schema, mimes, description
        errors?.forEach ({status, description})->
          voEndpoint.error status, description
        voEndpoint.summary title            if title?
        voEndpoint.description synopsis     if synopsis?
        voEndpoint.deprecated isDeprecated  if isDeprecated?

        # TODO: надо решить что с этим делать??? - т.к. в модуле нет больше контекста.
        # теоретически можно прямо здесь (где платформозависимый код) просто сделать вызов module.context.use voRouter
        module.context.use voRouter
        return


  return ArangoExtension::ArangoRouteMixin.initialize()
