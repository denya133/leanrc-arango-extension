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
  ###
  describe '#addIndex', ->
    it 'should apply step to add index in collection', ->
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
          @addIndex 'ARG_1', 'ARG_2', 'ARG_3'
        BaseMigration.initialize()
        migration = BaseMigration.new()
        spyAddIndex = sinon.spy migration, 'addIndex'
        yield migration.up()
        assert.isTrue spyAddIndex.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#addTimestamps', ->
    it 'should apply step to add timesteps in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_002'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @addTimestamps 'Test'
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create id: 1
        yield collection.create id: 2
        yield collection.create id: 3
        migration = BaseMigration.new {}, collection
        yield migration.up()
        for own id, doc of collection[Symbol.for '~collection']
          assert.property doc, 'createdAt'
          assert.property doc, 'updatedAt'
          assert.property doc, 'updatedAt'
        yield return
  describe '#changeCollection', ->
    it 'should apply step to change collection', ->
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
          @changeCollection 'ARG_1', 'ARG_2', 'ARG_3'
        BaseMigration.initialize()
        migration = BaseMigration.new()
        spyChangeCollection = sinon.spy migration, 'changeCollection'
        yield migration.up()
        assert.isTrue spyChangeCollection.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#changeField', ->
    it 'should apply step to change field in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_003'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @changeField 'Test', 'test', type: LeanRC::Migration::SUPPORTED_TYPES.integer
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create test: '42'
        yield collection.create test: '42'
        yield collection.create test: '42'
        migration = BaseMigration.new {}, collection
        yield migration.up()
        for own id, doc of collection[Symbol.for '~collection']
          assert.propertyVal doc, 'test', 42
        yield return
  describe '#renameField', ->
    it 'should apply step to rename field in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_004'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @renameField 'Test', 'test', 'test1'
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create test: '42'
        yield collection.create test: '42'
        yield collection.create test: '42'
        migration = BaseMigration.new {}, collection
        yield migration.up()
        for own id, doc of collection[Symbol.for '~collection']
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
        migration = BaseMigration.new()
        spyRenameIndex = sinon.spy migration, 'renameIndex'
        yield migration.up()
        assert.isTrue spyRenameIndex.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#renameCollection', ->
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
          @renameCollection 'ARG_1', 'ARG_2', 'ARG_3'
        BaseMigration.initialize()
        migration = BaseMigration.new()
        spyRenameCollection = sinon.spy migration, 'renameCollection'
        yield migration.up()
        assert.isTrue spyRenameCollection.calledWith 'ARG_1', 'ARG_2', 'ARG_3'
        yield return
  describe '#dropCollection', ->
    it 'should apply step to drop collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_005'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @dropCollection 'Test'
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create test: '42'
        yield collection.create test: '42'
        yield collection.create test: '42'
        migration = BaseMigration.new {}, collection
        yield migration.up()
        assert.deepEqual collection[Symbol.for '~collection'], {}
        yield return
  describe '#dropEdgeCollection', ->
    it 'should apply step to drop edge collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_006'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @dropEdgeCollection 'Test', 'Test'
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestTestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestTestCollection'
        yield collection.create test: '42'
        yield collection.create test: '42'
        yield collection.create test: '42'
        migration = BaseMigration.new {}, collection
        yield migration.up()
        assert.deepEqual collection[Symbol.for '~collection'], {}
        yield return
  describe '#removeField', ->
    it 'should apply step to remove field in collection', ->
      co ->
        KEY = 'TEST_ARANGO_MIGRATION_MIXIN_007'
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @removeField 'Test', 'test'
        BaseMigration.initialize()
        facade.registerProxy Test::MemoryCollection.new 'TestCollection',
          delegate: TestRecord
          serializer: LeanRC::Serializer
        collection = facade.retrieveProxy 'TestCollection'
        yield collection.create test: '42'
        yield collection.create test: '42'
        yield collection.create test: '42'
        migration = BaseMigration.new {}, collection
        yield migration.up()
        for own id, doc of collection[Symbol.for '~collection']
          assert.notProperty doc, 'test'
        yield return
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
          @removeIndex 'ARG_1', 'ARG_2', 'ARG_3'
        BaseMigration.initialize()
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
        class Test::MemoryCollection extends LeanRC::Collection
          @inheritProtected()
          @include LeanRC::MemoryCollectionMixin
          @module Test
        Test::MemoryCollection.initialize()
        class BaseMigration extends LeanRC::Migration
          @inheritProtected()
          @include Test::ArangoMigrationMixin
          @module Test
          @removeTimestamps 'Test'
        BaseMigration.initialize()
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
