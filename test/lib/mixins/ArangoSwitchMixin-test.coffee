{ db }  = require '@arangodb'

{ expect, assert } = require 'chai'
sinon = require 'sinon'

LeanRC = require 'LeanRC'

ArangoExtension = require '../../..'
{ co } = LeanRC::Utils


describe 'ArangoSwitchMixin', ->
  describe '.new', ->
    before ->
      db._createDocumentCollection 'test_tests'
    after ->
      db._drop 'test_tests'
    it 'should create switch instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestSwitch extends LeanRC::Switch
          @inheritProtected()
          @include Test::ArangoSwitchMixin
          @module Test
        TestSwitch.initialize()
        testSwitch = TestSwitch.new()
        assert.instanceOf testSwitch, TestSwitch
        yield return
  describe '#getLocks', ->
    before ->
      db._createDocumentCollection 'test_tests1'
      db._createDocumentCollection 'test_tests2'
      db._createDocumentCollection 'test_tests3'
      db._createDocumentCollection 'test_tests4'
    after ->
      db._drop 'test_tests1'
      db._drop 'test_tests2'
      db._drop 'test_tests3'
      db._drop 'test_tests4'
    it 'should get locks for collections', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root __dirname
        Test.initialize()
        class TestSwitch extends LeanRC::Switch
          @inheritProtected()
          @include Test::ArangoSwitchMixin
          @module Test
        TestSwitch.initialize()
        testSwitch = TestSwitch.new()
        locks = testSwitch.getLocks()
        assert.deepEqual locks,
          read: [ 'test_tests1', 'test_tests2', 'test_tests3', 'test_tests4' ]
          write: [ 'test_tests1', 'test_tests2', 'test_tests3', 'test_tests4' ]
        yield return
  describe '#del', ->
    it 'should alias to #delete', ->
      co ->
        spyDelete = sinon.spy ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestSwitch extends LeanRC::Switch
          @inheritProtected()
          @include Test::ArangoSwitchMixin
          @module Test
          @public routerName: String,
            default: 'TEST_SWITCH_ROUTER'
          @public delete: Function, { default: spyDelete }
        TestSwitch.initialize()
        switchMediator = TestSwitch.new 'TEST_SWITCH_MEDIATOR'
        switchMediator.del 'TEST'
        assert.isTrue spyDelete.calledWith 'TEST'
        yield return
