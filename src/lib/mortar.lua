local utf8 = require("utf8")

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

--------------------------------------------------------------------------------
-- # Element
--------------
-- A generic UI element, with common properties and actions.
--------------------------------------------------------------------------------

local element = {}
element.__index = element

function element.new(id, pos, options)
    local obj = {}

    obj.id    = id
    obj.pos   = pos or {0, 0, 100, 100, "top", "left"}
    obj.tags  = options.tags or {}
    obj.style = options.style or {}

    return obj
end

function element.getScreenBounds(self)
    if self.parent == nil then
        parentBounds = { 0, 0, love.graphics.getWidth(), love.graphics.getHeight() }
    else
        parentBounds = element.getScreenBounds(self.parent)
    end
    return {
        parentBounds[1] + self.pos[1] * parentBounds[3] / 100,
        parentBounds[2] + self.pos[2] * parentBounds[4] / 100,
        parentBounds[3] * self.pos[3] / 100,
        parentBounds[4] * self.pos[4] / 100
    }
end

function element.isMouseOver(self, mx, my)
    local bounds = element.getScreenBounds(self)
    local x, y, w, h = unpack(bounds)
    return (mx >= x and 
            my >= y and 
            mx <= x + w and 
            my <= y + h)
end

--------------------------------------------------------------------------------
-- # Button
--------------
-- A simple text button class. It is connected to an action which will fire when
-- the button is clicked.
--------------------------------------------------------------------------------
local Button = {}
Button.__index = Button
function Button:__tostring()
    return "<Button>"
end

function Button.new(id, position, options)
    local this = element.new(id, pos, options)
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
function Text:__tostring()
    return "<Text>"
end

function Text.new(id, position, options)
    local this = element.new(id, position, options)
    setmetatable(this, Text)
    this.text = options.text or ""
    return this
end

function Text:draw()
    if self.style.font then
        -- TODO: set font. reset old font afterwards?
    end
    local x, y, w, h = unpack(element.getScreenBounds(self))
    local align = self.pos[6]
    love.graphics.printf(self.text, x, y, w, align)
end

--------------------------------------------------------------------------------
-- # TextInput
--------------
-- A class for allowing a user to input text. 
--------------------------------------------------------------------------------
local TextInput = {}
TextInput.__index = TextInput
function TextInput:__tostring()
    return "<TextInput>"
end

function TextInput.new(id, position, options)
    local this = element.new(id, pos, options)
    setmetatable(this, TextInput)
    this.placeholder = options.placeholder or ""
    this.selected    = false
    this.text        = ""
    return this
end

function TextInput:mousepressed(mx, my, key)
    self.selected = element.isMouseOver(self, mx, my)
end

function TextInput:keypressed(key, isRepeat)
    if not self.selected then return end
    if key == "backspace" then
        -- SEE: https://love2d.org/wiki/love.textinput
        local offset = utf8.offset(self.text, -1)
        if offset then
            self.text = self.text:sub(1, offset - 1)
        end
    end
end

function TextInput:keytyped(text)
    if not self.selected then return end
    self.text = self.text .. text
end

--------------------------------------------------------------------------------
-- # Group
--------------
-- A group of other elements.
--------------------------------------------------------------------------------
local Group = {}
Group.__index = Group
function Group:__tostring()
    return "<Group>"
end

function Group.new(id, position, options)
    local this = element.new(id, pos, options)
    setmetatable(this, Group)
    this.elements = options.elements or {}
    for _, e in pairs(this.elements) do
        e.parent = this
    end
    return this
end

function Group:mousepressed(mx, my, key)
    if element.isMouseOver(self, mx, my) then
        for _, e in pairs(self.elements) do
            if e.mousepressed then
                e:mousepressed(mx, my, key)
            end
        end
    end
end

function Group:keytyped(text)
    for _, e in pairs(self.elements) do
        if e.keytyped then
            e:keytyped(text)
        end
    end
end

function Group:keypressed(key, isRepeat)
    for _, e in pairs(self.elements) do
        if e.keypressed then
            e:keypressed(text)
        end
    end
end

--------------------------------------------------------------------------------
-- # Layout
--------------
-- The top-level container.
--------------------------------------------------------------------------------
local Layout = {}
Layout.__index = Layout
function Layout:__tostring()
    return "<Layout>"
end

function Layout.new(id, position, options)
    local this = element.new(id, pos, options)
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
    if element.isMouseOver(self, mx, my) then
        for _, e in pairs(self.elements) do
            if e.mousepressed then
                e:mousepressed(mx, my, key)
            end
        end
    end
end

function Layout:keytyped(text)
    for _, e in pairs(self.elements) do
        if e.keytyped then
            e:keytyped(text)
        end
    end
end

function Layout:keypressed(key, isRepeat)
    for _, e in pairs(self.elements) do
        if e.keypressed then
            e:keypressed(text)
        end
    end
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