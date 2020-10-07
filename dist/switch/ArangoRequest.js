// Generated by CoffeeScript 2.5.1
(function() {
  // This file is part of leanrc-arango-extension.

  // leanrc-arango-extension is free software: you can redistribute it and/or modify
  // it under the terms of the GNU Lesser General Public License as published by
  // the Free Software Foundation, either version 3 of the License, or
  // (at your option) any later version.

  // leanrc-arango-extension is distributed in the hope that it will be useful,
  // but WITHOUT ANY WARRANTY; without even the implied warranty of
  // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  // GNU Lesser General Public License for more details.

  // You should have received a copy of the GNU Lesser General Public License
  // along with leanrc-arango-extension.  If not, see <https://www.gnu.org/licenses/>.
  var contentType, fresh, net, parse, qs, stringify;

  net = require('net'); // will be used only 'isIP' function

  contentType = require('content-type');

  stringify = require('url').format;

  parse = require('parseurl');

  qs = require('querystring');

  fresh = require('fresh');

  /*
  Идеи взяты из https://github.com/koajs/koa/blob/master/lib/request.js
  */
  module.exports = function(Module) {
    var AnyT, ArangoRequest, ContextInterface, CoreObject, FuncG, MaybeG, NilT, RequestInterface, SwitchInterface, UnionG, _;
    ({
      AnyT,
      NilT,
      FuncG,
      UnionG,
      MaybeG,
      RequestInterface,
      SwitchInterface,
      ContextInterface,
      CoreObject,
      // RequestInterface
      // SwitchInterface
      // ContextInterface
      Utils: {_}
    } = Module.prototype);
    return ArangoRequest = (function() {
      class ArangoRequest extends CoreObject {};

      ArangoRequest.inheritProtected();

      ArangoRequest.implements(RequestInterface);

      ArangoRequest.module(Module);

      ArangoRequest.public({
        req: Object // native request object
      }, {
        get: function() {
          return this.ctx.req;
        }
      });

      ArangoRequest.public({
        switch: SwitchInterface
      }, {
        get: function() {
          return this.ctx.switch;
        }
      });

      ArangoRequest.public({
        ctx: ContextInterface
      });

      ArangoRequest.public({
        body: MaybeG(AnyT) // тело должен предоставлять миксин из отдельного модуля
      });

      ArangoRequest.public({
        header: Object
      }, {
        get: function() {
          return this.headers;
        }
      });

      ArangoRequest.public({
        headers: Object
      }, {
        get: function() {
          return this.req.headers;
        }
      });

      ArangoRequest.public({
        originalUrl: String
      }, {
        get: function() {
          return this.ctx.originalUrl;
        }
      });

      ArangoRequest.public({
        url: String
      }, {
        get: function() {
          return this.req.url;
        },
        set: function(url) {
          return this.req.url = url;
        }
      });

      ArangoRequest.public({
        origin: String
      }, {
        get: function() {
          return `${this.protocol}://${this.host}`;
        }
      });

      ArangoRequest.public({
        href: String
      }, {
        get: function() {
          if (/^https?:\/\//i.test(this.originalUrl)) {
            return this.originalUrl;
          }
          return this.origin + this.originalUrl;
        }
      });

      ArangoRequest.public({
        method: String
      }, {
        get: function() {
          return this.req.method;
        },
        set: function(method) {
          return this.req.method = method;
        }
      });

      ArangoRequest.public({
        path: String
      }, {
        get: function() {
          return parse(this.req).pathname;
        },
        set: function(path) {
          var url;
          url = parse(this.req);
          if (url.pathname === path) {
            return;
          }
          url.pathname = path;
          url.path = null;
          return this.url = stringify(url);
        }
      });

      ArangoRequest.public({
        query: Object
      }, {
        get: function() {
          return qs.parse(this.querystring);
        },
        set: function(obj) {
          this.querystring = qs.stringify(obj);
          return obj;
        }
      });

      ArangoRequest.public({
        querystring: String
      }, {
        get: function() {
          var ref;
          if (this.req == null) {
            return '';
          }
          return (ref = parse(this.req).query) != null ? ref : '';
        },
        set: function(str) {
          var url;
          url = parse(this.req);
          if (url.search === `?${str}`) {
            return;
          }
          url.search = str;
          url.path = null;
          return this.url = stringify(url);
        }
      });

      ArangoRequest.public({
        search: String
      }, {
        get: function() {
          if (!this.querystring) {
            return '';
          }
          return `?${this.querystring}`;
        },
        set: function(str) {
          return this.querystring = str;
        }
      });

      ArangoRequest.public({
        host: String
      }, {
        get: function() {
          var host, trustProxy;
          ({trustProxy} = this.ctx.switch.configs);
          host = trustProxy && this.get('X-Forwarded-Host');
          host = host || this.get('Host');
          if (!host) {
            return '';
          }
          return host.split(/\s*,\s*/)[0];
        }
      });

      ArangoRequest.public({
        hostname: String
      }, {
        get: function() {
          var host;
          host = this.host;
          if (!host) {
            return '';
          }
          return host.split(':')[0];
        }
      });

      ArangoRequest.public({
        fresh: Boolean
      }, {
        get: function() {
          var method, s;
          method = this.method;
          s = this.ctx.status;
          // GET or HEAD for weak freshness validation only
          if ('GET' !== method && 'HEAD' !== method) {
            return false;
          }
          // 2xx or 304 as per rfc2616 14.26
          if ((s >= 200 && s < 300) || 304 === s) {
            return fresh(this.headers, this.ctx.response.headers);
          }
          return false;
        }
      });

      ArangoRequest.public({
        stale: Boolean
      }, {
        get: function() {
          return !this.fresh;
        }
      });

      ArangoRequest.public({
        idempotent: Boolean
      }, {
        get: function() {
          var methods;
          methods = ['GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS', 'TRACE'];
          return _.includes(methods, this.method);
        }
      });

      ArangoRequest.public({
        socket: MaybeG(Object)
      }, {
        get: function() {}
      });

      ArangoRequest.public({
        charset: String
      }, {
        get: function() {
          var err, ref, type;
          type = this.get('Content-Type');
          if (type == null) {
            return '';
          }
          try {
            type = contentType.parse(type);
          } catch (error) {
            err = error;
            return '';
          }
          return (ref = type.parameters.charset) != null ? ref : '';
        }
      });

      ArangoRequest.public({
        length: Number
      }, {
        get: function() {
          var contentLength;
          if ((contentLength = this.get('Content-Length')) != null) {
            if (contentLength === '') {
              return 0;
            }
            return ~~Number(contentLength);
          } else {
            return 0;
          }
        }
      });

      ArangoRequest.public({
        protocol: String
      }, {
        get: function() {
          return this.req.protocol;
        }
      });

      ArangoRequest.public({
        secure: Boolean
      }, {
        get: function() {
          return this.req.secure;
        }
      });

      ArangoRequest.public({
        ip: String
      });

      ArangoRequest.public({
        ips: Array
      }, {
        get: function() {
          var trustProxy, value;
          ({trustProxy} = this.ctx.switch.configs);
          value = this.get('X-Forwarded-For');
          if (trustProxy && value) {
            return value.split(/\s*,\s*/);
          } else {
            return [];
          }
        }
      });

      ArangoRequest.public({
        subdomains: Array
      }, {
        get: function() {
          var hostname, offset;
          ({
            subdomainOffset: offset
          } = this.ctx.switch.configs);
          hostname = this.hostname;
          if (net.isIP(hostname) !== 0) {
            return [];
          }
          return hostname.split('.').reverse().slice(offset != null ? offset : 0);
        }
      });

      ArangoRequest.public({
        accepts: FuncG([MaybeG(UnionG(String, Array))], UnionG(String, Array, Boolean))
      }, {
        default: function(...args) {
          return this.ctx.accept.types(...args);
        }
      });

      ArangoRequest.public({
        acceptsEncodings: FuncG([MaybeG(UnionG(String, Array))], UnionG(String, Array))
      }, {
        default: function(...args) {
          return this.ctx.accept.encodings(...args);
        }
      });

      ArangoRequest.public({
        acceptsCharsets: FuncG([MaybeG(UnionG(String, Array))], UnionG(String, Array))
      }, {
        default: function(...args) {
          return this.ctx.accept.charsets(...args);
        }
      });

      ArangoRequest.public({
        acceptsLanguages: FuncG([MaybeG(UnionG(String, Array))], UnionG(String, Array))
      }, {
        default: function(...args) {
          return this.ctx.accept.languages(...args);
        }
      });

      ArangoRequest.public({
        'is': FuncG([UnionG(String, Array)], UnionG(String, Boolean, NilT))
      }, {
        default: function(...args) {
          return this.req.is(...args);
        }
      });

      ArangoRequest.public({
        type: String
      }, {
        get: function() {
          var type;
          type = this.get('Content-Type');
          if (type == null) {
            return '';
          }
          return type.split(';')[0];
        }
      });

      ArangoRequest.public({
        get: FuncG(String, String)
      }, {
        default: function(field) {
          var ref, ref1, ref2;
          switch (field = field.toLowerCase()) {
            case 'referer':
            case 'referrer':
              return (ref = (ref1 = this.req.headers.referrer) != null ? ref1 : this.req.headers.referer) != null ? ref : '';
            default:
              return (ref2 = this.req.headers[field]) != null ? ref2 : '';
          }
        }
      });

      ArangoRequest.public(ArangoRequest.static(ArangoRequest.async({
        restoreObject: Function
      }, {
        default: function*() {
          throw new Error(`restoreObject method not supported for ${this.name}`);
        }
      })));

      ArangoRequest.public(ArangoRequest.static(ArangoRequest.async({
        replicateObject: Function
      }, {
        default: function*() {
          throw new Error(`replicateObject method not supported for ${this.name}`);
        }
      })));

      ArangoRequest.public({
        init: FuncG(ContextInterface)
      }, {
        default: function(context) {
          var ref, ref1;
          this.super();
          this.ctx = context;
          this.ip = (ref = (ref1 = this.ips[0]) != null ? ref1 : this.req.remoteAddress) != null ? ref : '';
        }
      });

      ArangoRequest.initialize();

      return ArangoRequest;

    }).call(this);
  };

}).call(this);