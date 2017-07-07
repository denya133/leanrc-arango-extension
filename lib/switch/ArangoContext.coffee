_             = require 'lodash'
assert        = require 'assert'
statuses      = require 'statuses'
createError   = require 'http-errors'


module.exports = (Module)->
  {
    ANY

    CoreObject
    ContextInterface
    RequestInterface
    ResponseInterface
    SwitchInterface
    CookiesInterface
    ArangoRequest
    ArangoResponse
    Cookies
  } = Module::

  class ArangoContext extends CoreObject
    @inheritProtected()
    @implements ContextInterface
    @module Module

    @public req: Object # native request object
    @public res: Object # native response object
    @public request: RequestInterface
    @public response: ResponseInterface
    @public cookies: CookiesInterface
    @public accept: Object
    @public state: Object
    @public switch: SwitchInterface
    @public respond: Boolean
    @public routePath: String
    @public pathParams: Object

    # @public database: String # возможно это тоже надо получать из метода из отдельного модуля

    @public throw: Function,
      default: (args...)-> throw createError args...

    @public assert: Function,
      default: assert

    @public onerror: Function,
      default: (err)->
        console.log '>>>>> IN ArangoContext::onerror ownKeys', Reflect.ownKeys err
        console.log '>>>>> IN ArangoContext::onerror', err.message, err.name, err.stack
        return unless err?
        unless _.isError err
          err = new Error "non-error thrown: #{err}"
        headerSent = no
        if @headerSent or not @writable
          headerSent = err.headerSent = yes
        @switch.getViewComponent().emit 'error', err, @
        return if headerSent
        if _.isFunction @res.getHeaderNames
          @res.getHeaderNames().forEach (name)=> @res.removeHeader name
        if (vlHeaderNames = Object.keys @res.headers ? {}).length > 0
          vlHeaderNames.forEach (name)=> @res.removeHeader name
        @response.set err.headers
        @response.type = 'text'
        err.status = 404 if 'ENOENT' is err.code
        err.status = 500 if not _.isNumber(err.status) or not statuses[err.status]
        code = statuses[err.status]
        msg = if err.expose
           err.message
        else
          code
        @res.status err.status
        @res.send msg
        return

    # Request aliases
    @public header: Object,
      get: -> @request.header
    @public headers: Object,
      get: -> @request.headers
    @public method: String,
      get: -> @request.method
      set: (method)-> @request.method = method
    @public url: String,
      get: -> @request.url
      set: (url)-> @request.url = url
    @public originalUrl: String
    @public origin: String,
      get: -> @request.origin
    @public href: String,
      get: -> @request.href
    @public path: String,
      get: -> @request.path
      set: (path)-> @request.path = path
    @public query: Object,
      get: -> @request.query
      set: (query)-> @request.query = query
    @public querystring: String,
      get: -> @request.querystring
      set: (querystring)-> @request.querystring = querystring
    @public host: String,
      get: -> @request.host
    @public hostname: String,
      get: -> @request.hostname
    @public fresh: Boolean,
      get: -> @request.fresh
    @public stale: Boolean,
      get: -> @request.stale
    @public socket: Object,
      get: -> @request.socket
    @public protocol: String,
      get: -> @request.protocol
    @public secure: Boolean,
      get: -> @request.secure
    @public ip: String,
      get: -> @request.ip
    @public ips: Array,
      get: -> @request.ips
    @public subdomains: Array,
      get: -> @request.subdomains
    @public is: Function,
      default: (args...)-> @request.is args...
    @public accepts: Function,
      default: (args...)-> @request.accepts args...
    @public acceptsEncodings: Function,
      default: (args...)-> @request.acceptsEncodings args...
    @public acceptsCharsets: Function,
      default: (args...)-> @request.acceptsCharsets args...
    @public acceptsLanguages: Function,
      default: (args...)-> @request.acceptsLanguages args...
    @public get: Function,
      default: (args...)-> @request.get args...

    # Response aliases
    @public body: [String, Buffer, Object, Array, Number, Boolean],
      get: -> @response.body
      set: (body)-> @response.body = body
    @public status: [String, Number],
      get: -> @response.status
      set: (status)-> @response.status = status
    @public message: String,
      get: -> @response.message
      set: (message)-> @response.message = message
    @public length: Number,
      get: -> @response.length
      set: (length)-> @response.length = length
    @public writable: Boolean,
      get: -> @response.writable
    @public type: String,
      get: -> @response.type
      set: (type)-> @response.type = type
    @public headerSent: Boolean,
      get: -> @response.headerSent
    @public redirect: Function,
      default: (args...)-> @response.redirect args...
    @public attachment: Function,
      default: (args...)-> @response.attachment args...
    @public set: Function,
      default: (args...)-> @response.set args...
    @public append: Function,
      default: (args...)-> @response.append args...
    @public vary: Function,
      default: (args...)-> @response.vary args...
    @public flushHeaders: Function,
      default: (args...)-> @response.flushHeaders args...
    @public remove: Function,
      default: (args...)-> @response.remove args...
    @public lastModified: Date,
      set: (date)-> @response.lastModified = date
    @public etag: String,
      set: (etag)-> @response.etag = etag

    @public init: Function,
      default: (req, res, switchInstanse)->
        @super()
        @req = req
        @res = res
        @switch = switchInstanse
        @originalUrl = req.url
        @accept =
          types: (args...)->
            req.accepts args...
          charsets: (args...)->
            req.acceptsCharsets args...
          encodings: (args...)->
            req.acceptsEncodings args...
          languages: (args...)->
            req.acceptsLanguages args...
        @request = ArangoRequest.new(@)
        @response = ArangoResponse.new(@)
        key = @switch.configs.cookieKey
        secure = req.secure
        @cookies = Cookies.new req, res, {key, secure}
        @state = {}
        return


  ArangoContext.initialize()
