---------------
-- Libraries --
---------------
local bitser = require "lib.bitser"
local sock   = require "lib.sock"

-------------
-- Classes --
-------------
local SceneBase = require 'scn_base'

--------------------------------------------------------------------------------
-- # GameOver
--------------
-- Handles the end of the game on the client side.
--------------------------------------------------------------------------------
local GameOver = {}
setmetatable(GameOver, SceneBase)
GameOver.__index = GameOver
 
function GameOver.new(port)
    local this = SceneBase.new("gameover")
    setmetatable(this, GameOver)
    this.layout = love.filesystem.load('layouts.lua')().gameOver
    return this
end

function GameOver:textinput(...)
    self.layout:keytyped(...)
end

function GameOver:keypressed(...)
    self.layout:keypressed(...)
end

function GameOver:mousepressed(...)
    self.layout:mousepressed(...)
end

function GameOver:mousereleased(...)
    self.layout:mousereleased(...)
end

function GameOver:update(dt)

end

function GameOver:draw()

end
