local Rock = {}
Rock.__index = Rock

function Rock.new(...)
    local this = {}
    setmetatable(this, Rock)
    this.polygon = {...}
    this.triangles = {}
    for i = 3, #this.polygon - 3, 2 do
        table.insert(this.triangles, {
            this.polygon[1], this.polygon[2], 
            this.polygon[i], this.polygon[i+1],
            this.polygon[i+2], this.polygon[i+3],
        })
    end
    return this
end

function Rock:containsPoint(x, y)
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
                return true
            end
        end
    end
    return false
end

return Rock

