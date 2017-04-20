

_             = require 'lodash'
inflect       = do require 'i'
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'
crypto        = require '@arangodb/crypto'
RC            = require 'RC'
LeanRC        = require 'LeanRC'


# здесь (наверху) надо привести пример использования в приложении
###
```coffee
module.exports = (App)->
  class App::CreateUsersCollectionMigration extends LeanRC::Migration
    @inheritProtected()
    @include ArangoExtension::ArangoMigrationMixin # в этом миксине должны быть реализованы платформозависимые методы, которые будут посылать нативные запросы к реальной базе данных

    @Module: App

    @public up: Function,
      default: ->
        @createCollection 'users'
        @addField 'users', name, 'string'
        @addField 'users', description, 'text'
        @addField 'users', createdAt, 'date'
        @addField 'users', updatedAt, 'date'
        @addField 'users', deletedAt, 'date'


    @public down: Function,
      default: ->
        @dropCollection 'users'

  return App::CreateUsersCollectionMigration.initialize()
```
###


module.exports = (ArangoExtension)->
  class ArangoExtension::ArangoMigrationMixin extends RC::Mixin
    @inheritProtected()

    @Module: ArangoExtension


  return ArangoExtension::ArangoMigrationMixin.initialize()
