createAuth  = require '@arangodb/foxx/auth'


module.exports = (FoxxMC)->
  FoxxMC::Utils.auth = createAuth()
