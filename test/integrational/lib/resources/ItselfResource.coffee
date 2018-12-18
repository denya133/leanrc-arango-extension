

module.exports = (Module)->
  {
    APPLICATION_ROUTER

    Resource
    CheckSessionsMixin
  } = Module::

  class ItselfResource extends Resource
    @inheritProtected()
    @include CheckSessionsMixin
    @module Module

    @public entityName: String,
      default: 'info'

    # TODO: надо перепроверить эти хуки
    @chains [
      'info', 'static'
    ]

    @initialHook 'checkSchemaVersion'
    @initialHook 'checkSession', only: [
      'static'
    ]
    @initialHook 'adminOnly', only: ['static']

    @action @async static: Function,
      default: ->
        [..., filename] = @context.url.split 'static/'
        filePath = @Module.context().fileName "public/#{filename}"
        @context.status = 200
        @context.respond = no
        mimeTypes = require 'mime-types'
        @context.type = mimeTypes.lookup(filename)
        unless @context.fresh
          @context.res.sendFile filePath
        yield return

    @action @async info: Function,
      default: ->
        {
          name
          description
          license
          version
          keywords
        } = @configs
        yield return {
          name
          description
          license
          version
          keywords
        }


    @initialize()
