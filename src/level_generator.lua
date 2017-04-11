-- https://github.com/interstellarDAVE/lualib-voronoi/blob/working/voronoi.lua
local Voronoi = require 'lib.voronoi'
local Level = require 'level'

local LevelGenerator = {}

-- From: http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
-- create random distribution of points
-- generate Voronoi polygons
-- "relax" the points
-- decide on the outline of the level

function LevelGenerator.generate(width, height, seed)
    math.randomseed(seed)

    local pointcount = 40
    local iterations = 3
    local minX = -32
    local minY = -32
    local maxX = width + 64
    local maxY = height + 64

    map = Voronoi:new(pointcount, iterations, minX, minY, maxX, maxY)

    return Level.new(map)

end

return LevelGenerator