

module.exports = (Module) ->
  {
    NILL

    SimpleCommand
    LogMessageCommand
    Application
    LogMessage: { CHANGE, NONE, FATAL, ERROR, WARN, INFO, DEBUG }
  } = Module::
  {
    LOGGER_PROXY
  } = Application::

  class LoggerProxy extends Module::Proxy
    @inheritProtected()
    @module Module

    @public addLogEntry: Function,
      args: [Object]
      return: NILL
      default: (data)->
        {logLevel, sender, time, message} = data
        switch logLevel
          when FATAL, ERROR
            console.error sender, '->', message
          when INFO
            console.info sender, '->', message
          when DEBUG
            console.log sender, '->', message
          when WARN
            console.warn sender, '->', message
          else
            console.log sender, '->', message
        return

    @public init: Function,
      default: ->
        @super LOGGER_PROXY, []
        return


  LoggerProxy.initialize()
