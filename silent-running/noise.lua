local Noise = {}
Noise.pong = {
    RADIUS        = 64,
    START_RADIUS  = 16,
    FADE_SPEED    = 128,
    GROW_SPEED    = 256,
    START_OPACITY = 255,
}
Noise.scan = {
    RADIUS        = 128,
    START_RADIUS  = 32,
    FADE_SPEED    = 64,
    GROW_SPEED    = 256,
    START_OPACITY = 255,
}
Noise.torpedo = {
    RADIUS        = 32,
    START_RADIUS  = 16,
    FADE_SPEED    = 128,
    GROW_SPEED    = 256,
    START_OPACITY = 255,
}
Noise.general = {
    RADIUS        = 1, -- to be scaled
    START_RADIUS  = 32,
    FADE_SPEED    = 256,
    GROW_SPEED    = 256,
    START_OPACITY = 255,
}
Noise.__index = Noise

function Noise.new(x, y, imageDataString, size, startSize, growSpeed, fadeSpeed, startOpacity)
    local this = {}
    local imageData = love.image.newImageData(size * 2, size * 2, imageDataString)
    setmetatable(this, Noise)
    this.finished  = false
    this.pos       = { x = x, y = y }
    this.maxRadius = size
    this.growSpeed = growSpeed
    this.fadeSpeed = fadeSpeed
    this.radius    = startSize
    this.opacity   = startOpacity
    this.image     = love.graphics.newImage(imageData)
    return this
end

function Noise:update(dt)
    if self.finished then return end
    self.radius  = math.min(self.maxRadius, self.radius + dt * self.growSpeed)
    self.opacity = math.max(0, self.opacity - dt * self.fadeSpeed)
    if self.opacity < 0 then 
        self.finished = true
    end
end

function Noise:draw()
    if self.finished then return end
    local function myStencilFunction()
        love.graphics.circle("fill", self.pos.x, self.pos.y, self.radius)
    end
    love.graphics.stencil(myStencilFunction, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    love.graphics.setColor(255, 255, 255, self.opacity)
    love.graphics.draw(self.image, self.pos.x - self.maxRadius, self.pos.y - self.maxRadius)

    love.graphics.setStencilTest()
end

return Noise
