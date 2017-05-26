array = {}

function array.map(list, f)
    local result = {}
    for i, v in ipairs(list) do
        result[i] = f(v)
    end
    return result
end

function array.reduce(list, f, initial)
    local result = initial
    for i, v in ipairs(list) do
        result = f(result, v)
    end
    return result
end

function array.filter(list, f)
    local result = {}
    for _, v in ipairs(list) do
        if f(v) then
            table.insert(result, v)
        end
    end
    return result
end

function array.filtermap(list, f)
    local result = {}
    for _, v in ipairs(list) do
        local x = f(v)
        if x then
            table.insert(result, x)
        end
    end
end

function array.zip(list1, list2)
    local result = {}
    for i = 1, math.max(#list1, #list2) do
        result[i] = { list1[i], list2[i] }
    end
    return result
end

function array.any(list, f)
    if f == nil then
        return #list > 0
    end
    for _, v in pairs(list) do
        if f(v) then return true end
    end
    return false
end

function array.none(list, f)
    if f == nil then
        return #list == 0
    end
    for _, v in pairs(list) do
        if f(v) then return false end
    end
    return true
end

function array.append(list, ...)
    local result = array.copy(list)
    for i, v in ipairs({...}) do
        table.insert(result, v)
    end
    return result
end

function array.copy(list)
    return { unpack(list) }
end

return array