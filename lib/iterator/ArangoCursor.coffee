

# TODO: Возможно стоит подумать над тем, чтобы повторно реиспользовать курсор, по которому уже прошлись один раз - например сохранять все итемы в кеш-скрытый массив, чтобы потом итерировать уже по ним.

module.exports = (Module)->
  {
    AnyT, NilT, PointerT
    FuncG, MaybeG, UnionG
    CollectionInterface, CursorInterface
    CoreObject
    Utils: { _ }
  } = Module::

  class ArangoCursor extends CoreObject
    @inheritProtected()
    @implements CursorInterface

    @module Module

    ipoCursor = PointerT @private cursor: MaybeG Object
    ipoCollection = PointerT @private collection: MaybeG CollectionInterface

    @public isClosed: Boolean,
      default: no

    @public setIterable: FuncG(Object, CursorInterface),
      default: (aoCursor)->
        @[ipoCursor] = aoCursor
        return @

    @public setCollection: FuncG(CollectionInterface, CursorInterface),
      default: (aoCollection)->
        @[ipoCollection] = aoCollection
        return @

    @public @async toArray: FuncG([], Array),
      default: ->
        while yield @hasNext()
          yield @next()

    @public @async next: FuncG([], MaybeG AnyT),
      default: ->
        unless @[ipoCursor]?
          yield return
        data = yield Module::Promise.resolve @[ipoCursor].next()
        switch
          when not data?
            yield return data
          when @[ipoCollection]?
            return yield @[ipoCollection].normalize data
          else
            yield return data

    @public @async hasNext: FuncG([], Boolean),
      default: -> yield Module::Promise.resolve @[ipoCursor].hasNext()

    @public @async close: Function,
      default: ->
        yield Module::Promise.resolve @[ipoCursor]?.dispose()
        @isClosed = yes
        yield return

    @public @async count: FuncG([], Number),
      default: (args...)->
        unless @[ipoCursor]?
          yield return 0
        return yield Module::Promise.resolve @[ipoCursor].count args...

    @public @async forEach: FuncG(Function, NilT),
      default: (lambda)->
        index = 0
        try
          while yield @hasNext()
            yield lambda (yield @next()), index++
          return
        catch err
          yield @close()
          throw err

    @public @async map: FuncG(Function, Array),
      default: (lambda)->
        index = 0
        try
          while (yield @hasNext())
            yield lambda (yield @next()), index++
        catch err
          yield @close()
          throw err

    @public @async filter: FuncG(Function, Array),
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

    @public @async find: FuncG(Function, MaybeG AnyT),
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

    @public @async compact: FuncG([], Array),
      default: ->
        unless @[ipoCursor]?
          yield return []
        index = 0
        results = []
        try
          while yield @hasNext()
            rawResult = yield Module::Promise.resolve @[ipoCursor].next()
            unless _.isEmpty rawResult
              result = switch
                when @[ipoCollection]?
                  yield @[ipoCollection].normalize rawResult
                else
                  rawResult
              results.push result
          yield return results
        catch err
          yield @close()
          throw err

    @public @async reduce: FuncG([Function, AnyT], AnyT),
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

    @public @async first: FuncG([], MaybeG AnyT),
      default: ->
        try
          result = if yield @hasNext()
            yield @next()
          else
            null
          yield return result
        catch err
          yield @close()
          throw err

    @public @static @async restoreObject: Function,
      default: ->
        throw new Error "restoreObject method not supported for #{@name}"
        yield return

    @public @static @async replicateObject: Function,
      default: ->
        throw new Error "replicateObject method not supported for #{@name}"
        yield return

    @public init: FuncG([MaybeG(CollectionInterface), MaybeG Object]),
      default: (aoCollection = null, aoCursor = null)->
        @super arguments...
        @[ipoCursor] = aoCursor if aoCursor?
        @[ipoCollection] = aoCollection if aoCollection?
        return


    @initialize()
