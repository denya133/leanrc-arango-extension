# TODO: это рекорд промежуточной связи (таблицы) для многие-ко-многим между лейблами и периодами
# лейблы могут наклеиваться как на автоматически залогированные периоды, так и на удаленные и мануальные.


module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class PeriodLabelRecord extends Record
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
    @belongsTo label: RecordInterface

    # business logic and before-, after- colbacks


  PeriodLabelRecord.initialize()
