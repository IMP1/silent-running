ROOT_2 = math.sqrt(2)

local Player = require("player")

function love.load()
    player = Player.new(256, 256)
end

function love.update(dt)
    player:update(dt)
end

function love.draw()
    player:draw()
end