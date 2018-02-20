

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class UploadRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    @attribute description: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute attachments: Array,
      validate: -> joi.any().empty(null).default(null)
    @attribute metadata: Object,
      validate: -> joi.any().empty(null).default(null)
    @attribute kind: String,
      validate: ->
        joi.string().allow([
          'image'
          'audio'
          'video'
          'file'
        ]).required()
    @attribute aspectRatio: String,
      validate: -> joi.string().empty(null).default(null)

    @attribute spaces: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @belongsTo creator: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo editor: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo remover: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord
    @belongsTo owner: RecordInterface,
      transform: -> @Module::UserRecord


  UploadRecord.initialize()
