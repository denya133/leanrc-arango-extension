

module.exports = (Module) ->
  {
    LOG_MSG
    NilT
    FuncG
    NotificationInterface
    Pipes
    LogFilterMessage
  } = Module::
  {
    PipeMessageInterface
    JunctionMediator
    Junction
    PipeAwareModule
    TeeMerge
    Filter
    PipeListener
  } = Pipes::
  {
    STDIN
  } = PipeAwareModule
  {
    INPUT
  } = Junction
  {
    ACCEPT_INPUT_PIPE
  } = JunctionMediator
  {
    LOG_FILTER_NAME
    filterLogByLevel
  } = LogFilterMessage

  class LoggerJunctionMediator extends JunctionMediator
    @inheritProtected()
    @module Module

    ipoJunction = Symbol.for '~junction'

    @public @static NAME: String,
      get: -> "#{@Module.name}JunctionMediator"

    @public listNotificationInterests: FuncG([], Array),
      default: (args...)->
        @super args...

    @public handleNotification: FuncG(NotificationInterface, NilT),
      default: (aoNotification)->
        switch aoNotification.getName()
          when ACCEPT_INPUT_PIPE
            name = aoNotification.getType()
            if name is STDIN
              pipe = aoNotification.getBody()
              tee = @[ipoJunction].retrievePipe STDIN
              tee.connectInput pipe
            else
              @super aoNotification
          else
            @super aoNotification
        return

    @public handlePipeMessage: FuncG(PipeMessageInterface, NilT),
      default: (aoMessage)->
        @sendNotification LOG_MSG, aoMessage
        return

    @public onRegister: Function,
      default: ->
        teeMerge = TeeMerge.new()
        filter = Filter.new LOG_FILTER_NAME, null, filterLogByLevel
        filter.connect PipeListener.new @, @handlePipeMessage
        teeMerge.connect filter
        @[ipoJunction].registerPipe STDIN, INPUT, teeMerge
        return

    @public init: Function,
      default: ->
        @super LoggerJunctionMediator.NAME, Junction.new()


    @initialize()
