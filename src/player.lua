local Player = {}
Player.__index = Player

Player.ACCELLERAION = 256
Player.FRICTION = 0.99

function Player.new(x, y)
    local this = {}
    setmetatable(this, Player)
    this.pos = { x = x, y = y }
    this.vel = { x = 0, y = 0 }
    return this
end

function Player:update(dt)
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
    self.vel.x = self.vel.x + dx * Player.ACCELLERAION ^ dt
    self.vel.y = self.vel.y + dy * Player.ACCELLERAION ^ dt

    self.pos.x = self.pos.x + self.vel.x * dt
    self.pos.y = self.pos.y + self.vel.y * dt

    self.vel.x = self.vel.x * Player.FRICTION
    self.vel.y = self.vel.y * Player.FRICTION
end

function Player:draw()
    love.graphics.rectangle("fill", self.pos.x - 32, self.pos.y - 16, 64, 32)
end

return Player