local DISABLED = false

local Log = {}
Log.__index = Log

function Log.new(font)
    local this = {}
    setmetatable(this, Log)
    this.font = font
    this.messages = {}
    return this
end

function Log:add(message)
    if DISABLED then return end
    print(message)
    table.insert(self.messages, message)
end

function Log:update()
    if DISABLED then return end
    if (#self.messages + 1) * 16 > love.graphics.getHeight() then
        table.remove(self.messages, 1)
    end
end

function Log:draw()
    if DISABLED then return end
    local oldFont = nil
    if self.font then
        oldFont = love.graphics.getFont()
        love.graphics.setFont(self.font)
    end
    for i, message in pairs(self.messages) do
        love.graphics.printf(message, 0, (i-1) * 16, love.graphics.getWidth(), "right")
    end
    if oldFont then
        love.graphics.setFont(oldFont)
    end
end

return Log