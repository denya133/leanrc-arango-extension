# AISC - Arango Inter-Service Communication
# этот миксин нужен, чтобы объявить медиатор, который будет предоставлять доступ к апи для клиентов, которые так же как этот запущены на платформе ArangoDB как микросервисы.
# для того чтобы обратиться из клиентского модуля к этому сервису будет использоваться обращение через module.context.dependencies....
# а с этой стороны модуля за взаимодействие будет отвечать этот медиатор
# по сути он просто будет врапить хендлеры (экшены) которые объявляются в Stock классах, или делать что-то эквивалентное.


# TODO: надо переадаптировать этот миксин в ...CollectionMixin чтобы за данными обращаться из коллекции сквозь прослойки аранги напрямую к работающему сервису.

# TODO: !!!! Поначалу было опасно начинать этот миксин, т.к. можно было закопаться с вычислением локов (т.к. транзакция открывалась в switch классе), но после того, как открытие транзакции было перенесено в ресурс. можно за это не переживать. Т.е. можно при появлении свободного времени взяться за реализацию этого миксина
semver        = require 'semver'


module.exports = (Module)->
  {
    APPLICATION_SWITCH
    APPLICATION_MEDIATOR
    AnyT, NilT, PointerT
    FuncG, UnionG, MaybeG, EnumG, ListG, StructG, DictG
    RecordInterface, CursorInterface, QueryInterface
    Mixin
    Collection, Cursor
    LogMessage: {
      SEND_TO_LOG
      LEVELS
      DEBUG
    }
    Utils: { _, inflect }
  } = Module::

  Module.defineMixin Mixin 'ArangoForeignCollectionMixin', (BaseClass = Collection) ->
    class extends BaseClass
      @inheritProtected()

      ipsRecordMultipleName = PointerT @private recordMultipleName: String
      ipsRecordSingleName = PointerT @private recordSingleName: String

      @public recordMultipleName: FuncG([], String),
        default: ->
          @[ipsRecordMultipleName] ?= inflect.pluralize @recordSingleName()

      @public recordSingleName: FuncG([], String),
        default: ->
          @[ipsRecordSingleName] ?= inflect.underscore @delegate.name.replace /Record$/, ''

      @public @async push: FuncG(RecordInterface, RecordInterface),
        default: (aoRecord)->
          params = {}
          params.requestType = 'push'
          params.recordName = @delegate.name
          params.snapshot = yield @serialize aoRecord

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            voRecord = yield @normalize body[@recordSingleName()]
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voRecord

      @public @async remove: FuncG([UnionG String, Number], NilT),
        default: (id)->
          params = {}
          params.requestType = 'remove'
          params.recordName = @delegate.name
          params.id = id

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "
          yield return

      @public @async take: FuncG([UnionG String, Number], RecordInterface),
        default: (id)->
          params = {}
          params.requestType = 'take'
          params.recordName = @delegate.name
          params.id = id

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            voRecord = yield @normalize body[@recordSingleName()]
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voRecord

      @public @async takeBy: FuncG([Object, MaybeG Object], CursorInterface),
        default: (query, options = {})->
          params = {}
          params.requestType = 'takeBy'
          params.recordName = @delegate.name
          params.query = $filter: query
          params.query.$sort = options.$sort if options.$sort?
          params.query.$limit = options.$limit if options.$limit?
          params.query.$offset = options.$offset if options.$offset?

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            vhRecordsData = body[@recordMultipleName()]
            voCursor = Cursor.new @, vhRecordsData
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voCursor

      @public @async takeMany: FuncG([ListG UnionG String, Number], CursorInterface),
        default: (ids)->
          params = {}
          params.requestType = 'takeBy'
          params.recordName = @delegate.name
          params.query = $filter: '@doc.id': {$in: ids}

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            vhRecordsData = body[@recordMultipleName()]
            voCursor = Cursor.new @, vhRecordsData
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voCursor

      @public @async takeAll: FuncG([], CursorInterface),
        default: ->
          params = {}
          params.requestType = 'takeAll'
          params.recordName = @delegate.name
          params.query = {}

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            vhRecordsData = body[@recordMultipleName()]
            voCursor = Cursor.new @, vhRecordsData
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voCursor

      @public @async override: FuncG([UnionG(String, Number), RecordInterface], RecordInterface),
        default: (id, aoRecord)->
          params = {}
          params.requestType = 'override'
          params.recordName = @delegate.name
          params.snapshot = yield @serialize aoRecord
          params.id = id

          request = @requestFor params
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res
          if body? and body isnt ''
            body = JSON.parse body if _.isString body
            voRecord = yield @normalize body[@recordSingleName()]
          else
            throw new Error "
              Record payload has not existed in response body.
            "
          yield return voRecord

      @public @async includes: FuncG([UnionG String, Number], Boolean),
        default: (id)->
          voQuery =
            $forIn: '@doc': @collectionFullName()
            $filter: '@doc.id': {$eq: id}
            $limit: 1
            $return: '@doc'
          return yield (yield @query voQuery).hasNext()

      @public @async length: FuncG([], Number),
        default: ->
          voQuery =
            $forIn: '@doc': @collectionFullName()
            $count: yes
          return yield (yield @query voQuery).first()

      @public headers: MaybeG DictG String, String
      @public host: String,
        default: 'http://127.0.0.1'
      @public dependencyName: String
      @public namespace: String,
        get: ->
          conf = @Module.context().manifest.dependencies[@dependencyName]
          conf.version
      @public queryEndpoint: String,
        default: 'query'

      @public headersForRequest: FuncG(StructG({
        requestType: String
        recordName: String
        snapshot: MaybeG Object
        id: MaybeG String
        query: MaybeG Object
        isCustomReturn: MaybeG Boolean
      }), DictG String, String),
        default: (params)->
          headers = @headers ? {}
          headers['Accept'] = 'application/json'
          if params.requestType in ['query', 'patchBy', 'removeBy']
            headers['Authorization'] = "Bearer #{@configs.apiKey}"
          else
            if params.requestType in ['takeAll', 'takeBy']
              headers['NonLimitation'] = @configs.apiKey
            service = @facade.retrieveMediator APPLICATION_MEDIATOR
              .getViewComponent()
            if service.context?
              if service.context.headers['authorization'] is "Bearer #{@configs.apiKey}"
                headers['Authorization'] = "Bearer #{@configs.apiKey}"
              else
                sessionCookie = service.context.cookies.get @configs.sessionCookie
                headers['Cookie'] = "#{@configs.sessionCookie}=#{sessionCookie}"
            else
              headers['Authorization'] = "Bearer #{@configs.apiKey}"
          headers

      @public methodForRequest: FuncG(StructG({
        requestType: String
        recordName: String
        snapshot: MaybeG Object
        id: MaybeG String
        query: MaybeG Object
        isCustomReturn: MaybeG Boolean
      }), String),
        default: ({requestType})->
          switch requestType
            when 'query' then 'POST'
            when 'patchBy' then 'POST'
            when 'removeBy' then 'POST'
            when 'takeAll' then 'GET'
            when 'takeBy' then 'GET'
            when 'take' then 'GET'
            when 'push' then 'POST'
            when 'remove' then 'DELETE'
            when 'override' then 'PUT'
            else
              'GET'

      @public dataForRequest: FuncG(StructG({
        requestType: String
        recordName: String
        snapshot: MaybeG Object
        id: MaybeG String
        query: MaybeG Object
        isCustomReturn: MaybeG Boolean
      }), MaybeG Object),
        default: ({recordName, snapshot, requestType, query})->
          if snapshot? and requestType in ['push', 'override']
            return snapshot
          else if requestType in ['query', 'patchBy', 'removeBy']
            return {query}
          else
            return

      @public urlForRequest: FuncG(StructG({
        requestType: String
        recordName: String
        snapshot: MaybeG Object
        id: MaybeG String
        query: MaybeG Object
        isCustomReturn: MaybeG Boolean
      }), String),
        default: (params)->
          {recordName, snapshot, id, requestType, query} = params
          @buildURL recordName, snapshot, id, requestType, query

      @public pathForType: FuncG(String, String),
        default: (recordName)->
          inflect.pluralize inflect.underscore recordName.replace /Record$/, ''

      @public urlPrefix: FuncG([MaybeG(String), MaybeG String], String),
        default: (path, parentURL)->
          if not @host or @host is '/'
            @host = ''

          if path
            # Protocol relative url
            if /^\/\//.test(path) or /http(s)?:\/\//.test(path)
              # Do nothing, the full @host is already included.
              return path

            # Absolute path
            else if path.charAt(0) is '/'
              return "#{@host}#{path}"
            # Relative path
            else
              return "#{parentURL}/#{path}"

          # No path provided
          url = []
          if @host then url.push @host
          if @namespace then url.push @namespace
          return url.join '/'

      @public FuncG([String, MaybeG(Object), MaybeG(UnionG Number, String), MaybeG Boolean], String),
        default: (recordName, query, id, isQueryable)->
          url = []
          prefix = @urlPrefix()

          if recordName
            path = @pathForType recordName
            url.push path if path

          if isQueryable and @queryEndpoint?
            url.push encodeURIComponent @queryEndpoint
          url.unshift prefix if prefix

          url.push id if id?

          url = url.join '/'
          if not @host and url and url.charAt(0) isnt '/'
            url = '/' + url
          if query?
            query = encodeURIComponent JSON.stringify query ? ''
            url += "?query=#{query}"
          return url

      @public urlForQuery: FuncG([String, MaybeG Object], String),
        default: (recordName, query)->
          @makeURL recordName, null, null, yes

      @public urlForPatchBy: FuncG([String, MaybeG Object], String),
        default: (recordName, query)->
          @makeURL recordName, null, null, yes

      @public urlForRemoveBy: FuncG([String, MaybeG Object], String),
        default: (recordName, query)->
          @makeURL recordName, null, null, yes

      @public urlForTakeAll: FuncG([String, MaybeG Object], String),
        default: (recordName, query)->
          @makeURL recordName, query, null, no

      @public urlForTakeBy: FuncG([String, MaybeG Object], String),
        default: (recordName, query)->
          @makeURL recordName, query, null, no

      @public urlForTake: FuncG([String, String], String),
        default: (recordName, id)->
          @makeURL recordName, null, id, no

      @public urlForPush: FuncG([String, Object], String),
        default: (recordName, snapshot)->
          @makeURL recordName, null, null, no

      @public urlForRemove: FuncG([String, String], String),
        default: (recordName, id)->
          @makeURL recordName, null, id, no

      @public urlForOverride: FuncG([String, Object, String], String),
        default: (recordName, snapshot, id)->
          @makeURL recordName, null, id, no

      @public buildURL: FuncG([String, MaybeG(Object), MaybeG(String), String, MaybeG Object], String),
        default: (recordName, snapshot, id, requestType, query)->
          switch requestType
            when 'query'
              @urlForQuery recordName, query
            when 'patchBy'
              @urlForPatchBy recordName, query
            when 'removeBy'
              @urlForRemoveBy recordName, query
            when 'takeAll'
              @urlForTakeAll recordName, query
            when 'takeBy'
              @urlForTakeBy recordName, query
            when 'take'
              @urlForTake recordName, id
            when 'push'
              @urlForPush recordName, snapshot
            when 'remove'
              @urlForRemove recordName, id
            when 'override'
              @urlForOverride recordName, snapshot, id
            else
              vsMethod = "urlFor#{inflect.camelize requestType}"
              @[vsMethod]? recordName, query, snapshot, id

      @public requestFor: FuncG(StructG({
        requestType: String
        recordName: String
        snapshot: MaybeG Object
        id: MaybeG String
        query: MaybeG Object
        isCustomReturn: MaybeG Boolean
      }), StructG {
        method: String
        url: String
        headers: Object
        data: MaybeG Object
      }),
        default: (params)->
          method  = @methodForRequest params
          url     = @urlForRequest params
          headers = {}
          for own headerName, headerValue of @headersForRequest params
            headers[headerName.toLowerCase()] = headerValue
          headers['accept'] ?= '*/*'
          data    = @dataForRequest params
          return {method, url, headers, data}

      @public @async sendRequest: FuncG(StructG({
        method: String
        url: String
        options: StructG {
          json: EnumG yes
          headers: Object
          body: MaybeG Object
        }
      }), StructG {
        body: MaybeG AnyT
        headers: DictG String, String
        status: Number
        message: MaybeG String
      }),
        default: ({method, url, options})->
          @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>>>>>>> FOREIGN MAKE OR CREATE', LEVELS[DEBUG]
          t1 = Date.now()
          {version} = @Module.context().manifest.dependencies[@dependencyName]
          foreignApp = @Module.context().dependencies[@dependencyName]
          depModuleName = foreignApp.Module.name
          depModuleVersion = foreignApp.Module.context().manifest.version
          unless semver.satisfies depModuleVersion, version
            throw new Error "
              Dependent module #{depModuleName} not compatible.
              This module required version #{version} but #{depModuleName} version is #{depModuleVersion}.
            "
          @sendNotification SEND_TO_LOG, ">>>>>>>>>>>>>>>>>>>>>>>>> FOREIGN START after #{Date.now() - t1}", LEVELS[DEBUG]
          foreignSwitch = foreignApp.facade.retrieveMediator APPLICATION_SWITCH
          foreignRes = yield foreignSwitch.perform method, url, options
          @sendNotification(SEND_TO_LOG, "ArangoForeignCollectionMixin::sendRequest <result> #{JSON.stringify foreignRes}", LEVELS[DEBUG])
          @sendNotification SEND_TO_LOG, '>>>>>>>>>>>>>>>>>>>>>>>>> FOREIGN END', LEVELS[DEBUG]
          yield return foreignRes

      @public requestToHash: FuncG(StructG({
        method: String
        url: String
        headers: Object
        data: MaybeG Object
      }), StructG {
        method: String
        url: String
        options: StructG {
          json: EnumG yes
          headers: Object
          body: MaybeG Object
        }
      }),
        default: ({method, url, headers, data})->
          options = {
            json: yes
            headers
          }
          options.body = data if data?
          return {
            method
            url
            options
          }

      @public @async makeRequest: FuncG(StructG({
        method: String
        url: String
        headers: Object
        data: MaybeG Object
      }), StructG {
        body: MaybeG AnyT
        headers: DictG String, String
        status: Number
        message: MaybeG String
      }),
        default: (request)-> # result of requestFor
          hash = @requestToHash request
          @sendNotification(SEND_TO_LOG, "ArangoForeignCollectionMixin::makeRequest <hash> #{JSON.stringify hash}", LEVELS[DEBUG])
          return yield @sendRequest hash

      @public @async parseQuery: FuncG(
        [UnionG Object, QueryInterface]
        UnionG Object, String, QueryInterface
      ),
        default: (aoQuery)->
          params = {}
          switch
            when aoQuery.$remove?
              if aoQuery.$forIn?
                params.requestType = 'removeBy'
                params.recordName = @delegate.name
                params.query = aoQuery
                params.isCustomReturn = yes
                yield return params
            when aoQuery.$patch?
              if aoQuery.$forIn?
                params.requestType = 'patchBy'
                params.recordName = @delegate.name
                params.query = aoQuery
                params.isCustomReturn = yes
                yield return params
            else
              params.requestType = 'query'
              params.recordName = @delegate.name
              params.query = aoQuery
              params.isCustomReturn = (
                aoQuery.$collect? or
                aoQuery.$count? or
                aoQuery.$sum? or
                aoQuery.$min? or
                aoQuery.$max? or
                aoQuery.$avg? or
                aoQuery.$remove? or
                aoQuery.$return isnt '@doc'
              )
              yield return params

      @public @async executeQuery: FuncG(
        [UnionG Object, String, QueryInterface]
        CursorInterface
      ),
        default: (aoQuery, options)->
          request = @requestFor aoQuery
          res = yield @makeRequest request

          if res.status >= 400
            throw new Error "
              Request failed with status #{res.status} #{res.message}
            "

          { body } = res

          if body? and body isnt ''
            if _.isString body
              body = JSON.parse body
            unless _.isArray body
              body = [body]

            if aoQuery.isCustomReturn
              yield return Cursor.new null, body
            else
              yield return Cursor.new @, body
          else
            yield return Cursor.new null, []


      @initializeMixin()
