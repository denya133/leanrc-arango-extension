# This file is part of leanrc-arango-extension.
#
# leanrc-arango-extension is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# leanrc-arango-extension is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with leanrc-arango-extension.  If not, see <https://www.gnu.org/licenses/>.

module.exports = (Module)->
  {
    FuncG, StructG, ListG
    Resource, Mixin
  } = Module::

  Module.defineMixin Mixin 'CommonLocksResourceMixin', (BaseClass = Resource) ->
    class extends BaseClass
      @inheritProtected()

      @public locksForAny: FuncG([], StructG {
        read: ListG String
        write: ListG String
      }),
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
