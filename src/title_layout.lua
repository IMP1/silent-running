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
                mortar.button({0, 0, 50, 100}, {
                    text = "Start a Server",
                    onclick = function() end,
                }),
                mortar.group({50, 0, 50, 100}, {
                    elements = {
                        mortar.text_input("ipAddress", {
                            placeholder = "IP Address",
                        }),
                        mortar.button({
                            text = "Join a Server",
                            onclick = function() end,
                        }),
                    },
                }),
            },
        }),
    },
})

mortar.style(layout, {
    ["{text}"] = {
        font   = "",
        colour = "",
    },

    
})

return layout