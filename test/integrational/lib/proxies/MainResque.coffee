# создаем его в Core для того чтобы можно было ставить задачи на обработку


module.exports = (Module)->
  {
    Resque
    ArangoResqueMixin
  } = Module::

  class MainResque extends Resque
    @inheritProtected()
    @include ArangoResqueMixin
    @module Module


  MainResque.initialize()
