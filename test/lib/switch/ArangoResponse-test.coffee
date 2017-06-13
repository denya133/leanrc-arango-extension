{ Readable } = require 'stream'
{ expect, assert } = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
accepts = require 'accepts'
mimeTypes = require 'mime-types'
contentDisposition = require 'content-disposition'
status = require 'statuses'
LeanRC = require 'LeanRC'

ArangoExtension = require '../../..'

{ co } = LeanRC::Utils
MIME_BINARY = 'application/octet-stream'


describe 'ArangoResponse', ->
  describe '.new', ->
    it 'should create Response instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        context = {}
        response = Response.new context
        assert.instanceOf response, Response
        yield return
  describe '#ctx', ->
    it 'should get context object', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        context = {}
        response = Response.new context
        assert.equal response.ctx, context
        yield return
  describe '#res', ->
    it 'should get native resource object', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res = {}
        context = { res }
        response = Response.new context
        assert.equal response.res, res
        yield return
  describe '#switch', ->
    it 'should get switch object', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        switchObject = {}
        context = switch: switchObject
        response = Response.new context
        assert.equal response.switch, switchObject
        yield return
  describe '#socket', ->
    it 'should get socket object', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        context = req: {}
        response = Response.new context
        assert.isUndefined response.socket
        yield return
  describe '#headerSent', ->
    it 'should get res.headersSent value', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res = headersSent: no
        context = { res }
        response = Response.new context
        assert.equal response.headerSent, res.headersSent
        yield return
  describe '#headers', ->
    it 'should get response headers', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'Foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
        context = { res }
        response = Response.new context
        assert.deepEqual response.headers, 'Foo': 'Bar'
        yield return
  describe '#header', ->
    it 'should get response headers', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'Foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
        context = { res }
        response = Response.new context
        assert.deepEqual response.header, 'Foo': 'Bar'
        yield return
  describe '#status', ->
    it 'should get and set response status', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          statusCode: 200
          statusMessage: 'OK'
        context = { res }
        response = Response.new context
        assert.equal response.status, 200
        response.status = 400
        assert.equal response.status, 400
        assert.equal res.statusCode, 400
        yield return
  describe '#message', ->
    it 'should get and set response message', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          statusCode: 200
          statusMessage: 'OK'
        context = { res }
        response = Response.new context
        assert.equal response.message, 'OK'
        response.message = 'TEST'
        assert.equal response.message, 'TEST'
        assert.equal res.statusMessage, 'TEST'
        yield return
  describe '#get', ->
    it 'should get specified response header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
        context = { res }
        response = Response.new context
        assert.deepEqual response.get('Foo'), 'Bar'
        yield return
  describe '#set', ->
    it 'should set specified response header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
        context = { res }
        response = Response.new context
        response.set 'Content-Type', 'text/plain'
        assert.equal res.headers['content-type'], 'text/plain'
        assert.equal response.get('Content-Type'), 'text/plain'
        now = new Date
        response.set 'Date', now
        assert.equal response.get('Date'), "#{now}"
        array = [ 1, now, 'TEST']
        response.set 'Test', array
        assert.deepEqual response.get('Test'), [ '1', "#{now}", 'TEST']
        response.set
          'Abc': 123
          'Last-Date': now
          'New-Test': 'Test'
        assert.equal response.get('Abc'), '123'
        assert.equal response.get('Last-Date'), "#{now}"
        assert.equal response.get('New-Test'), 'Test'
        yield return
  describe '#append', ->
    it 'should add specified response header value', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
        context = { res }
        response = Response.new context
        response.append 'Test', 'data'
        assert.equal response.get('Test'), 'data'
        response.append 'Test', 'Test'
        assert.deepEqual response.get('Test'), [ 'data', 'Test' ]
        response.append 'Test', 'Test'
        assert.deepEqual response.get('Test'), [ 'data', 'Test', 'Test' ]
        yield return
  describe '#remove', ->
    it 'should remove specified response header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        response.set 'Test', 'data'
        assert.equal response.get('Test'), 'data'
        response.remove 'Test'
        assert.equal response.get('Test'), ''
        yield return
  describe '#vary', ->
    it 'should set `Vary` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          vary: (value) -> @setHeader 'Vary', value
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
        context = { res }
        response = Response.new context
        response.vary 'Origin'
        assert.equal response.get('Vary'), 'Origin'
        yield return
  describe '#lastModified', ->
    it 'should get and set `Last-Modified` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
        context = { res }
        response = Response.new context
        now = new Date
        response.lastModified = now
        assert.equal res.headers['last-modified'], now.toUTCString()
        assert.deepEqual response.lastModified, new Date now.toUTCString()
        yield return
  describe '#etag', ->
    it 'should get and set `ETag` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: 'foo': 'Bar'
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
        context = { res }
        response = Response.new context
        etag = '123456789'
        response.etag = etag
        assert.equal res.headers['etag'], "\"#{etag}\""
        assert.deepEqual response.etag, "\"#{etag}\""
        etag = 'W/"123456789"'
        response.etag = etag
        assert.equal res.headers['etag'], etag
        assert.deepEqual response.etag, etag
        yield return
  describe '#type', ->
    it 'should get, set and remove `Content-Type` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        assert.equal response.type, ''
        response.type = 'markdown'
        assert.equal response.type, 'text/x-markdown'
        assert.equal res.headers['content-type'], 'text/x-markdown'
        response.type = 'file.json'
        assert.equal response.type, 'application/json'
        assert.equal res.headers['content-type'], 'application/json'
        response.type = 'text/html'
        assert.equal response.type, 'text/html'
        assert.equal res.headers['content-type'], 'text/html'
        response.type = null
        assert.equal response.type, ''
        assert.isUndefined res.headers['content-type']
        yield return
  describe '#attachment', ->
    it 'should setup attachment', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          attachment: (filename) ->
            @setHeader 'Content-Disposition', contentDisposition filename
            if filename and not @getHeader 'Content-Type'
              @setHeader 'Content-Type', (mimeTypes.lookup filename) or MIME_BINARY
            @
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        response.attachment "#{__dirname}/#{__filename}"
        assert.equal response.type, 'application/javascript'
        assert.equal response.get('Content-Disposition'), 'attachment; filename="ArangoResponse-test.js"'
        response.attachment 'attachment.js'
        assert.equal response.type, 'application/javascript'
        assert.equal response.get('Content-Disposition'), 'attachment; filename="attachment.js"'
        yield return
  describe '#writable', ->
    it 'should check if response is writable', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res = writable: yes
        context = { res }
        context = { res }
        response = Response.new context
        assert.isTrue response.writable
        yield return
  describe '#is', ->
    it 'should check `Content-Type` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: {}
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        response.type = 'data.json'
        assert.equal response.is('html' , 'application/*'), 'application/json'
        assert.isFalse response.is 'html'
        yield return
  describe '#body', ->
    it 'should get and set response body', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: {}
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        assert.isUndefined response.body
        response.body = 'TEST'
        assert.equal response.status, 200
        assert.equal response.message, 'OK'
        assert.equal response.get('Content-Type'), 'text/plain'
        assert.equal response.length, 4
        response.body = null
        assert.equal response.status, 204
        assert.equal response.message, 'No Content'
        assert.equal response.get('Content-Type'), ''
        assert.isUndefined response.length
        response._explicitStatus = no
        response.body = new Buffer '7468697320697320612074c3a97374', 'hex'
        assert.equal response.status, 200
        assert.equal response.message, 'OK'
        assert.equal response.get('Content-Type'), 'application/octet-stream'
        assert.equal response.length, 15
        response.body = null
        response._explicitStatus = no
        response.body = '<html></html>'
        assert.equal response.status, 200
        assert.equal response.message, 'OK'
        assert.equal response.get('Content-Type'), 'text/html'
        assert.equal response.length, 13
        response.body = null
        response._explicitStatus = no
        response.body = { test: 'TEST' }
        assert.equal response.status, 200
        assert.equal response.message, 'OK'
        assert.equal response.get('Content-Type'), 'application/json'
        assert.equal response.length, 15
        yield return
  describe '#length', ->
    it 'should get response data length', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: {}
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        assert.isUndefined response.length
        response.length = 10
        assert.equal response.length, 10
        response.remove 'Content-Length'
        response.body = '<html></html>'
        assert.equal response.length, 13
        response.remove 'Content-Length'
        response.body = new Buffer '7468697320697320612074c3a97374', 'hex'
        assert.equal response.length, 15
        response.remove 'Content-Length'
        response.body = test: 'TEST123'
        assert.equal response.length, 18
        yield return
  describe '#redirect', ->
    it 'should send redirect', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        req =
          headers:
            'accept': 'application/json, text/plain, image/png'
        res =
          headers: {}
          type: (value) ->
            if arguments.length is 0
              @getHeader 'Content-Type'
            else
              type = (mimeTypes.lookup value) or value
              if type?
                @setHeader 'Content-Type', type
              else
                @removeHeader 'Content-Type'
          redirect: (args...) ->
            switch args.length
              when 1
                [ url ] = args
              when 2
                [ code, url ] = args
              else
                throw new Error 'There is needed exactly one or two arguments'
            if code? and not @statusCode?
              @statusCode = code
              @statusMessage = status.codes[code]
            @setHeader 'Location', url
            @
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()] ? ''
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = {
          switch: configs: trustProxy: yes
          res, req,
          get: (args...) -> request.get args...
          accepts: (args...) -> request.accepts args...
          accept: accepts req
        }
        request = Test::Request.new context
        response = Response.new context
        response.redirect 'back', 'http://localhost:8888/test1'
        assert.equal response.get('Location'), 'http://localhost:8888/test1'
        assert.equal response.status, 302
        assert.equal response.message, 'Found'
        req.headers.referrer = 'http://localhost:8888/test3'
        response.redirect 'back'
        assert.equal response.get('Location'), 'http://localhost:8888/test3'
        assert.equal response.status, 302
        assert.equal response.message, 'Found'
        response.redirect 'http://localhost:8888/test2'
        assert.equal response.get('Location'), 'http://localhost:8888/test2'
        assert.equal response.status, 302
        assert.equal response.message, 'Found'
        yield return
  describe '#flushHeaders', ->
    it 'should clear all headers', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class Response extends Test::ArangoResponse
          @inheritProtected()
          @module Test
        Response.initialize()
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = { res }
        response = Response.new context
        now = new Date
        array = [ 1, now, 'TEST']
        response.set
          'Content-Type': 'text/plain'
          'Date': now
          'Abc': 123
          'Last-Date': now
          'New-Test': 'Test'
          'Test': array
        assert.equal response.get('Content-Type'), 'text/plain'
        assert.equal response.get('Date'), "#{now}"
        assert.equal response.get('Abc'), '123'
        assert.equal response.get('Last-Date'), "#{now}"
        assert.equal response.get('New-Test'), 'Test'
        assert.deepEqual response.get('Test'), [ '1', "#{now}", 'TEST']
        response.flushHeaders()
        assert.equal response.get('Content-Type'), ''
        assert.equal response.get('Date'), ''
        assert.equal response.get('Abc'), ''
        assert.equal response.get('Last-Date'), ''
        assert.equal response.get('New-Test'), ''
        assert.equal response.get('Test'), ''
        yield return
