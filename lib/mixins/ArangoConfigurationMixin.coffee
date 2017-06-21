

_             = require 'lodash'


###
```coffee
module.exports = (Module)->
  {
    Configuration
    ArangoConfigurationMixin
  } = Module::

  class AppConfiguration extends Configuration
    @inheritProtected()
    @module Module
    @include ArangoConfigurationMixin

  return AppConfiguration.initialize()
```
###

###
```coffee
module.exports = (Module)->
  {
    CONFIGURATION

    SimpleCommand
    AppConfiguration
  } = Module::

  class PrepareModelCommand extends SimpleCommand
    @inheritProtected()

    @module Module

    @public execute: Function,
      default: ->
        #...
        @facade.registerProxy AppConfiguration.new CONFIGURATION
        #...

  PrepareModelCommand.initialize()
```
###


module.exports = (Module)->
  { NILL } = Module
  Module.defineMixin Module::Configuration, (BaseClass) ->
    class ArangoConfigurationMixin extends BaseClass
      @inheritProtected()

      @public defineConfigProperties: Function,
        args: []
        return: NILL
        default: ->
          console.log '>>> IN ArangoConfigurationMixin', @Module.name, @Module.context?
          configs = @Module.context.configuration
          for own key, value of configs
            do (attr = key, config = value)=>
              Reflect.defineProperty @, attr,
                enumerable: yes
                configurable: yes
                writable: no
                value: config
              return
          return


    ArangoConfigurationMixin.initializeMixin()
