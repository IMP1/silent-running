local Stats = {}

local function loadData()
    Stats.data = love.filesystem.load("progress")()
end

return Stats