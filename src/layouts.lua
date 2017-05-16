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
                    onclick = function(self) role = Server.new() end,
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

layouts.server = mortar.layout({0, 0, 100, 100}, {

})

return layouts
