

module.exports = (Module) ->
  {
    DELAYED_JOBS_SCRIPT
    MIGRATE
    ROLLBACK
    FuncG
    NotificationInterface
    SimpleCommand
    DelayedJobScript
    MigrateCommand
    RollbackCommand
  } = Module::

  class PrepareControllerCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: FuncG(NotificationInterface),
      default: ->
        @facade.registerCommand DELAYED_JOBS_SCRIPT, DelayedJobScript
        @facade.registerCommand MIGRATE, MigrateCommand
        @facade.registerCommand ROLLBACK, RollbackCommand

        @facade.registerCommand(
          'ModelingClientsResource'
          Module::ClientsResource
        )

        @facade.registerCommand 'ItselfResource', Module::ItselfResource


    @initialize()
