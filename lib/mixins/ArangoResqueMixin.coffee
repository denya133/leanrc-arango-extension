

_             = require 'lodash'
LeanRC        = require 'LeanRC'
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

  class ArangoResqueMixin extends LeanRC::Mixin
    @inheritProtected()

    @module Module

    @public @async ensureQueue: Function,
      default: (name, concurrency = 1)->
        Queues.create name, concurrency
        yield return {name, concurrency}

    @public @async getQueue: Function,
      default: (name)->
        try
          {maxWorkers:concurrency} = Queues.get name
          yield return {name, concurrency}
        catch e
          yield return

    @public @async removeQueue: Function,
      default: (name)->
        try
          Queues.get name
          Queues.delete name
        yield return

    @public @async allQueues: Function,
      default: ->
        yield return for {_key:name, maxWorkers:concurrency} in db._queues.toArray()
          {name, concurrency}

    @public @async pushJob: Function,
      default: (queueName, scriptName:name, data, delayUntil)->
        queue = @getQueue queueName
        {mount} = module.context
        jobID = queue.push {name, mount}, data, {delayUntil}
        yield return jobID

    @public @async getJob: Function,
      default: (queueName, jobId)->
        queue = @getQueue queueName
        job = queue.get jobId
        yield return job

    @public @async deleteJob: Function,
      default: (queueName, jobId)->
        queue = @getQueue queueName
        isDeleted = queue.delete jobId
        yield return isDeleted

    @public @async abortJob: Function,
      default: (queueName, jobId)->
        queue = @getQueue queueName
        queue.abort jobId
        yield return

    @public @async allJobs: Function,
      default: (queueName, scriptName)->
        queue = @getQueue queueName
        yield return queue.all scriptName

    @public @async pendingJobs: Function,
      default: (queueName, scriptName)->
        queue = @getQueue queueName
        yield return queue.pending scriptName

    @public @async progressJobs: Function,
      default: (queueName, scriptName)->
        queue = @getQueue queueName
        yield return queue.progress scriptName

    @public @async completedJobs: Function,
      default: (queueName, scriptName)->
        queue = @getQueue queueName
        yield return queue.complete scriptName

    @public @async failedJobs: Function,
      default: (queueName, scriptName)->
        queue = @getQueue queueName
        yield return queue.failed scriptName


  ArangoResqueMixin.initialize()
