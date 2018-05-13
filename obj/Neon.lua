Neon = Object:extend()

Neon.blue_sprite_path = "res/blue_neon.png"
Neon.red_sprite_path = "res/red_neon.png"
Neon.width = 74
Neon.height = 14
Neon.mass = 2
Neon.restitution = 0.8
Neon.linear_damping = 1
Neon.active = false
Neon.light_radius = 80
Neon.shattered_light_radius = 70
Neon.hit_collision_classes = { NEON_COLLISION_CLASS, ENTITY_COLLISION_CLASS, LEVEL_COLLISION_CLASS }
Neon.shatter_speed = 450
Neon.light_alpha = 0.4
Neon.shattered_light_alpha = 0.15

function Neon:new(world, x, y, neon_type)
  self.x = x
  self.y = y
  self.neon_type = neon_type or "blue"

  -- Set sprite
  if self.neon_type == "blue" then
    self.light_color = { 0, 1, 1, self.light_alpha }
    self.sprite = love.graphics.newImage(self.blue_sprite_path)
  elseif self.neon_type == "red" then
    self.light_color = { 1, 0.1, 0, self.light_alpha }
    self.sprite = love.graphics.newImage(self.red_sprite_path)
  end

  self.sx = self.width / self.sprite:getWidth()
  self.sy = self.height / self.sprite:getHeight()
  self.ox = self.width/2
  self.oy = self.height/2

  self.body = world:newRectangleCollider(self.x, self.y, self.width, self.height)
  self.body:setCollisionClass(NEON_COLLISION_CLASS)
  self.body:setMass(self.mass)
  self.body:setLinearDamping(self.linear_damping)
  self.body:setRestitution(self.restitution)
end

function Neon:update(dt)
  if not self.shattered then
    -- Check collisions
    lume.each({ NEON_COLLISION_CLASS, ENTITY_COLLISION_CLASS, LEVEL_COLLISION_CLASS },
      function(class)
        if self.body:enter(class) then
          print("HIT")
          if self.body:getLinearVelocity() >= self.shatter_speed then
            self:shatter()
          end
        end
      end)
  elseif not self.destroyed then
    -- Check if player has let go and then destroy self body
    if #self.body:getJoints() == 0 then
      self:destroy()
    end
  end
end

function Neon:draw()
  if not self.shattered then
    -- Draw sprite
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.sprite, self.body:getX(), self.body:getY(),
      self.body:getAngle(), self.sx, self.sy, self.width*3.5, self.height*3)

    -- Draw light
    love.graphics.setColor(self.light_color)
    love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.light_radius)
  else
    love.graphics.setColor(self.light_color)
    love.graphics.circle("fill", self.last_x, self.last_y, self.shattered_light_radius)
  end
end

function Neon:activate()
  self.active = true
end

function Neon:shatter()
  self.shattered = true
  self.last_x, self.last_y = self.body:getPosition()
  -- Deactivate body
  self.body:setActive(false)
  -- Dim light
  self.light_color[4] = self.shattered_light_alpha
  print("SHATTER")
  -- TODO leave some shard particle effect shards
end

function Neon:destroy()
  self.destroyed = true
  self.body:destroy()
  print("DESTROY")
end

function Neon:getBody()
  return self.body
end

function Neon:isLightingPoint(x, y)
  return lume.dist(self.x, self.y, x, y, true) < sq(self.light_radius)
end

function Neon:isLightingCircle(x, y, r)
  return lume.dist(self.x, self.y, x, y, true) < sq(self.light_radius) + sq(r)
end