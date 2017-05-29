local bricks = require 'lib.bricks'
local mortar = require 'lib.mortar'
mortar.setup(bricks)

bricks.setIconFont("gfx/fontawesome-webfont.ttf")

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

-- Font Aweome Icons: http://fontawesome.io/cheatsheet/

local layouts = {}
layouts.title = {}

layouts.title.main = bricks.layout({
    bricks.text("title", {"0", "10", "100", "10", "top", "center"}, {
        text = T"Welcome to Silent Running",
    }),
    bricks.group("options", {"0", "30", "100", "60", "top", "center"}, {
        bricks.button({"55", "30", "30", "10"}, {
            onclick = function(self) 

            end,
            focusKey = { "s" }
        }, {
            bricks.text({text = T"Start a Server"}),
        }),
        bricks.button("connect", {"55", "50", "30", "10"}, {
            onclick = function(self)

            end,
        }, {
            bricks.text({text = T"Join a Server"}),
        }),
    }),
})
bricks.style(layouts.title.main, {
    ["text#title"] = {
        textColor = {0, 128, 128},
    },
    ["button"] = {
        backgroundColor = {0, 32, 32},
    }
})


layouts.title.server = bricks.layout({
    bricks.text("title", {"0", "10", "100", "10", "top", "center"}, {
        text = T"Start a server.",
    }),
    bricks.group({
        bricks.text_input("port", {"10", "50", "35", "10"}, {
            placeholder = T"Port",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            validation = {
                {
                    pattern = ".+",
                    element = bricks.text({
                        text = T"IP Address cannot be empty.",
                    })
                },
                {
                    pattern = "%d+",
                    element = bricks.text({
                        text = T"A port must be a number.",
                    })
                },
            },
        }),
    }),
    bricks.group("actions", {
        bricks.button({"55", "30", "30", "10"}, {
            onclick = function(self) print"back" end,
            focusKey = { "escape" }
        }, {
            bricks.text({text = T"Back"}),
        }),
        bricks.button({"55", "50", "30", "10"}, {
            onclick = function(self) startServer() end,
            focusKey = { "s" }
        }, {
            bricks.text({text = T"Start Server"}),
        }),
    })
})

layouts.title.client = bricks.layout({
    bricks.text("title", {"0", "10", "100", "10", "top", "center"}, {
        text = T"Join a server.",
    }),
    bricks.group({
        bricks.text_input("ipAddress", {"10", "50", "35", "10"}, {
            placeholder = T"IP Address",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            validation = {
                {
                    pattern = ".+",
                    element = bricks.text({
                        text = T"IP Address cannot be empty.",
                    })
                },
                {
                    custom = function(self, value)
                        if value:match("localhost") == value then return true end
                        return not value:find("[^%d%.]")
                    end,
                    element = bricks.text({
                        text = T"IP Address cannot contain any characters other than numbers and full stops.",
                    })
                },
            },
        }),
        bricks.text_input("port", {"10", "50", "35", "10"}, {
            placeholder = T"Port",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            validation = {
                {
                    pattern = ".+",
                    element = bricks.text({
                        text = T"IP Address cannot be empty.",
                    })
                },
                {
                    pattern = "%d+",
                    element = bricks.text({
                        text = T"A port must be a number.",
                    })
                },
            },
        }),
    }),
    bricks.group("actions", {
        bricks.button("back", {"55", "30", "30", "10"}, {
            onclick = function(self) print"back" end,
            focusKey = { "escape" }
        }, {
            bricks.text({text = T"Back"}),
        }),
        bricks.button("connect", {"55", "50", "30", "10"}, {
            onclick = function(self)
                local input = self:layout():elementWithId("ipAddress")
                input:validate(true)
                if input.valid then
                    -- TODO: try to connect before going to client role
                    local address = input:value()
                    attemptConnection(address)
                end
            end,
        }, {
            bricks.text({text = T"Join a Server"}),
        }),
        bricks.spinner("connectionSpinner", {"90", "50", 32, 32}, {
            visible = false,
        })
    })
})

layouts.server = {}
layouts.server.info = bricks.layout({2, 2, "40", "20"}, {
    elements = {
        bricks.text({4, 4, "100", "100"}, {
            text = T"Hosting Server"
        }),
        bricks.icon({4, "20", "100", "100"}, {
            icon = "",
            size = 20,
        }),
        bricks.text({32, "20", "100", "100"}, {
            text = T"IP Adresss"
        }),
        bricks.text("ipAddress", {"60", "20", "100", "100"}, {
            text = function() return role.server:getSocketAddress():match(".+:"):sub(1, -2) end
        }),
        bricks.text({32, "40", "100", "100"}, {
            text = T"Port"
        }),
        bricks.text("port", {"60", "40", "100", "100"}, {
            text = function() return role.server:getSocketAddress():match(":.+"):sub(2) end
        }),
        bricks.icon({4, "60", "100", "100"}, {
            icon = "",
            size = 20
        }),
        bricks.text({32, "60", "100", "100"}, {
            text = T"Connected Players"
        }),
        bricks.text("playerCount", {"60", "60", "100", "100"}, {
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
    bricks.graphics.push()
    bricks.graphics.setFont(iconFont)
    local x, y, w, h = unpack(self:getRelativeBounds())
    x = x + self.style.margin[1]
    y = y + self.style.margin[2]
    bricks.graphics.push()
    if self.focus then
        bricks.graphics.setColor(self.style.borderColorFocus)
    else
        bricks.graphics.setColor(self.style.borderColor)
    end
    love.graphics.print("", x, y)
    bricks.graphics.pop()
    bricks.graphics.setColor(self.style.textColor)
    if self.selected then
        love.graphics.print("", x + 1, y - 3)
    end
    bricks.graphics.pop()
    love.graphics.print(self.text(), x + 24, y)
end

layouts.server.commands = bricks.layout({2, -142, 152, 140}, {
    style = { 
            padding = { 2, 2, 2, 2 },
            backgroundColor = {0, 0, 0},
            borderColor = {255, 255, 255},
    }
},
{
    bricks.checkbox({"0", "0", "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show server info",
        onchange = function() 
            DEBUG.showServerInfo = not DEBUG.showServerInfo
        end,
        selected = DEBUG.showServerInfo,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", "14", "100", 16}, {
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
    bricks.checkbox({"0", "28", "100", 16}, {
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
    bricks.checkbox({"0", "42", "100", 16}, {
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
    bricks.checkbox({"0", "56", "100", 16}, {
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
    bricks.checkbox({"0", "70", "100", 16}, {
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
    bricks.checkbox({"0", "84", "100", 16}, {
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
})

layouts.server.commandsHidden = bricks.layout({2, -22, 136, 20}, {
    style = {
        padding = { 2, 2, 2, 2 },
        backgroundColor = {0, 0, 0},
        borderColor = {255, 255, 255},
    }
}, {
    bricks.checkbox({"0", 0, "100", 16}, {
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
})

return layouts
