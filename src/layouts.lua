local mortar = require 'lib.mortar'

mortar.setIconFont("gfx/fontawesome-webfont.ttf")

--[[
<layout>
    <label class="title"></label>
    <group>
        <button>Start Server</button>
        <group>
            <input_text></input_text>
            <button>Join Server</button>
        </group>
    </group>
</layout>
]]

local layouts = {}

layouts.title = mortar.layout({0, 0, 100, 100}, {
    elements = {
        mortar.text("title", {0, 10, 100, 10, "top", "center"}, {
            text = T"Welcome to Silent Running",
        }),
        mortar.group("options", {0, 30, 100, 60, "top", "center"}, {
            elements = {
                mortar.button({55, 30, 30, 10}, {
                    text = T"Start a Server",
                    onclick = function(self) startServer() end,
                }),
                mortar.text_input("ipAddress", {10, 50, 35, 10}, {
                    placeholder = T"IP Address",
                    style = {
                        padding = { 8, 8, 8, 8},
                    },
                    pattern = "%d+%.%d+.%d+.%d+"
                }),
                mortar.button({55, 50, 30, 10}, {
                    text = T"Join a Server",
                    onclick = function(self)
                        local input = self:layout():elementWithId("ipAddress")
                        input:validate(true)
                        if input.valid then
                            local address = input:value()
                            role = Client.new(address) 
                            lobby = nil
                        end
                    end,
                }),
            },
        }),
    },
})
mortar.style(layouts.title, {
    ["<text>#title"] = {
        font   = "",
        colour = {0, 128, 128},
    },

    
})

layouts.server = {}
layouts.server.info = mortar.layout({0, 0, 100, 100}, {
    elements = {
        mortar.text({0, 0, 100, 100}, {
            text = T"Hosting Server"
        }),
        mortar.text({0, 4, 100, 100}, {
            text = T"IP Adresss"
        }),
        mortar.icon({16, 4, 100, 100}, {
            icon = "",
            size = 20,
        }),
        mortar.text("ipAddress", {20, 4, 100, 100}, {
            text = function() return role.server:getSocketAddress() end
        }),
        mortar.text({0, 8, 100, 100}, {
            text = T"Connected Players"
        }),
        mortar.icon({16, 8, 100, 100}, {
            icon = "",
            size = 20
        }),
        mortar.text("playerCount", {20, 8, 100, 100}, {
            text = function() return tostring(#role.server.clients) end
        }),
    },
})

layouts.server.commands = mortar.layout({2, 70, 100, 30}, {
    elements = {
        mortar.checkbox({0, 4, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show map",
            onchange = function() 
                DEBUG.showMap = not DEBUG.showMap 
            end,
            selected = DEBUG.showMap
        }),
        mortar.checkbox({0, 8, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show map objects",
            onchange = function() 
                DEBUG.showMapObjects = not DEBUG.showMapObjects 
            end,
            selected = DEBUG.showMapObjects
        }),
        mortar.checkbox({0, 12, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show game objects",
            onchange = function() 
                DEBUG.showGameObjects = not DEBUG.showGameObjects 
            end,
            selected = DEBUG.showGameObjects
        }),
        mortar.checkbox({0, 16, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show player info",
            onchange = function() 
                DEBUG.showPlayerInfo = not DEBUG.showPlayerInfo 
            end,
            selected = DEBUG.showPlayerInfo
        }),
        mortar.checkbox({0, 20, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show log",
            onchange = function() 
                DEBUG.showLog = not DEBUG.showLog 
            end,
            selected = DEBUG.showLog
        }),
        mortar.checkbox({0, 24, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show commands",
            onchange = function() 
                DEBUG.showCommands = false
                role:hideCommands()
                return true -- cancel the normal checkbox behaviour.
            end,
            selected = true
        }),
    },
    backgroundColor = {0, 0, 0}
})

layouts.server.commandsHidden = mortar.layout({2, 70, 100, 30}, {
    elements = {
        mortar.checkbox({0, 24, 100, 4}, {
            width  = 16,
            height = 16,
            text = T"Show commands",
            onchange = function() 
                role:showCommands()
                return true -- cancel the normal checkbox behaviour.
            end,
            selected = false
        }),
    },
})

return layouts
