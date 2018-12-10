

module.exports = (Module)->
  {
    Gateway
    NamespacedGatewayMixin
    ModelingGatewayMixin
  } = Module::

  class ApplicationGateway extends Gateway
    @inheritProtected()
    @include NamespacedGatewayMixin
    @include ModelingGatewayMixin
    @module Module


    @initialize()
