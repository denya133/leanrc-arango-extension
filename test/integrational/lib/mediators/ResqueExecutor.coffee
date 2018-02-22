

module.exports = (Module)->
  {
    Mediator
    ArangoExecutorMixin
  } = Module::

  class ResqueExecutor extends Mediator
    @inheritProtected()
    @include ArangoExecutorMixin
    @module Module


  ResqueExecutor.initialize()
