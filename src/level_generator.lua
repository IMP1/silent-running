-- https://github.com/interstellarDAVE/lualib-voronoi/blob/working/voronoi.lua
local voronoi = require 'lib.voronoi'

local LevelGenerator = {}

-- From: http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
-- create random distribution of points
-- generate Voronoi polygons
-- "relax" the points
-- decide on the outline of the level

function LevelGenerator.generate(seed)
    math.randomseed(seed)

    local pointcount = 40
    local iterations = 3
    local minX = 25
    local minY = 25
    local maxX = 600
    local maxY = 600

    map = voronoi:new(pointcount, iterations, minX, minY, maxX, maxY)

end

return LevelGenerator