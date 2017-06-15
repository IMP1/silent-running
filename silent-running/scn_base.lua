local Scene = {}
Scene.__index = Scene
function Scene:__tostring()
    return "Scene " .. self._name
end

function Scene.new(name)
    local this = {}
    this._name = name
    setmetatable(this, Scene)
    this.fade  = nil
    this.music = {}
    return this
end

function Scene:update(dt, mx, my)

end

function Scene:fadeOut(duration, onfinish, fadeMusic, colour)
    if fadeMusic == nil then fadeMusic = true end
    self.fade = {}
    self.fade.colour    = colour   or {0, 0, 0}
    self.fade.duration  = duration or 0.5
    self.fade.onfinish  = onfinish or nil
    if fadeMusic then
        self.fade.music = {
            -- TODO: fade music
            -- volume = bgm:getVolume(),
        }
    end
    self.fade.timer     = duration
    self.fade.oldUpdate = self.update
    self.fade.oldDraw   = self.draw
    self.update = function(self, dt, ...)
        self.fade.timer = self.fade.timer - dt
        if self.fade.timer <= 0 then
            if self.fade.onfinish then
                self.fade.onfinish(self)
            end
            if self.dispose then
                self:dispose()
            end
        end
        if self.fade.music then
            -- TODO: fade music
            --bgm:setVolume( self.fade.music.volume * self.fade.timer / self.fade.duration )
        end
    end
    self.draw = function(self, ...)
        self.fade.oldDraw(self)
        local r, g, b = unpack(self.fade.colour)
        local a = 255 - math.floor(255 * self.fade.timer / self.fade.duration)
        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        -- TODO: go back to old colour
    end
end

function Scene:fadeIn(duraction, onfinish, fadeMusic, colour)
    if fadeMusic == nil then fadeMusic = true end
    self.fade = {}
    self.fade.colour    = colour   or { 0, 0, 0 }
    self.fade.duration  = duration or 0.5
    self.fade.onfinish  = onfinish
    if fadeMusic then
        self.fade.music = {
            -- TODO: fade music
            -- volume = bgm:getVolume(),
        }
    end
    self.fade.timer     = 0
    self.fade.oldUpdate = self.update
    self.fade.oldDraw   = self.draw
    self.update = function(self, dt, ...)
        self.fade.timer = self.fade.timer + dt
        if self.fade.timer >= self.fade.duration then
            if self.fade.onfinish then
                self.fade.onfinish(self)
            end
            self.update = self.oldUpdate
            self.draw   = self.oldDraw
        end
        if self.fade.music then
            -- TODO: fade music
            --bgm:setVolume( self.fade.music.volume * self.fade.timer / self.fade.duration )
        end
    end
    self.draw = function(self)
        self.fade.oldDraw(self)
        local r, g, b = unpack(self.fade.colour)
        local a = 255 - math.floor(255 * self.fade.timer / self.fade.duration)
        love.graphics.setColor( r, g, b, a )
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        -- TODO: go back to old colour
    end
end

function Scene:draw()

end

return Scene
