DEBUG = {
    showMap       = false,
    showLog       = false,
    showPlayers   = true,
    showVelocity  = true,
    showPings     = true,
    showTriangles = true,
    keepPongs     = false,
    showCommands  = false,
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
local LevelGenerator = require 'level_generator'
local Log            = require 'log'
local Rock           = require 'rock'
local Player         = require 'player'
local Ping           = require 'ping'
local PongGhost      = require 'pong_ghost'

function love.load()
    log = Log.new()
end

function love.keypressed(key, isRepeat)
    if not server and not client then 
        if key == "1" then
            start("server")
        elseif key == "2" then
            start("client")
        end
        return
    end

    if DEBUG then
        if key == "m" then
            DEBUG.showMap = not DEBUG.showMap
        end
        if key == "p" then
            DEBUG.showPlayers = not DEBUG.showPlayers
        end
        if key == "." then
            DEBUG.showPings = not DEBUG.showPings
        end
        if key == "v" then
            DEBUG.showVelocity = not DEBUG.showVelocity
        end
        if key == "r" then
            DEBUG.showTriangles = not DEBUG.showTriangles
        end
        if key == "tab" then
            DEBUG.showLog = not DEBUG.showLog
        end
        if key == "g" then
            DEBUG.keepPongs = not DEBUG.keepPongs
        end
        if key == "`" then
            DEBUG.showCommands = not DEBUG.showCommands
        end
    end
end

function love.mousepressed(mx, my, key)
    print(mx, my, key)
    if player and key == 1 then
        local x = player.pos.x
        local y = player.pos.y
        local dx = mx - x
        local dy = my - y
        local magnitude = math.sqrt(dx * dx + dy * dy)
        local pingSpeed = 256
        dx = pingSpeed * dx / magnitude
        dy = pingSpeed * dy / magnitude
        client:send("active-ping", {x, y, dx, dy})
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
    server:setSerialization(bitser.dumps, bitser.loads)

    playerCount = 0
    players     = {}

    activePings = {}

    levelWidth  = 960
    levelHeight = 640
    levelSeed   = 1337
    level       = LevelGenerator.generate(960, 640, levelSeed)

    ----------------------
    -- Server Callbacks --
    ----------------------
    server:on("connect", function(data, client)
        playerCount = playerCount + 1
        log:add("Added client.")
        local x = playerCount * 96
        local y = 256
        players[client] = Player.new(x, y)
        client:send("init", {x, y})
        client:send("level", {levelWidth, levelHeight, levelSeed})
    end)

    server:on("active-ping", function(kinematicState, client)
        log:add("Recieved active ping from client at " .. kinematicState[1] .. ", " .. kinematicState[2] .. ".")
        local newPing = Ping.new(unpack(kinematicState))
        table.insert(activePings, newPing)
        -- add to active pingsList, and return pongs on any bounces
    end)

    server:on("passive-ping", function(position, client)
        -- take an image around the pong location and return that
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
    client:setSerialization(bitser.dumps, bitser.loads)
    player = nil
    map = nil
    pongGhosts = nil
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    client:on("connect", function(data)
        log:add("Connected to localhost")
    end)

    client:on("init", function(playerPosition)
        log:add("Recieved '" .. playerPosition[1] .. ", " .. playerPosition[2] .. "' from server.")
        player = Player.new(unpack(playerPosition))
        pongGhosts = {}
    end)

    client:on("level", function(levelSetup)
        log:add("Recieved level seed from server.")
        map = LevelGenerator.generate(unpack(levelSetup))
    end)

    client:on("pong", function(pongPosition)
        log:add("Recieved '" .. pongPosition[1] .. ", " .. pongPosition[2] .. " from server.")
        local pong = PongGhost.new(unpack(pongPosition))
        table.insert(pongGhosts, pong)
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

    for i = #activePings, 1, -1 do
        activePings[i]:update(dt)
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
    if DEBUG then
        drawDebug()
    end

    love.graphics.setColor(255, 255, 255)

    if player then
        player:draw()
    else
        love.graphics.printf("WAITING", 0, 96, love.graphics.getWidth(), "center")
    end

    if pongGhosts then
        for _, p in pairs(pongGhosts) do
            p:draw()
        end 
    end
end

function drawDebug()
    love.graphics.setColor(128, 255, 255, 128)
    if player and DEBUG.showVelocity then
        love.graphics.print(tostring(player.vel.x), 0, 0)
        love.graphics.print(tostring(player.vel.y), 0, 16)
    end
    if activePings and DEBUG.showPings then
        for _, p in pairs(activePings) do
            p:draw()
        end
    end
    if map and DEBUG.showMap then
        map:draw()
    end
    if map and DEBUG.showTriangles then
        for _, rock in pairs(map.rocks) do
            for _, tri in pairs(rock.triangles) do
                love.graphics.polygon("line", unpack(tri))
            end
        end
    end
    if log and DEBUG.showLog then
        log:draw()
    end
    if DEBUG.showCommands then
        love.graphics.print("M  : toggle map objects", 0, love.graphics.getHeight() - 24 * 1)
        love.graphics.print(".  : toggle pings",       0, love.graphics.getHeight() - 24 * 2)
        love.graphics.print("V  : toggle velocity",    0, love.graphics.getHeight() - 24 * 3)
        love.graphics.print("R  : toggle triangles",   0, love.graphics.getHeight() - 24 * 4)
        love.graphics.print("TAB: toggle log",         0, love.graphics.getHeight() - 24 * 5)
        love.graphics.print("G  : toggle keep pongs",  0, love.graphics.getHeight() - 24 * 6)
        love.graphics.print("`  : toggle commands",    0, love.graphics.getHeight() - 24 * 7)
    end
end
