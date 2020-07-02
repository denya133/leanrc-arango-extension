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

{ db }        = require '@arangodb'


###
```coffee
module.exports = (Module)->
  class CreateUsersCollectionMigration extends Module::Migration
    @inheritProtected()
    @include Module::ArangoMigrationMixin # в этом миксине должны быть реализованы платформозависимые методы, которые будут посылать нативные запросы к реальной базе данных

    @module Module

    @up ->
      yield @createCollection 'users'
      yield @addField 'users', name, 'string'
      yield @addField 'users', description, 'text'
      yield @addField 'users', createdAt, 'date'
      yield @addField 'users', updatedAt, 'date'
      yield @addField 'users', deletedAt, 'date'
      yield return

    @down ->
      yield @dropCollection 'users'
      yield return

  return CreateUsersCollectionMigration.initialize()
```

Это эквивалентно

```coffee
module.exports = (Module)->
  class CreateUsersCollectionMigration extends Module::Migration
    @inheritProtected()
    @include Module::ArangoMigrationMixin # в этом миксине должны быть реализованы платформозависимые методы, которые будут посылать нативные запросы к реальной базе данных

    @module Module

    @change ->
      @createCollection 'users'
      @addField 'users', name, 'string'
      @addField 'users', description, 'text'
      @addField 'users', createdAt, 'date'
      @addField 'users', updatedAt, 'date'
      @addField 'users', deletedAt, 'date'


  return CreateUsersCollectionMigration.initialize()
```
###

# Миксин объявляет реализации для виртуальных методов основного Migration класса
# миксин должен содержать нативный платформозависимый код для обращения к релаьной базе данных на понятном ей языке.

module.exports = (Module)->
  {
    AnyT
    FuncG, ListG, EnumG, MaybeG, UnionG, InterfaceG, StructG
    Migration
    Mixin
    LogMessage: {
      SEND_TO_LOG
      LEVELS
      DEBUG
    }
    Utils: { _, inflect, assign, co, jsonStringify }
  } = Module::

  Module.defineMixin Mixin 'ArangoMigrationMixin', (BaseClass = Migration) ->
    class extends BaseClass
      @inheritProtected()

      { UP, DOWN, SUPPORTED_TYPES } = @::

      @public @async createCollection: FuncG([String, MaybeG Object]),
        default: (name, options = {})->
          qualifiedName = @collection.collectionFullName name
          unless db._collection qualifiedName
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::createCollection qualifiedName = #{qualifiedName}, options = #{jsonStringify options}", LEVELS[DEBUG])
            db._createDocumentCollection qualifiedName, options
          yield return

      @public @async createEdgeCollection: FuncG([String, String, MaybeG Object]),
        default: (collection_1, collection_2, options = {})->
          qualifiedName = @collection.collectionFullName "#{collection_1}_#{collection_2}"
          unless db._collection qualifiedName
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::createEdgeCollection qualifiedName = #{qualifiedName}, options = #{jsonStringify options}", LEVELS[DEBUG])
            db._createEdgeCollection qualifiedName, options
          yield return

      @public @async addField: FuncG([String, String, UnionG(
        EnumG SUPPORTED_TYPES
        InterfaceG {
          type: EnumG SUPPORTED_TYPES
          default: AnyT
        }
      )]),
        default: (collection_name, field_name, options)->
          qualifiedName = @collection.collectionFullName collection_name
          if _.isString options
            yield return
          if options.default?
            if _.isNumber(options.default) or _.isBoolean(options.default)
              initial = options.default
            else if _.isDate options.default
              initial = options.default.toISOString()
            else if _.isString options.default
              initial = "'#{options.default}'"
            else if _.isPlainObject options.default
              initial = JSON.stringify options.default
            else if _.isArray options.default
              initial = JSON.stringify options.default
            else
              initial = null
          else
            initial = null
          if initial?
            vsQuery = "
              FOR doc IN #{qualifiedName}
                UPDATE doc._key WITH {#{field_name}: #{initial}} IN #{qualifiedName}
            "
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::addField vsQuery #{vsQuery}", LEVELS[DEBUG])
            db._query vsQuery
          yield return

      @public @async addIndex: FuncG([String, ListG(String), InterfaceG {
        type: EnumG 'hash', 'skiplist', 'persistent', 'geo', 'fulltext'
        unique: MaybeG Boolean
        sparse: MaybeG Boolean
      }]),
        default: (collection_name, field_names, options)->
          # TODO; fulltext индекс вызывает ошибку в аранге - надо дебажить
          qualifiedName = @collection.collectionFullName collection_name
          opts =
            type: options.type ? 'hash'
            fields: field_names ? []
          if opts.type is 'fulltext'
            opts.minLength = 3
          else
            opts.unique = options.unique ? no
            opts.sparse = options.sparse ? no
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::addIndex opts #{jsonStringify opts}", LEVELS[DEBUG])
          db._collection(qualifiedName).ensureIndex opts
          yield return

      @public @async addTimestamps: FuncG([String, MaybeG Object]),
        default: (collection_name, options = {})->
          # NOTE: нет смысла выполнять запрос, т.к. в addField есть проверка if initial? и если null, то атрибут не добавляется
          yield return

      @public @async changeCollection: FuncG([String, Object]),
        default: (name, options)->
          qualifiedName = @collection.collectionFullName name
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::changeCollection qualifiedName = #{qualifiedName}, options = #{jsonStringify options}", LEVELS[DEBUG])
          db._collection(qualifiedName).properties options
          yield return

      @public @async changeField: FuncG([String, String, UnionG(
        EnumG SUPPORTED_TYPES
        InterfaceG {
          type: EnumG SUPPORTED_TYPES
        }
      )]),
        default: (collection_name, field_name, options)->
          {
            json
            binary
            boolean
            date
            datetime
            number
            decimal
            float
            integer
            primary_key
            string
            text
            time
            timestamp
            array
            hash
          } = SUPPORTED_TYPES
          type = if _.isString options
            options
          else
            options.type
          typeCast = switch type
            when boolean
              "TO_BOOL(doc.#{field_name})"
            when decimal, float, integer, number
              "TO_NUMBER(doc.#{field_name})"
            when string, text, primary_key, binary
              "TO_STRING(JSON_STRINGIFY(doc.#{field_name}))"
            when array
              "TO_ARRAY(doc.#{field_name})"
            when json, hash
              "JSON_PARSE(TO_STRING(doc.#{field_name}))"
            when date, datetime
              "DATE_ISO8601(doc.#{field_name})"
            when time, timestamp
              "DATE_TIMESTAMP(doc.#{field_name})"
          qualifiedName = @collection.collectionFullName collection_name
          vsQuery = "
            FOR doc IN #{qualifiedName}
              UPDATE doc._key
                WITH {#{field_name}: #{typeCast}}
              IN #{qualifiedName}
          "
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::changeField vsQuery #{vsQuery}", LEVELS[DEBUG])
          db._query vsQuery
          yield return

      @public @async renameField: FuncG([String, String, String]),
        default: (collection_name, field_name, new_field_name)->
          qualifiedName = @collection.collectionFullName collection_name
          vsQuery = "
            FOR doc IN #{qualifiedName}
              LET doc_with_n_field = MERGE(doc, {#{new_field_name}: doc.#{field_name}})
              LET doc_without_o_field = UNSET(doc_with_n_field, '#{field_name}')
              REPLACE doc._key
                WITH doc_without_o_field
              IN #{qualifiedName}
          "
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::renameField vsQuery #{vsQuery}", LEVELS[DEBUG])
          db._query vsQuery
          yield return

      @public @async renameIndex: FuncG([String, String, String]),
        default: (collection_name, old_name, new_name)->
          # not supported in ArangoDB because index has not name
          yield return

      @public @async renameCollection: FuncG([String, String]),
        default: (collectionName, newCollectionName)->
          qualifiedName = @collection.collectionFullName collectionName
          newQualifiedName = @collection.collectionFullName newCollectionName
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::renameCollection qualifiedName, newQualifiedName = #{qualifiedName}, #{newQualifiedName}", LEVELS[DEBUG])
          db._collection(qualifiedName).rename newQualifiedName
          yield return

      @public @async dropCollection: FuncG(String),
        default: (name)->
          qualifiedName = @collection.collectionFullName name
          if db._collection(qualifiedName)?
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::dropCollection qualifiedName = #{qualifiedName}", LEVELS[DEBUG])
            db._drop qualifiedName
          yield return

      @public @async dropEdgeCollection: FuncG([String, String]),
        default: (collection_1, collection_2)->
          qualifiedName = @collection.collectionFullName "#{collection_1}_#{collection_2}"
          if db._collection(qualifiedName)?
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::dropEdgeCollection qualifiedName = #{qualifiedName}", LEVELS[DEBUG])
            db._drop qualifiedName
          yield return

      @public @async removeField: FuncG([String, String]),
        default: (collection_name, field_name)->
          qualifiedName = @collection.collectionFullName collection_name
          vsQuery = "
            FOR doc IN #{qualifiedName}
              LET doc_without_f = UNSET(doc, '#{field_name}')
              REPLACE doc._key WITH doc_without_f IN #{qualifiedName}
          "
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::removeField vsQuery #{vsQuery}", LEVELS[DEBUG])
          db._query vsQuery
          yield return

      @public @async removeIndex: FuncG([String, ListG(String), InterfaceG {
        type: EnumG 'hash', 'skiplist', 'persistent', 'geo', 'fulltext'
        unique: MaybeG Boolean
        sparse: MaybeG Boolean
      }]),
        default: (collection_name, field_names, options)->
          qualifiedName = @collection.collectionFullName collection_name
          opts =
            type: options.type ? 'hash'
            fields: field_names ? []
          if opts.type is 'fulltext'
            opts.minLength = 3
          else
            opts.unique = options.unique ? no
            opts.sparse = options.sparse ? no

          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::removeIndex opts #{jsonStringify opts}", LEVELS[DEBUG])
          index = null
          db._collection(qualifiedName).getIndexes().forEach (item)->
            if (
              _.isEqual(item.fields, opts.fields) and
              item.type is opts.type and
              item.unique is opts.unique and
              item.sparse is opts.sparse
            )
              index = item
          if index?
            @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::removeIndex index #{jsonStringify index}", LEVELS[DEBUG])
            db._collection(qualifiedName).dropIndex index
          yield return

      @public @async removeTimestamps: FuncG([String, MaybeG Object]),
        default: (collection_name, options = {})->
          qualifiedName = @collection.collectionFullName collection_name
          vsQuery = "
            FOR doc IN #{qualifiedName}
              LET new_doc = UNSET(doc, 'createdAt', 'updatedAt', 'deletedAt')
              REPLACE doc._key WITH new_doc IN #{qualifiedName}
          "
          @collection.sendNotification(SEND_TO_LOG, "ArangoMigrationMixin::removeTimestamps vsQuery #{vsQuery}", LEVELS[DEBUG])
          db._query vsQuery
          yield return

      @public customLocks: FuncG([], Object),
        default: -> {}

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
          write = vlCollectionNames
          read = vlCollectionNames.concat ["#{inflect.underscore @Module.name}_migrations", '_queues', '_jobs']
          return {read, write}

      @public @async up: Function,
        default: ->
          iplSteps = @constructor.instanceVariables['_steps'].pointer
          {read, write} = assign {}, @getLocks(), @customLocks()
          steps = @[iplSteps]?[..] ? []
          [
            nonTransactionableSteps
            transactionableSteps
          ] = steps.reduce (prev, current)->
            [nonTrans, trans] = prev
            if current.method in [
              'createCollection'
              'createEdgeCollection'
              'addIndex'
              'removeIndex'
              'changeCollection'
              'renameIndex'
              'renameCollection'
              'dropCollection'
              'dropEdgeCollection'
            ]
              nonTrans.push current
            else
              trans.push current
            [nonTrans, trans]
          , [[], []]
          self = @
          if nonTransactionableSteps.length > 0
            for {method,args} in nonTransactionableSteps
              yield self[method] args...

            # yield forEach nonTransactionableSteps, ({method,args})->
            #   yield @[method] args...
            # , @
          if transactionableSteps.length > 0
            yield db._executeTransaction
              waitForSync: yes
              intermediateCommitSize: 33554432
              collections:
                read: read
                write: write
                allowImplicit: no
              action: co.wrap (params)->
                for { method, args } in params.steps
                  if method is 'reversible'
                    [lambda] = args
                    yield lambda.call self,
                      up: (f)-> f()
                      down: -> Module::Promise.resolve()
                  else
                    yield self[method] args...
                yield return

              params: {steps: transactionableSteps}

              # action: @wrap (params)->
              #   forEach params.steps, ({ method, args }) ->
              #     if method is 'reversible'
              #       [lambda] = args
              #       yield lambda.call @,
              #         up: (f)-> f()
              #         down: -> Module::Promise.resolve()
              #     else
              #       yield @[method] args...
              #   , params.self
              # params: {self: @, steps: transactionableSteps}
          yield return

      @public @async down: Function,
        default: ->
          iplSteps = @constructor.instanceVariables['_steps'].pointer
          {read, write} = assign {}, @getLocks(), @customLocks()
          steps = @[iplSteps]?[..] ? []
          steps.reverse()
          [
            transactionableSteps
            nonTransactionableSteps
          ] = steps.reduce (prev, current)->
            [trans, nonTrans] = prev
            if current.method in [
              'createCollection'
              'createEdgeCollection'
              'addIndex'
              'removeIndex'
              'changeCollection'
              'renameIndex'
              'renameCollection'
              'dropCollection'
              'dropEdgeCollection'
            ]
              nonTrans.push current
            else
              trans.push current
            [trans, nonTrans]
          , [[], []]
          self = @
          if transactionableSteps.length > 0
            yield db._executeTransaction
              waitForSync: yes
              intermediateCommitSize: 33554432
              collections:
                read: read
                write: write
                allowImplicit: no
              action: co.wrap (params)->
                for { method, args } in params.steps
                  if method is 'reversible'
                    [lambda] = args
                    yield lambda.call self,
                      up: -> Module::Promise.resolve()
                      down: (f)-> f()
                  else if method is 'renameField'
                    [collectionName, oldName, newName] = args
                    yield self[method] collectionName, newName, oldName
                  else
                    yield self[Migration::REVERSE_MAP[method]] args...
                yield return
              params: {steps: transactionableSteps}

              # action: @wrap (params)->
              #   forEach params.steps, ({ method, args }) ->
              #     if method is 'reversible'
              #       [lambda] = args
              #       yield lambda.call @,
              #         up: -> Module::Promise.resolve()
              #         down: (f)-> f()
              #     else if method is 'renameField'
              #       [collectionName, oldName, newName] = args
              #       yield @[method] collectionName, newName, oldName
              #     else
              #       yield @[Migration::REVERSE_MAP[method]] args...
              #   , params.self
              # params: {self: @, steps: transactionableSteps}
          if nonTransactionableSteps.length > 0
            for {method,args} in nonTransactionableSteps
              if method is 'renameIndex'
                [collectionName, oldName, newName] = args
                yield @[method] collectionName, newName, oldName
              else if method is 'renameCollection'
                [collectionName, newName] = args
                yield @[method] newName, collectionName
              else
                yield @[Migration::REVERSE_MAP[method]] args...

            # yield forEach nonTransactionableSteps, ({method,args})->
            #   if method is 'renameIndex'
            #     [collectionName, oldName, newName] = args
            #     yield @[method] collectionName, newName, oldName
            #   else if method is 'renameCollection'
            #     [collectionName, newName] = args
            #     yield @[method] newName, collectionName
            #   else
            #     yield @[Migration::REVERSE_MAP[method]] args...
            # , @
          yield return


      @initializeMixin()
