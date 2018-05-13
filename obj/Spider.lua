Spider = Object:extend()

Spider.idle_sprite = love.graphics.newImage("res/spider_1.png")
--Spider.walk_sprites = { love.graphics.newImage("res/spider_3.png"), love.graphics.newImage("res/spider_2.png") }
Spider.stunned_sprite = love.graphics.newImage("res/spider_stunned.png")
Spider.stand_chance = 0.2
Spider.aggro_distance = 80
Spider.global_aggro_distance = 700
Spider.idle_move_speed = 200
Spider.aggro_move_speed = 300
Spider.width = 36
Spider.height = 28
Spider.restitution = 0.8
Spider.mass = 10
Spider.linear_damping = 4
Spider.stun_time = 2
Spider.damage = 1
--Spider.isUp

function Spider:new(world, x, y)
  self.x, self.y = x, y
  self.name = "Spider"

  self.sprite = self.idle_sprite
  self.sx = 2 * self.width / self.sprite:getWidth()
  self.sy = 1.6 * self.height / self.sprite:getHeight()

  self.move_direction = lume.random(math.pi)
  self.standing = false
  self.stunned = false

  self.movement_timer = Timer()
  self.movement_timer:every({1, 3}, function()
    self.move_direction = lume.random(math.pi*2)
    self.standing = math.random(0, 1) > self.stand_chance
  end)

  self.stun_timer = Timer()

  self.recovering = false

  self.body = world:newRectangleCollider(self.x, self.y, self.width, self.height)
  self.body:setMass(self.mass)
  self.body:setRestitution(self.restitution)
  self.body:setLinearDamping(self.linear_damping)
  self.body:setCollisionClass(SPIDER_COLLISION_CLASS)
  self.body:setFixedRotation(true)
  self.body:setPreSolve(function(col1, col2, contact)
    -- Turn away from wall
    if col2.collision_class == LEVEL_COLLISION_CLASS
      or col2.collision_class == SPIDER_COLLISION_CLASS then
      self.move_direction = self.move_direction + lume.random(-math.pi, math.pi)
    end
  end)

  self.body:setObject(self)
end

function Spider:update(dt)
  self.stun_timer:update(dt)
  self.movement_timer:update(dt)

  -- AI
  if not self.stunned then
    if self.prey then
      self:chasePrey()
    else
      self.prey = self:findClosestPrey()
      if self.prey then
        -- start chasing prey
      else
        -- Idle
        if self.standing then
          -- stand
        else
          -- wander around
          local vx, vy = lume.vector(self.move_direction, self.idle_move_speed)
          self.body:setLinearVelocity(vx, vy)
        end
      end
    end
  elseif not self.recovering then
    -- Start recovering
    self.sprite = self.stunned_sprite
    self.recovering = true
    self.prey = nil
    self.stun_timer:after(self.stun_time, function()
      self.stunned = false
      self.recovering = false
      self.sprite = self.idle_sprite
    end)
  end

  -- Collisions
  if self.body:enter(ENTITY_COLLISION_CLASS) then
    local coll = self.body:getEnterCollisionData(ENTITY_COLLISION_CLASS).collider
    coll:getObject():takeDamage(self.damage)
  end
end

function Spider:draw()
  love.graphics.setColor(1, 1, 1, 1)
  local d = self:getDirection()
  love.graphics.draw(self.sprite, self.body:getX() - self.width*d , self.body:getY() - self.height/2 - self.height*self.sx, 0,
    self.sx * d, self.sy)

  love.graphics.circle("line", self.body:getX(), self.body:getY(), self.aggro_distance)
end

function Spider:getDirection()
  if self.move_direction > math.pi/2 and self.move_direction < math.pi*3/2 then
    return -1
  end
  return 1
end

function Spider:findClosestPrey()
  for i, p in pairs(players) do
    if p:inDistance(self.body:getX(), self.body:getY(), self.aggro_distance) then
      return p
    end
  end
  return nil
end

function Spider:chasePrey()
  if self.prey and self.prey.body then
    self.move_direction = lume.angle(self.body:getX(), self.body:getY(), self.prey.body:getX(), self.prey.body:getY())
    local vx, vy = lume.vector(self.move_direction, self.aggro_move_speed)
    self.body:setLinearVelocity(vx, vy)
  end
end

function Spider:setPrey(prey)
  self.prey = prey
end