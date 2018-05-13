Blood = Object:extend()

function Blood:new(x, y, persistent, color, max, img)
  self.x, self.y = x, y
  self.persistent = persistent
  self.color = color or {1, 0, 0, 1}
  self.img = img or love.graphics.newImage("res/blood.png")
  self.max = max or 32

  self.psystem = love.graphics.newParticleSystem(self.img, self.max)
  self.psystem:setParticleLifetime(10, 20) -- Particles live at least 2s and at most 5s.
  self.psystem:setDirection(lume.random(math.pi*2))
  self.psystem:setSizeVariation(1)
  self.psystem:setLinearAcceleration(-1000, -1000, 1000, 1000)
  self.psystem:setSpeed(400, 800)
  self.psystem:setLinearDamping(6)

  self.done = false
  self.done_timer = Timer()
  self.done_timer:after({0.1, 0.5}, function() self.done = true end)
  sound.play("blood")
end

function Blood:update(dt)
  self.done_timer:update(dt)
  self.psystem:emit(self.max)
  if not self.done then
    self.psystem:update(dt)
  end
end

function Blood:draw()
  love.graphics.draw(self.psystem, self.x, self.y)
end