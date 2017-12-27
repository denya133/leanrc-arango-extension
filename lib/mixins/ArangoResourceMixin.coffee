# TODO: этот миксин должен переопределить execute метод ресурса так, чтобы до выполнения открылась транзакция, после получения результата, транзакция должна быть закрыта.
# TODO: потом надо от Resque получить сохраненные в темпе джобы, отрыть новую транзакцию на _queues и _jobs - и сохранить джобы, после чего закрыть транзакцию и послать результат медиатору который его запросил
# TODO: в контексте надо зарезервировать transactionId, чтобы когда понадобтся - им можно было воспользоваться.


semver        = require 'semver'
{db, errors}  = require '@arangodb'
queues        = require '@arangodb/foxx/queues'

ARANGO_NOT_FOUND  = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code
ARANGO_CONFLICT   = errors.ERROR_ARANGO_CONFLICT.code

module.exports = (Module)->
  {
    Resource
    Utils: { _, inflect, extend, statuses }
  } = Module::

  HTTP_NOT_FOUND    = statuses 'not found'
  HTTP_CONFLICT     = statuses 'conflict'

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
          read = vlCollectionNames.concat ["#{inflect.underscore @Module.name}_migrations", '_queues', '_jobs']
          return {read, write}

      @public listNonTransactionables: Function,
        default: -> ['list', 'detail']

      @public nonPerformExecution: Function,
        default: (context)-> not context.isPerformExecution

      @public @async doAction: Function,
        default: (action, context)->
          isTransactionables = action not in @listNonTransactionables()
          locksMethodName = "locksFor#{inflect.camelize action}"
          {read, write} = extend {}, @getLocks(), (@[locksMethodName]?() ? {})

          writeTransaction = yield @writeTransaction action, context
          unless @nonPerformExecution context
            voResult = yield @super action, context
            queues._updateQueueDelay()
            yield return voResult

          if isTransactionables and writeTransaction
            voResult = db._executeTransaction
              waitForSync: yes
              collections:
                read: read
                write: write
                allowImplicit: no
              action: @wrap (params)->
                res = null
                error = null
                @super params.action, params.context
                  .then (data)->
                    res = data
                  .catch (err)->
                    error = err
                if error?
                  if error.isArangoError and error.errorNum is ARANGO_NOT_FOUND
                    params.context.throw HTTP_NOT_FOUND, error.message
                    return
                  if error.isArangoError and error.errorNum is ARANGO_CONFLICT
                    params.context.throw HTTP_CONFLICT, error.message
                    return
                  else if error.statusCode?
                    params.context.throw error.statusCode, error.message
                  else
                    params.context.throw 500, error.message, error.stack
                    return
                else
                  return res
              params: {action, context}
          else
            voResult = db._executeTransaction
              waitForSync: yes
              collections:
                read: read
                write: write
                allowImplicit: no
              action: @wrap (params)->
                res = null
                error = null
                @super params.action, params.context
                  .then (data)->
                    res = data
                  .catch (err)->
                    error = err
                if error?
                  if error.isArangoError and error.errorNum is ARANGO_NOT_FOUND
                    params.context.throw HTTP_NOT_FOUND, error.message
                    return
                  if error.isArangoError and error.errorNum is ARANGO_CONFLICT
                    params.context.throw HTTP_CONFLICT, error.message
                    return
                  else if error.statusCode?
                    params.context.throw error.statusCode, error.message
                  else
                    params.context.throw 500, error.message, error.stack
                    return
                else
                  return res
              params: {action, context}

          queues._updateQueueDelay()
          yield return voResult


    ArangoResourceMixin.initializeMixin()
