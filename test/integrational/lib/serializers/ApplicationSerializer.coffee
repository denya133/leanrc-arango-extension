

module.exports = (Module)->
  {
    Serializer
    ArangoSerializerMixin
  } = Module::

  class ApplicationSerializer extends Serializer
    @inheritProtected()
    @include ArangoSerializerMixin
    @module Module


    @initialize()
