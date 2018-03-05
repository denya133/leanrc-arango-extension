

module.exports = (Module)->
  {
    CrudRendererMixin
    Renderer
  } = Module::

  class MainRenderer extends Renderer
    @inheritProtected()
    @include CrudRendererMixin
    @module Module


  MainRenderer.initialize()
