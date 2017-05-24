{ db }  = require '@arangodb'
qb      = require 'aqb'

{ expect, assert }  = require 'chai'
sinon               = require 'sinon'
_                   = require 'lodash'
moment              = require 'moment'

LeanRC              = require 'LeanRC'

ArangoExtension = require '../../..'
{ co }          = LeanRC::Utils

###
commonServerInitializer = require.main.require 'test/common/server'
server = commonServerInitializer fixture: 'ArangoCollectionMixin'
###

describe 'ArangoCollectionMixin', ->
  before ->
    collection = db._create 'test_samples'
    date = new Date()
    collection.save id: 1, data: 'three', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 2, data: 'men', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 3, data: 'in', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 4, data: 'a boat', createdAt: date, updatedAt: date
  after ->
    db._drop 'test_samples'
  describe '.new', ->
    it 'should create ArangoDB collection instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        assert.instanceOf collection, ArangoCollection
        yield return
  describe '#operatorsMap', ->
    it 'should get full operators map', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        { operatorsMap } = collection

        assert.isFunction operatorsMap['$and']
        assert.isFunction operatorsMap['$or']
        assert.isFunction operatorsMap['$not']
        assert.isFunction operatorsMap['$nor']

        assert.isFunction operatorsMap['$eq']
        assert.isFunction operatorsMap['$ne']
        assert.isFunction operatorsMap['$lt']
        assert.isFunction operatorsMap['$lte']
        assert.isFunction operatorsMap['$gt']
        assert.isFunction operatorsMap['$gte']
        assert.isFunction operatorsMap['$in']
        assert.isFunction operatorsMap['$nin']

        assert.isFunction operatorsMap['$all']
        assert.isFunction operatorsMap['$elemMatch']
        assert.isFunction operatorsMap['$size']

        assert.isFunction operatorsMap['$exists']
        assert.isFunction operatorsMap['$type']

        assert.isFunction operatorsMap['$mod']
        assert.isFunction operatorsMap['$regex']

        assert.isFunction operatorsMap['$td']
        assert.isFunction operatorsMap['$ld']
        assert.isFunction operatorsMap['$tw']
        assert.isFunction operatorsMap['$lw']
        assert.isFunction operatorsMap['$tm']
        assert.isFunction operatorsMap['$lm']
        assert.isFunction operatorsMap['$ty']
        assert.isFunction operatorsMap['$ly']

        logicalOperator = operatorsMap['$and'] 'a', 'b', 'c'
        assert.deepEqual logicalOperator, qb.and 'a', 'b', 'c'
        logicalOperator = operatorsMap['$or'] 'a', 'b', 'c'
        assert.deepEqual logicalOperator, qb.or 'a', 'b', 'c'
        logicalOperator = operatorsMap['$not'] 'a', 'b', 'c'
        assert.deepEqual logicalOperator, qb.not 'a', 'b', 'c'
        logicalOperator = operatorsMap['$nor'] 'a', 'b', 'c'
        assert.deepEqual logicalOperator, qb.not qb.or 'a', 'b', 'c'

        compOperator = operatorsMap['$eq'] 'a', 'b'
        assert.deepEqual compOperator, qb.eq qb('a'), qb('b')
        compOperator = operatorsMap['$eq'] 'a', '@b'
        assert.deepEqual compOperator, qb.eq qb('a'), qb.ref('b')
        compOperator = operatorsMap['$ne'] 'a', 'b'
        assert.deepEqual compOperator, qb.neq qb('a'), qb('b')
        compOperator = operatorsMap['$ne'] 'a', '@b'
        assert.deepEqual compOperator, qb.neq qb('a'), qb.ref('b')
        compOperator = operatorsMap['$lt'] 'a', 'b'
        assert.deepEqual compOperator, qb.lt qb('a'), qb('b')
        compOperator = operatorsMap['$lt'] 'a', '@b'
        assert.deepEqual compOperator, qb.lt qb('a'), qb.ref('b')
        compOperator = operatorsMap['$lte'] 'a', 'b'
        assert.deepEqual compOperator, qb.lte qb('a'), qb('b')
        compOperator = operatorsMap['$lte'] 'a', '@b'
        assert.deepEqual compOperator, qb.lte qb('a'), qb.ref('b')
        compOperator = operatorsMap['$gt'] 'a', 'b'
        assert.deepEqual compOperator, qb.gt qb('a'), qb('b')
        compOperator = operatorsMap['$gt'] 'a', '@b'
        assert.deepEqual compOperator, qb.gt qb('a'), qb.ref('b')
        compOperator = operatorsMap['$gte'] 'a', 'b'
        assert.deepEqual compOperator, qb.gte qb('a'), qb('b')
        compOperator = operatorsMap['$gte'] 'a', '@b'
        assert.deepEqual compOperator, qb.gte qb('a'), qb.ref('b')
        compOperator = operatorsMap['$in'] 'a', 'b'
        assert.deepEqual compOperator, qb.in qb('a'), qb('b')
        compOperator = operatorsMap['$in'] '@a', 'b'
        assert.deepEqual compOperator, qb.in qb.ref('a'), qb('b')
        compOperator = operatorsMap['$nin'] 'a', 'b'
        assert.deepEqual compOperator, qb.notIn qb('a'), qb('b')
        compOperator = operatorsMap['$nin'] '@a', 'b'
        assert.deepEqual compOperator, qb.notIn qb.ref('a'), qb('b')

        queryOperator = operatorsMap['$all'] 'a', ['b', 'c', 'd']
        assert.deepEqual queryOperator, qb.and [
          qb.in qb('b'), qb('a')
          qb.in qb('c'), qb('a')
          qb.in qb('d'), qb('a')
        ]
        queryOperator = operatorsMap['$elemMatch'] '@a', ['b', 'c', 'd']
        assert.deepEqual queryOperator
        , qb.gt qb.expr('LENGTH(a[* FILTER b && c && d])'), qb 0
        queryOperator = operatorsMap['$size'] '@a', 'b'
        assert.deepEqual queryOperator, qb.eq qb.expr('LENGTH(a)'), qb('b')
        queryOperator = operatorsMap['$size'] '@a', '@b'
        assert.deepEqual queryOperator, qb.eq qb.expr('LENGTH(a)'), qb.ref('b')

        queryOperator = operatorsMap['$exists'] '@a', 'b'
        assert.deepEqual queryOperator, qb.eq qb.expr('HAS(a)'), qb('b')
        queryOperator = operatorsMap['$exists'] '@a', '@b'
        assert.deepEqual queryOperator, qb.eq qb.expr('HAS(a)'), qb.ref('b')
        queryOperator = operatorsMap['$type'] '@a', 'b'
        assert.deepEqual queryOperator, qb.eq qb.expr('TYPENAME(a)'), qb('b')
        queryOperator = operatorsMap['$type'] '@a', '@b'
        assert.deepEqual queryOperator, qb.eq qb.expr('TYPENAME(a)'), qb.ref('b')

        queryOperator = operatorsMap['$mod'] '@a', ['b', 'c']
        assert.deepEqual queryOperator, qb.eq qb.mod(qb.ref('a'), qb('b')), qb 'c'
        queryOperator = operatorsMap['$mod'] 'a', ['b', 'c']
        assert.deepEqual queryOperator, qb.eq qb.mod(qb('a'), qb('b')), qb 'c'
        queryOperator = operatorsMap['$regex'] '@a', 'b'
        assert.deepEqual queryOperator, qb.expr 'REGEX_TEST(a, "b")'
        queryOperator = operatorsMap['$regex'] 'a', 'b'
        assert.deepEqual queryOperator, qb.expr 'REGEX_TEST(a, "b")'

        date = new Date()

        todayStart = moment().startOf('day').toISOString()
        todayEnd = moment().endOf('day').toISOString()
        queryOperator = operatorsMap['$td'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb todayStart), qb.lt(qb(date), qb todayEnd)
        queryOperator = operatorsMap['$td'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb todayStart), qb.lt(qb(date), qb todayEnd)

        yesterdayStart = moment().subtract(1, 'days').startOf('day').toISOString()
        yesterdayEnd = moment().subtract(1, 'days').endOf('day').toISOString()
        queryOperator = operatorsMap['$ld'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb yesterdayStart), qb.lt(qb(date), qb yesterdayEnd)
        queryOperator = operatorsMap['$ld'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb yesterdayStart), qb.lt(qb(date), qb yesterdayEnd)

        weekStart = moment().startOf('week').toISOString()
        weekEnd = moment().endOf('week').toISOString()
        queryOperator = operatorsMap['$tw'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb weekStart), qb.lt(qb(date), qb weekEnd)
        queryOperator = operatorsMap['$tw'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb weekStart), qb.lt(qb(date), qb weekEnd)

        weekStart = moment().subtract(1, 'weeks').startOf 'week'
        weekEnd = weekStart.clone().endOf('week').toISOString()
        weekStart = weekStart.toISOString()
        queryOperator = operatorsMap['$lw'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb weekStart), qb.lt(qb(date), qb weekEnd)
        queryOperator = operatorsMap['$lw'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb weekStart), qb.lt(qb(date), qb weekEnd)

        firstDayStart = moment().startOf('month').toISOString()
        lastDayEnd = moment().endOf('month').toISOString()
        queryOperator = operatorsMap['$tm'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)
        queryOperator = operatorsMap['$tm'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)

        firstDayStart = moment().subtract(1, 'months').startOf 'month'
        lastDayEnd = firstDayStart.clone().endOf('month').toISOString()
        firstDayStart = firstDayStart.toISOString()
        queryOperator = operatorsMap['$lm'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)
        queryOperator = operatorsMap['$lm'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)

        firstDayStart = moment().startOf('year').toISOString()
        lastDayEnd = moment().endOf('year').toISOString()
        queryOperator = operatorsMap['$ty'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)
        queryOperator = operatorsMap['$ty'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)

        firstDayStart = moment().subtract(1, 'years').startOf 'year'
        lastDayEnd = firstDayStart.clone().endOf('year').toISOString()
        firstDayStart = firstDayStart.toISOString()
        queryOperator = operatorsMap['$ly'] date, yes
        assert.deepEqual queryOperator, qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)
        queryOperator = operatorsMap['$ly'] date, no
        assert.deepEqual queryOperator, qb.not qb.and qb.gte(qb(date), qb firstDayStart), qb.lt(qb(date), qb lastDayEnd)
        yield return
  describe '#parseFilter', ->
    it 'should get parse filter', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        result = collection.parseFilter
          field: 'a'
          operator: '$eq'
          operand: 'b'
          implicitField: yes
        assert.deepEqual result, qb.eq qb('a'), qb('b')
        result = collection.parseFilter
          parts: [
            field: 'c'
            operand: 'b'
            operator: '$or'
          ,
            field: 'd'
            operand: 'b'
            operator: '$nor'
          ]
          operator: '$and'
          implicitField: yes
        assert.deepEqual result, qb.and [
          qb.or qb.ref('c'), qb.ref('b')
          qb.not qb.or qb.ref('d'), qb.ref('b')
        ]
        result = collection.parseFilter
          operator: '$elemMatch'
          field: '@a'
          parts: [
            field: 'b'
            operand: 'c'
            operator: '$or'
          ]
        assert.deepEqual result, qb.gt qb.expr('LENGTH(a[* FILTER (@CURRENT.b || c)])'), qb 0
        yield return
  describe '#parseQuery', ->
    it 'should get parse query for `insert`', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$insert': SampleRecord.new
            id: '1'
            createdAt: date
            updatedAt: date
            test: 'test'
          , collection
          '$into': 'test_samples'
        assert.equal result, 'INSERT {"id": "1", "rev": null, "type": "Test::SampleRecord", "isHidden": false, "createdAt": "' + date.toISOString() + '", "updatedAt": "' + date.toISOString() + '", "deletedAt": null, "test": "test"} INTO test_samples'
        yield return
    it 'should get parse query for `update`', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$update': SampleRecord.new
            createdAt: date
            updatedAt: date
            test: 'test'
          , collection
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            parts: [
              field: 'c'
              operand: 'b'
              operator: '$or'
            ,
              field: 'd'
              operand: 'b'
              operator: '$nor'
            ]
            operator: '$and'
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER ([("parts" == [{"field": "c", "operand": "b", "operator": "$or"}, {"field": "d", "operand": "b", "operator": "$nor"}]), ("operator" == "$and")]) LET k = FOR doc1 IN test_samples FILTER ([(doc1.test == "test")]) RETURN doc1 UPDATE doc WITH {"rev": null, "type": "Test::SampleRecord", "isHidden": false, "createdAt": "' + date.toISOString() + '", "updatedAt": "' + date.toISOString() + '", "deletedAt": null, "test": "test"} IN test_samples'
        yield return
    it 'should get parse query for `replace`', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        class SampleRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$replace': SampleRecord.new
            createdAt: date
            updatedAt: date
            test: 'test'
          , collection
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            parts: [
              field: 'c'
              operand: 'b'
              operator: '$or'
            ,
              field: 'd'
              operand: 'b'
              operator: '$nor'
            ]
            operator: '$and'
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER ([("parts" == [{"field": "c", "operand": "b", "operator": "$or"}, {"field": "d", "operand": "b", "operator": "$nor"}]), ("operator" == "$and")]) LET k = FOR doc1 IN test_samples FILTER ([(doc1.test == "test")]) RETURN doc1 REPLACE doc WITH {"rev": null, "type": "Test::SampleRecord", "isHidden": false, "createdAt": "' + date.toISOString() + '", "updatedAt": "' + date.toISOString() + '", "deletedAt": null, "test": "test"} IN test_samples'
        yield return
  ###
  describe '#~sendRequest', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should make simple request', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_000'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public delegate: RC::Class,
            default: Test::TestRecord
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        data = yield collection[Symbol.for '~sendRequest']
          method: 'GET'
          url: 'http://localhost:8000'
          options: json: yes
        assert.equal data.status, 200
        assert.equal data.body?.message, 'OK'
        yield return
  describe '#~requestToHash, #~makeRequest', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should make simple request', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_001'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public delegate: RC::Class,
            default: Test::TestRecord
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        hash = collection[Symbol.for '~requestToHash']
          method: 'GET'
          url: 'http://localhost:8000'
        assert.equal hash.method, 'GET', 'Method is incorrect'
        assert.equal hash.url, 'http://localhost:8000', 'URL is incorrect'
        assert.equal hash.options?.json, yes, 'JSON option is not set'
        data = yield collection[Symbol.for '~makeRequest']
          method: 'GET'
          url: 'http://localhost:8000'
        assert.equal data.status, 200, 'Request received not OK status'
        assert.equal data?.body?.message, 'OK', 'Incorrect body'
        yield return
  describe '#methodForRequest', ->
    it 'should get method name from request params', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        method = collection.methodForRequest requestType: 'find'
        assert.equal method, 'GET', 'Find method is incorrect'
        method = collection.methodForRequest requestType: 'insert'
        assert.equal method, 'POST', 'Insert method is incorrect'
        method = collection.methodForRequest requestType: 'update'
        assert.equal method, 'PATCH', 'Update method is incorrect'
        method = collection.methodForRequest requestType: 'replace'
        assert.equal method, 'PUT', 'Replace method is incorrect'
        method = collection.methodForRequest requestType: 'remove'
        assert.equal method, 'DELETE', 'Remove method is incorrect'
        method = collection.methodForRequest requestType: 'someOther'
        assert.equal method, 'GET', 'Any other method is incorrect'
        yield return
  describe '#~urlPrefix', ->
    it 'should get url prefix', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection[Symbol.for '~urlPrefix'] 'Test', 'Tests'
        assert.equal url, 'Tests/Test'
        url = collection[Symbol.for '~urlPrefix'] '/Test'
        assert.equal url, 'http://localhost:8000/Test'
        url = collection[Symbol.for '~urlPrefix']()
        assert.equal url, 'http://localhost:8000/v1'
        yield return
  describe '#pathForType', ->
    it 'should get url for type', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.pathForType 'Type'
        assert.equal url, 'types'
        url = collection.pathForType 'TestRecord'
        assert.equal url, 'tests'
        url = collection.pathForType 'test-info'
        assert.equal url, 'test_infos'
        yield return
  describe '#~buildURL', ->
    it 'should get url from request params', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection[Symbol.for '~buildURL'] 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection[Symbol.for '~buildURL'] 'Test', {}, no
        assert.equal url, 'http://localhost:8000/v1/tests'
        yield return
  describe '#urlForFind', ->
    it 'should get url for find request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForFind 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.urlForFind 'TestRecord', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        yield return
  describe '#urlForInsert', ->
    it 'should get url for insert request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForInsert 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.urlForInsert 'TestRecord', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        yield return
  describe '#urlForUpdate', ->
    it 'should get url for insert request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForUpdate 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForUpdate 'TestRecord', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        yield return
  describe '#urlForReplace', ->
    it 'should get url for insert request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForReplace 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForReplace 'TestRecord', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        yield return
  describe '#urlForRemove', ->
    it 'should get url for insert request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForRemove 'Test', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForRemove 'TestRecord', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        yield return
  describe '#buildURL', ->
    it 'should get url from request params', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
          @public urlForTest: Function,
            default: (recordName, snapshot, requestType, query) ->
              "TEST_#{recordName ? 'RECORD_NAME'}_#{snapshot ? 'SNAPSHOT'}_#{requestType ? 'REQUEST_TYPE'}_#{query ? 'QUERY'}"
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.buildURL 'Test', {}, 'find', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.buildURL 'Test', {}, 'insert', {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.buildURL 'Test', {}, 'update', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.buildURL 'Test', {}, 'replace', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.buildURL 'Test', {}, 'remove', {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.buildURL 'Test', 'SNAP', 'test', 'QUE'
        assert.equal url, 'TEST_Test_SNAP_test_QUE'
        yield return
  describe '#urlForRequest', ->
    it 'should get url from request params', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
          @public urlForTest: Function,
            default: (recordName, snapshot, requestType, query) ->
              "TEST_#{recordName ? 'RECORD_NAME'}_#{snapshot ? 'SNAPSHOT'}_#{requestType ? 'REQUEST_TYPE'}_#{query ? 'QUERY'}"
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: {}
          requestType: 'find'
          query: {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: {}
          requestType: 'insert'
          query: {}
        assert.equal url, 'http://localhost:8000/v1/tests'
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: {}
          requestType: 'update'
          query: {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: {}
          requestType: 'replace'
          query: {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: {}
          requestType: 'remove'
          query: {}
        assert.equal url, 'http://localhost:8000/v1/tests/bulk'
        url = collection.urlForRequest
          recordName: 'Test'
          snapshot: 'SNAP'
          requestType: 'test'
          query: 'QUE'
        assert.equal url, 'TEST_Test_SNAP_test_QUE'
        yield return
  describe '#headersForRequest', ->
    it 'should get headers for collection', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        headers = collection.headersForRequest()
        assert.deepEqual headers, {}
        collection.headers = 'Allow': 'GET'
        headers = collection.headersForRequest()
        assert.deepEqual headers, { 'Allow': 'GET' }
        yield return
  describe '#dataForRequest', ->
    it 'should get data for request', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        data = collection.dataForRequest snapshot: test: 'test1'
        assert.deepEqual data, { test: 'test1' }
        data = collection.dataForRequest snapshot: test: 'test2'
        assert.deepEqual data, { test: 'test2' }
        yield return
  describe '#~requestFor', ->
    it 'should request params', ->
      co ->
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        collection = ArangoCollection.new()
        sampleData = test: 'test'
        request = collection[Symbol.for '~requestFor']
          recordName: 'TestRecord'
          snapshot: sampleData
          requestType: 'find'
          query: test: 'test'
        assert.deepEqual request,
          method: 'GET'
          url: 'http://localhost:8000/v1/tests'
          headers: {}
          data: sampleData
          query: test: 'test'
        request = collection[Symbol.for '~requestFor']
          recordName: 'TestRecord'
          snapshot: sampleData
          requestType: 'insert'
          query: test: 'test'
        assert.deepEqual request,
          method: 'POST'
          url: 'http://localhost:8000/v1/tests'
          headers: {}
          data: sampleData
          query: test: 'test'
        request = collection[Symbol.for '~requestFor']
          recordName: 'TestRecord'
          snapshot: sampleData
          requestType: 'update'
          query: test: 'test'
        assert.deepEqual request,
          method: 'PATCH'
          url: 'http://localhost:8000/v1/tests/bulk'
          headers: {}
          data: sampleData
          query: test: 'test'
        request = collection[Symbol.for '~requestFor']
          recordName: 'TestRecord'
          snapshot: sampleData
          requestType: 'replace'
          query: test: 'test'
        assert.deepEqual request,
          method: 'PUT'
          url: 'http://localhost:8000/v1/tests/bulk'
          headers: {}
          data: sampleData
          query: test: 'test'
        request = collection[Symbol.for '~requestFor']
          recordName: 'TestRecord'
          snapshot: sampleData
          requestType: 'remove'
          query: test: 'test'
        assert.deepEqual request,
          method: 'DELETE'
          url: 'http://localhost:8000/v1/tests/bulk'
          headers: {}
          data: sampleData
          query: test: 'test'
        yield return
  describe '#push', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should put data into collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_002'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        spyPush = sinon.spy collection, 'push'
        spyQuery = sinon.spy collection, 'query'
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        assert.equal record, spyPush.args[0][0]
        assert.equal spyQuery.args[0][0].$insert, record
        assert.equal spyQuery.args[0][0].$into, collection.collectionFullName()
        yield return
  describe '#remove', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should remove data from collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_003'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        spyQuery = sinon.spy collection, 'query'
        yield record.destroy()
        assert.deepEqual spyQuery.args[1][0].$forIn, { '@doc': 'test_tests' }
        assert.deepEqual spyQuery.args[1][0].$filter, { '@doc._key': { '$eq': record.id } }
        assert.isTrue spyQuery.args[1][0].$remove
        yield return
  describe '#take', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should get data item by id from collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_004'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        recordDuplicate = yield collection.take record.id
        assert.notEqual record, recordDuplicate
        for attribute in Test::TestRecord.attributes
          assert.equal record[attribute], recordDuplicate[attribute]
        yield return
  describe '#takeMany', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should get data items by id list from collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_005'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        originalRecords = []
        for i in [ 1 .. 5 ]
          originalRecords.push yield collection.create test: 'test1'
        ids = originalRecords.map (item) -> item.id
        recordDuplicates = yield (yield collection.takeMany ids).toArray()
        assert.equal originalRecords.length, recordDuplicates.length
        count = originalRecords.length
        for i in [ 1 .. count ]
          for attribute in Test::TestRecord.attributes
            assert.equal originalRecords[i][attribute], recordDuplicates[i][attribute]
        yield return
  describe '#takeAll', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should get all data items from collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_006'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        originalRecords = []
        for i in [ 1 .. 5 ]
          originalRecords.push yield collection.create test: 'test1'
        ids = originalRecords.map (item) -> item.id
        recordDuplicates = yield (yield collection.takeAll()).toArray()
        assert.equal originalRecords.length, recordDuplicates.length
        count = originalRecords.length
        for i in [ 1 .. count ]
          for attribute in Test::TestRecord.attributes
            assert.equal originalRecords[i][attribute], recordDuplicates[i][attribute]
        yield return
  describe '#override', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should replace data item by id in collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_007'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        updatedRecord = yield collection.override record.id, collection.build test: 'test2'
        assert.isDefined updatedRecord
        assert.equal record.id, updatedRecord.id
        assert.propertyVal record, 'test', 'test1'
        assert.propertyVal updatedRecord, 'test', 'test2'
        yield return
  describe '#patch', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should update data item by id in collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_008'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        updatedRecord = yield collection.patch record.id, collection.build test: 'test2'
        assert.isDefined updatedRecord
        assert.equal record.id, updatedRecord.id
        assert.propertyVal record, 'test', 'test1'
        assert.propertyVal updatedRecord, 'test', 'test2'
        yield return
  describe '#includes', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should test if item is included in the collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_009'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        assert.isDefined record
        includes = yield collection.includes record.id
        assert.isTrue includes
        yield return
  describe '#length', ->
    before ->
      server.listen 8000
    after ->
      server.close()
    it 'should count items in the collection', ->
      co ->
        KEY = 'FACADE_TEST_HTTP_COLLECTION_010'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC::Module
          @inheritProtected()
        Test.initialize()
        class Test::TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attribute test: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::TestRecord'
        Test::TestRecord.initialize()
        class ArangoCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        ArangoCollection.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        count = 11
        for i in [ 1 .. count ]
          yield collection.create test: 'test1'
        length = yield collection.length()
        assert.equal count, length
        yield return
  ###
