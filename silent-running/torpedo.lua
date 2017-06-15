local Noise = require 'noise'

local Torpedo = {
    SPEED = 128,
}
Torpedo.__index = Torpedo

function Torpedo.new(x, y, direction)
    local this = {}
    setmetatable(this, Torpedo)
    this.finished = false
    this.pos = { x = x, y = y }
    this.vel = { x = Torpedo.SPEED * direction, y = 0 }
    this.lastMove = { x = 0, y = 0 }
    return this
end

function Torpedo:update(dt)
    if self.finished then return end
    local newX = self.pos.x + self.vel.x * dt
    local newY = self.pos.y + self.vel.y * dt

    if scene.level:isPassable(newX, newY, self) then    
        self:move(self.vel.x * dt, self.vel.y * dt)
    else
        -- TODO: check for player or something damagable and do damage
        scene.server:sendToAll("damage", {self.pos.x, self.pos.y, 40, self.vel.x / 4, self.vel.y / 4})
        -- TODO: only send to relevant player?
        scene:sendSound(self.pos.x, self.pos.y, Noise.torpedo)
        self.finished = true
    end
end

function Torpedo:move(dx, dy)
    self.lastMove.x = dx
    self.lastMove.y = dy

    self.pos.x = self.pos.x + dx
    self.pos.y = self.pos.y + dy
end

function Torpedo:draw()
    love.graphics.ellipse("fill", self.pos.x, self.pos.y, 8, 4)
end

return Torpedo