local Level = {}
Level.__index = Level

function Level.new(width, height, seed, rocks)
    local this = {}
    setmetatable(this, Level)
    this.width  = width
    this.height = height
    this.seed   = seed
    this.params = { width, height, seed }
    this.rocks  = rocks
    return this
end

function Level:isValidStartingPosition(x, y)
    if x < 0 or y < 0 then 
        return false 
    end
    if x > self.width or y > self.height then 
        return false 
    end
    if not self:isPassable(x, y) then 
        return false 
    end
    return true
end

function Level:isPassable(x, y, objectToIgnore, leeway)
    if self:isSolid(x, y) then
        return false
    end
    -- TODO: check for other players
    for _, p in pairs(role.players) do
        local dr = 24 + (leeway or 0) -- TODO: change 24 to whatever is appropriate for players
        if objectToIgnore and p ~= objectToIgnore then
            local dx = p.pos.x - x
            local dy = p.pos.y - y
            if dx*dx + dy*dy < dr*dr then
                return false
            end
        end
    end
    -- TODO: check for other objects
    
    return true
end

function Level:isSolid(x, y)
    for _, r in pairs(self.rocks) do
        if r:containsPoint(x, y) then
            return true
        end
    end
    return false
end

function Level:getImageData(x, y, size)
    local canvas = love.graphics.newCanvas(size * 2, size * 2)
    love.graphics.push()
        love.graphics.setCanvas(canvas)
        love.graphics.translate(size-x, size-y)
        self:draw()
        local imageData = canvas:newImageData()
        love.graphics.setCanvas()
    love.graphics.pop()
    return imageData
end

function Level:draw()
    love.graphics.setColor(128, 255, 255, 128)
    for _, rock in pairs(self.rocks) do
        love.graphics.polygon('fill', unpack(rock.polygon))
    end
    for _, p in pairs(role.players) do
        p:draw()
    end
end

return Level
