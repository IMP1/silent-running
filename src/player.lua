local ROOT_2 = math.sqrt(2)

local Player = {}
Player.__index = Player

Player.ACCELLERATION = 256
Player.FRICTION = 0.99
Player.EPSILON = 0.5
Player.PASSIVE_PING_COOLDOWN = 1

function Player.new(x, y)
    local this = {}
    setmetatable(this, Player)
    this.pos = { x = x, y = y }
    this.vel = { x = 0, y = 0 }
    this.lastMove = { x = 0, y = 0 }
    this.health = 100
    this.passivePingTimer = Player.PASSIVE_PING_COOLDOWN
    this.isSilentRunning = true
    return this
end

function Player:update(dt)
    if self.isSilentRunning then
        
    else
        self.passivePingTimer = self.passivePingTimer - dt
        if self.passivePingTimer <= 0 then
            self.passivePingTimer = Player.PASSIVE_PING_COOLDOWN
            role.client:send("passive-ping", {self.pos.x, self.pos.y})
        end
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

    -- TODO: check for collisions

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

function Player:crash(x, y)
    local speed = math.sqrt(self.vel.x * self.vel.x + self.vel.y * self.vel.y)
    local damage = speed
    self.pos.x = x
    self.pos.y = y
    self.vel.x = -self.vel.x * 0.2
    self.vel.y = -self.vel.y * 0.2
    self:damage(damage)
    role.client:send("noise", {self.pos.x, self.pos.y, damage * 2})
end

function Player:damage(damage)
    self.health = self.health - damage
    if self.health < 0 then
        self:die()
    end
end

function Player:die()
    role.client:send("death", {self.pos.x, self.pos.y})
    role.player = nil
end

function Player:draw()
    love.graphics.rectangle("fill", self.pos.x - 32, self.pos.y - 16, 64, 32)
end

return Player