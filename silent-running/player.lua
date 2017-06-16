local ROOT_2 = math.sqrt(2)

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

function Player:update(dt)
    for k, v in pairs(self.cooldowns) do
        self.cooldowns[k] = math.max(0, v - dt)
    end

    if not self.isSilentRunning and self.cooldowns.passivePing == 0 then
        self.cooldowns.passivePing = Player.COOLDOWNS.passivePing
        scene.client:send("passive-ping", {self.pos.x, self.pos.y})
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then
        dy = dy - 1
    end
    if love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("s") then
        dy = dy + 1
    end
    if love.keyboard.isDown("d") then
        dx = dx + 1
    end
    if dx ~= 0 and dy ~= 0 then
        dx = dx / ROOT_2
        dy = dy / ROOT_2
    end
    self.vel.x = self.vel.x + dx * Player.ACCELLERATION ^ dt
    self.vel.y = self.vel.y + dy * Player.ACCELLERATION ^ dt

    self:move(self.vel.x * dt, self.vel.y * dt)

    local friction = Player.FRICTION
    local epsilon  = Player.EPSILON
    if love.keyboard.isDown("lshift") then
        friction = friction / 10
        epsilon  = epsilon * 2
    end

    self.vel.x = self.vel.x * friction ^ dt
    if math.abs(self.vel.x) < epsilon then
        self.vel.x = 0
    end
    self.vel.y = self.vel.y * friction ^ dt
    if math.abs(self.vel.y) < epsilon then
        self.vel.y = 0
    end
end

function Player:move(dx, dy)
    self.lastMove.x = dx
    self.lastMove.y = dy

    self.pos.x = self.pos.x + dx
    self.pos.y = self.pos.y + dy
end

function Player:changeWeapon(weapon)
    self.currentWeapon = weapon
    self.cooldowns[self.currentWeapon] = Player.COOLDOWNS[self.currentWeapon]
end

function Player:fireWeapon(dx, dy)
    if self.currentWeapon == nil then return end
    if self.cooldowns[self.currentWeapon] == nil then return end
    if self.cooldowns[self.currentWeapon] > 0 then return end

    self.cooldowns[self.currentWeapon] = Player.COOLDOWNS[self.currentWeapon]

    if self.currentWeapon == "torpedo" then
        if dx > 0 then
            scene.client:send("torpedo", {self.pos.x + 32, self.pos.y + 40,  1})
        elseif dx < 0 then
            scene.client:send("torpedo", {self.pos.x + 32, self.pos.y + 40, -1})
        end
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
    scene.client:send("noise", {self.pos.x, self.pos.y, loudness})
    scene.screen:shake(0.5, 8, 0.3) -- TODO: test this and tweak until it feels right
end

function Player:damage(damage, impactX, impactY)
    self.vel.x = self.vel.x + (impactX or 0)
    self.vel.y = self.vel.y + (impactY or 0)
    self.health = self.health - damage
    if self.health < 0 then
        self:die()
    end
end

function Player:die()
    scene.client:send("death", {self.pos.x, self.pos.y})
    scene.player = nil
end

function Player:draw(ox, oy)
    love.graphics.rectangle("fill", self.pos.x - 32 + (ox or 0), self.pos.y - 16 + (oy or 0), 64, 32)
end

return Player