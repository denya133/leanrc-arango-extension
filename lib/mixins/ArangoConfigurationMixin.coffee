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
    Configuration, Mixin
    Utils: { _ }
  } = Module::

  Module.defineMixin Mixin 'ArangoConfigurationMixin', (BaseClass = Configuration) ->
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
