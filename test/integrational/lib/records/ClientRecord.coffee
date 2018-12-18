

module.exports = (Module)->
  {
    ListG
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class ClientRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
    @attribute label: String,
      validate: -> joi.string().required()
    @attribute firstRunAt: Date,
      validate: -> joi.date().iso().required()
    @attribute systemInfo: Object,
      validate: -> joi.object().empty(null).default((->{}), 'by default')
    @attribute screensCount: Number,
      validate: -> joi.number().required().min(1)
    @attribute camsCount: Number,
      validate: -> joi.number().required().min(0)
    @attribute macAddress: String,
      validate: -> joi.string().required()

    @attribute spaces: Array,
      validate: -> joi.array().items joi.string().empty(null).default(null)
    @attribute creatorId: String
    @attribute editorId: String
    @attribute removerId: String
    @attribute ownerId: String

    @hasMany reports: ListG RecordInterface

    @relatedTo creator: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo editor: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo remover: RecordInterface,
      recordName: -> 'UserRecord'
    @relatedTo owner: RecordInterface,
      recordName: -> 'UserRecord'

    # business logic and before-, after- colbacks


    @initialize()
