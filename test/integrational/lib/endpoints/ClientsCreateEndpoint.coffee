

module.exports = (Module)->
  {
    Endpoint
    CrudEndpointMixin
    Utils: { joi, statuses }
  } = Module::

  HTTP_CONFLICT     = statuses 'conflict'
  UNAUTHORIZED      = statuses 'unauthorized'
  UPGRADE_REQUIRED  = statuses 'upgrade required'

  class ClientsCreateEndpoint extends Endpoint
    @inheritProtected()
    @include CrudEndpointMixin
    @module Module

    @public init: Function,
      default: (args...)->
        @super args...
        @pathParam   'v', @versionSchema, "
          The version of api endpoint in format `vx.x`
        "
        .header 'Authorization', joi.string().required(), "
          Authorization header for internal services.
        "
        .body @itemSchema.required(), "
          The #{@itemEntityName} to create.
        "
        .error HTTP_CONFLICT, "
          The #{@itemEntityName} already
          exists.
        "
        .error UNAUTHORIZED
        .error UPGRADE_REQUIRED
        .summary "
          Create a new #{@itemEntityName}
        "
        .description "
          Creates a new #{@itemEntityName}
          from the request body and
          returns the saved document.
        "


  ClientsCreateEndpoint.initialize()
