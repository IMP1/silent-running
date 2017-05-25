-- from https://love2d.org/wiki/coroutine.resume

local non_error_coroutine_resume = coroutine.resume
function coroutine.resume(...)
    local state,result = non_error_coroutine_resume(...)
    if not state then
        error( tostring(result), 2 )    -- Output error message
    end
    return state,result
end