
RC = require 'RC'

module.exports = (ArangoExtension)->
  class ArangoExtension::ArangoCursorInterface extends RC::Interface
    @inheritProtected()
    @include LeanRC::CursorInterface

    @Module: ArangoExtension

    @public setCursor: Function,
      args: [RC::Constants.ANY]
      return: ArangoCursorInterface

    @public getExtra: Function,
      args: []
      return: RC::Constants.ANY

    @public setBatchSize: Function,
      args: [Number]
      return: RC::Constants.NILL

    @public getBatchSize: Function,
      args: []
      return: RC::Constants.ANY

    @public dispose: Function,
      args: []
      return: RC::Constants.NILL


  return ArangoExtension::ArangoCursorInterface.initialize()
