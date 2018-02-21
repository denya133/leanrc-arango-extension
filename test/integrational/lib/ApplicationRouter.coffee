

module.exports = (Module)->
  {
    Router
  } = Module::

  class ApplicationRouter extends Router
    @inheritProtected()
    @module Module

    @map ->
      @get '/static/*',     to: 'itself#static',  recordName: null
      @get '/info',         to: 'itself#info',    recordName: null
      @namespace 'version', module: '', prefix: ':v', ->
        @namespace 'modeling',
          # module: ''
          prefix: 'modeling'
          templates: 'modeling'
          tag: 'modeling'
        , ->
          @resource 'clients', ->
            @post 'query', at: 'collection'
        @namespace 'sharing',
          # module: 'sharing'
          prefix: 'sharing/:space'
          templates: 'modeling'
          tag: 'sharing'
        , ->
          @resource 'permitables', only: ['list'], above:
            recordName: null
          @resource 'logged_reports',   only: ['list', 'detail'], above:
            permitable: ['list', 'detail', 'remove']
            accessible: []
            chargeable: []
          , ->
            @put 'remove', at: 'member'


  ApplicationRouter.initialize()
