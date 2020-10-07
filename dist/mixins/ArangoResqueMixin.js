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
  var Queues, db, flatten, internal;

  ({db} = require('@arangodb'));

  Queues = require('@arangodb/foxx/queues');

  internal = require('internal');

  ({flatten} = internal);

  /*
  ```coffee
  module.exports = (Module)->
    class ApplicationResque extends Module::Resque
      @inheritProtected()
      @include Module::ArangoResqueMixin # в этом миксине должны быть реализованы платформозависимые методы, которые будут посылать нативные запросы к реальной базе данных

      @module Module

    return ApplicationResque.initialize()
  ```
  */
  module.exports = function(Module) {
    var ARANGO_SCRIPT, AnyT, FuncG, ListG, MaybeG, Mixin, Resque, StructG, UnionG, _, inflect;
    ({
      AnyT,
      FuncG,
      ListG,
      StructG,
      MaybeG,
      UnionG,
      Resque,
      Mixin,
      Utils: {_, inflect}
    } = Module.prototype);
    ARANGO_SCRIPT = 'resque_executor';
    return Module.defineMixin(Mixin('ArangoResqueMixin', function(BaseClass = Resque) {
      return (function() {
        var _Class;

        _Class = class extends BaseClass {};

        _Class.inheritProtected();

        _Class.public({
          fullQueueName: FuncG(String, String)
        }, {
          default: function(queueName) {
            var moduleName;
            if (!/\_\_/.test(queueName)) {
              [moduleName] = this.moduleName().split('|>');
              queueName = `${moduleName}__${queueName}`;
            }
            if (/\|\>/.test(queueName)) {
              queueName = queueName.replace('|>', '__');
            }
            return inflect.underscore(queueName);
          }
        });

        _Class.public(_Class.async({
          ensureQueue: FuncG([String, MaybeG(Number)], StructG({
            name: String,
            concurrency: Number
          }))
        }, {
          default: function*(name, concurrency = 1) {
            name = this.fullQueueName(name);
            Queues.create(name, concurrency);
            return {name, concurrency};
          }
        }));

        _Class.public(_Class.async({
          getQueue: FuncG(String, MaybeG(StructG({
            name: String,
            concurrency: Number
          })))
        }, {
          default: function*(name) {
            var concurrency, err;
            name = this.fullQueueName(name);
            try {
              ({
                maxWorkers: concurrency
              } = db._queues.document(name));
              return {name, concurrency};
            } catch (error) {
              err = error;
              console.log('ERROR IN ArangoResqueMixin::getQueue', err.stack);
            }
          }
        }));

        _Class.public(_Class.async({
          removeQueue: FuncG(String)
        }, {
          default: function*(name) {
            name = this.fullQueueName(name);
            try {
              internal.deleteQueue(name);
            } catch (error) {}
          }
        }));

        _Class.public(_Class.async({
          allQueues: FuncG([], ListG(StructG({
            name: String,
            concurrency: Number
          })))
        }, {
          default: function*() {
            var concurrency, name, queues;
            queues = (function() {
              var i, len, ref, results;
              ref = db._queues.toArray();
              results = [];
              for (i = 0, len = ref.length; i < len; i++) {
                ({
                  _key: name,
                  maxWorkers: concurrency
                } = ref[i]);
                results.push({name, concurrency});
              }
              return results;
            })();
            return queues;
          }
        }));

        _Class.public(_Class.async({
          pushJob: FuncG([String, String, AnyT, MaybeG(Number)], UnionG(String, Number))
        }, {
          default: function*(queueName, scriptName, data, delayUntil) {
            var jobID, mount, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            ({mount} = this.Module.context());
            jobID = queue.push({
              name: ARANGO_SCRIPT,
              mount
            }, {scriptName, data}, {delayUntil});
            return jobID;
          }
        }));

        _Class.public(_Class.async({
          getJob: FuncG([String, UnionG(String, Number)], MaybeG(Object))
        }, {
          default: function*(queueName, jobId) {
            var job;
            try {
              // queueName = @fullQueueName queueName
              // queue = Queues.get queueName
              job = db._jobs.document(jobId);
            } catch (error) {}
            return job != null ? job : null;
          }
        }));

        _Class.public(_Class.async({
          deleteJob: FuncG([String, UnionG(String, Number)], Boolean)
        }, {
          default: function*(queueName, jobId) {
            var err, isDeleted;
            // queueName = @fullQueueName queueName
            // queue = Queues.get queueName
            // isDeleted = queue.delete jobId
            isDeleted = (function() {
              try {
                db._jobs.remove(jobId);
                return true;
              } catch (error) {
                err = error;
                return false;
              }
            })();
            return isDeleted;
          }
        }));

        _Class.public(_Class.async({
          abortJob: FuncG([String, UnionG(String, Number)])
        }, {
          default: function*(queueName, jobId) {
            var job;
            // queueName = @fullQueueName queueName
            // queue = Queues.get queueName
            // job = queue.get jobId
            // job.abort()
            job = db._jobs.document(jobId);
            if (job.status !== 'completed') {
              job.failures.push(flatten(new Error('Job aborted.')));
              db._jobs.update(job, {
                status: 'failed',
                modified: Date.now(),
                failures: job.failures
              });
            }
          }
        }));

        _Class.public(_Class.async({
          allJobs: FuncG([String, MaybeG(String)], ListG(Object))
        }, {
          default: function*(queueName, scriptName) {
            var allJobs, mount, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            if (scriptName != null) {
              ({mount} = this.Module.context());
              allJobs = queue.all({
                name: ARANGO_SCRIPT,
                mount
              }).map(function(jobId) {
                return queue.get(jobId);
              }).filter(function(job) {
                return job.data.scriptName === scriptName;
              });
              return allJobs;
            } else {
              return queue.all().map(function(jobId) {
                return queue.get(jobId);
              });
            }
          }
        }));

        _Class.public(_Class.async({
          pendingJobs: FuncG([String, MaybeG(String)], ListG(Object))
        }, {
          default: function*(queueName, scriptName) {
            var mount, pendingJobs, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            if (scriptName != null) {
              ({mount} = this.Module.context());
              pendingJobs = queue.pending({
                name: ARANGO_SCRIPT,
                mount
              }).map(function(jobId) {
                return queue.get(jobId);
              }).filter(function(job) {
                return job.data.scriptName === scriptName;
              });
              return pendingJobs;
            } else {
              return queue.pending().map(function(jobId) {
                return queue.get(jobId);
              });
            }
          }
        }));

        _Class.public(_Class.async({
          progressJobs: FuncG([String, MaybeG(String)], ListG(Object))
        }, {
          default: function*(queueName, scriptName) {
            var mount, progressJobs, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            if (scriptName != null) {
              ({mount} = this.Module.context());
              progressJobs = queue.progress({
                name: ARANGO_SCRIPT,
                mount
              }).map(function(jobId) {
                return queue.get(jobId);
              }).filter(function(job) {
                return job.data.scriptName === scriptName;
              });
              return progressJobs;
            } else {
              return queue.progress().map(function(jobId) {
                return queue.get(jobId);
              });
            }
          }
        }));

        _Class.public(_Class.async({
          completedJobs: FuncG([String, MaybeG(String)], ListG(Object))
        }, {
          default: function*(queueName, scriptName) {
            var completeJobs, mount, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            if (scriptName != null) {
              ({mount} = this.Module.context());
              completeJobs = queue.complete({
                name: ARANGO_SCRIPT,
                mount
              }).map(function(jobId) {
                return queue.get(jobId);
              }).filter(function(job) {
                return job.data.scriptName === scriptName;
              });
              return completeJobs;
            } else {
              return queue.complete().map(function(jobId) {
                return queue.get(jobId);
              });
            }
          }
        }));

        _Class.public(_Class.async({
          failedJobs: FuncG([String, MaybeG(String)], ListG(Object))
        }, {
          default: function*(queueName, scriptName) {
            var failedJobs, mount, queue;
            queueName = this.fullQueueName(queueName);
            queue = Queues.get(queueName);
            if (scriptName != null) {
              ({mount} = this.Module.context());
              failedJobs = queue.failed({
                name: ARANGO_SCRIPT,
                mount
              }).map(function(jobId) {
                return queue.get(jobId);
              }).filter(function(job) {
                return job.data.scriptName === scriptName;
              });
              return failedJobs;
            } else {
              return queue.failed().map(function(jobId) {
                return queue.get(jobId);
              });
            }
          }
        }));

        _Class.initializeMixin();

        return _Class;

      }).call(this);
    }));
  };

}).call(this);