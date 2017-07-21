---------------
-- Libraries --
---------------
local bitser = require "lib.bitser"
local sock   = require "lib.sock"

-------------
-- Classes --
-------------
local SceneBase      = require 'scn_base'
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
setmetatable(Server, SceneBase)
Server.__index = Server
 
function findExternalIPAddress()
    local socket = require 'socket'
    local http   = require 'socket.http'
    local ltn12  = require 'ltn12'

    local t = {}
    response = http.request({
        url = "http://myip.dnsomatic.com/", 
        create = function()
            local req_sock = socket.tcp()
            req_sock:settimeout(5)
            return req_sock
        end,
        sink = ltn12.sink.table(t)
    })

    if response == 1 then
        return table.concat(t)
    else
        return "0.0.0.0"
    end
end

function Server.new(port)
    local this = SceneBase.new("server")
    setmetatable(this, Server)
    this.port = port or DEFAULT_PORT
    this:setup()
    return this
end

function Server:setup()
    self.publicIp    = findExternalIPAddress()
    self.layouts     = love.filesystem.load("layouts.lua")().server
    self.server      = sock.newServer("*", self.port)
    self.server:setSerialization(bitser.dumps, bitser.loads)
    self.playerCount = 0
    self.players     = {}
    self.missiles    = {}
    self.activePings = {}
    self.level       = LevelGenerator.generate(640, 640, 1649)
    self.camera      = Camera.new()
    self.info        = self.layouts.info
    self.beginButton = self.layouts.begin
    self.started     = false
    self.timer       = 0
    self.show        = {
        map         = false,
        mapObjects  = false,
        gameObjects = false,
        serverInfo  = true,
        playerInfo  = false,
        log         = false,
        commands    = true,
    }
    self:showCommands()

    self.server:on("connect", function(data, client)
        log:add("New connection.")
        self:addPlayer(client)
    end)

    self.server:on("disconnect", function(data, client)
        log:add("Disconection")
        self:removePlayer(client)
    end)

    log:add("Started server.")
    self:fadeIn()
end

function Server:start()
    self.started = true

    self.server:on("active-ping", function(kinematicState, client)
        local player = self.players[client]
        if player.isSilentRunning then
            local newPing = Ping.new(unpack(kinematicState))
            table.insert(self.activePings, newPing)
        end
    end)

    self.server:on("change-weapon", function(weaponData, client) 
        local player = self.players[client]
        player:changeWeapon(unpack(weaponData))
    end)

    self.server:on("fire-weapon", function(directionData, client)
        local player = self.players[client]
        player:fireWeapon(unpack(directionData))
    end)

    self.server:on("silent-running", function(data, client) 
        local player = self.players[client]
        player.isSilentRunning = data[1]
    end)

    self.server:on("move", function(offset, client)
        local player = self.players[client]
        self:updatePlayer(player, unpack(offset))
    end)

    self.server:sendToAll("begin")

    log:add("Started game.")
end

function Server:addPlayer(client)
    if self.started then
        client:send("underway")
        client:disconnectLater()
        return
    end
    client:send("joined", {x, y})
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

function Server:sendPing(x, y)
    self:sendSound(x, y, Noise.scan)
end

function Server:sendSound(x, y, soundType, sizeScale)
    local size         = soundType.RADIUS * (sizeScale or 1)
    local imageData    = scene.level:getImageData(x, y, size)
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

function Server:updatePlayer(player, dx, dy, braking)
    player:input(dx, dy, braking)
end

function Server:removePlayer(player)
    local client
    for c, p in pairs(self.players) do
        if p == player then
            client = c
        end
    end
    if client and self.players[client] then
        print("sending death to client")
        client:send("death")
        print("removing player from list")
        self.players[client] = nil
    end
    -- TODO: test this out and posisbly handle this better.
end

function Server:hideCommands()
    self.show.commands = false
    self.commands = self.layouts.commandsHidden
end

function Server:showCommands()
    self.show.commands = true
    self.commands = self.layouts.commands
end

function Server:keypressed(key, isRepeat)
    self.commands:keypressed(key, isRepeat)
    self.info:keypressed(key, isRepeat)
end

function Server:mousepressed(mx, my, key)
    self.commands:mousepressed(mx, my, key)
    self.info:mousepressed(mx, my, key)
end

function Server:mousereleased(mx, my, key)
    self.commands:mousereleased(mx, my, key)
    self.info:mousereleased(mx, my, key)
end

function Server:update(dt)
    local mx, my = love.mouse.getPosition()

    self.server:update()

    self.commands:update(dt, mx, my)
    self.info:update(dt, mx, my)

    if self.started then
        self:updateGame(dt, mx, my)
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("up") then
        dy = dy - 128 * dt
    end
    if love.keyboard.isDown("left") then
        dx = dx - 128 * dt
    end
    if love.keyboard.isDown("down") then
        dy = dy + 128 * dt
    end
    if love.keyboard.isDown("right") then
        dx = dx + 128 * dt
    end
    self.camera:move(dx, dy)
end

function Server:updateGame(dt, mx, my)
    self.timer = self.timer + dt

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
    for client, player in pairs(self.players) do
        player:update(dt)
        if not self.level:isPassable(player.pos.x, player.pos.y, player) then
            local oldX = player.pos.x - player.lastMove.x
            local oldY = player.pos.y - player.lastMove.y
            if not self.level:isPassable(oldX, oldY) then
                -- something has gone wrong. cheating?
                player:crash(oldX, oldY, client)
            else
                -- TODO: work out crash message 
                --     new position of player (where it was before move), 
                --     damage (function of velocity)
                player:crash(oldX, oldY, client)
            end
        end
        local state = {
            player.pos.x, player.pos.y, 
            player.vel.x, player.vel.y,
            player.cooldowns.passivePing,
            player.cooldowns.torpedo,
        }
        client:send("player-update", state)
    end
end

function Server:draw()
    love.graphics.setColor(255, 255, 255)

    if self.camera then
        self.camera:set()
    end

    if self.level and self.show.map then
        love.graphics.setColor(128, 255, 255, 128)
        self.level:drawMap()
    end

    if self.level and self.show.mapObjects then
        love.graphics.setColor(128, 255, 255, 128)
        self.level:drawMapObjects()
    end

    if self.level and self.show.gameObjects then
        love.graphics.setColor(255, 255, 255)
        self.level:drawGameObjects()
    end

    if self.camera then
        self.camera:unset()
    end

    love.graphics.setColor(255, 255, 255)

    if self.show.serverInfo then
        self.info:draw()
    end

    self.commands:draw()
end

return Server