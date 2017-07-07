# AISC - Arango Inter-Service Communication
# этот миксин нужен, чтобы объявить медиатор, который будет предоставлять доступ к апи для клиентов, которые так же как этот запущены на платформе ArangoDB как микросервисы.
# для того чтобы обратиться из клиентского модуля к этому сервису будет использоваться обращение через module.context.dependencies....
# а с этой стороны модуля за взаимодействие будет отвечать этот медиатор
# по сути он просто будет врапить хендлеры (экшены) которые объявляются в Stock классах, или делать что-то эквивалентное.

LeanRC        = require 'LeanRC'

# TODO: надо переадаптировать этот миксин в ...CollectionMixin чтобы за данными обращаться из коллекции сквозь прослойки аранги напрямую к работающему сервису.

# TODO: !!!! Поначалу было опасно начинать этот миксин, т.к. можно было закопаться с вычислением локов (т.к. транзакция открывалась в switch классе), но после того, как открытие транзакции было перенесено в ресурс. можно за это не переживать. Т.е. можно при появлении свободного времени взяться за реализацию этого миксина

###
TODO: в старом коде в Module классе был код
```
    @initializeModules: ->
      if @context.manifest.dependencies?
        for own dependencyName, dependencyDefinition of @context.manifest.dependencies
          do ({name, version, required}=dependencyDefinition)=>
            required ?= no
            if required
              vModule = @context.dependencies[dependencyName]
              unless semver.satisfies vModule.context.manifest.version, version
                throw new Error "
                  Dependent module #{vModule.name} not compatible.
                  This module required version #{version} but #{vModule.name} version is #{vModule.context.manifest.version}.
                "
                return
            return
      return
```
###

module.exports = (Module)->
  Module.defineMixin (BaseClass) ->
    class AISCRouteMixin extends BaseClass
      @inheritProtected()


    AISCRouteMixin.initializeMixin()
