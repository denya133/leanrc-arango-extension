

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
  Module.defineMixin (BaseClass) ->
    class ArangoConfigurationMixin extends BaseClass
      @inheritProtected()

      @public defineConfigProperties: Function,
        args: []
        return: NILL
        default: ->
          configs = module.context.configuration
          for own key, value of configs
            do (attr = key, config = value)=>
              unless config.description?
                throw new Error "Description in config definition is required"
                return
              if config.required and not config.default?
                throw new Error "Attribute '#{attr}' is required in config"
                return
              # проверка типа
              unless config.type?
                throw new Error "Type in config definition is required"
                return
              switch config.type
                when 'string'
                  unless _.isString config.default
                    throw new Error "Default for '#{attr}' must be string"
                    return
                when 'number'
                  unless _.isNumber config.default
                    throw new Error "Default for '#{attr}' must be number"
                    return
                when 'boolean'
                  unless _.isBoolean config.default
                    throw new Error "Default for '#{attr}' must be boolean"
                    return
                when 'integer'
                  unless _.isInteger config.default
                    throw new Error "Default for '#{attr}' must be integer"
                    return
                when 'json'
                  unless _.isObject(config.default) or _.isArray(config.default)
                    throw new Error "Default for '#{attr}' must be object or array"
                    return
                when 'password' #like string but will be displayed as a masked input field in the web frontend
                  unless _.isString config.default
                    throw new Error "Default for '#{attr}' must be string"
                    return
              Reflect.defineProperty @, attr,
                enumerable: yes
                configurable: yes
                writable: no
                value: config.default
              return
          return


    ArangoConfigurationMixin.initializeMixin()
