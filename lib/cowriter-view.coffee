module.exports =
class CowriterView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('cowriter')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The Cowriter package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

    content = document.createElement('span')
    content.textContent = "text here!"
    @element.appendChild(content)

  setContent: (data) ->
    @element.children[1].textContent = data

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
