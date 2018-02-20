# TODO: по аналогии с RemovedPeriodRecord есть смысл сделать ремувед репорт чтобы единичные (залогированны автоматически) репорты можно было переводить в удаленные (чтобы по ним отдельная статистика считалась.)


module.exports = (Module)->
  {
    ReportRecord
    Utils: { joi }
  } = Module::

  class RemovedReportRecord extends ReportRecord
    @inheritProtected()
    @module Module

    # Place for attributes and computeds definitions
    @attribute reason: String,
      validate: -> joi.string().required()

    # business logic and before-, after- colbacks


  RemovedReportRecord.initialize()
