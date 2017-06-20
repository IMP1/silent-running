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
local Noise          = require 'noise'
local Camera         = require 'camera'
local Screen         = require 'screen'

--------------------------------------------------------------------------------
-- # Client 
--------------
-- Handles the client side of the game for the server. Handles user input and 
-- sends it to the server. Recieves messages from the server and displays 
-- ping responses and crashes to the user.
--------------------------------------------------------------------------------
local Client = {}
setmetatable(Client, SceneBase)
Client.__index = Client

function Client.new(address, port)
    local this = SceneBase.new("server")
    setmetatable(this, Client)
    this.client = sock.newClient(address, port or DEFAULT_PORT)
    this:setup()
    return this
end

function Client:setup()
    ----------------------
    -- Client Variables --
    ----------------------
    self.client:setSerialization(bitser.dumps, bitser.loads)
    
    self.player = nil
    self.map = nil
    self.camera = Camera.new()
    self.sounds = {}
    self.screen = Screen.new()
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    self.client:on("connect", function(data)
    end)

    self.client:on("underway", function(data)
        scene:gameUnderway()
    end)

    self.client:on("joined", function(data)
        log:add("Connected to server.")
        scene:connectionAchieved()
    end)

    self.client:on("disconnect", function(data)
        log:add("Disconnected from server.")
        scene:connectionFailed()
    end)

    self.client:on("init", function(playerPosition)
        log:add("Recieved player position (" .. playerPosition[1] .. ", " .. playerPosition[2] .. ") from server.")
        self.player = Player.new(unpack(playerPosition))
        self.camera:centreOn(unpack(playerPosition))
    end)

    self.client:on("level", function(levelParameters)
        log:add("Recieved level parameters from server.")
        log:add(tostring(levelParameters))
        self.map = LevelGenerator.generate(unpack(levelParameters))
    end)

    self.client:on("begin", function()
        log:add("Recieved begin command from server.")
        scene:start()
    end)

    self.client:connect()
    self.client:setTimeout(nil, nil, 6000)
end

function Client:start()
    self.client:on("pong", function(noiseData)
        log:add("Recieved pong ghost (" .. noiseData[1] .. ", " .. noiseData[2] .. ") from server.")
        local pong = Noise.new(unpack(noiseData))
        table.insert(self.sounds, pong)
    end)

    self.client:on("player-update", function(playerData)
        self.player.pos.x = playerData[1]
        self.player.pos.y = playerData[2]
        self.player.vel.x = playerData[3]
        self.player.vel.y = playerData[4]
        self.player.cooldowns.passivePing = playerData[5]
        self.player.cooldowns.torpedo     = playerData[6]
    end)

    self.client:on("crash", function(crashData)
        log:add("Recieved crash (" .. crashData[1] .. ", " .. crashData[2] .. ") from server.")
        self.player:crash(unpack(crashData))
    end)

    self.client:on("sound", function(soundData)
        log:add("Heard sound (" .. soundData[1] .. ", " .. soundData[2] .. ") from server.")
        local sound = Noise.new(unpack(soundData))
        table.insert(self.sounds, sound)
    end)

    self.client:on("damage", function(damageData)
        log:add("Recieved " .. damageData[3] .. " damage!")
        -- TODO: this should be handled by the server:
        local dx = self.player.pos.x - damageData[1]
        local dy = self.player.pos.y - damageData[2]
        local d  = 32
        if dx*dx + dy*dy < d*d then
            self.player:damage(damageData[3], damageData[4], damageData[5])
        end
    end)

    self.started = true
end

function Client:connectionFailed()
    print("uh oh")
end

function Client:keypressed(key, isRepeat)
    if not self.started then return end
    if key == "space" then
        self.player.isSilentRunning = not self.player.isSilentRunning
        self.client:send("silent-running", {self.player.isSilentRunning})
    end
    if key == "t" then
        self.client:send("change-weapon", {"torpedo"})
        self.player:changeWeapon("torpedo")
        self:resetCooldown(player.currentWeapon)
    end
end

function Client:mousepressed(mx, my, key)
    if not self.started then return end
    local wx, wy = self.camera:toWorldPosition(mx, my)
    if key == 2 then
        local x = self.player.pos.x
        local y = self.player.pos.y
        local dx = wx - x
        local dy = wy - y
        self.client:send("fire-weapon", {dx, dy})
        self:resetCooldown(player.currentWeapon)
    end
    if key == 1 then
        local x = self.player.pos.x
        local y = self.player.pos.y
        local dx = wx - x
        local dy = wy - y
        local r = math.atan2(dy, dx)
        local pingSpeed = 256
        dx = math.cos(r)
        dy = math.sin(r)
        x = x + dx * 26 -- TODO: change 26 for player size + epsilon
        y = y + dy * 26 -- TODO: change 26 for player size + epsilon
        dx = dx * pingSpeed
        dy = dy * pingSpeed
        self.client:send("active-ping", {x, y, dx, dy})
    end
end

function Client:update(dt)
    self.client:update()
    if not self.started then return end

    local dx, dy = 0, 0
    if love.keyboard.isDown(settings.controls.moveUp) then
        dy = dy - Player.ACCELLERATION ^ dt
    end
    if love.keyboard.isDown(settings.controls.moveLeft) then
        dx = dx - Player.ACCELLERATION ^ dt
    end
    if love.keyboard.isDown(settings.controls.moveDown) then
        dy = dy + Player.ACCELLERATION ^ dt
    end
    if love.keyboard.isDown(settings.controls.moveRight) then
        dx = dx + Player.ACCELLERATION ^ dt
    end
    local brake = love.keyboard.isDown(settings.controls.brake)
    self.client:send("move", {dx, dy, brake})

    self.player:input(dx, dy)
    self.player:simulate(dt)
    self.camera:centreOn(self.player.pos.x, self.player.pos.y)

    if self.screen then
        self.screen:update(dt)
    end

    if self.sounds then
        for i = #self.sounds, 1, -1 do
            self.sounds[i]:update(dt)
            if self.sounds[i].opacity <= 0 then
                table.remove(self.sounds, i)
                -- TODO: make sure this is happening (have count of pong ghosts on debugging text)
                print("removing pong ghost")
            end
        end
    end
end

function Client:draw()
    love.graphics.setColor(255, 255, 255)

    if self.screen then
        self.screen:set()
    end
    if self.camera then
        self.camera:set()
    end

    love.graphics.setColor(64, 128, 128)
    if self.sounds then
        for _, p in pairs(self.sounds) do
            p:draw()
        end 
    end

    love.graphics.setColor(255, 255, 255)
    if self.player then
        self.player:draw()
        love.graphics.setColor(255, 255, 255, 32)
        local r = math.atan2(self.player.lastMove.y, self.player.lastMove.x)
        local ox = self.player.pos.x
        local oy = self.player.pos.y
        love.graphics.line(ox, oy, ox + 32 * math.cos(r), oy + 32 * math.sin(r))
        -- TODO: have better way of indicating current direction of motion.

    end

    if self.camera then
        self.camera:unset()
    end
    if self.screen then
        self.screen:unset()
    end

    love.graphics.setColor(255, 255, 255)
    if self.player then
        if self.player.currentWeapon then
            if self.player.cooldowns[self.player.currentWeapon] > 0 then
                love.graphics.setColor(192, 192, 192)
            else
                love.graphics.setColor(255, 255, 255)
            end
            love.graphics.print(self.player.currentWeapon, 360, 0)
            love.graphics.rectangle("line", 360, 24, 100, 8)
            local n = Player.COOLDOWNS[self.player.currentWeapon]
            local i = self.player.cooldowns[self.player.currentWeapon]
            local w = 100 * (n - i) / n
            love.graphics.rectangle("fill", 360, 24, w, 8)
            
        end
        -- TODO: draw better HUD
        love.graphics.print(tostring(self.player.health), 0, 0)
        love.graphics.print(tostring(self.player.pos.x) .. "," .. tostring(self.player.pos.y), 0, 16)
        love.graphics.print(tostring(self.player.vel.x) .. "," .. tostring(self.player.vel.y), 0, 32)
        local state = "passive"
        if self.player.isSilentRunning then state = "silent running" end
        love.graphics.print(state, 0, 48)
    end

    if not self.started then
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
        love.graphics.printf(T"Waiting for game to begin", 0, 128, love.graphics.getWidth(), "center")
    end

    -- love.graphics.print(self.client:getState(), 0, 0)
end

return Client