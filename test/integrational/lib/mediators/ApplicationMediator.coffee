

module.exports = (Module) ->
  {
    Mediator
    ApplicationMediatorMixin
  } = Module::

  class ApplicationMediator extends Mediator
    @inheritProtected()
    @include ApplicationMediatorMixin
    @module Module


    @initialize()
