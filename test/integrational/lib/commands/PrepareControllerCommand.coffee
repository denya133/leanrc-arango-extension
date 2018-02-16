

module.exports = (Module) ->
  {
    DELAYED_JOBS_SCRIPT
    MIGRATE
    ROLLBACK

    SimpleCommand
    DelayedJobScript
    MigrateCommand
    RollbackCommand
  } = Module::

  class PrepareControllerCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: ->
        @facade.registerCommand DELAYED_JOBS_SCRIPT, DelayedJobScript
        @facade.registerCommand MIGRATE, MigrateCommand
        @facade.registerCommand ROLLBACK, RollbackCommand

        ###
        @facade.registerCommand(
          'TrackeringClientsResource'
          Module::TrackeringClientsResource
        )
        @facade.registerCommand(
          'TrackeringLoggedReportsResource'
          Module::TrackeringLoggedReportsResource
        )

        @facade.registerCommand(
          'SharingLabelsResource'
          Module::SharingLabelsResource
        )
        @facade.registerCommand(
          'SharingLoggedPeriodsResource'
          Module::SharingLoggedPeriodsResource
        )
        @facade.registerCommand(
          'SharingLoggedReportsResource'
          Module::SharingLoggedReportsResource
        )
        @facade.registerCommand(
          'SharingManuallyPeriodsResource'
          Module::SharingManuallyPeriodsResource
        )
        @facade.registerCommand(
          'SharingPeriodLabelsResource'
          Module::SharingPeriodLabelsResource
        )
        @facade.registerCommand(
          'SharingPeriodsResource'
          Module::SharingPeriodsResource
        )
        @facade.registerCommand(
          'SharingPeriodUploadsResource'
          Module::SharingPeriodUploadsResource
        )
        @facade.registerCommand(
          'SharingRemovedPeriodsResource'
          Module::SharingRemovedPeriodsResource
        )
        @facade.registerCommand(
          'SharingRemovedReportsResource'
          Module::SharingRemovedReportsResource
        )
        @facade.registerCommand(
          'SharingReportsResource'
          Module::SharingReportsResource
        )
        @facade.registerCommand(
          'SharingStatisticsResource'
          Module::SharingStatisticsResource
        )

        @facade.registerCommand(
          'AdminingClientsResource'
          Module::AdminingClientsResource
        )
        @facade.registerCommand(
          'AdminingLabelsResource'
          Module::AdminingLabelsResource
        )
        @facade.registerCommand(
          'AdminingLoggedPeriodsResource'
          Module::AdminingLoggedPeriodsResource
        )
        @facade.registerCommand(
          'AdminingLoggedReportsResource'
          Module::AdminingLoggedReportsResource
        )
        @facade.registerCommand(
          'AdminingManuallyPeriodsResource'
          Module::AdminingManuallyPeriodsResource
        )
        @facade.registerCommand(
          'AdminingPeriodLabelsResource'
          Module::AdminingPeriodLabelsResource
        )
        @facade.registerCommand(
          'AdminingPeriodsResource'
          Module::AdminingPeriodsResource
        )
        @facade.registerCommand(
          'AdminingPeriodUploadsResource'
          Module::AdminingPeriodUploadsResource
        )
        @facade.registerCommand(
          'AdminingRemovedPeriodsResource'
          Module::AdminingRemovedPeriodsResource
        )
        @facade.registerCommand(
          'AdminingRemovedReportsResource'
          Module::AdminingRemovedReportsResource
        )
        @facade.registerCommand(
          'AdminingReportsResource'
          Module::AdminingReportsResource
        )
        @facade.registerCommand(
          'AdminingStatisticsResource'
          Module::AdminingStatisticsResource
        )

        @facade.registerCommand(
          'ClientsResource'
          Module::ClientsResource
        )
        @facade.registerCommand(
          'LabelsResource'
          Module::LabelsResource
        )
        @facade.registerCommand(
          'LoggedPeriodsResource'
          Module::LoggedPeriodsResource
        )
        @facade.registerCommand(
          'LoggedReportsResource'
          Module::LoggedReportsResource
        )
        @facade.registerCommand(
          'ManuallyPeriodsResource'
          Module::ManuallyPeriodsResource
        )
        @facade.registerCommand(
          'PeriodLabelsResource'
          Module::PeriodLabelsResource
        )
        @facade.registerCommand(
          'PeriodsResource'
          Module::PeriodsResource
        )
        @facade.registerCommand(
          'PeriodUploadsResource'
          Module::PeriodUploadsResource
        )
        @facade.registerCommand(
          'RemovedPeriodsResource'
          Module::RemovedPeriodsResource
        )
        @facade.registerCommand(
          'RemovedReportsResource'
          Module::RemovedReportsResource
        )
        @facade.registerCommand(
          'ReportsResource'
          Module::ReportsResource
        )

        @facade.registerCommand 'ItselfResource', Module::ItselfResource
        @facade.registerCommand(
          'SharingPermitablesResource'
          Module::SharingPermitablesResource
        )
        @facade.registerCommand(
          'AdminingPermitablesResource'
          Module::AdminingPermitablesResource
        )
        @facade.registerCommand(
          'AdminingAccessiblesResource'
          Module::AdminingAccessiblesResource
        )
        @facade.registerCommand(
          'AdminingChargeablesResource'
          Module::AdminingChargeablesResource
        )
        ###


  PrepareControllerCommand.initialize()
