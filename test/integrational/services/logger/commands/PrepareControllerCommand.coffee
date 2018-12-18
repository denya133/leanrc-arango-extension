

module.exports = (Module) ->
  {
    LOG_MSG
    FuncG
    NotificationInterface
    SimpleCommand
    LogMessageCommand
  } = Module::

  class PrepareControllerCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: FuncG(NotificationInterface),
      default: ->
        @facade.registerCommand LOG_MSG, LogMessageCommand


    @initialize()
