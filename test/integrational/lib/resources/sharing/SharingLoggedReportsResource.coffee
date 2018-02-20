# TODO: этот ресурс нужен как отдельный самостоятельный т.к. именно на него будут отправляться (на нем будут обрабатываться) запросы из C++ клиента на создание автоматически логируемых репортов

# TODO: в этом же ресурсе должен быть экшен, который будет для мембера пробрасываться из роутера для превращения отлогированного репорта в удаленный репорт


module.exports = (Module)->
  {
    Resource
    BodyParseMixin
    CheckSessionsMixin
    QueryableResourceMixin
    ArangoResourceMixin
    EditableResourceMixin
    SharingResourceMixin
    ExtendReportFromClientsMixin
    Utils: { _, moment, statuses, isArangoDB, jsonStringify, uuid }
  } = Module::

  FORBIDDEN   = statuses 'forbidden'
  HTTP_NOT_FOUND  = statuses 'not found'

  class SharingLoggedReportsResource extends Resource
    @inheritProtected()
    @include BodyParseMixin
    @include CheckSessionsMixin
    @include QueryableResourceMixin
    @include ArangoResourceMixin
    @include EditableResourceMixin
    @include SharingResourceMixin
    @include ExtendReportFromClientsMixin
    @module Module

    @public entityName: String,
      default: 'loggedReport'

    @public keyName: String,
      get: -> 'sharing_logged_report'

    @public collection: Module::CollectionInterface,
      get: ->
        @facade.retrieveProxy 'ReportsCollection'

    @public periodsCollection: Module::CollectionInterface,
      get: ->
        @facade.retrieveProxy 'PeriodsCollection'

    # TODO: надо перепроверить эти хуки
    @chains ['remove']

    @initialHook 'checkSchemaVersion'
    @initialHook 'checkApiVersion'
    @initialHook 'checkSession'
    @initialHook 'parseBody',           only: ['remove']
    @initialHook 'checkPermission'

    @beforeHook 'filterByType',         only: ['list']
    @beforeHook 'getRecordId',          only: ['remove']

    @afterHook 'mixFromClients',        only: ['list']
    @afterHook 'mixFromClient',         only: ['detail']

    @public @async filterByType: Function,
      default: (args...)->
        @listQuery ?= {}
        moduleName = @collection.delegate.moduleName()
        if @listQuery.$filter?
          @listQuery.$filter = $and: [
            @listQuery.$filter
          ,
            '@doc.type': $eq: "#{moduleName}::LoggedReportRecord"
          ]
        else
          @listQuery.$filter = '@doc.type': $eq: "#{moduleName}::LoggedReportRecord"
        yield return args

    @public @async checkExistence: Function,
      default: (args...) ->
        moduleName = @collection.delegate.moduleName()
        currentSpace = @context.pathParams.space ? '_default'
        unless @recordId?
          @context.throw HTTP_NOT_FOUND
        unless (yield @collection.exists
          '@doc.id': @recordId
          '@doc.type': "#{moduleName}::LoggedReportRecord"
          '@doc.spaces': $all: [currentSpace]
        )
          @context.throw HTTP_NOT_FOUND
        yield return args

    @action @async remove: Function,
      default: ->
        moduleName = @collection.delegate.moduleName()
        type = "#{moduleName}::RemovedReportRecord"
        record = yield @collection.find @recordId
        record.type = type
        yield record.save()
        record = yield @collection.find @recordId
        record.reason = @context.request.body.reason
        yield record.save()
        yield return

    @public locksForList: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']

    @public locksForCreate: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']

    @public locksForDetail: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']

    @public locksForUpdate: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']

    @public locksForDelete: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']

    @public locksForQuery: Function,
      default: ->
        read: [
          'auth_migrations', 'auth_users', 'auth_sessions',
          'auth_spaces',
          'auth_roles',
          'auth_space_users', 'auth_sections', 'auth_rules'
        ]
        write: ['auth_sessions']


  SharingLoggedReportsResource.initialize()
