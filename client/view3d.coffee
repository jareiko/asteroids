
Meteor.subscribe "region", 0, 0

Template.view3d.created = ->
  @client = new Client

  # Add rendering component.
  Bots.addComponent MSL.makeBotRenderer @client.scene

  lastTime = null
  advance = (time) =>
    if lastTime
      delta = Math.min 0.1, (time - lastTime) * 0.001
      myES.advance delta
      @client.advance delta
      @client.render()
    lastTime = time
    requestAdvance()

  do requestAdvance = =>
    @requestID = requestAnimationFrame advance

Template.view3d.rendered = ->
  # TODO: Prevent this from being necessary on each render.
  view3d = @find('#view3d')
  canvas = @client.renderer.domElement
  view3d.appendChild canvas

  do layout = =>
    @client.setSize view3d.clientWidth, view3d.clientHeight
  # The window is the only element that reliably issues resize events.
  window.addEventListener 'resize', layout

  view3d.addEventListener 'click', (event) => @client.onClick event
  view3d.addEventListener 'wheel', (event) => @client.onWheel event

Template.view3d.destroyed = ->
  cancelAnimationFrame @requestID if @requestID
