Spider = Object:extend()

Spider.idle_sprite = love.graphics.newImage("res/spider_1.png")
Spider.stunned_sprite = love.graphics.newImage("res/spider_stunned.png")
Spider.stand_chance = 0.1
Spider.aggro_distance = 500
Spider.idle_move_speed = 200
Spider.aggro_move_speed = 500
Spider.width = 46
Spider.height = 32
Spider.restitution = 0.8
Spider.mass = 20
Spider.linear_damping = 4
Spider.stun_time = 2

function Spider:new(world, x, y)
  self.x, self.y = x, y

  self.sprite = self.idle_sprite
  self.sx = 2 * self.width / self.sprite:getWidth()
  self.sy = 2 * self.height / self.sprite:getHeight()

  self.move_direction = lume.random(math.pi)
  self.standing = false
  self.is_stunned = false

  self.movement_timer = Timer()
  self.movement_timer:every({1, 5}, function()
    self.move_direction = lume.random(math.pi*2)
    self.standing = lume.random(1) > self.stand_chance
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

  if not self.stunned then
    if self.standing then
      -- stand sprite
    else
      local vx, vy = lume.vector(self.move_direction, self.idle_move_speed)
      self.body:setLinearVelocity(vx, vy)
    end
  elseif not self.recovering then
    self.sprite = self.stunned_sprite
    self.recovering = true
    self.stun_timer:after(self.stun_time, function()
      self.stunned = false
      self.recovering = false
      self.sprite = self.idle_sprite
    end)
  end
end

function Spider:draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.sprite, self.body:getX(), self.body:getY(), 0,
    self.sx * self:getDirection(), self.sy, self.width/self.sx, self.height/self.sy)
end

function Spider:getDirection()
  if self.move_direction > math.pi/2 and self.move_direction < math.pi*3/2 then
    return -1
  end
  return 1
end