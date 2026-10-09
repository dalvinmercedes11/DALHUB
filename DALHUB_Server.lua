-- DALHUB | ServerScriptService Script
-- Put this Script in ServerScriptService in YOUR Roblox Studio experience.
-- Replace 123456789 with your Roblox UserId to authorize teleport/bring actions.
-- Publish the game and enable Studio Access to API Services to use DataStore saving.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local ADMIN_USER_IDS = {
    [123456789] = true, -- CHANGE THIS to your Roblox UserId
}
local SETTINGS_STORE = DataStoreService:GetDataStore("DALHUB_Settings_v1")

local remote = ReplicatedStorage:FindFirstChild("DALHUB_Remote")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "DALHUB_Remote"
    remote.Parent = ReplicatedStorage
end

local function notice(player, message)
    remote:FireClient(player, "Notice", message)
end

local function isAdmin(player)
    return ADMIN_USER_IDS[player.UserId] == true
end

local function characterRoot(player)
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart"), char
end

local function nearestOther(player, targetUserId)
    local root = characterRoot(player)
    if not root then return nil end
    local best, bestDist = nil, math.huge
    if typeof(targetUserId) == "number" then
        local target = Players:GetPlayerByUserId(targetUserId)
        if target and target ~= player and characterRoot(target) then
            return target
        end
        return nil
    end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local otherRoot = characterRoot(other)
            if otherRoot then
                local dist = (root.Position - otherRoot.Position).Magnitude
                if dist < bestDist then best, bestDist = other, dist end
            end
        end
    end
    return best
end

local function setCharacterInvisible(player, invisible)
    local root, char = characterRoot(player)
    if not char then return end
    if invisible then
        if char:GetAttribute("DALHUB_OriginalTransparencySaved") then return end
        char:SetAttribute("DALHUB_OriginalTransparencySaved", true)
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj:SetAttribute("DALHUB_OldTransparency", obj.Transparency)
                obj.Transparency = 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:SetAttribute("DALHUB_OldTransparency", obj.Transparency)
                obj.Transparency = 1
            end
        end
    else
        for _, obj in ipairs(char:GetDescendants()) do
            local old = obj:GetAttribute("DALHUB_OldTransparency")
            if old ~= nil and (obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture")) then
                obj.Transparency = old
                obj:SetAttribute("DALHUB_OldTransparency", nil)
            end
        end
        char:SetAttribute("DALHUB_OriginalTransparencySaved", nil)
    end
end

local function sanitizeSettings(value)
    if typeof(value) ~= "table" then return nil end
    local out = {}
    if typeof(value.speed)=="number" then out.speed=math.clamp(value.speed,1,100) end
    if value.graphics=="LOW" or value.graphics=="MEDIUM" or value.graphics=="HIGH" then out.graphics=value.graphics end
    for _,key in ipairs({"esp","espNames","espDistance","highlight"}) do
        if typeof(value[key])=="boolean" then out[key]=value[key] end
    end
    if typeof(value.uiScale)=="number" then out.uiScale=math.clamp(value.uiScale,.7,1.3) end
    if typeof(value.fpsTarget)=="number" then
        local allowed={[30]=true,[60]=true,[90]=true,[144]=true,[240]=true,[360]=true}
        if allowed[value.fpsTarget] then out.fpsTarget=value.fpsTarget end
    end
    if typeof(value.espColor)=="table" and #value.espColor==3 then
        out.espColor={
            math.clamp(tonumber(value.espColor[1]) or 1,0,1),
            math.clamp(tonumber(value.espColor[2]) or 0,0,1),
            math.clamp(tonumber(value.espColor[3]) or 0,0,1)
        }
    end
    return out
end

remote.OnServerEvent:Connect(function(player, actionName, payload)
    if typeof(actionName) ~= "string" then return end

    if actionName=="SetCustomName" then
        if typeof(payload)~="string" then return end
        local clean = string.sub(payload:gsub("[%c]", ""),1,24)
        if clean=="" then clean=player.DisplayName end
        player:SetAttribute("DALHUBCustomName", clean)
        notice(player, "Custom name updated.")
        return
    end

    if actionName=="SetInvisible" then
        if typeof(payload)~="boolean" then return end
        setCharacterInvisible(player, payload)
        return
    end

    if actionName=="SaveSettings" then
        local settings=sanitizeSettings(payload)
        if not settings then return end
        local ok,err=pcall(function()
            SETTINGS_STORE:SetAsync(tostring(player.UserId), settings)
        end)
        if ok then notice(player,"DALHUB settings saved.")
        else warn("DALHUB save failed:",err); notice(player,"Save failed. Check DataStore settings.") end
        return
    end

    if actionName=="LoadSettings" then
        local ok,data=pcall(function()
            return SETTINGS_STORE:GetAsync(tostring(player.UserId))
        end)
        if ok and typeof(data)=="table" then
            remote:FireClient(player,"LoadSettings",data)
        else
            remote:FireClient(player,"LoadSettings",{})
        end
        return
    end

    if actionName=="TeleportToNearest" or actionName=="BringNearest"
        or actionName=="TeleportToPlayer" or actionName=="BringPlayer" then
        if not isAdmin(player) then
            notice(player,"Server action denied: your UserId is not authorized.")
            return
        end
        local other=nearestOther(player, payload)
        if not other then notice(player,"Target player not found."); return end
        local root, char=characterRoot(player)
        local otherRoot, otherChar=characterRoot(other)
        if not root or not otherRoot or not char or not otherChar then return end

        if actionName=="TeleportToNearest" or actionName=="TeleportToPlayer" then
            char:PivotTo(otherRoot.CFrame * CFrame.new(0,0,3))
            notice(player,"Teleported near "..other.DisplayName)
        else
            otherChar:PivotTo(root.CFrame * CFrame.new(3,0,0))
            notice(player,"Brought "..other.DisplayName.." near you.")
        end
        return
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        -- Character appearance is recreated on respawn; don't preserve invisibility
        -- automatically so players cannot accidentally remain invisible forever.
    end)
end)
