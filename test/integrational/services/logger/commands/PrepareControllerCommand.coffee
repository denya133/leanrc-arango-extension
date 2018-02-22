

module.exports = (Module) ->
  {
    LOG_MSG

    SimpleCommand
    LogMessageCommand
  } = Module::

  class PrepareControllerCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: ->
        @facade.registerCommand LOG_MSG, LogMessageCommand


  PrepareControllerCommand.initialize()
