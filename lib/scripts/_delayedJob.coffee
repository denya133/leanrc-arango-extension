# TODO: эту штуку надо привести к виду абстрактного скрипта - только для аранги, который внутри будет ицициализировать приложение, и посылвать к фасаду сообщение через sendNotification чтобы это приложение отработало фоновую задачу.
# это выглядит именно так изза специфики работы фоновых скриптов в аранге.
# а конкретно этот скрипт - как бы враппер.
# TODO: возможно этот скрипт должен генерировать генератор в составе CLI при создании приложения.

_             = require 'lodash'
joi           = require 'joi'
inflect       = require('i')()
{ db }        = require '@arangodb'
queues        = require '@arangodb/foxx/queues'


dataSchema =  joi.object(
  moduleName: joi.string().required()
  className:  joi.string().required()
  id:         joi.string().empty(null)
  methodName: joi.string().required()
  args:       joi.array().items(joi.any())
)

###
{

}
###
module.exports = (FoxxMC)->
  runJob        = require('../utils/runJob') FoxxMC

  FoxxMC::Scripts.delayedJob = ({ROOT, context}={})->
    require "#{ROOT}index"
    runJob
      context: context ? module.context
      command: (rawData, jobId) ->
        {value:data} = dataSchema.validate rawData

        Class = classes[data.moduleName]::[data.className]
        methodNameForLocks = if data.id?
          ['.find', "::#{data.methodName}"]
        else
          ".#{data.methodName}"
        {read, write} = Class.getLocksFor methodNameForLocks

        db._executeTransaction
          collections:
            read: read
            write: write
            allowImplicit: no
          action: (params) ->
            do (
              {
                moduleName
                className
                id
                methodName
                args
              }       = params
            ) ->
              LocalClass = classes[moduleName]::[className]
              if id?
                record = LocalClass.find id
                record[methodName]? args...
              else
                LocalClass[methodName]? args...
              return

          params:
            moduleName: data.moduleName
            className:  data.className
            id:         data.id
            methodName: data.methodName
            args:       data.args

        queues._updateQueueDelay()


  FoxxMC::Scripts.delayedJob
