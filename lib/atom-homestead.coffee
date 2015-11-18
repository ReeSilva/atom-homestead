AtomHomesteadView = require './atom-homestead-view'
{execFile} = require('child_process')
{CompositeDisposable} = require 'atom'

module.exports = AtomHomestead =
  atomHomesteadView: null
  modalPanel: null
  subscriptions: null

  config:
    bin:
      title: 'Homestead exec'
      type: 'string'
      'default': '~/.composer/vendor/bin'

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
    atom.notifications.addSuccess(message = '.init file created', {detail:'File path: <path_do_arquivo>'})

  up: ->
    atom.notifications.addInfo(message = 'Creating machine...', {detail:'Homestead is powering the machine.'})
    atom.notifications.addSuccess(message = 'Created machine', {detail:'Your machine is now created.'})

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

  exec: (command) ->
    bin = atom.config.get('atom-homestead.bin')
    cwd = atom.project.getPaths()[0]

    args = [command]

    for name of params
      args.push(`--${name} ${params[name]}`)

    return new Promise((resolve, reject) => {
      execFile(bin, args, {cwd}, (err, stdout, stderr) => {
        if (err) {
          err.stdout = stdout;
          err.stderr = stderr;
          return reject(err);
        }

        resolve({stdout, stderr});
      });
    }).then(({stdout}) => {
      atom.notifications.addInfo(`Vagrant ${command}`, {
        detail: stdout
      });
    }).catch((e) => {
        atom.notifications.addError(`Vagrant ${command}`, {
        detail: e.stderr
        });
      });
