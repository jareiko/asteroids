
Vec3 = THREE.Vector3

tmpVec3a = new Vec3

@MSL = {}

ThreeMesh =
  update: (obj, doc) ->
    Vec3::set.apply obj.position, doc.pos
    obj.rotation.z = doc.rot
    return

makeTextMesh = (text, opts = {}) ->
  textShapes = THREE.FontUtils.generateShapes text,
    font: "helvetiker"
    weight: "normal"
    size: opts.size or 0.3

  geom = new THREE.ShapeGeometry textShapes
  mat = new THREE.MeshBasicMaterial
    color: opts.color or 0xffffff
    depthTest: no
    transparent: yes

  mesh = new THREE.Mesh geom, mat
  mesh.geometry.computeBoundingBox()
  centroid = mesh.geometry.boundingBox.center()
  mesh.position.x = -centroid.x
  mesh

MSL.makeBotRenderer = (scene) -> class Bot
  geom = new THREE.PlaneGeometry 1, 1, 1, 1
  mat = new THREE.MeshBasicMaterial
  mat.map = THREE.ImageUtils.loadTexture('/textures/bot1.png')
  mat.transparent = yes
  mat.depthTest = no

  # reticuleGeom = new THREE.BufferGeometry
  # reticuleGeom.dynamic = no
  # reticuleGeom.attributes.position =
  #   itemSize: 3
  #   array: [
  #     2, 0, 0
  #     3, -1, 0
  #     3, 1, 0
  #     -2, 0, 0
  #     -3, -1, 0
  #     -3, 1, 0
  #   ]
  reticuleGeom = new THREE.Geometry
  reticuleGeom.vertices = [
      new Vec3 2, 0, 0
      new Vec3 3, -1, 0
      new Vec3 3, 1, 0
      new Vec3 -2, 0, 0
      new Vec3 -3, 1, 0
      new Vec3 -3, -1, 0
    ]
  reticuleGeom.faces = [
      new THREE.Face3 0, 1, 2
      new THREE.Face3 3, 4, 5
    ]
  reticuleMat = new THREE.MeshBasicMaterial
    blending: THREE.AdditiveBlending
    color: 0x008800
    depthTest: false
    transparent: yes

  constructor: (ent) ->
    @doc = ent.doc
    mesh = new THREE.Mesh geom, mat
    mesh.position.z = 0.1
    @obj = new THREE.Object3D
    @obj.add mesh
    scene.add @obj
    @reticuleMesh = new THREE.Mesh reticuleGeom, reticuleMat
    @reticuleMesh.scale.set 0, 0, 0
    scene.add @reticuleMesh
    # @caption = null
    updateCaption @obj, @doc.name
    @targetPos = null

  removed: ->
    scene.remove @reticuleMesh if @reticuleMesh
    scene.remove @obj

  updateCaption = (obj, caption) ->
    # return if caption is @caption
    # @caption = caption
    obj.remove obj.caption
    return if _.isEmpty caption
    textMesh = makeTextMesh caption, size: 0.5
    textMesh.renderDepth = 10
    textMesh.position.y = 0.7
    obj.caption = new THREE.Object3D
    obj.caption.add textMesh
    # obj.caption.rotation.eulerOrder = 'ZYX'
    # obj.caption.position.z = 1
    obj.add obj.caption

  changed: (fields) ->
    updateCaption @obj, @doc.name if 'name' of fields
    # @reticuleMesh.scale.x = 0 if 'plan' of fields

  advance: (delta) ->
    ThreeMesh.update @obj, @doc
    action = @doc.plan?[0]
    showTarget = action?.pos?
    scale = @reticuleMesh.scale.x
    if showTarget
      scale = Math.min 0.3, scale + delta * 0.3
      unless _.isEqual @targetPos, action.pos
        @targetPos = action.pos
        scale = 0
      Vec3::set.apply @reticuleMesh.position, action.pos
    else
      scale = Math.max 0, scale - delta * 0.3
    @reticuleMesh.visible = scale > 0  # Prevent three.js complaining about zero scale.
    @reticuleMesh.scale.set scale, scale, scale
    @reticuleMesh.rotation.z += delta * 0.5 / (scale * scale + 0.01)

    @obj.caption?.rotation.z = -@obj.rotation.z
    return
