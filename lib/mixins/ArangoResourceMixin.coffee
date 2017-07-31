# TODO: этот миксин должен переопределить execute метод ресурса так, чтобы до выполнения открылась транзакция, после получения результата, транзакция должна быть закрыта.
# TODO: потом надо от Resque получить сохраненные в темпе джобы, отрыть новую транзакцию на _queues и _jobs - и сохранить джобы, после чего закрыть транзакцию и послать результат медиатору который его запросил
# TODO: в контексте надо зарезервировать transactionId, чтобы когда понадобтся - им можно было воспользоваться.


_             = require 'lodash'
inflect       = do require 'i'
semver        = require 'semver'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'


module.exports = (Module)->
  {
    Resource
    Utils: { extend }
  } = Module::

  Module.defineMixin Resource, (BaseClass) ->
    class ArangoResourceMixin extends BaseClass
      @inheritProtected()

      @initialHook 'checkDependencies'

      @public checkDependencies: Function,
        args: []
        return: Array
        default: (args...)->
          if (dependencies = @Module.context().manifest.dependencies)?
            for own dependencyName, dependencyDefinition of dependencies
              do ({name, version, required}=dependencyDefinition)=>
                required ?= no
                if required
                  voApp = @Module.context().dependencies[dependencyName]
                  depModuleName = voApp.Module.name
                  depModuleVersion = voApp.Module.context().manifest.version
                  unless semver.satisfies depModuleVersion, version
                    throw new Error "
                      Dependent module #{depModuleName} not compatible.
                      This module required version #{version} but #{depModuleName} version is #{depModuleVersion}.
                    "
                    return
                return
          return args

      @public getLocks: Function,
        args: []
        return: Object
        default: ->
          vrCollectionPrefix = new RegExp "^#{inflect.underscore @Module.name}_"
          vlCollectionNames = db._collections().reduce (alResults, aoCollection) ->
            if vrCollectionPrefix.test name = aoCollection.name()
              alResults.push name unless /migrations$/.test name
            alResults
          , []
          write = vlCollectionNames
          read = ["#{inflect.underscore @Module.name}_migrations"]
          return {read, write}

      @public listNonTransactionables: Function,
        default: -> ['list', 'detail']

      @public nonPerformExecution: Function,
        default: (context)-> not context.isPerformExecution

      @public @async doAction: Function, # для того, чтобы отдельная примесь могла переопределить этот метод и обернуть выполнение например в транзакцию
        default: (action, context)->
          console.log '>>> ArangoResourceMixin::doAction action, context', action, context
          isTransactionables = action not in @listNonTransactionables()
          locksMethodName = "locksFor#{inflect.camelize action}"
          console.log '>>> ArangoResourceMixin::doAction locksMethodName', locksMethodName
          {read, write} = extend {}, @getLocks(), (@[locksMethodName]?() ? {})
          self = @
          console.log '>>> ArangoResourceMixin::doAction {read, write}', {read, write}
          writeTransaction = yield @writeTransaction action, context
          console.log '>>> ArangoResourceMixin::doAction isTransactionables, writeTransaction, @nonPerformExecution context', isTransactionables, writeTransaction, @nonPerformExecution context
          voResult = if @nonPerformExecution context
            if isTransactionables and writeTransaction
              promise = db._executeTransaction
                waitForSync: yes
                collections:
                  read: ["#{inflect.underscore @Module.name}_migrations"]
                  write: write
                  allowImplicit: no
                action: @wrap (params)->
                  params.self.super params.action, params.context
                params: {self, action, context}
              yield promise
            else
              promise = db._executeTransaction
                waitForSync: yes
                collections:
                  read: read
                  allowImplicit: no
                action: @wrap (params)->
                  params.self.super params.action, params.context
                params: {self, action, context}
              yield promise
          else
            yield self.super action, context
          console.log '>>> ArangoResourceMixin::doAction voResult', voResult
          yield return voResult

      @public @async saveDelayeds: Function, # для того, чтобы сохранить все отложенные джобы
        default: (app)->
          self = @
          promise = db._executeTransaction
            waitForSync: yes
            collections:
              write: ['_queues', '_jobs']
              allowImplicit: no
            action: @wrap (params)->
              params.self.super params.app
            params: {self, app}
          yield promise
          queues._updateQueueDelay()
          yield return


    ArangoResourceMixin.initializeMixin()
