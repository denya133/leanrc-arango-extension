

module.exports = (Module) ->
  {
    FuncG
    NotificationInterface
    SimpleCommand
    LoggerProxy
  } = Module::

  class PrepareModelCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: FuncG(NotificationInterface),
      default: ->
        @facade.registerProxy LoggerProxy.new()


    @initialize()
