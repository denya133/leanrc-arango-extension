# This file is part of leanrc-arango-extension.
#
# leanrc-arango-extension is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# leanrc-arango-extension is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with leanrc-arango-extension.  If not, see <https://www.gnu.org/licenses/>.

assert        = require 'assert'
createError   = require 'http-errors'
Stream        = require 'stream'


module.exports = (Module)->
  {
    DEVELOPMENT
    AnyT, NilT
    FuncG, UnionG, MaybeG
    RequestInterface, ResponseInterface, SwitchInterface, CookiesInterface
    ContextInterface
    CoreObject
    # ContextInterface
    # RequestInterface
    # ResponseInterface
    # SwitchInterface
    # CookiesInterface
    ArangoRequest
    ArangoResponse
    Cookies
    Utils: { _, statuses }
  } = Module::

  class ArangoContext extends CoreObject
    @inheritProtected()
    @implements ContextInterface
    @module Module

    @public req: Object # native request object
    @public res: Object # native response object
    @public request: MaybeG RequestInterface
    @public response: MaybeG ResponseInterface
    @public cookies: MaybeG CookiesInterface
    @public accept: Object
    @public state: MaybeG Object
    @public switch: SwitchInterface
    @public respond: MaybeG Boolean
    @public routePath: MaybeG String
    @public pathParams: MaybeG Object
    @public transaction: MaybeG Object
    @public session: MaybeG Object
    @public isPerformExecution: Boolean,
      default: no

    # @public database: String # возможно это тоже надо получать из метода из отдельного модуля

    @public throw: FuncG([UnionG(String, Number), MaybeG(String), MaybeG Object]),
      default: (args...)-> throw createError args...

    @public assert: FuncG([AnyT, MaybeG(UnionG String, Number), MaybeG(String), MaybeG Object]),
      default: assert

    @public onerror: FuncG([MaybeG AnyT]),
      default: (err)->
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
        @response.set err.headers ? {}
        @response.type = 'text'
        err.status = 404 if 'ENOENT' is err.code
        err.status = 500 if not _.isNumber(err.status) or not statuses[err.status]
        code = statuses[err.status]
        msg = if err.expose
           err.message
        else
          code
        message =
          error: yes
          errorNum: err.status
          errorMessage: msg
          code: err.code ? code
        if @switch.configs.environment is DEVELOPMENT
          message.exception = "#{err.name ? 'Error'}: #{msg}"
          message.stacktrace = err.stack.split '\n'
        @res.status err.status
        @res.send message
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
    @public socket: MaybeG(Object),
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
    @public 'is': FuncG([UnionG String, Array], UnionG String, Boolean, NilT),
      default: (args...)-> @request.is args...
    @public accepts: FuncG([MaybeG UnionG String, Array], UnionG String, Array, Boolean),
      default: (args...)-> @request.accepts args...
    @public acceptsEncodings: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @request.acceptsEncodings args...
    @public acceptsCharsets: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @request.acceptsCharsets args...
    @public acceptsLanguages: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @request.acceptsLanguages args...
    @public get: FuncG(String, String),
      default: (args...)-> @request.get args...

    # Response aliases
    @public body: MaybeG(UnionG String, Buffer, Object, Array, Number, Boolean, Stream),
      get: -> @response.body
      set: (body)-> @response.body = body
    @public status: MaybeG(Number),
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
    @public type: MaybeG(String),
      get: -> @response.type
      set: (type)-> @response.type = type
    @public headerSent: MaybeG(Boolean),
      get: -> @response.headerSent
    @public redirect: FuncG([String, MaybeG String]),
      default: (args...)-> @response.redirect args...
    @public attachment: FuncG(String),
      default: (args...)-> @response.attachment args...
    @public set: FuncG([UnionG(String, Object), MaybeG AnyT]),
      default: (args...)-> @response.set args...
    @public append: FuncG([String, UnionG String, Array]),
      default: (args...)-> @response.append args...
    @public vary: FuncG(String),
      default: (args...)-> @response.vary args...
    @public flushHeaders: Function,
      default: (args...)-> @response.flushHeaders args...
    @public remove: FuncG(String),
      default: (args...)-> @response.remove args...
    @public lastModified: MaybeG(Date),
      set: (date)-> @response.lastModified = date
    @public etag: String,
      set: (etag)-> @response.etag = etag

    @public @static @async restoreObject: Function,
      default: ->
        throw new Error "restoreObject method not supported for #{@name}"
        yield return

    @public @static @async replicateObject: Function,
      default: ->
        throw new Error "replicateObject method not supported for #{@name}"
        yield return

    @public init: FuncG([Object, Object, SwitchInterface]),
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


    @initialize()
