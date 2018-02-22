

module.exports = (Module) ->
  {
    SimpleCommand
    LoggerJunctionMediator
  } = Module::

  class PrepareViewCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: (aoNotification)->
        @facade.registerMediator LoggerJunctionMediator.new()
        return


  PrepareViewCommand.initialize()
