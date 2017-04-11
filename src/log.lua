local Log = {}
Log.__index = Log

function Log.new()
    local this = {}
    setmetatable(this, Log)
    this.messages = {}
    return this
end

function Log:add(message)
    print(message)
    table.insert(self.messages, message)
end

function Log:update()
    if (#self.messages + 1) * 16 > love.graphics.getHeight() then
        table.remove(self.messages, 0)
    end
end

function Log:draw()
    for i, message in pairs(self.messages) do
        love.graphics.printf(message, 0, (i-1) * 16, love.graphics.getWidth(), "right")
    end
end

return Log