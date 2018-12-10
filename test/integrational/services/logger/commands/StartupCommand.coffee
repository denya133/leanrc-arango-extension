

module.exports = (Module) ->
  {
    MacroCommand
    PrepareControllerCommand
    PrepareViewCommand
    PrepareModelCommand
  } = Module::

  class StartupCommand extends MacroCommand
    @inheritProtected()
    @module Module

    @public initializeMacroCommand: Function,
      default: ->
        @addSubCommand PrepareControllerCommand
        @addSubCommand PrepareModelCommand
        @addSubCommand PrepareViewCommand

    @initialize()
