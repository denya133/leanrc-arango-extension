

module.exports = (Module)->
  {
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

    @hasMany reports: RecordInterface
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
    # business logic and before-, after- colbacks


  ClientRecord.initialize()
