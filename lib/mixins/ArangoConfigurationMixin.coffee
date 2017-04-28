

_             = require 'lodash'
LeanRC        = require 'LeanRC'


###
```coffee
module.exports = (Module)->
  class AppConfiguration extends Module::Configuration
    @inheritProtected()
    @include Module::ArangoConfigurationMixin

    @module Module

  return AppConfiguration.initialize()
```
###

###
```coffee
module.exports = (Module)->
  {CONFIGURATION} = Module::

  class PrepareModelCommand extends Module::SimpleCommand
    @inheritProtected()

    @module Module

    @public execute: Function,
      default: ->
        #...
        @facade.registerProxy Module::AppConfiguration.new CONFIGURATION,
          environment: 'production'
        #...

  PrepareModelCommand.initialize()
```
###


module.exports = (Module)->
  Module.defineMixin (BaseClass) ->
    class ArangoConfigurationMixin extends BaseClass
      @inheritProtected()

      @public configs: Object,
        get: ->
          module.context.configuration


    ArangoConfigurationMixin.initializeMixin()
