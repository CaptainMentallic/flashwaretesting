local remotePath = game:GetService("ReplicatedStorage").Events.ClientToServer.ClientToServerEvent
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local GuiLibrary =
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/cerberus.lua"))()

local boosts = LocalPlayer.Boosts

getCharacter = function(plr)
    return plr.Character or plr.CharacterAdded:Wait()
end

getTorso = function(plr)
    plr = plr or getCharacter(LocalPlayer)
    return plr:FindFirstChild("Torso") or plr:FindFirstChild("UpperTorso") or plr:FindFirstChild("LowerTorso") or
               plr:FindFirstChild("HumanoidRootPart")
end

getRoot = function(char)
    char = char or getCharacter(LocalPlayer)
    local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or
                         char:FindFirstChild('UpperTorso')
    return rootPart
end

isAlive = function(plr)
    if plr and plr.Character then
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        return humanoid and humanoid.Health > 0
    end
    return false
end

respawn = function(plr)
    local char = getChar(plr)
    if char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):ChangeState(15)
    end
    char:ClearAllChildren()
    local newChar = Instance.new("Model")
    newChar.Parent = workspace
    plr.Character = newChar
    task.wait()
    plr.Character = char
    newChar:Destroy()
end

refresh = function(plr)
    local Human = getChar(plr):FindFirstChildOfClass("Humanoid", true)
    local pos = Human and Human.RootPart and Human.RootPart.CFrame
    local pos1 = workspace.CurrentCamera.CFrame
    respawn(plr)
    task.spawn(function()
        plr.CharacterAdded:Wait():WaitForChild("Humanoid").RootPart.CFrame, workspace.CurrentCamera.CFrame = pos,
            task.wait() and pos1
    end)
end

tpPlayerTo = function(destination)
    if isAlive(LocalPlayer) then
        getRoot(getCharacter(LocalPlayer)).CFrame = destination.CFrame
    end
end

r15 = function(plr)
    if getCharacter(plr):FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15 then
        return true
    end
end

tools = function(plr)
    if plr:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass('Tool') or
        plr.Character:FindFirstChildOfClass('Tool') then
        return true
    end
end
function ClickGrinder()
    spawn(function()
        while ClickGrinder == true do
            local args = {
                [1] = "HUDHandler",
                [2] = "EmitClicks"
            }

            remotePath:FireServer(unpack(args))
            task.wait()
        end
    end)
end

function activateBoosts()
    spawn(function()
        while activateBoosts == true do
            boosts.DoubleClicks.isActive.Value = true
            boosts.DoubleGems.isActive.Value = true
            boosts.DoubleLuck.isActive.Value = true
            boosts.DoubleShiny.isActive.Value = true
            boosts.DoubleEventCurrency.isActive.Value = true
            task.wait()
        end
    end)
end

function autoRebirth()
    spawn(function()
        while autoRebirth == true do

            local args = {
                [1] = "LocalScript",
                [2] = "RequestRebirth",
                [3] = 1,
                [4] = false,
                [5] = false
            }

            remotePath:FireServer(unpack(args))

            task.wait()
        end
    end)
end

function buyEgg(eggType)
    spawn(function()
        while task.wait() do
            if not buyEgg then
                break
            end
            -- remotePath.EggService.Purchase:FireServer(eggType)
        end
    end)
end

function removeRandomGift()
    while removeGift == true do
        local ui = LocalPlayer.PlayerGui.randomGiftUI
        ui.Enabled = false

        ui:GetPropertyChangedSignal("Enabled"):Connect(function(bool)
            if bool then
                ui.Enabled = false
            end
        end)
        task.wait()
    end
end

function kill(target)
    if tools(LocalPlayer) then
        if target ~= nil then
            local NormPos = getRoot(getChar(LocalPlayer)).CFrame
            refresh(LocalPlayer)
            task.wait()
            repeat
                task.wait()
            until getChar(LocalPlayer) ~= nil and getRoot(getChar(LocalPlayer))
            task.wait(0.3)

            local hrp = getRoot(getChar(LocalPlayer))
            attach(LocalPlayer, target)
            repeat
                task.wait()
                hrp.CFrame = CFrame.new(999999, workspace.FallenPartsDestroyHeight + 5, 999999)
            until not getRoot(getChar(target)) or not getRoot(getChar(LocalPlayer))
            task.wait(1)
            LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = NormPos
        end
    else
        notify('Tool Required', 'You need to have an item in your inventory to use this command')
    end
end

function bring(target)
    if tools(LocalPlayer) then
        if target ~= nil then
            local NormPos = getRoot(getChar(LocalPlayer)).CFrame
            refresh(LocalPlayer)
            task.wait()
            repeat
                task.wait()
            until getChar(LocalPlayer) ~= nil and getRoot(getChar(LocalPlayer))
            task.wait(0.3)

            local hrp = getRoot(getChar(LocalPlayer))
            attach(LocalPlayer, target)
            repeat
                wait()
                hrp.CFrame = NormPos
            until not getRoot(getChar(target)) or not getRoot(getChar(LocalPlayer))
            task.wait(1)
            LocalPlayer.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = NormPos
        end
    else
        notify('Tool Required', 'You need to have an item in your inventory to use this command')
    end
end

function bang(plr, speed)
    if bangLoop then
        return
    end
    bangAnim = Instance.new("Animation")
    if not r15(plr) then
        bangAnim.AnimationId = "rbxassetid://148840371"
    else
        bangAnim.AnimationId = "rbxassetid://5918726674"
    end
    bang = getChar(LocalPlayer):FindFirstChildOfClass('Humanoid'):LoadAnimation(bangAnim)
    bang:Play(.1, 1, 1)
    bang:AdjustSpeed(speed)

    local bangplr = plr.Name
    bangDied = plr.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
        bangLoop = bangLoop:Disconnect()
        bang:Stop()
        bangAnim:Destroy()
        bangDied:Disconnect()
    end)
    local bangOffet = CFrame.new(0, 0, 1.1)
    bangLoop = game:GetService('RunService').Stepped:Connect(function()
        pcall(function()
            local otherRoot = getTorso(getCharacter(Players[bangplr]))
            getRoot(getCharacter(LocalPlayer)).CFrame = otherRoot.CFrame * bangOffet
        end)
    end)
end

function unbang()
    if bangLoop then
        bangLoop = bangLoop:Disconnect()
        bangDied:Disconnect()
        bang:Stop()
        bangAnim:Destroy()
    end
end

local worldsTeleport = {
    techWorld = game:GetService("Workspace").techWorld.teleport,
    fantasyWorld = game:GetService("Workspace").fantasyWorld.teleport,
    timeWorld = game:GetService("Workspace").spaceWorld.teleport,
    spaceWorld = game:GetService("Workspace").spaceWorld.teleport,
    oceanWorld = game:GetService("Workspace").oceanWorld.teleport,
    Underworld = game:GetService("Workspace").Zones.Underworld.teleport,
    foodWorld = game:GetService("Workspace").foodWorld.teleport
}

local function teleportWorld(world)
    for worldname, path in pairs(worldsTeleport) do
        print(worldname, world)
        if world == worldname then
            tpPlayerTo(path)
        end
    end
    return false
end

local Window = GuiLibrary.new("FlashWare V1")
local ClickingSim = Window:Tab("Clicking Simulator")

local Farming = ClickingSim:Section("Farming")
local Pets = ClickingSim:Section("Egg/Pets")
local Teleports = ClickingSim:Section("Teleports")
local Fun = ClickingSim:Section("Fun")
local Misc = ClickingSim:Section("Misc")

Farming:Title("Auto Farming")
local ClickGrindToggle = Farming:Toggle("Click Grinder", function(bool)
    ClickGrinder = bool
    if bool then
        ClickGrinder();
    end
end)
ClickGrindToggle:Set(false)

local AutoRebirthToggle = Farming:Toggle("Auto Rebirth", function(bool)
    autoRebirth = bool
    if bool then
        autoRebirth();
    end
end)
AutoRebirthToggle:Set(false)

Farming:Title("Other")

local activateBoostsToggle = Farming:Toggle("Activate All Boosts", function(bool)
    activateBoosts = bool
    if bool then
        activateBoosts();
    else
        boosts.DoubleClicks.isActive.Value = false
        boosts.DoubleGems.isActive.Value = false
        boosts.DoubleLuck.isActive.Value = false
        boosts.DoubleShiny.isActive.Value = false
        boosts.DoubleEventCurrency.isActive.Value = false
    end
end)
activateBoostsToggle:Set(false)

local BuyPetToggle = Pets:Toggle("Auto Buy Basic Pet", function(bool)
    buyEgg = bool
    if bool then
        buyEgg("basic");
    end
end)
BuyPetToggle:Set(false)

Teleports:Title("World Teleports")
local worldtpDropdown = Teleports:Dropdown("World to teleport to")

worldtpDropdown:Button("Tech World", function()
    teleportWorld("techWorld")
end)
worldtpDropdown:Button("Fantasy World", function()
    teleportWorld("fantasyWorld")
end)
worldtpDropdown:Button("Time World", function()
    teleportWorld("timeWorld")
end)
worldtpDropdown:Button("Space World", function()
    teleportWorld("spaceWorld")
end)
worldtpDropdown:Button("Ocean World", function()
    teleportWorld("oceanWorld")
end)
worldtpDropdown:Button("Underworld", function()
    teleportWorld("Underworld")
end)
worldtpDropdown:Button("Food World", function()
    teleportWorld("foodWorld")
end)

Teleports:Title("Player Teleports")

local PlayerTpDropdown = Teleports:Dropdown("Player to teleport to")

for _, p in pairs(Players:GetChildren()) do
    PlayerTpDropdown:Button(p.Name, function()
        tpPlayerTo(getRoot(p.Character))
    end)
end

Fun:Title("Bang players")
local playersDropdown = Fun:Dropdown("List of Players")

for _, p in pairs(Players:GetChildren()) do
    playersDropdown:Button(p.Name, function()
        bang(p, 3)
    end)
end

Fun:Button("Unbang", function()
    unbang()
end)

local RemoveRandomGiftToggle = Misc:Toggle("Remove random gift popups", function(bool)
    removeGift = bool
    if bool then
        removeRandomGift();
    else
        LocalPlayer.PlayerGui.randomGiftUI.Enabled = true
    end
end)
RemoveRandomGiftToggle:Set(false)

Misc:Button("Reset Character", function(bool)
    getCharacter(LocalPlayer):FindFirstChild("Humanoid").Health = 0
end)

Misc:Button("Refresh Character", function(bool)
    refresh(LocalPlayer)
end)
