DEBUG = {
    -- server
    showMap         = false,
    showMapObjects  = false,
    showGameObjects = false,
    showPlayerInfo  = false,
    showLog         = false,
    showCommands    = true,
    -- client
    keepPongs       = false,
}

---------------
-- Libraries --
---------------
array        = require 'lib.functional'
local bitser = require 'lib.bitser'
local sock   = require 'lib.sock'
local tlo    = require 'lib.tlo'
tlo.setLanguage("en-UK")
tlo.setLanguagesFolder("lang")

---------------
-- Constants --
---------------
PORT = 22122
T = tlo.localise

-------------
-- Classes --
-------------
Server         = require 'server'
Client         = require 'client'
local Layouts  = require 'layouts'
local Log      = require 'log'

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
    lobby = Layouts.title
end

function startServer()
    role  = Server.new()
    lobby = nil
end

function love.textinput(text)
    if lobby then
        lobby:keytyped(text)
    end
end

function love.keypressed(key, isRepeat)
    if lobby then 
        lobby:keypressed(key, isRepeat)
        -- if key == "1" then
        --     role = Server.new()
        -- elseif key == "2" then
        --     role = Client.new("localhost")
        -- end
    elseif role then
        role:keypressed(key, isRepeat)
    end
end

function love.mousepressed(mx, my, key)
    if lobby then
        lobby:mousepressed(mx, my, key)
    elseif role and role.mousepressed then
        role:mousepressed(mx, my, key)
    end
end

function love.mousereleased(mx, my, key)
    if lobby then
        lobby:mousereleased(mx, my, key)
    elseif role and role.mousereleased then
        role:mousereleased(mx, my, key)
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    if lobby then
        lobby:update(dt, mx, my)
    elseif role then
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
