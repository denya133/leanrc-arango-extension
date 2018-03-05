

module.exports = (Module) ->
  {
    SimpleCommand
    LoggerProxy
  } = Module::

  class PrepareModelCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: ->
        @facade.registerProxy LoggerProxy.new()


  PrepareModelCommand.initialize()
