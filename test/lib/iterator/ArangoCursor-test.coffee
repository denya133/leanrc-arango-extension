{ db } = require '@arangodb'
{ co, assert } = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
LeanRC = require 'LeanRC'
ArangoExtension = require '../../..'
{ co } = LeanRC::Utils


describe 'ArangoCursor', ->
  before ->
    collection = db._create 'test_thames_travel'
    date = new Date()
    collection.save id: 1, data: 'three', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 2, data: 'men', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 3, data: 'in', createdAt: date, updatedAt: date
    date = new Date()
    collection.save id: 4, data: 'a boat', createdAt: date, updatedAt: date
  after ->
    db._drop 'test_thames_travel'
  describe '.new', ->
    it 'should create cursor instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        collection = db.test_thames_travel
        cursor = Test::ArangoCursor.new collectionInstance, collection.all()
        yield return
  describe '#setCollection', ->
    it 'should setup collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
        TestRecord.initialize()
        class TestCollection extends Test::Collection
          @inheritProtected()
          @module Test
        TestCollection.initialize()
        cursor = Test::ArangoCursor.new()
        cursor.setCollection TestCollection.new()
        yield return
  describe '#setIterable', ->
    it 'should setup cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        collection = db.test_thames_travel
        cursor = Test::ArangoCursor.new collectionInstance
        cursor.setIterable collection.all()
        yield return
  describe '#next', ->
    it 'should get next values one by one', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        assert.equal (yield cursor.next()).data, 'three', 'First item is incorrect'
        assert.equal (yield cursor.next()).data, 'men', 'Second item is incorrect'
        assert.equal (yield cursor.next()).data, 'in', 'Third item is incorrect'
        assert.equal (yield cursor.next()).data, 'a boat', 'Fourth item is incorrect'
        assert.isUndefined (yield cursor.next()), 'Uncoed item is present'
  describe '#hasNext', ->
    before ->
      collection = db._create 'test_collection'
      date = new Date()
      collection.save id: 1, data: 'data', createdAt: date, updatedAt: date
    after ->
      db._drop 'test_collection'
    it 'should check if next value is present', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        collection = db.test_collection
        cursor = Test::ArangoCursor.new collectionInstance, collection.all()
        assert.isTrue (yield cursor.hasNext()), 'There is no next value'
        data = yield cursor.next()
        assert.isFalse (yield cursor.hasNext()), 'There is something else'
  describe '#toArray', ->
    it 'should get array from cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        array = db._query 'FOR item IN test_thames_travel SORT item._key RETURN item'
        .toArray()
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        records = yield cursor.toArray()
        assert.equal records.length, array.length, 'Counts of input and output data are different'
        for record, index in records
          assert.instanceOf record, TestRecord, "Record #{index} is incorrect"
          assert.equal record.data, array[index].data, "Record #{index} `data` is incorrect"
        return
  describe '#close', ->
    it 'should remove records from cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        assert.isTrue (yield cursor.hasNext()), 'There is no next value'
        yield cursor.close()
        assert.isFalse (yield cursor.hasNext()), 'There is something else'
        return
  describe '#count', ->
    it 'should count records in cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        assert.equal (yield cursor.count()), 4, 'Count works incorrectly'
        return
  describe '#forEach', ->
    it 'should call lambda in each record in cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        spyLambda = sinon.spy -> yield return
        yield cursor.forEach spyLambda
        assert.isTrue spyLambda.called, 'Lambda never called'
        assert.equal spyLambda.callCount, 4, 'Lambda calls are not match'
        assert.equal spyLambda.args[0][0].data, 'three', 'Lambda 1st call is not match'
        assert.equal spyLambda.args[1][0].data, 'men', 'Lambda 2nd call is not match'
        assert.equal spyLambda.args[2][0].data, 'in', 'Lambda 3rd call is not match'
        assert.equal spyLambda.args[3][0].data, 'a boat', 'Lambda 4th call is not match'
        return
  describe '#map', ->
    it 'should map records using lambda', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        records = yield cursor.map (record) ->
          record.data = '+' + record.data + '+'
          yield Test::Promise.resolve record
        assert.lengthOf records, 4, 'Records count is not match'
        assert.equal records[0].data, '+three+', '1st record is not match'
        assert.equal records[1].data, '+men+', '2nd record is not match'
        assert.equal records[2].data, '+in+', '3rd record is not match'
        assert.equal records[3].data, '+a boat+', '4th record is not match'
        return
  describe '#filter', ->
    it 'should filter records using lambda', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        records = yield cursor.filter (record) ->
          yield Test::Promise.resolve record.data.length > 3
        assert.lengthOf records, 2, 'Records count is not match'
        assert.equal records[0].data, 'three', '1st record is not match'
        assert.equal records[1].data, 'a boat', '2nd record is not match'
        return
  describe '#find', ->
    before ->
      collection = db._create 'test_collection'
      date = new Date()
      collection.save id: 1, name: 'Jerome', createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, name: 'George', createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, name: 'Harris', createdAt: date, updatedAt: date
    after ->
      db._drop 'test_collection'
    it 'should find record using lambda', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute name: String, { default: 'Unknown' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db.test_collection.all()
        record = yield cursor.find (record) ->
          yield Test::Promise.resolve record.name is 'George'
        assert.equal record.name, 'George', 'Record is not match'
        record = yield cursor.find (record) ->
          yield Test::Promise.resolve record.name is 'Marvel'
        assert.isNull record
        return
  describe '#compact', ->
    before ->
      collection = db._create 'test_collection'
      date = new Date()
      collection.save id: 1, data: 'men', createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, data: null, createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, data: 'a boat', createdAt: date, updatedAt: date
    after ->
      db._drop 'test_collection'
    it 'should get non-empty records from cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_collection SORT item._key RETURN item.data ? item : null
        '''
        records = yield cursor.compact()
        assert.lengthOf records, 2, 'Records count not match'
        assert.equal records[0].data, 'men', '1st record is not match'
        assert.equal records[1].data, 'a boat', '2nd record is not match'
        return
  describe '#reduce', ->
    it 'should reduce records using lambda', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        records = yield cursor.reduce (accumulator, item) ->
          accumulator[item.data] = item
          yield Test::Promise.resolve accumulator
        , {}
        assert.equal records['three'].data, 'three', '1st record is not match'
        assert.equal records['men'].data, 'men', '2nd record is not match'
        assert.equal records['in'].data, 'in', '3rd record is not match'
        assert.equal records['a boat'].data, 'a boat', '4th record is not match'
        return
  describe '#first', ->
    before ->
      collection = db._create 'test_collection'
      date = new Date()
      collection.save id: 1, data: 'Jerome', createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, data: 'George', createdAt: date, updatedAt: date
      date = new Date()
      collection.save id: 1, data: 'Harris', createdAt: date, updatedAt: date
    after ->
      db._drop 'test_collection'
    it 'should get first record from cursor', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends Test::Record
          @inheritProtected()
          @module Test
          @attribute data: String, { default: '' }
        TestRecord.initialize()
        collectionInstance = Test::Collection.new 'TEST_COLLECTION',
          delegate: TestRecord
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_thames_travel SORT item._key RETURN item
        '''
        record = yield cursor.first()
        assert.equal record.data, 'three', '1st record is not match'
        cursor = Test::ArangoCursor.new collectionInstance, db._query '''
          FOR item IN test_collection SORT item._key RETURN item
        '''
        record = yield cursor.first()
        assert.equal record.data, 'Jerome', 'Another 1st record is not match'
        return
