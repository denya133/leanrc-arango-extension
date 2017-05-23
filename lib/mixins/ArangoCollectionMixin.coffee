# надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
# эта реализация должна имплементировать методы `parseQuery` и `executeQuery`.
# последний должен возврашать результат с интерфейсом CursorInterface
# но для хранения и получения данных должна обращаться к ArangoDB коллекциям.

_             = require 'lodash'
{ db }        = require '@arangodb'
qb            = require 'aqb'
Parser        = require 'mongo-parse' #mongo-parse@2.0.2
moment        = require 'moment'


module.exports = (Module)->
  Module.defineMixin (BaseClass) ->
    class ArangoCollectionMixin extends BaseClass
      @inheritProtected()
      @implements Module::QueryableMixinInterface

      @public @async push: Function,
        default: (aoRecord)->
          voQuery = Module::Query.new()
            .insert aoRecord
            .into @collectionFullName()
          yield @query voQuery
          return yes

      @public @async remove: Function,
        default: (id)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$eq: id}
            .remove()
          yield @query voQuery
          return yes

      @public @async take: Function,
        default: (id)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$eq: id}
            .return '@doc'
          cursor = yield @query voQuery
          cursor.first()

      @public @async takeMany: Function,
        default: (ids)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$in: ids}
            .return '@doc'
          yield @query voQuery

      @public @async takeAll: Function,
        default: ->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .return '@doc'
          yield @query voQuery

      @public @async override: Function,
        default: (id, aoRecord)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$eq: id}
            .replace aoRecord
          yield @query voQuery

      @public @async patch: Function,
        default: (id, aoRecord)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$eq: id}
            .update aoRecord
          yield @query voQuery

      @public @async includes: Function,
        default: (id)->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .filter '@doc._key': {$eq: id}
            .limit 1
            .return '@doc'
          cursor = yield @query voQuery
          cursor.hasNext()

      @public @async length: Function,
        default: ->
          voQuery = Module::Query.new()
            .forIn '@doc': @collectionFullName()
            .count()
          cursor = yield @query voQuery
          cursor.first()

      wrapReference = (value)->
        if _.isString(value) and /^[@]/.test value
          qb.ref value.replace '@', ''
        else
          qb value

      @public operatorsMap: Object,
        default:
          # Logical Query Operators
          $and: (args...)-> qb.and args...
          $or: (args...)-> qb.or args...
          $not: (args...)-> qb.not args...
          $nor: (args...)-> qb.not qb.or args... # not or # !(a||b) === !a && !b

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
            qb.and alItems.map (aoItem)->
              qb.in wrapReference(aoItem), wrapReference(aoFirst)
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
            qb.expr "REGEX_TEST(#{aoFirst.replace '@', ''}, \"#{String aoSecond}\")"

          # Datetime Query Operators
          $td: (aoFirst, aoSecond)-> # this day (today)
            todayStart = moment().startOf 'day'
            todayEnd = moment().endOf 'day'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb todayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb todayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb todayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb todayEnd.toISOString()
              ]...
          $ld: (aoFirst, aoSecond)-> # last day (yesterday)
            yesterdayStart = moment().subtract(1, 'days').startOf 'day'
            yesterdayEnd = moment().subtract(1, 'days').endOf 'day'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst),qb  yesterdayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb yesterdayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb yesterdayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb yesterdayEnd.toISOString()
              ]...
          $tw: (aoFirst, aoSecond)-> # this week
            weekStart = moment().startOf 'week'
            weekEnd = moment().endOf 'week'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb weekStart.toISOString()
                qb.lt wrapReference(aoFirst), qb weekEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb weekStart.toISOString()
                qb.lt wrapReference(aoFirst), qb weekEnd.toISOString()
              ]...
          $lw: (aoFirst, aoSecond)-> # last week
            weekStart = moment().subtract(1, 'weeks').startOf 'week'
            weekEnd = weekStart.clone().endOf 'week'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb weekStart.toISOString()
                qb.lt wrapReference(aoFirst), qb weekEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb weekStart.toISOString()
                qb.lt wrapReference(aoFirst), qb weekEnd.toISOString()
              ]...
          $tm: (aoFirst, aoSecond)-> # this month
            firstDayStart = moment().startOf 'month'
            lastDayEnd = moment().endOf 'month'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
          $lm: (aoFirst, aoSecond)-> # last month
            firstDayStart = moment().subtract(1, 'months').startOf 'month'
            lastDayEnd = firstDayStart.clone().endOf 'month'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
          $ty: (aoFirst, aoSecond)-> # this year
            firstDayStart = moment().startOf 'year'
            lastDayEnd = firstDayStart.clone().endOf 'year'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
          $ly: (aoFirst, aoSecond)-> # last year
            firstDayStart = moment().subtract(1, 'years').startOf 'year'
            lastDayEnd = firstDayStart.clone().endOf 'year'
            if aoSecond
              qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...
            else
              qb.not qb.and [
                qb.gte wrapReference(aoFirst), qb firstDayStart.toISOString()
                qb.lt wrapReference(aoFirst), qb lastDayEnd.toISOString()
              ]...

      @public parseFilter: Function,
        args: [Object]
        return: Module::ANY
        default: ({field, parts, operator, operand, implicitField})->
          if field? and operator isnt '$elemMatch' and parts.length is 0
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

      @public parseQuery: Function,
        default: (aoQuery)->
          voQuery = null
          intoUsed = intoPartial = finAggUsed = finAggPartial = null
          if aoQuery.$remove?
            do =>
              if aoQuery.$forIn?
                for own asItemRef, asCollectionFullName of aoQuery.$forIn
                  voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                    .in asCollectionFullName
                if (voJoin = aoQuery.$join)?
                  vlJoinFilters = voJoin.$and.map (asItemRef, {$eq:asRelValue})->
                    voItemRef = qb.ref asItemRef.replace '@', ''
                    voRelValue = qb.ref asRelValue.replace '@', ''
                    qb.eq voItemRef, voRelValue
                  voQuery = voQuery.filter qb.and vlJoinFilters...
                if (voFilter = aoQuery.$filter)?
                  voQuery = voQuery.filter @parseFilter Parser.parse voFilter
                if (voLet = aoQuery.$let)?
                  for own asRef, aoValue of voLet
                    voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
                voQuery = (voQuery ? qb).remove aoQuery.$remove
                if aoQuery.$into?
                  voQuery = voQuery.into aoQuery.$into
          else if (voRecord = aoQuery.$insert)?
            do =>
              if aoQuery.$into?
                vhObjectForInsert = @serializer.serialize voRecord
                voQuery = (voQuery ? qb).insert vhObjectForInsert
                  .into aoQuery.$into
          else if (voRecord = aoQuery.$update)?
            do =>
              if aoQuery.$into?
                if aoQuery.$forIn?
                  for own asItemRef, asCollectionFullName of aoQuery.$forIn
                    voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                      .in asCollectionFullName
                  if (voJoin = aoQuery.$join?.$and)?
                    vlJoinFilters = voJoin.map (asItemRef, {$eq:asRelValue})->
                      voItemRef = qb.ref asItemRef.replace '@', ''
                      voRelValue = qb.ref asRelValue.replace '@', ''
                      qb.eq voItemRef, voRelValue
                    voQuery = voQuery.filter qb.and vlJoinFilters...
                  if (voFilter = aoQuery.$filter)?
                    voQuery = voQuery.filter @parseFilter Parser.parse voFilter
                  if (voLet = aoQuery.$let)?
                    for own asRef, aoValue of voLet
                      voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
                vhObjectForUpdate = _.omit @serializer.serialize(voRecord), ['id', '_key']
                voQuery = (voQuery ? qb).update qb.ref 'doc'
                  .with vhObjectForUpdate
                  .into aoQuery.$into
          else if (voRecord = aoQuery.$replace)?
            do =>
              if aoQuery.$into?
                if aoQuery.$forIn?
                  for own asItemRef, asCollectionFullName of aoQuery.$forIn
                    voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                      .in asCollectionFullName
                  if (voJoin = aoQuery.$join?.$and)?
                    vlJoinFilters = voJoin.map (asItemRef, {$eq:asRelValue})->
                      voItemRef = qb.ref asItemRef.replace '@', ''
                      voRelValue = qb.ref asRelValue.replace '@', ''
                      qb.eq voItemRef, voRelValue
                    voQuery = voQuery.filter qb.and vlJoinFilters...
                  if (voFilter = aoQuery.$filter)?
                    voQuery = voQuery.filter @parseFilter Parser.parse voFilter
                  if (voLet = aoQuery.$let)?
                    for own asRef, aoValue of voLet
                      voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
                vhObjectForReplace = _.omit @serializer.serialize(voRecord), ['id', '_key']
                voQuery = (voQuery ? qb).replace qb.ref 'doc'
                  .with vhObjectForReplace
                  .into aoQuery.$into
          else if aoQuery.$forIn?
            do =>
              for own asItemRef, asCollectionFullName of aoQuery.$forIn
                voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
                  .in asCollectionFullName
              if (voJoin = aoQuery.$join)?
                vlJoinFilters = voJoin.$and.map (asItemRef, {$eq:asRelValue})->
                  voItemRef = qb.ref asItemRef.replace '@', ''
                  voRelValue = qb.ref asRelValue.replace '@', ''
                  qb.eq voItemRef, voRelValue
                voQuery = voQuery.filter qb.and vlJoinFilters...
              if (voFilter = aoQuery.$filter)?
                voQuery = voQuery.filter @parseFilter Parser.parse voFilter
              if (voLet = aoQuery.$let)?
                for own asRef, aoValue of voLet
                  voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
              if (voCollect = aoQuery.$collect)?
                for own asRef, aoValue of voCollect
                  voQuery = voQuery.collect qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
              if (vsInto = aoQuery.$into)?
                intoUsed = _.escapeRegExp "FILTER {{INTO #{vsInto}}}"
                intoPartial = "INTO #{vsInto}"
                query = query.filter qb.expr "{{INTO #{vsInto}}}"
              if (voHaving = aoQuery.$having)?
                voQuery = voQuery.filter @parseFilter Parser.parse voHaving
              if (voSort = aoQuery.$sort)?
                for {asRef, asSortDirect} in aoQuery.$sort
                  do (asRef, asSortDirect)->
                    voQuery = voQuery.sort qb.ref(asRef.replace '@', ''), asSortDirect

              if (vnLimit = aoQuery.$limit)?
                if (vnOffset = aoQuery.$offset)?
                  voQuery = voQuery.limit vnOffset, vnLimit
                else
                  voQuery = voQuery.limit vnLimit

              if (aoQuery.$count)?
                voQuery = voQuery.collectWithCountInto 'counter'
                  .return qb.ref('counter').then('counter').else('0')
              else if (vsSum = aoQuery.$sum)?
                finAggUsed = "RETURN {{COLLECT AGGREGATE result = SUM\\(TO_NUMBER\\(#{vsSum.replace '@', ''}\\)\\) RETURN result}}"
                finAggPartial = "COLLECT AGGREGATE result = SUM(TO_NUMBER(#{vsSum.replace '@', ''})) RETURN result"
                voQuery = voQuery.return qb.expr "{{#{finAggPartial}}}"
              else if (vsMin = aoQuery.$min)?
                voQuery = voQuery.sort qb.ref(vsMin.replace '@', '')
                  .limit 1
                  .return qb.ref(vsMin.replace '@', '')
              else if (vsMax = aoQuery.$max)?
                voQuery = voQuery.sort qb.ref(vsMax.replace '@', ''), 'DESC'
                  .limit 1
                  .return qb.ref(vsMax.replace '@', '')
              else if (vsAvg = aoQuery.$avg)?
                finAggUsed = "RETURN {{COLLECT AGGREGATE result = AVG\\(TO_NUMBER\\(#{vsAvg.replace '@', ''}\\)\\) RETURN result}}"
                finAggPartial = "COLLECT AGGREGATE result = AVG(TO_NUMBER(#{vsAvg.replace '@', ''})) RETURN result"
                voQuery = voQuery.return qb.expr "{{#{finAggPartial}}}"
              else
                if aoQuery.$return?
                  voReturn = if _.isString aoQuery.$return
                    qb.ref aoQuery.$return.replace '@', ''
                  else if _.isObject aoQuery.$return
                    vhObj = {}
                    for own key, value of aoQuery.$return
                      do (key, value)->
                        vhObj[key] = qb.ref value.replace '@', ''
                    vhObj
                  if aoQuery.$distinct
                    voQuery = voQuery.returnDistinct voReturn
                  else
                    voQuery = voQuery.return voReturn
          vsQuery = voQuery.toAQL()

          if intoUsed and new RegExp(intoUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(intoUsed), intoPartial
          if finAggUsed and new RegExp(finAggUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(finAggUsed), finAggPartial

          return vsQuery

      @public @async executeQuery: Function,
        default: (asQuery, options)->
          voNativeCursor = yield db._query asQuery
          voCursor = Module::ArangoCursor.new @delegate, voNativeCursor
          return voCursor


    ArangoCollectionMixin.initializeMixin()
