# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# эта реализация должна имплементировать методы `parseQuery` и `executeQuery`.
# последний должен возврашать результат с интерфейсом CursorInterface
# но для хранения и получения данных должна обращаться к ArangoDB коллекциям.

{ db }        = require '@arangodb'
qb            = require 'aqb'
Parser        = require 'mongo-parse' #mongo-parse@2.0.2


module.exports = (Module)->
  {
    AnyT, MomentT
    FuncG, UnionG, MaybeG, EnumG, ListG, DictG, InterfaceG
    RecordInterface, CursorInterface, QueryInterface
    Mixin
    Collection, Query
    ArangoCursor
    LogMessage: {
      SEND_TO_LOG
      LEVELS
      DEBUG
    }
    Utils: { _, moment }
  } = Module::

  Module.defineMixin Mixin 'ArangoCollectionMixin', (BaseClass = Collection) ->
    class extends BaseClass
      @inheritProtected()

      # TODO: generateId был удален отсюда, т.к. был объявлен миксин GenerateUuidIdMixin который дефайнит этот метод с uuid.v4(), а использование этого миксина должно быть таковым, чтобы дефолтный generateId из Collection использовался (не возвращающий ничего)

      wrapReference = (value)->
        if _.isString(value) and /^[@]/.test value
          qb.ref value.replace '@', ''
        else
          qb value

      @public @async push: FuncG(RecordInterface, RecordInterface),
        default: (aoRecord)->
          vhObjectForInsert = yield @serialize aoRecord
          voQuery = qb.insert qb vhObjectForInsert
            .into @collectionFullName()
            .returnNew 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::push vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          return yield @normalize voNativeCursor.next()
          # if voNativeCursor.hasNext()
          #   return yield @normalize voNativeCursor.next()
          # else
          #   yield return

      @public @async remove: FuncG([UnionG String, Number]),
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .remove _key: 'doc._key'
            .into @collectionFullName()
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::remove vsQuery #{vsQuery}", LEVELS[DEBUG])
          db._query "#{vsQuery}"
          yield return

      @public @async take: FuncG([UnionG String, Number], MaybeG RecordInterface),
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::take vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          if voNativeCursor.hasNext()
            return yield @normalize voNativeCursor.next()
          else
            yield return

      @public @async takeBy: FuncG([Object, MaybeG Object], CursorInterface),
        default: (query, options = {})->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter @parseFilter Parser.parse query
          if (voSort = options.$sort)?
            for sortObj in voSort
              for own asRef, asSortDirect of sortObj
                voQuery = voQuery.sort wrapReference(asRef), asSortDirect
          if (vnLimit = options.$limit)?
            if (vnOffset = options.$offset)?
              voQuery = voQuery.limit vnOffset, vnLimit
            else
              voQuery = voQuery.limit vnLimit
          voQuery = voQuery.return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::takeBy vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          yield return ArangoCursor.new @, voNativeCursor

      @public @async takeMany: FuncG([ListG UnionG String, Number], CursorInterface),
        default: (ids)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.in qb.ref('doc.id'), qb(ids)
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::takeMany vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          yield return ArangoCursor.new @, voNativeCursor

      @public @async takeAll: FuncG([], CursorInterface),
        default: ->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::takeAll vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          yield return ArangoCursor.new @, voNativeCursor

      @public @async override: FuncG([UnionG(String, Number), RecordInterface], RecordInterface),
        default: (id, aoRecord)->
          vhObjectForUpdate = _.omit (yield @serialize aoRecord), ['id', '_key']
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .update qb.ref 'doc'
            .with qb vhObjectForUpdate
            .into @collectionFullName()
            .returnNew 'newDoc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::override vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          return yield @normalize voNativeCursor.next()

      @public @async includes: FuncG([UnionG String, Number], Boolean),
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .limit qb 1
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::includes vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          yield return voNativeCursor.hasNext()

      @public @async exists: FuncG(Object, Boolean),
        default: (query)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter @parseFilter Parser.parse query
            .limit qb 1
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::exists vsQuery #{vsQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{vsQuery}"
          yield return voNativeCursor.hasNext()

      @public @async length: FuncG([], Number),
        default: ->
          # voQuery = qb.for 'doc'
          #   .in @collectionFullName()
          #   .collectWithCountInto 'count'
          #   .return qb.ref 'count'
          # vsQuery = voQuery.toAQL()
          # voNativeCursor = db._query "#{vsQuery}"
          # yield return voNativeCursor.next()
          collection = db._collection @collectionFullName()
          yield return collection.count()

      buildIntervalQuery = FuncG(
        [Object, MomentT, EnumG('day', 'week', 'month', 'year'), Boolean]
        Object
      ) (aoKey, aoInterval, aoIntervalSize, aoDirect)->
        aoInterval = aoInterval.utc()
        voIntervalStart = aoInterval.startOf(aoIntervalSize).toISOString()
        voIntervalEnd = aoInterval.clone().endOf(aoIntervalSize).toISOString()
        if aoDirect
          qb.and [
            qb.gte aoKey, qb voIntervalStart
            qb.lt aoKey, qb voIntervalEnd
          ]...
        else
          qb.not qb.and [
            qb.gte aoKey, qb voIntervalStart
            qb.lt aoKey, qb voIntervalEnd
          ]...

      @public operatorsMap: DictG(String, Function),
        default:
          # Logical Query Operators
          $and: (items)-> qb.and _.castArray(items)...
          $or: (items)-> qb.or _.castArray(items)...
          $not: (items)-> qb.not _.castArray(items)...
          $nor: (items)-> qb.not qb.or _.castArray(items)... # not or # !(a||b) === !a && !b

          $where: (args...)-> throw new Error 'Not supported'

          # Comparison Query Operators (aoSecond is NOT sub-query)
          $eq: (aoFirst, aoSecond)->
            qb.eq wrapReference(aoFirst), wrapReference(aoSecond) # ==
          $ne: (aoFirst, aoSecond)->
            qb.neq wrapReference(aoFirst), wrapReference(aoSecond) # !=
          $lt: (aoFirst, aoSecond)->
            qb.lt wrapReference(aoFirst), wrapReference(aoSecond) # <
          $lte: (aoFirst, aoSecond)->
            qb.lte wrapReference(aoFirst), wrapReference(aoSecond) # <=
          $gt: (aoFirst, aoSecond)->
            qb.gt wrapReference(aoFirst), wrapReference(aoSecond) # >
          $gte: (aoFirst, aoSecond)->
            qb.gte wrapReference(aoFirst), wrapReference(aoSecond) # >=
          $in: (aoFirst, alItems)-> # check value present in array
            qb.in wrapReference(aoFirst), qb alItems
          $nin: (aoFirst, alItems)-> # ... not present in array
            qb.notIn wrapReference(aoFirst), qb alItems

          # Array Query Operators
          $all: (aoFirst, alItems)-> # contains some values
            qb.and (alItems.map (aoItem)->
              qb.in wrapReference(aoItem), wrapReference(aoFirst))...
          $elemMatch: (aoFirst, aoSecond)-> # conditions for complex item
            wrappedReference = aoFirst.replace '@', ''
            voFilter = qb.and(aoSecond...).toAQL()
            voFirst = qb.expr "LENGTH(#{wrappedReference}[* FILTER #{voFilter}])"
            qb.gt voFirst, qb 0
          $size: (aoFirst, aoSecond)->
            voFirst = qb.expr "LENGTH(#{aoFirst.replace '@', ''})"
            qb.eq voFirst, wrapReference(aoSecond) # condition for array length

          # Element Query Operators
          $exists: (aoFirst, aoSecond)-> # condition for check present some value in field
            voFirst = qb.expr "HAS(#{aoFirst.replace '@', ''})"
            qb.eq voFirst, wrapReference(aoSecond)
          $type: (aoFirst, aoSecond)->
            voFirst = qb.expr "TYPENAME(#{aoFirst.replace '@', ''})"
            qb.eq voFirst, wrapReference(aoSecond) # check value type

          # Evaluation Query Operators
          $mod: (aoFirst, [divisor, remainder])->
            qb.eq qb.mod(wrapReference(aoFirst), qb divisor), qb remainder
          $regex: (aoFirst, aoSecond)-> # value must be string. ckeck it by RegExp.
            regExpDefinitions = /^\/([\s\S]*)\/(i?)$/i.exec aoSecond
            unless regExpDefinitions?
              throw new Error "Invalid Regular Expression"
            [full, regexp, params] = regExpDefinitions
            qb.expr "REGEX_TEST(#{aoFirst.replace '@', ''},
              \"#{String regexp}\",
              #{params is 'i'})"

          # Datetime Query Operators
          $td: (aoFirst, aoSecond)-> # this day (today)
            buildIntervalQuery wrapReference(aoFirst), moment(), 'day', aoSecond
          $ld: (aoFirst, aoSecond)-> # last day (yesterday)
            buildIntervalQuery wrapReference(aoFirst), moment().subtract(1, 'days'), 'day', aoSecond
          $tw: (aoFirst, aoSecond)-> # this week
            buildIntervalQuery wrapReference(aoFirst), moment(), 'week', aoSecond
          $lw: (aoFirst, aoSecond)-> # last week
            buildIntervalQuery wrapReference(aoFirst), moment().subtract(1, 'weeks'), 'week', aoSecond
          $tm: (aoFirst, aoSecond)-> # this month
            buildIntervalQuery wrapReference(aoFirst), moment(), 'month', aoSecond
          $lm: (aoFirst, aoSecond)-> # last month
            buildIntervalQuery wrapReference(aoFirst), moment().subtract(1, 'months'), 'month', aoSecond
          $ty: (aoFirst, aoSecond)-> # this year
            buildIntervalQuery wrapReference(aoFirst), moment(), 'year', aoSecond
          $ly: (aoFirst, aoSecond)-> # last year
            buildIntervalQuery wrapReference(aoFirst), moment().subtract(1, 'years'), 'year', aoSecond

      @public parseFilter: FuncG(InterfaceG({
        field: MaybeG String
        parts: MaybeG ListG Object
        operator: MaybeG String
        operand: MaybeG AnyT
        implicitField: MaybeG Boolean
      }), Object),
        default: ({field, parts = [], operator, operand, implicitField})->
          if field? and operator isnt '$elemMatch' and parts.length is 0
            throw new Error '`$not` must be defined in field operand'  if field is '$not'
            customFilter = @delegate.customFilters[field]
            if (customFilterFunc = customFilter?[operator])?
              qb.expr customFilterFunc.call @, operand
            else
              @operatorsMap[operator] field, operand
          else if field? and operator is '$elemMatch'
            if implicitField is yes
              @operatorsMap[operator] field, parts.map (part)=>
                part.field = "@CURRENT"
                @parseFilter part
            else
              @operatorsMap[operator] field, parts.map (part)=>
                part.field = "@CURRENT.#{part.field}"
                @parseFilter part
          else
            @operatorsMap[operator ? '$and'] parts.map @parseFilter.bind @

      @public @async parseQuery: FuncG(
        [UnionG Object, QueryInterface]
        UnionG Object, String, QueryInterface
      ),
        default: (aoQuery)->
          voQuery = null
          intoUsed = intoPartial = finAggUsed = finAggPartial = null
          isCustomReturn = no
          if aoQuery.$remove?
            yield do @wrap ->
              if aoQuery.$forIn?
                for own asItemRef, asCollectionFullName of aoQuery.$forIn
                  voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                    .in asCollectionFullName
                if (voJoin = aoQuery.$join?.$and)?
                  vlJoinFilters = voJoin.map (mongoFilter)->
                    asItemRef = Object.keys(mongoFilter)[0]
                    {$eq:asRelValue} = mongoFilter[asItemRef]
                    voItemRef = wrapReference asItemRef
                    voRelValue = wrapReference asRelValue
                    qb.eq voItemRef, voRelValue
                  voQuery = voQuery.filter qb.and vlJoinFilters...
                if (voFilter = aoQuery.$filter)?
                  voQuery = voQuery.filter @parseFilter Parser.parse voFilter
                if (voLet = aoQuery.$let)?
                  for own asRef, aoValue of voLet
                    vsValue = String yield @parseQuery Query.new aoValue
                    voQuery = (voQuery ? qb).let asRef, qb.expr vsValue
                if (voSort = aoQuery.$sort)?
                  voQuery = voQuery.sort (do ->
                    vlSort = []
                    for sortObj in voSort
                      for own asRef, asSortDirect of sortObj
                        vlSort.push wrapReference asRef
                        vlSort.push asSortDirect
                    vlSort
                  )...

                if (vnLimit = aoQuery.$limit)?
                  if (vnOffset = aoQuery.$offset)?
                    voQuery = voQuery.limit vnOffset, vnLimit
                  else
                    voQuery = voQuery.limit vnLimit
                isCustomReturn = yes
                voQuery = (voQuery ? qb).remove _key: wrapReference "@doc._key"
                if aoQuery.$into?
                  voQuery = voQuery.into aoQuery.$into
              yield return
          else if aoQuery.$patch?
            yield do @wrap ->
              if aoQuery.$into?
                if aoQuery.$forIn?
                  for own asItemRef, asCollectionFullName of aoQuery.$forIn
                    voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                      .in asCollectionFullName
                  if (voJoin = aoQuery.$join?.$and)?
                    vlJoinFilters = voJoin.map (mongoFilter)->
                      asItemRef = Object.keys(mongoFilter)[0]
                      {$eq:asRelValue} = mongoFilter[asItemRef]
                      voItemRef = wrapReference asItemRef
                      voRelValue = wrapReference asRelValue
                      qb.eq voItemRef, voRelValue
                    voQuery = voQuery.filter qb.and vlJoinFilters...
                  if (voFilter = aoQuery.$filter)?
                    voQuery = voQuery.filter @parseFilter Parser.parse voFilter
                  if (voLet = aoQuery.$let)?
                    for own asRef, aoValue of voLet
                      vsValue = String yield @parseQuery Query.new aoValue
                      voQuery = (voQuery ? qb).let asRef, qb.expr vsValue
                  if (voSort = aoQuery.$sort)?
                    voQuery = voQuery.sort (do ->
                      vlSort = []
                      for sortObj in voSort
                        for own asRef, asSortDirect of sortObj
                          vlSort.push wrapReference asRef
                          vlSort.push asSortDirect
                      vlSort
                    )...

                  if (vnLimit = aoQuery.$limit)?
                    if (vnOffset = aoQuery.$offset)?
                      voQuery = voQuery.limit vnOffset, vnLimit
                    else
                      voQuery = voQuery.limit vnLimit
                vhObjectForUpdate = _.omit aoQuery.$patch, ['id', '_key']
                isCustomReturn = yes
                voQuery = (voQuery ? qb).update qb.ref 'doc'
                  .with qb vhObjectForUpdate
                  .into aoQuery.$into
              yield return
          else if aoQuery.$forIn?
            yield do @wrap ->
              for own asItemRef, asCollectionFullName of aoQuery.$forIn
                voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                  .in asCollectionFullName
              if (voJoin = aoQuery.$join?.$and)?
                vlJoinFilters = voJoin.map (mongoFilter)->
                  asItemRef = Object.keys(mongoFilter)[0]
                  {$eq:asRelValue} = mongoFilter[asItemRef]
                  voItemRef = wrapReference asItemRef
                  voRelValue = wrapReference asRelValue
                  qb.eq voItemRef, voRelValue
                voQuery = voQuery.filter qb.and vlJoinFilters...
              if (voFilter = aoQuery.$filter)?
                voQuery = voQuery.filter @parseFilter Parser.parse voFilter
              if (voLet = aoQuery.$let)?
                for own asRef, aoValue of voLet
                  vsValue = String yield @parseQuery Query.new aoValue
                  voQuery = (voQuery ? qb).let asRef, qb.expr vsValue
              if (voCollect = aoQuery.$collect)?
                isCustomReturn = yes
                for own asRef, aoValue of voCollect
                  vsValue = String yield @parseQuery Query.new aoValue
                  voQuery = voQuery.collect asRef, qb.expr vsValue
              if (vsInto = aoQuery.$into)?
                intoUsed = _.escapeRegExp "FILTER {{INTO #{vsInto}}}"
                intoPartial = "INTO #{vsInto}"
                voQuery = voQuery.filter qb.expr "{{INTO #{vsInto}}}"
              if (voHaving = aoQuery.$having)?
                voQuery = voQuery.filter @parseFilter Parser.parse voHaving
              if (voSort = aoQuery.$sort)?
                voQuery = voQuery.sort (do ->
                  vlSort = []
                  for sortObj in voSort
                    for own asRef, asSortDirect of sortObj
                      vlSort.push wrapReference asRef
                      vlSort.push asSortDirect
                  vlSort
                )...

              if (vnLimit = aoQuery.$limit)?
                if (vnOffset = aoQuery.$offset)?
                  voQuery = voQuery.limit vnOffset, vnLimit
                else
                  voQuery = voQuery.limit vnLimit

              if (aoQuery.$count)?
                isCustomReturn = yes
                voQuery = voQuery.collectWithCountInto 'counter'
                  .return qb.ref('counter').then('counter').else('0')
              else if (vsSum = aoQuery.$sum)?
                isCustomReturn = yes
                finAggUsed = "RETURN {{COLLECT AGGREGATE result = SUM\\(TO_NUMBER\\(#{vsSum.replace '@', ''}\\)\\) RETURN result}}"
                finAggPartial = "COLLECT AGGREGATE result = SUM(TO_NUMBER(#{vsSum.replace '@', ''})) RETURN result"
                voQuery = voQuery.return qb.expr "{{#{finAggPartial}}}"
              else if (vsMin = aoQuery.$min)?
                isCustomReturn = yes
                voQuery = voQuery.sort qb.ref(vsMin.replace '@', '')
                  .limit 1
                  .return qb.ref(vsMin.replace '@', '')
              else if (vsMax = aoQuery.$max)?
                isCustomReturn = yes
                voQuery = voQuery.sort qb.ref(vsMax.replace '@', ''), 'DESC'
                  .limit 1
                  .return qb.ref(vsMax.replace '@', '')
              else if (vsAvg = aoQuery.$avg)?
                isCustomReturn = yes
                finAggUsed = "RETURN {{COLLECT AGGREGATE result = AVG\\(TO_NUMBER\\(#{vsAvg.replace '@', ''}\\)\\) RETURN result}}"
                finAggPartial = "COLLECT AGGREGATE result = AVG(TO_NUMBER(#{vsAvg.replace '@', ''})) RETURN result"
                voQuery = voQuery.return qb.expr "{{#{finAggPartial}}}"
              else
                if aoQuery.$return?
                  if aoQuery.$return isnt '@doc'
                    isCustomReturn = yes
                  voReturn = if _.isString aoQuery.$return
                    qb.ref aoQuery.$return.replace '@', ''
                  else if _.isObject aoQuery.$return
                    vhObj = {}
                    for own key, value of aoQuery.$return
                      vhObj[key] = wrapReference value
                    vhObj
                  if aoQuery.$distinct
                    voQuery = voQuery.returnDistinct voReturn
                  else
                    voQuery = voQuery.return voReturn
              yield return
          vsQuery = voQuery?.toAQL()

          if intoUsed and new RegExp(intoUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(intoUsed), intoPartial
          if finAggUsed and new RegExp(finAggUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(finAggUsed), finAggPartial
          vsQuery = new String vsQuery
          Reflect.defineProperty vsQuery, 'isCustomReturn', value: isCustomReturn
          yield return vsQuery

      @public @async executeQuery: FuncG(
        [UnionG Object, String, QueryInterface]
        CursorInterface
      ),
        default: (asQuery, options)->
          @sendNotification(SEND_TO_LOG, "ArangoCollectionMixin::executeQuery asQuery #{asQuery}", LEVELS[DEBUG])
          voNativeCursor = db._query "#{asQuery}"
          voCursor = if asQuery.isCustomReturn
            ArangoCursor.new null, voNativeCursor
          else
            ArangoCursor.new @, voNativeCursor
          yield return voCursor


      @initializeMixin()
