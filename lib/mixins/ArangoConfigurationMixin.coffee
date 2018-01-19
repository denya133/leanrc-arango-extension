

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
  {
    Configuration
    Utils: { _ }
  } = Module::

  Module.defineMixin 'ArangoConfigurationMixin', (BaseClass = Configuration) ->
    class extends BaseClass
      @inheritProtected()

      @public defineConfigProperties: Function,
        default: ->
          Reflect.defineProperty @, 'name',
            enumerable: yes
            configurable: yes
            writable: no
            value: @Module.context().manifest.name
          Reflect.defineProperty @, 'description',
            enumerable: yes
            configurable: yes
            writable: no
            value: @Module.context().manifest.description
          Reflect.defineProperty @, 'license',
            enumerable: yes
            configurable: yes
            writable: no
            value: @Module.context().manifest.license
          Reflect.defineProperty @, 'version',
            enumerable: yes
            configurable: yes
            writable: no
            value: @Module.context().manifest.version
          Reflect.defineProperty @, 'keywords',
            enumerable: yes
            configurable: yes
            writable: no
            value: @Module.context().manifest.keywords
          configs = @Module.context().configuration
          for own key, value of configs
            do (attr = key, config = value)=>
              Reflect.defineProperty @, attr,
                enumerable: yes
                configurable: yes
                writable: no
                value: config
              return
          return


      @initializeMixin()
