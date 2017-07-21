

module.exports = (Module)->
  Module.defineMixin Module::Serializer, (BaseClass) ->
    class ArangoSerializerMixin extends BaseClass
      @inheritProtected()

      @public normalize: Function,
        default: (acRecord, ahPayload)->
          ahPayload.rev = ahPayload._rev
          ahPayload._rev = undefined
          delete ahPayload._rev
          acRecord.normalize ahPayload, @collection

      @public serialize: Function,
        default: (aoRecord, options = null)->
          vcRecord = aoRecord.constructor
          serialized = vcRecord.serialize aoRecord, options
          serialized.rev = undefined
          serialized._rev = undefined
          delete serialized.rev
          delete serialized._rev
          serialized


    ArangoSerializerMixin.initializeMixin()
