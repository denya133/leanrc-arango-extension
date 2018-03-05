

module.exports = (Module)->
  {
    Endpoint
    CrudEndpointMixin
    Utils: { joi }
  } = Module::

  class ItselfInfoEndpoint extends Endpoint
    @inheritProtected()
    @include CrudEndpointMixin
    @module Module

    @public init: Function,
      default: (args...)->
        @super args...
        @response joi.object(
          info: joi.object(
            name: joi.string()
            description: joi.string()
            license: joi.string()
            version: joi.string()
            keywords: joi.array().items joi.string()
          )
        ), 'Information'
          .summary 'Service info'
          .description 'Info about this service'


  ItselfInfoEndpoint.initialize()
