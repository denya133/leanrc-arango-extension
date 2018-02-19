

module.exports = (Module)->
  {
    Collection
    QueryableCollectionMixin
    ArangoCollectionMixin
  } = Module::

  class MigrationsCollection extends Collection
    @inheritProtected()
    @include QueryableCollectionMixin
    @include ArangoCollectionMixin
    @module Module


  MigrationsCollection.initialize()
