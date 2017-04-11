local Level = {}
Level.__index = Level

function Level.new(voronoi)
    local this = {}
    setmetatable(this, Level)
    this.voronoi = voronoi
    return this
end

function Level:draw()
    for index,polygon in pairs(self.voronoi.polygons) do
        if #polygon.points >= 6 then
            love.graphics.setColor(50,50,50)
            love.graphics.polygon('fill',unpack(polygon.points))
            love.graphics.setColor(255,255,255)
            love.graphics.polygon('line',unpack(polygon.points))
        end
    end

    -- draw the points
    love.graphics.setColor(255,255,255)
    love.graphics.setPointSize(7)
    for index,point in pairs(self.voronoi.points) do
        love.graphics.point(point.x,point.y)
        love.graphics.print(index,point.x,point.y)
    end

    -- draws the centroids
    love.graphics.setColor(255,255,0)
    love.graphics.setPointSize(5)
    for index,point in pairs(self.voronoi.centroids) do
        love.graphics.point(point.x,point.y)
        love.graphics.print(index,point.x,point.y)
    end

    -- draws the relationship lines
    love.graphics.setColor(0,255,0)
    for pointindex,relationgroups in pairs(self.voronoi.polygonmap) do
        for badindex,subpindex in pairs(relationgroups) do
            love.graphics.line(self.voronoi.centroids[pointindex].x, self.voronoi.centroids[pointindex].y,
                               self.voronoi.centroids[subpindex].x,  self.voronoi.centroids[subpindex].y)
        end
    end
end

return Level