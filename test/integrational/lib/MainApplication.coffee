

module.exports = (Module) ->
  {
    NilT
    FuncG, MaybeG
    LogMessage
    LogFilterMessage
    Application
  } = Module::

  class MainApplication extends Application
    @inheritProtected()
    @module Module

    @public @static @async testDelayedMethod: Function,
      default: ->
        console.log '>>>>>>>>>>>>>> TEST DELAYED METHOD'
        yield return

    @public setLogLevelMethod: Function,
      default: (level)->
        @facade.sendNotification LogFilterMessage.SET_LOG_LEVEL, level

    @public init: FuncG([MaybeG Symbol], NilT),
      default: (args...)->
        @super args...
        @setLogLevelMethod LogMessage.DEBUG
        return


    @initialize()
