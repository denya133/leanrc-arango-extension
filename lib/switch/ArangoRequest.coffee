_           = require 'lodash'
net         = require 'net' # will be used only 'isIP' function
contentType = require 'content-type'
stringify   = require('url').format
parse       = require 'parseurl'
qs          = require 'querystring'
# typeis      = require 'type-is'
fresh       = require 'fresh'

###
Идеи взяты из https://github.com/koajs/koa/blob/master/lib/request.js
###

module.exports = (Module)->
  {
    ANY

    CoreObject
    # RequestInterface
    SwitchInterface
    ContextInterface
  } = Module::

  class ArangoRequest extends CoreObject
    @inheritProtected()
    # @implements RequestInterface
    @module Module

    @public req: Object, # native request object
      get: -> @ctx.req

    @public switch: SwitchInterface,
      get: -> @ctx.switch

    @public ctx: ContextInterface

    @public body: ANY # тело должен предоставлять миксин из отдельного модуля

    @public header: Object,
      get: -> @headers
    @public headers: Object,
      get: -> @req.headers

    @public originalUrl: String,
      get: -> @ctx.originalUrl

    @public url: String,
      get: -> @req.url
      set: (url)-> @req.url = url

    @public origin: String,
      get: -> "#{@protocol}://#{@host}"

    @public href: String,
      get: ->
        return @originalUrl if /^https?:\/\//i.test @originalUrl
        return @origin + @originalUrl

    @public method: String,
      get: -> @req.method
      set: (method)-> @req.method = method

    @public path: String,
      get: -> parse(@req).pathname
      set: (path)->
        url = parse @req
        return if url.pathname is path
        url.pathname = path
        url.path = null
        @url = stringify url

    @public query: Object,
      get: -> qs.parse @querystring
      set: (obj)-> @querystring = qs.stringify obj

    @public querystring: String,
      get: ->
        return '' unless @req?
        parse(@req).query ? ''
      set: (str)->
        url = parse @req
        return if url.search is "?#{str}"
        url.search = str
        url.path = null
        @url = stringify url

    @public search: String,
      get: ->
        return '' unless @querystring
        "?#{@querystring}"
      set: (str)-> @querystring = str

    @public host: String,
      get: ->
        {trustProxy} = @ctx.switch.configs
        host = trustProxy and @get 'X-Forwarded-Host'
        host = host or @get 'Host'
        return '' unless host
        host.split(/\s*,\s*/)[0]

    @public hostname: String,
      get: ->
        host = @host
        return '' unless host
        host.split(':')[0]

    @public fresh: Boolean,
      get: ->
        method = @method
        s = @ctx.status
        # GET or HEAD for weak freshness validation only
        if 'GET' isnt method and 'HEAD' isnt method
          return no
        # 2xx or 304 as per rfc2616 14.26
        if (s >= 200 and s < 300) or 304 is s
          return fresh @headers, @ctx.response.headers
        return no

    @public stale: Boolean,
      get: -> not @fresh

    @public idempotent: Boolean,
      get: ->
        methods = ['GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS', 'TRACE']
        _.includes methods, @method

    @public socket: Object,
      get: ->

    @public charset: String,
      get: ->
        type = @get 'Content-Type'
        return '' unless type?
        try
          type = contentType.parse type
        catch err
          return ''
        type.parameters.charset ? ''

    @public length: Number,
      get: ->
        if (contentLength = @get 'Content-Length')?
          return if contentLength is ''
          ~~Number contentLength

    @public protocol: String,
      get: -> @req.protocol

    @public secure: Boolean,
      get: -> @req.secure

    @public ip: String

    @public ips: Array,
      get: ->
        {trustProxy} = @ctx.switch.configs
        value = @get 'X-Forwarded-For'
        if trustProxy and value
          value.split /\s*,\s*/
        else
          []

    @public subdomains: Array,
      get: ->
        {subdomainOffset:offset} = @ctx.switch.configs
        hostname = @hostname
        return []  if net.isIP(hostname) isnt 0
        hostname
          .split('.')
          .reverse()
          .slice offset ? 0

    @public accepts: Function,
      default: (args...)-> @ctx.accept.types args...
    @public acceptsCharsets: Function,
      default: (args...)-> @ctx.accept.charsets args...
    @public acceptsEncodings: Function,
      default: (args...)-> @ctx.accept.encodings args...
    @public acceptsLanguages: Function,
      default: (args...)-> @ctx.accept.languages args...

    @public 'is': Function,
      default: (args...)->
        @req.is args...

    @public type: String,
      get: ->
        type = @get 'Content-Type'
        return '' unless type?
        type.split(';')[0]

    @public get: Function,
      default: (field)->
        switch field = field.toLowerCase()
          when 'referer', 'referrer'
            @req.headers.referrer ? @req.headers.referer ? ''
          else
            @req.headers[field] ? ''

    @public init: Function,
      default: (context)->
        @super()
        @ctx = context
        @ip = @ips[0] ? @req.remoteAddress ? ''
        return


  ArangoRequest.initialize()
