-- Shallow-copy a table
-- (from https://gist.github.com/MihailJP/3931841 with slight adaptations)
function shallow_copy(t)
    if type(t) ~= "table" then
        return t
    end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        target[k] = v
    end
    setmetatable(target, meta)
    return target
end

-- deep-copy a table
-- (from https://gist.github.com/MihailJP/3931841 with slight adaptations)
function deep_copy(t)
    if type(t) ~= "table" then
        return t
    end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end
