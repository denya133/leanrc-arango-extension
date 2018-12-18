

module.exports = (Module) ->
  {
    STARTUP
    START_RESQUE
    PointerT
    FuncG
    FacadeInterface
    Facade
    StartupCommand
  } = Module::

  class ApplicationFacade extends Facade
    @inheritProtected()
    @module Module

    vpbIsInitialized = PointerT @private isInitialized: Boolean,
      default: no
    cphInstanceMap  = PointerT @classVariables['~instanceMap'].pointer

    @protected initializeController: Function,
      default: (args...)->
        @super args...
        @registerCommand STARTUP, StartupCommand
        # ... здесь могут быть регистрации и других команд

    @public startup: Function,
      default: (aoApplication)->
        unless @[vpbIsInitialized]
          @[vpbIsInitialized] = yes
          @sendNotification STARTUP, aoApplication
          unless aoApplication.isLightweight
            @sendNotification START_RESQUE
        return

    @public @static getInstance: FuncG(String, FacadeInterface),
      default: (asKey)->
        vhInstanceMap = Facade[cphInstanceMap]
        unless vhInstanceMap[asKey]?
          vhInstanceMap[asKey] = ApplicationFacade.new asKey
        vhInstanceMap[asKey]


    @initialize()
