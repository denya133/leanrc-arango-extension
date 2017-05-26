_  = require 'lodash'
LeanRC = require 'LeanRC'


module.exports = (Module)->
  class ArangoCursor extends LeanRC::CoreObject
    @inheritProtected()
    @implements LeanRC::CursorInterface

    @module Module

    ipoCursor = @private cursor: LeanRC::ANY
    ipcRecord = @private Record: LeanRC::Class
    ipoCollection = @private collection: Module::Collection

    @public setCursor: Function,
      args: [LeanRC::ANY]
      return: LeanRC::CursorInterface
      default: (aoCursor)->
        @[ipoCursor] = aoCursor
        return @

    @public setRecord: Function,
      default: (acRecord)->
        @[ipcRecord] = acRecord
        return @

    @public setCollection: Function,
      default: (aoCollection)->
        @[ipoCollection] = aoCollection
        return @

    @public @async toArray: Function,
      default: (acRecord = null)->
        while yield @hasNext()
          yield @next acRecord ? @[ipoCollection]?.delegate

    @public @async next: Function,
      default: (acRecord = null)->
        acRecord ?= @[ipcRecord]
        data = yield LeanRC::Promise.resolve @[ipoCursor].next()
        if data?
          switch
            when acRecord?
              acRecord.new data
            when @[ipoCollection]?
              @[ipoCollection].normalize data
        else
          data

    @public @async hasNext: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].hasNext()

    @public @async close: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].dispose()

    @public @async count: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].count arguments...

    @public @async forEach: Function,
      default: (lambda, acRecord = null)->
        index = 0
        try
          while yield @hasNext()
            yield lambda (yield @next acRecord), index++
          return
        catch err
          yield @close()
          throw err

    @public @async map: Function,
      default: (lambda, acRecord = null)->
        index = 0
        try
          while yield @hasNext()
            yield lambda (yield @next acRecord), index++
        catch err
          yield @close()
          throw err

    @public @async filter: Function,
      default: (lambda, acRecord = null)->
        index = 0
        records = []
        try
          while yield @hasNext()
            record = yield @next acRecord
            if yield lambda record, index++
              records.push record
          records
        catch err
          yield @close()
          throw err

    @public @async find: Function,
      default: (lambda, acRecord = null)->
        index = 0
        _record = null
        try
          while yield @hasNext()
            record = yield @next acRecord
            if yield lambda record, index++
              _record = record
              break
          _record
        catch err
          yield @close()
          throw err

    @public @async compact: Function,
      default: (acRecord = null)->
        acRecord ?= @[ipcRecord]
        index = 0
        records = []
        try
          while yield @hasNext()
            rawRecord = yield LeanRC::Promise.resolve @[ipoCursor].next()
            unless _.isEmpty rawRecord
              switch
                when acRecord?
                  record = acRecord.new rawRecord
                when @[ipoCollection]?
                  record = @[ipoCollection].normalize rawRecord
              records.push record
          records
        catch err
          yield @close()
          throw err

    @public @async reduce: Function,
      default: (lambda, initialValue, acRecord = null)->
        try
          index = 0
          _initialValue = initialValue
          while yield @hasNext()
            _initialValue = yield lambda _initialValue, (yield @next acRecord), index++
          _initialValue
        catch err
          yield @close()
          throw err

    @public @async first: Function,
      default: (acRecord = null)->
        try
          if yield @hasNext()
            yield @next acRecord
          else
            null
        catch err
          yield @close()
          throw err

    @public init: Function,
      default: (acRecord, aoCursor = null, aoCollection = null)->
        @super arguments...
        @[ipcRecord] = acRecord
        @[ipoCursor] = aoCursor
        @[ipoCollection] = aoCollection
        return


  ArangoCursor.initialize()
