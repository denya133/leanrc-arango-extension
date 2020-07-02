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

cleanCallback = (message = 'Job ID:') ->
  new Function 'result', 'jobData', 'job', "
    var queueName = job.queue;
    var queue = require('@arangodb/foxx/queues').get(queueName);
    var job = queue.get(job._id);
    console.log('#{message}', queueName, job.id, job.status);
    if (job.status === 'complete') {
      queue.delete(job.id);
    }
  "

cleanConfig = (successMessage = 'Job success:', failureMessage = 'Job failure:') ->
  success: cleanCallback successMessage
  failure: cleanCallback failureMessage


module.exports = (FoxxMC)->
  FoxxMC::Utils.cleanConfig =
    cleanCallback: cleanCallback
    cleanConfig: cleanConfig
