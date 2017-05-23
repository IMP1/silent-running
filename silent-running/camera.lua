if not math.clamp then
    function math.clamp(x, lower, upper)
      return x < lower and lower or (x > upper and upper or x)
    end
end

local Camera = {}
Camera.__index = Camera

function Camera.new()
    local this = {}
    setmetatable(this, Camera)
    this.x = 0
    this.y = 0
    this.scaleX = 1
    this.scaleY = 1
    this.rotation = 0
    return this
end

function Camera:set()
    love.graphics.push()
    love.graphics.rotate(-self.rotation)
    love.graphics.scale(self.scaleX, self.scaleY)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:move(dx, dy)
    self:setX(self.x + (dx or 0))
    self:setY(self.y + (dy or 0))
end

function Camera:rotate(dr)
    self.rotation = self.rotation + dr
end

function Camera:scale(sx, sy)
    sx = sx or 1
    self.scaleX = self.scaleX * sx
    self.scaleY = self.scaleY * (sy or sx)
end

function Camera:setX(value)
    if self.bounds then
        self.x = math.clamp(value, self.bounds.x1, self.bounds.x2)
    else
        self.x = value
    end
end

function Camera:setY(value)
    if self.bounds then
        self.y = math.clamp(value, self.bounds.y1, self.bounds.y2)
    else
        self.y = value
    end
end

function Camera:setPosition(x, y)
    if x then self:setX(x) end
    if y then self:setY(y) end
end

function Camera:centreOn(x, y)
    local viewWidth = love.graphics.getWidth() / self.scaleX
    local viewHeight = love.graphics.getHeight() / self.scaleY
    self:setPosition(x - viewWidth / 2, y - viewHeight / 2)
end

function Camera:setScale(sx, sy)
    self.scaleX = sx or self.scaleX
    self.scaleY = sy or self.scaleY
end

function Camera:getBounds()
    return unpack(self.bounds)
end

function Camera:setBounds(x1, y1, x2, y2)
    self.bounds = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

function Camera:toWorldPosition(screenX, screenY)
    -- TODO: include rotation
    return (screenX + self.x) / self.scaleX, (screenY + self.y) / self.scaleY
end

function Camera:toScreenPosition(worldX, worldY)
    -- TODO: include rotation
    return worldX * math.abs(self.scaleX) - self.x, worldY * self.scaleY - self.y
end

return Camera
