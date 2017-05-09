local mortar = require 'mortar'

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

layout = mortar.layout({
    mortar.title("Welcome to Silent Running"),
    mortar.group("options", {
        mortar.button({
            text = "Start a Server",
            onclick = function() end,
        }),
        mortar.group({
            mortar.text_input("ipAddress", {
                placeholder = "IP Address",
            })
            mortar.button({
                text = "Join a Server",
                onclick = function() end,
            }),
        })
    })
})

layout:style({
    title = {
        font   = "",
        colour = "",
    },
    
})

return layout