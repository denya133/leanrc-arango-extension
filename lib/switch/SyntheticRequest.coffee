# Класс намеренно подгоняется под интерфейс класса `SyntheticRequest` который используется в недрах аранги.
# однако этот класс будет использоваться при формировании запросов между сервисами вместо http (в ArangoForeignCollectionMixin)


_             = require 'lodash'
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
    ANY
    CoreObject
  } = Module::

  class SyntheticRequest extends CoreObject
    @inheritProtected()
    @module Module

    ipoUrlCache = @private urlCache: Object
    ipoParsedUrl = @protected parsedUrl: Object,
      get: ->
        @[ipoUrlCache] ?= parseUrl @initialUrl
        return @[ipoUrlCache]
    @public initialUrl: String
    # @public arangoUser: String # not supported
    # @public arangoVersion: Number # not supported
    @public baseUrl: String,
      get: -> @context.baseUrl.replace @context.mount, ''
    @public body: ANY
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


    @public accepts: Function,
      default: (args...)-> @accept.types args...
    @public acceptsEncodings: Function,
      default: (args...)-> @accept.encodings args...
    @public acceptsCharsets: Function,
      default: (args...)-> @accept.charsets args...
    @public acceptsLanguages: Function,
      default: (args...)-> @accept.languages args...

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
    @public get: Function,
      default: (name)->
        lc = name.toLowerCase()
        if lc is 'referer' or lc is 'referrer'
          return @headers.referer ? @headers.referrer
        return @headers[lc]
    @public header: Function,
      default: (name)-> @get name
    @public is: Function,
      default: (args...)->
        unless @headers['content-type']
          return no
        types = if args.length is 1
          args[0]
        else
          args
        typeIs.is @, types
    @public json: Function,
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
    @public param: Function,
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


    @public init: Function,
      default: (context)->
        @super()
        @context = context
        @accept = accepts @
        @pathParams = {}
        return


  SyntheticRequest.initialize()
