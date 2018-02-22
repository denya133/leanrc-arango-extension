

module.exports = (Module)->
  {
    Endpoint
    CrudEndpointMixin
  } = Module::

  class ItselfStaticEndpoint extends Endpoint
    @inheritProtected()
    @include CrudEndpointMixin
    @module Module

    @public init: Function,
      default: (args...)->
        @super args...
        @summary 'Documentation'
          .description 'Static codo documentation'


  ItselfStaticEndpoint.initialize()
