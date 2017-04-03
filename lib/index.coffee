# _         = require 'lodash'
# fs        = require 'fs'
RC = require 'RC'


class ArangoExtension extends RC::Module
  @inheritProtected()
  # Utils: {}
  # Scripts: {}
  Constants:    require('./Constants') ArangoExtension


  require('./interfaces/mixins/ArangoCursorInterface') ArangoExtension

  require('./mixins/AISCRouteMixin') ArangoExtension
  require('./mixins/ArangoCollectionMixin') ArangoExtension
  require('./mixins/ArangoCursor') ArangoExtension
  require('./mixins/ArangoRouteMixin') ArangoExtension


module.exports = ArangoExtension.initialize()
