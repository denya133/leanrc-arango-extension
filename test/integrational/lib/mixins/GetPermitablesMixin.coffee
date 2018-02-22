

module.exports = (Module)->
  {
    APPLICATION_ROUTER

    Resource
    Utils: { _, inflect }
  } = Module::

  Module.defineMixin 'GetPermitablesMixin', (BaseClass = Resource) ->
    class extends BaseClass
      @inheritProtected()

      @public @async getPermitablesFor: Function,
        default: (kind)->
          applicationRouter = @context.switch.facade.retrieveProxy APPLICATION_ROUTER
          Mapping = {}
          do -> applicationRouter.routes
          applicationRouter.resources.forEach (aoResource)=>
            if new RegExp("^#{kind}").test aoResource.name
              if aoResource.above?.permitable?
                permitables = aoResource.above.permitable
                if _.isString permitables
                  permitables = [permitables]
              if permitables? and permitables.length > 0
                resourceName = inflect.camelize inflect.underscore "#{aoResource.name.replace /[/]/g, '_'}Resource"
                resourceKey = "#{@Module.name}::#{resourceName}"
                Mapping[resourceKey] ?= []
                actions = []
                permitables.forEach (permitable)->
                  if permitable is 'all'
                    actions = actions.concat ['list', 'detail', 'create', 'update', 'delete']
                  else
                    actions.push permitable
                actions.forEach (action)->
                  unless _.includes Mapping[resourceKey], action
                    Mapping[resourceKey].push action
          allSections = Object.keys Mapping
          sections = []
          sections.push
            id: 'moderator'
            actions: allSections
          sections = sections.concat allSections.map (section)=>
            id: section
            actions: Mapping[section]

          yield return sections


      @initializeMixin()
