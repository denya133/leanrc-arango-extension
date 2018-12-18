

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
    FuncG
    NotificationInterface
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

    @public execute: FuncG(NotificationInterface),
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

        @facade.registerProxy MainCollection.new 'ReportsCollection',
          delegate: Module::ReportRecord
          serializer: ApplicationSerializer
        @facade.registerProxy MainCollection.new 'ClientsCollection',
          delegate: Module::ClientRecord
          serializer: ApplicationSerializer
        ###

        @facade.registerProxy ApplicationRouter.new APPLICATION_ROUTER

        unless voApplication.isLightweight
          @facade.registerProxy ApplicationGateway.new APPLICATION_GATEWAY
          @facade.registerProxy MainRenderer.new APPLICATION_RENDERER


    @initialize()
