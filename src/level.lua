local Level = {}
Level.__index = Level

function Level.new(rocks)
    local this = {}
    setmetatable(this, Level)
    this.rocks = rocks
    return this
end

function Level:isPassable(x, y)
    for _, r in pairs(self.rocks) do
        if r:containsPoint(x, y) then
            return false
        end
    end
    return true
end

function Level:draw()
    for _, rock in pairs(self.rocks) do
        love.graphics.polygon('line',unpack(rock.polygon))
    end
end

return Level