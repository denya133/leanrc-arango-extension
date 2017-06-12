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
        yield return
