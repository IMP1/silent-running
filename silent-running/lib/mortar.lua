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
    this.x = 0
    this.y = 0
    this.currentElement = currentElement
    this.nextElement = nextElement
    this.currentElement.visible = false
    this.nextElement.visible = false

    this.targetX               = options.ox or 0
    this.targetY               = options.oy or 0
    local duration             = options.duration or 0.1

    this.nextElement.offset[1] = -this.targetX
    this.nextElement.offset[2] = -this.targetY

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
    self.x = self.x + dx
    self.y = self.y + dy
    self.currentElement.offset[1] = self.currentElement.offset[1] + dx
    self.currentElement.offset[2] = self.currentElement.offset[2] + dy
    self.nextElement.offset[1] = self.nextElement.offset[1] + dx
    self.nextElement.offset[2] = self.nextElement.offset[2] + dy
    -- TODO: work out how opacity will be applied.
    self.currentElementOpacity = self.currentElementOpacity - self.fadeOutSpeed * dt
    self.nextElementOpacity    = self.nextElementOpacity    + self.fadeInSpeed  * dt

    if math.abs(self.x) >= math.abs(self.targetX) and math.abs(self.y) >= math.abs(self.targetY) then
        self.finished = true
        self.nextElement.offset[1] = 0
        self.currentElement.offset[1] = 0
        self.nextElement.visible = true
        self.currentElement.visible = true
        if self.onfinish then
            self.onfinish(self)
        end
    end
end

function Swipe:draw()
    self.currentElement.visible = true
    self.currentElement:draw()
    self.currentElement.visible = false
    self.nextElement.visible = true
    self.nextElement:draw()
    self.nextElement.visible = false
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

function mortar.setup(bricks)
    addIcons(bricks)
end

local animations = {}

function mortar.swipe(currentElement, nextElement, options)
    return Swipe.new(currentElement, nextElement, options)
end

function mortar.animate(animation)
    table.insert(animations, animation)
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