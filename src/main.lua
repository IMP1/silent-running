DEBUG = {
    showMap      = true,
    showLog      = true,
    showPlayers  = true,
    showVelocity = true,
}

---------------
-- Constants --
---------------
PORT = 22122

---------------
-- Libraries --
---------------
local bitser = require 'lib.bitser'
local sock   = require 'lib.sock'

-------------
-- Classes --
-------------
local Server = require 'server'
local Log    = require 'log'
local Rock   = require 'rock'
local Player = require 'player'

function love.load()
    log = Log.new()
end

function love.keypressed(key, isRepeat)
    if not role then 
        if key == "1" then
            role = Server.new()
        elseif key == "2" then
            role = Client.new()
        end
    else
        role:keypressed(key, isRepeat)
    end
end

function love.update(dt)
    role:update(dt)
    log:update()
end

function love.draw()
    if DEBUG then
        drawDebug()
    end

    if role then
        role:draw()
    else
        love.graphics.setColor(255, 255, 255)
        love.graphics.printf("WAITING", 0, 96, love.graphics.getWidth(), "center")
    end

end

function drawDebug()
    love.graphics.setColor(255, 255, 255)
    if DEBUG.showLog then
        log:draw()
    end
end