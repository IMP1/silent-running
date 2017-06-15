local SceneBase = require 'scn_base'

local Title = {}
setmetatable(Title, SceneBase)
Title.__index = Title

function Title.new()
    local this = {}
    setmetatable(this, Title)
    this.layouts  = love.filesystem.load('layouts.lua')().title
    this.layout = this.layouts.main
    return this
end


function Title:keypressed(...)
    self.layout:keypressed(...)
end

function Title:mousepressed(...)
    self.layout:mousepressed(...)
end

function Title:mousereleased(...)
    self.layout:mousereleased(...)
end

function Title:update(dt)
    if self.connecting then
        self.client.client:update()
    end
    local mx, my = love.mouse.getPosition()
    self.layout:update(dt, mx, my)
    mortar.update(dt)
end

function Title:draw()
    love.graphics.setColor(255, 255, 255)
    self.layout:draw()
    mortar.draw()
end

function Title:startServer()
    local input = self.layout:elementWithId("port")
    input:validate(true)
    if input.valid then
        local port = tonumber(input:value())
        self:fadeOut(0.5, function()
            local server = Server.new(port)
            role = server
        end)
    end
end

function Title:attemptConnection()
    local input1 = self.layout:elementWithId("ipAddress")
    local input2 = self.layout:elementWithId("port")
    input1:validate(true)
    input2:validate(true)
    if input1.valid and input2.valid then
        local address = input1:value()
        local port = tonumber(input2:value())
        self.layout:elementWithId("connectionSpinner").visible = true
        self.client = Client.new(address, port)
        self.connecting = true
    end
end

function Title:connectionAchieved()
    self.connecting = nil
    self.layout:elementWithId("connectionSpinner").visible = false
    self:fadeOut(0.5, function()
        role = self.client
        self.client = nil
    end)
end

function Title:cancelConnection()
    self.layout:elementWithId("connectionSpinner").visible = false
    self.connecting = false
    self.client     = nil
end

return Title