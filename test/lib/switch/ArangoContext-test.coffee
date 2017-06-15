{ Readable } = require 'stream'
EventEmitter = require 'events'
{ expect, assert } = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
# accepts = require 'accepts'
mimeTypes = require 'mime-types'
contentDisposition = require 'content-disposition'
status = require 'statuses'
httpErrors = require 'http-errors'

LeanRC = require 'LeanRC'

ArangoExtension = require '../../..'

{ co } = LeanRC::Utils


describe 'ArangoContext', ->
  describe '.new', ->
    it 'should create ArangoContext instance', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = Test::ArangoContext.new req, res, switchInstance
        assert.instanceOf context, Test::ArangoContext
        assert.equal context.req, req
        assert.equal context.res, res
        assert.equal context.switch, switchInstance
        assert.instanceOf context.request, Test::ArangoRequest
        assert.instanceOf context.response, Test::ArangoResponse
        assert.instanceOf context.cookies, Test::Cookies
        assert.deepEqual context.state, {}
        yield return
  describe '#throw', ->
    it 'should throw an error exception', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.throws -> context.throw 404
        , httpErrors.HttpError
        assert.throws -> context.throw 501, 'Not Implemented'
        , httpErrors.HttpError
        yield return
  describe '#assert', ->
    it 'should assert with status codes', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.doesNotThrow -> context.assert yes
        assert.throws -> context.assert 'test' is 'TEST', 500, 'Internal Error'
        , Error
        yield return
  describe '#header', ->
    it 'should get request header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.header, req.headers
        yield return
  describe '#headers', ->
    it 'should get request headers', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.headers, req.headers
        yield return
  describe '#method', ->
    it 'should get and set request method', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.method, 'POST'
        context.method = 'PUT'
        assert.equal context.method, 'PUT'
        assert.equal req.method, 'PUT'
        yield return
  describe '#url', ->
    it 'should get and set request URL', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.url, 'http://localhost:8888/test1'
        context.url = 'http://localhost:8888/test2'
        assert.equal context.url, 'http://localhost:8888/test2'
        assert.equal req.url, 'http://localhost:8888/test2'
        yield return
  describe '#originalUrl', ->
    it 'should get original request URL', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.originalUrl, 'http://localhost:8888/test1'
        yield return
  describe '#origin', ->
    it 'should get request origin data', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          protocol: 'http'
          method: 'POST'
          url: 'http://localhost:8888/test1'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'host': 'localhost:8888'
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.origin, 'http://localhost:8888'
        req.protocol = 'https'
        assert.equal context.origin, 'https://localhost:8888'
        yield return
  describe '#href', ->
    it 'should get request hyper reference', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          protocol: 'http'
          method: 'POST'
          url: '/test1'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'host': 'localhost:8888'
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.href, 'http://localhost:8888/test1'
        req.url = 'http://localhost1:9999/test2'
        context = TestContext.new req, res, switchInstance
        assert.equal context.href, 'http://localhost1:9999/test2'
        yield return
  describe '#path', ->
    it 'should get and set request path', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1?t=ttt'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.path, '/test1'
        context.path = '/test2'
        assert.equal context.path, '/test2'
        assert.equal req.url, 'http://localhost:8888/test2?t=ttt'
        yield return
  describe '#query', ->
    it 'should get and set request query object', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1?t=ttt'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.query, t: 'ttt'
        context.query = a: 'aaa'
        assert.deepEqual context.query, a: 'aaa'
        assert.equal req.url, 'http://localhost:8888/test1?a=aaa'
        yield return
  describe '#querystring', ->
    it 'should get and set request query string', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'POST'
          url: 'http://localhost:8888/test1?t=ttt'
          headers: 'x-forwarded-for': '192.168.0.1'
          secure: no
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.querystring, 't=ttt'
        context.querystring = 'a=aaa'
        assert.equal context.querystring, 'a=aaa'
        assert.equal req.url, 'http://localhost:8888/test1?a=aaa'
        yield return
  describe '#host', ->
    it 'should get request host', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          headers:
            'x-forwarded-for': '192.168.0.1'
            'host': 'localhost:9999'
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.host, 'localhost:9999'
        req =
          headers:
            'x-forwarded-for': '192.168.0.1'
            'x-forwarded-host': 'localhost:8888, localhost:9999'
        context = TestContext.new req, res, switchInstance
        assert.equal context.host, 'localhost:8888'
        req =
          headers: 'x-forwarded-for': '192.168.0.1'
        context = TestContext.new req, res, switchInstance
        assert.equal context.host, ''
        yield return
  describe '#hostname', ->
    it 'should get request host name', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          headers:
            'x-forwarded-for': '192.168.0.1'
            'host': 'localhost:9999'
        res =
          headers: 'Foo': 'Bar'
        context = TestContext.new req, res, switchInstance
        assert.equal context.hostname, 'localhost'
        req =
          headers:
            'x-forwarded-for': '192.168.0.1'
            'x-forwarded-host': 'localhost1:8888, localhost:9999'
        context = TestContext.new req, res, switchInstance
        assert.equal context.hostname, 'localhost1'
        req =
          headers: 'x-forwarded-for': '192.168.0.1'
        context = TestContext.new req, res, switchInstance
        assert.equal context.hostname, ''
        yield return
  describe '#fresh', ->
    it 'should test request freshness', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'GET'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'if-none-match': '"foo"'
        res =
          headers: 'etag': '"bar"'
        context = TestContext.new req, res, switchInstance
        context.status = 200
        assert.isFalse context.fresh
        req =
          method: 'GET'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'if-none-match': '"foo"'
        res =
          headers: 'etag': '"foo"'
        context = TestContext.new req, res, switchInstance
        context.status = 200
        assert.isTrue context.fresh
        yield return
  describe '#stale', ->
    it 'should test request non-freshness', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          method: 'GET'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'if-none-match': '"foo"'
        res =
          headers: 'etag': '"bar"'
        context = TestContext.new req, res, switchInstance
        context.status = 200
        assert.isTrue context.stale
        req =
          method: 'GET'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'if-none-match': '"foo"'
        res =
          headers: 'etag': '"foo"'
        context = TestContext.new req, res, switchInstance
        context.status = 200
        assert.isFalse context.stale
        yield return
  describe '#socket', ->
    it 'should get request socket', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          headers:
            'x-forwarded-for': '192.168.0.1'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.equal context.socket, req.socket
        yield return
  describe '#protocol', ->
    it 'should get request protocol', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: no
            cookieKey: 'COOKIE_KEY'
        req =
          protocol: 'http'
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.equal context.protocol, 'http'
        req.protocol = 'https'
        context = TestContext.new req, res, switchInstance
        assert.equal context.protocol, 'https'
        yield return
  describe '#secure', ->
    it 'should check if request secure', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: no
            cookieKey: 'COOKIE_KEY'
        req =
          secure: no
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.isFalse context.secure
        req.secure = yes
        context = TestContext.new req, res, switchInstance
        assert.isTrue context.secure
        yield return
  describe '#ips', ->
    it 'should get request IPs', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1, 192.168.1.1, 123.222.12.21'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.ips, [ '192.168.0.1', '192.168.1.1', '123.222.12.21' ]
        yield return
  describe '#ip', ->
    it 'should get request IP', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1, 192.168.1.1, 123.222.12.21'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.ip, '192.168.0.1'
        yield return
  describe '#subdomains', ->
    it 'should get request subdomains', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
            subdomainOffset: 1
        req =
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'host': 'www.test.localhost:9999'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.subdomains, [ 'test', 'www' ]
        req.headers.host = '192.168.0.2:9999'
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.subdomains, []
        yield return
  describe '#is', ->
    it 'should test types from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          is: -> 'application/json'
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'content-type': 'application/json'
            'content-length': '0'
        res =
          headers: 'etag': '"bar"'
        context = TestContext.new req, res, switchInstance
        assert.equal context.is('html' , 'application/*'), 'application/json'
        yield return
  describe '#accepts', ->
    it 'should get acceptable types from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          accepts: -> @headers['accept'].split /\s*\,\s*/
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'accept': 'application/json, text/plain, image/png'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.accepts(), [
          'application/json', 'text/plain', 'image/png'
        ]
        yield return
  describe '#acceptsEncodings', ->
    it 'should get acceptable encodings from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          acceptsEncodings: -> @headers['accept-encoding'].split /\s*\,\s*/
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'accept-encoding': 'compress, gzip, deflate, sdch, identity'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.acceptsEncodings(), [
          'compress', 'gzip', 'deflate', 'sdch', 'identity'
        ]
        yield return
  describe '#acceptsCharsets', ->
    it 'should get acceptable charsets from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          acceptsCharsets: ->
            @headers['accept-charset'].split /\s*\,\s*/
              .map (charset) ->
                data = charset.split ';'
                data[1] = if data[1]? then +data[1].split('=')[1] else 1
                data
              .sort (a, b) ->
                return 0  if a[1] is b[1]
                return if a[1] > b[1] then -1 else 1
              .map (item) -> item[0]
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'accept-charset': 'utf-8, iso-8859-1;q=0.5, *;q=0.1'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.acceptsCharsets(), [
          'utf-8', 'iso-8859-1', '*'
        ]
        yield return
  describe '#acceptsLanguages', ->
    it 'should get acceptable languages from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          acceptsLanguages: -> @headers['accept-language'].split /\s*\,\s*/
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'accept-language': 'en, ru, cn, fr'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.deepEqual context.acceptsLanguages(), [
          'en', 'ru', 'cn', 'fr'
        ]
        yield return
  describe '#get', ->
    it 'should get single header from request', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers:
            'referrer': 'localhost'
            'x-forwarded-for': '192.168.0.1'
            'x-forwarded-proto': 'https'
            'abc': 'def'
        res = headers: {}
        context = TestContext.new req, res, switchInstance
        assert.equal context.get('Referrer'), 'localhost'
        assert.equal context.get('X-Forwarded-For'), '192.168.0.1'
        assert.equal context.get('X-Forwarded-Proto'), 'https'
        assert.equal context.get('Abc'), 'def'
        assert.equal context.get('123'), ''
        yield return
  describe '#body', ->
    it 'should get and set response body', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
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
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        assert.isUndefined context.body
        context.body = 'TEST'
        assert.equal context.status, 200
        assert.equal context.message, 'OK'
        assert.equal context.response.get('Content-Type'), 'text/plain'
        assert.equal context.response.length, '4'
        context.body = null
        assert.equal context.status, 204
        assert.equal context.message, 'No Content'
        assert.equal context.response.get('Content-Type'), ''
        assert.isUndefined context.response.length
        context.response._explicitStatus = no
        context.body = new Buffer '7468697320697320612074c3a97374', 'hex'
        assert.equal context.status, 200
        assert.equal context.message, 'OK'
        assert.equal context.response.get('Content-Type'), 'application/octet-stream'
        assert.equal context.response.length, '15'
        context.body = null
        context.response._explicitStatus = no
        context.body = '<html></html>'
        assert.equal context.status, 200
        assert.equal context.message, 'OK'
        assert.equal context.response.get('Content-Type'), 'text/html'
        assert.equal context.response.length, '13'
        context.body = null
        context.response._explicitStatus = no
        context.body = { test: 'TEST' }
        assert.equal context.status, 200
        assert.equal context.message, 'OK'
        assert.equal context.response.get('Content-Type'), 'application/json'
        assert.equal context.response.length, '15'
        yield return
  describe '#status', ->
    it 'should get and set response status', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          statusCode: 200
          statusMessage: 'OK'
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        assert.equal context.status, 200
        context.status = 400
        assert.equal context.status, 400
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
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          statusCode: 200
          statusMessage: 'OK'
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        assert.equal context.message, 'OK'
        context.message = 'TEST'
        assert.equal context.message, 'TEST'
        assert.equal res.statusMessage, 'TEST'
        yield return
  describe '#length', ->
    it 'should get and set response body length', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
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
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        assert.isUndefined context.length
        context.length = 10
        assert.equal context.length, 10
        context.response.remove 'Content-Length'
        context.body = '<html></html>'
        assert.equal context.length, 13
        context.response.remove 'Content-Length'
        context.body = new Buffer '7468697320697320612074c3a97374', 'hex'
        assert.equal context.length, 15
        context.response.remove 'Content-Length'
        context.body = test: 'TEST123'
        assert.equal context.length, 18
        yield return
  describe '#writable', ->
    it 'should check if response is writable', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          writable: yes
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        assert.isTrue context.writable
        yield return
  describe '#type', ->
    it 'should get, set and remove `Content-Type` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
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
        context = TestContext.new req, res, switchInstance
        assert.equal context.type, ''
        context.type = 'markdown'
        assert.equal context.type, 'text/x-markdown'
        assert.equal res.headers['content-type'], 'text/x-markdown'
        context.type = 'file.json'
        assert.equal context.type, 'application/json'
        assert.equal res.headers['content-type'], 'application/json'
        context.type = 'text/html'
        assert.equal context.type, 'text/html'
        assert.equal res.headers['content-type'], 'text/html'
        context.type = null
        assert.equal context.type, ''
        assert.isUndefined res.headers['content-type']
        yield return
  describe '#headerSent', ->
    it 'should get res.headersSent value', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headersSent: no
          headers: {}
        context = TestContext.new req, res, switchInstance
        assert.equal context.headerSent, res.headersSent
        yield return
  describe '#redirect', ->
    it 'should send redirect', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers:
            'x-forwarded-for': '192.168.0.1'
            'accept': 'application/json, text/plain, image/png'
        res =
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
        context = TestContext.new req, res, switchInstance
        context.redirect 'back', 'http://localhost:8888/test1'
        assert.equal context.response.get('Location'), 'http://localhost:8888/test1'
        assert.equal context.status, 302
        assert.equal context.message, 'Found'
        req.headers.referrer = 'http://localhost:8888/test3'
        context.redirect 'back'
        assert.equal context.response.get('Location'), 'http://localhost:8888/test3'
        assert.equal context.status, 302
        assert.equal context.message, 'Found'
        context.redirect 'http://localhost:8888/test2'
        assert.equal context.response.get('Location'), 'http://localhost:8888/test2'
        assert.equal context.status, 302
        assert.equal context.message, 'Found'
        yield return
  describe '#attachment', ->
    it 'should setup attachment', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
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
        context = TestContext.new req, res, switchInstance
        context.attachment "#{__dirname}/#{__filename}"
        assert.equal context.type, 'application/javascript'
        assert.equal context.response.get('Content-Disposition'), 'attachment; filename="ArangoContext-test.js"'
        context.attachment 'attachment.js'
        assert.equal context.type, 'application/javascript'
        assert.equal context.response.get('Content-Disposition'), 'attachment; filename="attachment.js"'
        yield return
  describe '#set', ->
    it 'should set specified response header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        context.set 'Content-Type', 'text/plain'
        assert.equal res.headers['content-type'], 'text/plain'
        assert.equal context.response.get('Content-Type'), 'text/plain'
        now = new Date
        context.set 'Date', now
        assert.equal context.response.get('Date'), "#{now}"
        array = [ 1, now, 'TEST']
        context.set 'Test', array
        assert.deepEqual context.response.get('Test'), [ '1', "#{now}", 'TEST']
        context.set
          'Abc': 123
          'Last-Date': now
          'New-Test': 'Test'
        assert.equal context.response.get('Abc'), '123'
        assert.equal context.response.get('Last-Date'), "#{now}"
        assert.equal context.response.get('New-Test'), 'Test'
        yield return
  describe '#append', ->
    it 'should add specified response header value', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        context.append 'Test', 'data'
        assert.equal context.response.get('Test'), 'data'
        context.append 'Test', 'Test'
        assert.deepEqual context.response.get('Test'), [ 'data', 'Test' ]
        context.append 'Test', 'Test'
        assert.deepEqual context.response.get('Test'), [ 'data', 'Test', 'Test' ]
        yield return
  describe '#vary', ->
    it 'should set `Vary` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          vary: (value) -> @setHeader 'Vary', value
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        context.vary 'Origin'
        assert.equal context.response.get('Vary'), 'Origin'
        yield return
  describe '#flushHeaders', ->
    it 'should clear all headers', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        now = new Date
        array = [ 1, now, 'TEST']
        context.set
          'Content-Type': 'text/plain'
          'Date': now
          'Abc': 123
          'Last-Date': now
          'New-Test': 'Test'
          'Test': array
        assert.equal context.response.get('Content-Type'), 'text/plain'
        assert.equal context.response.get('Date'), "#{now}"
        assert.equal context.response.get('Abc'), '123'
        assert.equal context.response.get('Last-Date'), "#{now}"
        assert.equal context.response.get('New-Test'), 'Test'
        assert.deepEqual context.response.get('Test'), [ '1', "#{now}", 'TEST']
        context.flushHeaders()
        assert.equal context.response.get('Content-Type'), ''
        assert.equal context.response.get('Date'), ''
        assert.equal context.response.get('Abc'), ''
        assert.equal context.response.get('Last-Date'), ''
        assert.equal context.response.get('New-Test'), ''
        assert.equal context.response.get('Test'), ''
        yield return
  describe '#remove', ->
    it 'should remove specified response header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        context.set 'Test', 'data'
        assert.equal context.response.get('Test'), 'data'
        context.remove 'Test'
        assert.equal context.response.get('Test'), ''
        yield return
  describe '#lastModified', ->
    it 'should set `Last-Modified` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        now = new Date
        context.lastModified = now
        assert.equal res.headers['last-modified'], now.toUTCString()
        assert.deepEqual context.response.lastModified, new Date now.toUTCString()
        yield return
  describe '#etag', ->
    it 'should set `ETag` header', ->
      co ->
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
        res =
          headers: {}
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
        context = TestContext.new req, res, switchInstance
        etag = '123456789'
        context.etag = etag
        assert.equal res.headers['etag'], "\"#{etag}\""
        assert.deepEqual context.response.etag, "\"#{etag}\""
        etag = 'W/"123456789"'
        context.etag = etag
        assert.equal res.headers['etag'], etag
        assert.deepEqual context.response.etag, etag
        yield return
  describe '#onerror', ->
    it 'should run error handler', ->
      co ->
        trigger = new EventEmitter
        class Test extends LeanRC
          @inheritProtected()
          @include ArangoExtension
          @root "#{__dirname}/config/root"
        Test.initialize()
        class TestContext extends Test::ArangoContext
          @inheritProtected()
          @module Test
        TestContext.initialize()
        switchInstance =
          getViewComponent: -> trigger
          configs:
            trustProxy: yes
            cookieKey: 'COOKIE_KEY'
        req =
          url: 'http://localhost:8888'
          headers: 'x-forwarded-for': '192.168.0.1'
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
          status: (code) -> @statusCode = code
          set: (headers) ->
            for headerName, headerValue of headers ? {}
              @setHeader headerName, headerValue
          getHeaders: -> LeanRC::Utils.copy @headers
          getHeader: (field) -> @headers[field.toLowerCase()]
          setHeader: (field, value) -> @headers[field.toLowerCase()] = value
          removeHeader: (field) -> delete @headers[field.toLowerCase()]
          end: (data) -> trigger.emit 'end', data
          send: (args...) -> @end args...
        context = TestContext.new req, res, switchInstance
        errorPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'error', resolve
        endPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'end', resolve
        context.onerror 'TEST_ERROR'
        err = yield errorPromise
        data = yield endPromise
        assert.instanceOf err, Error
        assert.equal err.message, 'non-error thrown: TEST_ERROR'
        assert.equal err.status, 500
        assert.equal data, 'Internal Server Error'
        context = TestContext.new req, res, switchInstance
        errorPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'error', resolve
        endPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'end', resolve
        context.onerror new Error 'TEST_ERROR'
        err = yield errorPromise
        data = yield endPromise
        assert.instanceOf err, Error
        assert.equal err.message, 'TEST_ERROR'
        assert.equal err.status, 500
        assert.equal data, 'Internal Server Error'
        context = TestContext.new req, res, switchInstance
        errorPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'error', resolve
        endPromise = LeanRC::Promise.new (resolve) ->
          trigger.once 'end', resolve
        context.onerror httpErrors 400, 'TEST_ERROR'
        err = yield errorPromise
        data = yield endPromise
        assert.instanceOf err, httpErrors.BadRequest
        assert.isTrue err.expose
        assert.equal err.message, 'TEST_ERROR'
        assert.equal err.status, 400
        assert.equal data, 'TEST_ERROR'
        yield return
