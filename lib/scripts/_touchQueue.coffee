queues        = require '@arangodb/foxx/queues'


module.exports = (FoxxMC)->
  runJob        = require('../utils/runJob') FoxxMC

  FoxxMC::Scripts.touchQueue = ({ROOT, context}={})->
    runJob
      context: context ? module.context
      command: (rawData, jobId) ->
        queues._updateQueueDelay()
    return yes

  FoxxMC::Scripts.touchQueue
