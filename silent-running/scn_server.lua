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

 
function findClientIPAddress()
    local http = require("socket.http")

    local getipScriptURL = "http://myip.dnsomatic.com/"  --php script on my server
    local DeviceIP
    
    function ipListener(event)
        if not event.isError and event.response ~= "" then
            DeviceIP = event.response 
            print("DeviceIP:"..DeviceIP)
        end
    end
    
    body, status, content = http.request(getipScriptURL)
    if status >= 200 and status < 300 then
        return body
    else
        return nil
    end
end

function Server.new(port)
    local this = {}
    setmetatable(this, Server)
    this.port = port or DEFAULT_PORT
    this:start()
    return this
end

function Server:start()
    self.publicIp    = findClientIPAddress()
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
    self:showCommands()
    
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
    self:fadeIn()
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

function Server:hideCommands()
    DEBUG.showCommands = false
    self.commands = self.layouts.commandsHidden
end

function Server:showCommands()
    DEBUG.showCommands = true
    self.commands = self.layouts.commands
end

function Server:keypressed(key, isRepeat)
    self.commands:keypressed(key, isRepeat)
    if DEBUG and key == "`" then
        DEBUG.showCommands = not DEBUG.showCommands
    end
end

function Server:mousepressed(mx, my, key)
    self.commands:mousepressed(mx, my, key)
end

function Server:mousereleased(mx, my, key)
    self.commands:mousereleased(mx, my, key)
end

function Server:update(dt)
    local mx, my = love.mouse.getPosition()

    self.server:update()

    self.commands:update(dt, mx, my)

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

function Server:draw()
    love.graphics.setColor(255, 255, 255)

    if self.camera then
        self.camera:set()
    end

    if self.level and DEBUG.showMap then
        love.graphics.setColor(128, 255, 255, 128)
        self.level:drawMap()
    end

    if self.level and DEBUG.showMapObjects then
        love.graphics.setColor(128, 255, 255, 128)
        self.level:drawMapObjects()
    end

    if self.level and DEBUG.showGameObjects then
        love.graphics.setColor(255, 255, 255)
        self.level:drawGameObjects()
    end

    if self.camera then
        self.camera:unset()
    end

    love.graphics.setColor(255, 255, 255)

    if DEBUG.showServerInfo then
        self.info:draw()
    end

    self.commands:draw()
end

return Server