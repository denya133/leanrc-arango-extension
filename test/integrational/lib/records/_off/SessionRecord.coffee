

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class SessionRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    @attribute uid: String
    @attribute customData: Object,
      validate: -> joi.object().empty(null).default((->{}), 'by default')
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
    @belongsTo owner: RecordInterface, # `system` only
      validate: -> joi.string().empty(null).default(null)
      transform: -> @Module::UserRecord


  SessionRecord.initialize()
