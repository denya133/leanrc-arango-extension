{ db }        = require '@arangodb'
Queues        = require '@arangodb/foxx/queues'
manifestJson  = require '../manifest.json'
inflect       = do require 'i'


do ->
  moduleName = inflect.underscore manifestJson.name.replace 'leanrc-', ''
  qualifiedName = "#{moduleName}_migrations"

  Queues.create "#{moduleName}__default", 1
  Queues.create "#{moduleName}__signals", 4
  Queues.create "#{moduleName}__delayed_jobs", 4

  unless db._collection qualifiedName
    db._createDocumentCollection qualifiedName, waitForSync: yes

  db._collection(qualifiedName).ensureIndex
    type: 'hash'
    fields: ['id']
    unique: yes
  db._collection(qualifiedName).ensureIndex
    type: 'skiplist'
    fields: ['id']
  db._collection(qualifiedName).ensureIndex
    type: 'hash'
    fields: ['id', 'type']
  db._collection(qualifiedName).ensureIndex
    type: 'hash'
    fields: ['id', 'type', 'isHidden']
  db._collection(qualifiedName).ensureIndex
    type: 'hash'
    fields: ['rev']
  db._collection(qualifiedName).ensureIndex
    type: 'hash'
    fields: ['isHidden']
    sparse: yes
  db._collection(qualifiedName).ensureIndex
    type: 'skiplist'
    fields: ['createdAt']
    sparse: yes
  db._collection(qualifiedName).ensureIndex
    type: 'skiplist'
    fields: ['updatedAt']
    sparse: yes
  db._collection(qualifiedName).ensureIndex
    type: 'skiplist'
    fields: ['deletedAt']
    sparse: yes


module.exports = yes
