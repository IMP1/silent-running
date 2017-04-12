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
    for _, triangle in pairs(self.triangles) do
        -- http://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle/2049712#2049712
    end
    return false
end

return Rock

