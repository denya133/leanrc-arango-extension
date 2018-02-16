

module.exports = (Module)->
  {
    Gateway
    # CrudGatewayMixin
  } = Module::

  class ApplicationGateway extends Gateway
    @inheritProtected()
    # @include CrudGatewayMixin
    @module Module


  ApplicationGateway.initialize()
