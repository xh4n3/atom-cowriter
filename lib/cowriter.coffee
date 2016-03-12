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
    @editor = atom.workspace.getActiveTextEditor()
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cowriter:toggle': => @toggle()
    # Current document's title
    @title = 'demo'
    # mode: server, client
    @mode = 'server'
    # @mode = 'client'
    # Initialization for Sever
    if @mode == 'server'
      # Save new diff
      @Acticles = AV.Object.extend 'Acticles'
      # Server: Sends changes when change stops
      @subscriptions.add @editor.onDidStopChanging => @stop()
      @oldText = ''
      @newText = ''
      console.log 'Server starts.'
    # Initialization for Client
    if @mode == 'client'
      # Query for new diff
      @query = new AV.Query 'Acticles'
      # Base time for syncing
      @syncTime = new Date()
      #### DEBUG ONLY
      # @syncTime = new Date '2016-03-12 19:09:20'
      ####
      # Client: Refresh view every 3 seconds
      @interval = setInterval ( => @getDiff() ), 3000
      console.log 'Client starts.'

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cowriterView.destroy()

  serialize: ->
    cowriterViewState: @cowriterView.serialize()

  stop: ->
    if (@mode != 'server')
      return
    @newText = @editor.getText()
    diff = Diff.diffChars(@oldText, @newText)
    @oldText = @newText
    @saveCompressedDiff(@compressDiff(diff))
    console.log(diff)
    @cowriterView.setContent(diff.toString())

  compressDiff: (diff) ->
    if (@mode != 'server')
      return
    # Better truncate removed value as well
    compress = (item) ->
      if item['added'] == undefined && item['removed'] == undefined
        item['value'] = null
      return item
    # Truncate the values don't change
    compress item for item in diff

  saveCompressedDiff: (compressedDiff) ->
    if (@mode != 'server')
      return
    acticle = new @Acticles()
    acticle.save {
      'diff': compressedDiff,
      'document': @title
      }, {
      success: (object) ->
        @syncTime = object.updatedAt
        console.log 'syncTime ' + object.updatedAt
      }

  getDiff: ->
    if (@mode != 'client')
      return
    # Only gets the newest changes
    @query.greaterThan 'updatedAt', @syncTime
    @query.equalTo 'document', @title
    @query.addAscending 'updatedAt'
    @query.find().then (response) =>
      console.log @query
      console.log 'success'
      console.log response
      @applyDiff res['attributes']['diff'] for res in response

  applyDiff: (diff) ->
    console.log diff
    x = @editor.getText()
    str = ""
    position = 0
    process = (item) ->
      if item['added'] == true
        # added
        str += item['value']
      else if item['removed'] == true
        # removed
        position += item['count']
      else
        # remains unchanged
        str += x.slice position, position + item['count']
        position += item['count']
    # updates syncTime with lastest update
    @syncTime = diff['updatedAt']
    # apply diffs to current text one by one
    process item for item in diff
    @editor.setText str

  toggle: ->
    if @modalPanel.isVisible()
      if @mode == 'client'
        # Clear the interval
        clearInterval @interval
      console.log 'Cowriter closed!'
      @modalPanel.hide()
    else
      @modalPanel.show()
      console.log 'Cowriter opened!'
