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

net         = require 'net' # will be used only 'isIP' function
contentType = require 'content-type'
stringify   = require('url').format
parse       = require 'parseurl'
qs          = require 'querystring'
fresh       = require 'fresh'

###
Идеи взяты из https://github.com/koajs/koa/blob/master/lib/request.js
###

module.exports = (Module)->
  {
    AnyT, NilT
    FuncG, UnionG, MaybeG
    RequestInterface, SwitchInterface, ContextInterface
    CoreObject
    # RequestInterface
    # SwitchInterface
    # ContextInterface
    Utils: { _ }
  } = Module::

  class ArangoRequest extends CoreObject
    @inheritProtected()
    @implements RequestInterface
    @module Module

    @public req: Object, # native request object
      get: -> @ctx.req

    @public switch: SwitchInterface,
      get: -> @ctx.switch

    @public ctx: ContextInterface

    @public body: MaybeG AnyT # тело должен предоставлять миксин из отдельного модуля

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
      set: (obj)->
        @querystring = qs.stringify obj
        obj

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

    @public socket: MaybeG(Object),
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
          return 0 if contentLength is ''
          ~~Number contentLength
        else
          0

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

    @public accepts: FuncG([MaybeG UnionG String, Array], UnionG String, Array, Boolean),
      default: (args...)-> @ctx.accept.types args...
    @public acceptsEncodings: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @ctx.accept.encodings args...
    @public acceptsCharsets: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @ctx.accept.charsets args...
    @public acceptsLanguages: FuncG([MaybeG UnionG String, Array], UnionG String, Array),
      default: (args...)-> @ctx.accept.languages args...

    @public 'is': FuncG([UnionG String, Array], UnionG String, Boolean, NilT),
      default: (args...)->
        @req.is args...

    @public type: String,
      get: ->
        type = @get 'Content-Type'
        return '' unless type?
        type.split(';')[0]

    @public get: FuncG(String, String),
      default: (field)->
        switch field = field.toLowerCase()
          when 'referer', 'referrer'
            @req.headers.referrer ? @req.headers.referer ? ''
          else
            @req.headers[field] ? ''

    @public @static @async restoreObject: Function,
      default: ->
        throw new Error "restoreObject method not supported for #{@name}"
        yield return

    @public @static @async replicateObject: Function,
      default: ->
        throw new Error "replicateObject method not supported for #{@name}"
        yield return

    @public init: FuncG(ContextInterface),
      default: (context)->
        @super()
        @ctx = context
        @ip = @ips[0] ? @req.remoteAddress ? ''
        return


    @initialize()
