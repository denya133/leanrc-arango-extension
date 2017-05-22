

LeanRC = require 'LeanRC'

###
Example of use

```coffee
LeanRC = require 'LeanRC'
ArangoExtension = require 'leanrc-arango-extension'

class TestApp extends LeanRC
  @inheritProtected()
  @include ArangoExtension

  @const ANIMATE_ROBOT: Symbol 'animateRobot'
  @const ROBOT_SPEAKING: Symbol 'robotSpeaking'

  require('./controller/command/StartupCommand') TestApp
  require('./controller/command/PrepareControllerCommand') TestApp
  require('./controller/command/PrepareViewCommand') TestApp
  require('./controller/command/PrepareModelCommand') TestApp
  require('./controller/command/AnimateRobotCommand') TestApp

  require('./view/component/ConsoleComponent') TestApp
  require('./view/mediator/ConsoleComponentMediator') TestApp

  require('./model/proxy/RobotDataProxy') TestApp

  require('./AppFacade') TestApp


module.exports = TestApp.initialize().freeze()
```
###

Extension = (BaseClass) ->
  class ArangoExtension extends BaseClass
    @inheritProtected()

    require('./iterator/ArangoCursor') @Module # needs testing

    require('./mixins/AISCRouteMixin') @Module # needs testing # empty
    require('./mixins/ArangoCollectionMixin') @Module # needs testing
    require('./mixins/ArangoSwitchMixin') @Module # needs testing
    require('./mixins/ArangoMigrationMixin') @Module # needs testing
    require('./mixins/ArangoConfigurationMixin') @Module # needs testing
    require('./mixins/ArangoResqueMixin') @Module # needs testing
  ArangoExtension.initializeMixin()

sample = Extension LeanRC
Reflect.defineProperty Extension, 'reification',
  value: sample


module.exports = Extension
