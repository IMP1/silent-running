---------------
-- Constants --
---------------
PORT = 22122

---------------
-- Libraries --
---------------
local bitser = require "lib.bitser"
local sock   = require "lib.sock"

local LevelGenerator = require 'level_generator'
local Player         = require 'player'

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
    self.level = LevelGenerator.generate(640, 640, 1337)
    
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
        self.players[client]:move(offset.x, offset.y)
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
    love.graphics.setColor(128, 255, 255, 128)
    if DEBUG.showPlayers then
        for _, p in pairs(self.players) do
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
    self.level:draw()

    if DEBUG.showTriangles then
        for _, rock in pairs(self.level.rocks) do
            for _, tri in pairs(rock.triangles) do
                love.graphics.polygon("line", unpack(tri))
            end
        end
    end
    if DEBUG.showCommands then
        love.graphics.print("M  : toggle map objects", 0, love.graphics.getHeight() - 24 * 1)
        love.graphics.print(".  : toggle pings",       0, love.graphics.getHeight() - 24 * 2)
        love.graphics.print("R  : toggle triangles",   0, love.graphics.getHeight() - 24 * 4)
        love.graphics.print("TAB: toggle log",         0, love.graphics.getHeight() - 24 * 5)
        love.graphics.print("`  : toggle commands",    0, love.graphics.getHeight() - 24 * 7)
    end
end

return Server