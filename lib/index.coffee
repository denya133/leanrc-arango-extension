

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
  class extends BaseClass
    @inheritProtected()

    coContext = module.context
    @public @static context: Function,
      default: -> coContext

    require('./iterator/ArangoCursor') @Module

    require('./switch/SyntheticRequest') @Module # needs test
    require('./switch/SyntheticResponse') @Module # needs test
    require('./switch/ArangoRequest') @Module
    require('./switch/ArangoResponse') @Module
    require('./switch/ArangoContext') @Module

    require('./mixins/ArangoForeignCollectionMixin') @Module # needs test
    require('./mixins/ArangoCollectionMixin') @Module
    require('./mixins/ArangoSwitchMixin') @Module # needs retest
    require('./mixins/ArangoResourceMixin') @Module # needs retest
    require('./mixins/ArangoMigrationMixin') @Module
    require('./mixins/ArangoConfigurationMixin') @Module
    require('./mixins/ArangoResqueMixin') @Module
    require('./mixins/ArangoSerializerMixin') @Module
    require('./mixins/ArangoExecutorMixin') @Module
    @initializeMixin()

Reflect.defineProperty Extension, 'name',
  value: 'ArangoExtension'


module.exports = Extension
