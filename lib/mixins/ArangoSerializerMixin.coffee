

module.exports = (Module)->
  { Serializer } = Module::

  Module.defineMixin 'ArangoSerializerMixin', (BaseClass = Serializer) ->
    class extends BaseClass
      @inheritProtected()

      @public @async normalize: Function,
        default: (acRecord, ahPayload)->
          ahPayload.rev = ahPayload._rev
          ahPayload._rev = undefined
          delete ahPayload._rev
          return yield acRecord.normalize ahPayload, @collection

      @public @async serialize: Function,
        default: (aoRecord, options = null)->
          vcRecord = aoRecord.constructor
          serialized = yield vcRecord.serialize aoRecord, options
          serialized.rev = undefined
          serialized._rev = undefined
          delete serialized.rev
          delete serialized._rev
          yield return serialized


      @initializeMixin()
