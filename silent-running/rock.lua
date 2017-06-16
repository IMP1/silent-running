local Rock = {}
Rock.__index = Rock

function Rock.new(...)
    local this = {}
    setmetatable(this, Rock)
    this.polygon = {...}
    this.triangles = {}
    for i = 3, #this.polygon - 3, 2 do
        table.insert(this.triangles, {
            this.polygon[1],   this.polygon[2], 
            this.polygon[i],   this.polygon[i+1],
            this.polygon[i+2], this.polygon[i+3],
        })
    end
    this.lines = {}
    for i = 1, #this.polygon - 3, 2 do
        table.insert(this.lines, {
            points = {
                this.polygon[i],   this.polygon[i+1],
                this.polygon[i+2], this.polygon[i+3],  
            }
        })
    end
    local n = #this.polygon
    table.insert(this.lines, {
        points = {
            this.polygon[n-1], this.polygon[n],
            this.polygon[1],   this.polygon[2]
        },
    })
    for _, line in pairs(this.lines) do
        line.angle = math.atan2(line.points[4] - line.points[2], line.points[3] - line.points[1])
    end
    return this
end

function Rock:containsPoint(x, y)
    return self:getTriangle(x, y)
end

function Rock:getTriangle(x, y)
    for _, r in pairs(self.triangles) do
        -- http://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle/2049712#2049712
     -- local s = p0.Y * p2.X - p0.X * p2.Y + (p2.Y - p0.Y) * p.X + (p0.X - p2.X) * p.Y;
        local s = r[2] * r[5] - r[1] * r[6] + (r[6] - r[2]) * x   + (r[1] - r[5]) * y
     -- local t = p0.X * p1.Y - p0.Y * p1.X + (p0.Y - p1.Y) * p.X + (p1.X - p0.X) * p.Y;
        local t = r[1] * r[4] - r[2] * r[3] + (r[2] - r[4]) * x   + (r[3] - r[1]) * y
        if not ((s < 0) ~= (t < 0)) then
         -- local A = -p1.Y * p2.X + p0.Y * (p2.X - p1.X) + p0.X * (p1.Y - p2.Y) + p1.X * p2.Y;
            local A = -r[4] * r[5] + r[2] * (r[5] - r[3]) + r[1] * (r[4] - r[6]) + r[3] * r[6]
            
            if (A < 0.0) then
                s = -s
                t = -t
                A = -A
            end
            if s > 0 and t > 0 and (s + t) <= A then
                return r
            end
        end
    end
    return nil
end

local function segmentIntersects(x1, y1, x2, y2, x3, y3, x4, y4)
    -- from https://gist.github.com/voiceoftreason/1348463
    local d = (y4-y3)*(x2-x1)-(x4-x3)*(y2-y1)
    local Ua_n = ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3))
    local Ub_n = ((x2-x1)*(y1-y3)-(y2-y1)*(x1-x3))
    if d == 0 then
        --if Ua_n == 0 and Ua_n == Ub_n then
        --    return true
        --end
        return false
    end
    Ua = Ua_n / d
    Ub = Ub_n / d
    if Ua >= 0 and Ua <= 1 and Ub >= 0 and Ub <= 1 then
        return true
    end
    return false
end

function Rock:getBounceDirection(x2, y2, vx, vy)
    local x1, y1 = x2 - vx, y2 - vy
    for _, line in pairs(self.lines) do
        if segmentIntersects(x1, y1, x2, y2, unpack(line.points)) then
            print("bouncing off line!")
            local currentAngle = math.atan2(vy, vx)
            local currentSpeed = (vx*vx + vy*vy) ^ 0.5
            local newAngle = 2 * line.angle - currentAngle
            local newSpeed = currentSpeed * 0.9
            return newSpeed * math.cos(newAngle), newSpeed * math.sin(newAngle)
            -- TODO: find angle of reflection
            -- return -vx, -vy
        end
    end
    return vx, vy
end

function Rock:draw()
    love.graphics.polygon('fill', unpack(self.polygon))
end

return Rock

