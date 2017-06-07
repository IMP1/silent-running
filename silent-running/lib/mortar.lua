local mortar = {
    _VERSION     = 'v0.0.1',
    _DESCRIPTION = 'Advanced Lua UI features for LÖVE games',
    _URL         = '',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2017 Huw Taylor

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

-- Transitions

local Swipe = {}
Swipe.__index = Swipe
function Swipe:__tostring()
    return "<Swipe:" .. (self.id or "") .. ">"
end

function Swipe.new(currentElement, nextElement, options)
    local this = {}
    setmetatable(this, Swipe)
    this.currentElement = currentElement
    this.nextElement = nextElement

    this.drawCurrentElement = this.currentElement.draw
    this.drawNextElement = this.nextElement.draw
    this.currentElement.draw = function() end
    this.nextElement.draw = function() end

    this.targetX               = options.ox or 0
    this.targetY               = options.oy or 0
    local duration             = options.duration or 0.1

    this.currentElementOffset = {}
    this.currentElementOffset[1] = 0
    this.currentElementOffset[2] = 0

    this.nextElementOffset = {}
    this.nextElementOffset[1] = -this.targetX
    this.nextElementOffset[2] = -this.targetY

    -- TODO: add easing function as an option

    this.vx = this.targetX / duration
    this.vy = this.targetY / duration

    this.fadeOutSpeed          = options.fadeOutSpeed or 0
    this.fadeInSpeed           = options.fadeInSpeed or 0
    this.currentElementOpacity = options.currentElementOpacity or 255
    this.nextElementOpacity    = options.nextElementOpacity or 255
    this.onfinish              = options.onfinish or nil

    this.finished = false
    return this
end

function Swipe:update(dt)
    if self.finished then return end
    local dx = self.vx * dt
    local dy = self.vy * dt
    self.currentElementOffset[1] = self.currentElementOffset[1] + dx
    self.currentElementOffset[2] = self.currentElementOffset[2] + dy
    self.nextElementOffset[1] = self.nextElementOffset[1] + dx
    self.nextElementOffset[2] = self.nextElementOffset[2] + dy
    -- TODO: work out how opacity will be applied.
    self.currentElementOpacity = self.currentElementOpacity - self.fadeOutSpeed * dt
    self.nextElementOpacity    = self.nextElementOpacity    + self.fadeInSpeed  * dt

    local x, y = unpack(self.currentElementOffset)
    if math.abs(x) >= math.abs(self.targetX) and math.abs(y) >= math.abs(self.targetY) then
        self:finish()
    end
end

function Swipe:finish()
    self.finished = true
    self.currentElement.draw = self.drawCurrentElement
    self.nextElement.draw = self.drawNextlement
    if self.onfinish then
        self.onfinish(self)
    end
end

function Swipe:draw()
    if self.finished then return end
    love.graphics.push()
    love.graphics.translate(unpack(self.currentElementOffset))
    self.drawCurrentElement(self.currentElement)
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(unpack(self.nextElementOffset))
    self.drawNextElement(self.nextElement)
    love.graphics.pop()         
end

local function addIcons(bricks)
    local settings = {
        iconFont     = nil,
        iconFontPath = nil
    }

    --------------------------------------------------------------------------------
    -- # Icon
    --------------
    -- A graphical symbol.
    --------------------------------------------------------------------------------
    local Icon = {}
    setmetatable(Icon, bricks._classes.Element_mt)
    Icon.__index = Icon
    function Icon:__tostring()
        return "<Icon" .. (self.id or "") .. ">"
    end

    function Icon.new(id, position, options)
        local this = bricks._classes.Element.new("icon", id, position, options)
        setmetatable(this, Icon)
        this.icon = options.icon
        if options.size then
            this.font = love.graphics.newFont(settings.iconFontPath, options.size)
        end
        return this
    end

    function Icon:draw()
        if not self.visible then
            return
        end
        bricks.graphics.push()
        if self.font then
            bricks.graphics.setFont(self.font)
        else
            bricks.graphics.setFont(settings.iconFont)
        end
        local x, y, w, h = unpack(self:getRelativeBounds())
        local align = self.pos[6]
        love.graphics.printf(self.icon, x, y, w, align)
        bricks.graphics.pop()
    end

    bricks.icon = bricks._functions.default_constructor_for(Icon)
    bricks._classes.Icon = Icon
    bricks.setIconFont = function(iconFontPath)
        settings.iconFontPath = iconFontPath
        settings.iconFont = love.graphics.newFont(iconFontPath)
    end
end

local function addFlashes(bricks, animations)

    --------------------------------------------------------------------------------
    -- # Flash
    --------------
    -- A textual element that fades out after a certain time.
    --------------------------------------------------------------------------------
    local Flash = {}
    setmetatable(Flash, bricks._classes.Element_mt)
    Flash.__index = Flash
    function Flash:__tostring()
        return "<Flash" .. (self.id or "") .. ">"
    end

    function Flash.new(id, position, options)
        local this = bricks._classes.Element.new("flash", id, position, options)
        setmetatable(this, Flash)
        if options.text == nil then
            this.text = function () return "" end
        elseif type(options.text) == "string" then
            this.text = function() return options.text end
        elseif type(options.text) == "function" then
            this.text = options.text
        else
            error("[Mortar] Invalid text value: '" .. tostring(options.text) .. "' for Text.")
        end
        this.cannotTarget    = true
        this.fadeInDuration  = options.fadeIn   or 0
        this.duration        = options.duration or 1
        this.fadeOutDuration = options.fadeOut  or 0.2
        this.timer           = 0
        this.opacity         = 0
        this.finished        = false
        return this
    end

    function Flash:update(dt, mx, my)
        if self.finished then return end
        self.timer = self.timer + dt
        if self.timer < self.fadeInDuration then
            local fadeIn = self.timer / self.fadeInDuration
            self.opacity = 255 * fadeIn
        elseif self.timer < self.fadeInDuration + self.duration then
            self.opacity = 255
        elseif self.timer < self.fadeInDuration + self.duration + self.fadeOutDuration then
            local fadeOut = (self.timer - self.fadeInDuration - self.duration) / self.fadeOutDuration
            self.opacity = 255 * (1 - fadeOut)
        else
            self.finished = true
        end
    end

    function Flash:draw()
        if self.finished then return end
        if self.style.customDraw then 
            self.style.customDraw(self)
            return
        end
        if not self.visible then
            return
        end
        bricks.graphics.push()
        if self.style.font then
            bricks.graphics.setFont(self.style.font)
        end
        if self.style.textColor then
            local r, g, b, a = unpack(self.style.textColor)
            a = (a or 255) * self.opacity / 255
            bricks.graphics.setColor(r, g, b, a)
        end
        local x, y, w, h = unpack(self:getRelativeBounds())
        local align = self.pos[6]
        love.graphics.printf(self.text(), x, y, w, align)
        bricks.graphics.pop()
    end

    bricks.flash = bricks._functions.default_constructor_for(Flash)
    bricks._classes.Flash = Flash

    mortar.flash = function(text, options)
        options = options or {}
        options.text = text
        table.insert(animations, Flash.new(options.id, nil, options))
    end
end

local animations = {}

function mortar.setup(bricks)
    addIcons(bricks)
    addFlashes(bricks, animations)
end

function mortar.swipe(currentElement, nextElement, options)
    table.insert(animations, Swipe.new(currentElement, nextElement, options))
end

function mortar.update(dt)
    for i = #animations, 1, -1 do
        animations[i]:update(dt)
        if animations[i].finished then
            table.remove(animations, i)
        end
    end
end

function mortar.draw( ... )
    for _, a in pairs(animations) do
        a:draw()
    end
end

return mortar