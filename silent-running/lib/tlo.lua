local tlo = {
    _VERSION     = 'v0.0.1',
    _DESCRIPTION = 'A Lua localisation library for LÖVE games',
    _URL         = '',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2017 Huw Taylor

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

tlo.settings = {
    -- "blank", "error", "ignore", "nil"
    onMissingLocalisation = "ignore",
    addMissingLocalisations = true,
    -- "blank", "error", "ignore", "nil"
    onUnsetLanguage       = "error",
    -- "error", "ignore"
    onMissingLanguageFile = "error",
    addMissingLanguageFiles = true,
}

local currentLanguage = nil
local languageFilesPath = "lang"
local lookupTable = {}

function addString(newString)
    local files = love.filesystem.getDirectoryItems(languageFilesPath)
    for _, file in pairs(files) do
        local path = languageFilesPath .. "/" .. file
        local fileString = love.filesystem.read(path)
        local index = fileString:find("}[^}]*$")
        local newString = newString:gsub("\n", "\\n")
        local newContent = fileString:sub(1, index - 1) ..
                           "    [\"" .. newString .. "\"] = \"" .. newString .. "\", -- AUTOMATICALLY ADDED.\n" ..
                           fileString:sub(index)
        love.filesystem.write(path, newContent)
    end
end

function tlo.localise(string)
    if not currentLanguage then
        if tlo.settings.onUnsetLanguage == "blank" then
            return ""
        elseif tlo.settings.onUnsetLanguage == "error" then
            error("There is no language set. Use tlo.setLanguage() to set which language to use.")
        elseif tlo.settings.onUnsetLanguage == "ignore" then
            return string
        elseif tlo.settings.onUnsetLanguage == "nil" then
            return nil
        end
    else
        if lookupTable[string] then
            return lookupTable[string]
        else
            if tlo.settings.addMissingLocalisations then
                addString(string)
            end
            if tlo.settings.onMissingLocalisation == "blank" then
                return ""
            elseif tlo.settings.onMissingLocalisation == "error" then
                error("Missing localisation for '" .. string .. "' in " .. currentLanguage .. ".")
            elseif tlo.settings.onMissingLocalisation == "ignore" then
                return string
            elseif tlo.settings.onMissingLocalisation == "nil" then
                return nil
            end
        end
    end
end

function tlo.deferredLocalise(string)
    return function()
        return tlo.localise(string)
    end
end

function tlo.setLanguage(languageCode)
    local path = languageFilesPath .. "/" .. languageCode
    local exists = love.filesystem.exists(path)
    if exists then
        lookupTable = love.filesystem.load(path)()
    else
        if tlo.settings.addMissingLanguageFiles then
            local f = love.filesystem.newFile(path)
            f:open('r')
            f:close()
        end
        if tlo.settings.onMissingLanguageFile == "error" then
            error("Missing language file '" .. languageCode .. "'.")
        elseif tlo.settings.onMissingLanguageFile == "ignore" then
            lookupTable = lookupTable or {}
        end
    end
    currentLanguage = languageCode
end

function tlo.getLanguage()
    return currentLanguage
end

function tlo.setLanguagesFolder(path)
    languageFilesPath = path
end

function tlo.getLanguagesFolder(path)
    return languageFilesPath
end

return tlo