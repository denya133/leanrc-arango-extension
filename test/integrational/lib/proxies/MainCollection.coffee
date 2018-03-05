

module.exports = (Module)->
  {
    Collection
    QueryableCollectionMixin
    ArangoCollectionMixin
    IterableMixin
    GenerateUuidIdMixin
  } = Module::

  class MainCollection extends Collection
    @inheritProtected()
    @include QueryableCollectionMixin
    @include ArangoCollectionMixin
    @include IterableMixin
    @include GenerateUuidIdMixin
    @module Module


  MainCollection.initialize()
