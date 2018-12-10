

module.exports = (Module)->
  {
    JoiT
    ArrayTransform
    Utils: { joi }
  } = Module::

  class TimestampsArrayTransform extends ArrayTransform
    @inheritProtected()
    @module Module

    @public @static schema: JoiT,
      get: -> joi.array().items [joi.number(), joi.any().strip()]


    @initialize()
