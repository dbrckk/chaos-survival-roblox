--!strict
-- Genuine MapBuilder skyline and exterior retrofit stream ownership.
-- Test meshes exist only in the Roblox Cloud Engine fixture.
local Lest=require("@lest")
local describe,it,expect=Lest.describe,Lest.it,Lest.expect
local MapBuilder=require("../../src/server/MapBuilder")
local Config=require("../../src/shared/Config")
local ArenaVariants=require("../../src/server/ArenaVariants")
local VisualTheme=require("../../src/shared/VisualTheme")
local PrimarySkyline=require("../../src/client/ApprovedPrimarySkylineMeshKit")
local ExteriorRetrofit=require("../../src/client/ApprovedExteriorRetrofitMeshKit")

describe("Skyline and exterior retrofit streaming fallback", function()
    it("replaces the complete exterior retrofit structures in five worlds while preserving original landmark signals",function()
        local storage = game:GetService("ReplicatedStorage")
        local function model(folder,name,id,tag,size)
            local holder = Instance.new("Folder")
            holder.Name = folder
            holder:SetAttribute("OwnerVerified",true)
            holder.Parent = storage
            local source = Instance.new("Model")
            source.Name = name
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("Original3DAssetId",id)
            source:SetAttribute(tag,true)
            for index = 1,7 do
                local part = Instance.new("MeshPart")
                part.Name = "Mesh"..index
                part.Size = index == 1 and size or Vector3.new(.12,.06,.15)
                if index == 2 then part.Position = Vector3.new(4,0,0) end
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Parent = source
            end
            source.Parent = holder
            return source
        end
        local tower = model("ApprovedExteriorTowerTemplates","Tower21",137744886537150,
            "OriginalExteriorTower3D",Vector3.new(9.84,22.2,11.84))
        local gantry = model("ApprovedCrossroadsGantryTemplates","Gantry",90844491148907,
            "OriginalCrossroadsGantry3D",Vector3.new(2.74,3.6,27.92))
        -- The long-axis signal component remains in the genuine width.
        gantry.Mesh2.Position = Vector3.new(0,0,4)
        local bucket = assert(workspace:FindFirstChild("ApprovedExteriorRetrofitsLocal"))
        local preserved = {Classic="ClassicBroadcastGlow1",Crossroads="CrossroadSignal1",
            Towers="TowerAntenna1",Orbital="OrbitalReactorNode1"}
        local total = 0
        for _,variant in ipairs(ArenaVariants.Order) do
            local arena = MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
            local base,decor = arena.Base,arena.Decor
            local fleet = decor.OriginalExteriorRetrofits
            local selected = fleet:FindFirstChild(variant.."Retrofit1")
            local anchor = selected:GetAttribute("RetrofitOrigin")
            local signal = preserved[variant] and decor:FindFirstChild(preserved[variant])
            local signalAlpha = signal and signal.Transparency
            local count = variant == "Crossroads" and 17 or 13
            ExteriorRetrofit.sync(arena,base.Position,"High",true,false,0)
            local models, natives = ExteriorRetrofit.count()
            assert(models == 4 and natives == 4*count,variant.." retrofit coverage")
            total += natives
            for i=1,4 do
                local structure = fleet:FindFirstChild(variant.."Retrofit"..i)
                local sculpture = assert(bucket:FindFirstChild("Sculpted"..structure.Name))
                assert(#sculpture:GetChildren() == (variant == "Crossroads" and 14 or 7))
                local origin = structure:GetAttribute("RetrofitOrigin")
                for _,piece in ipairs(sculpture:GetChildren()) do
                    assert(piece:IsA("MeshPart") and piece.Anchored and piece.Massless
                        and not piece.CanCollide and not piece.CanTouch and not piece.CanQuery)
                    if piece.Name == "Mesh1" and piece:GetAttribute("Original3DAssetId") == 90844491148907 then
                        local axis = i <= 2 and Vector3.xAxis or Vector3.zAxis
                        assert(math.abs(piece.CFrame.LookVector:Dot(axis)) > .999)
                        assert(math.abs(piece.Size.Z-29.6) < .03)
                    elseif piece.Name == "Mesh2" and piece:GetAttribute("Original3DAssetId") == 137744886537150 then
                        assert((piece.Position-origin.Position):Dot(origin.LookVector) > 0)
                    end
                end
                assert(structure.OuterFrontArmor.Transparency == 1)
            end
            if signal then assert(signal.Transparency == signalAlpha) end
            local size = base.Size
            base.Size = Vector3.new(size.X*.7,size.Y,size.Z*.7)
            ExteriorRetrofit.sync(arena,anchor.Position,"Low",true,true,0)
            models,natives = ExteriorRetrofit.count()
            assert(models == 1 and natives == count and base.CanCollide)
            local panel = selected.OuterFrontArmor
            local replacement = assert(bucket:FindFirstChild("Sculpted"..selected.Name))
            replacement:GetChildren()[1]:Destroy()
            task.wait()
            assert(math.abs(panel.Transparency-.045) < .001 and ExteriorRetrofit.count() == 0)
            ExteriorRetrofit.sync(arena,anchor.Position,"Low",true,true,0)
            local saved = panel.CFrame
            panel.CFrame *= CFrame.new(.24,0,0)
            task.wait()
            assert(ExteriorRetrofit.count() == 0 and panel.Transparency < 1)
            panel.CFrame = saved
            ExteriorRetrofit.sync(arena,anchor.Position,"Low",true,true,0)
            assert(panel.Transparency == 1)
            local sourcePart = variant == "Crossroads" and gantry.Mesh1 or tower.Mesh1
            local sourceSize = sourcePart.Size
            sourcePart.Size *= 1.18
            task.wait()
            assert(ExteriorRetrofit.count() == 0 and panel.Transparency < 1)
            sourcePart.Size = sourceSize
            ExteriorRetrofit.sync(arena,anchor.Position,"Low",true,true,0)
            assert(panel.Transparency == 1)
            ExteriorRetrofit.sync(arena,anchor.Position,"Low",true,true,1)
            assert(panel.Transparency < 1 and #bucket:GetChildren() == 0)
            if signal then assert(signal.Transparency == signalAlpha) end
            ExteriorRetrofit.sync(nil,Vector3.zero,"Low",false)
            arena.Parent:Destroy()
        end
        expect(total).toBe(276)
        tower.Parent:Destroy()
        gantry.Parent:Destroy()
    end)

    it("fits eighty-four primary skyline details across five real arenas and rolls them back independently",function()
        local storage = game:GetService("ReplicatedStorage")
        local holders = {}
        local function model(folder,name,id,tag,rows)
            local holder = holders[folder]
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = folder
                holder:SetAttribute("OwnerVerified",true)
                holder.Parent = storage
                holders[folder] = holder
            end
            local source = Instance.new("Model")
            source.Name = name
            source:SetAttribute("OwnerVerified",true)
            source:SetAttribute("CosmeticOnly",true)
            source:SetAttribute("Original3DAssetId",id)
            source:SetAttribute(tag,true)
            for i = 1,7 do
                local row = rows[i] or {Vector3.one*.25,Vector3.zero}
                local mesh = Instance.new("MeshPart")
                mesh.Name = "Mesh"..i
                mesh.Size = row[1]
                mesh.Position = row[2]
                mesh.Anchored = true
                mesh.CanCollide = false
                mesh.CanTouch = false
                mesh.CanQuery = false
                mesh.Parent = source
            end
            source.Parent = holder
            return source
        end
        local towerId = {[21]=137744886537150,[24]=74958476744494,
            [27]=97864559770371,[30]=112172520488996}
        for h,id in pairs(towerId) do
            local swapped = h == 24 or h == 30
            model("ApprovedExteriorTowerTemplates","Tower"..h,id,"OriginalExteriorTower3D",{
                {Vector3.new(swapped and 9.84 or 11.84,h+1.2,swapped and 11.84 or 9.84),Vector3.zero},
                {Vector3.new(.12,.05,.12),swapped and Vector3.new(4.45,h*.5,0)
                    or Vector3.new(0,h*.5,-4.45)},
            })
        end
        local footSrc = model("ApprovedHarborDockCaissonTemplates","DockCaisson",101457508594609,
            "OriginalHarborDockCaisson3D",{
            {Vector3.new(12.82,2.69,12.82),Vector3.new(0,.2938,0)},
            {Vector3.new(13.54,2.95755,13.54),Vector3.new(0,-.175,0)},
            {Vector3.new(14.07,1.865,14.07),Vector3.new(0,-.6937,0)},
            {Vector3.new(13.54,.35,13.54),Vector3.new(0,1.4788,0)},
        })
        model("ApprovedPerimeterArmorTemplates","Cap",88962643359267,"OriginalPerimeterArmor3D",{
            {Vector3.new(2.34,2.14,2.7699),Vector3.zero},
            {Vector3.new(1.7784,.4494,2.4566),Vector3.new(0,-.5564,0)},
        })
        model("ApprovedPerimeterRotorTemplates","Rotor",133526819668194,"OriginalPerimeterRotor3D",{
            {Vector3.new(2.56,.72,2.56),Vector3.new(0,-.01275,0)},
            {Vector3.new(2.0018,.2528,2.0009),Vector3.new(.015,.0257,.0159)},
            {Vector3.new(.7,.68,.7),Vector3.new(0,-.01275,0)},
            {Vector3.new(.16,.06,.15),Vector3.new(0,.37775,0)},
        })
        model("ApprovedVariantIdentitySpineTemplates","Towers",86423178125318,
            "OriginalVariantIdentitySpine3D",{
            {Vector3.new(2.52,19.92,2.52),Vector3.new(0,-.02781,0)},
            {Vector3.new(2.29954,19.52,2.23955),Vector3.new(0,-.02781,0)},
            {Vector3.new(.1,.1,.1),Vector3.new(0,9.93781,0)},
        })
        model("ApprovedVariantIdentitySpineTemplates","Classic",105555650820011,
            "OriginalVariantIdentitySpine3D",{
            {Vector3.new(2.16,11.92,2.16),Vector3.zero},
            {Vector3.new(1.9388,11.52,1.8788),Vector3.zero},
        })
        local barSrc = model("ApprovedOrbitalReactorLandmarkTemplates","Strut",138666009076890,
            "OriginalOrbitalReactorLandmark3D",{
            {Vector3.new(1.10,1.24,8.46),Vector3.zero},
            {Vector3.new(.872,.8638,7.96),Vector3.zero},
        })
        local details = {Classic={"RelayAerial"},Harbor={"RelayAerial"},
            Towers={"ServiceMast"},Orbital={"ReceiverHead"},Crossroads={"ExchangeMast","CrossAntenna"}}
        local bucket = assert(workspace:FindFirstChild("ApprovedPrimarySkylineLocal"))
        local totals = 0
        for _,variant in ipairs(ArenaVariants.Order) do
            local arena = MapBuilder.buildArena(Config,variant,ArenaVariants,VisualTheme)
            local base,decor = arena.Base,arena.Decor
            local expectedNames = details[variant]
            PrimarySkyline.sync(arena,base.Position,"High",true,false,0)
            local body,extra = PrimarySkyline.replacedNativeCount()
            assert(body == 24 and extra == 4*(1+#expectedNames),variant.." primary skyline coverage")
            totals += (body-16)+extra
            for _,direction in ipairs({"North","East","South","West"}) do
                local owner = decor:FindFirstChild("SkylineStructure"..direction)
                local art = assert(bucket:FindFirstChild("SculptedSkylineStructure"..direction))
                assert(owner.InsetL.Transparency == 1 and owner.InsetR.Transparency == 1)
                local marker = art.Mesh2.Position-owner.StructuralCore.Position
                local inward = base.Position-owner.StructuralCore.Position
                assert(Vector3.new(inward.X,0,inward.Z):Dot(marker) > 0,variant.." "..direction.." facade")
                local foot = assert(art:FindFirstChild("ForgedSkylineFoundation"))
                local fixture = assert(art:FindFirstChild("SculptedSkylineEquipment"))
                assert(#foot:GetChildren() == 2 and owner.Foundation.Transparency == 1)
                assert(#fixture:GetChildren() == (variant == "Crossroads" and 4 or variant == "Orbital" and 3 or 2))
                for _,found in ipairs({foot, fixture}) do
                    for _,part in ipairs(found:GetChildren()) do
                        assert(part:IsA("MeshPart") and part.Anchored and part.Massless and not part.CastShadow
                            and not part.CanCollide and not part.CanTouch and not part.CanQuery)
                    end
                end
                local top = art.Mesh1.Position.Y+art.Mesh1.Size.Y*.5
                local lowest = math.huge
                for _,part in ipairs(fixture:GetChildren()) do
                    lowest = math.min(lowest,part.Position.Y-part.Size.Y*.5)
                end
                assert(lowest <= top and top-lowest < .35,variant.." "..direction.." roof attachment")
                for _,name in ipairs(expectedNames) do assert(owner[name].Transparency == 1) end
            end
            local first = decor.SkylineStructureNorth
            local original = base.Size
            base.Size = Vector3.new(original.X*.70,original.Y,original.Z*.70)
            PrimarySkyline.sync(arena,first.StructuralCore.Position,"Low",true,true,0)
            body,extra = PrimarySkyline.replacedNativeCount()
            assert(body == 6 and extra == 1+#expectedNames and base.CanCollide)
            local art = assert(bucket:FindFirstChild("SculptedSkylineStructureNorth"))
            local roof = assert(art:FindFirstChild("SculptedSkylineEquipment"))
            footSrc.Parent:SetAttribute("OwnerVerified",false)
            task.wait()
            assert(first.Foundation.Transparency < 1 and roof.Parent == art)
            footSrc.Parent:SetAttribute("OwnerVerified",true)
            if variant == "Crossroads" then
                local bar = barSrc.Mesh1
                bar.Parent = nil
                task.wait()
                assert(first.ExchangeMast.Transparency < 1 and first.CrossAntenna.Transparency < 1)
                assert(first.InsetL.Transparency == 1 and art.Parent == bucket)
                bar.Parent = barSrc
            else
                roof:GetChildren()[1]:Destroy()
                task.wait()
                assert(first[expectedNames[1]].Transparency < 1 and art.Parent == bucket)
            end
            PrimarySkyline.sync(arena,first.StructuralCore.Position,"Low",true,true,0)
            assert(first[expectedNames[1]].Transparency == 1 and first.Foundation.Transparency == 1)
            PrimarySkyline.sync(arena,first.StructuralCore.Position,"High",true,true,1)
            body,extra = PrimarySkyline.replacedNativeCount()
            assert(body == 6 and extra == 0 and first.Foundation.Transparency < 1
                and first[expectedNames[1]].Transparency < 1)
            PrimarySkyline.sync(nil,Vector3.zero,"Low",false)
            assert(first.InsetL.Transparency < 1 and #bucket:GetChildren() == 0)
            arena.Parent:Destroy()
        end
        expect(totals).toBe(84)
        for _,holder in pairs(holders) do holder:Destroy() end
    end)
end)

return nil
