_  = require 'lodash'
RC = require 'RC'

module.exports = (ArangoExtension)->
  class ArangoExtension::ArangoCursor extends RC::CoreObject
    @inheritProtected()
    @implements ArangoExtension::ArangoCursorInterface

    @Module: ArangoExtension

    ipoCursor = @private _cursor: RC::Constants.ANY
    ipcRecord = @private Record: RC::Class

    @public setCursor: Function,
      default: (aoCursor)->
        @[ipoCursor] = aoCursor
        return @

    @public setRecord: Function,
      default: (acRecord)->
        @[ipcRecord] = acRecord
        return @

    @public toArray: Function,
      default: (acRecord = null)->
        while @hasNext()
          @next(acRecord)

    @public next: Function,
      default: (acRecord = null)->
        acRecord ?= @[ipcRecord]
        data = @[ipoCursor].next()
        if acRecord?
          if data?
            acRecord.new data
          else
            data
        else
          data

    @public hasNext: Function,
      default: -> @[ipoCursor].hasNext()

    @public getExtra: Function,
      default: -> @[ipoCursor].getExtra arguments...

    @public setBatchSize: Function,
      default: -> @[ipoCursor].setBatchSize arguments...

    @public getBatchSize: Function,
      default: -> @[ipoCursor].getBatchSize arguments...

    @public close: Function,
      default: -> @[ipoCursor].dispose()

    @public dispose: Function,
      default: -> @[ipoCursor].dispose()

    @public count: Function,
      default: -> @[ipoCursor].count arguments...

    @public forEach: Function,
      default: (lambda, acRecord = null)->
        index = 0
        try
          while @hasNext()
            lambda @next(acRecord), index++
          return
        catch err
          @dispose()
          throw err

    @public map: Function,
      default: (lambda, acRecord = null)->
        index = 0
        try
          while @hasNext()
            lambda @next(acRecord), index++
        catch err
          @dispose()
          throw err

    @public filter: Function,
      default: (lambda, acRecord = null)->
        index = 0
        records = []
        try
          while @hasNext()
            record = @next(acRecord)
            if lambda record, index++
              records.push record
          records
        catch err
          @dispose()
          throw err

    @public find: Function,
      default: (lambda, acRecord = null)->
        index = 0
        _record = null
        try
          while @hasNext()
            record = @next(acRecord)
            if lambda record, index++
              _record = record
              break
          _record
        catch err
          @dispose()
          throw err

    @public compact: Function,
      default: (acRecord = null)->
        acRecord ?= @[ipcRecord]
        index = 0
        records = []
        try
          while @hasNext()
            rawRecord = @[ipoCursor].next()
            unless _.isEmpty rawRecord
              record = acRecord.new rawRecord
              records.push record
          records
        catch err
          @dispose()
          throw err

    @public reduce: Function,
      default: (lambda, initialValue, acRecord = null)->
        try
          index = 0
          _initialValue = initialValue
          while @hasNext()
            _initialValue = lambda _initialValue, @next(acRecord), index++
          _initialValue
        catch err
          @dispose()
          throw err

    @public first: Function,
      default: (acRecord = null)->
        try
          if @hasNext()
            @next(acRecord)
          else
            null
        catch err
          @dispose()
          throw err

    constructor: (acRecord, aoCursor = null)->
      super arguments...
      @[ipcRecord] = acRecord
      @[ipoCursor] = aoCursor


  return ArangoExtension::ArangoCursor.initialize()
