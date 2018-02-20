# TODO: это рекорд лейбла. пользователь или менеджер может создавать неограниченное количество лейблов (на свое усмотрение) и наклеивать их на периоды (для кастомной фильтрации при подсчете статистики)


module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class LabelRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
    @attribute name: String,
      validate: -> joi.string().required()

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


  LabelRecord.initialize()
