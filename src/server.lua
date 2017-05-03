---------------
-- Libraries --
---------------
local bitser = require "lib.bitser"
local sock   = require "lib.sock"

-------------
-- Classes --
-------------
local LevelGenerator = require 'level_generator'
local Player         = require 'player'
local Ping           = require 'ping'
local Noise          = require 'noise'
local Torpedo        = require 'torpedo'
local Camera         = require 'camera'

--------------------------------------------------------------------------------
-- # Server
--------------
-- Handles the server side of the game for the server. Responds to connections 
-- and shows debugging information. Simulates the game and informs of clients
-- of ping responses and weapon damage.
--------------------------------------------------------------------------------
local Server = {}
Server.__index = Server

function Server.new()
    local this = {}
    setmetatable(this, Server)
    this:start()
    return this
end

function Server:start()
    self.server = sock.newServer("*", PORT)
    self.server:setSerialization(bitser.dumps, bitser.loads)
    self.playerCount = 0
    self.players = {}
    self.missiles = {}
    self.activePings = {}
    self.level = LevelGenerator.generate(640, 640, 1649)
    self.camera = Camera.new()
    
    self.server:on("connect", function(data, client)
        log:add("New connection.")
        self:addPlayer(client)
    end)

    self.server:on("disconnect", function(data, client)
        log:add("Disconection")
        print(data)
        print(client)
    end)

    self.server:on("active-ping", function(kinematicState, client)
        local newPing = Ping.new(unpack(kinematicState))
        table.insert(self.activePings, newPing)
    end)

    self.server:on("passive-ping", function(position, client)
        log:add("Passive ping (" .. position[1] .. ", " .. position[2] ..").")
        -- TODO: check that this is near enough to the players location
        --       or maybe just use the player's location?
        self:sendSound(position[1], position[2], Noise.scan)
    end)

    self.server:on("move", function(offset, client)
        self:movePlayer(client, unpack(offset))
    end)

    self.server:on("noise", function(noiseData, client)
        self:sendSound(noiseData[1], noiseData[2], Noise.general, noiseData[3])
    end)

    self.server:on("death", function(playerData, client)
        self.players[client] = nil
    end)

    self.server:on("torpedo", function(torpedoData, client)
        local torpedo = Torpedo.new(unpack(torpedoData))
        table.insert(self.missiles, torpedo)
    end)

    log:add("Started server.")
end

function Server:addPlayer(client)
    local x = -1
    local y = -1
    while not self.level:isValidStartingPosition(x, y) do
        x = math.random() * self.level.width
        y = math.random() * self.level.height
    end
    self.players[client] = Player.new(x, y)
    client:send("init", {x, y})
    client:send("level", self.level.params)
    self.playerCount = self.playerCount + 1
    log:add("Added new player.")
end

function Server:sendSound(x, y, soundType, sizeScale)
    local size         = soundType.RADIUS * (sizeScale or 1)
    local imageData    = role.level:getImageData(x, y, size)
    local startSize    = soundType.START_RADIUS
    local growSpeed    = soundType.GROW_SPEED
    local fadeSpeed    = soundType.FADE_SPEED
    local startOpacity = soundType.START_OPACITY
    local noiseData = {
        x, 
        y, 
        imageData:getString(), 
        size, 
        startSize, 
        growSpeed, 
        fadeSpeed,
        startOpacity
    }
    self.server:sendToAll("sound", noiseData)
end

function Server:movePlayer(client, dx, dy)
    local player = self.players[client]
    player:move(dx, dy)
    if not self.level:isPassable(player.pos.x, player.pos.y, player) then
        local oldX = player.pos.x - player.lastMove.x
        local oldY = player.pos.y - player.lastMove.y
        if not self.level:isPassable(oldX, oldY) then
            -- something has gone wrong. cheating?
        else
            -- TODO: work out crash message 
            --     new position of player (where it was before move), 
            --     damage (function of velocity)
            client:send("crash", { oldX, oldY })
        end
    end
end

function Server:keypressed(key, isRepeat)
    if DEBUG then
        if key == "m" then
            DEBUG.showMap = not DEBUG.showMap
        end
        if key == "p" then
            DEBUG.showPlayers = not DEBUG.showPlayers
        end
        if key == "r" then
            DEBUG.showTriangles = not DEBUG.showTriangles
        end

        if key == "." then
            DEBUG.showPings = not DEBUG.showPings
        end
        if key == "tab" then
            DEBUG.showLog = not DEBUG.showLog
        end
        if key == "`" then
            DEBUG.showCommands = not DEBUG.showCommands
        end
    end
end

function Server:mousepressed(mx, my, key)

end

function Server:update(dt)
    self.server:update()
    for i = #self.activePings, 1, -1 do
        self.activePings[i]:update(dt)
        if self.activePings[i].finished then
            table.remove(self.activePings, i)
        end
    end
    for i = #self.missiles, 1, -1 do
        self.missiles[i]:update(dt)
        if self.missiles[i].finished then
            table.remove(self.missiles, i)
        end
    end
end

function Server:draw()
    if self.camera then
        self.camera:set()
    end
    -- TODO: test camera

    love.graphics.setColor(255, 255, 255)
    if DEBUG.showPlayers then
        for _, p in pairs(self.players) do
            if not player or p ~= player then
                p:draw()
            end
        end
    end

    if self.activePings and DEBUG.showPings then
        for _, p in pairs(self.activePings) do
            p:draw()
        end
    end

    if self.missiles then
        for _, m in pairs(self.missiles) do
            m:draw()
        end
    end

    if self.level and DEBUG.showMap then
        self.level:draw()
    end

    love.graphics.setColor(255, 255, 255)
    if DEBUG.showTriangles then
        for _, rock in pairs(self.level.rocks) do
            for _, tri in pairs(rock.triangles) do
                love.graphics.polygon("line", unpack(tri))
            end
        end
    end

    if self.camera then
        self.camera:unset()
    end

    if DEBUG.showCommands then
        local w = 256
        local h = 24 * 5
        local x = 0
        local y = love.graphics.getHeight() - h
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.print("M  : [" .. (DEBUG.showMap       and "X" or " ") .. "] toggle map objects", 
                            x + 4, y + 24 * 0 + 4)
        love.graphics.print(".  : [" .. (DEBUG.showPings     and "X" or " ") .. "] toggle pings",       
                            x + 4, y + 24 * 1 + 4)
        love.graphics.print("R  : [" .. (DEBUG.showTriangles and "X" or " ") .. "] toggle triangles",   
                            x + 4, y + 24 * 2 + 4)
        love.graphics.print("TAB: [" .. (DEBUG.showLog       and "X" or " ") .. "] toggle log",         
                            x + 4, y + 24 * 3 + 4)
        love.graphics.print("`  : [" .. (DEBUG.showCommands  and "X" or " ") .. "] toggle commands",    
                            x + 4, y + 24 * 4 + 4)
    else
        local w = 256
        local h = 24 * 1
        local x = 0
        local y = love.graphics.getHeight() - h
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.print("`  : [" .. (DEBUG.showCommands  and "X" or " ") .. "] toggle commands",    
                            x + 4, y + 24 * 0 + 4)
    end
end

return Server