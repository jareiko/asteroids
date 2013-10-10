
projector = new THREE.Projector

Vec3 = THREE.Vector3

intersectZPlane = (ray, z) ->
  return null if Math.abs(ray.direction.z) < 1e-10
  lambda = (z - ray.origin.z) / ray.direction.z
  return null if lambda < ray.near
  isect = ray.direction.clone()
  isect.multiplyScalar(lambda).add ray.origin
  isect.z = z  # Make sure no arithmetic error creeps in.
  pos: isect
  distance: lambda

Meteor.startup ->
  Deps.autorun ->
    selected = Session.get 'selected'
    if not selected or not BotDocs.findOne selected
      bot = BotDocs.findOne "owner": Meteor.userId()
      Session.set 'selected', bot?._id

class @Client
  constructor: ->
    @createRenderer()

    @scene = new THREE.Scene

    @camera = new THREE.PerspectiveCamera 75, 1, 0.1, 10000000
    @camera.idealFov = 75
    @camera.degreesPerPixel = 1
    @camera.up.set 0, 0, 1
    @camera.position.set 0, 0, 8
    @camera.rotation.eulerOrder = 'ZYX'
    @camera.rotation.set 0, 0, 0
    # @scene.add @camera  # Only necessary if stuff should be attached to camera.

    # do =>
    #   geom = new THREE.PlaneGeometry 20, 20, 1, 1
    #   mat = new THREE.MeshBasicMaterial
    #   # mat.color = new THREE.Color 0xffffff
    #   mat.map = THREE.ImageUtils.loadTexture('/textures/ground/ground1.jpg')
    #   mat.map.wrapS = THREE.RepeatWrapping
    #   mat.map.wrapT = THREE.RepeatWrapping
    #   mat.map.repeat.set 20, 20
    #   mat.depthTest = no
    #   ground = new THREE.Mesh geom, mat
    #   # ground.position.z = 0
    #   ground.renderDepth = 0
    #   @scene.add ground

    do =>
      geom = new THREE.PlaneGeometry 1, 1, 1, 1
      mat = new THREE.MeshBasicMaterial
      mat.map = THREE.ImageUtils.loadTexture('/asteroids/4660-nereus.jpg')
      mat.depthTest = no
      # mat.transparent = yes
      # mat.opacity = 0.5
      @asteroid = asteroid = new THREE.Mesh geom, mat
      asteroid.scale.multiplyScalar 30
      # mesh.position.z = 1
      asteroid.renderDepth = -1
      @scene.add asteroid


    @following = null
    Deps.autorun =>
      selected = Session.get 'selected'
      @following = selected and BotDocs.findOne selected

  setSize: (@width, @height) ->
    @renderer.setSize width, height
    aspect = if height > 0 then width / height else 1
    @camera.aspect = aspect
    @camera.updateProjectionMatrix()

  createRenderer: ->
    r = new THREE.WebGLRenderer
      alpha: false
      antialias: true
      premultipliedAlpha: false
    # r.devicePixelRatio = 1
    r.shadowMapEnabled = false
    r.shadowMapCullFrontFaces = false
    r.autoClear = false
    r.setClearColor new THREE.Color 0x000000

    # r = new THREE.CanvasRenderer

    @renderer = r

  advance: (delta) ->
    if @following
      pos = @camera.position
      target = @following.pos
      factor = 1 / (1 + delta * 3)
      pos.x = target[0] + (pos.x - target[0]) * factor
      pos.y = target[1] + (pos.y - target[1]) * factor

  render: ->
    # @asteroid.material.opacity = Math.max 0, Math.min 1, @camera.position.z / 100
    # @renderer.clear false, true, false
    @renderer.clear true, false, false
    @renderer.render @scene, @camera

  viewToEye: (vec) ->
    vec.x = (vec.x / @width) * 2 - 1
    vec.y = 1 - (vec.y / @height) * 2
    vec

  viewRay: (viewX, viewY) ->
    vec = @viewToEye new Vec3 viewX, viewY, 0.9
    projector.unprojectVector vec, @camera
    vec.sub @camera.position
    vec.normalize()
    new THREE.Ray @camera.position, vec

  onClick: (event) ->
    ray = @viewRay event.clientX, event.clientY
    { pos, distance } = intersectZPlane ray, 0
    Meteor.call 'moveBotTo', pos.x, pos.y

  onWheel: (event) ->
    deltaY = event.wheelDeltaY ? event.deltaY
    @camera.position.z = Math.max 2, Math.min 100, @camera.position.z * Math.pow 2, deltaY * -0.0015
