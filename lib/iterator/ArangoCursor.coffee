_  = require 'lodash'
LeanRC = require 'LeanRC'


module.exports = (Module)->
  class ArangoCursor extends LeanRC::CoreObject
    @inheritProtected()
    @implements LeanRC::CursorInterface

    @module Module

    ipoCursor = @private cursor: LeanRC::ANY
    ipoCollection = @private collection: Module::Collection

    @public setCursor: Function,
      args: [LeanRC::ANY]
      return: LeanRC::CursorInterface
      default: (aoCursor)->
        @[ipoCursor] = aoCursor
        return @

    @public setCollection: Function,
      default: (aoCollection)->
        @[ipoCollection] = aoCollection
        return @

    @public @async toArray: Function,
      default: ->
        while yield @hasNext()
          yield @next()

    @public @async next: Function,
      default: ->
        data = yield LeanRC::Promise.resolve @[ipoCursor].next()
        switch
          when not data?
            yield return data
          when @[ipoCollection]?
            yield return @[ipoCollection].normalize data
          else
            yield return data

    @public @async hasNext: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].hasNext()

    @public @async close: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].dispose()

    @public @async count: Function,
      default: -> yield LeanRC::Promise.resolve @[ipoCursor].count arguments...

    @public @async forEach: Function,
      default: (lambda)->
        index = 0
        try
          while yield @hasNext()
            yield lambda (yield @next()), index++
          return
        catch err
          yield @close()
          throw err

    @public @async map: Function,
      default: (lambda)->
        index = 0
        try
          while yield @hasNext()
            yield lambda (yield @next()), index++
        catch err
          yield @close()
          throw err

    @public @async filter: Function,
      default: (lambda)->
        index = 0
        records = []
        try
          while yield @hasNext()
            record = yield @next()
            if yield lambda record, index++
              records.push record
          records
        catch err
          yield @close()
          throw err

    @public @async find: Function,
      default: (lambda)->
        index = 0
        _record = null
        try
          while yield @hasNext()
            record = yield @next()
            if yield lambda record, index++
              _record = record
              break
          _record
        catch err
          yield @close()
          throw err

    @public @async compact: Function,
      default: ->
        index = 0
        results = []
        try
          while yield @hasNext()
            rawResult = yield LeanRC::Promise.resolve @[ipoCursor].next()
            unless _.isEmpty rawResult
              result = switch
                when @[ipoCollection]?
                  @[ipoCollection].normalize rawResult
                else
                  rawResult
              results.push result
          yield return results
        catch err
          yield @close()
          throw err

    @public @async reduce: Function,
      default: (lambda, initialValue)->
        try
          index = 0
          _initialValue = initialValue
          while yield @hasNext()
            _initialValue = yield lambda _initialValue, (yield @next()), index++
          _initialValue
        catch err
          yield @close()
          throw err

    @public @async first: Function,
      default: ->
        try
          result = if yield @hasNext()
            yield @next()
          else
            null
          yield @close()
          yield return result
        catch err
          yield @close()
          throw err

    @public init: Function,
      default: (aoCollection = null, aoCursor = null)->
        @super arguments...
        @[ipoCursor] = aoCursor
        @[ipoCollection] = aoCollection
        return


  ArangoCursor.initialize()
