local D = {Name = "BLACKOUT", Hint = "VISIBILITY IS LOW — MOVE CAREFULLY!"}

function D.start(_ctx)
    -- Blackout is rendered locally from replicated round state so players
    -- outside the active round are not forced into another contestant's darkness.
end

return D
