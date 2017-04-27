local PongGhost = require "pong_ghost"

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
    if self.finished then return end
    local newX = self.pos.x + self.vel.x * dt
    local newY = self.pos.y + self.vel.y * dt

    if role.level:isPassable(newX, newY) then    
        self:move(self.vel.x * dt, self.vel.y * dt)
    else
        self:pong(true)
        -- TODO: maybe bounce instead and have a distance limit? or a bounce limit?
        self.finished = true
    end
end

function Ping:pong(isActive)
    local imageData = role.level:getImageData(self.pos.x, self.pos.y, PongGhost.RADIUS)
    role.server:sendToAll("pong", { self.pos.x, self.pos.y, imageData:getString(), isActive } )
    log:add("pong at '" .. self.pos.x .. ", " .. self.pos.y .. "'.")
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

