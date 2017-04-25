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

local Client = {}
Client.__index = Client

function Client.new()
    local this = {}
    setmetatable(this, Client)
    this:start()
    return this
end

function Client:start()
    ----------------------
    -- Client Variables --
    ----------------------
    self.client = sock.newClient("localhost", PORT)
    self.client:setSerialization(bitser.dumps, bitser.loads)
    self.player = nil
    self.map = nil
    self.pongGhosts = nil
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    self.client:on("connect", function(data)
        log:add("Connected to localhost")
    end)

    self.client:on("init", function(playerPosition)
        log:add("Recieved '" .. playerPosition[1] .. ", " .. playerPosition[2] .. "' from server.")
        self.player = Player.new(unpack(playerPosition))
        self.pongGhosts = {}
    end)

    self.client:on("level", function(level)
        log:add("Recieved level from server.")
        log:add(tostring(level))
        self.map = LevelGenerator.generate(unpack(level))
    end)

    self.client:on("pong", function(pongGhost)
        log:add("Recieved '" .. tostring(pongGhost) .. "' from server.")
        table.insert(pongGhosts, pongGhost)
    end)

    self.client:connect()
end

function Client:keypressed(key, isRepeat)
    if DEBUG then
        if key == "v" then
            DEBUG.showVelocity = not DEBUG.showVelocity
        end
        if key == "g" then
            DEBUG.keepPongs = not DEBUG.keepPongs
        end
        if key == "tab" then
            DEBUG.showLog = not DEBUG.showLog
        end
        if key == "`" then
            DEBUG.showCommands = not DEBUG.showCommands
        end
    end
end

function Client:mousepressed(mx, my, key)
    if key == 1 then
        local x = self.player.pos.x
        local y = self.player.pos.y
        local dx = mx - x
        local dy = my - y
        local magnitude = math.sqrt(dx * dx + dy * dy)
        local pingSpeed = 256
        dx = pingSpeed * dx / magnitude
        dy = pingSpeed * dy / magnitude
        self.client:send("active-ping", {x, y, dx, dy})
    end
end

function Client:update(dt)
    self.client:update()
    if self.player then
        self.player:update(dt)
        self.client:send("move", self.player.lastMove)
    end
    if self.pongGhosts then
        for i = #self.pongGhosts, 1, -1 do
            self.pongGhosts[i]:update(dt) -- TODO: have pongGhost class
            -- TODO: pongGhost class will have a draw function and opacity levels.
            if self.pongGhosts[i].opacity == 0 then
                table.remove(self.pongGhosts, i)
            end
        end
    end
end

function Client:draw()
    love.graphics.setColor(255, 255, 255)
    if self.player then
        self.player:draw()
    end

    if self.pongGhosts then
        for _, p in pairs(self.pongGhosts) do
            p:draw()
        end 
    end

    if DEBUG.showVelocity and self.player then
        love.graphics.print(tostring(self.player.vel.x), 0, 0)
        love.graphics.print(tostring(self.player.vel.y), 0, 16)
    end
    if DEBUG.showCommands then
        love.graphics.print("V  : toggle velocity",    0, love.graphics.getHeight() - 24 * 3)
        love.graphics.print("TAB: toggle log",         0, love.graphics.getHeight() - 24 * 5)
        love.graphics.print("G  : toggle keep pongs",  0, love.graphics.getHeight() - 24 * 6)
        love.graphics.print("`  : toggle commands",    0, love.graphics.getHeight() - 24 * 7)
    end
end

return Client