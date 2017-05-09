DEBUG = {
    showMap        = true,
    showLog        = false,
    showPlayers    = true,
    showPlayerInfo = true,
    showPings      = true,
    showTriangles  = true,
    keepPongs      = false,
    showCommands   = true,
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
local UiCollection   = require 'mortar'
local Server         = require 'server'
local Client         = require 'client'
local Log            = require 'log'

function love.load(args)
    log = Log.new()
    if args[2] == "server" then
        role = Server.new()
    end
    if args[2] == "client" then
        role = Client.new(args[3])
    end
    if not role then 
        setupLobby()
    end
end

function setupLobby()
    lobby = love.filesystem.load("title_layout.lua")()
end

function love.keypressed(key, isRepeat)
    if lobby then 
        if key == "1" then
            role = Server.new()
        elseif key == "2" then
            role = Client.new("localhost")
        end
    end
    if role then
        role:keypressed(key, isRepeat)
    end
end

function love.mousepressed(mx, my, key)
    if lobby then
        lobby:mousepressed(mx, my, key)
    end
    if role then
        role:mousepressed(mx, my, key)
    end
end

function love.update(dt)
    if lobby then
        lobby:update(dt)
    end
    if role then
        role:update(dt)
    end
    log:update()
end

function love.draw()
    if role then
        role:draw()
    else
        drawLobby()
    end

    if DEBUG then
        drawDebug()
    end
end

function drawLobby()
    love.graphics.setColor(255, 255, 255)
    lobby:draw()
end

function drawDebug()
    love.graphics.setColor(255, 255, 255)
    if DEBUG.showLog then
        log:draw()
    end
end
