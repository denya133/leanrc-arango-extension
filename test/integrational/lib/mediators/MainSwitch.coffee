

module.exports = (Module)->
  {
    APPLICATION_RENDERER
    APPLICATION_ROUTER
    ListG
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

    @public responseFormats: ListG(String),
      get: -> [
        'application/octet-stream', 'json', 'html', 'xml', 'atom', 'text'
      ]


    @initialize()
