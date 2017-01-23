---------------
-- Constants --
---------------
ROOT_2 = math.sqrt(2)

PORT   = 22122

---------------
-- Libraries --
---------------
local sock = require "sock"

-------------
-- Classes --
-------------
local Log    = require "log"
local Rock   = require "rock"
local Player = require "player"

function love.load()
    player = Player.new(256, 256)
    log = Log.new()
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
    ----------------------
    -- Server Variables --
    ----------------------
    server = sock.newServer("*", PORT)


    server:on("connect", function(data, client)
        log:add("Connected to " .. tostring(client))
        server:sendToAll("image", "Floop de loop")
        -- client:send("image", "Hello there!")
    end)

    log:add("Started server.")
end

function startClient()
    client = sock.newClient("localhost", PORT)

    client:on("image", function(data)
        log:add("Recieved '" .. tostring(data) .. "' from server.")
    end)

    client:connect()

    log:add("Connected to localhost")
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

    log:update()
end

function love.draw()
    player:draw()
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

    log:draw()
end
