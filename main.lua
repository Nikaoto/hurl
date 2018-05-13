-- require "conf"

inspect = require "lib/inspect"

Object = require "lib/classic"
lume = require "lib/lume"
Timer = require "lib/Timer"
wf = require "lib/windfield"

-- Objects
require "obj/Player"
require "obj/Controller"
require "obj/Neon"

FULL_SCREEN = false
LEVEL_COLLISION_CLASS = "Level"
ARM_COLLISION_CLASS = "Arm"
HAND_COLLISION_CLASS = "Hand"
NEON_COLLISION_CLASS = "Neon"
ENTITY_COLLISION_CLASS = "Entity"

-- contains everything except Level and Players
objects = {}

function love.load()
  love.window.setFullscreen(FULL_SCREEN)
  --
  world = wf.newWorld(0, 0, true)
  -- Collision classes
  world:addCollisionClass(LEVEL_COLLISION_CLASS)
  world:addCollisionClass(NEON_COLLISION_CLASS)
  world:addCollisionClass(ARM_COLLISION_CLASS)
  world:addCollisionClass(ENTITY_COLLISION_CLASS)
  world:addCollisionClass(HAND_COLLISION_CLASS, {
    ignores = { LEVEL_COLLISION_CLASS, ENTITY_COLLISION_CLASS, NEON_COLLISION_CLASS } })

  local w, h = love.graphics.getDimensions()

  player1 = Player(world, { x = getRandX(), y = getRandY() }, love.joystick.getJoysticks()[1])
  if love.joystick.getJoysticks()[2] then
    player2 = Player(world, { x = getRandX(), y = getRandY() }, love.joystick.getJoysticks()[2])
  end

  -- Level
  wall_bottom = world:newRectangleCollider(0, h - 50, w, 50)
  wall_left = world:newRectangleCollider(0, 0, 50, w)
  wall_top = world:newRectangleCollider(0, 0, w, 50)
  wall_right = world:newRectangleCollider(w-50, 0, 50, w)
  wall_top:setType('static')
  wall_right:setType('static')
  wall_bottom:setType('static')
  wall_left:setType('static')
  wall_top:setCollisionClass(LEVEL_COLLISION_CLASS)
  wall_right:setCollisionClass(LEVEL_COLLISION_CLASS)
  wall_bottom:setCollisionClass(LEVEL_COLLISION_CLASS)
  wall_left:setCollisionClass(LEVEL_COLLISION_CLASS)

  --- Neons
  local neon_count = 5
  for i=1, neon_count do
    table.insert(objects, Neon(world, getRandX(), getRandY(), lume.randomchoice({"blue", "red"})))
  end
end

function love.update(dt)
  world:update(dt)
  player1:update(dt)

  if player2 then
    player2:update(dt)
  end

  -- Update objects
  for _, obj in pairs(objects) do
    if obj.update then
      obj:update(dt)
    end
  end
end

function love.draw()
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  world:draw()
  player1:draw()

  if player2 then
    player2:draw()
  end

  -- Draw neons
  for _, obj in pairs(objects) do
    if obj.draw then
      obj:draw()
    end
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end


-- [[ Utils ]] --
function sq(n) return n*n end

function filter_collision_classes(objects, ccs)
  local ret = {}

  for _, obj in pairs(objects) do
    if obj and obj.collisionClass
      and lume.reduce(ccs, function(acc, x) return acc and x ~= obj.collisionClass end) then
      table.insert(ret, obj)
    end
  end

  return ret
end

function queryRect(x, y, w, h, excluded_collision_classes)
  local colliders = {}

  for _, obj in pairs(objects) do
    -- Null and exclude check
    if obj and obj.collisionClass
      and lume.reduce(excluded_collision_classes, 
        function(acc, b) return acc and b ~= obj.collisionClass end) then
      -- Collision check
      if obj.x and obj.y and obj.width and obj.height
        and lume.aabb(x, y, w, h, obj.x, obj.y, obj.width, obj.height) then
        table.insert(colliders, obj)
      end
    end
  end

  return colliders
end

--- Spawning
rand_spawn_margin = 125
function getRandPosition()
  local m = rand_spawn_margin
  local w, h = love.graphics.getDimensions()
  local x, y = lume.random(m, w - m), lume.random(m, h - m)

  return x, y
end

function getRandX(margin)
  local w = love.graphics.getDimensions()
  return love.math.random(rand_spawn_margin, w - (margin or rand_spawn_margin))
end

function getRandY(margin)
  local _, h = love.graphics.getDimensions()
  return love.math.random(rand_spawn_margin, h - (margin or rand_spawn_margin))
end
--