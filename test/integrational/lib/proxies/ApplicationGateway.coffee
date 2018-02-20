

module.exports = (Module)->
  {
    Gateway
    NamespacedGatewayMixin
  } = Module::

  class ApplicationGateway extends Gateway
    @inheritProtected()
    @include NamespacedGatewayMixin
    @module Module


  ApplicationGateway.initialize()
