local Screen = {}
Screen.__index = Screen

Screen.WIDTH = love.window.getWidth()
Screen.HEIGHT = love.window.getHeight()

Screen.shakes = {}

function Screen.new()
    return Screen
end

function Screen:update(dt)
    local finishedShakes = {}
    for i, shake in pairs(Screen.shakes) do
        shake.duration = shake.duration - dt
        shake.power = shake.power * shake.degredation ^ dt
        if shake.duration <= 0 or shake.power <= 0 then
            table.insert(finishedShakes, i)
        end
    end
    for i = #finishedShakes, 1, -1 do
        table.remove(Screen.shakes, finishedShakes[i])
    end
end

function Screen:shake(duration, power, degredation)
    local s = { duration = duration, power = power, degredation = (degredation or 1) }
    table.insert(Screen.shakes, s)
end

function Screen:set(paused)
    love.graphics.push()
    if not paused then
        local biggestShake = 0
        for _, shake in pairs(Screen.shakes) do
            if shake.power > biggestShake then
                biggestShake = shake.power
            end
        end
        love.graphics.translate(math.random() * biggestShake - biggestShake / 2, (math.random() * biggestShake - biggestShake / 2) / 2 )
    end
end

function Screen:unset()
    love.graphics.pop()
end

return Screen
