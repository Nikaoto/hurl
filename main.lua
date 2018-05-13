-- require "conf"

inspect = require "lib/inspect"

Object = require "lib/classic"
lume = require "lib/lume"
Timer = require "lib/Timer"
wf = require "lib/windfield"
shack = require "lib/shack"

require "sound"

-- Objects
require "obj/Blood"
require "obj/Player"
require "obj/Controller"
require "obj/Neon"
require "obj/Spider"

FULL_SCREEN = true
LEVEL_COLLISION_CLASS = "Level"
ARM_COLLISION_CLASS = "Arm"
HAND_COLLISION_CLASS = "Hand"
NEON_COLLISION_CLASS = "Neon"
ENTITY_COLLISION_CLASS = "Entity"
SPIDER_COLLISION_CLASS = "Spider"
--BACKGROUND_COLOR = {0.5, 0.5, 0.5, 1}
BACKGROUND_COLOR =  { 0.41, 0.35, 0.12, 1 }
BACKGROUND_COLOR_2 =  { 0.41, 0.35, 0.12, 0.2 }
WALL_COLOR = {0.7, 0.7, 0.7, 1}

-- contains everything except Level and Players
objects = {}
players = {}
blood = {}
game_done = false

function love.load()
  love.window.setFullscreen(FULL_SCREEN)
  math.randomseed(os.time())
  --
  block_sprite = love.graphics.newImage("res/block.png")
  block_size = 55
  block_sx = block_size / block_sprite:getWidth()
  block_sy = block_size / block_sprite:getHeight()

  world = wf.newWorld(0, 0, true)
  -- Collision classes
  world:addCollisionClass(LEVEL_COLLISION_CLASS)
  world:addCollisionClass(NEON_COLLISION_CLASS)
  world:addCollisionClass(ARM_COLLISION_CLASS)
  world:addCollisionClass(ENTITY_COLLISION_CLASS)
  world:addCollisionClass(SPIDER_COLLISION_CLASS)
  world:addCollisionClass(HAND_COLLISION_CLASS, {
    ignores = { LEVEL_COLLISION_CLASS, ENTITY_COLLISION_CLASS, NEON_COLLISION_CLASS } })

  local w, h = love.graphics.getDimensions()

  mappings = {
    {
      grab = 6
    },
    {
      grab = 7,
      rx = 4,
      ry = 3
    }
  }

  -- Spawn players
  for i, j in pairs(love.joystick.getJoysticks()) do
    local randcolor = { lume.random(5, 100)/100,lume.random(5, 100)/100,lume.random(5, 100)/100 }
    table.insert(players, Player("Player "..i, world, { x = getRandX(), y = getRandY() }, j, randcolor, mappings[i]))
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
  local m = 70
  for i=1, neon_count do
    local x = lume.random(m, w-m)
    local y = lume.random(m, m*3)
    table.insert(objects, Neon(world, x, y, lume.randomchoice({"red", "blue"})))
  end

  --- Spiders
  local spider_count = 3
  for i=1, spider_count do
    table.insert(objects, Spider(world, getRandX(), getRandY()))
  end
end

function love.update(dt)
  shack:update(dt)
  world:update(dt)

  if #players == 1 then
    game_done = true
    winner = players[1].name
  end

  -- Update players
  for i, p in pairs(players) do
    p:update(dt)
  end

  -- Update objects
  for _, obj in pairs(objects) do
    if obj.update then
      obj:update(dt)
    end
  end

  -- Update blood
  for i, b in pairs(blood) do
    b:update(dt)
  end
end

function love.draw()
  love.graphics.clear(BACKGROUND_COLOR)
  shack:apply()

  --world:draw()

  -- Draw level
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(WALL_COLOR)

  -- Top wall
  for x=0, w, block_size do
    drawBlock(x, 0)
  end
  --Bottom wall
  for x=0, w, block_size do
    drawBlock(x, h - block_size)
  end
  -- Left wall
  for y=0, h, block_size do
    drawBlock(0, y)
  end
  --Right wall
  for y=0, h, block_size do
    drawBlock(w - block_size, y)
  end

  -- Background blocks
  love.graphics.setColor(BACKGROUND_COLOR_2)
  for x=0, w, block_size/2 do
    for y=0, h, block_size/2 do
      drawBlock(x, y)
    end
  end

  -- Draw blood
  for i, b in pairs(blood) do
    b:draw()
  end

  -- Draw players
  for i, p in pairs(players) do
    p:draw()
  end

  -- Draw neons
  for _, obj in pairs(objects) do
    if obj.draw then
      obj:draw()
    end
  end

  if game_done then
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", w/4, h/4, w/2, h/2)
    love.graphics.setColor(1, 1, 1, 1)

    -- NOTE: DO NOT CROSS 0.25 and 0.75 screen width with text
    local scale = 8
    love.graphics.setColor(1, 0.843, 0)
    love.graphics.printf(winner .. " wins!", 0, h*0.3, w/scale, 'center', 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "r" then
    players = {}
    blood = {}
    objects = {}
    game_done = false
    love.load()
  end
  if key == "n" then
    objects = {}
    game_done = false
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

function targetPlayer(p)
  local all_spiders = lume.filter(objects, function(obj) return obj.name and obj.name == "Spider" end)

  local available_spiders = lume.filter(all_spiders, function(spider) return spider.prey == nil end)
  if #available_spiders > 0 then
    for _, spider in pairs(available_spiders) do
      spider:setPrey(p)
    end
  else
    for _, spider in pairs(lume.slice(all_spiders, math.ceil(#all_spiders/2))) do
      if lume.distance(p.body:getX(), p.body:getY(), spider.body:getX(), spider.body:getY())
        < Spider.global_aggro_distance then
        spider:setPrey(p)
      end
    end
  end
end

function getAllNeons(color)
  local neons = {}
  for _, obj in pairs(objects) do
    if obj.name and obj.name == "Neon" and obj.neon_type == color then
      table.insert(neons, obj)
    end
  end
  return neons
end

function drawBlock(x, y)
  love.graphics.draw(block_sprite, x, y, 0, block_sx, block_sy)
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