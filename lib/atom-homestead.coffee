AtomHomesteadView = require './atom-homestead-view'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'

module.exports = AtomHomestead =
  atomHomesteadView: null
  modalPanel: null
  subscriptions: null

  config:
    bin:
      title: 'Homestead exec'
      type: 'string'
      'default': 'homestead'

  activate: (state) ->
    @atomHomesteadView = new AtomHomesteadView(state.atomHomesteadViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomHomesteadView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:init':    => @init()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:up':      => @up()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:suspend': => @suspend()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:resume':  => @resume()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:halt':    => @halt()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:status':  => @status()
    @subscriptions.add atom.commands.add 'atom-workspace', 'homestead:destroy': => @destroy()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomHomesteadView.destroy()

  serialize: ->
    atomHomesteadViewState: @atomHomesteadView.serialize()

  init: ->
    @exec(['init'])
    .then (data) ->
      atom.notifications.addSuccess(message = '.init file created', {detail:'${data}'})

  up: ->
    @exec(['up'])
    console.log "Começou"
    # atom.notifications.addInfo(message = 'Creating machine...', {detail:'Homestead is powering the machine.'})
    .then (data) ->
      console.log data
      # atom.notifications.addSuccess(message = 'Created machine', {detail:'Your machine is now created ${data}.'})

  suspend: ->
    atom.notifications.addInfo(message = 'Suspending machine...', {detail:'Homestead is putting your machine to sleep...'})
    atom.notifications.addSuccess(message = 'Machine suspended', {detail:'Your homestead is now sleeping.'})

  resume: ->
    atom.notifications.addInfo(message = 'Resuming machine...', {detail:'Homestead is waking your machine...'})
    atom.notifications.addSuccess(message = 'Machine resumed', {detail:'Your machine is now wakeful.'})

  halt: ->
    atom.notifications.addInfo(message = 'Turning off the machine...', {detail:'Homestead is turning off your machine...'})
    atom.notifications.addSuccess(message = 'Machine offline', {detail:'Your machine is now offline.'})

  status: ->
    atom.notifications.addInfo(message = 'Machine status', {detail:'return of the command homestead status'})

  destroy: ->
    atom.notifications.addWarning(message = 'Destroying machine...', {detail:'Homestead is destroying your machine...'})
    atom.notifications.addSuccess(message = 'Machine destroyed', {detail:'Your machine is now destroyed.'})

  exec: (args, options={}) ->
    new Promise (resolve, reject) ->
      output = ''
      try
        new BufferedProcess
          command: 'homestead'
          args: args
          options: options
          stdout: (data) -> output += data.toString()
          stderr: (data) -> reject data.toString()
          exit: (code) -> resolve output
      catch
        notifier.addError 'Git Plus is unable to locate the git command. Please ensure process.env.PATH can access git.'
        reject "Couldn't find git"
