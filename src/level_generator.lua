local LevelGenerator = {}

function LevelGenerator.generate(seed)
    math.randomseed(seed)

    -- From: http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
    -- create random distribution of points
    -- generate Voronoi polygons
    -- "relax" the points
    -- decide on the outline of the level

end

return LevelGenerator