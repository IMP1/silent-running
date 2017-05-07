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
    self.camera = Camera.new()
    self.sounds = {}
    self.screen = Screen.new()
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    self.client:on("connect", function(data)
        log:add("Connected to server.")
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

    self.client:on("pong", function(noiseData)
        log:add("Recieved pong ghost (" .. noiseData[1] .. ", " .. noiseData[2] .. ") from server.")
        local pong = Noise.new(unpack(noiseData))
        table.insert(self.sounds, pong)
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

    self.client:connect()
end

function Client:keypressed(key, isRepeat)
    if key == "space" then
        self.player.isSilentRunning = not self.player.isSilentRunning
    end
    if key == "t" then
        self.player:changeWeapon("torpedo")
    end
    if DEBUG then
        if key == "v" then
            DEBUG.showPlayerInfo = not DEBUG.showPlayerInfo
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
    local wx, wy = self.camera:toWorldPosition(mx, my)
    if key == 2 then
        local x = self.player.pos.x
        local y = self.player.pos.y
        local dx = wx - x
        local dy = wy - y
        self.player:fireWeapon(dx, dy)
        print("pew pew")
    end
    if self.player.isSilentRunning and key == 1 then
        local x = self.player.pos.x
        local y = self.player.pos.y
        local dx = wx - x
        local dy = wy - y
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
        self.client:send("move", {self.player.lastMove.x, self.player.lastMove.y})
        self.camera:move(self.player.lastMove.x, self.player.lastMove.y)
    end
    if self.screen then
        self.screen:update(dt)
    end
    if self.sounds then
        for i = #self.sounds, 1, -1 do
            self.sounds[i]:update(dt)
            if self.sounds[i].opacity == 0 then
                -- TODO: make sure this is happening (have count of pong ghosts on debugging text)
                table.remove(self.sounds, i)
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
        -- TODO: test camera works
    end

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
        if DEBUG.showPlayerInfo then
            love.graphics.print(tostring(self.player.health), 0, 0)
            love.graphics.print(tostring(self.player.pos.x) .. "," .. tostring(self.player.pos.y), 0, 16)
            love.graphics.print(tostring(self.player.vel.x) .. "," .. tostring(self.player.vel.y), 0, 32)
            local state = "passive"
            if self.player.isSilentRunning then state = "silent running" end
            love.graphics.print(state, 0, 48)
        end
    end
    if DEBUG.showCommands then
        love.graphics.print("V  : toggle velocity",    0, love.graphics.getHeight() - 24 * 3)
        love.graphics.print("TAB: toggle log",         0, love.graphics.getHeight() - 24 * 5)
        love.graphics.print("G  : toggle keep pongs",  0, love.graphics.getHeight() - 24 * 6)
        love.graphics.print("`  : toggle commands",    0, love.graphics.getHeight() - 24 * 7)
    end
end

return Client