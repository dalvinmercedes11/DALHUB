-- DALHUB | Hide & Seek | LocalScript
-- Install in StarterPlayer > StarterPlayerScripts
-- Designed for your own Roblox Studio experience.
-- Server features use ReplicatedStorage.DALHUB_Remote (created by the server script).

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("DALHUB_Remote", 10)

local VERSION = "1.0.0"
local PASSWORD = "DALHUBHIDE" -- Client-side password is not secure against code inspection.
local RED = Color3.fromRGB(205, 0, 32)
local RED2 = Color3.fromRGB(255, 20, 45)
local BLACK = Color3.fromRGB(7, 7, 9)
local PANEL = Color3.fromRGB(17, 17, 21)
local WHITE = Color3.fromRGB(245, 245, 245)
local MUTED = Color3.fromRGB(155, 155, 165)

local selectedTargetUserId = nil
local state = {
    speed = 16, infiniteJump = false, noclip = false, invisible = false,
    esp = false, espNames = true, espDistance = true, highlight = true,
    espColor = Color3.fromRGB(255, 0, 35), customName = "",
    graphics = "MEDIUM", fpsTarget = 60, uiScale = 1
}
local oldCollisions = {}
local highlights = {}
local billboards = {}
local connections = {}
local espColorChoices = {
    {name="Blood Red", color=Color3.fromRGB(255, 0, 35)},
    {name="Blue", color=Color3.fromRGB(0, 140, 255)},
    {name="Green", color=Color3.fromRGB(0, 255, 100)},
    {name="Purple", color=Color3.fromRGB(180, 70, 255)},
    {name="Gold", color=Color3.fromRGB(255, 190, 0)},
    {name="White", color=Color3.fromRGB(255, 255, 255)}
}
local savedLocalLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
}

local gui = Instance.new("ScreenGui")
gui.Name = "DALHUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function round(obj, radius)
    make("UICorner", {CornerRadius=UDim.new(0,radius or 8)}, obj)
end
local function outline(obj, color, thickness)
    make("UIStroke", {Color=color or RED, Thickness=thickness or 1}, obj)
end
local function textLabel(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency=1, Text=text, TextColor3=color or WHITE,
        Font=font or Enum.Font.Gotham, TextSize=size or 13,
        TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left
    }, parent)
end

-- Login panel
local login = make("Frame", {
    Size=UDim2.fromOffset(330,205), Position=UDim2.new(.5,-165,.5,-102),
    BackgroundColor3=BLACK, BorderSizePixel=0
}, gui)
round(login,12); outline(login,RED,2)
local loginTitle = make("TextLabel", {
    Size=UDim2.new(1,0,0,55), BackgroundTransparency=1,
    Text="DALHUB", TextColor3=RED2, Font=Enum.Font.GothamBlack, TextSize=29
}, login)
local passBox = make("TextBox", {
    Size=UDim2.new(1,-36,0,40), Position=UDim2.fromOffset(18,65),
    BackgroundColor3=PANEL, TextColor3=WHITE, PlaceholderColor3=MUTED,
    PlaceholderText="Enter access password", Text="", ClearTextOnFocus=false,
    Font=Enum.Font.Gotham, TextSize=14
}, login)
round(passBox,7); outline(passBox,RED)
local loginBtn = make("TextButton", {
    Size=UDim2.new(1,-36,0,36), Position=UDim2.fromOffset(18,115),
    BackgroundColor3=RED, Text="UNLOCK DALHUB", TextColor3=WHITE,
    Font=Enum.Font.GothamBold, TextSize=13
}, login)
round(loginBtn,7)
local loginStatus = textLabel(login,"Version "..VERSION.." • Hide & Seek",12,MUTED)
loginStatus.Size=UDim2.new(1,-24,0,22); loginStatus.Position=UDim2.fromOffset(12,164)
loginStatus.TextXAlignment=Enum.TextXAlignment.Center

-- Main window
local main = make("Frame", {
    Size=UDim2.fromOffset(650,440), Position=UDim2.new(.5,-325,.5,-220),
    BackgroundColor3=BLACK, BorderSizePixel=0, Visible=false, ClipsDescendants=true
}, gui)
round(main,12); outline(main,RED,2)
local scale = make("UIScale",{Scale=1},main)
local header = make("Frame", {
    Size=UDim2.new(1,0,0,54), BackgroundColor3=Color3.fromRGB(3,3,4),
    BorderSizePixel=0
},main)
local title = make("TextLabel", {
    Size=UDim2.new(1,-105,1,0), Position=UDim2.fromOffset(14,0),
    BackgroundTransparency=1, Text="DALHUB  |  HIDE & SEEK",
    TextColor3=RED2, TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBlack, TextSize=20
},header)
local closeBtn = make("TextButton", {
    Size=UDim2.fromOffset(35,34), Position=UDim2.new(1,-44,0,10),
    BackgroundColor3=RED, Text="×", TextColor3=WHITE,
    Font=Enum.Font.GothamBold, TextSize=22
},header)
round(closeBtn,7)

-- Drag window by header
local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPosition=main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging=false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput=input
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        main.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
    end
end)

-- Persistent draggable floating D button (remains when window is closed)
local floating = make("TextButton", {
    Size=UDim2.fromOffset(56,56), Position=UDim2.new(0,14,.55,-28),
    BackgroundColor3=BLACK, Text="D", TextColor3=RED2,
    Font=Enum.Font.GothamBlack, TextSize=29, AutoButtonColor=false
},gui)
round(floating,100); outline(floating,RED,2)
local floatDragging, floatMoved, floatStart, floatPos = false, false, nil, nil
floating.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        floatDragging=true; floatMoved=false; floatStart=input.Position; floatPos=floating.Position
    end
end)
floating.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
        dragInput=input
    end
end)
UIS.InputChanged:Connect(function(input)
    if floatDragging and floatStart and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-floatStart
        if math.abs(delta.X)>5 or math.abs(delta.Y)>5 then floatMoved=true end
        if floatMoved then
            floating.Position=UDim2.new(floatPos.X.Scale,floatPos.X.Offset+delta.X,floatPos.Y.Scale,floatPos.Y.Offset+delta.Y)
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        if floatDragging then
            floatDragging=false
            if not floatMoved then main.Visible=not main.Visible end
        end
    end
end)
closeBtn.Activated:Connect(function() main.Visible=false end)

local nav = make("Frame", {
    Size=UDim2.new(0,150,1,-65), Position=UDim2.fromOffset(8,60),
    BackgroundTransparency=1
},main)
make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},nav)
local content = make("ScrollingFrame", {
    Size=UDim2.new(1,-174,1,-67), Position=UDim2.fromOffset(166,60),
    BackgroundColor3=Color3.fromRGB(8,8,10), BorderSizePixel=0,
    ScrollBarThickness=4, ScrollBarImageColor3=RED,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y
},main)
round(content,8)
make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},content)
make("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},content)

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
end
local function section(text)
    local l=make("TextLabel",{Size=UDim2.new(1,-4,0,29),BackgroundTransparency=1,Text=text,TextColor3=RED2,Font=Enum.Font.GothamBold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left},content)
    return l
end
local function info(text)
    local l=make("TextLabel",{Size=UDim2.new(1,-4,0,28),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=text,TextColor3=MUTED,Font=Enum.Font.Gotham,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},content)
    return l
end
local function action(text, callback)
    local b=make("TextButton",{Size=UDim2.new(1,-4,0,36),BackgroundColor3=PANEL,Text=text,TextColor3=WHITE,Font=Enum.Font.GothamSemibold,TextSize=12,AutoButtonColor=true},content)
    round(b,7); outline(b,RED,1)
    b.Activated:Connect(callback)
    return b
end
local function toggle(text, key, callback)
    local b
    local function update()
        b.Text=text..": "..(state[key] and "ON" or "OFF")
        b.TextColor3=state[key] and RED2 or WHITE
    end
    b=action(text..": OFF",function()
        state[key]=not state[key]
        update()
        if callback then callback(state[key]) end
    end)
    update()
    return b
end
local function slider(text, minVal, maxVal, initial, callback)
    local wrap=make("Frame",{Size=UDim2.new(1,-4,0,57),BackgroundTransparency=1},content)
    local val=initial
    local label=make("TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text=text..": "..tostring(val),TextColor3=WHITE,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},wrap)
    local bar=make("Frame",{Size=UDim2.new(1,-8,0,9),Position=UDim2.fromOffset(2,31),BackgroundColor3=Color3.fromRGB(55,55,60)},wrap)
    round(bar,6)
    local fill=make("Frame",{Size=UDim2.new((val-minVal)/(maxVal-minVal),0,1,0),BackgroundColor3=RED},bar)
    round(fill,6)
    local knob=make("Frame",{Size=UDim2.fromOffset(15,17),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new((val-minVal)/(maxVal-minVal),0,.5,0),BackgroundColor3=RED2},bar)
    round(knob,5)
    local hit=make("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,.5,-14),BackgroundTransparency=1,Text=""},bar)
    local function setFromX(x)
        local ratio=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        val=math.floor(minVal+ratio*(maxVal-minVal)+.5)
        fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,0,.5,0)
        label.Text=text..": "..val
        callback(val)
    end
    hit.Activated:Connect(function() setFromX(UIS:GetMouseLocation().X) end)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch then setFromX(input.Position.X) end
    end)
end

local function getHumanoid()
    local char=player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function setSpeed(v)
    state.speed=v
    local h=getHumanoid()
    if h then h.WalkSpeed=v end
end

local function removeEsp(target)
    if highlights[target] then highlights[target]:Destroy(); highlights[target]=nil end
    if billboards[target] then billboards[target]:Destroy(); billboards[target]=nil end
end
local function applyEsp(target)
    if target==player or not target.Character then return end
    removeEsp(target)
    if state.highlight then
        local h=Instance.new("Highlight")
        h.Name="DALHUB_ESP_Highlight"; h.Adornee=target.Character
        h.FillColor=state.espColor; h.OutlineColor=state.espColor
        h.FillTransparency=.72; h.OutlineTransparency=.05; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=gui; highlights[target]=h
    end
    if state.espNames or state.espDistance then
        local head=target.Character:FindFirstChild("Head")
        if head then
            local bb=Instance.new("BillboardGui")
            bb.Name="DALHUB_ESP_Label"; bb.Adornee=head; bb.Size=UDim2.fromOffset(180,42)
            bb.StudsOffset=Vector3.new(0,2.5,0); bb.AlwaysOnTop=true; bb.Parent=gui
            local txt=Instance.new("TextLabel")
            txt.Size=UDim2.fromScale(1,1); txt.BackgroundTransparency=1
            txt.TextColor3=state.espColor; txt.TextStrokeTransparency=.2
            txt.Font=Enum.Font.GothamBold; txt.TextSize=12; txt.Parent=bb
            billboards[target]=bb
        end
    end
end
local function refreshEsp()
    for _, p in ipairs(Players:GetPlayers()) do
        removeEsp(p)
        if state.esp then applyEsp(p) end
    end
end
local function updateEspLabels()
    local myChar=player.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    for p,bb in pairs(billboards) do
        if p.Parent and p.Character and bb.Parent then
            local parts={}
            if state.espNames then table.insert(parts,p:GetAttribute("DALHUBCustomName") or p.DisplayName) end
            if state.espDistance and myRoot then
                local root=p.Character:FindFirstChild("HumanoidRootPart")
                if root then table.insert(parts,math.floor((root.Position-myRoot.Position).Magnitude).." studs") end
            end
            local t=bb:FindFirstChildOfClass("TextLabel")
            if t then t.Text=table.concat(parts," • "); t.TextColor3=state.espColor end
        end
    end
end

local function setGraphics(preset)
    state.graphics=preset
    if preset=="LOW" then
        Lighting.GlobalShadows=false; Lighting.Brightness=1.5
        Lighting.EnvironmentDiffuseScale=.5; Lighting.EnvironmentSpecularScale=0
    elseif preset=="MEDIUM" then
        Lighting.GlobalShadows=true; Lighting.Brightness=2
        Lighting.EnvironmentDiffuseScale=.8; Lighting.EnvironmentSpecularScale=.5
    else
        Lighting.GlobalShadows=true; Lighting.Brightness=2
        Lighting.EnvironmentDiffuseScale=1; Lighting.EnvironmentSpecularScale=1
    end
end

local function showTab(tab)
    clearContent()
    if tab=="Main" then
        section("DALHUB • MAIN")
        info("Version: "..VERSION)
        info("Game mode: Hide & Seek")
        info("Theme: Blood Red / Black LED")
        info("Status: Loaded")
        section("UPDATE 1.0.0")
        info("• Redesigned draggable interface")
        info("• Player movement options")
        info("• ESP highlights, names and distance")
        info("• Graphics presets and UI scaling")
        info("• Floating D button stays after closing")
        info("Important: client-side password is only a basic gate.")
    elseif tab=="Player" then
        section("PLAYER CONTROLS")
        toggle("Infinite Jump","infiniteJump")
        slider("Walk Speed",1,100,state.speed,setSpeed)
        toggle("NoClip","noclip",function(on)
            if not on then
                for part,old in pairs(oldCollisions) do
                    if part and part.Parent then part.CanCollide=old end
                end
                table.clear(oldCollisions)
            end
        end)
        toggle("Invisible (server)","invisible",function(on)
            if remote then remote:FireServer("SetInvisible",on) end
        end)
        local nameBox=make("TextBox",{Size=UDim2.new(1,-4,0,36),BackgroundColor3=PANEL,Text=state.customName,PlaceholderText="Custom display name",PlaceholderColor3=MUTED,TextColor3=WHITE,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false},content)
        round(nameBox,7); outline(nameBox,RED)
        action("Apply Custom Name",function()
            state.customName=string.sub(nameBox.Text,1,24)
            if remote then remote:FireServer("SetCustomName",state.customName) end
        end)
        section("SERVER ACTIONS")
        info("These actions require the server script and an authorized UserId.")
        action("Select target player",function()
            local candidates={}
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=player then table.insert(candidates,p) end
            end
            table.sort(candidates,function(a,b) return a.Name<b.Name end)
            if #candidates==0 then
                selectedTargetUserId=nil
                info("No other players are in this server.")
                return
            end
            local current=1
            for i,p in ipairs(candidates) do
                if p.UserId==selectedTargetUserId then current=i%#candidates+1; break end
            end
            selectedTargetUserId=candidates[current].UserId
            info("Selected target: "..candidates[current].DisplayName)
        end)
        action("Teleport to selected player",function()
            if remote and selectedTargetUserId then
                remote:FireServer("TeleportToPlayer",selectedTargetUserId)
            else
                info("Select a target player first.")
            end
        end)
        action("Bring selected player to me",function()
            if remote and selectedTargetUserId then
                remote:FireServer("BringPlayer",selectedTargetUserId)
            else
                info("Select a target player first.")
            end
        end)
        action("Reset Walk Speed to 16",function() setSpeed(16) end)
    elseif tab=="Visuals" then
        section("VISUAL SETTINGS")
        toggle("Player ESP","esp",function() refreshEsp() end)
        toggle("Names","espNames",function() refreshEsp() end)
        toggle("Distance","espDistance",function() refreshEsp() end)
        toggle("Character Highlight","highlight",function() refreshEsp() end)
        section("ESP COLOR")
        for _,choice in ipairs(espColorChoices) do
            action("Color: "..choice.name,function()
                state.espColor=choice.color; refreshEsp()
            end)
        end
        action("Remove all ESP",function()
            state.esp=false; refreshEsp()
        end)
    elseif tab=="Settings" then
        section("GRAPHICS")
        for _,preset in ipairs({"LOW","MEDIUM","HIGH"}) do
            action(preset.." Graphics",function() setGraphics(preset) end)
        end
        section("FPS TARGET")
        info("This is a preference display. Roblox does not let ordinary LocalScripts force every listed FPS cap.")
        for _,fps in ipairs({30,60,90,144,240,360}) do
            action(tostring(fps).." FPS target",function()
                state.fpsTarget=fps
                title.Text="DALHUB | "..fps.." FPS TARGET"
            end)
        end
        section("INTERFACE")
        slider("UI Scale (%)",70,130,math.floor(state.uiScale*100),function(v)
            state.uiScale=v/100; scale.Scale=state.uiScale
        end)
        action("Save settings on server",function()
            if remote then
                remote:FireServer("SaveSettings",{
                    speed=state.speed, graphics=state.graphics, esp=state.esp,
                    espNames=state.espNames, espDistance=state.espDistance,
                    highlight=state.highlight, uiScale=state.uiScale,
                    fpsTarget=state.fpsTarget, espColor={state.espColor.R,state.espColor.G,state.espColor.B}
                })
            end
        end)
        action("Restore default lighting",function()
            for k,v in pairs(savedLocalLighting) do Lighting[k]=v end
        end)
        info("Persistent saving requires DataStore access enabled in Studio.")
    end
end

for i,tab in ipairs({"Main","Player","Visuals","Settings"}) do
    local b=make("TextButton",{
        Size=UDim2.new(1,0,0,43),BackgroundColor3=PANEL,Text=tab,
        TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=13,LayoutOrder=i
    },nav)
    round(b,8); outline(b,RED,1)
    b.Activated:Connect(function() showTab(tab) end)
end

-- Movement loops and ESP distance updates
UIS.JumpRequest:Connect(function()
    if state.infiniteJump then
        local h=getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
RunService.Stepped:Connect(function()
    if state.noclip then
        local char=player.Character
        if char then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if oldCollisions[part]==nil then oldCollisions[part]=part.CanCollide end
                    part.CanCollide=false
                end
            end
        end
    end
end)
RunService.Heartbeat:Connect(updateEspLabels)

local function connectPlayer(p)
    if p==player then return end
    p.CharacterAdded:Connect(function()
        task.wait(.5)
        if state.esp then applyEsp(p) end
    end)
end
for _,p in ipairs(Players:GetPlayers()) do connectPlayer(p) end
Players.PlayerAdded:Connect(connectPlayer)
Players.PlayerRemoving:Connect(function(p) removeEsp(p) end)
player.CharacterAdded:Connect(function()
    task.wait(.5)
    setSpeed(state.speed)
    if state.noclip then
        table.clear(oldCollisions)
    end
    if state.esp then refreshEsp() end
end)

loginBtn.Activated:Connect(function()
    if passBox.Text==PASSWORD then
        login.Visible=false; main.Visible=true; showTab("Main")
    else
        loginStatus.Text="Incorrect password"; loginStatus.TextColor3=RED2
    end
end)

-- Server responses / restore saved settings
if remote then
    remote.OnClientEvent:Connect(function(actionName,payload)
        if actionName=="Notice" and typeof(payload)=="string" then
            loginStatus.Text=payload
        elseif actionName=="LoadSettings" and typeof(payload)=="table" then
            if typeof(payload.speed)=="number" then setSpeed(math.clamp(payload.speed,1,100)) end
            if typeof(payload.graphics)=="string" then setGraphics(payload.graphics) end
            if typeof(payload.uiScale)=="number" then state.uiScale=math.clamp(payload.uiScale,.7,1.3); scale.Scale=state.uiScale end
            if typeof(payload.esp)=="boolean" then state.esp=payload.esp end
            if typeof(payload.espNames)=="boolean" then state.espNames=payload.espNames end
            if typeof(payload.espDistance)=="boolean" then state.espDistance=payload.espDistance end
            if typeof(payload.highlight)=="boolean" then state.highlight=payload.highlight end
            if typeof(payload.fpsTarget)=="number" then state.fpsTarget=payload.fpsTarget end
            refreshEsp()
        end
    end)
    remote:FireServer("LoadSettings")
else
    warn("DALHUB: DALHUB_Remote missing. Install the DALHUB server script in ServerScriptService.")
end

showTab("Main")
