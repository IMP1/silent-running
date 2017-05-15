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

--[[
    Elements:
        Button
        Group
        Layout
        Text
        TextInput

    Common Attributes:
        id    : string (can be nil)
        pos   : { 
            x,              : 0-100 (% of parent's width)
            y,              : 0-100 (% of parent's height)
            width,          : 0-100 (% of parent's width)
            height,         : 0-100 (% of parent's height)
            verticalAlign,  : "top", "bottom" or "middle"
            horizontalAlign : "left", "right", or "center"
        }
        tags  : list of strings
        style : list of style rules

    Style Rule:
        selector = {
            styleAttribute = value,
            styleAttribute = value,
            ...
        }

    Selector:
        <text> : matches text elements
        .green : matches elements with the tag 'green'
        #title : matches element with id 'title'
        <*>    : matches all elements

        <text>.green              : matches text elements with the tag 'green'
        #parent <*>               : matches all elements that are children of 
                                    an element with the tag #parent
        #my-form <button>.visible : matches button elements with the tag 
                                    'visible' that are children of elements 
                                    with the id 'my-form'.

    Style Attributes:
        color           : {r, g, b, a}
        font            : 
        backgroundColor : {r, g, b, a}
        borderWidth     : int
        borderColor     : {r, g, b, a}
        padding         : {left, top, right, bottom }
        customDraw      : function(element)

]]

-- https://airstruck.github.io/luigi/doc/classes/Layout.html

default_style = {
    common    = {
        backgroundColor = nil,
        borderColor     = nil,
        textColor       = {224, 224, 224},
        borderRadius    = {0, 0},
        margin          = {0, 0, 0, 0},
        padding         = {4, 4, 4, 4},

    },

    Button    = {
        backgroundColor = {32, 32, 32},
        borderColor     = {192, 192, 192},
        borderRadius    = {8, 8},
        padding         = {8, 8, 4, 4}
    },

    Group     = {},
    Layout    = {},
    Text      = {},
    TextInput = {},
}

--------------------------------------------------------------------------------
-- # Element
--------------
-- A generic UI element, with common properties and actions.
--------------------------------------------------------------------------------

local Element = {}
local Element_mt = { __index = Element }
Element.__index = Element

function Element.new(elementName, id, pos, options)
    local obj = {}
    obj._name = elementName

    obj.id    = id
    obj.pos   = pos or {0, 0, 100, 100, "top", "left"}
    obj.tags  = options.tags or {}
    obj.style = options.style or default_style[elementName]
    setmetatable(obj.style, {__index = default_style.common})
    obj.hover = false
    obj.focus = false

    return obj
end

function Element:getScreenBounds()
    local parentBounds
    if self.parent == nil then
        parentBounds = { 0, 0, love.graphics.getWidth(), love.graphics.getHeight() }
    else
        parentBounds = self.parent:getScreenBounds()
    end
    return {
        parentBounds[1] + self.pos[1] * parentBounds[3] / 100,
        parentBounds[2] + self.pos[2] * parentBounds[4] / 100,
        parentBounds[3] * self.pos[3] / 100,
        parentBounds[4] * self.pos[4] / 100
    }
end

function Element:getRelativeBounds()
    local x, y = unpack(self:getRelativePosition())
    local w, h = unpack(self:getSize())
    return { x, y, w, h }
end

function Element:isMouseOver(mx, my)
    local bounds = self:getScreenBounds()
    local x, y, w, h = unpack(bounds)
    return (mx >= x and 
            my >= y and 
            mx <= x + w and 
            my <= y + h)
end

function Element:getSize()
    if self.parent == nil then
        return { 
            love.graphics.getWidth(), 
            love.graphics.getHeight() 
        }
    else
        local parentSize = self.parent:getSize()
        return {
            parentSize[1] * self.pos[3] / 100,
            parentSize[2] * self.pos[4] / 100,
        }
    end
end

function Element:getRelativePosition()
    local parentSize
    if self.parent == nil then
        parentSize = { love.graphics.getWidth(), love.graphics.getHeight() }
    else
        parentSize = self.parent:getSize()
    end
    return {
        self.pos[1] * parentSize[1] / 100,
        self.pos[2] * parentSize[2] / 100
    }
end

function Element:layout()
    local top = self
    while top.parent do
        top = top.parent
    end
    return top
end

function Element:draw()
    if self.style.customDraw then 
        self.style.customDraw(self)
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
setmetatable(Button, Element_mt)
Button.__index = Button
function Button:__tostring()
    return "<Button:" .. (self.id or "") .. ">"
end

function Button.new(id, position, options)
    local this = Element.new("Button", id, position, options, options.style)
    setmetatable(this, Button)
    this.text     = options.text or ""
    this.onclick  = options.onclick
    return this
end

function Button:update(dt, mx, my)
    self.hover = self:isMouseOver(mx, my)
end

function Button:draw()
    if self.style.customDraw then 
        self.style.customDraw(self)
        return
    end
    -- get positions
    local x, y, w, h = unpack(self:getRelativeBounds())
    x = x + self.style.margin[1]
    y = y + self.style.margin[2]
    w = w - (self.style.margin[1] + self.style.margin[3])
    h = h - (self.style.margin[2] + self.style.margin[4])
    local rx, ry = unpack(self.style.borderRadius)
    local align = self.pos[6]
    -- draw shape
    if self.style.backgroundColor then
        mortar.graphics.setColor(unpack(self.style.backgroundColor))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    end
    -- draw border
    mortar.graphics.setColor(unpack(self.style.borderColor))
    love.graphics.rectangle("line", x, y, w, h, rx, ry)
    -- draw content
    x = x + self.style.padding[1]
    y = y + self.style.padding[2]
    w = w - (self.style.margin[1] + self.style.padding[3])
    h = h - (self.style.margin[2] + self.style.padding[4])
    mortar.graphics.setColor(unpack(self.style.textColor))
    love.graphics.printf(self.text, x, y, w, align)
end

function Button:mousepressed(mx, my, key)
    self.selected = self:isMouseOver(mx, my)
end

function Button:mousereleased(mx, my, key)
    if self:isMouseOver(mx, my) and key == 1 then
        self:onclick()
    end
end

--------------------------------------------------------------------------------
-- # Text
--------------
-- A simple class for displaying text. 
--------------------------------------------------------------------------------
local Text = {}
setmetatable(Text, Element_mt)
Text.__index = Text
function Text:__tostring()
    return "<Text:" .. tostring(self.id) .. ">"
end

function Text.new(id, position, options)
    local this = Element.new("Text", id, position, options)
    setmetatable(this, Text)
    this.text = options.text or ""
    return this
end

function Text:draw()
    if self.style.font then
        -- TODO: set font. reset old font afterwards?
    end
    local x, y, w, h = unpack(self:getRelativeBounds())
    local align = self.pos[6]
    love.graphics.printf(self.text, x, y, w, align)
end

--------------------------------------------------------------------------------
-- # TextInput
--------------
-- A class for allowing a user to input text. 
--------------------------------------------------------------------------------
local TextInput = {}
setmetatable(TextInput, Element_mt)
TextInput.__index = TextInput
function TextInput:__tostring()
    return "<TextInput>"
end

function TextInput.new(id, position, options)
    local this = Element.new("TextInput", id, position, options)
    setmetatable(this, TextInput)
    this.placeholder   = options.placeholder or ""
    this.focus         = false
    this.text          = {}
    this.index         = #this.text
    this.flashSpeed    = 0.5
    this.flashTimer    = 0
    this.cursorVisible = true
    return this
end

function TextInput:update(dt, mx, my)
    self.hover = self:isMouseOver(mx, my)
    if self.focus then
        self.flashTimer = self.flashTimer + dt
        if self.flashTimer > self.flashSpeed then
            self.cursorVisible = not self.cursorVisible
            self.flashTimer = self.flashTimer - self.flashSpeed
        end
    end
end

function TextInput:mousereleased(mx, my, key)
    self.focus = self:isMouseOver(mx, my)
end

function TextInput:keypressed(key, isRepeat)
    -- SEE: https://love2d.org/wiki/love.textinput
    if not self.focus then return end
    if key == "backspace" then
        if self.index > 0 and #self.text > 0 then
            table.remove(self.text, self.index)
            self.index = self.index - 1
        end
    end
    if key == "delete" then
        if #self.text > 0 and self.text[self.index + 1] then
            table.remove(self.text, self.index + 1)
        end
    end
    if key == "left" and self.index > 0 then
        self.index = self.index - 1
    end
    if key == "right" and self.index < #self.text then
        self.index = self.index + 1
    end
end

function TextInput:value()
    local text = ""
    for i, char in ipairs(self.text) do
        text = text .. char
    end
    return text
end

function TextInput:keytyped(text)
    if not self.focus then return end
    table.insert(self.text, self.index + 1, text)
    self.index = self.index + 1
end

function TextInput:draw()
    local font = love.graphics.getFont()
    local x, y, w, h = unpack(self:getRelativeBounds())
    if self.focus then
        love.graphics.setColor(128, 128, 255)
    else
        love.graphics.setColor(192, 192, 192)
    end
    love.graphics.line(x, y + h, x + w, y + h)
    local text = self:value()
    if text:len() == 0 then
        love.graphics.setColor(128, 128, 128)
        love.graphics.printf(self.placeholder, x, y, w, self.pos[6])
    end
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf(text, x, y, w, self.pos[6])
    if self.focus and self.cursorVisible then
        local ox = 0
        for i = 1, self.index do
            ox = ox + font:getWidth(self.text[i])
        end
        local a = math.floor(x + ox) + 0.5
        local b = math.floor(y) + 0.5
        local c = math.floor(y + h) + 0.5
        -- love.graphics.line(x + ox, y, x + ox, y + h)
        love.graphics.line(a, b, a, c)
    end
end

--------------------------------------------------------------------------------
-- # Group
--------------
-- A group of other elements.
--------------------------------------------------------------------------------
local Group = {}
local Group_mt = { __index = Group }
setmetatable(Group, Element_mt)
Group.__index = Group
function Group:__tostring()
    return "<Group:" .. (self.id or "") .. ">"
end

function Group.new(id, position, options)
    local this = Element.new("Group", id, position, options)
    setmetatable(this, Group)
    this.elements = options.elements or {}
    for _, e in pairs(this.elements) do
        e.parent = this
    end
    return this
end

function Group:mousepressed(mx, my, key)
    if self:isMouseOver(mx, my) then
        for _, e in pairs(self.elements) do
            if e.mousepressed then
                e:mousepressed(mx, my, key)
            end
        end
    end
end

function Group:mousereleased(mx, my, key)
    if self:isMouseOver(mx, my) then
        for _, e in pairs(self.elements) do
            if e.mousereleased then
                e:mousereleased(mx, my, key)
            end
        end
    end
end

function Group:update(dt, mx, my)
    for _, e in pairs(self.elements) do
        if e.update then
            e:update(dt, mx, my)
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
            e:keypressed(key, isRepeat)
        end
    end
end

function Group:elementWithId(id)
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

function Group:draw()
    love.graphics.push()
    local x, y = unpack(self:getRelativePosition())
    love.graphics.translate(x, y)

    for _, element in pairs(self.elements) do
        if element.draw then
            element:draw()
        end
    end

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- # Layout
--------------
-- The top-level container.
--------------------------------------------------------------------------------
local Layout = {}
setmetatable(Layout, Group_mt)
Layout.__index = Layout
function Layout:__tostring()
    return "<Layout>"
end

function Layout.new(id, position, options)
    local this = Element.new("Layout", id, position, options)
    setmetatable(this, Layout)
    this.elements = options.elements or {}
    for _, e in pairs(this.elements) do
        e.parent = this
    end
    return this
end

function Layout:style(styleRules)
    mortar.style(self, styleRules)
end

function Layout:draw()
    mortar.graphics.setLineStyle("rough")
    Group.draw(self)
    mortar.graphics.refresh()
end

mortar.graphics = {old = {}}
setmetatable(mortar.graphics, {
    __index = function(table, key)
        if key:find("set") and love.graphics[key] then
            local getter = key:gsub("set", "get", 1)
            local currentValue = { love.graphics[getter]() }
            if not mortar.graphics.old[getter] then
                mortar.graphics.old[getter] = currentValue
            end
            return love.graphics[key]
        elseif key:find("get") and mortar.graphics.old[key] then
            return mortar.graphics.old[key]
        else
            return rawget(table, key)
        end
    end
})

function mortar.graphics.refresh()
    for key, value in pairs(mortar.graphics.old) do
        local setter = key:gsub("get", "set", 1)
        love.graphics[setter](unpack(value))
    end
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
    for selector, rules in pairs(styleRules) do

    end
end

return mortar