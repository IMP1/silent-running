local functionalTable = {}

function functionalTable.map(array, f)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = f(v)
    end
    return result
end

function functionalTable.reduce(array, f, initial)
    local result = initial
    for i, v in ipairs(array) do
        result = f(result, v)
    end
    return result
end

function functionalTable.filter(array, f)
    local result = {}
    for _, v in ipairs(array) do
        if f(v) then
            table.insert(result, v)
        end
    end
    return result
end

function functionalTable.zip(arary1, array2)
    local result = {}
    for i = 1, math.max(#arary1, #array2) do
        result[i] = { arary1[i], array2[i] }
    end
    return result
end

function functionalTable.append(array, ...)
    local result = {}
    for i, v in ipairs(array) do
        table.insert(result, v)
    end
    for i, v in ipairs({...}) do
        table.insert(result, v)
    end
    return result
end

return functionalTable