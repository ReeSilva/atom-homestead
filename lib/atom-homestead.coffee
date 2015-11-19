AtomHomesteadView = require './atom-homestead-view'
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'

module.exports = AtomHomestead =
  atomHomesteadView: null
  modalPanel: null
  subscriptions: null
  path: null

  config:
    bin:
      title: 'Homestead exec'
      type: 'string'
      'default': 'homestead'

  activate: (state) ->
    @atomHomesteadView = new AtomHomesteadView(state.atomHomesteadViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomHomesteadView.getElement(), visible: false)
    @path = atom.project.getPaths()[0]

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
    @exec(['init'], cwd: @path)
    .then (data) ->
      if data.indexOf("InvalidArgumentException") > -1
        atom.notifications.addWarning(message = 'Homestead already created', {detail:"#{data}"})
      else
        atom.notifications.addSuccess(message = 'Homestead created', {detail:"#{data}"})

  up: ->
    atom.notifications.addInfo(message = 'Creating machine...', {detail:'Homestead is powering the machine.'})
    atom.notifications.addSuccess(message = 'Created machine', {detail:'Your machine is now created ${data}.'})

  suspend: ->
    atom.notifications.addInfo(message = 'Suspending machine...', {detail:'Homestead is putting your machine to sleep...'})
    atom.notifications.addSuccess(message = 'Machine suspended', {detail:'Your homestead is now sleeping.'})

  resume: ->
    atom.notifications.addInfo(message = 'Resuming machine...', {detail:'Homestead is waking your machine...'})
    atom.notifications.addSuccess(message = 'Machine resumed', {detail:'Your machine is now wakeful.'})

  halt: ->
    atom.notifications.addInfo(message = 'Turning off the machine...', {detail:'Homestead is turning off your machine...'})
    @exec(['halt'], cwd: @path)
    .then (data) ->
      if data.indexOf("shutdown") > -1
        atom.notifications.addSuccess(message = 'Machine offline', {detail:'Your machine is now offline.'})
      else
        atom.notifications.addInfo(message= 'Machine already offline', {detail: 'Your machine is already offline, nothing to do here :)'})

  status: ->
    atom.notifications.addInfo(message = "Checking the status of your machine...", {detail: "Wait a second..."})
    @exec(['status'], cwd: @path)
    .then (data) ->
      if data.indexOf('poweroff') > -1
        atom.notifications.addWarning(message = 'Machine offline', {detail:"#{data}"})
      else if data.indexOf('running') > -1
        atom.notifications.addSuccess(message = 'Machine online', {detail:"#{data}"})
      else
        atom.notifications.addInfo(message = 'Machine suspended', {detail:"#{data}"})

  destroy: ->
    atom.notifications.addWarning(message = 'Destroying machine...', {detail:'Homestead is destroying your machine...'})
    atom.notifications.addSuccess(message = 'Machine destroyed', {detail:'Your machine is now destroyed.'})

  exec: (args, options={}) ->
    new Promise (resolve, reject) ->
      output = ''
      try
        new BufferedProcess
          command: atom.config.get "atom-homestead.bin"
          args: args
          options: options
          stdout: (data) -> output += data.toString()
          stderr: (data) -> output += data.toString()
          exit: (code) -> resolve output
      catch
        atom.notifications.addError(message = 'Homestead not found', {detail: 'Homestead command not found. Make sure that Homestead path is correctly defined.'})
        reject "Couldn't find Homestead"
