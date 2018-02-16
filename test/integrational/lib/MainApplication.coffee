

module.exports = (Module) ->
  {
    NILL

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
      args: []
      return: NILL
      default: (level)->
        @facade.sendNotification LogFilterMessage.SET_LOG_LEVEL, level

    @public init: Function,
      default: (args...)->
        @super args...
        @setLogLevelMethod LogMessage.DEBUG
        console.log 'STARTED'
        return


  MainApplication.initialize()
