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
        mortar.text("title", {0, 10, 100, 10, "top", "centre"}, {
            text = "Welcome to Silent Running",
        }),
        mortar.group("options", {0, 30, 100, 60, "top", "centre"}, {
            elements = {
                mortar.button({
                    text = "Start a Server",
                    onclick = function() end,
                }),
                mortar.group({
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