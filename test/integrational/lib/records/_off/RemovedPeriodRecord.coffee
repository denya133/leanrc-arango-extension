# TODO: возникла такая идея, что можно `отлогированный` период превратить одним куском в `удаленный` - чтобы и все его репорты считались в отдельную статистику.
# А так как это отдельная сущность и под нее сделаем отдельный ресурс - то можно сделать так, что под эти типы будут отдельные пермишены грантиться.
# TODO: этот период создает и ведет (редактирует) только C++ клиент


module.exports = (Module)->
  {
    PeriodRecord
    RecordInterface
    Utils: { joi }
  } = Module::

  class RemovedPeriodRecord extends PeriodRecord
    @inheritProtected()
    @module Module

    # Place for attributes and computeds definitions
    @attribute reason: String,
      validate: -> joi.string().required()

    @belongsTo client: RecordInterface,
      validate: -> joi.string().required()

    # business logic and before-, after- colbacks


  RemovedPeriodRecord.initialize()
