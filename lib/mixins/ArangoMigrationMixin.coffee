

_             = require 'lodash'
inflect       = do require 'i'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'
crypto        = require '@arangodb/crypto'
LeanRC        = require 'LeanRC'



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
  class ArangoMigrationMixin extends LeanRC::Mixin
    @inheritProtected()

    @module Module

    @public @async createCollection: Function,
      default: (name, options)->
        qualifiedName = @collection.collectionFullName name
        unless db._collection qualifiedName
          db._createDocumentCollection qualifiedName, options
        yield return

    @public @async createEdgeCollection: Function,
      default: (collection_1, collection_2, options)->
        qualifiedName = @collection.collectionFullName "#{collection_1}_#{collection_2}"
        unless db._collection qualifiedName
          db._createEdgeCollection qualifiedName, options
        yield return

    @public @async addField: Function,
      default: (collection_name, field_name, options)->
        yield return

    @public @async addIndex: Function,
      args: [String, Array, Object]
      return: NILL
      default: (collection_name, field_names, options)->
        qualifiedName = @collection.collectionFullName collection_name
        db._collection(qualifiedName).ensureIndex
          type: options.type
          fields: field_names
          unique: options.unique
        yield return

    @public @async addTimestamps: Function,
      args: [String, Object]
      return: NILL
      default: ()->
        yield return

    @public @async changeCollection: Function,
      args: [String, Object]
      return: NILL
      default: ()->
        yield return

    @public @async changeField: Function,
      args: [String, String, Object]
      return: NILL
      default: ()->
        yield return

    @public @async renameField: Function,
      args: [String, String, String]
      return: NILL
      default: ()->
        yield return

    @public @async renameIndex: Function,
      args: [String, String, String]
      return: NILL
      default: ()->
        yield return

    @public @async renameCollection: Function,
      args: [String, String, String]
      return: NILL
      default: ()->
        yield return

    @public @async dropCollection: Function,
      args: [String]
      return: NILL
      default: ()->
        yield return

    @public @async dropEdgeCollection: Function,
      args: [String, String]
      return: NILL
      default: ()->
        yield return

    @public @async removeField: Function,
      args: [String, String]
      return: NILL
      default: ()->
        yield return

    @public @async removeIndex: Function,
      args: [String, Array, Object]
      return: NILL
      default: ()->
        yield return

    @public @async removeTimestamps: Function,
      args: [String, Object]
      return: NILL
      default: ()->
        yield return


  ArangoMigrationMixin.initialize()
