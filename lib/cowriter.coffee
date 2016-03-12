CowriterView = require './cowriter-view'
Diff = require 'diff'
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

    # Current document's title
    @title= 'demo'

    # Save new diff
    @Acticles = AV.Object.extend 'Acticles'

    # Query for new diff
    @query = new AV.Query 'Acticles'

    # Base time for syncing
    @syncTime = new Date()

    @editor = atom.workspace.getActiveTextEditor()
    @oldText = ''
    @newText = ''

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cowriter:toggle': => @toggle()

    # Server: Sends changes when change stops
    @subscriptions.add @editor.onDidStopChanging => @stop()

    # May suffered from unsafe-eval of CSP
    # Cilent: Refresh view every 3 seconds
    @interval = setInterval ( => @getDiff() ), 3000

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cowriterView.destroy()

  serialize: ->
    cowriterViewState: @cowriterView.serialize()

  stop: ->
    @newText = @editor.getText()
    diff = Diff.diffChars(@oldText, @newText)
    @oldText = @newText
    @saveCompressedDiff(@compressDiff(diff))
    console.log(diff)
    @cowriterView.setContent(diff.toString())

  compressDiff: (diff) ->
    # Better truncate removed value as well
    compress = (item) ->
      if item['added'] == undefined && item['removed'] == undefined
        item['value'] = null
      return item
    # Truncate the values don't change
    compress item for item in diff

  saveCompressedDiff: (compressedDiff) ->
    acticle = new @Acticles()
    acticle.save {
      'diff': compressedDiff,
      'document': @document
      }, {
      success: (object) ->
        @syncTime = object.updatedAt
        console.log 'syncTime ' + object.updatedAt
      }

  getDiff: ->
    # Only gets the newest changes
    @query.greaterThan 'updatedAt', @syncTime
    @query.equalTo 'document', @title
    @query.find().then (response) ->
      console.log 'success'
      console.log response

  # applyDiff: (diff) ->


  toggle: ->
    if @modalPanel.isVisible()
      # Clear the interval
      clearInterval @interval
      console.log 'Cowriter closed!'
      @modalPanel.hide()
    else
      @modalPanel.show()
      console.log 'Cowriter opened!'
