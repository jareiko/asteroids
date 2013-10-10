
Template.infopanel.selected = ->
  BotDocs.findOne Session.get 'selected'

Template.infopanel.selected_coords = ->
  return unless ent = Bots.findById Session.get 'selected'
  bot = ent.getComponent BotComponent
  pos = bot.doc.pos
  "#{pos[0].toFixed(2)}, #{pos[1].toFixed(2)}"

Template.infopanel.selected_task = ->
  return unless ent = BotDocs.findOne Session.get 'selected'
  ent.plan[0]?.type ? 'idle'

Template.infopanel.nameEditable = ->
  ent = Bots.findById Session.get 'selected'
  ent and ent.doc.owner is Meteor.userId()

Template.infopanel.loggedOut = ->
  true
  # not Meteor.userId()?

Template.infopanel.events
  'click .name': (event) ->
    return unless ent = Bots.findById Session.get 'selected'
    bot = ent.getComponent BotComponent
    result = window.prompt 'Edit Robot Name', bot.doc.name
    bot.setName result if result
    false
