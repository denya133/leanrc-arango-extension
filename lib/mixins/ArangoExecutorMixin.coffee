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
