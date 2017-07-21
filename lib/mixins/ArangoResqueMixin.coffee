

_             = require 'lodash'
inflect       = do require 'i'
{ db }        = require '@arangodb'
Queues        = require '@arangodb/foxx/queues'


###
```coffee
module.exports = (Module)->
  class ApplicationResque extends Module::Resque
    @inheritProtected()
    @include Module::ArangoResqueMixin # в этом миксине должны быть реализованы платформозависимые методы, которые будут посылать нативные запросы к реальной базе данных

    @module Module

  return ApplicationResque.initialize()
```
###


module.exports = (Module)->
  ARANGO_SCRIPT = 'resque_executor'
  Module.defineMixin Module::Resque, (BaseClass) ->
    class ArangoResqueMixin extends BaseClass
      @inheritProtected()

      @public fullQueueName: Function,
        default: (queueName)->
          unless /\_\_/.test queueName
            [ moduleName ] = @moduleName().split '|>'
            queueName = "#{moduleName}__#{queueName}"
          if /\|\>/.test queueName
            queueName = queueName.replace '|>', '__'
          inflect.underscore queueName

      @public @async ensureQueue: Function,
        default: (name, concurrency = 1)->
          name = @fullQueueName name
          Queues.create name, concurrency
          yield return {name, concurrency}

      @public @async getQueue: Function,
        default: (name)->
          name = @fullQueueName name
          try
            {maxWorkers:concurrency} = db._queues.document name
            yield return {name, concurrency}
          catch e
            console.log 'ERROR IN ArangoResqueMixin::getQueue', err.stack
            yield return

      @public @async removeQueue: Function,
        default: (name)->
          name = @fullQueueName name
          try
            Queues.get name
            Queues.delete name
          yield return

      @public @async allQueues: Function,
        default: ->
          queues = for {_key:name, maxWorkers:concurrency} in db._queues.toArray()
            {name, concurrency}
          yield return queues

      @public @async pushJob: Function,
        default: (queueName, scriptName, data, delayUntil)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          {mount} = @Module.context()
          jobID = queue.push {name: ARANGO_SCRIPT, mount}, {scriptName, data}, {delayUntil}
          yield return jobID

      @public @async getJob: Function,
        default: (queueName, jobId)->
          # queueName = @fullQueueName queueName
          # queue = Queues.get queueName
          try job = db._jobs.document jobId
          yield return job ? null

      @public @async deleteJob: Function,
        default: (queueName, jobId)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          isDeleted = queue.delete jobId
          yield return isDeleted

      @public @async abortJob: Function,
        default: (queueName, jobId)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          job = queue.get jobId
          job.abort()
          yield return

      @public @async allJobs: Function,
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            allJobs = queue.all { name: ARANGO_SCRIPT, mount }
              .filter (job) -> job.data.scriptName is scriptName
            yield return allJobs
          else
            yield return queue.all()

      @public @async pendingJobs: Function,
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            pendingJobs = queue.pending { name: ARANGO_SCRIPT, mount }
              .filter (job) -> job.data.scriptName is scriptName
            yield return pendingJobs
          else
            yield return queue.pending()

      @public @async progressJobs: Function,
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            progressJobs = queue.progress { name: ARANGO_SCRIPT, mount }
              .filter (job) -> job.data.scriptName is scriptName
            yield return progressJobs
          else
            yield return queue.progress()

      @public @async completedJobs: Function,
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            completeJobs = queue.complete { name: ARANGO_SCRIPT, mount }
              .filter (job) -> job.data.scriptName is scriptName
            yield return completeJobs
          else
            yield return queue.complete()

      @public @async failedJobs: Function,
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            failedJobs = queue.failed { name: ARANGO_SCRIPT, mount }
              .filter (job) -> job.data.scriptName is scriptName
            yield return failedJobs
          else
            yield return queue.failed()


    ArangoResqueMixin.initializeMixin()
