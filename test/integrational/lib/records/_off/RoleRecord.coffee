

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class RoleRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
    @attribute name: String,
      validate: -> joi.string().required()
    @attribute title: String,
      validate: -> joi.string().required()
    @attribute description: String,
      validate: -> joi.string().empty(null).default(null)
    @attribute rules: Object

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


  RoleRecord.initialize()
