{ expect, assert } = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
LeanRC = require 'LeanRC'
ArangoExtension = require '../../..'
{ co } = LeanRC::Utils

###
commonServerInitializer = require.main.require 'test/common/server'
server = commonServerInitializer fixture: 'ArangoCollectionMixin'
###

describe 'ArangoCollectionMixin', ->
  describe '.new', ->
    it 'should create HTTP collection instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class Test::HttpCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public delegate: RC::Class,
            default: Test::TestRecord
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public delegate: RC::Class,
            default: Test::TestRecord
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
          @public urlForTest: Function,
            default: (recordName, snapshot, requestType, query) ->
              "TEST_#{recordName ? 'RECORD_NAME'}_#{snapshot ? 'SNAPSHOT'}_#{requestType ? 'REQUEST_TYPE'}_#{query ? 'QUERY'}"
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
          @public urlForTest: Function,
            default: (recordName, snapshot, requestType, query) ->
              "TEST_#{recordName ? 'RECORD_NAME'}_#{snapshot ? 'SNAPSHOT'}_#{requestType ? 'REQUEST_TYPE'}_#{query ? 'QUERY'}"
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        collection = Test::HttpCollection.new()
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        spyPush = sinon.spy collection, 'push'
        spyQuery = sinon.spy collection, 'query'
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
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
        class Test::HttpCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::QueryableMixin
          @include LeanRC::ArangoCollectionMixin
          @module Test
          @public host: String, { default: 'http://localhost:8000' }
          @public namespace: String, { default: 'v1' }
        Test::HttpCollection.initialize()
        facade.registerProxy Test::HttpCollection.new KEY,
          delegate: Test::TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy KEY
        assert.instanceOf collection, Test::HttpCollection
        count = 11
        for i in [ 1 .. count ]
          yield collection.create test: 'test1'
        length = yield collection.length()
        assert.equal count, length
        yield return
  ###
