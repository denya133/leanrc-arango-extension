

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi, uuid }
  } = Module::

  class SpaceRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    @attribute name: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute shortName: String,
      validate: ->
        joi.string().empty(null).default(uuid.v4, 'by default')
    @attribute description: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute kind: String,
      validate: -> joi.string().empty(null).default('custom', 'by default')

    @attribute entityId: String,
      validate: -> joi.string().required()
    @belongsTo image: RecordInterface,
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UploadRecord
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


  SpaceRecord.initialize()
