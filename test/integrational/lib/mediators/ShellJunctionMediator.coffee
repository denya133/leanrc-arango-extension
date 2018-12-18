

# это медиатор, для ораганизации пайпов между Core и сторонними ядрами-клиентами чтобы обмениваться данными со сторонними (отдельно запущенными) микросервисами.

module.exports = (Module) ->
  {
    NilT
    FuncG
    NotificationInterface
    LoggingJunctionMixin
    LogMessage
    Pipes
    ApplicationFacade
    Application
  } = Module::
  {
    CONNECT_MODULE_TO_SHELL
    CONNECT_SHELL_TO_LOGGER
  } = Application::
  {
    PipeMessageInterface
    JunctionMediator
    PipeAwareModule
    Pipe
    TeeMerge
    TeeSplit
    Junction
  } = Pipes::
  {
    INPUT
    OUTPUT
  } = Junction
  {
    STDIN
    STDOUT
    STDLOG
    STDSHELL
  } = PipeAwareModule
  {
    SEND_TO_LOG
    LEVELS
    DEBUG
    INFO
  } = LogMessage

  class ShellJunctionMediator extends JunctionMediator
    @inheritProtected()
    @include LoggingJunctionMixin
    @module Module

    ipoJunction = Symbol.for '~junction'

    @public @static NAME: String,
      get: -> "#{@Module.name}JunctionMediator"

    @public listNotificationInterests: FuncG([], Array),
      default: (args...)->
        interests = @super args...
        interests.push CONNECT_MODULE_TO_SHELL
        interests

    @public handleNotification: FuncG(NotificationInterface, NilT),
      default: (aoNotification)->
        switch aoNotification.getName()
          when CONNECT_MODULE_TO_SHELL
            @sendNotification(LogMessage.SEND_TO_LOG,"Connecting new module instance to Shell.",LogMessage.LEVELS[LogMessage.DEBUG])

            # Connect a module's STDSHELL to the shell's STDIN
            module = aoNotification.getBody()
            moduleToShell = Pipe.new()
            module.acceptOutputPipe STDSHELL, moduleToShell
            shellIn = @[ipoJunction].retrievePipe STDIN
            shellIn.connectInput moduleToShell

            # Connect the shell's STDOUT to the module's STDIN
            shellToModule = Pipe.new()
            module.acceptInputPipe STDIN, shellToModule
            shellOut = @[ipoJunction].retrievePipe STDOUT
            shellOut.connect shellToModule
            break
          else
            @super aoNotification

    @public handlePipeMessage: FuncG(PipeMessageInterface, NilT),
      default: (aoMessage)->
        return

    @public onRegister: Function,
      default: ->
        # The STDOUT pipe from the shell to all modules
        @[ipoJunction].registerPipe STDOUT,  OUTPUT, TeeSplit.new()

        # The STDIN pipe to the shell from all modules
        @[ipoJunction].registerPipe STDIN,  INPUT, TeeMerge.new()
        @[ipoJunction].addPipeListener STDIN, @, @handlePipeMessage

        # The STDLOG pipe from the shell to the logger
        @[ipoJunction].registerPipe STDLOG, OUTPUT, Pipe.new()
        @sendNotification CONNECT_SHELL_TO_LOGGER, @[ipoJunction]

    @public init: Function,
      default: ->
        @super ShellJunctionMediator.NAME, Junction.new()


    @initialize()
