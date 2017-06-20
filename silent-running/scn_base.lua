local Scene = {}
Scene.__index = Scene
function Scene:__tostring()
    return "Scene " .. self._name
end

function Scene.new(name)
    local this = {}
    this._name = name
    this.fade  = nil
    this.music = {
        tracks = {},
    }
    return this
end

function Scene:fadeOut(duration, onfinish, fadeMusic, colour)
    if fadeMusic == nil then fadeMusic = true end
    self.fade = {}
    self.fade.colour    = colour   or {0, 0, 0}
    self.fade.duration  = duration or 0.5
    self.fade.onfinish  = onfinish or nil
    if fadeMusic and self.music then
        self.fade.music = {
            volumes = {}
        }
        for _, track in pairs(self.music.tracks) do
            self.fade.music.volumes[track] = track:getVolume()
        end
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
            for track, volume in pairs(self.fade.music.volumes) do
                track:setVolume(volume * self.fade.timer / self.fade.duration)
            end
        end
    end
    self.draw = function(self, ...)
        self.fade.oldDraw(self)
        local r, g, b = unpack(self.fade.colour)
        local a = 255 - math.floor(255 * self.fade.timer / self.fade.duration)
        local oldColour = { love.graphics.getColor() }
        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(unpack(oldColour))
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
            volumes = {}
        }
        for _, track in pairs(self.music.tracks) do
            self.fade.music.volumes[track] = track:getVolume()
        end
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
            for track, volume in pairs(self.fade.music.volumes) do
                track:setVolume(volume * self.fade.timer / self.fade.duration)
            end
        end
    end
    self.draw = function(self)
        self.fade.oldDraw(self)
        local r, g, b = unpack(self.fade.colour)
        local a = 255 - math.floor(255 * self.fade.timer / self.fade.duration)
        local oldColour = { love.graphics.getColor() }
        love.graphics.setColor( r, g, b, a )
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(unpack(oldColour))
    end
end

return Scene
