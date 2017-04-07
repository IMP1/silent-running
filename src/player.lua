local ROOT_2 = math.sqrt(2)

local Player = {}
Player.__index = Player

Player.ACCELLERATION = 256
Player.FRICTION = 0.99
Player.EPSILON = 0.5

function Player.new(x, y)
    local this = {}
    setmetatable(this, Player)
    this.pos = { x = x, y = y }
    this.vel = { x = 0, y = 0 }
    this.lastMove = { x = 0, y = 0 }
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
    self.vel.x = self.vel.x + dx * Player.ACCELLERATION ^ dt
    self.vel.y = self.vel.y + dy * Player.ACCELLERATION ^ dt

    self:move(self.vel.x * dt, self.vel.y * dt)

    -- TODO: check for collisions

    self.vel.x = self.vel.x * Player.FRICTION ^ dt
    if math.abs(self.vel.x) < Player.EPSILON then
        self.vel.x = 0
    end
    self.vel.y = self.vel.y * Player.FRICTION ^ dt
    if math.abs(self.vel.y) < Player.EPSILON then
        self.vel.y = 0
    end
end

function Player:move(dx, dy)
    self.lastMove.x = dx
    self.lastMove.y = dy

    self.pos.x = self.pos.x + dx
    self.pos.y = self.pos.y + dy
end

function Player:draw()
    love.graphics.rectangle("fill", self.pos.x - 32, self.pos.y - 16, 64, 32)

    love.graphics.print(tostring(self.vel.x), 0, 0)
    love.graphics.print(tostring(self.vel.y), 0, 16)
end

return Player