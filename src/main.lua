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
        local image = love.filesystem.newFileData("hello.png")
        -- server:sendToAll("image", image)
        client:send("image", image)
    end)
end

function startClient()
    client = sock.newClient("localhost", PORT)

    client:connect()

    client:on("image", function(data)
        local file = love.filesystem.newFileData(data, "")
        receivedImage = love.image.newImageData(file)
        receivedImage = love.graphics.newImage(receivedImage)
    end)
end

function love.update(dt)
    if running then
        player:update(dt)
    end
end

function love.draw()
    player:draw()
end