

module.exports = (Module)->
  {
    Resource
  } = Module::

  Module.defineMixin 'CommonLocksResourceMixin', (BaseClass = Resource) ->
    class extends BaseClass
      @inheritProtected()

      @public locksForAny: Function,
        default: ->
          read: [
            'auth_migrations', 'auth_users', 'auth_sessions',
            'auth_spaces',
            'auth_roles',
            'auth_space_users', 'auth_sections', 'auth_rules'
            'auth_permissions', 'auth_role_permissions'
            'core_migrations'
          ]
          write: ['core_tasks']


      @initializeMixin()
