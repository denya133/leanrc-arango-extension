

module.exports = (Module)->
  {
    FuncG, StructG, UnionG, EnumG, ListG
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

    @action @async list: FuncG([], StructG {
      meta: StructG pagination: StructG {
        limit: UnionG Number, EnumG ['not defined']
        offset: UnionG Number, EnumG ['not defined']
      }
      items: ListG Object
    }),
      default: ->
        sections = yield @getPermitablesFor 'sharing'
        yield return sections


    @initialize()
