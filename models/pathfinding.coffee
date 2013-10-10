
_ = @_ ? require '../tests/node_modules/underscore'

exp = if Meteor? then @Pathfinding = {} else exports

class exp.Grid
  constructor: (opts) ->
    @blocked = {}
    @size = opts?.size ? 1

  # Pretty much just for testing.
  blockTile: (gX, gY) ->
    @blocked["#{gX},#{gY}"] = yes

  addCylinder: (x, y, radius) ->
    size = @size
    tMinX = Math.floor (x - radius) / size
    tMaxX = Math.ceil  (x + radius) / size
    tMinY = Math.floor (y - radius) / size
    tMaxY = Math.ceil  (y + radius) / size
    radiusSq = radius * radius
    for gY in [tMinY...tMaxY]
      for gX in [tMinX...tMaxX]
        dX = gX * size - x
        dY = gY * size - y
        distSq = dX * dX + dY * dY
        continue if distSq > radiusSq
        @blocked["#{gX},#{gY}"] = yes
    return

  getNode: (x, y) ->
    size = @size
    gX = Math.round x / size
    gY = Math.round y / size
    "#{gX},#{gY}"

  neighbors: (key) ->
    [ gX, gY ] = key.split ','
    gX = parseInt gX
    gY = parseInt gY
    directions = [
      [ -1, -1 ]
      [ 0, -1 ]
      [ 1, -1 ]
      [ 1, 0 ]
      [ 1, 1 ]
      [ 0, 1 ]
      [ -1, 1 ]
      [ -1, 0 ]
    ]
    blocked = @blocked
    results = []
    for d in directions
      key = (gX + d[0]) + ',' + (gY + d[1])
      results.push key unless blocked[key]
    results

  estimateCost: (src, dst) ->
    [ gSX, gSY ] = src.split ','
    [ gDX, gDY ] = dst.split ','
    dX = gDX - gSX
    dY = gDY - gSY
    @size * Math.sqrt dX * dX + dY * dY

  findAStar: (start, goal) ->
    fCost = @estimateCost start, goal
    # A sorted list of pairs: [ fCost, key ]
    open = [ [ fCost, start ] ]
    openSet = {}
    closedSet = {}
    cameFrom = {}
    gCost = {}

    open[start] = yes
    gCost[start] = 0

    sortByCost = (pair) -> pair[0]

    reconstructPath = (key) ->
      if key of cameFrom
        path = reconstructPath cameFrom[key]
        path.push key
        return path
      else
        return [ key ]

    counter = 0
    while node = open.shift()
      break if ++counter > 200
      [ cost, key ] = node
      return reconstructPath goal if key is goal
      delete openSet[key]

      closedSet[key] = yes
      for neighbor in @neighbors key
        gCostTentative = gCost[key] + @estimateCost key, neighbor
        if closedSet[neighbor] and gCostTentative >= gCost[neighbor]
          continue

        if not openSet[neighbor] or gCostTentative < gCost[neighbor]
          cameFrom[neighbor] = key
          gCost[neighbor] = gCostTentative
          fCost = gCost[neighbor] + @estimateCost neighbor, goal
          if neighbor not of openSet
            openSet[neighbor] = yes
            value = [ fCost, neighbor ]
            open.splice (_.sortedIndex open, value, sortByCost), 0, value

    return false

  decodePath: (path) ->
    size = @size
    tupleFromKey = (key) ->
      s = key.split ','
      [ parseInt(s[0]) * size, parseInt(s[1]) * size ]
    tupleFromKey key for key in path


