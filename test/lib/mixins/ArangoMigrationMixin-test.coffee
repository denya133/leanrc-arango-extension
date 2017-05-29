{ db }  = require '@arangodb'

{ expect, assert } = require 'chai'
sinon = require 'sinon'

LeanRC = require 'LeanRC'

ArangoExtension = require '../../..'
{ co } = LeanRC::Utils


describe 'ArangoMigrationMixin', ->
  describe '.new', ->
    it 'should create migration instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
        BaseMigration.initialize()
        migration = BaseMigration.new()
        yield return
  describe '#createCollection', ->
    after ->
      db._drop 'test_TestCollection'
    it 'should apply step for create collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @createCollection 'TestCollection'
        BaseMigration.initialize()
        collection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = collection.build {}
        spyCreateCollection = sinon.spy migration, 'createCollection'
        yield migration.up()
        assert.isTrue spyCreateCollection.calledWith 'TestCollection'
        collectionFullName = collection.collectionFullName 'TestCollection'
        assert.isNotNull db._collection collectionFullName
        yield return
  describe '#createEdgeCollection', ->
    after ->
      db._drop 'test_TestCollection1_TestCollection2'
    it 'should apply step for create edge collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @createEdgeCollection 'TestCollection1', 'TestCollection2'
        BaseMigration.initialize()
        collection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = collection.build {}
        spyCreateCollection = sinon.spy migration, 'createEdgeCollection'
        yield migration.up()
        assert.isTrue spyCreateCollection.calledWith 'TestCollection1', 'TestCollection2'
        collectionFullName = collection.collectionFullName 'TestCollection1_TestCollection2'
        assert.isNotNull db._collection collectionFullName
        yield return
  describe '#addField', ->
    after ->
      db._drop 'test_tests'
    it 'should apply step to add field in record at collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_001'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attr 'test': String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'TestRecord'
        TestRecord.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
        BaseMigration.initialize()
        class Migration1 extends BaseMigration
          @inheritProtected()
          @module Test
          @createCollection 'tests'
        Migration1.initialize()
        class Migration2 extends BaseMigration
          @inheritProtected()
          @module Test
          @addField 'tests', 'test',
            default: 'Test1'
        Migration2.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class ArangoTestCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoTestCollection.initialize()
        facade.registerProxy ArangoTestCollection.new 'TestCollection',
          delegate: TestRecord
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration1 = Migration1.new {}, migrationsCollection
        yield migration1.up()
        facade.registerProxy ArangoTestCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create id: 1
        yield collection.create id: 2
        yield collection.create id: 3
        migration2 = Migration2.new {}, migrationsCollection
        yield migration2.up()
        for doc in db._collection('test_tests').all().toArray()
          assert.propertyVal doc, 'test', 'Test1'
        yield return
  describe '#addIndex', ->
    before ->
      db._createDocumentCollection 'test_tests'
    after ->
      db._drop 'test_tests'
    it 'should apply step to add index in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        fields = [ 'test' ]
        options = unique: yes, sparse: yes
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @addIndex 'tests', fields, options
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        spyAddIndex = sinon.spy migration, 'addIndex'
        yield migration.up()
        assert.isTrue spyAddIndex.calledWith 'tests', fields, options
        indexes = db.test_tests.getIndexes()
        assert.isTrue indexes.some ({ type, fields, unique, sparse }) ->
          type is 'hash' and 'test' in fields and unique and sparse
        yield return
  describe '#addTimestamps', ->
    before ->
      db._createDocumentCollection 'test_tests'
      collection = db._collection 'test_tests'
      collection.save {}
      collection.save {}
      collection.save {}
    after ->
      db._drop 'test_tests'
    it 'should apply step to add timesteps in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_002'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @addTimestamps 'tests'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class ArangoTestCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoTestCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        for doc in db._collection('test_tests').all().toArray()
          assert.property doc, 'createdAt'
          assert.property doc, 'updatedAt'
          assert.property doc, 'updatedAt'
        yield return
  describe '#changeCollection', ->
    before ->
      db._createDocumentCollection 'test_tests',
        waitForSync: no
    after ->
      db._drop 'test_tests'
    it 'should apply step to change collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        options =
          waitForSync: yes
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @changeCollection 'tests', options
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        spyChangeCollection = sinon.spy migration, 'changeCollection'
        assert.propertyVal db._collection('test_tests').properties(), 'waitForSync', no
        yield migration.up()
        assert.isTrue spyChangeCollection.calledWith 'tests', options
        assert.propertyVal db._collection('test_tests').properties(), 'waitForSync', yes
        yield return
  describe '#changeField', ->
    before ->
      db._createDocumentCollection 'test_tests'
      collection = db._collection 'test_tests'
      collection.save test: '42'
      collection.save test: '42'
      collection.save test: '42'
    after ->
      db._drop 'test_tests'
    it 'should apply step to change field in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @changeField 'tests', 'test', type: LeanRC::Migration::SUPPORTED_TYPES.integer
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        for doc in db._collection('test_tests').all().toArray()
          assert.propertyVal doc, 'test', 42
        yield return
  describe '#renameField', ->
    before ->
      db._createDocumentCollection 'test_tests'
      collection = db._collection 'test_tests'
      collection.save test: '42'
      collection.save test: '42'
      collection.save test: '42'
    after ->
      db._drop 'test_tests'
    it 'should apply step to rename field in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @renameField 'tests', 'test', 'test1'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        for doc in db._collection('test_tests').all().toArray()
          assert.notProperty doc, 'test'
          assert.property doc, 'test1'
        yield return
  describe '#renameIndex', ->
    it 'should apply step to rename index in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @renameIndex 'ARG_1', 'ARG_2', 'ARG_3'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        spyRenameIndex = sinon.spy migration, 'renameIndex'
        yield migration.up()
        assert.isTrue spyRenameIndex.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#renameCollection', ->
    before ->
      db._createDocumentCollection 'test_tests'
    after ->
      db._drop 'test_new_tests'
    it 'should apply step to rename collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @renameCollection 'tests', 'tests', 'new_tests'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        spyRenameCollection = sinon.spy migration, 'renameCollection'
        assert.isNotNull db._collection 'test_tests'
        yield migration.up()
        assert.isTrue spyRenameCollection.calledWith 'tests', 'tests', 'new_tests'
        assert.isNull db._collection 'test_tests'
        assert.isNotNull db._collection 'test_new_tests'
        yield return
  describe '#dropCollection', ->
    before ->
      db._createDocumentCollection 'test_tests'
      collection = db._collection 'test_tests'
      collection.save test: '42'
      collection.save test: '42'
      collection.save test: '42'
    after ->
      db._drop 'test_tests'
    it 'should apply step to drop collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @dropCollection 'tests'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        assert.isNull db._collection 'test_tests'
        yield return
  describe '#dropEdgeCollection', ->
    before ->
      db._createEdgeCollection 'test_tests_tests'
    after ->
      db._drop 'test_tests_tests'
    it 'should apply step to drop edge collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @dropEdgeCollection 'tests', 'tests'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        assert.isNull db._collection 'test_tests_tests'
        yield return
  describe '#removeField', ->
    before ->
      db._createDocumentCollection 'test_tests'
      collection = db._collection 'test_tests'
      collection.save test: '42'
      collection.save test: '42'
      collection.save test: '42'
    after ->
      db._drop 'test_tests'
    it 'should apply step to remove field in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attr 'test': String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'TestRecord'
        TestRecord.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @removeField 'tests', 'test'
        BaseMigration.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        migrationsCollection = ArangoMigrationCollection.new 'MIGRATIONS',
          delegate: BaseMigration
        migration = BaseMigration.new {}, migrationsCollection
        yield migration.up()
        for doc in db._collection('test_tests').all().toArray()
          assert.notProperty doc, 'test'
        yield return
  ###
  describe '#removeIndex', ->
    it 'should apply step to remove index in collection', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
        BaseMigration.initialize()
        class Migration1 extends BaseMigration
          @inheritProtected()
          @module Test
          @createCollection 'tests'
        Migration1.initialize()
        class Migration2 extends BaseMigration
          @inheritProtected()
          @module Test
          @removeIndex 'ARG_1', 'ARG_2', 'ARG_3'
        Migration2.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class ArangoTestCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoTestCollection.initialize()
        migration = BaseMigration.new()
        spyRemoveIndex = sinon.spy migration, 'removeIndex'
        yield migration.up()
        assert.isTrue spyRemoveIndex.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#removeTimestamps', ->
    it 'should apply step to remove timestamps in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_008'
        facade = LeanRC::Facade.getInstance KEY
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestRecord extends LeanRC::Record
          @inheritProtected()
          @module Test
          @attr 'test': String
          @public init: Function,
            default: ->
              @super arguments...
              @type = 'TestRecord'
        TestRecord.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
        BaseMigration.initialize()
        class Migration1 extends BaseMigration
          @inheritProtected()
          @module Test
          @createCollection 'tests'
        Migration1.initialize()
        class Migration2 extends BaseMigration
          @inheritProtected()
          @module Test
          @removeTimestamps 'Test'
        Migration2.initialize()
        class ArangoMigrationCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoMigrationCollection.initialize()
        class ArangoTestCollection extends Test::Collection
          @inheritProtected()
          @include Test::QueryableMixin
          @include Test::ArangoCollectionMixin
          @module Test
        ArangoTestCollection.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        DATE = new Date()
        yield collection.create test: '42', createdAt: DATE
        yield collection.create test: '42', createdAt: DATE
        yield collection.create test: '42', createdAt: DATE
        migration = BaseMigration.new {}, collection
        for own id, doc of collection[Symbol.for '~collection']
          assert.property doc, 'createdAt'
          assert.property doc, 'updatedAt'
          assert.property doc, 'deletedAt'
        yield migration.up()
        for own id, doc of collection[Symbol.for '~collection']
          assert.notProperty doc, 'createdAt'
          assert.notProperty doc, 'updatedAt'
          assert.notProperty doc, 'deletedAt'
        yield return
  ###
