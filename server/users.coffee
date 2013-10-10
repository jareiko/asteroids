Accounts.onCreateUser (options, user) ->
  console.log "Created user: " + JSON.stringify user
  user.profile = options.profile if options.profile

  ent = Bots.create()
  ent.getComponent(BotComponent).setOwner user._id
  randCoord = -> Random.fraction() * 10 - 5
  ent.doc.pos = [ randCoord(), randCoord(), 0 ]
  Bots.add ent

  return user
