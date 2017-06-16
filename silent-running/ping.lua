local Noise = require "noise"

local Ping = {}
Ping.__index = Ping

function Ping.new(x, y, vx, vy)
    log:add("new ping @ (" .. tostring(x) .. ", " .. tostring(y) .. ").")
    local this = {}
    setmetatable(this, Ping)
    this.finished = false
    this.pos      = { x = x, y = y }
    this.vel      = { x = vx, y = vy }
    this.lastMove = { x = 0, y = 0 }
    this.bounces  = 2
    return this
end

function Ping:update(dt)
    if self.finished then return end
    local newX = self.pos.x + self.vel.x * dt
    local newY = self.pos.y + self.vel.y * dt

    if scene.level:isPassable(newX, newY) then    
        self:move(self.vel.x * dt, self.vel.y * dt)
    elseif self.bounces > 0 then
        local vx, vy = scene.level:getBounceDirection(newX, newY, self.vel.x, self.vel.y)
        self.vel.x = vx
        self.vel.y = vy
        self:pong()
        self.bounces = self.bounces - 1
        -- TODO: maybe bounce instead and have a distance limit? or a bounce limit?
    else
        self:pong()
        self.finished = true
    end
end

function Ping:pong()
    scene:sendSound(self.pos.x, self.pos.y, Noise.pong)
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
