

module.exports = (Module) ->
  {
    FuncG
    NotificationInterface
    SimpleCommand
    LoggerJunctionMediator
  } = Module::

  class PrepareViewCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: FuncG(NotificationInterface),
      default: (aoNotification)->
        @facade.registerMediator LoggerJunctionMediator.new()
        return


    @initialize()
