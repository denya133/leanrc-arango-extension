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

# Миксин только для единообразного создания и регистрации в приложении RESQUE_EXECUTOR'а
# но в случае с арангой не надо реализовывать экзекютор, т.к. аранга сама разберется с джобами
queues        = require '@arangodb/foxx/queues'


module.exports = (Module)->
  {
    START_RESQUE
    FuncG
    NotificationInterface
    Mixin
    Mediator
  } = Module::

  Module.defineMixin Mixin 'ArangoExecutorMixin', (BaseClass = Mediator) ->
    class extends BaseClass
      @inheritProtected()

      @public listNotificationInterests: FuncG([], Array),
        default: -> [
          START_RESQUE
        ]

      @public handleNotification: FuncG(NotificationInterface),
        default: (aoNotification)->
          vsName = aoNotification.getName()
          voBody = aoNotification.getBody()
          vsType = aoNotification.getType()
          switch vsName
            when START_RESQUE
              @start()
          return

      @public @async start: Function,
        default: ->
          queues._updateQueueDelay()
          yield return

      @public @async stop: Function,
        default: ->
          yield return


      @initializeMixin()
