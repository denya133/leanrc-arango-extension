# Класс намеренно подгоняется под интерфейс класса `SyntheticRequest` который используется в недрах аранги.
# однако этот класс будет использоваться при формировании запросов между сервисами вместо http (в ArangoForeignCollectionMixin)


accepts       = require 'accepts'
typeIs        = require 'type-is'
parseRange    = require 'range-parser'
cookie        = require 'cookie'
querystring   = require 'querystring'
parseUrl      = require('url').parse
formatUrl     = require('url').format
crypto        = require '@arangodb/crypto'


module.exports = (Module)->
  {
    AnyT, NilT, PointerT
    FuncG, MaybeG, UnionG
    ContextInterface
    CoreObject
    Utils: { _ }
  } = Module::

  class SyntheticRequest extends CoreObject
    @inheritProtected()
    @module Module

    ipoUrlCache = PointerT @private urlCache: MaybeG Object
    ipoParsedUrl = PointerT @protected parsedUrl: Object,
      get: ->
        @[ipoUrlCache] ?= parseUrl @initialUrl
        return @[ipoUrlCache]
    @public initialUrl: String
    # @public arangoUser: String # not supported
    # @public arangoVersion: Number # not supported
    @public baseUrl: String,
      get: -> @context.baseUrl.replace @context.mount, ''
    @public body: MaybeG AnyT
    @public context: Object
    @public database: String,
      get: -> @baseUrl.replace '/_db/', ''
    @public headers: Object
    @public hostname: String, # copy from main request
      default: '127.0.0.1'
    @public method: String
    @public originalUrl: String,
      get: -> "#{@baseUrl}/#{@path}#{@[ipoParsedUrl].search ? ''}"
    @public path: String,
      get: -> @[ipoParsedUrl].pathname
    @public pathParams: Object
    @public port: Number # copy from main request
      default: 80
    @public protocol: String,
      default: 'http'
    @public queryParams: Object,
      get: -> querystring.decode @[ipoParsedUrl].query
    @public rawBody: Buffer
    @public remoteAddress: String # copy from main request
    @public remoteAddresses: Array # copy from main request
    @public remotePort: Number # copy from main request
    @public secure: Boolean,
      get: -> @protocol is 'https'
    # @public suffix: String # not supported
    @public trustProxy: Boolean, # copy from main request
      default: no
    # @public url: String,
    #   get: -> "#{@path}#{@[ipoParsedUrl].search ? ''}"
    @public url: String
    @public xhr: Boolean,
      get: ->
        "xmlhttprequest" is @headers['x-requested-with']?.toLowerCase()


    @public accepts: FuncG([MaybeG UnionG String, Array], UnionG String, Array, Boolean),
      default: (args...)->
        accept = accepts @
        accept.types args...
    @public acceptsEncodings: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)->
        accept = accepts @
        accept.encodings args...
    @public acceptsCharsets: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)->
        accept = accepts @
        accept.charsets args...
    @public acceptsLanguages: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)->
        accept = accepts @
        accept.languages args...

    @public cookie: Function,
      default: (name, opts)->
        if _.isString opts
          opts = secret: opts
        else unless opts
          opts = {}
        cookies = cookie.parse @headers.cookie
        value = cookies[name]
        if value and opts.secret
          sign = cookies["#{name}.sig"] ? ''
          ciph = crypto.hmac opts.secret, value, opts.algorithm
          valid = crypto.constantEquals sign, ciph
          unless valid
            return undefined
        return value

    @public get: FuncG(String, String),
      default: (name)->
        lc = name.toLowerCase()
        if lc is 'referer' or lc is 'referrer'
          return @headers.referer ? @headers.referrer
        return @headers[lc]

    @public header: Function,
      default: (name)-> @get name

    @public 'is': FuncG([UnionG String, Array], UnionG String, Boolean, NilT),
      default: (args...)->
        unless @headers['content-type']
          return no
        types = if args.length is 1
          args[0]
        else
          args
        typeIs.is @, types

    @public json: FuncG([], Object),
      default: ->
        if not @rawBody or not @rawBody.length
          undefined
        JSON.parse @rawBody.toString 'utf8'

    @public makeAbsolute: Function,
      default: (path, query)->
        opts =
          protocol: @protocol
          hostname: @hostname
          port: (if @secure then @port != 443 else @port != 80) and @port
          pathname: "#{@baseUrl}#{@context.mount}/#{path}"
        if query
          if _.isString query
            opts.search = query
          else
            opts.query = query
        return formatUrl opts

    @public param: FuncG(String, String),
      default: (name)->
        {hasOwnProperty} = {}
        if hasOwnProperty.call @pathParams, name
          return @pathParams[name]
        return @queryParams[name]

    @public range: Function,
      default: (size)->
        range = @headers.rang
        unless range
          return undefined
        size = if size or size is 0 then size else Infinity
        return parseRange size, @headers.range
    # @public reverse: Function, # not supported
    #   default: (name, params)->


    @public init: FuncG(ContextInterface, NilT),
      default: (context)->
        @super()
        @context = context
        @pathParams = {}
        return


    @initialize()
