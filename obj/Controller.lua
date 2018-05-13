Controller = Object:extend()

Controller.aim_distance = 100
Controller.aim_speed = 0.25
Controller.swing_speed_mult = 0.015
Controller.swing_tick = 65/1000
Controller.speed = 250
Controller.grab_button = 6
Controller.axis_deadzone = 0.1
--Controller.swing_deadzone = 0.5

function Controller:new(control_body, swing_body, joystick, swing_callback, grab_callback, release_callback)
  self.control_body = control_body
  self.control_body_mass = control_body:getMass()
  self.swing_body = swing_body
  self.joystick = joystick
  self.swing_callback = swing_callback
  self.grab_callback = grab_callback
  self.release_callback = release_callback

  self.aim = {
    x = control_body:getX() or 0,
    y = control_body:getY() or 0,
    actual_x = 0,
    actual_y = 0
  }
  self.prev_aim = { x = 0, y = 0 }
  self.control_swing_speed = 0
  self.body_swing_speed = 0
end

function Controller:update(dt)
  --swing_timer:update(dt)
  self:handleJoystick(dt)

  if self.is_swinging then
    self:swing(self.aim.x, self.aim.y)
    self.swing_callback()
  end
end

function Controller:handleJoystick(dt)
  -- Rotation
  local RX, RY = self.joystick:getAxis(3), self.joystick:getAxis(4)

  self.aim.actual_x = self.control_body:getX() + self.aim_distance * RX
  self.aim.actual_y = self.control_body:getY() + self.aim_distance * RY

  self:aimAt(self.aim.actual_x, self.aim.actual_y)

  if not (self:axisInDeadzone(self.axis_deadzone, RX)
      and self:axisInDeadzone(self.axis_deadzone, RY))  then
    self.is_swinging = true
    self:aimAt(self.aim.actual_x, self.aim.actual_y)
  else
    self.is_swinging = false
    self:aimAt(self.control_body:getX(), self.control_body:getY())
  end

  -- Movement
  local LX, LY = self.joystick:getAxis(1), self.joystick:getAxis(2)
  self.control_body:setLinearVelocity(LX * self.speed, LY * self.speed)

  -- Grabbing
  if self.joystick:isDown(self.grab_button) then
    self.grab_callback()
  else
    self.release_callback()
  end
end

function Controller:draw()
  -- Draw lerper
  -- love.graphics.setColor(0, 1, 0)
  -- love.graphics.circle("fill", self.aim.x, self.aim.y, 10)

  -- -- Draw aim
  -- love.graphics.setColor(1, 1, 1)
  -- love.graphics.circle("fill", self.aim.actual_x, self.aim.actual_y, 5)
end

function Controller:aimAt(x, y)
  self.aim.x = lume.lerp(self.aim.x, x, self.aim_speed)
  self.aim.y = lume.lerp(self.aim.y, y, self.aim_speed)
end

function Controller:swing(x, y)
  local px, py = self.control_body:getPosition()
  local desired_angle = lume.angle(px, py, x, y) - math.pi/2
  local hz = 130
  local next_angle = self.swing_body:getAngle() + self.swing_body:getAngularVelocity() / hz
  local total_rotation = desired_angle - next_angle

  while total_rotation < -math.pi do
    total_rotation = total_rotation + math.pi*2
  end
  while total_rotation > math.pi do
    total_rotation = total_rotation - math.pi*2
  end

  local desired_angular_velocity = total_rotation * hz
  local torque = self.swing_body:getInertia() * desired_angular_velocity / (1/hz)
  self.swing_body:applyTorque(torque)
end

function Controller:grab()

end

-- Utils
function Controller:axisInDeadzone(deadzone, axis)
  return math.abs(axis) < deadzone
end
