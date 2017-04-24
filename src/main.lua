DEBUG = {
    showMap       = false,
    showLog       = false,
    showPlayers   = true,
    showVelocity  = true,
    showPings     = true,
    showTriangles = true,
    keepPongs     = false,
    showCommands  = false,
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
local Server         = require 'server'
local Client         = require 'client'
local LevelGenerator = require 'level_generator'
local Log            = require 'log'
local Rock           = require 'rock'
local Player         = require 'player'
local Ping           = require 'ping'
local PongGhost      = require 'pong_ghost'

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

function love.mousepressed(mx, my, key)
    if role then
        role:mousepressed(mx, my, key)
    end
end

function love.update(dt)
    role:update(dt)
    log:update()
end

function love.draw()
    if role then
        role:draw()
    else
        love.graphics.setColor(255, 255, 255)
        love.graphics.printf("WAITING", 0, 96, love.graphics.getWidth(), "center")
    end

    if DEBUG then
        drawDebug()
    end
end

function drawDebug()
    love.graphics.setColor(255, 255, 255)
    if DEBUG.showLog then
        log:draw()
    end
end
