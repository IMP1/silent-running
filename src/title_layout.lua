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

local layout = mortar.layout({0, 0, 100, 100}, {
    elements = {
        mortar.text("title", {0, 10, 100, 10, "top", "center"}, {
            text = "Welcome to Silent Running",
        }),
        mortar.group("options", {0, 30, 100, 60, "top", "center"}, {
            elements = {
                mortar.button({55, 30, 30, 10}, {
                    text = "Start a Server",
                    onclick = function(self) role = Server.new() end,
                }),
                mortar.text_input("ipAddress", {10, 50, 35, 10}, {
                    placeholder = "IP Address",
                }),
                mortar.button({55, 50, 30, 10}, {
                    text = "Join a Server",
                    onclick = function(self)
                        local address = self:layout():elementWithId("ipAddress"):value() or "localhost"
                        role = Client.new(address) 
                    end,
                }),
            },
        }),
    },
})

mortar.style(layout, {
    ["<text>#title"] = {
        font   = "",
        colour = {0, 128, 128},
    },

    
})

return layout
