

module.exports = (Module)->
  {
    Resource
    CheckSessionsMixin
    GetPermitablesMixin
  } = Module::

  class SharingPermitablesResource extends Resource
    @inheritProtected()
    @include CheckSessionsMixin
    @include GetPermitablesMixin
    @module Module

    @public entityName: String,
      default: 'permitable'

    @public keyName: String,
      get: -> 'sharing_permitable'

    # TODO: надо перепроверить эти хуки
    @chains ['list']

    @initialHook 'checkSchemaVersion'
    @initialHook 'checkApiVersion'
    @initialHook 'checkSession'

    @action @async list: Function,
      default: ->
        sections = yield @getPermitablesFor 'sharing'
        yield return sections


  SharingPermitablesResource.initialize()
