_                   = require 'lodash'
typeis              = require('type-is').is
statuses            = require 'statuses'
assert              = require 'assert'


module.exports = (Module)->
  {
    NILL

    CoreObject
    ResponseInterface
    SwitchInterface
    ContextInterface
  } = Module::

  class ArangoResponse extends CoreObject
    @inheritProtected()
    @implements ResponseInterface
    @module Module

    @public res: Object, # native response object
      get: -> @ctx.res

    @public switch: SwitchInterface,
      get: -> @ctx.switch

    @public ctx: ContextInterface

    @public socket: Object,
      get: ->

    @public header: Object,
      get: -> @headers
    @public headers: Object,
      get: -> @res.headers

    @public status: Number,
      get: -> @res.statusCode
      set: (code)->
        assert _.isNumber(code), 'status code must be a number'
        assert statuses[code], "invalid status code: #{code}"
        @_explicitStatus = yes
        @res.statusCode = code
        @res.statusMessage = statuses[code]
        if Boolean(@body and statuses.empty[code])
          @body = null
        return

    @public message: String,
      get: -> @res.statusMessage ? statuses[@status]
      set: (msg)->
        @res.statusMessage = msg
        return

    @public body: [String, Buffer, Object, Array, Date, Boolean],
      get: -> @_body
      set: (val)->
        original = @_body
        @_body = val
        unless val?
          unless statuses.empty[@status]
            @status = 204
          @remove 'Content-Type'
          @remove 'Content-Length'
          @remove 'Transfer-Encoding'
          return
        unless @_explicitStatus
          @status = 200
        setType = not @headers['content-type']
        if _.isString val
          if setType
            @res.type if /^\s*</.test val then 'html' else 'text'
          return
        if _.isBuffer val
          if setType
            @res.type 'bin'
          return
        @remove 'Content-Length'
        @res.type 'json'
        return

    @public length: Boolean,
      get: ->
        len = @headers['content-length']
        unless len?
          return unless @body
          if _.isString @body
            return Buffer.byteLength @body
          if _.isBuffer @body
            return @body.length
          if _.isObjectLike @body
            return Buffer.byteLength JSON.stringify @body
          return
        ~~Number len
      set: (n)-> @set 'Content-Length', n

    @public headerSent: Boolean,
      get: -> no

    @public vary: Function,
      default: (args...)->
        @res.vary args...
        return

    @public redirect: Function,
      default: (url, alt)->
        if 'back' is url
          url = @ctx.get('Referrer') or alt or '/'
        if statuses.redirect[@status]
          @res.redirect url
        else
          @res.redirect 302, url
        return

    @public attachment: Function,
      default: (filename)->
        @res.attachment filename
        return

    @public lastModified: Date,
      get: ->
        date = @get 'last-modified'
        if date
          new Date date
      set: (val)->
        if _.isString val
          val = new Date val
        @set 'Last-Modified', val.toUTCString()

    @public etag: String,
      get: -> @get 'ETag'
      set: (val)->
        val = "\"#{val}\"" unless /^(W\/)?"/.test val
        @set 'ETag', val

    @public type: String,
      get: ->
        @res.type()
      set: (type)->
        @res.type type

    @public is: Function,
      default: (args...)->
        [types] = args
        return @type or no unless types
        unless _.isArray types
          types = args
        typeis @type, types

    @public get: Function,
      default: (field)->
        @headers[field.toLowerCase()] ? ''

    @public set: Function,
      default: (args...)->
        [field, val] = args
        if 2 is args.length
          if _.isArray val
            val = val.map String
          else
            val = String val
          @res.setHeader field, val
        else
          for own key, value of field
            @set key, value
        return

    @public append: Function,
      default: (field, val)->
        prev = @get field
        if prev
          if _.isArray prev
            val = prev.concat val
          else
            val = [prev].concat val
        @set field, val

    @public remove: Function,
      default: (field)->
        @res.removeHeader field
        return

    @public flushHeaders: Function,
      default: (field)->
        Object.keys(@res.headers).forEach (name)=>
          @res.removeHeader name
        return

    @public writable: Boolean,
      get: -> yes

    @public init: Function,
      default: (context)->
        @super()
        @ctx = context
        return


  ArangoResponse.initialize()
