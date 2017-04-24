local Client = {}
Client.__index = Client

function Client.new()
    local this = {}
    setmetatable(this, Client)
    this:start()
    return this
end

function Client:start()
    ----------------------
    -- Client Variables --
    ----------------------
    self.client = sock.newClient("localhost", PORT)
    self.client:setSerialization(bitser.dumps, bitser.loads)
    self.player = nil
    self.map = nil
    self.pongGhosts = nil
    
    ----------------------
    -- Client Callbacks --
    ----------------------
    self.client:on("connect", function(data)
        log:add("Connected to localhost")
    end)

    self.client:on("init", function(playerPosition)
        log:add("Recieved '" .. playerPosition[1] .. ", " .. playerPosition[2] .. "' from server.")
        self.player = Player.new(unpack(playerPosition))
        self.pongGhosts = {}
    end)

    self.client:on("level", function(level)
        log:add("Recieved level from server.")
        log:add(tostring(level))
        self.map = level
    end)

    self.client:on("pong", function(pongGhost)
        log:add("Recieved '" .. tostring(pongGhost) .. "' from server.")
        table.insert(pongGhosts, pongGhost)
    end)

    self.client:connect()
end

function Client:keypressed(key, isRepeat)
    if DEBUG then
        if key == "v" then
            DEBUG.showVelocity = not DEBUG.showVelocity
        end
        if key == "tab" then
            DEBUG.showLog = not DEBUG.showLog
        end
    end
end

function Client:update(dt)
    self.client:update()
    self.player:update(dt)
    self.client:send("move", player.lastMove)
    for i = #self.pongGhosts, 1, -1 do
        self.pongGhosts[i]:update(dt) -- TODO: have pongGhost class
        -- TODO: pongGhost class will have a draw function and opacity levels.
        if self.pongGhosts[i].opacity == 0 then
            table.remove(self.pongGhosts, i)
        end
    end
end

function Client:draw()
    love.graphics.setColor(255, 255, 255)
    self.player:draw()

    if self.pongGhosts then
        for _, p in pairs(self.pongGhosts) do
            p:draw()
        end 
    end

    if DEBUG.showVelocity then
        love.graphics.print(tostring(player.vel.x), 0, 0)
        love.graphics.print(tostring(player.vel.y), 0, 16)
    end
end

return Client