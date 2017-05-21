local mortar = require 'lib.mortar'

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
        mortar.text("ipAddress", {20, 4, 100, 100}, {
            text = function() return role.server:getSocketAddress() end
        }),
        mortar.text({0, 8, 100, 100}, {
            text = T"Connected Players"
        }),
        mortar.text("playerCount", {20, 8, 100, 100}, {
            text = function() return tostring(#role.server.clients) end
        }),
    },
})

layouts.server.commands = mortar.layout({0, 0, 100, 100}, {
    elements = {
        mortar.checkbox({0, 0, 100, 100}, {
            width  = 16,
            height = 16,
        })
    }
})

return layouts
