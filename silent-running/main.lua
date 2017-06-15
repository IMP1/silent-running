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

-- local bitser = require 'lib.bitser'
-- local sock   = require 'lib.sock'
local tlo    = require 'lib.tlo'

---------------
-- Constants --
---------------
DEFAULT_PORT = 22122
T = tlo.localise

-------------
-- Classes --
-------------
Server = require 'server'
Client = require 'client'
Title  = require 'scn_title'
Log    = require 'log'

function love.load(args)
    applySettings()
    log = Log.new()
    if args[2] == "server" then
        role = Server.new()
    elseif args[2] == "client" then
        role = Client.new(args[3])
    else
        role = Title.new()
    end
end

function applySettings()
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

function love.textinput(text)
    if role and role.textinput then
        role:textinput(text)
    end
end

function love.keypressed(key, isRepeat)
    if role and role.keypressed then
        role:keypressed(key, isRepeat)
    end
end

function love.mousepressed(mx, my, key)
    if role and role.mousepressed then
        role:mousepressed(mx, my, key)
    end
end

function love.mousereleased(mx, my, key)
    if role and role.mousereleased then
        role:mousereleased(mx, my, key)
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    if role then
        role:update(dt)
    end
    log:update()
end

function love.draw()
    if role then
        role:draw()
    end
end
