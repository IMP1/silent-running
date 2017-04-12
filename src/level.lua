local Level = {}
Level.__index = Level

function Level.new(rocks)
    local this = {}
    setmetatable(this, Level)
    this.rocks = rocks
    return this
end

function Level:draw()
    for _, rock in pairs(self.rocks) do
        love.graphics.polygon('line',unpack(rock.polygon))
    end
end

return Level