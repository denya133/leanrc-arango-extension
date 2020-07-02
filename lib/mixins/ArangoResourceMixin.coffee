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

# TODO: этот миксин должен переопределить execute метод ресурса так, чтобы до выполнения открылась транзакция, после получения результата, транзакция должна быть закрыта.
# TODO: потом надо от Resque получить сохраненные в темпе джобы, отрыть новую транзакцию на _queues и _jobs - и сохранить джобы, после чего закрыть транзакцию и послать результат медиатору который его запросил
# TODO: в контексте надо зарезервировать transactionId, чтобы когда понадобтся - им можно было воспользоваться.


{db, errors}  = require '@arangodb'
queues        = require '@arangodb/foxx/queues'

ARANGO_NOT_FOUND  = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code
ARANGO_CONFLICT   = errors.ERROR_ARANGO_CONFLICT.code

module.exports = (Module)->
  {
    AnyT
    FuncG, StructG, ListG, MaybeG
    ContextInterface
    Resource, Mixin
    LogMessage: {  ERROR, DEBUG, LEVELS, SEND_TO_LOG }
    Utils: { _, inflect, assign, statuses }
  } = Module::

  HTTP_NOT_FOUND    = statuses 'not found'
  HTTP_CONFLICT     = statuses 'conflict'

  Module.defineMixin Mixin 'ArangoResourceMixin', (BaseClass = Resource) ->
    class extends BaseClass
      @inheritProtected()

      @public getLocks: FuncG([], StructG {
        read: ListG String
        write: ListG String
      }),
        default: ->
          vrCollectionPrefix = new RegExp "^#{inflect.underscore @Module.name}_"
          vlCollectionNames = db._collections().reduce (alResults, aoCollection) ->
            if vrCollectionPrefix.test name = aoCollection.name()
              alResults.push name unless /migrations$/.test name
            alResults
          , []
          write = vlCollectionNames.concat ['_jobs']
          read = vlCollectionNames.concat ["#{inflect.underscore @Module.name}_migrations", '_aqlfunctions', '_queues', '_jobs']
          return {read, write}

      @public listNonTransactionables: FuncG([], ListG String),
        default: -> ['list', 'detail']

      @public nonPerformExecution: FuncG(ContextInterface, Boolean),
        default: (context)-> not context.isPerformExecution

      @public @async doAction: FuncG([String, ContextInterface], MaybeG AnyT),
        default: (action, context)->
          isTransactionables = action not in @listNonTransactionables()
          locksMethodName = "locksFor#{inflect.camelize action}"
          {read, write} = assign(
            {}
          ,
            @getLocks()
          ,
            (@locksForAny?() ? {})
          ,
            (@[locksMethodName]?() ? {})
          )

          writeTransaction = yield @writeTransaction action, context

          unless @nonPerformExecution context
            @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> PERFORM-EXECUTION OPEN', LEVELS[DEBUG]
            voResult = yield @super action, context
            @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> PERFORM-EXECUTION CLOSE', LEVELS[DEBUG]
            queues._updateQueueDelay()
            yield return voResult

          voResult = null
          voError = null

          try
            if isTransactionables
              @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> TRANSACTION OPEN', LEVELS[DEBUG]
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
                      voError = err
                      error = err
                  if error?
                    throw error
                  else
                    return res
                params: {action, context}
              @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> TRANSACTION CLOSE', LEVELS[DEBUG]
            else
              @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> NON-TRANSACTION OPEN', LEVELS[DEBUG]
              res = null
              error = null
              @super action, context
                .then (data)->
                  res = data
                .catch (err)->
                  voError = err
                  error = err
              if error?
                throw error
              else
                voResult = res
              @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>> NON-TRANSACTION CLOSE', LEVELS[DEBUG]
          catch err
            voError ?= err
          if voError?
            if voError.isArangoError and voError.errorNum is ARANGO_NOT_FOUND
              context.throw HTTP_NOT_FOUND, voError.message, voError.stack
              return
            if voError.isArangoError and voError.errorNum is ARANGO_CONFLICT
              context.throw HTTP_CONFLICT, voError.message, voError.stack
              return
            else if voError.statusCode?
              context.throw voError.statusCode, voError.message, voError.stack
            else
              context.throw 500, voError.message, voError.stack
              return

          queues._updateQueueDelay()
          yield return voResult


      @initializeMixin()
