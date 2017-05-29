DEBUG = {
    -- server
    showMap         = false,
    showMapObjects  = false,
    showGameObjects = false,
    showServerInfo  = true,
    showPlayerInfo  = false,
    showLog         = false,
    showCommands    = true,
    -- client
    keepPongs       = false,
}

---------------
-- Libraries --
---------------
require 'helpers.functional'
require 'helpers.coroutine'

local bitser = require 'lib.bitser'
local sock   = require 'lib.sock'
local tlo    = require 'lib.tlo'
tlo.setLanguagesFolder("lang")
tlo.setLanguage("en-UK")

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
    lobby = Layouts.title.main
end

function startServer()
    local server = Server.new()
    role = server
    lobby = nil
end

function attemptConnection(address)
    lobby:elementWithId("connectionSpinner").visible = true
    client = Client.new("localhost")
    connecting = true
end

function connectionAchieved()
    role = client
    connecting = nil
    client     = nil
    lobby      = nil
end

function cancelConnection()
    lobby:elementWithId("connectionSpinner").visible = false
    connecting = false
    client     = nil
end

function love.textinput(text)
    if lobby then
        lobby:keytyped(text)
    end
end

function love.keypressed(key, isRepeat)
    if lobby then 
        lobby:keypressed(key, isRepeat)
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
    if connecting then
        client.client:update()
    end
    if lobby then
        lobby:update(dt, mx, my)
        -- lobby:update(dt, mx, my)
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

    if connecting then
        love.graphics.print(client.client:getState(), 0, 0)
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