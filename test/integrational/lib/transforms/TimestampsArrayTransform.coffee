

module.exports = (Module)->
  {
    CoreObject
    Utils: { _ }
  } = Module::

  class TimestampsArrayTransform extends CoreObject
    @inheritProtected()
    # @implements Module::TransformInterface
    @module Module

    @public @static normalize: Function,
      default: (serialized)->
        if _.isNil(serialized) then [] else serialized.map (item)->
          Number item

    @public @static serialize: Function,
      default: (deserialized)->
        if _.isNil(deserialized) then [] else deserialized.map (item)->
          Number item

    @public @static @async restoreObject: Function,
      default: ->
        throw new Error "restoreObject method not supported for #{@name}"
        yield return

    @public @static @async replicateObject: Function,
      default: ->
        throw new Error "replicateObject method not supported for #{@name}"
        yield return


  TimestampsArrayTransform.initialize()
