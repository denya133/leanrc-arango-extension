# TODO: этот миксин должен переопределить execute метод ресурса так, чтобы до выполнения открылась транзакция, после получения результата, транзакция должна быть закрыта.
# TODO: потом надо от Resque получить сохраненные в темпе джобы, отрыть новую транзакцию на _queues и _jobs - и сохранить джобы, после чего закрыть транзакцию и послать результат медиатору который его запросил
# TODO: в контексте надо зарезервировать transactionId, чтобы когда понадобтся - им можно было воспользоваться.


_             = require 'lodash'
inflect       = do require 'i'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'


module.exports = (Module)->
  Module.defineMixin Module::Resource, (BaseClass) ->
    class ArangoResourceMixin extends BaseClass
      @inheritProtected()

      @public getLocks: Function,
        args: []
        return: Object
        default: ->
          vrCollectionPrefix = new RegExp "^#{inflect.underscore @Module.name}_"
          vlCollectionNames = db._collections().reduce (alResults, aoCollection) ->
            if vrCollectionPrefix.test name = aoCollection.name()
              alResults.push name
            alResults
          , []
          return read: vlCollectionNames, write: vlCollectionNames

      @public listNonTransactionables: Function,
        default: -> ['list', 'detail']

      @public @async doAction: Function, # для того, чтобы отдельная примесь могла переопределить этот метод и обернуть выполнение например в транзакцию
        default: (action, context)->
          needsTransaction = action not in @listNonTransactionables()
          voResult = if needsTransaction and  yield @needsTransaction action, context
            {read, write} = @getLocks()
            self = @
            promise = db._executeTransaction
              waitForSync: yes
              collections:
                read: read
                write: write
                allowImplicit: yes
              action: @wrap (params)->
                params.self.super params.action, params.context
              params: {self, action, context}
            yield promise
          else
            yield @super action, context
          yield return voResult

      @public @async saveDelayeds: Function, # для того, чтобы сохранить все отложенные джобы
        default: (app)->
          self = @
          promise = db._executeTransaction
            waitForSync: yes
            collections:
              write: ['_queues', '_jobs']
              allowImplicit: yes
            action: @wrap (params)->
              params.self.super params.app
            params: {self, app}
          yield promise
          queues._updateQueueDelay()
          yield return


    ArangoResourceMixin.initializeMixin()
