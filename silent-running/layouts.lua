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

layouts.title = mortar.layout({"0", "0", "100", "100"}, {
    elements = {
        mortar.text("title", {"0", "10", "100", "10", "top", "center"}, {
            text = T"Welcome to Silent Running",
        }),
        mortar.group("options", {"0", "30", "100", "60", "top", "center"}, {
            elements = {
                mortar.button({"55", "30", "30", "10"}, {
                    text = T"Start a Server",
                    onclick = function(self) startServer() end,
                    focusKey = { "S", }
                }),
                mortar.text_input("ipAddress", {"10", "50", "35", "10"}, {
                    placeholder = T"IP Address",
                    style = {
                        padding = { 8, 8, 8, 8},
                    },
                    validation = {
                        {
                            pattern = ".+",
                            element = mortar.text({
                                text = T"IP Address cannot be empty.",
                            })
                        },
                        {
                            custom = function(self, value)
                                return not value:find("[%w]")
                            end,
                            element = mortar.text({
                                text = T"IP Address cannot contain any characters other than numbers and full stops.",
                            })
                        },
                    },
                }),
                mortar.button({"55", "50", "30", "10"}, {
                    text = T"Join a Server",
                    onclick = function(self)
                        local input = self:layout():elementWithId("ipAddress")
                        input:validate(true)
                        if input.valid then
                            -- TODO: try to connect before going to client role
                            local address = input:value()
                            joinServer(address)
                        end
                    end,
                }),
            },
        }),
    },
})
mortar.style(layouts.title, {
    ["text#title"] = {
        textColor = {0, 128, 128},
    },
    ["button"] = {
        backgroundColor = {0, 32, 32},
    }
})

layouts.server = {}
layouts.server.info = mortar.layout({2, 2, "100", "100"}, {
    elements = {
        mortar.text({"4", "0", "100", "100"}, {
            text = T"Hosting Server"
        }),
        mortar.icon({"0", "4", "100", "100"}, {
            icon = "",
            size = 20,
        }),
        mortar.text({"4", "4", "100", "100"}, {
            text = T"IP Adresss"
        }),
        mortar.text("ipAddress", {"20", "4", "100", "100"}, {
            text = function() return role.server:getSocketAddress():match(".+:"):sub(1, -2) end
        }),
        mortar.text({"4", "8", "100", "100"}, {
            text = T"Port"
        }),
        mortar.text("port", {"20", "8", "100", "100"}, {
            text = function() return role.server:getSocketAddress():match(":.+"):sub(2) end
        }),
        mortar.icon({"0", "12", "100", "100"}, {
            icon = "",
            size = 20
        }),
        mortar.text({"4", "12", "100", "100"}, {
            text = T"Connected Players"
        }),
        mortar.text("playerCount", {"20", "12", "100", "100"}, {
            text = function() return tostring(#role.server.clients) end
        }),
    },
    style = {
        padding = { 2, 2, 2, 2 },
        backgroundColor = {0, 0, 0},
        borderColor = {255, 255, 255},
    }  
})

local iconFont = love.graphics.newFont("gfx/fontawesome-webfont.ttf", 20)
local function drawCheckbox(self)
    mortar.graphics.push()
    mortar.graphics.setFont(iconFont)
    local x, y, w, h = unpack(self:getRelativeBounds())
    x = x + self.style.margin[1]
    y = y + self.style.margin[2]
    mortar.graphics.push()
    if self.focus then
        mortar.graphics.setColor(self.style.borderColorFocus)
    else
        mortar.graphics.setColor(self.style.borderColor)
    end
    love.graphics.print("", x, y)
    mortar.graphics.pop()
    mortar.graphics.setColor(self.style.textColor)
    if self.selected then
        love.graphics.print("", x + 1, y - 3)
    end
    mortar.graphics.pop()
    love.graphics.print(self.text(), x + 24, y)
end

layouts.server.commands = mortar.layout({2, -122, 152, 120}, {
    elements = {
        mortar.checkbox({"0", 0, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show map",
            onchange = function() 
                DEBUG.showMap = not DEBUG.showMap 
            end,
            selected = DEBUG.showMap,
            style = {
                customDraw = drawCheckbox
            }
        }),
        mortar.checkbox({"0", 20, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show map objects",
            onchange = function() 
                DEBUG.showMapObjects = not DEBUG.showMapObjects 
            end,
            selected = DEBUG.showMapObjects,
            style = {
                customDraw = drawCheckbox
            }
        }),
        mortar.checkbox({"0", 40, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show game objects",
            onchange = function() 
                DEBUG.showGameObjects = not DEBUG.showGameObjects 
            end,
            selected = DEBUG.showGameObjects,
            style = {
                customDraw = drawCheckbox
            }
        }),
        mortar.checkbox({"0", 60, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show player info",
            onchange = function() 
                DEBUG.showPlayerInfo = not DEBUG.showPlayerInfo 
            end,
            selected = DEBUG.showPlayerInfo,
            style = {
                customDraw = drawCheckbox
            }
        }),
        mortar.checkbox({"0", 80, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show log",
            onchange = function() 
                DEBUG.showLog = not DEBUG.showLog 
            end,
            selected = DEBUG.showLog,
            style = {
                customDraw = drawCheckbox
            }
        }),
        mortar.checkbox({"0", 100, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show commands",
            onchange = function() 
                DEBUG.showCommands = false
                role:hideCommands()
                return true -- cancel the normal checkbox behaviour.
            end,
            selected = true,
            style = {
                customDraw = drawCheckbox
            }
        }),
    },
    style = {
        padding = { 2, 2, 2, 2 },
        backgroundColor = {0, 0, 0},
        borderColor = {255, 255, 255},
    }  
})

layouts.server.commandsHidden = mortar.layout({2, -22, 136, 20}, {
    elements = {
        mortar.checkbox({"0", 0, "100", 16}, {
            width  = 16,
            height = 16,
            text = T"Show commands",
            onchange = function() 
                role:showCommands()
                return true -- cancel the normal checkbox behaviour.
            end,
            selected = false,
            style = {
                customDraw = drawCheckbox
            }
        }),
    },
    style = {
        padding = { 2, 2, 2, 2 },
        backgroundColor = {0, 0, 0},
        borderColor = {255, 255, 255},
    }  
})

return layouts
