{ db }        = require '@arangodb'
manifestJson  = require '../manifest.json'
inflect       = do require 'i'
Queues        = require '@arangodb/foxx/queues'


moduleName = inflect.underscore manifestJson.name.replace 'leanrc-', ''
vrPrefix = new RegExp "^#{moduleName}_"
vlCollectionNames = db._collections().reduce (alResults, aoCollection) ->
  if vrPrefix.test name = aoCollection.name()
    alResults.push name
  alResults
, []

vlCollectionNames.forEach (qualifiedName)->
  if db._collection qualifiedName
    db._drop qualifiedName

vlQueueNames = db._collection('_queues').toArray().reduce (alResults, aoDoc) ->
  if vrPrefix.test name = aoDoc._key
    alResults.push name
  alResults
, []

vlQueueNames.forEach (queueName)->
  Queues.delete queueName


module.exports = yes
