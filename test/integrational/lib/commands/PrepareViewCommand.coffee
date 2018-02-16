# OtherServiceApplication = require('../../services/other')::MainApplication


module.exports = (Module) ->
  {
    APPLICATION_MEDIATOR
    APPLICATION_SWITCH
    RESQUE_EXECUTOR

    SimpleCommand
    ApplicationMediator
    LoggerModuleMediator
    ShellJunctionMediator
    # OtherModuleMediator
    ResqueExecutor
    MainSwitch
    Application
  } = Module::
  {
    CONNECT_MODULE_TO_LOGGER
    CONNECT_MODULE_TO_SHELL
  } = Application::

  class PrepareViewCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: (aoNotification)->
        voApplication = aoNotification.getBody()
        ###
        @facade.registerMediator LoggerModuleMediator.new()
        @facade.registerMediator ShellJunctionMediator.new()

        @facade.registerMediator ApplicationMediator.new APPLICATION_MEDIATOR, voApplication
        unless voApplication.isLightweight
          @facade.registerMediator MainSwitch.new APPLICATION_SWITCH
          @facade.registerMediator ResqueExecutor.new RESQUE_EXECUTOR
        ###

        # other = OtherServiceApplication.new()
        # @sendNotification CONNECT_MODULE_TO_LOGGER, other
        # @sendNotification CONNECT_MODULE_TO_SHELL, other
        # @facade.registerMediator OtherModuleMediator.new other

        return


  PrepareViewCommand.initialize()
