-- Shallow-copy a table
function shallow_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- Copies fields from defaults to t but only if they are currently nil in t
function update_with_defaults(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
end