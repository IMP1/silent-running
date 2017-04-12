-- https://github.com/interstellarDAVE/lualib-voronoi/blob/working/voronoi.lua
local Voronoi = require 'lib.voronoi'
local Level   = require 'level'
local Rock    = require 'rock'

local LevelGenerator = {}

-- From: http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
-- create random distribution of points
-- generate Voronoi polygons
-- "relax" the points
-- decide on the outline of the level

function LevelGenerator.generate(width, height, seed)
    math.randomseed(seed)

    local n = 8 + math.random() * 16
    local pointcount = math.floor(width / n)
    local iterations = 3
    local minX = -32
    local minY = -32
    local maxX = width + 64
    local maxY = height + 64

    local map = Voronoi:new(pointcount, iterations, minX, minY, maxX, maxY)

    local rockiness = 0.4 + math.random() / 4

    local rocks = {}
    for _, p in pairs(map.polygons) do
        if #p.points >= 6 then
            if math.random() <= rockiness then
                table.insert(rocks, Rock.new(unpack(p.points)))
            end
        end
    end

    return Level.new(rocks)

end

return LevelGenerator