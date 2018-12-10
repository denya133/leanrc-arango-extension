

module.exports = (Module) ->
  {
    Application
  } = Module::

  class LoggerApplication extends Application
    @inheritProtected()
    @module Module


    @initialize()
