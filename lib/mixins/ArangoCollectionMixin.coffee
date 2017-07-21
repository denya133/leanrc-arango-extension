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
  Module.defineMixin Module::Collection, (BaseClass) ->
    class ArangoCollectionMixin extends BaseClass
      @inheritProtected()
      @implements Module::QueryableCollectionMixinInterface

      # TODO: generateId был удален отсюда, т.к. был объявлен миксин GenerateUuidIdMixin который дефайнит этот метод с uuid.v4(), а использование этого миксина должно быть таковым, чтобы дефолтный generateId из Collection использовался (не возвращающий ничего)

      @public @async push: Function,
        default: (aoRecord)->
          vhObjectForInsert = @serialize aoRecord
          voQuery = qb.insert qb vhObjectForInsert
            .into @collectionFullName()
            .returnNew 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return @normalize voNativeCursor.next()

      @public @async remove: Function,
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .remove _key: 'doc._key'
            .into @collectionFullName()
          vsQuery = voQuery.toAQL()
          db._query "#{vsQuery}"
          yield return

      @public @async take: Function,
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          console.log '????? vsQuery', vsQuery, voNativeCursor.next()
          yield return @normalize voNativeCursor.next()

      @public @async takeBy: Function,
        default: (query)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter @parseFilter Parser.parse query
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return Module::ArangoCursor.new @, voNativeCursor

      @public @async takeMany: Function,
        default: (ids)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.in qb.ref('doc.id'), qb(ids)
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return Module::ArangoCursor.new @, voNativeCursor

      @public @async takeAll: Function,
        default: ->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return Module::ArangoCursor.new @, voNativeCursor

      @public @async override: Function,
        default: (id, aoRecord)->
          vhObjectForUpdate = _.omit @serialize(voRecord), ['id', '_key']
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .update qb.ref 'doc'
            .with qb vhObjectForUpdate
            .into @collectionFullName()
            .returnNew 'newDoc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return @normalize voNativeCursor.next()

      @public @async includes: Function,
        default: (id)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter qb.eq qb.ref('doc.id'), qb(id)
            .limit qb 1
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return voNativeCursor.hasNext()

      @public @async exists: Function,
        default: (query)->
          voQuery = qb.for 'doc'
            .in @collectionFullName()
            .filter @parseFilter Parser.parse query
            .limit qb 1
            .return qb.ref 'doc'
          vsQuery = voQuery.toAQL()
          voNativeCursor = db._query "#{vsQuery}"
          yield return voNativeCursor.hasNext()

      @public @async length: Function,
        default: ->
          # voQuery = qb.for 'doc'
          #   .in @collectionFullName()
          #   .collectWithCountInto 'count'
          #   .return qb.ref 'count'
          # vsQuery = voQuery.toAQL()
          # voNativeCursor = db._query "#{vsQuery}"
          # yield return voNativeCursor.next()
          collection = db._collection @collectionFullName()
          yield return collection.figures().alive.count

      wrapReference = (value)->
        if _.isString(value) and /^[@]/.test value
          qb.ref value.replace '@', ''
        else
          qb value

      @public operatorsMap: Object,
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
        default: ({field, parts = [], operator, operand, implicitField})->
          if field? and operator isnt '$elemMatch' and parts.length is 0
            throw new Error '`$not` must be defined in field operand'  if field is '$not'
            customFilter = @delegate.customFilters[field]
            if (customFilterFunc = customFilter?[operator])?
              customFilterFunc.call @, operand
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

      @public @async parseQuery: Function,
        default: (aoQuery)->
          voQuery = null
          intoUsed = intoPartial = finAggUsed = finAggPartial = null
          isCustomReturn = no
          if aoQuery.$remove?
            do =>
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
                    voQuery = (voQuery ? qb).let wrapReference(asRef), qb.expr @parseQuery Module::Query.new aoValue
                isCustomReturn = yes
                voQuery = (voQuery ? qb).remove _key: wrapReference "@doc._key"
                if aoQuery.$into?
                  voQuery = voQuery.into aoQuery.$into
          # else if (voRecord = aoQuery.$insert)?
          #   do =>
          #     if aoQuery.$into?
          #       vhObjectForInsert = @serialize voRecord
          #       voQuery = (voQuery ? qb).insert qb vhObjectForInsert
          #         .into aoQuery.$into
          else if aoQuery.$patch?
            do =>
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
                      voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
                vhObjectForUpdate = _.omit aoQuery.$patch, ['id', '_key']
                isCustomReturn = yes
                voQuery = (voQuery ? qb).update qb.ref 'doc'
                  .with qb vhObjectForUpdate
                  .into aoQuery.$into
                # voQuery = voQuery.returnNew 'newDoc'
          # else if (voRecord = aoQuery.$replace)?
          #   do =>
          #     if aoQuery.$into?
          #       if aoQuery.$forIn?
          #         for own asItemRef, asCollectionFullName of aoQuery.$forIn
          #           voQuery = (voQuery ? qb).for qb.ref asItemRef.replace '@', ''
          #             .in asCollectionFullName
          #         if (voJoin = aoQuery.$join?.$and)?
          #           vlJoinFilters = voJoin.map (mongoFilter)->
          #             asItemRef = Object.keys(mongoFilter)[0]
          #             {$eq:asRelValue} = mongoFilter[asItemRef]
          #             voItemRef = wrapReference asItemRef
          #             voRelValue = wrapReference asRelValue
          #             qb.eq voItemRef, voRelValue
          #           voQuery = voQuery.filter qb.and vlJoinFilters...
          #         if (voFilter = aoQuery.$filter)?
          #           voQuery = voQuery.filter @parseFilter Parser.parse voFilter
          #         if (voLet = aoQuery.$let)?
          #           for own asRef, aoValue of voLet
          #             voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
          #       vhObjectForReplace = _.omit @serialize(voRecord), ['id', '_key']
          #       voQuery = (voQuery ? qb).replace qb.ref 'doc'
          #         .with qb vhObjectForReplace
          #         .into aoQuery.$into
          #       voQuery = voQuery.returnNew 'new_doc'
          else if aoQuery.$forIn?
            do =>
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
                  voQuery = (voQuery ? qb).let qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
              if (voCollect = aoQuery.$collect)?
                isCustomReturn = yes
                for own asRef, aoValue of voCollect
                  voQuery = voQuery.collect qb.ref(asRef.replace '@', ''), qb.expr @parseQuery Module::Query.new aoValue
              if (vsInto = aoQuery.$into)?
                intoUsed = _.escapeRegExp "FILTER {{INTO #{vsInto}}}"
                intoPartial = "INTO #{vsInto}"
                voQuery = voQuery.filter qb.expr "{{INTO #{vsInto}}}"
              if (voHaving = aoQuery.$having)?
                voQuery = voQuery.filter @parseFilter Parser.parse voHaving
              if (voSort = aoQuery.$sort)?
                for sortObj in aoQuery.$sort
                  do (sortObj)->
                    for own asRef, asSortDirect of sortObj
                      do (asRef, asSortDirect)->
                        voQuery = voQuery.sort qb.ref(asRef.replace '@', ''), asSortDirect

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
          vsQuery = voQuery?.toAQL()

          if intoUsed and new RegExp(intoUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(intoUsed), intoPartial
          if finAggUsed and new RegExp(finAggUsed).test vsQuery
            vsQuery = vsQuery.replace new RegExp(finAggUsed), finAggPartial
          vsQuery = new String vsQuery
          Reflect.defineProperty vsQuery, 'isCustomReturn', value: isCustomReturn
          yield return vsQuery

      @public @async executeQuery: Function,
        default: (asQuery, options)->
          voNativeCursor = db._query "#{asQuery}"
          voCursor = if asQuery.isCustomReturn
            Module::ArangoCursor.new null, voNativeCursor
          else
            Module::ArangoCursor.new @, voNativeCursor
          yield return voCursor


    ArangoCollectionMixin.initializeMixin()
