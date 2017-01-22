---------------
-- Constants --
---------------
ROOT_2 = math.sqrt(2)
DEBUG_TEXT = {"DEBUG"}

PORT   = 22122

---------------
-- Libraries --
---------------
local sock = require "sock"

-------------
-- Classes --
-------------
local Rock   = require "rock"
local Player = require "player"

function love.load()
    player = Player.new(256, 256)
    level = love.filesystem.load("level.lua")()
    running = false
end

function love.keypressed(key, isRepeat)
    if key == "1" then
        start("server")
    elseif key == "2" then
        start("client")
    end
end

function start(role)
    if role == "server" then
        startServer()
        startClient()
    elseif role == "client" then
        startClient()
    end
    running = true
end

function startServer()
    server = sock.newServer("*", PORT)

    server:on("connect", function(data, client)
        table.insert(DEBUG_TEXT, "Connected to " .. tostring(client))
        server:sendToAll("image", "Floop de loop")
        -- client:send("image", "Hello there!")
    end)
    table.insert(DEBUG_TEXT, "Started server.")
end

function startClient()
    client = sock.newClient("localhost", PORT)

    client:connect()

    client:on("image", function(data)
        table.insert(DEBUG_TEXT, "Recieved '" .. tostring(data) .. "' from server.")
    end)
    table.insert(DEBUG_TEXT, "Connected to localhost")
end

function love.update(dt)
    if running then
        player:update(dt)
    end
    if server then
        server:update()
    end
    if client then
        client:update()
    end
end

function love.draw()
    player:draw()
    for i, line in pairs(DEBUG_TEXT) do
        love.graphics.printf(line, 0, (i-1) * 16, love.graphics.getWidth(), "right")
    end
    local status = ""
    if not running then
        status = "PAUSED"
    elseif server then
        status = "SERVER"
    elseif client then
        status = "CLIENT"
    else
        status = "???"
    end
    
    love.graphics.printf(status, 0, 96, love.graphics.getWidth(), "center")
end