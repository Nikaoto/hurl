Player = Object:extend()

-- [[ Defaults ]] --
Player.open_hand_sprite = love.graphics.newImage("res/hand_open.png")
Player.closed_hand_sprite = love.graphics.newImage("res/hand_closed.png")
Player.arm_sprite = love.graphics.newImage("res/arm.png")
Player.radius = 28
Player.restitution = 0.8
Player.mass = 800
Player.linear_damping = 0.9
Player.fixed_rotation = false
--- Arm
Player.arm_width = 10
Player.arm_height = 50
Player.arm_mass = 1
Player.arm_angular_damping = 4
--- Hand
Player.hand_width = 20
Player.hand_height = 20
Player.hand_mass = 1
Player.hand_angular_damping = 40


function Player:new(world, spawn, joystick, color)
  self.x = spawn.x or 100
  self.y = spawn.y or 100
  self.color = color or {1, 0.88, 0.74, 1}
  self.name = "Player"

  self.body = world:newCircleCollider(self.x, self.y, self.radius)
  self.body:setCollisionClass(ENTITY_COLLISION_CLASS)
  self.body:setRestitution(self.restitution)
  self.body:setMass(self.mass)
  self.body:setLinearDamping(self.linear_damping)
  self.body:setFixedRotation(self.fixed_rotation)

  local arm_x = self.x - self.arm_width / 2
  local arm_y = self.y

  -- Arm spawns south of player
  self.arm = world:newRectangleCollider(arm_x, arm_y, self.arm_width, self.arm_height)
  self.arm:setCollisionClass(ARM_COLLISION_CLASS)
  self.arm:setMass(self.arm_mass)
  self.arm:setAngularDamping(self.arm_angular_damping)
  self.arm_joint = world:addJoint("RevoluteJoint", self.body, self.arm, self.x, self.y, false)
  self.arm_sx = 1.2*self.arm_width / self.arm_sprite:getWidth()
  self.arm_sy = 1.3*self.arm_height / self.arm_sprite:getHeight()

  -- Hand spawns south of arm
  local hand_x = self.x - self.hand_width / 2
  local hand_y = self.y + self.arm_height
  self.hand = world:newRectangleCollider(hand_x, hand_y, self.hand_width, self.hand_height)
  self.hand:setCollisionClass(HAND_COLLISION_CLASS)
  self.hand:setMass(self.hand_mass)
  self.hand_joint = world:addJoint("RevoluteJoint", self.arm, self.hand, self.x, hand_y, true)
  self.hand_sx = 1.6* self.hand_width / self.open_hand_sprite:getWidth()
  self.hand_sy = 1.6* self.hand_height / self.open_hand_sprite:getHeight()

  -- Joint between grabbed object and hand
  self.grab_joint = nil

  self.is_grabbing = false
  self.is_trying_to_grab = false

  -- Controller callbacks
  self.controller = Controller(self.body, self.arm, joystick,
    function() -- onGrab
      self.is_trying_to_grab = true
      if not self.is_grabbing then
        self:grab()
      end
    end,
    function() -- onRelease
      self.is_trying_to_grab = false
      if self.is_grabbing then
        self:release()
      end
    end)
end

function Player:grab()
  local x, y = self.hand:getX(), self.hand:getY()

  lume.each({ NEON_COLLISION_CLASS, ENTITY_COLLISION_CLASS }, function(class)
    if self.hand:enter(class) then
      local collision_data = self.hand:getEnterCollisionData(class)
      self.grab_joint = world:addJoint("WeldJoint", self.hand, collision_data.collider, x, y, false)
      self.grab_joint:setUserData(self.name)
      self.is_grabbing = true
    end
  end)
end

function Player:release()
  self.is_grabbing = false

  if self.grab_joint then
    world:removeJoint(self.grab_joint)
    self.grab_joint = nil
  else
    self.grab_joint = nil
  end
end

function Player:update(dt)
  self.controller:update(dt)
  -- move
  -- rotate
  -- update physics
end

function Player:draw()
  self.controller:draw()

  -- Draw player
  love.graphics.setColor(self.color)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.circle("line", self.body:getX(), self.body:getY(), self.radius+1)

  love.graphics.setColor(1, 1, 1, 1)
  -- Draw arm
  love.graphics.draw(self.arm_sprite, self.arm:getX(), self.arm:getY(), self.arm:getAngle() - math.pi,
    self.arm_sx, self.arm_sy, self.arm_width*2, self.arm_height)

  -- Draw hand
  if self.is_grabbing or self.is_trying_to_grab then
    love.graphics.draw(self.closed_hand_sprite, self.hand:getX(), self.hand:getY(),
      self.hand:getAngle() - math.pi, self.hand_sx, self.hand_sy, self.hand_width*2.2,
      self.hand_height / self.hand_sy)
  else
    love.graphics.draw(self.open_hand_sprite, self.hand:getX(), self.hand:getY(),
      self.hand:getAngle() - math.pi, self.hand_sx, self.hand_sy, self.hand_width*2.2,
      self.hand_height / self.hand_sy)
  end
end