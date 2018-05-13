Neon = Object:extend()

Neon.width = 70
Neon.height = 14
Neon.mass = 2
Neon.restitution = 0.8
Neon.active = false
Neon.light_radius = 80
Neon.hit_collision_classes = { NEON_COLLISION_CLASS, ENTITY_COLLISION_CLASS, LEVEL_COLLISION_CLASS }
print(Neon.hit_collision_classes[2])
Neon.shatter_speed = 30

function Neon:new(world, x, y, color)
  self.x = x
  self.y = y
  self.color = color or { 0, 1, 1, 0.3 }

  self.body = world:newRectangleCollider(self.x, self.y, self.width, self.height)
  self.body:setCollisionClass(NEON_COLLISION_CLASS)
  self.body:setMass(self.mass)
  self.body:setRestitution(self.restitution)
end

function Neon:update(dt)
  -- Check collisions
  lume.each(self.hit_collision_classes, function(class)
    if self.body:enter(class) then
      print("HIT")
      if self.body:getLinearVelocity() >= self.shatter_speed then
        self:shatter()
      end
    end
  end)
end

function Neon:draw()
  love.graphics.setColor(self.color)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.light_radius)
end

function Neon:activate()
  self.active = true
end

function Neon:shatter()
  self = {}
  self.broken = true
  print("SHATTER")
  -- TODO leave some shard particle effect shards
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