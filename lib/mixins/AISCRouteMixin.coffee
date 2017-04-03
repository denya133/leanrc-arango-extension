# AISC - Arango Inter-Service Communication
# этот миксин нужен, чтобы объявить медиатор, который будет предоставлять доступ к апи для клиентов, которые так же как этот запущены на платформе ArangoDB как микросервисы.
# для того чтобы обратиться из клиентского модуля к этому сервису будет использоваться обращение через module.context.dependencies....
# а с этой стороны модуля за взаимодействие будет отвечать этот медиатор
# по сути он просто будет врапить хендлеры (экшены) которые объявляются в Stock классах, или делать что-то эквивалентное.

RC            = require 'RC'
LeanRC        = require 'LeanRC'


module.exports = (ArangoExtension)->
  class ArangoExtension::AISCRouteMixin extends RC::Mixin
    @inheritProtected()

    @Module: ArangoExtension


  return ArangoExtension::AISCRouteMixin.initialize()
