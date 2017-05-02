local DISABLED = false

local Log = {}
Log.__index = Log

function Log.new()
    local this = {}
    setmetatable(this, Log)
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
    for i, message in pairs(self.messages) do
        love.graphics.printf(message, 0, (i-1) * 16, love.graphics.getWidth(), "right")
    end
end

return Log