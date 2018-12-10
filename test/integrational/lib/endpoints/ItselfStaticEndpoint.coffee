

module.exports = (Module)->
  {
    NilT
    FuncG, InterfaceG
    GatewayInterface
    EndpointInterface
    Endpoint
    CrudEndpointMixin
  } = Module::

  class ItselfStaticEndpoint extends Endpoint
    @inheritProtected()
    @include CrudEndpointMixin
    @module Module

    @public init: FuncG(InterfaceG(gateway: GatewayInterface), NilT),
      default: (args...)->
        @super args...
        @summary 'Documentation'
          .description 'Static codo documentation'
        return


    @initialize()
