

module.exports = (Module)->
  {
    Serializer
    HttpSerializerMixin
  } = Module::

  class HttpSerializer extends Serializer
    @inheritProtected()
    @include HttpSerializerMixin
    @module Module


  HttpSerializer.initialize()
