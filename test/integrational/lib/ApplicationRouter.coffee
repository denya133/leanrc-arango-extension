

module.exports = (Module)->
  {
    Router
  } = Module::

  class ApplicationRouter extends Router
    @inheritProtected()
    @module Module

    @map ->
      @get '/static/*',     to: 'itself#static'
      @get '/info',         to: 'itself#info'
      @namespace 'version', module: '', prefix: ':v', ->
        ###
        @namespace 'modeling',
          module: ''
          prefix: 'modeling'
          templates: 'modeling'
          tag: 'modeling'
        , ->
          @resource 'clients', ->
            @post 'query', at: 'collection'
          @resource 'logged_reports', ->
            @post 'query', at: 'collection'
          @resource 'logged_periods', ->
            @post 'query', at: 'collection'
          @resource 'labels', ->
            @post 'query', at: 'collection'
          @resource 'period_labels', ->
            @post 'query', at: 'collection'
          @resource 'period_uploads', ->
            @post 'query', at: 'collection'
          @resource 'manually_periods', ->
            @post 'query', at: 'collection'
          @resource 'removed_periods', ->
            @post 'query', at: 'collection'
          @resource 'removed_reports', ->
            @post 'query', at: 'collection'
          @resource 'reports', ->
            @post 'query', at: 'collection'
          @resource 'periods', ->
            @post 'query', at: 'collection'

        # @namespace 'guesting',
        #   # module: 'guesting'
        #   prefix: 'guesting'
        #   templates: 'guesting'
        #   tag: 'guesting'
        # , ->

        # @namespace 'globaling',
        #   # module: 'globaling'
        #   prefix: 'globaling'
        #   templates: 'modeling'
        #   tag: 'globaling'
        # , ->

        # @namespace 'personing',
        #   # module: 'personing'
        #   prefix: 'personing'
        #   templates: 'modeling'
        #   tag: 'personing'
        # , ->

        @namespace 'trackering',
          # module: 'trackering'
          prefix: 'trackering'
          templates: 'modeling'
          tag: 'trackering'
        , ->
          @resource 'clients',          only: ['create']
          @resource 'logged_reports',   only: ['create'], above:
            accessible: ['team-work-available']
            chargeable: ['init-rated-period']

        @namespace 'sharing',
          # module: 'sharing'
          prefix: 'sharing/:space'
          templates: 'modeling'
          tag: 'sharing'
        , ->
          @resource 'permitables', only: ['list']
          @resource 'logged_reports',   only: ['list', 'detail'], above:
            permitable: ['list', 'detail', 'remove']
            accessible: []
            chargeable: []
          , ->
            @put 'remove', at: 'member'
          @resource 'logged_periods',   only: ['list', 'detail'], above:
            permitable: ['list', 'detail', 'remove']
            accessible: []
            chargeable: []
          , ->
            @put 'remove', at: 'member'

          @resource 'labels', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'period_labels', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'period_uploads', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'manually_periods', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'removed_periods',  only: ['list', 'detail'], above:
            permitable: ['list', 'detail']
            accessible: []
            chargeable: []
          @resource 'removed_reports',  only: ['list', 'detail'], above:
            permitable: ['list', 'detail']
            accessible: []
            chargeable: []
          @resource 'statistics',       except: ['all'], above:
            permitable: ['aggregate', 'coaggregate', 'lasts']
            accessible: []
            chargeable: []
          , ->
            @post 'aggregate', at: 'collection'
            @post 'coaggregate', at: 'collection'
            @post 'lasts', at: 'collection'
          @resource 'reports',          only: ['list', 'detail'], above:
            permitable: ['list', 'detail']
            accessible: []
            chargeable: []
          @resource 'periods',          only: ['list', 'detail'], above:
            permitable: ['list', 'detail']
            accessible: []
            chargeable: []

        @namespace 'admining',
          # module: 'admining'
          prefix: 'admining/:space'
          templates: 'modeling'
          tag: 'admining'
        , ->
          @resource 'permitables', only: ['list']
          @resource 'accessibles', only: ['list']
          @resource 'chargeables', only: ['list']
          @resource 'clients', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'logged_reports', above:
            permitable: ['all', 'remove']
            accessible: []
            chargeable: []
          , ->
            @put 'remove', at: 'member'
          @resource 'logged_periods', above:
            permitable: ['all', 'remove']
            accessible: []
            chargeable: []
          , ->
            @put 'remove', at: 'member'
          @resource 'labels', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'period_labels', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'period_uploads', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'manually_periods', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'removed_periods', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'removed_reports', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'reports', above:
            permitable: 'all'
            accessible: []
            chargeable: []
          @resource 'periods', above:
            permitable: 'all'
            accessible: []
            chargeable: []
        ###



        # @resource 'clients',            except: ['delete'] # создаются из С++ клента, на чтение и редактирование доступны только админу
        # @namespace 'space', module: '', prefix: ':space', ->
        #   # for C++ client
        #   @resource 'logged_reports',   except: ['update'], -> # создаются из С++
        #     @put 'remove', at: 'member'
        #   @resource 'logged_periods',   except: ['create', 'update', 'delete'], -> # TODO: надо описать, что create не доступен (создаются автоматически на основе репортов из С++ клиента)
        #     @put 'remove', at: 'member'
        #
        #   # for Web client
        #   @resource 'labels'
        #   @resource 'period_labels'
        #   @resource 'period_uploads'
        #   @resource 'manually_periods'
        #   @resource 'removed_periods',  except: ['create']
        #   @resource 'removed_reports',  except: ['create']
        #   @resource 'statistics',       except: ['all'], ->
        #     @post 'aggregate', at: 'collection'
        #     @post 'coaggregate', at: 'collection'
        #     @post 'lasts', at: 'collection'
        #   @resource 'reports',          except: ['create', 'update', 'delete']
        #   @resource 'periods',          except: ['create', 'update', 'delete']
        #


  ApplicationRouter.initialize()
