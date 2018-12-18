

module.exports = (Module)->
  {
    Resource
    BodyParseMixin
    QueryableResourceMixin
    ArangoResourceMixin
    EditableResourceMixin
    ModelingResourceMixin
  } = Module::

  class ClientsResource extends Resource
    @inheritProtected()
    @include BodyParseMixin
    @include QueryableResourceMixin
    @include ArangoResourceMixin
    @include EditableResourceMixin
    @include ModelingResourceMixin
    @module Module

    @public entityName: String,
      default: 'client'

    # TODO: надо перепроверить эти хуки
    @initialHook 'checkSchemaVersion'
    @initialHook 'checkApiVersion'
    @initialHook 'systemOnly'
    @initialHook 'parseBody', only: ['create', 'update']

    @beforeHook 'setOwnerId', only: ['create']

    @public locksForList: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']

    @public locksForCreate: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']

    @public locksForDetail: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']

    @public locksForUpdate: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']

    @public locksForDelete: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']

    @public locksForQuery: Function,
      default: ->
        read: ['auth_migrations', 'auth_users', 'auth_sessions']
        write: ['auth_sessions']


    @initialize()
