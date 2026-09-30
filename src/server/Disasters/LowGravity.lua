local D = {Name = "MOON GRAVITY", Hint = "DON'T FLY AWAY!"}

function D.start(ctx)
    local old = workspace.Gravity
    workspace.Gravity = 55
    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        workspace.Gravity = old
    end
end

return D
