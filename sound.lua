sound = {
  ["grab"] = love.audio.newSource("res/grab.ogg", "static"),
  ["shatter"] = love.audio.newSource("res/shatter.ogg", "static"),
  ["electro"] = love.audio.newSource("res/electro.ogg", "static"),
  ["throw"] = love.audio.newSource("res/throw.ogg", "static"),
  ["blood"] = love.audio.newSource("res/blood.ogg", "static"),
  ["hiss"] = love.audio.newSource("res/hiss.ogg", "static"),
  ["crawl"] = love.audio.newSource("res/crawl.ogg", "static"),
}

function sound.play(str)
  sound[str]:setPitch(lume.random(0.5, 1))
  sound[str]:play()
end