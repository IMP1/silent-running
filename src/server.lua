---------------
-- Constants --
---------------
PORT = 22122

---------------
-- Libraries --
---------------
local bitser = require "lib.bitser"
local sock   = require "lib.sock"

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
    self.level = love.filesystem.load("level.lua")()
    
    self.server:on("connect", function(data, client)
        self.playerCount = self.playerCount + 1
        log:add("Added client.")
        local x = self.playerCount * 96
        local y = 256
        players[client] = Player.new(x, y)
        client:send("init", {x, y})
        client:send("level", level)
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
        players[client]:move(offset.x, offset.y)
    end)

    log:add("Started server.")
end

function Server:keypressed(key, isRepeat)
    if DEBUG then
        if key == "m" then
            DEBUG.showMap = not DEBUG.showMap
        end
        if key == "p" then
            DEBUG.showPlayers = not DEBUG.showPlayers
        end
        if key == "tab" then
            DEBUG.showLog = not DEBUG.showLog
        end
    end
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
    love.graphics.setColor(128, 255, 255, 128)
    if DEBUG.showPlayers then
        for _, p in pairs(players) do
            if not player or p ~= player then
                p:draw()
            end
        end
    end
    if activePings then
        for _, p in pairs(activePings) do
            p:draw()
        end
    end
    level:draw()
end

return Server