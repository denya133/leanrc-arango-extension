

_             = require 'lodash'
inflect       = do require 'i'
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
    Migration
    Utils: { extend, forEach }
  } = Module::

  Module.defineMixin Migration, (BaseClass) ->
    class ArangoMigrationMixin extends BaseClass
      @inheritProtected()

      @public @async createCollection: Function,
        default: (name, options = {})->
          qualifiedName = @collection.collectionFullName name
          unless db._collection qualifiedName
            db._createDocumentCollection qualifiedName, options
          yield return

      @public @async createEdgeCollection: Function,
        default: (collection_1, collection_2, options = {})->
          qualifiedName = @collection.collectionFullName "#{collection_1}_#{collection_2}"
          unless db._collection qualifiedName
            db._createEdgeCollection qualifiedName, options
          yield return

      @public @async addField: Function,
        default: (collection_name, field_name, options)->
          qualifiedName = @collection.collectionFullName collection_name
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
            db._query "
              FOR doc IN #{qualifiedName}
                UPDATE doc._key WITH {#{field_name}: #{initial}} IN #{qualifiedName}
            "
          yield return

      @public @async addIndex: Function,
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
          db._collection(qualifiedName).ensureIndex opts
          yield return

      @public @async addTimestamps: Function,
        default: (collection_name, options)->
          qualifiedName = @collection.collectionFullName collection_name
          db._query "
            FOR doc IN #{qualifiedName}
              UPDATE doc._key
                WITH {createdAt: null, updatedAt: null, deletedAt: null}
              IN #{qualifiedName}
          "
          yield return

      @public @async changeCollection: Function,
        default: (name, options)->
          qualifiedName = @collection.collectionFullName name
          db._collection(qualifiedName).properties options
          yield return

      @public @async changeField: Function,
        default: (collection_name, field_name, options)->
          {
            json
            binary
            boolean
            date
            datetime
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
          } = Migration::SUPPORTED_TYPES
          typeCast = switch options.type
            when boolean
              "TO_BOOL(doc.#{field_name})"
            when decimal, float, integer
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
          db._query "
            FOR doc IN #{qualifiedName}
              UPDATE doc._key
                WITH {#{field_name}: #{typeCast}}
              IN #{qualifiedName}
          "
          yield return

      @public @async renameField: Function,
        default: (collection_name, field_name, new_field_name)->
          qualifiedName = @collection.collectionFullName collection_name
          db._query "
            FOR doc IN #{qualifiedName}
              LET doc_with_n_field = MERGE(doc, {#{new_field_name}: doc.#{field_name}})
              LET doc_without_o_field = UNSET(doc_with_n_field, '#{field_name}')
              REPLACE doc._key
                WITH doc_without_o_field
              IN #{qualifiedName}
          "
          yield return

      @public @async renameIndex: Function,
        default: (collection_name, old_name, new_name)->
          # not supported in ArangoDB because index has not name
          yield return

      @public @async renameCollection: Function,
        default: (collection_name, old_name, new_name)->
          qualifiedName = @collection.collectionFullName collection_name
          newQualifiedName = @collection.collectionFullName new_name
          db._collection(qualifiedName).rename newQualifiedName
          yield return

      @public @async dropCollection: Function,
        default: (name)->
          qualifiedName = @collection.collectionFullName name
          if db._collection(qualifiedName)?
            db._drop qualifiedName
          yield return

      @public @async dropEdgeCollection: Function,
        default: (collection_1, collection_2)->
          qualifiedName = @collection.collectionFullName "#{collection_1}_#{collection_2}"
          if db._collection(qualifiedName)?
            db._drop qualifiedName
          yield return

      @public @async removeField: Function,
        default: (collection_name, field_name)->
          qualifiedName = @collection.collectionFullName collection_name
          db._query "
            FOR doc IN #{qualifiedName}
              LET doc_without_f = UNSET(doc, '#{field_name}')
              REPLACE doc._key WITH doc_without_f IN #{qualifiedName}
          "
          yield return

      @public @async removeIndex: Function,
        default: (collection_name, field_names, options)->
          qualifiedName = @collection.collectionFullName collection_name
          index = db._collection(qualifiedName).ensureIndex
            type: options.type
            fields: field_names
            unique: options.unique
            sparse: options.sparse
          db._collection(qualifiedName).dropIndex index
          yield return

      @public @async removeTimestamps: Function,
        default: (collection_name, options)->
          qualifiedName = @collection.collectionFullName collection_name
          db._query "
            FOR doc IN #{qualifiedName}
              LET new_doc = UNSET(doc, 'createdAt', 'updatedAt', 'deletedAt')
              REPLACE doc._key WITH new_doc IN #{qualifiedName}
          "
          yield return

      @public customLocks: Function,
        args: []
        return: Object
        default: -> {}

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
          write = vlCollectionNames.concat ['_queues', '_jobs']
          read = vlCollectionNames.concat ["#{inflect.underscore @Module.name}_migrations", '_queues', '_jobs']
          return {read, write}

      @public @async up: Function,
        default: ->
          iplSteps = @constructor.instanceVariables['_steps'].pointer
          {read, write} = extend {}, @getLocks(), @customLocks()
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
          if nonTransactionableSteps.length > 0
            yield forEach nonTransactionableSteps, ({method,args})->
              yield @[method] args...
            , @
          if transactionableSteps.length > 0
            yield db._executeTransaction
              waitForSync: yes
              intermediateCommitSize: 33554432
              collections:
                read: read
                write: write
                allowImplicit: no
              action: @wrap (params)->
                forEach params.steps, ({ method, args }) ->
                  if method is 'reversible'
                    [lambda] = args
                    yield lambda.call @,
                      up: (f)-> f()
                      down: -> Module::Promise.resolve()
                  else
                    yield @[method] args...
                , params.self
              params: {self: @, steps: transactionableSteps}
          yield return

      @public @async down: Function,
        default: ->
          iplSteps = @constructor.instanceVariables['_steps'].pointer
          {read, write} = extend {}, @getLocks(), @customLocks()
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
          if transactionableSteps.length > 0
            yield db._executeTransaction
              waitForSync: yes
              intermediateCommitSize: 33554432
              collections:
                read: read
                write: write
                allowImplicit: no
              action: @wrap (params)->
                forEach params.steps, ({ method, args }) ->
                  if method is 'reversible'
                    [lambda] = args
                    yield lambda.call @,
                      up: -> Module::Promise.resolve()
                      down: (f)-> f()
                  else if method is 'renameField'
                    [collectionName, oldName, newName] = args
                    yield @[method] collectionName, newName, oldName
                  else
                    yield @[Migration::REVERSE_MAP[method]] args...
                , params.self
              params: {self: @, steps: transactionableSteps}
          if nonTransactionableSteps.length > 0
            yield forEach nonTransactionableSteps, ({method,args})->
              if method is 'renameIndex'
                [collectionName, oldName, newName] = args
                yield @[method] collectionName, newName, oldName
              else if method is 'renameCollection'
                [collectionName, newName] = args
                yield @[method] newName, collectionName
              else
                yield @[Migration::REVERSE_MAP[method]] args...
            , @
          yield return


    ArangoMigrationMixin.initializeMixin()
