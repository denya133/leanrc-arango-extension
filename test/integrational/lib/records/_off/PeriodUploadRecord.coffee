# TODO: это рекорд промежуточной связи (таблицы) для многие-ко-многим между мануальными периодами и аплоадами
# это нужно чтобы к мануальным периодам помимо ризона можно было приатачить некоторые файлы


module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class PeriodUploadRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
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
    @belongsTo period: RecordInterface
    @belongsTo upload: RecordInterface

    # business logic and before-, after- colbacks


  PeriodUploadRecord.initialize()
