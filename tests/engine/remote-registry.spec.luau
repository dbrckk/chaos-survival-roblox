--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RemoteRegistry = require("../../src/server/RemoteRegistry")

describe("Remote registry", function()
    it("reuses valid remotes and replaces invalid class collisions", function()
        local root = Instance.new("Folder")
        root.Name = "RemoteRegistryTest"
        root.Parent = game:GetService("ReplicatedStorage")

        local first = RemoteRegistry.ensureRemoteEvent(root, "State")
        local second = RemoteRegistry.ensureRemoteEvent(root, "State")
        expect(first).toBe(second)
        expect(second:IsA("RemoteEvent")).toBe(true)

        second:Destroy()

        local wrong = Instance.new("Folder")
        wrong.Name = "State"
        wrong.Parent = root

        local repaired = RemoteRegistry.ensureRemoteEvent(root, "State")
        expect(repaired:IsA("RemoteEvent")).toBe(true)
        expect(wrong.Parent == nil).toBe(true)

        root:Destroy()
    end)

    it("repairs the remotes container class", function()
        local parent = Instance.new("Folder")
        parent.Parent = workspace

        local wrong = Instance.new("Part")
        wrong.Name = "Remotes"
        wrong.Parent = parent

        local folder = RemoteRegistry.ensureFolder(parent, "Remotes")
        expect(folder:IsA("Folder")).toBe(true)
        expect(wrong.Parent == nil).toBe(true)

        parent:Destroy()
    end)
end)

return nil
