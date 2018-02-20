

module.exports = (Module)->
  {
    PeriodRecord
    RecordInterface
    Utils: { joi }
  } = Module::

  class ManuallyPeriodRecord extends PeriodRecord
    @inheritProtected()
    @module Module

    # Place for attributes and computeds definitions
    @attribute reason: String,
      validate: -> joi.string().required()

    @hasMany uploadsRelations: RecordInterface,
      transform: -> @Module::PeriodUploadRecord
      inverse: 'periodId'
    @hasMany uploads: RecordInterface,
      transform: -> @Module::UploadRecord
      through: ['uploadsRelations', by: 'uploadId']

    # business logic and before-, after- colbacks
    # TODO: надо запрещать пользователю создавать перекрывающиеся по какоим то признакам мануальные периоды.


  ManuallyPeriodRecord.initialize()
