

module.exports = (Module)->
  {
    Endpoint
    CrudEndpointMixin
    Utils: { joi, statuses }
  } = Module::

  UNAUTHORIZED      = statuses 'unauthorized'
  UPGRADE_REQUIRED  = statuses 'upgrade required'

  class SharingLoggedReportsRemoveEndpoint extends Endpoint
    @inheritProtected()
    @include CrudEndpointMixin
    @module Module

    @public clientSchemaForRemove: Object,
      get: ->
        joi.object
          reason: joi.string().required()

    @public init: Function,
      default: (args...)->
        @super args...
        @pathParam   'v', @versionSchema, "
          The version of api endpoint in format `vx.x`
        "
        .header 'Authorization', joi.string().optional(), "
          Authorization header for internal services.
        "
        .body @clientSchemaForRemove.required(), "
          The reason for remove.
        "
        .error UNAUTHORIZED
        .error UPGRADE_REQUIRED
        .summary "
          Remove an #{@itemEntityName}
        "
        .description "
          An #{@itemEntityName} will been RemovedReport type
        "


  SharingLoggedReportsRemoveEndpoint.initialize()
