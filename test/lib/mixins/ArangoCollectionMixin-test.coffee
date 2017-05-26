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
        collection = ArangoCollection.new 'TEST_COLLECTION',
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        { operatorsMap } = collection

        assert.isFunction operatorsMap['$and']
        assert.isFunction operatorsMap['$or']
        assert.isFunction operatorsMap['$not']
        assert.isFunction operatorsMap['$nor']

        assert.isFunction operatorsMap['$where']

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

        logicalOperator = operatorsMap['$and'] ['a', 'b', 'c']
        assert.deepEqual logicalOperator, qb.and 'a', 'b', 'c'
        logicalOperator = operatorsMap['$or'] ['a', 'b', 'c']
        assert.deepEqual logicalOperator, qb.or 'a', 'b', 'c'
        logicalOperator = operatorsMap['$not'] ['a', 'b', 'c']
        assert.deepEqual logicalOperator, qb.not 'a', 'b', 'c'
        logicalOperator = operatorsMap['$nor'] ['a', 'b', 'c']
        assert.deepEqual logicalOperator, qb.not qb.or 'a', 'b', 'c'

        assert.throws -> operatorsMap['$where'] ['a', 'b', 'c']
        , Error

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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        result = collection.parseFilter
          field: 'a'
          operator: '$eq'
          operand: 'b'
        assert.deepEqual result, qb.eq qb('a'), qb('b')
        result = collection.parseFilter
          parts: [
            operator: '$or'
            parts: [
              field: '@c'
              operand: '1'
              operator: '$eq'
            ,
              field: '@b'
              operand: '2'
              operator: '$eq'
            ]
          ,
            operator: '$nor'
            parts: [
              field: '@d'
              operand: '1'
              operator: '$eq'
            ,
              field: '@b'
              operand: '2'
              operator: '$eq'
            ]
          ]
          operator: '$and'
        assert.deepEqual result, qb.and [
          qb.or qb.eq(qb.ref('c'), qb('1')), qb.eq(qb.ref('b'), qb('2'))
          qb.not qb.or qb.eq(qb.ref('d'), qb('1')), qb.eq(qb.ref('b'), qb('2'))
        ]...
        result = collection.parseFilter
          operator: '$elemMatch'
          field: '@a'
          parts: [
            field: '@b'
            operand: 'c'
            operator: '$eq'
          ]
          implicitField: yes
        assert.deepEqual result, qb.gt qb.expr('LENGTH(a[* FILTER (CURRENT == "c")])'), qb 0
        result = collection.parseFilter
          operator: '$elemMatch'
          field: '@a'
          parts: [
            field: 'b'
            operand: 'c'
            operator: '$eq'
          ]
        assert.deepEqual result, qb.gt qb.expr('LENGTH(a[* FILTER (CURRENT.b == "c")])'), qb 0
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
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
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) LET k = FOR doc1 IN test_samples FILTER ((doc1.test == "test")) RETURN doc1 UPDATE doc WITH {"rev": null, "type": "Test::SampleRecord", "isHidden": false, "createdAt": "' + date.toISOString() + '", "updatedAt": "' + date.toISOString() + '", "deletedAt": null, "test": "test"} IN test_samples'
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
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
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) LET k = FOR doc1 IN test_samples FILTER ((doc1.test == "test")) RETURN doc1 REPLACE doc WITH {"rev": null, "type": "Test::SampleRecord", "isHidden": false, "createdAt": "' + date.toISOString() + '", "updatedAt": "' + date.toISOString() + '", "deletedAt": null, "test": "test"} IN test_samples'
        yield return
    it 'should get parse query for `remove`', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$remove': 'id': '1'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) LET k = FOR doc1 IN test_samples FILTER ((doc1.test == "test")) RETURN doc1 REMOVE {id: 1} IN test_samples'
        yield return
    it 'should get parse query for other with distinct return', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$let':
            k:
              '$forIn':
                'doc1': 'test_samples'
              '$filter':
                '@doc1.test': 'test'
              '$return': 'doc1'
          '$collect':
            l:
              '$forIn':
                'doc2': 'test_samples'
              '$filter':
                '@doc2.test': 'test'
              '$return': 'doc2'
          '$having':
            '$and': [
              '$or': [
                'f': '$eq': '1'
              ,
                '@doc.g': '$eq': '2'
              ]
            ,
              '@doc.h':
                '$not': '$eq': '2'
            ]
          '$sort':
            '@doc.field1': 'ASC'
            '@doc.field2': 'DESC'
          '$limit': 100
          '$offset': 50
          '$distinct': yes
          '$return': '@doc'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) LET k = FOR doc1 IN test_samples FILTER ((doc1.test == "test")) RETURN doc1 COLLECT l = FOR doc2 IN test_samples FILTER ((doc2.test == "test")) RETURN doc2 INTO test_samples FILTER (((((("f" == "1")) || ((doc.g == "2")))) && (!(doc.h == "2")))) SORT doc.field1 ASC SORT doc.field2 DESC LIMIT 50, 100 RETURN DISTINCT doc'
        yield return
    it 'should get parse query for other with count', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$count': yes
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples COLLECT WITH COUNT INTO counter RETURN (counter ? counter : 0)'
        yield return
    it 'should get parse query for other with sum', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$sum': '@doc.test'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples COLLECT AGGREGATE result = SUM(TO_NUMBER(doc.test)) RETURN result'
        yield return
    it 'should get parse query for other with min', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$min': '@doc.test'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples SORT doc.test LIMIT 1 RETURN doc.test'
        yield return
    it 'should get parse query for other with max', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$max': '@doc.test'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples SORT doc.test DESC LIMIT 1 RETURN doc.test'
        yield return
    it 'should get parse query for other with average', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$avg': '@doc.test'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples COLLECT AGGREGATE result = AVG(TO_NUMBER(doc.test)) RETURN result'
        yield return
    it 'should get parse query for other with return', ->
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
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        date = new Date
        result = collection.parseQuery
          '$forIn':
            'doc': 'test_samples'
          '$into': 'test_samples'
          '$join':
            '$and': [
              '@doc.tomatoId': '$eq': '@tomato._key'
            ,
              '@tomato.active': '$eq': yes
            ]
          '$filter':
            '$and': [
              '$or': [
                'c': '$eq': '1'
              ,
                '@doc.b': '$eq': '2'
              ]
            ,
              '@doc.b':
                '$not': '$eq': '2'
            ]
          '$return':
            'doc': '@doc'
        assert.equal result, 'FOR doc IN test_samples FILTER ((doc.tomatoId == tomato._key) && (tomato.active == true)) FILTER (((((("c" == "1")) || ((doc.b == "2")))) && (!(doc.b == "2")))) INTO test_samples RETURN {doc: doc}'
        yield return
  describe '#executeQuery', ->
    it 'should send query to ArangoDB', ->
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
          @attribute data: String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'Test::SampleRecord'
        SampleRecord.initialize()
        collection = ArangoCollection.new 'TEST_COLLECTION',
          delegate: SampleRecord
          serializer: Test::Serializer
        samples = yield collection.executeQuery '
          FOR doc IN test_samples
          SORT doc._key
          RETURN doc
        '
        items = yield samples.toArray()
        assert.lengthOf items, 4
        for item in items
          assert.instanceOf item, SampleRecord
        items = yield collection.executeQuery '
          FOR doc IN test_samples
          FILTER doc.data == "a boat"
          RETURN doc
        '
        item = yield items.first()
        assert.equal item.data, 'a boat'
        yield return
  describe '#push', ->
    it 'should put data into collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_002'
        facade = LeanRC::Facade.getInstance KEY
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
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: Test::Serializer
        collection = facade.retrieveProxy KEY
        spyPush = sinon.spy collection, 'push'
        spyQuery = sinon.spy collection, 'query'
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        assert.equal record, spyPush.args[0][0]
        assert.equal spyQuery.args[1][0].$insert, record
        assert.equal spyQuery.args[1][0].$into, collection.collectionFullName()
        yield return
  describe '#remove', ->
    it 'should remove data from collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_003'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        spyQuery = sinon.spy collection, 'query'
        yield record.destroy()
        assert.deepEqual spyQuery.args[1][0].$forIn, { '@doc': 'test_samples' }
        assert.deepEqual spyQuery.args[1][0].$filter, { '@doc._key': { '$eq': record.id } }
        assert.deepEqual spyQuery.args[1][0].$remove, _key: 'doc._key'
        yield return
  describe '#take', ->
    it 'should get data item by id from collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_004'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        recordDuplicate = yield collection.take record.id
        assert.notEqual record, recordDuplicate
        for attribute in SampleRecord.attributes
          assert.equal record[attribute], recordDuplicate[attribute]
        yield return
  describe '#takeMany', ->
    it 'should get data items by id list from collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_005'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
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
          for attribute in SampleRecord.attributes
            assert.equal originalRecords[i][attribute], recordDuplicates[i][attribute]
        yield return
  ###
  describe '#takeAll', ->
    it 'should get all data items from collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_006'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
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
          for attribute in SampleRecord.attributes
            assert.equal originalRecords[i][attribute], recordDuplicates[i][attribute]
        yield return
  describe '#override', ->
    it 'should replace data item by id in collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_007'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
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
    it 'should update data item by id in collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_008'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
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
    it 'should test if item is included in the collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_009'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        record = yield collection.create test: 'test1'
        assert.isDefined record
        includes = yield collection.includes record.id
        assert.isTrue includes
        yield return
  describe '#length', ->
    it 'should count items in the collection', ->
      co ->
        KEY = 'FACADE_TEST_ARANGO_COLLECTION_010'
        facade = LeanRC::Facade.getInstance KEY
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
        class SampleSerializer extends Test::Serializer
          @inheritProtected()
          @module Test
          @public normalize: Function,
            default: (acRecord, ahPayload) ->
              result = @super acRecord, ahPayload
              result.id = ahPayload._key
              result
          @public serialize: Function,
            default: (aoRecord, options = null) ->
              result = @super aoRecord, options
              result = _.omit result, [ 'id' ]
              result._key = aoRecord.id
              result
        SampleSerializer.initialize()
        facade.registerProxy ArangoCollection.new KEY,
          delegate: SampleRecord
          serializer: SampleSerializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, ArangoCollection
        count = 11
        for i in [ 1 .. count ]
          yield collection.create test: 'test1'
        length = yield collection.length()
        assert.equal count, length
        yield return
  ###
