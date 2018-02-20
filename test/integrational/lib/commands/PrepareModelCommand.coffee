

module.exports = (Module) ->
  {
    CONFIGURATION
    RESQUE
    APPLICATION_RENDERER
    APPLICATION_ROUTER
    APPLICATION_GATEWAY
    USERS
    SPACES
    SESSIONS
    ROLES
    MIGRATIONS

    ApplicationSerializer
    HttpSerializer
    SimpleCommand
    MainConfiguration
    MainResque
    MigrationsCollection
    AuthForeignCollection
    GridHttpCollection
    MainCollection
    ModelingGateway
    ApplicationGateway
    StatisticsGateway
    BaseMigration
    MainRenderer
    ApplicationRouter
  } = Module::

  class PrepareModelCommand extends SimpleCommand
    @inheritProtected()
    @module Module

    @public execute: Function,
      default: (aoNotification)->
        voApplication = aoNotification.getBody()

        @facade.registerProxy MainConfiguration.new CONFIGURATION, @Module::ROOT
        @facade.registerProxy MainResque.new RESQUE
        @facade.registerProxy MigrationsCollection.new MIGRATIONS,
          delegate: BaseMigration
          serializer: ApplicationSerializer

        ###
        @facade.registerProxy AuthForeignCollection.new USERS,
          delegate: Module::UserRecord
          serializer: HttpSerializer
        @facade.registerProxy AuthForeignCollection.new SESSIONS,
          delegate: Module::SessionRecord
          serializer: HttpSerializer
        @facade.registerProxy AuthForeignCollection.new SPACES,
          delegate: Module::SpaceRecord
          serializer: HttpSerializer
        @facade.registerProxy AuthForeignCollection.new ROLES,
          delegate: Module::RoleRecord
          serializer: HttpSerializer
        @facade.registerProxy GridHttpCollection.new 'UploadsCollection',
          delegate: Module::UploadRecord
          serializer: HttpSerializer

        @facade.registerProxy MainCollection.new 'ReportsCollection',
          delegate: Module::ReportRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'ClientsCollection',
          delegate: Module::ClientRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'LabelsCollection',
          delegate: Module::LabelRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'PeriodsCollection',
          delegate: Module::PeriodRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'PeriodLabelsCollection',
          delegate: Module::PeriodLabelRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'PeriodUploadsCollection',
          delegate: Module::PeriodUploadRecord
          serializer: ApplicationSerializer
        ###
        
        @facade.registerProxy ApplicationRouter.new APPLICATION_ROUTER

        unless voApplication.isLightweight
          @facade.registerProxy ApplicationGateway.new APPLICATION_GATEWAY
          @facade.registerProxy MainRenderer.new APPLICATION_RENDERER

        ###
          # trackering
          @facade.registerProxy ApplicationGateway.new 'TrackeringClientsGateway',
            entityName: 'client'
            schema: Module::ClientRecord.schema
            endpoints: {
              create: Module::ClientsCreateEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'TrackeringLoggedReportsGateway',
            entityName: 'loggedReport'
            schema: Module::LoggedReportRecord.schema
            endpoints: {
              create: Module::LoggedReportsCreateEndpoint
              remove: Module::LoggedReportsRemoveEndpoint
            }

          # sharing
          @facade.registerProxy ApplicationGateway.new 'SharingReportsGateway',
            entityName: 'report'
            schema: Module::ReportRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingLabelsGateway',
            entityName: 'label'
            schema: Module::LabelRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingPeriodsGateway',
            entityName: 'period'
            schema: Module::PeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingPeriodLabelsGateway',
            entityName: 'periodLabel'
            schema: Module::PeriodLabelRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingPeriodUploadsGateway',
            entityName: 'periodUpload'
            schema: Module::PeriodUploadRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingLoggedPeriodsGateway',
            entityName: 'loggedPeriod'
            schema: Module::LoggedPeriodRecord.schema
            endpoints: {
              remove: Module::LoggedPeriodsRemoveEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'SharingManuallyPeriodsGateway',
            entityName: 'manuallyPeriod'
            schema: Module::ManuallyPeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingRemovedPeriodsGateway',
            entityName: 'removedPeriod'
            schema: Module::RemovedPeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'SharingLoggedReportsGateway',
            entityName: 'loggedReport'
            schema: Module::LoggedReportRecord.schema
            endpoints: {
              create: Module::LoggedReportsCreateEndpoint
              remove: Module::LoggedReportsRemoveEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'SharingRemovedReportsGateway',
            entityName: 'removedReport'
            schema: Module::RemovedReportRecord.schema
          @facade.registerProxy StatisticsGateway.new 'SharingStatisticsGateway',
            entityName: 'statistic'
            endpoints: {
              aggregate: Module::StatisticsAggregateEndpoint
              coaggregate: Module::StatisticsCoaggregateEndpoint
              lasts: Module::StatisticsLastsEndpoint
            }

          # admining
          @facade.registerProxy ApplicationGateway.new 'AdminingReportsGateway',
            entityName: 'report'
            schema: Module::ReportRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingClientsGateway',
            entityName: 'client'
            schema: Module::ClientRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingLabelsGateway',
            entityName: 'label'
            schema: Module::LabelRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingPeriodsGateway',
            entityName: 'period'
            schema: Module::PeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingPeriodLabelsGateway',
            entityName: 'periodLabel'
            schema: Module::PeriodLabelRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingPeriodUploadsGateway',
            entityName: 'periodUpload'
            schema: Module::PeriodUploadRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingLoggedPeriodsGateway',
            entityName: 'loggedPeriod'
            schema: Module::LoggedPeriodRecord.schema
            endpoints: {
              remove: Module::LoggedPeriodsRemoveEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'AdminingManuallyPeriodsGateway',
            entityName: 'manuallyPeriod'
            schema: Module::ManuallyPeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingRemovedPeriodsGateway',
            entityName: 'removedPeriod'
            schema: Module::RemovedPeriodRecord.schema
          @facade.registerProxy ApplicationGateway.new 'AdminingLoggedReportsGateway',
            entityName: 'loggedReport'
            schema: Module::LoggedReportRecord.schema
            endpoints: {
              create: Module::LoggedReportsCreateEndpoint
              remove: Module::LoggedReportsRemoveEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'AdminingRemovedReportsGateway',
            entityName: 'removedReport'
            schema: Module::RemovedReportRecord.schema
          @facade.registerProxy StatisticsGateway.new 'AdminingStatisticsGateway',
            entityName: 'statistic'
            endpoints: {
              aggregate: Module::StatisticsAggregateEndpoint
              coaggregate: Module::StatisticsCoaggregateEndpoint
              lasts: Module::StatisticsLastsEndpoint
            }

          # modeling
          @facade.registerProxy ModelingGateway.new 'ReportsGateway',
            entityName: 'report'
            schema: Module::ReportRecord.schema
          @facade.registerProxy ModelingGateway.new 'ClientsGateway',
            entityName: 'client'
            schema: Module::ClientRecord.schema
          @facade.registerProxy ModelingGateway.new 'LabelsGateway',
            entityName: 'label'
            schema: Module::LabelRecord.schema
          @facade.registerProxy ModelingGateway.new 'PeriodsGateway',
            entityName: 'period'
            schema: Module::PeriodRecord.schema
          @facade.registerProxy ModelingGateway.new 'PeriodLabelsGateway',
            entityName: 'periodLabel'
            schema: Module::PeriodLabelRecord.schema
          @facade.registerProxy ModelingGateway.new 'PeriodUploadsGateway',
            entityName: 'periodUpload'
            schema: Module::PeriodUploadRecord.schema
          @facade.registerProxy ModelingGateway.new 'LoggedPeriodsGateway',
            entityName: 'loggedPeriod'
            schema: Module::LoggedPeriodRecord.schema
            endpoints: {
              remove: Module::LoggedPeriodsRemoveEndpoint
            }
          @facade.registerProxy ModelingGateway.new 'ManuallyPeriodsGateway',
            entityName: 'manuallyPeriod'
            schema: Module::ManuallyPeriodRecord.schema
          @facade.registerProxy ModelingGateway.new 'RemovedPeriodsGateway',
            entityName: 'removedPeriod'
            schema: Module::RemovedPeriodRecord.schema
          @facade.registerProxy ModelingGateway.new 'LoggedReportsGateway',
            entityName: 'loggedReport'
            schema: Module::LoggedReportRecord.schema
            endpoints: {
              create: Module::LoggedReportsCreateEndpoint
              remove: Module::LoggedReportsRemoveEndpoint
            }
          @facade.registerProxy ModelingGateway.new 'RemovedReportsGateway',
            entityName: 'removedReport'
            schema: Module::RemovedReportRecord.schema

          @facade.registerProxy ApplicationGateway.new 'ItselfGateway',
            entityName: 'info'
            schema: {}
            endpoints: {
              info: Module::ItselfInfoEndpoint
              static: Module::ItselfStaticEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'SharingPermitablesGateway',
            entityName: 'permitable'
            schema: {}
            endpoints: {
              list: Module::SharingPermitablesListEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'AdminingPermitablesGateway',
            entityName: 'permitable'
            schema: {}
            endpoints: {
              list: Module::AdminingPermitablesListEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'AdminingAccessiblesGateway',
            entityName: 'accessible'
            schema: {}
            endpoints: {
              list: Module::AdminingAccessiblesListEndpoint
            }
          @facade.registerProxy ApplicationGateway.new 'AdminingChargeablesGateway',
            entityName: 'chargeable'
            schema: {}
            endpoints: {
              list: Module::AdminingChargeablesListEndpoint
            }
        ###


  PrepareModelCommand.initialize()
