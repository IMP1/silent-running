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

local default_style = {
    common    = {
        backgroundColor = nil,
        borderColor     = nil,
        textColor       = {224, 224, 224},
        borderRadius    = {0, 0},
        margin          = {0, 0, 0, 0},
        padding         = {4, 4, 4, 4},

    },

    Button    = {
        backgroundColorFocus  = {32, 32, 32},
        backgroundColorActive = {64, 64, 64},
        backgroundColor       = {32, 32, 32},
        borderRadius          = {8, 8},
        borderColor           = {192, 192, 192},
        borderColorFocus      = {128, 128, 255},
        borderColorActive     = {192, 192, 192},
        padding               = {8, 8, 4, 4}
    },

    Group     = {},
    Layout    = {},
    Text      = {},
    Checkbox  = {
        borderColor           = {192, 192, 192},
        borderColorFocus      = {128, 128, 255},
        backgroundColor       = {32, 32, 32},
        backgroundColorFocus  = {32, 32, 32},
    },
    TextInput = {
        borderColor        = {192, 192, 192},
        borderColorFocus   = {128, 128, 255},
        borderColorInvalid = {192, 128, 128},
        placeholderColor   = {128, 128, 128},
        textColor          = {255, 255, 255},
        textColorInvalid   = {255, 255, 255},
        cursorColor        = {255, 255, 255},

    },
}

--------------------------------------------------------------------------------
-- # Element
--------------
-- A generic UI element, with common properties and actions.
--------------------------------------------------------------------------------

local Element = {}
local Element_mt = { __index = Element }
Element.__index = Element
function Element:__tostring()
    return "<Element:" .. (self.id or "") .. ">"
end

function Element.new(elementName, id, pos, options)
    local obj = {}
    obj._name = elementName

    obj.id    = id
    obj.pos   = pos or {0, 0, 100, 100, "top", "left"}
    obj.tags  = options.tags or {}
    obj.style = options.style or {}
    for k, v in pairs (default_style[elementName]) do
        if obj.style[k] == nil then
            obj.style[k] = v
        end
    end
    setmetatable(obj.style, {__index = default_style.common})
    obj.hover = false
    obj.focus = false

    return obj
end

function Element:getScreenBounds()
    local parentBounds
    if self.parent == nil then
        parentBounds = { 
            0, 
            0, 
            love.graphics.getWidth(),
            love.graphics.getHeight(),
        }
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
    if options.text == nil then
        this.text = function () return "" end
    elseif type(options.text) == "string" then
        this.text = function() return options.text end
    elseif type(options.text) == "function" then
        this.text = options.text
    else
        error("[Mortar] Invalid text value: '" .. tostring(options.text) .. "' for Button.")
    end
    this.onclick = options.onclick or nil
    this.hover   = false
    this.focus   = false
    this.active  = false
    return this
end

function Button:update(dt, mx, my)
    self.hover = self:isMouseOver(mx, my)
end

function Button:isActive(mx, my)
    return self.active and self.hover
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
    if self:isActive() and self.style.backgroundColorActive then
        mortar.graphics.setColor(unpack(self.style.backgroundColorActive))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    elseif self.focus and self.style.backgroundColorFocus then
        mortar.graphics.setColor(unpack(self.style.backgroundColorFocus))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    elseif self.style.backgroundColor then
        mortar.graphics.setColor(unpack(self.style.backgroundColor))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    end
    -- draw border
    if self.active and self.style.borderColorActive then
        mortar.graphics.setColor(unpack(self.style.borderColorActive))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    elseif self.focus and self.style.borderColorFocus then
        mortar.graphics.setColor(unpack(self.style.borderColorFocus))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    elseif self.style.borderColor then
        mortar.graphics.setColor(unpack(self.style.borderColor))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    end
    -- draw content
    x = x + self.style.padding[1]
    y = y + self.style.padding[2]
    w = w - (self.style.padding[1] + self.style.padding[3])
    h = h - (self.style.padding[2] + self.style.padding[4])
    mortar.graphics.setColor(unpack(self.style.textColor))
    love.graphics.printf(self.text(), x, y, w, align)
end

function Button:keypressed(key, isRepeat)
    if self.focus and key == "space" then
        self.active = true
        self:onclick()
    end
end

function Button:mousepressed(mx, my, key)
    self.active = self:isMouseOver(mx, my)
    self.focus  = self:isMouseOver(mx, my)
end

function Button:mousereleased(mx, my, key)
    if self:isActive(mx, my) and key == 1 and self.onclick then
        self:onclick()
    end
    self.active = false
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
    if options.text == nil then
        this.text = function () return "" end
    elseif type(options.text) == "string" then
        this.text = function() return options.text end
    elseif type(options.text) == "function" then
        this.text = options.text
    else
        error("[Mortar] Invalid text value: '" .. tostring(options.text) .. "' for Text.")
    end
    this.cannotTarget = true
    return this
end

function Text:draw()
    if self.style.font then
        -- TODO: set font. reset old font afterwards?
    end
    local x, y, w, h = unpack(self:getRelativeBounds())
    local align = self.pos[6]
    love.graphics.printf(self.text(), x, y, w, align)
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
    return "<TextInput:" .. (self.id or "") .. ">"
end

function TextInput.new(id, position, options)
    local this = Element.new("TextInput", id, position, options)
    setmetatable(this, TextInput)
    this.placeholder   = options.placeholder or ""
    this.pattern       = options.pattern or nil
    this.text          = options.text or {}
    this.index         = #this.text
    this.focus         = false
    this.flashSpeed    = 0.5
    this.flashTimer    = 0
    this.cursorVisible = true
    this.valid         = true
    this:validate()
    return this
end

function TextInput:validate(force)
    if not self.pattern then
        self.valid = true
        return
    end
    if #self.text == 0 and not force then
        self.valid = true
        return
    end
    local text = self:value()
    self.valid = (text:match(self.pattern) == text)
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
            self:validate()
        end
    end
    if key == "delete" then
        if #self.text > 0 and self.text[self.index + 1] then
            table.remove(self.text, self.index + 1)
            self:validate()
        end
    end
    if key == "left" and self.index > 0 then
        self.index = self.index - 1
    end
    if key == "right" and self.index < #self.text then
        self.index = self.index + 1
    end
    if (key == "v" and love.keyboard.isDown("lctrl", "rctrl")) or
        (key == "insert" and love.keyboard.isDown("lshift", "rshift")) then
        self:keytyped(love.system.getClipboardText())
        self:validate()
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
    for c in text:gmatch(".") do
        table.insert(self.text, self.index + 1, c)
        self.index = self.index + 1
    end
    self:validate()
end

function TextInput:draw()
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
    if not self.valid and self.style.borderColorInvalid then
        mortar.graphics.setColor(unpack(self.style.borderColorInvalid))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    elseif self.focus and self.style.borderColorFocus then
        mortar.graphics.setColor(unpack(self.style.borderColorFocus))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    elseif self.style.borderColor then
        mortar.graphics.setColor(unpack(self.style.borderColor))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    end
    -- draw content
    x = x + self.style.padding[1]
    y = y + self.style.padding[2]
    w = w - (self.style.padding[1] + self.style.padding[3])
    h = h - (self.style.padding[2] + self.style.padding[4])
    
    if self.style.font then
        mortar.graphics.setFont(self.style.font)
    end
    
    if not self.valid and self.style.borderColorInvalid then
        mortar.graphics.setColor(unpack(self.style.borderColorInvalid))
    elseif self.focus and self.style.borderColorFocus then
        mortar.graphics.setColor(unpack(self.style.borderColorFocus))
    elseif self.style.borderColor then
        mortar.graphics.setColor(unpack(self.style.borderColor))
    end
    love.graphics.line(x, y + h, x + w, y + h)

    local font = love.graphics.getFont()
    local text = self:value()
    if text:len() == 0 then
        mortar.graphics.setColor(unpack(self.style.placeholderColor))
        love.graphics.printf(self.placeholder, x, y, w, self.pos[6])
    end

    if not self.valid and self.style.textColorInvalid then
        mortar.graphics.setColor(unpack(self.style.textColorInvalid))
    else
        mortar.graphics.setColor(unpack(self.style.textColor))
    end
    love.graphics.printf(text, x, y, w, self.pos[6])

    if self.focus and self.cursorVisible then
        local ox = 0
        for i = 1, self.index do
            ox = ox + font:getWidth(self.text[i])
        end
        local ch = font:getHeight()
        mortar.graphics.setColor(unpack(self.style.cursorColor))
        love.graphics.line(x + ox, y, x + ox, y + ch)
    end
end

--------------------------------------------------------------------------------
-- # Checkbox
--------------
-- A class for allowing a user to toggle options on and off.
--------------------------------------------------------------------------------
local Checkbox = {}
setmetatable(Checkbox, Element_mt)
Checkbox.__index = Checkbox
function Checkbox:__tostring()
    return "<Checkbox:" .. (self.id or "") .. ">"
end

function Checkbox.new(id, position, options)
    local this = Element.new("Checkbox", id, position, options)
    setmetatable(this, Checkbox)
    this.focus    = false
    this.selected = options.selected or false
    this.onchange = options.onchange or nil
    this.width    = options.width    or 16
    this.height   = options.height   or 16
    return this
end

function Checkbox:mousereleased(mx, my, key)
    print("mousereleased")
    if self:isMouseOver(mx, my) then
        self.selected = not self.selected
        if self.onchange then
            self:onchange(self.selected)
        end
        self.focus = true
    else
        print("unselected")
    end
end

function Checkbox:draw()
    if self.style.customDraw then 
        self.style.customDraw(self)
        return
    end
    -- get positions
    local x, y, w, h = unpack(self:getRelativeBounds())
    x = x + self.style.margin[1]
    y = y + self.style.margin[2]
    w = self.width
    h = self.height
    local rx, ry = unpack(self.style.borderRadius)
    -- draw shape
    if self.focus and self.style.backgroundColorFocus then
        mortar.graphics.setColor(unpack(self.style.backgroundColorFocus))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    elseif self.style.backgroundColor then
        mortar.graphics.setColor(unpack(self.style.backgroundColor))
        love.graphics.rectangle("fill", x, y, w, h, rx, ry)
    end
    -- draw border
    if self.focus and self.style.borderColorFocus then
        mortar.graphics.setColor(unpack(self.style.borderColorFocus))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    elseif self.style.borderColor then
        mortar.graphics.setColor(unpack(self.style.borderColor))
        love.graphics.rectangle("line", x, y, w, h, rx, ry)
    end
    -- draw content
    if self.selected then
        mortar.graphics.setColor(unpack(self.style.textColor))
        love.graphics.printf("X", x, y, w, "center")
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
    this.cannotTarget = true
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
    local stopped
    for _, e in pairs(self.elements) do
        if e.keypressed then
            stopped = e:keypressed(key, isRepeat)
        end
    end
end

function Group:selectNextElement(current, takeNext)
    if current == nil then takeNext = true end
    for _, e in pairs(self.elements) do
        if e.selectNextElement then
            local finished = e:selectNextElement(current, takeNext)
            if finished then return finished end
        end
        if takeNext and not e.cannotTarget then 
            e.focus = true
            return e
        end
        if e == current then
            e.focus = false
            takeNext = true
        end
    end
    return nil
end

function Group:selectPreviousElement(current, previous)
    for _, e in pairs(self.elements) do
        if e.selectPreviousElement then
            previous = e:selectPreviousElement(current, previous)
        end
        if e == current then
            e.focus = false
            if previous then previous.focus = true end
            return previous
        elseif not e.cannotTarget then
            previous = e
        end
    end
    if current == nil then
        if previous and not previous.cannotTarget then 
            previous.focus = true 
        end
    end
    return previous
end

function Group:elementWith(f, ...)
    for _, e in pairs(self.elements) do
        if f(e, ...) then
            return e
        end
        if e.elementWith then
            local element = e:elementWith(f, ...)
            if element then
                return element
            end
        end
    end
    return nil
end

function Group:elementWithId(id)
    local f = function(element, id)
        return element.id == id
    end
    return self:elementWith(f, id)
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

function Layout:keypressed(key, isRepeat)
    Group.keypressed(self, key, isRepeat)
    if key == "tab" and not stopped then
            local selectedElement = self:elementWith(function(e) return e.focus end)
        if love.keyboard.isDown("lshift", "rshift") then
            self:selectPreviousElement(selectedElement)
        else
            self:selectNextElement(selectedElement)
        end
    end
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
        print("INVALID PARAMS! " .. type(params))
        print(tostring(ObjectClass))
        if type(params) == "table" then
            print("table: size = " .. tostring(#params))
            for k, v in pairs(params) do
                print(k, v)
            end
        else
            print("Params: " .. tostring(params))
        end
        return ObjectClass.new(nil, nil, {})
    end
end

mortar.text       = default_constructor_for(Text)
mortar.button     = default_constructor_for(Button)
mortar.text_input = default_constructor_for(TextInput)
mortar.group      = default_constructor_for(Group)
mortar.layout     = default_constructor_for(Layout)
mortar.checkbox   = default_constructor_for(Checkbox)

function mortar.style(object, styleRules)
    for selector, rules in pairs(styleRules) do

    end
end

return mortar