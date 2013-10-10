
PI = Math.PI
TAU = PI * 2

repeat = (x, limit) -> x - (Math.floor x / limit) * limit
roundRange = (x, range) -> (Math.round x / range) * range

class @BotComponent

  all = []

  @findByOwner = (owner) ->
    for comp in all
      return comp if comp.doc.owner is owner
    null

  constructor: (ent) ->
    all.push @
    @doc = ent.doc
    @doc.name ?= 'Robot ' + Random.id().slice(0, 4)
    @doc.owner ?= null
    @doc.plan ?= []

  setOwner: (owner) ->
    @doc.owner = owner

  setName: (name) ->
    Meteor.call 'botSetName', @doc._id, name

  advance: (delta) ->
    plan = @doc.plan
    if action = plan?[0]
      switch action.type
        when 'walk'
          doc = @doc
          pos = doc.pos
          target = action.pos
          pos[2] = target[2]
          # factor = 1 - 1 / (1 + 5 * delta)
          dx = target[0] - pos[0]
          dy = target[1] - pos[1]
          dist = Math.sqrt dx * dx + dy * dy
          if dist > 0
            ang = Math.atan2 dy, dx
            rot = doc.rot
            rot -= roundRange rot - ang, TAU
            if rot < ang
              rot = Math.min ang, rot + delta
            else
              rot = Math.max ang, rot - delta
            doc.rot = rot

            angleDiff = ang - doc.rot
            stepSize = 5 * Math.max 0, (Math.cos angleDiff) - 0.8
            stepSize = Math.max stepSize, dist - 3
            stepSize = delta * Math.min 1, stepSize
            if dist > stepSize
              fwdX = stepSize * Math.cos doc.rot
              fwdY = stepSize * Math.sin doc.rot
              # if factor < 1 then dx *= factor; dy *= factor
              pos[0] += fwdX
              pos[1] += fwdY
            else
              pos[0] = target[0]
              pos[1] = target[1]
          else
            plan.shift()

# DB collection on server, published collection on client.
@BotDocs = new Meteor.Collection "bots"

# Entities
@Bots = new Asteroid.EntityCollection @BotDocs
@Bots.addComponent Asteroid.Transform
@Bots.addComponent BotComponent

# ES performs auto advancing on server.
@myES = new Asteroid.EntitySystem
@myES.addEntityCollection @Bots

if Meteor.isServer
  Meteor.publish 'region', (x, y) ->
    # console.log 'publish to user ' + @userId
    Bots.publish 'bots', @

Meteor.methods
  moveBotTo: (x, y) ->
    myBot = BotComponent.findByOwner @userId
    return unless myBot
    myBot.doc.plan = [
      type: 'walk'
      pos: [ x, y, 0 ]
    ]
  botSetName: (_id, name) ->
    bot = Bots.findById _id
    return unless bot.doc.owner is @userId
    return unless 1 <= name.length <= 20
    bot.doc.name = name
