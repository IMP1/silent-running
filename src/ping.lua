local Ping = {}
Ping.__index = Ping

function Ping.new(x, y, vx, vy)
    local this = {}
    setmetatable(this, Ping)
    this.finished = false
    this.pos = { x = x, y = y }
    this.vel = { x = vx, y = vy }
    this.lastMove = { x = 0, y = 0 }
    return this
end

function Ping:update(dt)
    self:move(self.vel.x * dt, self.vel.y * dt)
    -- TODO: check for collisions and PONG.
end

function Ping:move(dx, dy)
    self.lastMove.x = dx
    self.lastMove.y = dy

    self.pos.x = self.pos.x + dx
    self.pos.y = self.pos.y + dy
end

function Ping:draw()
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x - self.lastMove.x, self.pos.y - self.lastMove.y)
end

return Ping

