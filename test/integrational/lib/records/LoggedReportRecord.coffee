# TODO: по аналогии с LoggedPeriodRecord есть смысл сделать логгед репорт, чтобы потом реализовать функцию удаления этого единичного репорта. об удаленных детальнее написано в RemovedReportRecord
# TODO: этот период создает и ведет (редактирует) только C++ клиент


module.exports = (Module)->
  {
    ReportRecord
  } = Module::

  class LoggedReportRecord extends ReportRecord
    @inheritProtected()
    @module Module

    # Place for attributes and computeds definitions

    # business logic and before-, after- colbacks


    @initialize()
