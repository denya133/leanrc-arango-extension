

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


class ArangoExtension extends LeanRC::Mixin
  @inheritProtected()

  require('./iterator/ArangoCursor') ArangoExtension

  require('./mixins/AISCRouteMixin') ArangoExtension
  require('./mixins/ArangoCollectionMixin') ArangoExtension
  require('./mixins/ArangoSwitchMixin') ArangoExtension
  require('./mixins/ArangoMigrationMixin') ArangoExtension
  require('./mixins/ArangoConfigurationMixin') ArangoExtension


module.exports = ArangoExtension.initialize()
