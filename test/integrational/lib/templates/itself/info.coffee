

module.exports = (Module)->
  Module.defineTemplate __filename, (resource, action, aoData)->
    info: aoData
