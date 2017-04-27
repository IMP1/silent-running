local PongGhost = {
    RADIUS = {
        [true] = 64,
        [false] = 128
    },
    START_RADIUS = {
        [true] = 16,
        [false] = 32
    },
    FADE_SPEED = {
        [true] = 128,
        [false] = 64
    },
    GROW_SPEED = {
        [true] = 256,
        [false] = 256
    }
}
PongGhost.__index = PongGhost

function PongGhost.new(x, y, imageDataString, isActive)
    local this = {}
    setmetatable(this, PongGhost)
    this.finished = false
    this.pos = { x = x, y = y }
    this.radius = PongGhost.START_RADIUS[isActive]
    this.isActive = isActive
    this.opacity = 255
    local imageData = love.image.newImageData(PongGhost.RADIUS[isActive] * 2, PongGhost.RADIUS[isActive] * 2, imageDataString)
    this.image = love.graphics.newImage(imageData)
    return this
end

function PongGhost:update(dt)
    self.radius  = math.min(PongGhost.RADIUS[self.isActive], self.radius + dt * PongGhost.GROW_SPEED[self.isActive])
    if DEBUG and DEBUG.keepPongs then return end
    self.opacity = math.max(0, self.opacity - dt * PongGhost.FADE_SPEED[self.isActive])
end

function PongGhost:draw()
    local function myStencilFunction()
        love.graphics.circle("fill", self.pos.x, self.pos.y, self.radius)
    end
    love.graphics.stencil(myStencilFunction, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    love.graphics.setColor(255, 255, 255, self.opacity)
    love.graphics.draw(self.image, self.pos.x - PongGhost.RADIUS[self.isActive], self.pos.y - PongGhost.RADIUS[self.isActive])

    love.graphics.setStencilTest()
end

return PongGhost
