# _         = require 'lodash'
# fs        = require 'fs'
RC = require 'RC'


class ArangoExtension extends RC::Module
  @inheritProtected()
  # Utils: {}
  # Scripts: {}
  require('./Constants') ArangoExtension


  require('./interfaces/iterator/ArangoCursorInterface') ArangoExtension

  require('./iterator/ArangoCursor') ArangoExtension

  require('./mixins/AISCRouteMixin') ArangoExtension
  require('./mixins/ArangoCollectionMixin') ArangoExtension
  require('./mixins/ArangoSwitchMixin') ArangoExtension


module.exports = ArangoExtension.initialize()
