

module.exports = (Module)->
  {
    AnyT
    FuncG, SubsetG
    RecordInterface
    Serializer, Mixin
  } = Module::

  Module.defineMixin Mixin 'ArangoSerializerMixin', (BaseClass = Serializer) ->
    class extends BaseClass
      @inheritProtected()

      @public @async normalize: FuncG([SubsetG(RecordInterface), AnyT], RecordInterface),
        default: (acRecord, ahPayload)->
          ahPayload.rev = ahPayload._rev
          ahPayload._rev = undefined
          delete ahPayload._rev
          return yield acRecord.normalize ahPayload, @collection

      @public @async serialize: FuncG([RecordInterface, Object], AnyT),
        default: (aoRecord, options = null)->
          vcRecord = aoRecord.constructor
          serialized = yield vcRecord.serialize aoRecord, options
          serialized.rev = undefined
          serialized._rev = undefined
          delete serialized.rev
          delete serialized._rev
          yield return serialized


      @initializeMixin()
