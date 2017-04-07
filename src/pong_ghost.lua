local PongGhost = {
    FADE_SPEED = 128,
}
PongGhost.__index = PongGhost

function PongGhost.new(x, y, image)
    local this = {}
    setmetatable(this, PongGhost)
    this.finished = false
    this.pos = { x = x, y = y }
    this.opacity = 255
    this.image = image
    return this
end

function PongGhost:update(dt)
    self.opacity = math.max(0, self.opacity - dt * PongGhost.FADE_SPEED)
end

function PongGhost:draw()
    love.graphics.setColor(255, 255, 255, self.opacity)
    love.graphics.draw(self.image, self.x, self.y)
end

return PongGhost

