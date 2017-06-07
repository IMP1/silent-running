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

---------------
-- Constants --
---------------
DEFAULT_PORT = 22122
T = tlo.localise

-------------
-- Classes --
-------------
Server         = require 'server'
Client         = require 'client'
-- local Layouts  = require 'layouts'
Log      = require 'log'

function love.load(args)
    applySettings()
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

function createDefaultSettings()
    file = love.filesystem.newFile(".settings")
    file:open('w')
    file:write("return {")
    file:write("    graphics = {")
    file:write("        resolution = { 960, 640 },")
    file:write("        vsync = true,")
    file:write("        fullscreen = 0,")
    file:write("    },")
    file:write("    language = \"en-UK\",")
    file:write("}")
    file:close()
    
    love.filesystem.createDirectory("lang")
    defaultLanguageFile = love.filesystem.newFile("lang/en-UK")
    defaultLanguageFile:open("w")
    defaultLanguageFile:write("return {}")
    defaultLanguageFile:close()
end

function applySettings()
    if not love.filesystem.exists(".settings") then
        createDefaultSettings()
    end
    tlo.setLanguagesFolder("lang")

    local settings = love.filesystem.load(".settings")()
    if settings.graphics then
        local width  = settings.graphics.resolution[1] or 800
        local height = settings.graphics.resolution[2] or 600
        local flags = {}
        flags.vsync = settings.graphics.vsync == 1
        local fullscreen = settings.graphics.fullscreen or 0
        flags.fullscreen = fullscreen > 0
        flags.fullscreentype = ({"desktop", "exclusive"})[fullscreen]
        love.window.setMode(width, height, flags)
    end
    
    if settings.language then
        tlo.setLanguage("en-UK")
    end
end

function setupLobby()
    local layouts  = love.filesystem.load('layouts.lua')().title
    lobby = layouts.main
end

function startServer()
    local input = lobby:elementWithId("port")
    input:validate(true)
    if input.valid then
        local port = tonumber(input:value())
        local server = Server.new(port)
        role = server
        lobby = nil
    end
end

function attemptConnection(address)
    local input1 = lobby:elementWithId("ipAddress")
    local input2 = lobby:elementWithId("port")
    input1:validate(true)
    input2:validate(true)
    if input1.valid and input2.valid then
        local address = input1:value()
        local port = tonumber(input2:value())
        lobby:elementWithId("connectionSpinner").visible = true
        client = Client.new(address, port)
        connecting = true
    end
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
        mortar.update(dt)
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
    mortar.draw()
end

function drawDebug()
    love.graphics.setColor(255, 255, 255)
    if DEBUG.showLog then
        log:draw()
    end
end
