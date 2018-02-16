t1 = Date.now()

LeanRC = require 'LeanRC'
ArangoExtensionMixin = require '../..'

class Test extends LeanRC
  @inheritProtected()
  @include ArangoExtensionMixin

  @root __dirname

  require('./ApplicationRouter') @Module

  require('./commands/PrepareControllerCommand') @Module
  require('./commands/PrepareViewCommand') @Module
  require('./commands/PrepareModelCommand') @Module
  require('./commands/StartupCommand') @Module

  require('./ApplicationFacade') @Module

  require('./MainApplication') @Module

m = Test.initialize()

console.log 'TEST loaded in', Date.now() - t1

module.exports = m
