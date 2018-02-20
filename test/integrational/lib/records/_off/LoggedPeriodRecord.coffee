# TODO: этот период создает и ведет (редактирует) только C++ клиент


module.exports = (Module)->
  {
    PeriodRecord
    RecordInterface
    Utils: { joi }
  } = Module::

  class LoggedPeriodRecord extends PeriodRecord
    @inheritProtected()
    @module Module

    # Place for attributes and computeds definitions

    @belongsTo client: RecordInterface,
      validate: -> joi.string().required()

    # business logic and before-, after- colbacks


  LoggedPeriodRecord.initialize()
