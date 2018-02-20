

module.exports = (Module)->
  {
    Record
    RelationsMixin
    RecordInterface
    Utils: { joi }
  } = Module::

  class PeriodRecord extends Record
    @inheritProtected()
    @include RelationsMixin
    @module Module

    # Place for attributes and computeds definitions
    @attribute dateSince: Date,
      validate: -> joi.date().iso().required()
    @attribute dateTill: Date,
      validate: -> joi.date().iso().required()

    @attribute customPlaceLabel: String,
      validate: -> joi.string().empty(null).default(null, 'by default')
    @attribute customPlaceAddress: String,
      validate: -> joi.string().empty(null).default(null, 'by default')
    @attribute device: String, # так как и в мануальном и в автоматическом репорте должно быть поле с произвольной строкой. - сервер никак на это не реагирует, т.к. там произвольный текст. - что с++ клиент и веб-клиент решат там хранить, то и будет там.
      validate: -> joi.string().empty(null).default(null, 'by default')

    @attribute taskId: String,
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
    @hasMany labelsRelations: RecordInterface,
      transform: -> @Module::PeriodLabelRecord
      inverse: 'periodId'
    @hasMany labels: RecordInterface,
      transform: -> @Module::LabelRecord
      through: ['labelsRelations', by: 'labelId']

    # business logic and before-, after- colbacks
    # TODO: надо добавить такую проверку, чтобы временные отрезки не пересекались на create хуке.


  PeriodRecord.initialize()
