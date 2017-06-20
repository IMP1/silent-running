local ROOT_2 = math.sqrt(2)

local Noise   = require 'noise'
local Torpedo = require 'torpedo'

local Player = {}
Player.__index = Player

Player.ACCELLERATION = 256
Player.FRICTION = 0.99
Player.EPSILON = 0.5
Player.COOLDOWNS = {
    passivePing = 1,
    torpedo = 1,
}

function Player.new(x, y)
    local this = {}
    setmetatable(this, Player)
    this.pos = { x = x, y = y }
    this.vel = { x = 0, y = 0 }
    this.lastMove = { x = 0, y = 0 }
    this.health = 100
    this.cooldowns = {}
    for k, v in pairs(Player.COOLDOWNS) do
        this.cooldowns[k] = v
    end
    this.isSilentRunning = true
    this:changeWeapon("torpedo")
    return this
end

function Player:input(dx, dy, braking)
    if dx ~= 0 and dy ~= 0 then
        dx = dx / ROOT_2
        dy = dy / ROOT_2
    end

    self.vel.x = self.vel.x + dx -- * Player.ACCELLERATION
    self.vel.y = self.vel.y + dy -- * Player.ACCELLERATION

    -- self.pos.x = self.pos.x + dx
    -- self.pos.y = self.pos.y + dy

    self.lastMove.x = dx
    self.lastMove.y = dy
    self.isBraking  = braking
end

function Player:update(dt)   
    self:simulate(dt)
    if not self.isSilentRunning and self.cooldowns.passivePing == 0 then
        self.cooldowns.passivePing = Player.COOLDOWNS.passivePing
        scene:sendSound(self.pos.x, self.pos.y, Noise.scan)
    end
end

function Player:simulate(dt)
    for k, v in pairs(self.cooldowns) do
        self.cooldowns[k] = math.max(0, v - dt)
    end
    
    local friction = Player.FRICTION
    local epsilon  = Player.EPSILON
    if self.isBraking then
        friction = friction / 10
        epsilon  = epsilon * 2
    end

    self.pos.x = self.pos.x + self.vel.x * dt
    self.pos.y = self.pos.y + self.vel.y * dt

    self.vel.x = self.vel.x * friction ^ dt
    if math.abs(self.vel.x) < epsilon then
        self.vel.x = 0
    end
    self.vel.y = self.vel.y * friction ^ dt
    if math.abs(self.vel.y) < epsilon then
        self.vel.y = 0
    end
end

function Player:changeWeapon(weapon)
    self.currentWeapon = weapon
    self.cooldowns[self.currentWeapon] = Player.COOLDOWNS[self.currentWeapon]
end

function Player:resetCooldown(cooldown)
    if cooldown == nil                 then return end
    if self.cooldowns[cooldown] == nil then return end
    if self.cooldowns[cooldown] > 0    then return end

    self.cooldowns[cooldown] = Player.COOLDOWNS[cooldown]
end

function Player:fireWeapon(dx, dy)
    self:resetCooldown(self.currentWeapon)

    if self.currentWeapon == "torpedo" then
        local direction
        if dx > 0 then
            direction = 1
        elseif dx < 0 then
            direction = -1
        else
            direction = 1
        end
        local torpedo = Torpedo.new(client, self.pos.x + 32, self.pos.y + 40, direction)
        table.insert(scene.missiles, torpedo)
    end
end

function Player:crash(x, y)
    local speed = math.sqrt(self.vel.x * self.vel.x + self.vel.y * self.vel.y)
    local damage = speed
    local loudness = damage * 2
    self.pos.x = x
    self.pos.y = y
    self.vel.x = -self.vel.x * 0.2
    self.vel.y = -self.vel.y * 0.2
    self:damage(damage)
    scene:sendSound(self.pos.x, self.pos.y, Noise.general, loudness)
    scene.screen:shake(0.5, 8, 0.3) -- TODO: test this and tweak until it feels right
end

function Player:damage(damage, impactX, impactY)
    self.vel.x = self.vel.x + (impactX or 0)
    self.vel.y = self.vel.y + (impactY or 0)
    self.health = self.health - damage
    if self.health <= 0 then
        self:die()
    end
end

function Player:die()
    scene:removePlayer(self)
end

function Player:draw(ox, oy)
    love.graphics.rectangle("fill", self.pos.x - 32 + (ox or 0), self.pos.y - 16 + (oy or 0), 64, 32)
end

return Player