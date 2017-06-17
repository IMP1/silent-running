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
        bricks.button("server", {"35", "30", "30", 32}, {
            focusKeys = { "s" }
        }, {
            bricks.text({text = T"Start a Server"}),
        }),
        bricks.button("connect", {"35", "50", "30", 32}, {
            focusKeys = { "j" }
        }, {
            bricks.text({text = T"Join a Server"}),
        }),
        bricks.button("settings", {"35", "70", "30", 32}, {
            focusKeys = { "o" }
        }, {
            bricks.text({text = T"Settings"}),
        }),
    }),
})

layouts.title.main:findFirst("button#server").onclick = function(self)
    mortar.swipe(layouts.title.main, layouts.title.server, {
        ox = -800,
        oy = 0,
        duration = 0.2,
        onfinish = function()
            scene.layout = layouts.title.server
        end
    })
end

layouts.title.main:findFirst("button#connect").onclick = function(self)
    mortar.swipe(layouts.title.main, layouts.title.client, {
        ox = -800,
        oy = 0,
        duration = 0.2,
        onfinish = function()
            scene.layout = layouts.title.client
        end
    })
end

layouts.title.server = bricks.layout({
    bricks.text("title", {"0", "10", "100", "10", "top", "center"}, {
        text = T"Start a server.",
    }),
    bricks.group({
        bricks.text_input("port", {"30", "50", "40", 32}, {
            placeholder = T"Port",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            text = tostring(DEFAULT_PORT),
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
        bricks.button("back", {"15", "70", "30", 32}, {
            onclick = function(self)
                mortar.swipe(layouts.title.server, layouts.title.main, {
                    ox = 800,
                    oy = 0,
                    duration = 0.2,
                    onfinish = function()
                        scene.layout = layouts.title.main
                    end
                })
            end,
            focusKeys = { "escape" }
        }, {
            bricks.text({text = T"Back"}),
        }),
        bricks.button({"55", "70", "30", 32}, {
            onclick = function(self) scene:startServer() end,
            focusKeys = { "s" }
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
        bricks.text_input("ipAddress", {"30", "40", "40", 32}, {
            placeholder = T"IP Address",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            text = "localhost",
            validation = {
                {
                    pattern = ".+",
                    oninvalid = function(self)
                        -- self:layout():elementWithId("errorMessageIpAddressEmpty").visible = true
                        mortar.flash(T"An IP Address cannot be empty.")
                    end,
                },
                {
                    custom = function(self, value)
                        if value:match("localhost") == value then return true end
                        return not value:find("[^%d%.]")
                    end,
                },
            },
        }),
        bricks.text("errorMessageIpAddressEmpty", {"32", "46", "40", 16}, {
            text = T"An IP Address cannot be empty.",
            visible = false,
            tags = {"error"},
        }),
        bricks.text("errorMessageIpAddressBad", {"32", "46", "40", 16}, {
            text = T"The format of the IP Address was incorrect.",
            visible = false,
            tags = {"error"},
        }),
        bricks.text_input("port", {"30", "50", "40", 32}, {
            placeholder = T"Port",
            style = {
                padding = { 8, 8, 8, 8 },
            },
            text = tostring(DEFAULT_PORT),
            validation = {
                {
                    pattern = ".+",
                    element = bricks.text({
                        text = T"Port cannot be empty.",
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
        bricks.button("back", {"15", "70", "30", 32}, {
            onclick = function(self) 
                mortar.swipe(layouts.title.client, layouts.title.main, {
                    ox = 800,
                    oy = 0,
                    duration = 0.2,
                    onfinish = function()
                        scene.layout = layouts.title.main
                    end
                })
            end,
            focusKeys = { "escape" }
        }, {
            bricks.text({text = T"Back"}),
        }),
        bricks.button("connect", {"55", "70", "30", 32}, {
            onclick = function(self)
                local input = self:layout():elementWithId("ipAddress")
                input:validate(true)
                if input.valid then
                    -- TODO: try to connect before going to client scene
                    local address = input:value()
                    scene:attemptConnection(address)
                end
            end,
        }, {
            bricks.text({text = T"Join a Server"}),
        }),
        bricks.spinner("connectionSpinner", {"50", "80", 32, 32}, {
            visible = false,
        })
    })
})

for _, l in pairs(layouts.title) do
    bricks.style(l, {
        ["text#title"] = {
            textColor = {0, 128, 128},
        },
        ["button"] = {
            backgroundColor = {0, 32, 32},
        },
        [".error"] = {
            textColor = {192, 64, 64},
        },
    })
end

layouts.server = {}
layouts.server.info = bricks.layout({2, 2, "40", "30"}, {
    style = {
        padding = { 2, 2, 2, 2 },
        backgroundColor = {0, 0, 0},
        borderColor = {255, 255, 255},
    }
}, {  
    bricks.text({4, 4, "100", "100"}, {
        text = T"Hosting Server"
    }),
    bricks.icon({4, 32, "100", "100"}, {
        icon = "",
        size = 20,
    }),
    bricks.text({32, 32, "100", "100"}, {
        text = T"IP Adresss"
    }),
    bricks.text("ipAddress", {"60", 32, "100", "100"}, {
        text = function() return scene.publicIp end
    }),
    bricks.text({32, 56, "100", "100"}, {
        text = T"Port"
    }),
    bricks.text("port", {"60", 56, "100", "100"}, {
        text = function() return scene.server:getSocketAddress():match(":.+"):sub(2) end
    }),
    bricks.icon({4, 80, "100", "100"}, {
        icon = "",
        size = 20
    }),
    bricks.text({32, 80, "100", "100"}, {
        text = T"Connected Players"
    }),
    bricks.text("playerCount", {"60", 80, "100", "100"}, {
        text = function() return tostring(#scene.server.clients) end
    }),
    bricks.button({"20", "70", "60", 32}, {
        onclick = function(self)
            scene:start()
            self.onclick = nil
            self:layout():elementWithId("gameClock").visible = true
            self:layout():removeElement(self)
            self:layout().pos[4] = "25"
        end
    }, {
        bricks.text({
            text = T"Start Game"
        })
    }),
    bricks.text("gameClock", {"20", 120, "60", 32, "top", "center"}, {
        visible = false,
        text = function()
            local centis  = math.floor((scene.timer % 1) * 100)
            local seconds = math.floor(scene.timer)
            local minutes = math.floor(seconds / 60)
            local hours   = math.floor(minutes / 60)
            return string.format("%03d:%02d:%02d.%02d", hours, minutes, seconds, centis)
        end,
    })
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

layouts.server.commands = bricks.layout({2, -170, 152, 168}, {
    style = { 
            padding = { 2, 2, 2, 2 },
            backgroundColor = {0, 0, 0},
            borderColor = {255, 255, 255},
    }
}, {
    bricks.checkbox({"0", 0, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show server info",
        onchange = function() 
            scene.show.serverInfo = not scene.show.serverInfo
        end,
        selected = true,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 24, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show map",
        onchange = function() 
            scene.show.map = not scene.show.map 
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 48, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show map objects",
        onchange = function() 
            scene.show.mapObjects = not scene.show.mapObjects 
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 72, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show game objects",
        onchange = function() 
            scene.show.gameObjects = not scene.show.gameObjects 
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 96, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show player info",
        onchange = function() 
            scene.show.playerInfo = not scene.show.playerInfo 
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 120, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show log",
        onchange = function() 
            scene.show.log = not scene.show.log 
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
    bricks.checkbox({"0", 144, "100", 16}, {
        width  = 16,
        height = 16,
        text = T"Show commands",
        onchange = function() 
            scene:hideCommands()
            return true -- cancel the normal checkbox behaviour.
        end,
        selected = true,
        style = {
            customDraw = drawCheckbox
        }
    }),
})

layouts.server.commandsHidden = bricks.layout({2, -26, 136, 24}, {
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
            scene:showCommands()
            return true -- cancel the normal checkbox behaviour.
        end,
        selected = false,
        style = {
            customDraw = drawCheckbox
        }
    }),
})

return layouts
