local util = {}

function util.map(array, f)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = f(v)
    end
    return result
end

function util.reduce(array, f, initial)
    local result = initial
    for i, v in ipairs(array) do
        result = f(result, v)
    end
    return result
end

function util.filter(array, f)
    local result = {}
    for _, v in ipairs(array) do
        if f(v) then
            table.insert(result, v)
        end
    end
    return result
end

function util.zip(arary1, array2)
    local result = {}
    for i = 1, math.max(#arary1, #array2) do
        result[i] = { arary1[i], array2[i] }
    end
    return result
end

function util.any(array, f)
    if f == nil then
        return #array > 0
    end
    for _, v in pairs(array) do
        if f(v) then return true end
    end
    return false
end

function util.none(array, f)
    if f == nil then
        return #array == 0
    end
    for _, v in pairs(array) do
        if f(v) then return false end
    end
    return true
end

function util.append(array, ...)
    local result = util.copy(array)
    for i, v in ipairs({...}) do
        table.insert(result, v)
    end
    return result
end

function util.copy(array)
    return { unpack(array) }
end

return util