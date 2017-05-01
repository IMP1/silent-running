local Noise = {}
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
