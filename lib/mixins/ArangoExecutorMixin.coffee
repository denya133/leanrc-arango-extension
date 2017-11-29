# Миксин только для единообразного создания и регистрации в приложении RESQUE_EXECUTOR'а
# но в случае с арангой не надо реализовывать экзекютор, т.к. аранга сама разберется с джобами
queues        = require '@arangodb/foxx/queues'


module.exports = (Module)->
  {
    NILL
    START_RESQUE

    Mediator
  } = Module::

  Module.defineMixin Mediator, (BaseClass) ->
    class ArangoExecutorMixin extends BaseClass
      @inheritProtected()

      @public listNotificationInterests: Function,
        default: -> [
          START_RESQUE
        ]

      @public handleNotification: Function,
        default: (aoNotification)->
          vsName = aoNotification.getName()
          voBody = aoNotification.getBody()
          vsType = aoNotification.getType()
          switch vsName
            when START_RESQUE
              @start()
          return

      @public @async start: Function,
        args: []
        return: NILL
        default: ->
          queues._updateQueueDelay()
          yield return

      @public @async stop: Function,
        args: []
        return: NILL
        default: ->
          yield return


    ArangoExecutorMixin.initializeMixin()
