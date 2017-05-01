local Noise = require 'noise'

local PongGhost = {
    RADIUS = {
        [true] = 64,
        [false] = 128
    },
    START_RADIUS = {
        [true] = 16,
        [false] = 32
    },
    FADE_SPEED = {
        [true] = 128,
        [false] = 64
    },
    GROW_SPEED = {
        [true] = 256,
        [false] = 256
    }
}
PongGhost.__index = PongGhost

function PongGhost.new(x, y, imageDataString, isActive)
    return Noise.new(x, y, imageDataString, 
                        PongGhost.RADIUS[isActive],
                        PongGhost.START_RADIUS[isActive],
                        PongGhost.GROW_SPEED[isActive],
                        PongGhost.FADE_SPEED[isActive],
                        255)
end

return PongGhost
