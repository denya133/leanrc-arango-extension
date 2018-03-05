

module.exports = (Module)->
  {
    Resource
  } = Module::

  Module.defineMixin 'ExtendReportFromClientsMixin', (BaseClass = Resource) ->
    class extends BaseClass
      @inheritProtected()

      @public @async mixFromClients: Function,
        default: (result) ->
          {items} = result
          ClientsCollection = @facade.retrieveProxy 'ClientsCollection'
          clientIds = items.map (item) -> item.clientId
          clients = (yield(yield ClientsCollection.findBy
            '@doc.id': $in: clientIds
          ).toArray()).reduce (prev, client)->
            prev[client.id] = client
            prev
          , {}
          result.items = items.map (item)->
            client = clients[item.clientId]
            item.screens = client.screensCount
            item.cameras = client.camsCount
            item.macAddress = client.macAddress
            item
          yield return result

      @public @async mixFromClient: Function,
        default: (result) ->
          ClientsCollection = @facade.retrieveProxy 'ClientsCollection'
          client = yield ClientsCollection.find result.clientId
          result.screens = client.screensCount
          result.cameras = client.camsCount
          result.macAddress = client.macAddress
          yield return result


      @initializeMixin()
