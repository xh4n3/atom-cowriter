CowriterView = require './cowriter-view'
diff = require 'diff'
AV = require 'avoscloud-sdk'
{CompositeDisposable} = require 'atom'
AV.initialize 'APPID','APPKEY'

module.exports = Cowriter =
  cowriterView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @cowriterView = new CowriterView(state.cowriterViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @cowriterView.getElement(), visible: false)

    @textBuffer = ''
    Acticles = AV.Object.extend 'Acticles'
    @acticle = new Acticles()
    @editor = atom.workspace.getActiveTextEditor()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cowriter:toggle': => @toggle()
    @subscriptions.add @editor.onDidStopChanging => @stop()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cowriterView.destroy()

  serialize: ->
    cowriterViewState: @cowriterView.serialize()

  stop: ->
    textBuffer = @editor.getText()
    @save(textBuffer)
    @cowriterView.setContent(@textBuffer)

  save: (text) ->
    @acticle.save { 'demo': text }, { success: (object) -> alert 'LeanCloud works!' }

  toggle: ->
    console.log 'Cowriter was toggled!'
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
