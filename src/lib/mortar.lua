local mortar = {
    _VERSION     = 'v0.0.1',
    _DESCRIPTION = 'A Lua UI library for LÖVE games',
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

-- https://airstruck.github.io/luigi/doc/classes/Layout.html

local function createDefaultOptions(id, pos, options)
    local obj = {}

    obj.id    = id
    obj.pos   = pos or {0, 0, 100, 100, "top", "left"}
    obj.tags  = options.tags or {}
    obj.style = options.style or {}

    return obj
end

local function getScreenBounds(obj)
    local parentBounds
    if getmetatable(obj) == Layout then
        parentBounds = { 0, 0, love.graphics.getWidth(), love.graphics.getHeight() }
    else
        parentBounds = getScreenBounds(obj.parent)
    end
    return {
        obj.pos[1] + parentBounds[1],
        obj.pos[2] + parentBounds[2],
        obj.pos[3] * parentBounds[3] / 100,
        obj.pos[4] * parentBounds[4] / 100
    }
end

local function getWidth(obj)
    if getmetatable(obj) == Layout then
        return obj.pos[3] * love.graphics.getWidth()
    else
        return obj.pos[3] * getWidth(obj.parent)
    end
end

local function getHeight(obj)
    if getmetatable(obj) == Layout then
        return obj.pos[4] * love.graphics.getHeight()
    else
        return obj.pos[4] * getHeight(obj.parent)
    end
end

local function mousePressed(obj, mx, my, key)
    local bounds = getScreenBounds(obj)
    local x, y, w, h = unpack(bounds)
    if mx < x or my < y or mx > x + w or my > y + h then
        return
    end
    
end

--------------------------------------------------------------------------------
-- # Button
--------------
-- A simple text button class. It is connected to an action which will fire when
-- the button is clicked.
--------------------------------------------------------------------------------
local Button = {}
Button.__index = Button

function Button.new(id, position, options)
    local this = createDefaultOptions(id, pos, options)
    setmetatable(this, Button)
    this.text     = options.text or ""
    this.onclick  = options.onclick
    return this
end

--------------------------------------------------------------------------------
-- # Text
--------------
-- A simple class for displaying text. 
--------------------------------------------------------------------------------
local Text = {}
Text.__index = Text

function Text.new(id, position, options)
    local this = createDefaultOptions(id, pos, options)
    setmetatable(this, Text)
    this.text = options.text or ""
    return this
end


local TextInput = {}
TextInput.__index = TextInput

function TextInput.new(id, position, options)
    local this = createDefaultOptions(id, pos, options)
    setmetatable(this, TextInput)
    this.placeholder = options.placeholder or ""
    return this
end


local Group = {}
Group.__index = Group

function Group.new(id, position, options)
    local this = createDefaultOptions(id, pos, options)
    setmetatable(this, Group)
    this.elements = options.elements or {}
    for _, e in pairs(this.elements) do
        e.parent = this
    end
    return this
end


local Layout = {}
Layout.__index = Layout

function Layout.new(id, position, options)
    local this = createDefaultOptions(id, pos, options)
    setmetatable(this, Layout)
    this.elements = options.elements or {}
    for _, e in pairs(this.elements) do
        e.parent = this
    end
    return this
end

function Layout:update(dt)
    -- TODO: Implement
end

function Layout:mousepressed(mx, my, key)
    
    -- TODO: Implement
end

function Layout:draw(ox, oy)
    love.graphics.push()
    love.graphics.translate(ox or 0, oy or 0)

    for _, element in pairs(self.elements) do
        if element.draw then
            element:draw()
        end
    end

    love.graphics.pop()
end

function Layout:elementWithId(id)
    for _, e in pairs(self.elements) do
        if e.id == id then 
            return e 
        end
        if e.elementWithId then
            local element = e:elementWithId(id)
            if element ~= nil then 
                return element 
            end
        end
    end
    return nil
end

function Layout:style(styleRules)
    mortar.style(self, styleRules)
end

local function default_constructor_for(ObjectClass)
    return function(...)
        params = {...}
        if #params == 3 then
            return ObjectClass.new(unpack(params))
        elseif #params == 2 then
            if type(params[1]) == "string" then
                return ObjectClass.new(params[1], nil, params[2])
            elseif type(params[1]) == "table" then
                return ObjectClass.new(nil, params[1], params[2])
            end
        elseif #params == 1 then
            return ObjectClass.new(nil, nil, params[1])
        end
        print("INVALID PARAMS!")
        if type(params) == "table" then
            for k, v in pairs(params) do
                print(k, v)
            end
        else
            print(params)
        end
    end
end

mortar.text       = default_constructor_for(Text)
mortar.button     = default_constructor_for(Button)
mortar.text_input = default_constructor_for(TextInput)
mortar.group      = default_constructor_for(Group)
mortar.layout     = default_constructor_for(Layout)

function mortar.style(object, styleRules)

end

return mortar