--!strict
-- Real Studio server-only diagnostic smoke; does not request network assets.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Gate = require("../../src/server/PremiumApprovedAssetImportGate")

describe("Premium 3D Model import diagnostics", function()
    it("exposes bounded, attributed import timings in ServerStorage only", function()
        local serverStorage = game:GetService("ServerStorage")
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local folder = serverStorage:FindFirstChild("PremiumApprovedImportDiagnostics")
        expect(folder ~= nil).toBe(true)
        expect(folder:IsA("Folder")).toBe(true)
        expect(replicatedStorage:FindFirstChild("PremiumApprovedImportDiagnostics")).toBe(nil)

        local snapshot = Gate.snapshot()
        expect(snapshot.Limit).toBe(2)
        expect(snapshot.InFlight >= 0 and snapshot.InFlight <= 2).toBe(true)
        expect(snapshot.Waiting >= 0).toBe(true)
        expect(snapshot.PeakInFlight <= 2).toBe(true)
        for _, key in ipairs({
            "InFlight", "Waiting", "PeakInFlight", "Limit",
            "Completed", "Failed", "TotalWaits",
            "LastQueueWaitMs", "MaxQueueWaitMs",
            "LastRequestMs", "MaxRequestMs",
            "LastRequestAssetId", "SlowestRequestAssetId",
            "SlowestQueueAssetId", "TotalRequestMs", "TotalQueueWaitMs",
            "SlowRequestCount", "SlowQueueCount", "SlowThresholdMs",
        }) do
            expect(type((snapshot :: any)[key])).toBe("number")
            -- Imports may advance between snapshot() and this read.
            -- Only assert the attribute is real and numeric, not identical.
            expect(type(folder:GetAttribute(key))).toBe("number")
        end
        expect(snapshot.SlowThresholdMs).toBe(8000)
        expect(snapshot.SlowestRequestAssetId >= 0).toBe(true)
        expect(snapshot.SlowestQueueAssetId >= 0).toBe(true)
        expect(snapshot.TotalRequestMs >= snapshot.MaxRequestMs).toBe(true)
        expect(snapshot.TotalQueueWaitMs >= snapshot.MaxQueueWaitMs).toBe(true)
    end)

    it("rejects non-AssetService calls without consuming any permit", function()
        local before = Gate.snapshot()
        local success = pcall(Gate.load, nil, 1234)
        expect(success).toBe(false)
        local after = Gate.snapshot()
        expect(after.InFlight).toBe(before.InFlight)
        expect(after.Waiting).toBe(before.Waiting)
        expect(after.Completed).toBe(before.Completed)
        expect(after.Failed).toBe(before.Failed)
        expect(after.TotalWaits).toBe(before.TotalWaits)
    end)
end)
