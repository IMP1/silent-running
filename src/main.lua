DEBUG = true

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
    log = Log.new()
    level = love.filesystem.load("level.lua")()
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
end

function startServer()
    ----------------------
    -- Server Variables --
    ----------------------
    server = sock.newServer("*", PORT)
    playerCount = 0
    players = {}
    activePings = {}

    server:on("connect", function(data, client)
        playerCount = playerCount + 1
        log:add("Added client.")
        local x = playerCount * 96
        local y = 256
        players[client] = Player.new(x, y)
        -- server:sendToAll("image", "Floop de loop")
        client:send("init", {x, y})
    end)

    server:on("active-ping", function(kinematicState, client)
        local newPing = Ping.new(unpack(kinematicState))
        table.insert(activePings, newPing)
        -- add to active pingsList, and return pongs on any bounces
    end)

    server:on("passive-ping", function(position, client)
        -- get all objects in the radius from the player
        -- return them all
    end)

    server:on("move", function(offset, client)
        players[client]:move(offset.x, offset.y)
    end)

    log:add("Started server.")
end

function startClient()
    ----------------------
    -- Client Variables --
    ----------------------
    client = sock.newClient("localhost", PORT)
    player = nil
    pongGhosts = nil
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    client:on("connect", function(data)
        log:add("Connected to localhost")
    end)

    client:on("init", function(playerPosition)
        log:add("Recieved '" .. tostring(playerPosition) .. "' from server.")
        player = Player.new(unpack(playerPosition))
        pongGhosts = {}
    end)

    client:on("pong", function(pongGhost)
        log:add("Recieved '" .. tostring(pongGhost) .. "' from server.")
        table.insert(pongGhosts, pongGhost)
    end)

    client:connect()
end

function love.update(dt)
    if server then
        updateServer(dt)
    end
    if client then
        updateClient(dt)
    end

    log:update()
end

function updateServer(dt)
    server:update()
    for o= #activePings, 1, -1 do
        activePings[i]:update(dt) -- TODO: have ping class
        -- TODO: ping class will handle movement, and collisions with players and terrain, and fires 'pong' events to players.
        if activePings[i].finished then
            table.remove(activePings, i)
        end
    end
end

function updateClient(dt)
    client:update()
    if player == nil then return end
    player:update(dt)
    client:send("move", player.lastMove)
    for i = #pongGhosts, 1, -1 do
        pongGhosts[i]:update(dt) -- TODO: have pongGhost class
        -- TODO: pongGhost class will have a draw function and opacity levels.
        if pongGhosts[i].opacity == 0 then
            table.remove(pongGhosts, i)
        end
    end
end

function love.draw()
    if player and players == nil then
        player:draw()
    else
        love.graphics.printf("WAITING", 0, 96, love.graphics.getWidth(), "center")
    end

    if players and DEBUG then
        for _, p in pairs(players) do
            p:draw()
        end
    end

    log:draw()
end
