DEBUG = {
    -- client
    keepPongs       = false,
}

---------------
-- Libraries --
---------------
require 'helpers.functional'
require 'helpers.coroutine'

local tlo    = require 'lib.tlo'

---------------
-- Constants --
---------------
DEFAULT_PORT = 22122
T = tlo.localise

-------------
-- Classes --
-------------
Server = require 'scn_server'
Client = require 'scn_client'
Title  = require 'scn_title'
Log    = require 'log'

function love.load(args)
    applySettings()
    log = Log.new()
    scene = Title.new()
end

function createDefaultSettings()
    settingsFile = love.filesystem.newFile(".settings")
    settingsFile:open('w')
    settingsFile:write("return {")
    settingsFile:write("    graphics = {")
    settingsFile:write("        resolution = { 960, 640 },")
    settingsFile:write("        vsync = true,")
    settingsFile:write("        fullscreen = 0,")
    settingsFile:write("    },")
    settingsFile:write("    language = \"en-UK\",")
    settingsFile:write("}")
    settingsFile:close()
    
    love.filesystem.createDirectory("lang")
    defaultLanguageFile = love.filesystem.newFile("lang/en-UK")
    defaultLanguageFile:open("w")
    defaultLanguageFile:write("return {}")
    defaultLanguageFile:close()

    progressFile = love.filesystem.newFile("progress")
    progressFile:open('w')
    progressFile:write("return {")
    progressFile:write("    stats = {")
    progressFile:write("        tutorial = {")
    progressFile:write("        },")
    progressFile:write("    },")
    progressFile:write("}")
    progressFile:close()
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
        tlo.setLanguage(settings.language)
    end
end

function love.textinput(text)
    if scene and scene.textinput then
        scene:textinput(text)
    end
end

function love.keypressed(key, isRepeat)
    if scene and scene.keypressed then
        scene:keypressed(key, isRepeat)
    end
end

function love.mousepressed(mx, my, key)
    if scene and scene.mousepressed then
        scene:mousepressed(mx, my, key)
    end
end

function love.mousereleased(mx, my, key)
    if scene and scene.mousereleased then
        scene:mousereleased(mx, my, key)
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    if scene then
        scene:update(dt)
    end
    log:update()
end

function love.draw()
    if scene then
        scene:draw()
    end
end
