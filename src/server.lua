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
    self.activePings = {}
    self.level = LevelGenerator.generate(640, 640, 1649)
    
    self.server:on("connect", function(data, client)
        self.playerCount = self.playerCount + 1
        log:add("Added client.")
        local x = self.playerCount * 96
        local y = 256
        self.players[client] = Player.new(x, y)
        client:send("init", {x, y})
        client:send("level", self.level.params)
    end)

    self.server:on("active-ping", function(kinematicState, client)
        local newPing = Ping.new(unpack(kinematicState))
        table.insert(self.activePings, newPing)
        -- add to active pingsList, and return pongs on any bounces
    end)

    self.server:on("passive-ping", function(position, client)
        -- take an image around the pong location and return that
    end)

    self.server:on("move", function(offset, client)
        self:movePlayer(client, unpack(offset))
    end)

    log:add("Started server.")
end

function Server:movePlayer(client, dx, dy)
    local player = self.players[client]
    player:move(dx, dy)
    if not self.level:isPassable(player.pos.x, player.pos.y) then
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
end

function Server:draw()
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