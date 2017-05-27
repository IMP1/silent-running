function love.conf(game)
    game.identity = "silent-running"
 
    game.window.title = "Silent Running [Alpha v0.1.0]"
    game.window.icon = nil                 -- Filepath to an image to use as the window's icon (string)

    game.modules.math    = false
    game.modules.physics = false
    game.modules.video   = false
end