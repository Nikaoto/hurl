Player = Object:extend()

-- [[ Defaults ]] --
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


function Player:new(world, spawn, joystick)
  self.x = spawn.x or 100
  self.y = spawn.y or 100

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

  -- Hand spawns south of arm
  local hand_x = self.x - self.hand_width / 2
  local hand_y = self.y + self.arm_height
  self.hand = world:newRectangleCollider(hand_x, hand_y, self.hand_width, self.hand_height)
  self.hand:setCollisionClass(HAND_COLLISION_CLASS)
  self.hand:setMass(self.hand_mass)
  self.hand_joint = world:addJoint("RevoluteJoint", self.arm, self.hand, self.x, hand_y, true)

  -- Joint between grabbed object and hand
  self.grab_joint = nil

  self.controller = Controller(self.body, self.arm, joystick,
    function() -- onGrab
      if not self.is_grabbing then
        self:grab()
      end
    end,
    function() -- onRelease
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
      self.is_grabbing = true
    end
  end)
end

function Player:release()
  self.is_grabbing = false

  if self.grab_joint and self.grab_joint.destroy then
    self.grab_joint:destroy()
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
  -- don't do anything for now
end