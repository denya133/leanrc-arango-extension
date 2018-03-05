

module.exports = (Module)->
  {
    APPLICATION_RENDERER
    APPLICATION_ROUTER

    Switch
    ArangoSwitchMixin
    # Utils: {
    #   _
    #   co
    #   genRandomAlphaNumbers
    #   inflect
    #   statuses
    # }
  } = Module::

  class MainSwitch extends Switch
    @inheritProtected()
    @include ArangoSwitchMixin
    @module Module

    @public routerName: String,
      default: APPLICATION_ROUTER
    @public jsonRendererName: String,
      default: APPLICATION_RENDERER

    @public responseFormats: Array,
      get: -> [
        'application/octet-stream', 'json', 'html', 'xml', 'atom', 'text'
      ]


  MainSwitch.initialize()
