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

  // надо реализовать в отдельном модуле (npm-пакете) так как является платформозависимым
  // здесь должна быть реализация интерфейса SwitchInterface работающая с Foxx роутером.
  var ARANGO_CONFLICT, ARANGO_DUPLICATE, ARANGO_NOT_FOUND, EventEmitter, FoxxRouter, db, errors, methods, pathToRegexp,
    indexOf = [].indexOf;

  methods = require('methods');

  FoxxRouter = require('@arangodb/foxx/router');

  ({db} = require('@arangodb'));

  ({errors} = require('@arangodb'));

  EventEmitter = require('events');

  pathToRegexp = require('path-to-regexp');

  ARANGO_NOT_FOUND = errors.ERROR_ARANGO_DOCUMENT_NOT_FOUND.code;

  ARANGO_DUPLICATE = errors.ERROR_ARANGO_UNIQUE_CONSTRAINT_VIOLATED.code;

  ARANGO_CONFLICT = errors.ERROR_ARANGO_CONFLICT.code;

  // здесь (наверху) надо привести пример использования в приложении
  /*
  ```coffee
  module.exports = (Module)->
    class HttpSwitch extends Module::Switch
      @inheritProtected()
      @include Module::ArangoSwitchMixin

      @module Module

      @public routerName: String,
        default: 'ApplicationRouter'
      @public jsonRendererName: String,
        default: 'JsonRenderer'  # or 'ApplicationRenderer'
    HttpSwitch.initialize()
  ```
  */
  module.exports = function(Module) {
    var APPLICATION_GATEWAY, AnyT, ArangoContext, AsyncFunctionT, ContextInterface, DEBUG, DictG, ERROR, EnumG, FuncG, HTTP_CONFLICT, HTTP_NOT_FOUND, InterfaceG, LEVELS, LambdaT, ListG, MaybeG, Mixin, NotificationInterface, PointerT, SEND_TO_LOG, StructG, Switch, SwitchInterface, SyntheticRequest, SyntheticResponse, TupleG, _, co, genRandomAlphaNumbers, inflect, statuses;
    ({
      APPLICATION_GATEWAY,
      AnyT,
      PointerT,
      AsyncFunctionT,
      LambdaT,
      FuncG,
      ListG,
      MaybeG,
      InterfaceG,
      StructG,
      TupleG,
      DictG,
      EnumG,
      SwitchInterface,
      ContextInterface,
      NotificationInterface,
      Mixin,
      Switch,
      ArangoContext,
      SyntheticRequest,
      SyntheticResponse,
      LogMessage: {ERROR, DEBUG, LEVELS, SEND_TO_LOG},
      Utils: {_, inflect, co, genRandomAlphaNumbers, statuses}
    } = Module.prototype);
    HTTP_NOT_FOUND = statuses('not found');
    HTTP_CONFLICT = statuses('conflict');
    return Module.defineMixin(Mixin('ArangoSwitchMixin', function(BaseClass = Switch) {
      return (function() {
        var Class, _Class, decode, iphEventNames, matches;

        _Class = class extends BaseClass {};

        _Class.inheritProtected();

        iphEventNames = PointerT(_Class.private({
          eventNames: Object
        }));

        _Class.public({
          middlewaresHandler: LambdaT
        });

        // from https://github.com/koajs/route/blob/master/index.js ###############
        decode = FuncG([MaybeG(String)], MaybeG(String))(function(val) { // чистая функция
          if (val) {
            return decodeURIComponent(val);
          }
        });

        matches = FuncG([ContextInterface, String], Boolean)(function(ctx, method) {
          if (!method) {
            return true;
          }
          if (ctx.method === method) {
            return true;
          }
          if (method === 'GET' && ctx.method === 'HEAD') {
            return true;
          }
          return false;
        });

        //###############
        _Class.public(_Class.static({
          createMethod: FuncG([MaybeG(String)])
        }, {
          default: function(method) {
            var originMethodName;
            originMethodName = method;
            if (method) {
              method = method.toUpperCase();
            } else {
              originMethodName = 'all';
            }
            this.public({
              [`${originMethodName}`]: FuncG([String, Function], TupleG(Object, Object))
            }, {
              default: function(path, routeFunc) {
                var keys, re, self, voEndpoint, voRouter;
                voRouter = FoxxRouter();
                if (!routeFunc) {
                  throw new Error('handler is required');
                }
                keys = [];
                re = pathToRegexp(path, keys);
                this.sendNotification(SEND_TO_LOG, `${method != null ? method : 'ALL'} ${path} -> ${re} has been defined`, LEVELS[DEBUG]);
                self = this;
                this.use(keys.length, co.wrap(function*(ctx) {
                  var m, pathParams;
                  if (!matches(ctx, method)) {
                    return;
                  }
                  m = re.exec(ctx.path);
                  if (m) {
                    pathParams = m.slice(1).map(decode).reduce(function(prev, item, index) {
                      prev[keys[index].name] = item;
                      return prev;
                    }, {});
                    ctx.routePath = path;
                    self.sendNotification(SEND_TO_LOG, `${ctx.method} ${path} matches ${ctx.path} ${JSON.stringify(pathParams)}`, LEVELS[DEBUG]);
                    ctx.pathParams = pathParams;
                    ctx.req.pathParams = pathParams;
                    return (yield routeFunc.call(self, ctx));
                  }
                }));
                voEndpoint = typeof voRouter[originMethodName] === "function" ? voRouter[originMethodName](path, this.callback(path, routeFunc)) : void 0;
                return [voRouter, voEndpoint];
              }
            });
          }
        }));

        Class = _Class;

        methods.forEach(function(method) {
          return Class.createMethod(method);
        });

        _Class.public({
          del: Function
        }, {
          default: function(...args) {
            return this.delete(...args);
          }
        });

        _Class.createMethod(); // create @public all:...

        //#########################################################################
        _Class.public(_Class.async({
          perform: FuncG(StructG({
            method: String,
            url: String,
            options: InterfaceG({
              json: EnumG([true]),
              headers: DictG(String, String),
              body: MaybeG(Object)
            })
          }), StructG({
            body: MaybeG(AnyT),
            headers: DictG(String, String),
            status: Number,
            message: MaybeG(String)
          }))
        }, {
          default: function*(method, url, options) {
            var body, err, headers, message, req, res, status, voContext;
            this.sendNotification(SEND_TO_LOG, '>>>>>> START PERFORM-REQUEST HANDLING', LEVELS[DEBUG]);
            req = SyntheticRequest.new(this.Module.context());
            res = SyntheticResponse.new(this.Module.context());
            req.method = method;
            req.url = url;
            req.initialUrl = url;
            req.headers = options.headers;
            if (options.body != null) {
              req.body = options.body;
              req.rawBody = new Buffer(JSON.stringify(options.body));
            }
            res.statusCode = 404;
            voContext = ArangoContext.new(req, res, this);
            voContext.isPerformExecution = true;
            try {
              yield this.middlewaresHandler(voContext);
              this.respond(voContext);
            } catch (error1) {
              err = error1;
              voContext.onerror(err);
            }
            ({
              statusCode: status,
              statusMessage: message,
              body,
              headers
            } = res);
            this.sendNotification(SEND_TO_LOG, '>>>>>> END PERFORM-REQUEST HANDLING', LEVELS[DEBUG]);
            return {status, message, headers, body};
          }
        }));

        _Class.public({
          onRegister: Function
        }, {
          default: function() { // super не вызываем
            var FILTER, eventNames, voEmitter;
            voEmitter = new EventEmitter();
            if (!_.isFunction(voEmitter.eventNames)) {
              eventNames = this[iphEventNames] = {};
              FILTER = ['newListener', 'removeListener'];
              voEmitter.on('newListener', function(event, listener) {
                if (indexOf.call(FILTER, event) < 0) {
                  if (eventNames[event] == null) {
                    eventNames[event] = 0;
                  }
                  ++eventNames[event];
                }
              });
              voEmitter.on('removeListener', function(event, listener) {
                if (indexOf.call(FILTER, event) < 0) {
                  if (eventNames[event] > 0) {
                    --eventNames[event];
                  }
                }
              });
            }
            if (voEmitter.listeners('error').length === 0) {
              voEmitter.on('error', this.onerror.bind(this));
            }
            this.setViewComponent(voEmitter);
            this.defineRoutes();
            this.serverListen();
          }
        });

        _Class.public({
          onRemove: Function
        }, {
          default: function() { // super не вызываем
            var eventNames, ref, ref1, voEmitter;
            voEmitter = this.getViewComponent();
            eventNames = (ref = typeof voEmitter.eventNames === "function" ? voEmitter.eventNames() : void 0) != null ? ref : Object.keys((ref1 = this[iphEventNames]) != null ? ref1 : {});
            eventNames.forEach(function(eventName) {
              return voEmitter.removeAllListeners(eventName);
            });
          }
        });

        _Class.public({
          serverListen: Function
        }, {
          default: function() {
            this.middlewaresHandler = this.constructor.compose(this.middlewares, this.handlers);
          }
        });

        _Class.public({
          callback: FuncG([], AsyncFunctionT)
        }, {
          default: function(path, routeFunc) {
            var handleRequest, self;
            self = this;
            handleRequest = co.wrap(function*(req, res) {
              var err, reqLength, resLength, t1, time, voContext;
              t1 = Date.now();
              ({ERROR, DEBUG, LEVELS, SEND_TO_LOG} = Module.prototype.LogMessage);
              self.sendNotification(SEND_TO_LOG, '>>>>>> START REQUEST HANDLING', LEVELS[DEBUG]);
              res.statusCode = 404;
              voContext = ArangoContext.new(req, res, self);
              voContext.routePath = path;
              self.sendNotification(SEND_TO_LOG, `${voContext.method} ${path} matches ${voContext.path} ${JSON.stringify(req.pathParams)}`, LEVELS[DEBUG]);
              voContext.pathParams = req.pathParams;
              try {
                yield routeFunc.call(self, voContext);
                self.respond(voContext);
              } catch (error1) {
                err = error1;
                voContext.onerror(err);
              }
              self.sendNotification(SEND_TO_LOG, '>>>>>> END REQUEST HANDLING', LEVELS[DEBUG]);
              reqLength = voContext.request.length;
              resLength = voContext.response.length;
              time = Date.now() - t1;
              yield self.handleStatistics(reqLength, resLength, time, voContext);
            });
            return handleRequest;
          }
        });

        _Class.public({
          respond: FuncG(ContextInterface)
        }, {
          default: function(ctx) {
            var body, code, ref;
            if (ctx.respond === false) {
              return;
            }
            if (!ctx.writable) {
              return;
            }
            body = ctx.body;
            code = ctx.status;
            if (statuses.empty[code]) {
              ctx.body = null;
              return ctx.res.send();
            }
            if ('HEAD' === ctx.method) {
              return ctx.res.send();
            }
            if (body == null) {
              body = (ref = ctx.message) != null ? ref : String(code);
              return ctx.res.send(body);
            }
            ctx.res.send(body);
          }
        });

        _Class.public({
          defineSwaggerEndpoint: FuncG([
            Object,
            InterfaceG({
              method: String,
              path: String,
              resource: String,
              action: String,
              tag: String,
              template: String,
              keyName: MaybeG(String),
              entityName: String,
              recordName: MaybeG(String)
            })
          ])
        }, {
          default: function(aoSwaggerEndpoint, {
              resource,
              action,
              tag: resourceTag,
              options,
              keyName,
              entityName,
              recordName
            }) {
            var headers, isDeprecated, pathParams, payload, queryParams, responses, synopsis, tags, title, voGateway, voSwaggerDefinition;
            voGateway = this.facade.retrieveProxy(APPLICATION_GATEWAY);
            if (voGateway == null) {
              throw new Error(`${APPLICATION_GATEWAY} is absent in code`);
            }
            voSwaggerDefinition = voGateway.swaggerDefinitionFor(resource, action, {keyName, entityName, recordName});
            if (voSwaggerDefinition == null) {
              // throw new Error "#{gatewayName}::#{action} is absent in code"
              throw new Error(`Endpoint for ${resource}#${action} is absent in code`);
            }
            ({tags, headers, pathParams, queryParams, payload, responses, errors, title, synopsis, isDeprecated} = voSwaggerDefinition);
            if (resourceTag != null) {
              aoSwaggerEndpoint.tag(resourceTag);
            }
            if (tags != null ? tags.length : void 0) {
              aoSwaggerEndpoint.tag(...tags);
            }
            if (headers != null) {
              headers.forEach(function({name, schema, description}) {
                return aoSwaggerEndpoint.header(name, schema, description);
              });
            }
            if (pathParams != null) {
              pathParams.forEach(function({name, schema, description}) {
                return aoSwaggerEndpoint.pathParam(name, schema, description);
              });
            }
            if (queryParams != null) {
              queryParams.forEach(function({name, schema, description}) {
                return aoSwaggerEndpoint.queryParam(name, schema, description);
              });
            }
            if (payload != null) {
              aoSwaggerEndpoint.body(payload.schema, payload.mimes, payload.description);
            }
            if (responses != null) {
              responses.forEach(function({status, schema, mimes, description}) {
                // responses?.forEach (args)->
                return aoSwaggerEndpoint.response(status, schema, mimes, description);
              });
            }
            // aoSwaggerEndpoint.response args...
            if (errors != null) {
              errors.forEach(function({status, description}) {
                return aoSwaggerEndpoint.error(status, description);
              });
            }
            if (title != null) {
              aoSwaggerEndpoint.summary(title);
            }
            if (synopsis != null) {
              aoSwaggerEndpoint.description(synopsis);
            }
            if (isDeprecated != null) {
              aoSwaggerEndpoint.deprecated(isDeprecated);
            }
          }
        });

        _Class.public({
          sender: FuncG([
            String,
            StructG({
              context: ContextInterface,
              reverse: String
            }),
            InterfaceG({
              method: String,
              path: String,
              resource: String,
              action: String,
              tag: String,
              template: String,
              keyName: MaybeG(String),
              entityName: String,
              recordName: MaybeG(String)
            })
          ])
        }, {
          default: function(resourceName, aoMessage, {method, path, resource, action}) {
            var context, err;
            ({context} = aoMessage);
            try {
              this.sendNotification(resourceName, aoMessage, action);
            } catch (error1) {
              err = error1;
              console.error('???????????????????!!', JSON.stringify(err));
              if (err.isArangoError && err.errorNum === ARANGO_NOT_FOUND) {
                context.throw(HTTP_NOT_FOUND, err.message);
                return;
              }
              if (err.isArangoError && err.errorNum === ARANGO_CONFLICT) {
                context.throw(HTTP_CONFLICT, err.message);
                return;
              } else if (err.statusCode != null) {
                console.error('kkkkkkkk1111', err.message, err.stack);
                context.throw(err.statusCode, err.message);
              } else {
                console.error('kkkkkkkk2222', err.message, err.stack);
                context.throw(500, err.message, err.stack);
                return;
              }
            }
          }
        });

        _Class.public({
          createNativeRoute: FuncG([
            InterfaceG({
              method: String,
              path: String,
              resource: String,
              action: String,
              tag: String,
              template: String,
              keyName: MaybeG(String),
              entityName: String,
              recordName: MaybeG(String)
            })
          ])
        }, {
          default: function(opts) {
            var method, path, resourceName, self, voEndpoint, voRouter;
            ({method, path} = opts);
            resourceName = inflect.camelize(inflect.underscore(`${opts.resource.replace(/[\/]/g, '_')}Resource`));
            self = this;
            [voRouter, voEndpoint] = typeof this[method] === "function" ? this[method](path, co.wrap(function*(context) {
              yield Module.prototype.Promise.new(function(resolve, reject) {
                var err, reverse;
                try {
                  reverse = genRandomAlphaNumbers(32);
                  self.getViewComponent().once(reverse, co.wrap(function*({error, result, resource}) {
                    var err;
                    self.sendNotification(SEND_TO_LOG, `ArangoSwitchMixin::createNativeRoute <result from resource> isError ${error != null} ${error != null ? error.stack : void 0} result: ${JSON.stringify(result)} resource: ${resource.constructor.name}`, LEVELS[DEBUG]);
                    if (error != null) {
                      reject(error);
                      return;
                    }
                    try {
                      yield self.sendHttpResponse(context, result, resource, opts);
                      resolve();
                    } catch (error1) {
                      err = error1;
                      reject(err);
                    }
                  }));
                  self.sender(resourceName, {context, reverse}, opts);
                } catch (error1) {
                  err = error1;
                  reject(err);
                }
              });
              return true;
            })) : void 0;
            this.defineSwaggerEndpoint(voEndpoint, opts);
            this.Module.context().use(voRouter);
          }
        });

        _Class.initializeMixin();

        return _Class;

      }).call(this);
    }));
  };

}).call(this);
