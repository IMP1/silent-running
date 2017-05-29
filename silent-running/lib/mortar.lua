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

local Animation = {}
Animation.__index = Animation

function Animation.new()
    local this = {}
    setmetatable(this, Animation)
    return this
end


function mortar.setup(bricks)
    addIcons(bricks)
end

return mortar