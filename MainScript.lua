repeat task.wait() until game:IsLoaded()

local GuiLibrary
local baseDirectory = "flash/"
local FlashExecuted = true
local oldRainbow = false
local errorPopupShown = false
local redownloadedAssets = false
local ConfigsLoaded = false
local teleportedServers = false
local gameCamera = workspace.CurrentCamera
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or
                        function()
    end
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or
                        function()
        return 0
    end
local getcustomasset = getsynasset or getcustomasset or function(location)
    return "rbxasset://" .. location
end
local queueonteleport = syn and syn.queue_on_teleport or queue_on_teleport or function() end

local betterisfile = function(file) local suc, res = pcall(function() return readfile(file) end) return suc and res ~= nil end

local cachedfiles = "flash/cachedfiles.txt"
if not betterisfile(cachedfiles) then
    writefile(cachedfiles, game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/cachedfiles.txt", true))
end

local serv = setmetatable({}, { __index = function(self, name) local pass, service = pcall(game.GetService, game, name) if pass then self[name] = service return service end end})

local function displayErrorPopup(text, funclist)
	local oldidentity = getidentity()
	setidentity(8)
	local ErrorPrompt = getrenv().require(serv.CoreGui.RobloxGui.Modules.ErrorPrompt)
	local prompt = ErrorPrompt.new("Default")
	prompt._hideErrorCode = true
	local gui = Instance.new("ScreenGui", serv.CoreGui)
	prompt:setErrorTitle("FlashWare")
	local funcs
	if funclist then 
		funcs = {}
		local num = 0
		for i,v in pairs(funclist) do 
			num = num + 1
			table.insert(funcs, {
				Text = i,
				Callback = function() 
					prompt:_close() 
					v()
				end,
				Primary = num == #funclist
			})
		end
	end
	prompt:updateButtons(funcs or {{
		Text = "OK",
		Callback = function() 
			prompt:_close() 
		end,
		Primary = true
	}}, 'Default')
	prompt:setParent(gui)
	prompt:_open(text)
	setidentity(oldidentity)
end

local function getFromGithub(scripturl, force)
    local filepath = baseDirectory .. scripturl
	if not betterisfile(filepath) or force then
		local suc, res
		task.delay(10, function()
			if not res and not errorPopupShown then 
				errorPopupShown = true
				displayErrorPopup("The connection to GitHub is being slow, or there was an error with the script.")
			end
		end)
		suc, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/"..scripturl, true) end)
		if not suc or res == "404: Not Found" then
			displayErrorPopup("Couldn't connect to github : "..filepath.." : "..res)
			error(res)
		end

        local cached = readfile(cachedfiles)
		if scripturl:find(".lua") then cached = filepath.."\n"..cached end
        
        writefile("flash/cachedfiles.txt", cached)
		writefile(filepath, res)
	end
	return readfile(filepath)
end

local function LoadScript(scripturl)
	if betterisfile(scripturl) then
		return loadstring(getFromGithub(scripturl))()		
	end
end

local cachedAssets = {}
local function downloadAsset(path)
    if not betterisfile(path) then
        local textlabel = Instance.new("TextLabel")
        textlabel.Size = UDim2.new(1, 0, 0, 36)
        textlabel.Text = "Downloading " .. path
        textlabel.BackgroundTransparency = 1
        textlabel.TextStrokeTransparency = 0
        textlabel.TextSize = 30
        textlabel.Font = Enum.Font.SourceSans
        textlabel.TextColor3 = Color3.new(1, 1, 1)
        textlabel.Position = UDim2.new(0, 0, 0, -36)
        textlabel.Parent = GuiLibrary.MainGui

        local success, asset = pcall(getFromGithub, path:gsub("flash/assets", "assets"))
        if success and asset then
            writefile(path, asset)
        else
            warn("Couldn't download asset " .. path)
        end
        textlabel:Destroy()
    end
    if not cachedAssets[path] then
        cachedAssets[path] = getcustomasset(path)
    end
    return cachedAssets[path]
end

--assert(not shared.FlashExecuted, "FlashWare Is Already Injected")
shared.FlashExecuted = true

for i, v in pairs({baseDirectory:gsub("/", ""), "flash", "flash/Libraries", "flash/Games", "flash/configs", "flash/scripts", baseDirectory .. "configs", "flash/assets", "flash/exports"}) do
    if not isfolder(v) then
        makefolder(v)
    end
end
task.spawn(function()
    local success, assetver = pcall(function()
        return getFromGithub("assetsversion.txt")
    end)
    if not betterisfile("flash/assetsversion.txt") then
        writefile("flash/assetsversion.txt", "0")
    end
    if success and assetver > readfile("flash/assetsversion.txt") then
        redownloadedAssets = true
        if isfolder("flash/assets") then
            if delfolder then
                delfolder("flash/assets")
                makefolder("flash/assets")
            end
        end
        writefile("flash/assetsversion.txt", assetver)
    end
end)

GuiLibrary = LoadScript("GuiLibrary.lua")
shared.GuiLibrary = GuiLibrary

LoadScript("scripts/ChatTags.lua")

local saveSettingsLoop = coroutine.create(function()
    repeat
        GuiLibrary.SaveSettings()
        task.wait(10)
    until not FlashExecuted or not GuiLibrary
end)

task.spawn(function()
    local image = Instance.new("ImageLabel")
    image.Name = "IsLoaded"
    image.Image = downloadAsset("flash/assets/CombatIcon.png")
    image.Position = UDim2.new()
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromOffset(100, 100)
    image.ImageTransparency = 0.999
    image.Parent = GuiLibrary.MainGui
    image:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        image:Destroy()
        image = nil
    end)
    task.spawn(function()
        task.wait(15)
        if image and image.ContentImageSize == Vector2.zero and (not errorPopupShown) and (not redownloadedAssets) and (not betterisfile("flash/assets/check.txt")) then
            errorPopupShown = true
            displayErrorPopup("Assets wouldn't load, Try another executor if this keeps happening. \n Current executor : " ..(identifyexecutor and identifyexecutor() or "Unknown") .. ")", {
                OK = function()
                    writefile("flash/assets/check.txt", "Lua is a lightweight, high-level, multi-paradigm programming language designed primarily for embedded use in applications. Lua is cross-platform, since the interpreter of compiled bytecode is written in ANSI C, and Lua has a relatively simple C API to embed it into applications.")
                end
            })
        end
    end)
end)

GuiLibrary.CreateMainWindow()
local Configs = GuiLibrary.CreateTab({
    Name = "Configs",
    Order = 9,
    Icon = "assets/ConfigIcon.png"
})
local Settings = GuiLibrary.CreateTab({
    Name = "Settings",
    Order = 10,
    Icon = "assets/SettingsIcon.png"
})

Settings.CreateToggle({
    Name = "Lobby Check",
    DefaultToggle = true,
    Column = "1",
    Function = function() end
})
-- Settings.CreateDropdown({
--     Name = "GUI Theme"
-- })
Settings.CreateToggle({
    Name = "Blatant mode",
    DefaultToggle = false,
    Column = "1",
    Function = function() 
        pcall(function()
            GuiLibrary.CreateNotification("Blatant Enabled", "Flash is now in Blatant Mode.", 5.5, "assets/WarningNotification.png")
        end)
    end
})

local IdledConnection
Settings.CreateToggle({
    Name = "Anti AFK",
    DefaultToggle = false,
    Column = "2",
    Function = function(callback)
        if callback then
            IdledConnection = serv.Players.LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                task.wait(1)
                game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end)
        else
            if IdledConnection and IdledConnection.Disconnect then
                IdledConnection:Disconnect()
                print("Disconnected IdledConnection")
            end
        end
    end
})

Settings.CreateToggle({
    Name = "Blur Background",
    DefaultToggle = true,
    Column = "2",
    Function = function(callback)
        game:GetService("RunService"):SetRobloxGuiFocused(GuiLibrary.MainGui.ScaledGui.MainUI.Visible and callback)
    end
})
local GUIRescaleToggle = Settings.CreateToggle({
    Name = "Rescale",
    DefaultToggle = true,
    Column = "3",
    Function = function(callback)
        task.spawn(function()
            GuiLibrary.MainRescale.Scale = (callback and math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1) or 0.99)
            task.wait(0.01)
            GuiLibrary.MainRescale.Scale = (callback and math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1) or 1)
        end)
    end
})
gameCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if GUIRescaleToggle.Enabled then
        GuiLibrary.MainRescale.Scale = math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1)
    end
end)
Settings.CreateToggle({
    Name = "Notifications",
    DefaultToggle = true,
    Column = "2",
    Function = function(callback)
        GuiLibrary.Notifications = callback
    end
})
Settings.CreateSlider({
    Name = "Rainbow Speed",
    Min = 1,
    Max = 100,
    DefaultValue = 10,
    Column = "3",
    Function = function(val)
        GuiLibrary.RainbowSpeed = math.max((val / 10) - 0.4, 0)
    end
})

local teleportConnection = serv.Players.LocalPlayer.OnTeleport:Connect(function(State)
    if (not teleportedServers) then
        teleportedServers = true
        local teleportScript = [[
			shared.FlashSwitchServers = true  
			loadstring(game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/Startup.lua", true))()
		]]
        if shared.FlashCustomConfig then
            teleportScript = "shared.FlashCustomConfig = '" .. shared.FlashCustomConfig .. "'\n" .. teleportScript
        end
        GuiLibrary.SaveSettings()
        queueonteleport(teleportScript)
    end
end)

GuiLibrary.SelfDestruct = function()
    task.spawn(function()
        coroutine.close(saveSettingsLoop)
    end)
    if FlashExecuted then
        GuiLibrary.SaveSettings()
    end
    FlashExecuted = false
    game:GetService("UserInputService").OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None

    for i, v in pairs(GuiLibrary.Objects) do
        if v.Type == "ToggleButton" and v.Controller.Enabled then
            v.Controller.Toggle(false)
        end
    end

    GuiLibrary.SelfDestructEvent:Fire()
    shared.FlashExecuted = nil
    shared.FlashSwitchServers = nil
    shared.GuiLibrary = nil
    GuiLibrary.KeyInputHandler:Disconnect()
    GuiLibrary.KeyInputHandler2:Disconnect()
    teleportConnection:Disconnect()
    GuiLibrary.MainGui:Destroy()
    game:GetService("RunService"):SetRobloxGuiFocused(false)
end

Settings.CreateToggle({
    Name = "Reset Current Config",
    DefaultToggle = true,
    Column = "3",
    Function = function()
        GuiLibrary.SelfDestruct()
        if delfile then
            delfile(baseDirectory .. "Configs/" .. (GuiLibrary.CurrentConfig ~= "default" and GuiLibrary.CurrentConfig or "") .. game.PlaceId .. ".FlashConfig.txt")
        else
            writefile(baseDirectory .. "Configs/" .. (GuiLibrary.CurrentConfig ~= "default" and GuiLibrary.CurrentConfig or "") .. game.PlaceId .. ".FlashConfig.txt", "")
        end
        shared.FlashSwitchServers = true
        shared.FlashOpenGui = true
        LoadScript("Startup.lua")
    end
})
Settings.CreateToggle({
    Name = "Reset UI Position",
    DefaultToggle = true,
    Column = "3",
    Function = function()
        for i, v in pairs(GuiLibrary.Objects) do
            if (v.Type == "MainWindow") then
                v.Object.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
        end
    end
})
Settings.CreateToggle({
    Name = "Uninject",
    DefaultToggle = true,
    Column = "3",
    Function = GuiLibrary.SelfDestruct
})

local PlaceDirectory = "Games/"..game.PlaceId..".lua"
if betterisfile("flash/" .. PlaceDirectory) then
    LoadScript("flash/" .. PlaceDirectory)
else
    local success, result = pcall(getFromGithub(PlaceDirectory))
    if success then
        LoadScript(result)()
    else
        LoadScript("Universal.lua")
    end
end
GuiLibrary.LoadSettings(shared.FlashCustomConfig)
local Configs = {}
for i, v in pairs(GuiLibrary.Configs) do
    table.insert(Configs, i)
end

table.sort(Configs, function(a, b)
    return b == "default" and true or a:lower() < b:lower()
end)

if not shared.FlashSwitchServers then
    GuiLibrary.LoadedAnimation(true)
else
    shared.FlashSwitchServers = nil
end
if shared.FlashOpenGui then
    GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = true
    game:GetService("RunService"):SetRobloxGuiFocused(GuiLibrary.MainBlur.Size ~= 0)
    shared.FlashOpenGui = nil
end
coroutine.resume(saveSettingsLoop)
