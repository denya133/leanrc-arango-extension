

{ db }        = require '@arangodb'
Queues        = require '@arangodb/foxx/queues'
internal      = require 'internal'
{ flatten }   = internal


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
  {
    AnyT
    FuncG, ListG, StructG, MaybeG, UnionG
    Resque, Mixin
    Utils: { _, inflect }
  } = Module::

  ARANGO_SCRIPT = 'resque_executor'

  Module.defineMixin Mixin 'ArangoResqueMixin', (BaseClass = Resque) ->
    class extends BaseClass
      @inheritProtected()

      @public fullQueueName: FuncG(String, String),
        default: (queueName)->
          unless /\_\_/.test queueName
            [ moduleName ] = @moduleName().split '|>'
            queueName = "#{moduleName}__#{queueName}"
          if /\|\>/.test queueName
            queueName = queueName.replace '|>', '__'
          inflect.underscore queueName

      @public @async ensureQueue: FuncG([String, MaybeG Number], StructG name: String, concurrency: Number),
        default: (name, concurrency = 1)->
          name = @fullQueueName name
          Queues.create name, concurrency
          yield return {name, concurrency}

      @public @async getQueue: FuncG(String, MaybeG StructG name: String, concurrency: Number),
        default: (name)->
          name = @fullQueueName name
          try
            {maxWorkers:concurrency} = db._queues.document name
            yield return {name, concurrency}
          catch err
            console.log 'ERROR IN ArangoResqueMixin::getQueue', err.stack
            yield return

      @public @async removeQueue: FuncG(String),
        default: (name)->
          name = @fullQueueName name
          try
            internal.deleteQueue name
          yield return

      @public @async allQueues: FuncG([], ListG StructG name: String, concurrency: Number),
        default: ->
          queues = for {_key:name, maxWorkers:concurrency} in db._queues.toArray()
            {name, concurrency}
          yield return queues

      @public @async pushJob: FuncG([String, String, AnyT, MaybeG Number], UnionG String, Number),
        default: (queueName, scriptName, data, delayUntil)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          {mount} = @Module.context()
          jobID = queue.push {name: ARANGO_SCRIPT, mount}, {scriptName, data}, {delayUntil}
          yield return jobID

      @public @async getJob: FuncG([String, UnionG String, Number], MaybeG Object),
        default: (queueName, jobId)->
          # queueName = @fullQueueName queueName
          # queue = Queues.get queueName
          try job = db._jobs.document jobId
          yield return job ? null

      @public @async deleteJob: FuncG([String, UnionG String, Number], Boolean),
        default: (queueName, jobId)->
          # queueName = @fullQueueName queueName
          # queue = Queues.get queueName
          # isDeleted = queue.delete jobId
          isDeleted = try
            db._jobs.remove jobId
            yes
          catch err
            no
          yield return isDeleted

      @public @async abortJob: FuncG([String, UnionG String, Number]),
        default: (queueName, jobId)->
          # queueName = @fullQueueName queueName
          # queue = Queues.get queueName
          # job = queue.get jobId
          # job.abort()
          job = db._jobs.document jobId
          if job.status isnt 'completed'
            job.failures.push flatten new Error 'Job aborted.'
            db._jobs.update job, {
              status: 'failed'
              modified: Date.now()
              failures: job.failures
            }
          yield return

      @public @async allJobs: FuncG([String, MaybeG String], ListG Object),
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            allJobs = queue.all { name: ARANGO_SCRIPT, mount }
              .map (jobId) -> queue.get jobId
              .filter (job) -> job.data.scriptName is scriptName
            yield return allJobs
          else
            yield return queue.all().map (jobId) -> queue.get jobId

      @public @async pendingJobs: FuncG([String, MaybeG String], ListG Object),
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            pendingJobs = queue.pending { name: ARANGO_SCRIPT, mount }
              .map (jobId) -> queue.get jobId
              .filter (job) -> job.data.scriptName is scriptName
            yield return pendingJobs
          else
            yield return queue.pending().map (jobId) -> queue.get jobId

      @public @async progressJobs: FuncG([String, MaybeG String], ListG Object),
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            progressJobs = queue.progress { name: ARANGO_SCRIPT, mount }
              .map (jobId) -> queue.get jobId
              .filter (job) -> job.data.scriptName is scriptName
            yield return progressJobs
          else
            yield return queue.progress().map (jobId) -> queue.get jobId

      @public @async completedJobs: FuncG([String, MaybeG String], ListG Object),
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            completeJobs = queue.complete { name: ARANGO_SCRIPT, mount }
              .map (jobId) -> queue.get jobId
              .filter (job) -> job.data.scriptName is scriptName
            yield return completeJobs
          else
            yield return queue.complete().map (jobId) -> queue.get jobId

      @public @async failedJobs: FuncG([String, MaybeG String], ListG Object),
        default: (queueName, scriptName)->
          queueName = @fullQueueName queueName
          queue = Queues.get queueName
          if scriptName?
            { mount } = @Module.context()
            failedJobs = queue.failed { name: ARANGO_SCRIPT, mount }
              .map (jobId) -> queue.get jobId
              .filter (job) -> job.data.scriptName is scriptName
            yield return failedJobs
          else
            yield return queue.failed().map (jobId) -> queue.get jobId


      @initializeMixin()
