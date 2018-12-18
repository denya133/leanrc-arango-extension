

module.exports = (Module)->
  {
    Configuration
    ArangoConfigurationMixin
  } = Module::

  class MainConfiguration extends Configuration
    @inheritProtected()
    @include ArangoConfigurationMixin
    @module Module


    @initialize()
