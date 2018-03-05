

module.exports = (Module)->
  {
    Migration
    ArangoMigrationMixin
  } = Module::

  class BaseMigration extends Migration
    @inheritProtected()
    @include ArangoMigrationMixin
    @module Module


  BaseMigration.initialize()
