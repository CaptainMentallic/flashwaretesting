repeat
    task.wait()
until game:IsLoaded()
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
local queueonteleport = syn and syn.queue_on_teleport or queue_on_teleport or function()
end
local cachedfiles = "flash/cachedfiles.txt" or game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/cachedfiles.txt", true)

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

local function getFromGithub(scripturl)
    local filepath = baseDirectory .. scripturl
    if not isfile(filepath) then
        local warningShown = false
        task.spawn(function()
            local success, _ = pcall(task.wait, 10)
            if not isfile(filepath) and not warningShown then
                warningShown = true
                displayErrorPopup("The connection to GitHub is being slow. \n Please wait a little.")
            end
        end)
        local url = string.format("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/%s", scripturl)
        local success, response = pcall(serv.HttpService.RequestAsync, serv.HttpService, {
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Roblox/WinInet",
            },
        })
        assert(success and response.Success, "Failed to connect to GitHub: flash/" .. scripturl .. " : " .. response.StatusCode)
        if scripturl:find("%.lua$") then
            local cached = readfile(cachedfiles)
            response.Body = scripturl .. "\n" .. cached .. "\n" .. response.Body
        end
        writefile(filepath, response.Body)
    end
    return readfile(filepath)
end  

local cachedAssets = {}
local function downloadAsset(path)
    if not isfile(path) then
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
        downloadLabel:Destroy()
    end
    if not cachedAssets[path] then
        cachedAssets[path] = getcustomasset(path)
    end
    return cachedAssets[path]
end

assert(not shared.FlashExecuted, "FlashWare Is Already Injected")
shared.FlashExecuted = true

for i, v in pairs({baseDirectory:gsub("/", ""), "flash", "flash/Libraries", "flash/Games", "flash/configs",
                   baseDirectory .. "configs", "flash/assets", "flash/exports"}) do
    if not isfolder(v) then
        makefolder(v)
    end
end
task.spawn(function()
    local success, assetver = pcall(function()
        return getFromGithub("assetsversion.txt")
    end)
    if not isfile("flash/assetsversion.txt") then
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

GuiLibrary = loadstring(getFromGithub("GuiLibrary.lua"))()
shared.GuiLibrary = GuiLibrary

local saveSettingsLoop = coroutine.create(function()
    repeat
        GuiLibrary.SaveSettings()
        task.wait(10)
    until not FlashExecuted or not GuiLibrary
end)

task.spawn(function()
    local image = Instance.new("ImageLabel")
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
        if image and image.ContentImageSize == Vector2.zero and (not errorPopupShown) and (not redownloadedAssets) and
            (not isfile("flash/assets/check3.txt")) then
            errorPopupShown = true
            displayErrorPopup("Assets failed to load, Try another executor (executor : " ..
                                  (identifyexecutor and identifyexecutor() or "Unknown") .. ")", {
                OK = function()
                    writefile("flash/assets/check3.txt", "")
                end
            })
        end
    end)
end)

local GUI = GuiLibrary.CreateMainWindow()
local Configs = GuiLibrary.CreateTab({
    Name = "Configs",
    Order = 9,
    Icon = "assets/ConfigIcon"
})
local Settings = GuiLibrary.CreateTab({
    Name = "Settings",
    Order = 10,
    Icon = "assets/SettingIcon"
})
-- local Controller = shared.GuiLibrary.Objects["GUIWindow"]["Controller"]
-- Controller.CreateTab({})

local ConfigsTextList = {
    RefreshValues = function()
    end
}
ConfigsTextList = Configs.CreateTextList({
    Name = "ConfigsList",
    TempText = "Type name",
    NoSave = true,
    AddFunction = function(ConfigName)
        GuiLibrary.Configs[ConfigName] = {
            Keybind = "",
            Selected = false
        }
        local Configs = {}
        for i, v in pairs(GuiLibrary.Configs) do
            table.insert(Configs, i)
        end
        table.sort(Configs, function(a, b)
            return b == "default" and true or a:lower() < b:lower()
        end)
        ConfigsTextList.RefreshValues(Configs)
    end,
    RemoveFunction = function(ConfigIndex, ConfigName)
        if ConfigName ~= "default" and ConfigName ~= GuiLibrary.CurrentConfig then
            pcall(function()
                delfile(baseDirectory .. "Configs/" .. ConfigName .. game.PlaceId .. ".FlashConfig.txt")
            end)
            GuiLibrary.Configs[ConfigName] = nil
        else
            table.insert(ConfigsTextList.ObjectList, ConfigName)
            ConfigsTextList.RefreshValues(ConfigsTextList.ObjectList)
        end
    end,
    CustomFunction = function(ConfigObject, ConfigName)
        if GuiLibrary.Configs[ConfigName] == nil then
            GuiLibrary.Configs[ConfigName] = {
                Keybind = ""
            }
        end
        ConfigObject.MouseButton1Click:Connect(function()
            GuiLibrary.SwitchConfig(ConfigName)
        end)
        local newsize = UDim2.new(0, 20, 0, 21)
        local bindbkg = Instance.new("TextButton")
        bindbkg.Text = ""
        bindbkg.AutoButtonColor = false
        bindbkg.Size = UDim2.new(0, 20, 0, 21)
        bindbkg.Position = UDim2.new(1, -50, 0, 6)
        bindbkg.BorderSizePixel = 0
        bindbkg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        bindbkg.BackgroundTransparency = 0.95
        bindbkg.Visible = GuiLibrary.Configs[ConfigName].Keybind ~= ""
        bindbkg.Parent = ConfigObject
        local bindimg = Instance.new("ImageLabel")
        bindimg.Image = downloadAsset("flash/assets/KeybindIcon.png")
        bindimg.BackgroundTransparency = 1
        bindimg.Size = UDim2.new(0, 12, 0, 12)
        bindimg.Position = UDim2.new(0, 4, 0, 5)
        bindimg.ImageTransparency = 0.2
        bindimg.Active = false
        bindimg.Visible = (GuiLibrary.Configs[ConfigName].Keybind == "")
        bindimg.Parent = bindbkg
        local bindtext = Instance.new("TextLabel")
        bindtext.Active = false
        bindtext.BackgroundTransparency = 1
        bindtext.TextSize = 16
        bindtext.Parent = bindbkg
        bindtext.Font = Enum.Font.SourceSans
        bindtext.Size = UDim2.new(1, 0, 1, 0)
        bindtext.TextColor3 = Color3.fromRGB(85, 85, 85)
        bindtext.Visible = (GuiLibrary.Configs[ConfigName].Keybind ~= "")
        local bindtext2 = Instance.new("TextLabel")
        bindtext2.Text = "PRESS A KEY TO BIND"
        bindtext2.Size = UDim2.new(0, 150, 0, 33)
        bindtext2.Font = Enum.Font.SourceSans
        bindtext2.TextSize = 17
        bindtext2.TextColor3 = Color3.fromRGB(201, 201, 201)
        bindtext2.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
        bindtext2.BorderSizePixel = 0
        bindtext2.Visible = false
        bindtext2.Parent = ConfigObject
        local bindround = Instance.new("UICorner")
        bindround.CornerRadius = UDim.new(0, 4)
        bindround.Parent = bindbkg
        bindbkg.MouseButton1Click:Connect(function()
            if not GuiLibrary.KeybindCaptured then
                GuiLibrary.KeybindCaptured = true
                task.spawn(function()
                    bindtext2.Visible = true
                    repeat
                        task.wait()
                    until GuiLibrary.PressedKeybindKey ~= ""
                    local key = (GuiLibrary.PressedKeybindKey == GuiLibrary.Configs[ConfigName].Keybind and "" or
                                    GuiLibrary.PressedKeybindKey)
                    if key == "" then
                        GuiLibrary.Configs[ConfigName].Keybind = key
                        newsize = UDim2.new(0, 20, 0, 21)
                        bindbkg.Size = newsize
                        bindbkg.Visible = true
                        bindbkg.Position = UDim2.new(1, -(30 + newsize.X.Offset), 0, 6)
                        bindimg.Visible = true
                        bindtext.Visible = false
                        bindtext.Text = key
                    else
                        local textsize = serv.TextService:GetTextSize(key, 16, bindtext.Font, Vector2.new(99999, 99999))
                        newsize = UDim2.new(0, 13 + textsize.X, 0, 21)
                        GuiLibrary.Configs[ConfigName].Keybind = key
                        bindbkg.Visible = true
                        bindbkg.Size = newsize
                        bindbkg.Position = UDim2.new(1, -(30 + newsize.X.Offset), 0, 6)
                        bindimg.Visible = false
                        bindtext.Visible = true
                        bindtext.Text = key
                    end
                    GuiLibrary.PressedKeybindKey = ""
                    GuiLibrary.KeybindCaptured = false
                    bindtext2.Visible = false
                end)
            end
        end)
        bindbkg.MouseEnter:Connect(function()
            bindimg.Image = downloadAsset("flash/assets/PencilIcon.png")
            bindimg.Visible = true
            bindtext.Visible = false
            bindbkg.Size = UDim2.new(0, 20, 0, 21)
            bindbkg.Position = UDim2.new(1, -50, 0, 6)
        end)
        bindbkg.MouseLeave:Connect(function()
            bindimg.Image = downloadAsset("flash/assets/KeybindIcon.png")
            if GuiLibrary.Configs[ConfigName].Keybind ~= "" then
                bindimg.Visible = false
                bindtext.Visible = true
                bindbkg.Size = newsize
                bindbkg.Position = UDim2.new(1, -(30 + newsize.X.Offset), 0, 6)
            end
        end)
        ConfigObject.MouseEnter:Connect(function()
            bindbkg.Visible = true
        end)
        ConfigObject.MouseLeave:Connect(function()
            bindbkg.Visible = GuiLibrary.Configs[ConfigName] and GuiLibrary.Configs[ConfigName].Keybind ~= ""
        end)
        if GuiLibrary.Configs[ConfigName].Keybind ~= "" then
            bindtext.Text = GuiLibrary.Configs[ConfigName].Keybind
            local textsize = serv.TextService:GetTextSize(GuiLibrary.Configs[ConfigName].Keybind, 16, bindtext.Font,
                Vector2.new(99999, 99999))
            newsize = UDim2.new(0, 13 + textsize.X, 0, 21)
            bindbkg.Size = newsize
            bindbkg.Position = UDim2.new(1, -(30 + newsize.X.Offset), 0, 6)
        end
        if ConfigName == GuiLibrary.CurrentConfig then
            ConfigObject.BackgroundColor3 = Color3.fromHSV(GuiLibrary.Objects["Gui ColorSliderColor"].Controller.Hue,
                GuiLibrary.Objects["Gui ColorSliderColor"].Controller.Sat, GuiLibrary.Objects["Gui ColorSliderColor"]
                    .Controller.Value)
            ConfigObject.ImageButton.BackgroundColor3 = Color3.fromHSV(
                GuiLibrary.Objects["Gui ColorSliderColor"].Controller.Hue,
                GuiLibrary.Objects["Gui ColorSliderColor"].Controller.Sat,
                GuiLibrary.Objects["Gui ColorSliderColor"].Controller.Value)
            ConfigObject.ItemText.TextColor3 = Color3.new(1, 1, 1)
            ConfigObject.ItemText.TextStrokeTransparency = 0.75
            bindbkg.BackgroundTransparency = 0.9
            bindtext.TextColor3 = Color3.fromRGB(214, 214, 214)
        end
    end
})

local TextGUI = GuiLibrary.CreateCustomWindow({
    Name = "Text GUI",
    Icon = "flash/assets/TextGUIIcon1.png",
    IconSize = 21
})
local TextGUICircleObject = {
    CircleList = {}
}
GUI.CreateCustomToggle({
    Name = "Text GUI",
    Icon = "flash/assets/TextGUIIcon3.png",
    Function = function(callback)
        TextGUI.SetVisible(callback)
    end,
    Priority = 2
})
local GUIColorSlider = {
    RainbowValue = false
}
local TextGUIMode = {
    Value = "Normal"
}
local TextGUISortMode = {
    Value = "Alphabetical"
}
local TextGUIBackgroundToggle = {
    Enabled = false
}
local TextGUIObjects = {
    Logo = {},
    Labels = {},
    ShadowLabels = {},
    Backgrounds = {}
}
local TextGUIConnections = {}
local TextGUIFormatted = {}
local flashLogoFrame = Instance.new("Frame")
flashLogoFrame.BackgroundTransparency = 1
flashLogoFrame.Size = UDim2.new(1, 0, 1, 0)
flashLogoFrame.Parent = TextGUI.GetCustomChildren()
local flashLogo = Instance.new("ImageLabel")
flashLogo.Parent = flashLogoFrame
flashLogo.Name = "Logo"
flashLogo.Size = UDim2.new(0, 100, 0, 27)
flashLogo.Position = UDim2.new(1, -140, 0, 3)
flashLogo.BackgroundColor3 = Color3.new()
flashLogo.BorderSizePixel = 0
flashLogo.BackgroundTransparency = 1
flashLogo.Visible = true
flashLogo.Image = downloadAsset("flash/assets/VapeLogo3.png")
local flashLogoV4 = Instance.new("ImageLabel")
flashLogoV4.Parent = flashLogo
flashLogoV4.Size = UDim2.new(0, 41, 0, 24)
flashLogoV4.Name = "Logo2"
flashLogoV4.Position = UDim2.new(1, 0, 0, 1)
flashLogoV4.BorderSizePixel = 0
flashLogoV4.BackgroundColor3 = Color3.new()
flashLogoV4.BackgroundTransparency = 1
flashLogoV4.Image = downloadAsset("flash/assets/VapeLogo4.png")
local flashLogoShadow = flashLogo:Clone()
flashLogoShadow.ImageColor3 = Color3.new()
flashLogoShadow.ImageTransparency = 0.5
flashLogoShadow.ZIndex = 0
flashLogoShadow.Position = UDim2.new(0, 1, 0, 1)
flashLogoShadow.Visible = false
flashLogoShadow.Parent = flashLogo
flashLogoShadow.Logo2.ImageColor3 = Color3.new()
flashLogoShadow.Logo2.ZIndex = 0
flashLogoShadow.Logo2.ImageTransparency = 0.5
local flashLogoGradient = Instance.new("UIGradient")
flashLogoGradient.Rotation = 90
flashLogoGradient.Parent = flashLogo
local flashLogoGradient2 = Instance.new("UIGradient")
flashLogoGradient2.Rotation = 90
flashLogoGradient2.Parent = flashLogoV4
local flashText = Instance.new("TextLabel")
flashText.Parent = flashLogoFrame
flashText.Size = UDim2.new(1, 0, 1, 0)
flashText.Position = UDim2.new(1, -154, 0, 35)
flashText.TextColor3 = Color3.new(1, 1, 1)
flashText.RichText = true
flashText.BackgroundTransparency = 1
flashText.TextXAlignment = Enum.TextXAlignment.Left
flashText.TextYAlignment = Enum.TextYAlignment.Top
flashText.BorderSizePixel = 0
flashText.BackgroundColor3 = Color3.new()
flashText.Font = Enum.Font.SourceSans
flashText.Text = ""
flashText.TextSize = 23
local flashTextExtra = Instance.new("TextLabel")
flashTextExtra.Name = "ExtraText"
flashTextExtra.Parent = flashText
flashTextExtra.Size = UDim2.new(1, 0, 1, 0)
flashTextExtra.Position = UDim2.new(0, 1, 0, 1)
flashTextExtra.BorderSizePixel = 0
flashTextExtra.Visible = false
flashTextExtra.ZIndex = 0
flashTextExtra.Text = ""
flashTextExtra.BackgroundTransparency = 1
flashTextExtra.TextTransparency = 0.5
flashTextExtra.TextXAlignment = Enum.TextXAlignment.Left
flashTextExtra.TextYAlignment = Enum.TextYAlignment.Top
flashTextExtra.TextColor3 = Color3.new()
flashTextExtra.Font = Enum.Font.SourceSans
flashTextExtra.TextSize = 23
local flashCustomText = Instance.new("TextLabel")
flashCustomText.TextSize = 30
flashCustomText.Font = Enum.Font.GothamBold
flashCustomText.Size = UDim2.new(1, 0, 1, 0)
flashCustomText.BackgroundTransparency = 1
flashCustomText.Position = UDim2.new(0, 0, 0, 35)
flashCustomText.TextXAlignment = Enum.TextXAlignment.Left
flashCustomText.TextYAlignment = Enum.TextYAlignment.Top
flashCustomText.Text = ""
flashCustomText.Parent = flashLogoFrame
local flashCustomTextShadow = flashCustomText:Clone()
flashCustomTextShadow.ZIndex = -1
flashCustomTextShadow.Size = UDim2.new(1, 0, 1, 0)
flashCustomTextShadow.TextTransparency = 0.5
flashCustomTextShadow.TextColor3 = Color3.new()
flashCustomTextShadow.Position = UDim2.new(0, 1, 0, 1)
flashCustomTextShadow.Parent = flashCustomText
flashCustomText:GetPropertyChangedSignal("TextXAlignment"):Connect(function()
    flashCustomTextShadow.TextXAlignment = flashCustomText.TextXAlignment
end)
local flashBackground = Instance.new("Frame")
flashBackground.BackgroundTransparency = 1
flashBackground.BorderSizePixel = 0
flashBackground.BackgroundColor3 = Color3.new()
flashBackground.Size = UDim2.new(1, 0, 1, 0)
flashBackground.Visible = false
flashBackground.Parent = flashLogoFrame
flashBackground.ZIndex = 0
local flashBackgroundList = Instance.new("UIListLayout")
flashBackgroundList.FillDirection = Enum.FillDirection.Vertical
flashBackgroundList.SortOrder = Enum.SortOrder.LayoutOrder
flashBackgroundList.Padding = UDim.new(0, 0)
flashBackgroundList.Parent = flashBackground
local flashBackgroundTable = {}
local flashScale = Instance.new("UIScale")
flashScale.Parent = flashLogoFrame

local function TextGUIUpdate()
    local scaledgui = FlashExecuted and GuiLibrary.MainGui.ScaledGui
    if scaledgui and scaledgui.Visible then
        local formattedText = ""
        local moduleList = {}

        for i, v in pairs(GuiLibrary.Objects) do
            if v.Type == "OptionsButton" and v.Controller.Enabled then
                local blacklistedCheck = table.find(TextGUICircleObject.CircleList.ObjectList, v.Controller.Name)
                blacklistedCheck = blacklistedCheck and TextGUICircleObject.CircleList.ObjectList[blacklistedCheck]
                if not blacklistedCheck then
                    local extraText = v.Controller.GetExtraText()
                    table.insert(moduleList, {
                        Text = v.Controller.Name,
                        ExtraText = extraText ~= "" and " " .. extraText or ""
                    })
                end
            end
        end

        if TextGUISortMode.Value == "Alphabetical" then
            table.sort(moduleList, function(a, b)
                return a.Text:lower() < b.Text:lower()
            end)
        else
            table.sort(moduleList, function(a, b)
                return serv.TextService:GetTextSize(a.Text .. a.ExtraText, flashText.TextSize, flashText.Font,
                           Vector2.new(1000000, 1000000)).X >
                           serv.TextService:GetTextSize(b.Text .. b.ExtraText, flashText.TextSize, flashText.Font,
                               Vector2.new(1000000, 1000000)).X
            end)
        end

        local backgroundList = {}
        local first = true
        for i, v in pairs(moduleList) do
            local newEntryText = v.Text .. v.ExtraText
            if first then
                formattedText = "\n" .. newEntryText
                first = false
            else
                formattedText = formattedText .. '\n' .. newEntryText
            end
            table.insert(backgroundList, newEntryText)
        end

        TextGUIFormatted = moduleList
        flashTextExtra.Text = formattedText
        flashText.Size = UDim2.fromOffset(154, (formattedText ~= "" and
            serv.TextService:GetTextSize(formattedText, flashText.TextSize, flashText.Font,
                Vector2.new(1000000, 1000000)) or Vector2.zero).Y)

        if TextGUI.GetCustomChildren().Parent then
            if (TextGUI.GetCustomChildren().Parent.Position.X.Offset + TextGUI.GetCustomChildren().Parent.Size.X.Offset /
                2) >= (gameCamera.ViewportSize.X / 2) then
                flashText.TextXAlignment = Enum.TextXAlignment.Right
                flashTextExtra.TextXAlignment = Enum.TextXAlignment.Right
                flashTextExtra.Position = UDim2.fromOffset(5, 1)
                flashLogo.Position = UDim2.new(1, -142, 0, 8)
                flashText.Position = UDim2.new(1, -158, 0,
                    (flashLogo.Visible and (TextGUIBackgroundToggle.Enabled and 41 or 35) or 5) +
                        (flashCustomText.Visible and 25 or 0) - 23)
                flashCustomText.Position = UDim2.fromOffset(0, flashLogo.Visible and 35 or 0)
                flashCustomText.TextXAlignment = Enum.TextXAlignment.Right
                flashBackgroundList.HorizontalAlignment = Enum.HorizontalAlignment.Right
                flashBackground.Position = flashText.Position + UDim2.fromOffset(-56, 2 + 23)
            else
                flashText.TextXAlignment = Enum.TextXAlignment.Left
                flashTextExtra.TextXAlignment = Enum.TextXAlignment.Left
                flashTextExtra.Position = UDim2.fromOffset(5, 1)
                flashLogo.Position = UDim2.fromOffset(2, 8)
                flashText.Position = UDim2.fromOffset(6,
                    (flashLogo.Visible and (TextGUIBackgroundToggle.Enabled and 41 or 35) or 5) +
                        (flashCustomText.Visible and 25 or 0) - 23)
                flashCustomText.Position = UDim2.fromOffset(0, flashLogo.Visible and 35 or 0)
                flashCustomText.TextXAlignment = Enum.TextXAlignment.Left
                flashBackgroundList.HorizontalAlignment = Enum.HorizontalAlignment.Left
                flashBackground.Position = flashText.Position + UDim2.fromOffset(-1, 2 + 23)
            end
        end

        if TextGUIMode.Value == "Drawing" then
            for i, v in pairs(TextGUIObjects.Labels) do
                v.Visible = false
                v:Remove()
                TextGUIObjects.Labels[i] = nil
            end
            for i, v in pairs(TextGUIObjects.ShadowLabels) do
                v.Visible = false
                v:Remove()
                TextGUIObjects.ShadowLabels[i] = nil
            end
            for i, v in pairs(backgroundList) do
                local textdraw = Drawing.new("Text")
                textdraw.Text = v
                textdraw.Size = 23 * flashScale.Scale
                textdraw.ZIndex = 2
                textdraw.Position = flashText.AbsolutePosition + Vector2.new(
                    flashText.TextXAlignment == Enum.TextXAlignment.Right and
                        (flashText.AbsoluteSize.X - textdraw.TextBounds.X), ((textdraw.Size - 3) * i) + 6)
                textdraw.Visible = true
                local textdraw2 = Drawing.new("Text")
                textdraw2.Text = textdraw.Text
                textdraw2.Size = 23 * flashScale.Scale
                textdraw2.Position = textdraw.Position + Vector2.new(1, 1)
                textdraw2.Color = Color3.new()
                textdraw2.Transparency = 0.5
                textdraw2.Visible = flashTextExtra.Visible
                table.insert(TextGUIObjects.Labels, textdraw)
                table.insert(TextGUIObjects.ShadowLabels, textdraw2)
            end
        end

        for i, v in pairs(flashBackground:GetChildren()) do
            table.clear(flashBackgroundTable)
            if v:IsA("Frame") then
                v:Destroy()
            end
        end
        for i, v in pairs(backgroundList) do
            local textsize = serv.TextService:GetTextSize(v, flashText.TextSize, flashText.Font,
                Vector2.new(1000000, 1000000))
            local backgroundFrame = Instance.new("Frame")
            backgroundFrame.BorderSizePixel = 0
            backgroundFrame.BackgroundTransparency = 0.62
            backgroundFrame.BackgroundColor3 = Color3.new()
            backgroundFrame.Visible = true
            backgroundFrame.ZIndex = 0
            backgroundFrame.LayoutOrder = i
            backgroundFrame.Size = UDim2.fromOffset(textsize.X + 8, textsize.Y)
            backgroundFrame.Parent = flashBackground
            local backgroundLineFrame = Instance.new("Frame")
            backgroundLineFrame.Size = UDim2.new(0, 2, 1, 0)
            backgroundLineFrame.Position = (flashBackgroundList.HorizontalAlignment == Enum.HorizontalAlignment.Left and
                                               UDim2.new() or UDim2.new(1, -2, 0, 0))
            backgroundLineFrame.BorderSizePixel = 0
            backgroundLineFrame.Name = "ColorFrame"
            backgroundLineFrame.Parent = backgroundFrame
            local backgroundLineExtra = Instance.new("Frame")
            backgroundLineExtra.BorderSizePixel = 0
            backgroundLineExtra.BackgroundTransparency = 0.96
            backgroundLineExtra.BackgroundColor3 = Color3.new()
            backgroundLineExtra.ZIndex = 0
            backgroundLineExtra.Size = UDim2.new(1, 0, 0, 2)
            backgroundLineExtra.Position = UDim2.new(0, 0, 1, -1)
            backgroundLineExtra.Parent = backgroundFrame
            table.insert(flashBackgroundTable, backgroundFrame)
        end

        GuiLibrary.UpdateUI(GUIColorSlider.Hue, GUIColorSlider.Sat, GUIColorSlider.Value)
    end
end

TextGUI.GetCustomChildren().Parent:GetPropertyChangedSignal("Position"):Connect(TextGUIUpdate)
GuiLibrary.UpdateHudEvent.Event:Connect(TextGUIUpdate)
flashScale:GetPropertyChangedSignal("Scale"):Connect(function()
    local childrenobj = TextGUI.GetCustomChildren()
    local check = (childrenobj.Parent.Position.X.Offset + childrenobj.Parent.Size.X.Offset / 2) >=
                      (gameCamera.ViewportSize.X / 2)
    childrenobj.Position = UDim2.new((check and -(flashScale.Scale - 1) or 0),
        (check and 0 or -6 * (flashScale.Scale - 1)), 1, -6 * (flashScale.Scale - 1))
    TextGUIUpdate()
end)
TextGUIMode = TextGUI.CreateDropdown({
    Name = "Mode",
    List = {"Normal", "Drawing"},
    Function = function(val)
        flashLogoFrame.Visible = val == "Normal"
        for i, v in pairs(TextGUIConnections) do
            v:Disconnect()
        end
        for i, v in pairs(TextGUIObjects) do
            for i2, v2 in pairs(v) do
                v2.Visible = false
                v2:Remove()
                v[i2] = nil
            end
        end
        if val == "Drawing" then
            local flashLogoDrawing = Drawing.new("Image")
            flashLogoDrawing.Data = readfile("flash/assets/VapeLogo3.png")
            flashLogoDrawing.Size = flashLogo.AbsoluteSize
            flashLogoDrawing.Position = flashLogo.AbsolutePosition + Vector2.new(0, 36)
            flashLogoDrawing.ZIndex = 2
            flashLogoDrawing.Visible = flashLogo.Visible
            local flashLogoV4Drawing = Drawing.new("Image")
            flashLogoV4Drawing.Data = readfile("flash/assets/VapeLogo4.png")
            flashLogoV4Drawing.Size = flashLogoV4.AbsoluteSize
            flashLogoV4Drawing.Position = flashLogoV4.AbsolutePosition + Vector2.new(0, 36)
            flashLogoV4Drawing.ZIndex = 2
            flashLogoV4Drawing.Visible = flashLogo.Visible
            local flashLogoShadowDrawing = Drawing.new("Image")
            flashLogoShadowDrawing.Data = readfile("flash/assets/VapeLogo3.png")
            flashLogoShadowDrawing.Size = flashLogo.AbsoluteSize
            flashLogoShadowDrawing.Position = flashLogo.AbsolutePosition + Vector2.new(1, 37)
            flashLogoShadowDrawing.Transparency = 0.5
            flashLogoShadowDrawing.Visible = flashLogo.Visible and flashLogoShadow.Visible
            local VapeLogo4Drawing = Drawing.new("Image")
            VapeLogo4Drawing.Data = readfile("flash/assets/VapeLogo4.png")
            VapeLogo4Drawing.Size = flashLogoV4.AbsoluteSize
            VapeLogo4Drawing.Position = flashLogoV4.AbsolutePosition + Vector2.new(1, 37)
            VapeLogo4Drawing.Transparency = 0.5
            VapeLogo4Drawing.Visible = flashLogo.Visible and flashLogoShadow.Visible
            local flashCustomDrawingText = Drawing.new("Text")
            flashCustomDrawingText.Size = 30
            flashCustomDrawingText.Text = flashCustomText.Text
            flashCustomDrawingText.Color = flashCustomText.TextColor3
            flashCustomDrawingText.ZIndex = 2
            flashCustomDrawingText.Position = flashCustomText.AbsolutePosition +
                                                  Vector2.new(
                    flashText.TextXAlignment == Enum.TextXAlignment.Right and
                        (flashCustomText.AbsoluteSize.X - flashCustomDrawingText.TextBounds.X), 32)
            flashCustomDrawingText.Visible = flashCustomText.Visible
            local flashCustomDrawingShadow = Drawing.new("Text")
            flashCustomDrawingShadow.Size = 30
            flashCustomDrawingShadow.Text = flashCustomText.Text
            flashCustomDrawingShadow.Transparency = 0.5
            flashCustomDrawingShadow.Color = Color3.new()
            flashCustomDrawingShadow.Position = flashCustomDrawingText.Position + Vector2.new(1, 1)
            flashCustomDrawingShadow.Visible = flashCustomText.Visible and flashTextExtra.Visible
            pcall(function()
                flashLogoShadowDrawing.Color = Color3.new()
                VapeLogo4Drawing.Color = Color3.new()
                flashLogoDrawing.Color = flashLogoGradient.Color.Keypoints[1].Value
            end)
            table.insert(TextGUIObjects.Logo, flashLogoDrawing)
            table.insert(TextGUIObjects.Logo, flashLogoV4Drawing)
            table.insert(TextGUIObjects.Logo, flashLogoShadowDrawing)
            table.insert(TextGUIObjects.Logo, VapeLogo4Drawing)
            table.insert(TextGUIObjects.Logo, flashCustomDrawingText)
            table.insert(TextGUIObjects.Logo, flashCustomDrawingShadow)
            table.insert(TextGUIConnections, flashLogo:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                flashLogoDrawing.Position = flashLogo.AbsolutePosition + Vector2.new(0, 36)
                flashLogoShadowDrawing.Position = flashLogo.AbsolutePosition + Vector2.new(1, 37)
            end))
            table.insert(TextGUIConnections, flashLogo:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                flashLogoDrawing.Size = flashLogo.AbsoluteSize
                flashLogoShadowDrawing.Size = flashLogo.AbsoluteSize
                flashCustomDrawingText.Size = 30 * flashScale.Scale
                flashCustomDrawingShadow.Size = 30 * flashScale.Scale
            end))
            table.insert(TextGUIConnections, flashLogoV4:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                flashLogoV4Drawing.Position = flashLogoV4.AbsolutePosition + Vector2.new(0, 36)
                VapeLogo4Drawing.Position = flashLogoV4.AbsolutePosition + Vector2.new(1, 37)
            end))
            table.insert(TextGUIConnections, flashLogoV4:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                flashLogoV4Drawing.Size = flashLogoV4.AbsoluteSize
                VapeLogo4Drawing.Size = flashLogoV4.AbsoluteSize
            end))
            table.insert(TextGUIConnections,
                flashCustomText:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                    flashCustomDrawingText.Position = flashCustomText.AbsolutePosition +
                                                          Vector2.new(
                            flashText.TextXAlignment == Enum.TextXAlignment.Right and
                                (flashCustomText.AbsoluteSize.X - flashCustomDrawingText.TextBounds.X), 32)
                    flashCustomDrawingShadow.Position = flashCustomDrawingText.Position + Vector2.new(1, 1)
                end))
            table.insert(TextGUIConnections, flashLogoShadow:GetPropertyChangedSignal("Visible"):Connect(function()
                flashLogoShadowDrawing.Visible = flashLogoShadow.Visible
                VapeLogo4Drawing.Visible = flashLogoShadow.Visible
            end))
            table.insert(TextGUIConnections, flashTextExtra:GetPropertyChangedSignal("Visible"):Connect(function()
                for i, textdraw in pairs(TextGUIObjects.ShadowLabels) do
                    textdraw.Visible = flashTextExtra.Visible
                end
                flashCustomDrawingShadow.Visible = flashCustomText.Visible and flashTextExtra.Visible
            end))
            table.insert(TextGUIConnections, flashLogo:GetPropertyChangedSignal("Visible"):Connect(function()
                flashLogoDrawing.Visible = flashLogo.Visible
                flashLogoV4Drawing.Visible = flashLogo.Visible
                flashLogoShadowDrawing.Visible = flashLogo.Visible and flashTextExtra.Visible
                VapeLogo4Drawing.Visible = flashLogo.Visible and flashTextExtra.Visible
            end))
            table.insert(TextGUIConnections, flashCustomText:GetPropertyChangedSignal("Visible"):Connect(function()
                flashCustomDrawingText.Visible = flashCustomText.Visible
                flashCustomDrawingShadow.Visible = flashCustomText.Visible and flashTextExtra.Visible
            end))
            table.insert(TextGUIConnections, flashCustomText:GetPropertyChangedSignal("Text"):Connect(function()
                flashCustomDrawingText.Text = flashCustomText.Text
                flashCustomDrawingShadow.Text = flashCustomText.Text
                flashCustomDrawingText.Position = flashCustomText.AbsolutePosition +
                                                      Vector2.new(
                        flashText.TextXAlignment == Enum.TextXAlignment.Right and
                            (flashCustomText.AbsoluteSize.X - flashCustomDrawingText.TextBounds.X), 32)
                flashCustomDrawingShadow.Position = flashCustomDrawingText.Position + Vector2.new(1, 1)
            end))
            table.insert(TextGUIConnections, flashCustomText:GetPropertyChangedSignal("TextColor3"):Connect(function()
                flashCustomDrawingText.Color = flashCustomText.TextColor3
            end))
            table.insert(TextGUIConnections, flashText:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                for i, textdraw in pairs(TextGUIObjects.Labels) do
                    textdraw.Position = flashText.AbsolutePosition + Vector2.new(
                        flashText.TextXAlignment == Enum.TextXAlignment.Right and
                            (flashText.AbsoluteSize.X - textdraw.TextBounds.X), ((textdraw.Size - 3) * i) + 6)
                end
                for i, textdraw in pairs(TextGUIObjects.ShadowLabels) do
                    textdraw.Position = Vector2.new(1, 1) + (flashText.AbsolutePosition + Vector2.new(
                        flashText.TextXAlignment == Enum.TextXAlignment.Right and
                            (flashText.AbsoluteSize.X - textdraw.TextBounds.X), ((textdraw.Size - 3) * i) + 6))
                end
            end))
            table.insert(TextGUIConnections, flashLogoGradient:GetPropertyChangedSignal("Color"):Connect(function()
                pcall(function()
                    flashLogoDrawing.Color = flashLogoGradient.Color.Keypoints[1].Value
                end)
            end))
        end
    end
})
TextGUISortMode = TextGUI.CreateDropdown({
    Name = "Sort",
    List = {"Alphabetical", "Length"},
    Function = function(val)
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
local TextGUIFonts = {"SourceSans"}
local TextGUIFonts2 = {"GothamBold"}
for i, v in pairs(Enum.Font:GetEnumItems()) do
    if v.Name ~= "SourceSans" then
        table.insert(TextGUIFonts, v.Name)
    end
    if v.Name ~= "GothamBold" then
        table.insert(TextGUIFonts2, v.Name)
    end
end
TextGUI.CreateDropdown({
    Name = "Font",
    List = TextGUIFonts,
    Function = function(val)
        flashText.Font = Enum.Font[val]
        flashTextExtra.Font = Enum.Font[val]
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
TextGUI.CreateDropdown({
    Name = "CustomTextFont",
    List = TextGUIFonts2,
    Function = function(val)
        flashText.Font = Enum.Font[val]
        flashTextExtra.Font = Enum.Font[val]
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
TextGUI.CreateSlider({
    Name = "Scale",
    Min = 1,
    Max = 50,
    Default = 10,
    Function = function(val)
        flashScale.Scale = val / 10
    end
})
TextGUI.CreateToggle({
    Name = "Shadow",
    Function = function(callback)
        flashTextExtra.Visible = callback
        flashLogoShadow.Visible = callback
    end,
    HoverText = "Renders shadowed text."
})
TextGUI.CreateToggle({
    Name = "Watermark",
    Function = function(callback)
        flashLogo.Visible = callback
        GuiLibrary.UpdateHudEvent:Fire()
    end,
    HoverText = "Renders a flash watermark"
})
TextGUIBackgroundToggle = TextGUI.CreateToggle({
    Name = "Render background",
    Function = function(callback)
        flashBackground.Visible = callback
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
TextGUI.CreateToggle({
    Name = "Hide Modules",
    Function = function(callback)
        if TextGUICircleObject.Object then
            TextGUICircleObject.Object.Visible = callback
        end
    end
})
TextGUICircleObject = TextGUI.CreateCircleWindow({
    Name = "Blacklist",
    Type = "Blacklist",
    UpdateFunction = function()
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
TextGUICircleObject.Object.Visible = false
local TextGUIGradient = TextGUI.CreateToggle({
    Name = "Gradient Logo",
    Function = function()
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
TextGUI.CreateToggle({
    Name = "Alternate Text",
    Function = function()
        GuiLibrary.UpdateHudEvent:Fire()
    end
})
local CustomText = {
    Value = "",
    Object = nil
}
TextGUI.CreateToggle({
    Name = "Add custom text",
    Function = function(callback)
        flashCustomText.Visible = callback
        CustomText.Object.Visible = callback
        GuiLibrary.UpdateHudEvent:Fire()
    end,
    HoverText = "Renders a custom label"
})
CustomText = TextGUI.CreateTextBox({
    Name = "Custom text",
    FocusLost = function(enter)
        flashCustomText.Text = CustomText.Value
        flashCustomTextShadow.Text = CustomText.Value
    end
})
CustomText.Object.Visible = false
local TargetInfo = GuiLibrary.CreateCustomWindow({
    Name = "Target Info",
    Icon = "flash/assets/TargetInfoIcon1.png",
    IconSize = 16
})
local TargetInfoDisplayNames = TargetInfo.CreateToggle({
    Name = "Use Display Name",
    Function = function()
    end,
    Default = true
})
local TargetInfoBackground = {
    Enabled = false
}
local TargetInfoMainFrame = Instance.new("Frame")
TargetInfoMainFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
TargetInfoMainFrame.BorderSizePixel = 0
TargetInfoMainFrame.BackgroundTransparency = 1
TargetInfoMainFrame.Size = UDim2.new(0, 220, 0, 72)
TargetInfoMainFrame.Position = UDim2.new(0, 0, 0, 5)
TargetInfoMainFrame.Parent = TargetInfo.GetCustomChildren()
local TargetInfoMainInfo = Instance.new("Frame")
TargetInfoMainInfo.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
TargetInfoMainInfo.Size = UDim2.new(0, 220, 0, 80)
TargetInfoMainInfo.BackgroundTransparency = 0.25
TargetInfoMainInfo.Position = UDim2.new(0, 0, 0, 0)
TargetInfoMainInfo.Name = "MainInfo"
TargetInfoMainInfo.Parent = TargetInfoMainFrame
local TargetInfoName = Instance.new("TextLabel")
TargetInfoName.TextSize = 17
TargetInfoName.Font = Enum.Font.SourceSans
TargetInfoName.TextColor3 = Color3.fromRGB(162, 162, 162)
TargetInfoName.Position = UDim2.new(0, 72, 0, 7)
TargetInfoName.TextStrokeTransparency = 1
TargetInfoName.BackgroundTransparency = 1
TargetInfoName.Size = UDim2.new(0, 80, 0, 16)
TargetInfoName.TextScaled = true
TargetInfoName.Text = "Target name"
TargetInfoName.ZIndex = 2
TargetInfoName.TextXAlignment = Enum.TextXAlignment.Left
TargetInfoName.TextYAlignment = Enum.TextYAlignment.Top
TargetInfoName.Parent = TargetInfoMainInfo
local TargetInfoNameShadow = TargetInfoName:Clone()
TargetInfoNameShadow.Size = UDim2.new(1, 0, 1, 0)
TargetInfoNameShadow.TextTransparency = 0.5
TargetInfoNameShadow.TextColor3 = Color3.new()
TargetInfoNameShadow.ZIndex = 1
TargetInfoNameShadow.Position = UDim2.new(0, 1, 0, 1)
TargetInfoName:GetPropertyChangedSignal("Text"):Connect(function()
    TargetInfoNameShadow.Text = TargetInfoName.Text
end)
TargetInfoNameShadow.Parent = TargetInfoName
local TargetInfoHealthBackground = Instance.new("Frame")
TargetInfoHealthBackground.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
TargetInfoHealthBackground.Size = UDim2.new(0, 138, 0, 4)
TargetInfoHealthBackground.Position = UDim2.new(0, 72, 0, 29)
TargetInfoHealthBackground.Parent = TargetInfoMainInfo
local TargetInfoHealthBackgroundShadow = Instance.new("ImageLabel")
TargetInfoHealthBackgroundShadow.AnchorPoint = Vector2.new(0.5, 0.5)
TargetInfoHealthBackgroundShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
TargetInfoHealthBackgroundShadow.Image = downloadAsset("flash/assets/WindowBlur.png")
TargetInfoHealthBackgroundShadow.BackgroundTransparency = 1
TargetInfoHealthBackgroundShadow.ImageTransparency = 0.6
TargetInfoHealthBackgroundShadow.ZIndex = -1
TargetInfoHealthBackgroundShadow.Size = UDim2.new(1, 6, 1, 6)
TargetInfoHealthBackgroundShadow.ImageColor3 = Color3.new()
TargetInfoHealthBackgroundShadow.ScaleType = Enum.ScaleType.Slice
TargetInfoHealthBackgroundShadow.SliceCenter = Rect.new(10, 10, 118, 118)
TargetInfoHealthBackgroundShadow.Parent = TargetInfoHealthBackground
local TargetInfoHealth = Instance.new("Frame")
TargetInfoHealth.BackgroundColor3 = Color3.fromRGB(40, 137, 109)
TargetInfoHealth.Size = UDim2.new(1, 0, 1, 0)
TargetInfoHealth.ZIndex = 3
TargetInfoHealth.BorderSizePixel = 0
TargetInfoHealth.Parent = TargetInfoHealthBackground
local TargetInfoHealthExtra = Instance.new("Frame")
TargetInfoHealthExtra.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
TargetInfoHealthExtra.Size = UDim2.new(0, 0, 1, 0)
TargetInfoHealthExtra.ZIndex = 4
TargetInfoHealthExtra.BorderSizePixel = 0
TargetInfoHealthExtra.AnchorPoint = Vector2.new(1, 0)
TargetInfoHealthExtra.Position = UDim2.new(1, 0, 0, 0)
TargetInfoHealthExtra.Parent = TargetInfoHealth
local TargetInfoImage = Instance.new("ImageLabel")
TargetInfoImage.Size = UDim2.new(0, 61, 0, 61)
TargetInfoImage.BackgroundTransparency = 1
TargetInfoImage.Image = 'rbxthumb://type=AvatarHeadShot&id=' .. serv.PlayerService.LocalPlayer.UserId .. '&w=420&h=420'
TargetInfoImage.Position = UDim2.new(0, 5, 0, 10)
TargetInfoImage.Parent = TargetInfoMainInfo
local TargetInfoMainInfoCorner = Instance.new("UICorner")
TargetInfoMainInfoCorner.CornerRadius = UDim.new(0, 4)
TargetInfoMainInfoCorner.Parent = TargetInfoMainInfo
local TargetInfoHealthBackgroundCorner = Instance.new("UICorner")
TargetInfoHealthBackgroundCorner.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthBackgroundCorner.Parent = TargetInfoHealthBackground
local TargetInfoHealthCorner = Instance.new("UICorner")
TargetInfoHealthCorner.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthCorner.Parent = TargetInfoHealth
local TargetInfoHealthCorner2 = Instance.new("UICorner")
TargetInfoHealthCorner2.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthCorner2.Parent = TargetInfoHealthExtra
local TargetInfoHealthExtraCorner = Instance.new("UICorner")
TargetInfoHealthExtraCorner.CornerRadius = UDim.new(0, 4)
TargetInfoHealthExtraCorner.Parent = TargetInfoImage
TargetInfoBackground = TargetInfo.CreateToggle({
    Name = "Use Background",
    Function = function(callback)
        TargetInfoMainInfo.BackgroundTransparency = callback and 0.25 or 1
        TargetInfoName.TextColor3 = callback and Color3.fromRGB(162, 162, 162) or Color3.new(1, 1, 1)
        TargetInfoName.Size = UDim2.new(0, 80, 0, callback and 16 or 18)
        TargetInfoHealthBackground.Size = UDim2.new(0, 138, 0, callback and 4 or 7)
    end,
    Default = true
})
local TargetInfoHealthTween
TargetInfo.GetCustomChildren().Parent:GetPropertyChangedSignal("Size"):Connect(function()
    TargetInfoMainInfo.Position = UDim2.fromOffset(0, TargetInfo.GetCustomChildren().Parent.Size ~=
        UDim2.fromOffset(220, 0) and -5 or 40)
end)
shared.flashTargetInfo = {
    UpdateInfo = function(tab, targetsize)
        if TargetInfo.GetCustomChildren().Parent then
            local hasTarget = false
            for _, v in pairs(shared.flashTargetInfo.Targets) do
                hasTarget = true
                TargetInfoImage.Image = 'rbxthumb://type=AvatarHeadShot&id=' .. v.Player.UserId .. '&w=420&h=420'
                TargetInfoHealth:TweenSize(
                    UDim2.new(math.clamp(v.Humanoid.Health / v.Humanoid.MaxHealth, 0, 1), 0, 1, 0),
                    Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
                TargetInfoHealthExtra:TweenSize(UDim2.new(math.clamp((v.Humanoid.Health / v.Humanoid.MaxHealth) - 1, 0,
                    1), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
                if TargetInfoHealthTween then
                    TargetInfoHealthTween:Cancel()
                end
                TargetInfoHealthTween = game:GetService("TweenService"):Create(TargetInfoHealth, TweenInfo.new(0.25,
                    Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromHSV(math.clamp(v.Humanoid.Health / v.Humanoid.MaxHealth, 0, 1) / 2.5,
                        0.89, 1)
                })
                TargetInfoHealthTween:Play()
                TargetInfoName.Text = (TargetInfoDisplayNames.Enabled and v.Player.DisplayName or v.Player.Name)
                break
            end
            TargetInfoMainInfo.Visible = hasTarget or
                                             (TargetInfo.GetCustomChildren().Parent.Size ~= UDim2.new(0, 220, 0, 0))
        end
    end,
    Targets = {},
    Object = TargetInfo
}
task.spawn(function()
    repeat
        shared.flashTargetInfo.UpdateInfo()
        task.wait()
    until not FlashExecuted
end)
GUI.CreateCustomToggle({
    Name = "Target Info",
    Icon = "flash/assets/TargetInfoIcon2.png",
    Function = function(callback)
        TargetInfo.SetVisible(callback)
    end,
    Priority = 1
})
local GeneralSettings = GUI.CreateDivider2("General Settings")
local ModuleSettings = GUI.CreateDivider2("Module Settings")
local GUISettings = GUI.CreateDivider2("GUI Settings")
local TeamsByColorToggle = {
    Enabled = false
}
TeamsByColorToggle = ModuleSettings.CreateToggle({
    Name = "Teams by color",
    Function = function()
        if TeamsByColorToggle.Refresh then
            TeamsByColorToggle.Refresh:Fire()
        end
    end,
    Default = true,
    HoverText = "Ignore players on your team designated by the game"
})
TeamsByColorToggle.Refresh = Instance.new("BindableEvent")
local MiddleClickInput
ModuleSettings.CreateToggle({
    Name = "MiddleClick friends",
    Function = function(callback)
        if callback then
            MiddleClickInput = game:GetService("UserInputService").InputBegan:Connect(function(input1)
                if input1.UserInputType == Enum.UserInputType.MouseButton3 then
                    local entityLibrary = shared.flashentity
                    if entityLibrary then
                        local rayparams = RaycastParams.new()
                        rayparams.FilterType = Enum.RaycastFilterType.Whitelist
                        local chars = {}
                        for i, v in pairs(entityLibrary.entityList) do
                            table.insert(chars, v.Character)
                        end
                        rayparams.FilterDescendantsInstances = chars
                        local mouseunit = serv.PlayerService.LocalPlayer:GetMouse().UnitRay
                        local ray = workspace:Raycast(mouseunit.Origin, mouseunit.Direction * 10000, rayparams)
                        if ray then
                            for i, v in pairs(entityLibrary.entityList) do
                                if ray.Instance:IsDescendantOf(v.Character) then
                                    local found = table.find(FriendsTextList.ObjectList, v.Player.Name)
                                    if not found then
                                        table.insert(FriendsTextList.ObjectList, v.Player.Name)
                                        table.insert(FriendsTextList.ObjectListEnabled, true)
                                        FriendsTextList.RefreshValues(FriendsTextList.ObjectList)
                                    else
                                        table.remove(FriendsTextList.ObjectList, found)
                                        table.remove(FriendsTextList.ObjectListEnabled, found)
                                        FriendsTextList.RefreshValues(FriendsTextList.ObjectList)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        else
            if MiddleClickInput then
                MiddleClickInput:Disconnect()
            end
        end
    end,
    HoverText = "Click middle mouse button to add the player you are hovering over as a friend"
})
ModuleSettings.CreateToggle({
    Name = "Lobby Check",
    Function = function()
    end,
    Default = true,
    HoverText = "Temporarily disables certain features in server lobbies."
})
GUIColorSlider = GUI.CreateColorSlider("GUI Theme", function(h, s, v)
    GuiLibrary.UpdateUI(h, s, v)
end)
local BlatantModeToggle = GUI.CreateToggle({
    Name = "Blatant mode",
    Function = function()
    end,
    HoverText = "Required for certain features."
})
local windowSortOrder = {
    CombatButton = 1,
    BlatantButton = 2,
    RenderButton = 3,
    UtilityButton = 4,
    WorldButton = 5,
    FriendsButton = 6,
    TargetsButton = 7,
    ConfigsButton = 8
}
local windowSortOrder2 = {"Combat", "Blatant", "Render", "Utility", "World"}

local function getflashSaturation(val)
    local sat = 0.9
    if val < 0.03 then
        sat = 0.75 + (0.15 * math.clamp(val / 0.03, 0, 1))
    end
    if val > 0.59 then
        sat = 0.9 - (0.4 * math.clamp((val - 0.59) / 0.07, 0, 1))
    end
    if val > 0.68 then
        sat = 0.5 + (0.4 * math.clamp((val - 0.68) / 0.14, 0, 1))
    end
    if val > 0.89 then
        sat = 0.9 - (0.15 * math.clamp((val - 0.89) / 0.1, 0, 1))
    end
    return sat
end

GuiLibrary.UpdateUI = function(h, s, val, bypass)
    pcall(function()
        local rainbowGUICheck = GUIColorSlider.RainbowValue
        local mainRainbowSaturation = rainbowGUICheck and getflashSaturation(h) or s
        local mainRainbowGradient = h + (rainbowGUICheck and (-0.05) or 0)
        mainRainbowGradient = mainRainbowGradient % 1
        local mainRainbowGradientSaturation = TextGUIGradient.Enabled and getflashSaturation(mainRainbowGradient) or
                                                  mainRainbowSaturation

        GuiLibrary.Objects.GUIWindow.Object.Logo1.Logo2.ImageColor3 =
            Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
        flashText.TextColor3 = Color3.fromHSV(TextGUIGradient.Enabled and mainRainbowGradient or h,
            mainRainbowSaturation, rainbowGUICheck and 1 or val)
        flashCustomText.TextColor3 = flashText.TextColor3
        flashLogoGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(h,
            mainRainbowSaturation, rainbowGUICheck and 1 or val)), ColorSequenceKeypoint.new(1, flashText.TextColor3)})
        flashLogoGradient2.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(h,
            TextGUIGradient.Enabled and rainbowGUICheck and mainRainbowSaturation or 0, 1)),
                                                      ColorSequenceKeypoint.new(1,
            Color3.fromHSV(TextGUIGradient.Enabled and mainRainbowGradient or h,
                TextGUIGradient.Enabled and rainbowGUICheck and mainRainbowSaturation or 0, 1))})

        local newTextGUIText = "\n"
        local backgroundTable = {}
        for i, v in pairs(TextGUIFormatted) do
            local rainbowcolor = h + (rainbowGUICheck and (-0.025 * (i + (TextGUIGradient.Enabled and 2 or 0))) or 0)
            rainbowcolor = rainbowcolor % 1
            local newcolor = Color3.fromHSV(rainbowcolor, rainbowGUICheck and getflashSaturation(rainbowcolor) or
                mainRainbowSaturation, rainbowGUICheck and 1 or val)
            newTextGUIText = newTextGUIText .. '<font color="rgb(' .. math.floor(newcolor.R * 255) .. "," ..
                                 math.floor(newcolor.G * 255) .. "," .. math.floor(newcolor.B * 255) .. ')">' .. v.Text ..
                                 '</font><font color="rgb(170, 170, 170)">' .. v.ExtraText .. '</font>\n'
            backgroundTable[i] = newcolor
        end

        if TextGUIMode.Value == "Drawing" then
            for i, v in pairs(TextGUIObjects.Labels) do
                if backgroundTable[i] then
                    v.Color = backgroundTable[i]
                end
            end
        end

        if TextGUIBackgroundToggle.Enabled then
            for i, v in pairs(flashBackgroundTable) do
                v.ColorFrame.BackgroundColor3 = backgroundTable[v.LayoutOrder] or Color3.new()
            end
        end
        flashText.Text = newTextGUIText

        if (not GuiLibrary.MainGui.ScaledGui.ClickGui.Visible) and (not bypass) then
            return
        end
        local buttonColorIndex = 0
        for i, v in pairs(GuiLibrary.Objects) do
            if v.Type == "TargetFrame" then
                if v.Object2.Visible then
                    v.Object.TextButton.Frame.BackgroundColor3 =
                        Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                end
            elseif v.Type == "TargetButton" then
                if v.Controller.Enabled then
                    v.Object.BackgroundColor3 = Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                end
            elseif v.Type == "CircleListFrame" then
                if v.Object2.Visible then
                    v.Object.TextButton.Frame.BackgroundColor3 =
                        Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                end
            elseif (v.Type == "Button" or v.Type == "ButtonMain") and v.Controller.Enabled then
                buttonColorIndex = buttonColorIndex + 1
                local rainbowcolor = h + (rainbowGUICheck and (-0.025 * windowSortOrder[i]) or 0)
                rainbowcolor = rainbowcolor % 1
                local newcolor = Color3.fromHSV(rainbowcolor, rainbowGUICheck and getflashSaturation(rainbowcolor) or
                    mainRainbowSaturation, rainbowGUICheck and 1 or val)
                v.Object.ButtonText.TextColor3 = newcolor
                if v.Object:FindFirstChild("ButtonIcon") then
                    v.Object.ButtonIcon.ImageColor3 = newcolor
                end
            elseif v.Type == "OptionsButton" then
                if v.Controller.Enabled then
                    local newcolor = Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                    if (not oldrainbow) then
                        local mainRainbowGradient = table.find(windowSortOrder2, v.Object.Parent.Parent.Name)
                        mainRainbowGradient = mainRainbowGradient and (mainRainbowGradient - 1) > 0 and
                                                  GuiLibrary.Objects[windowSortOrder2[mainRainbowGradient - 1] ..
                                                      "Window"].SortOrder or 0
                        local rainbowcolor = h +
                                                 (rainbowGUICheck and (-0.025 * (mainRainbowGradient + v.SortOrder)) or
                                                     0)
                        rainbowcolor = rainbowcolor % 1
                        newcolor = Color3.fromHSV(rainbowcolor, rainbowGUICheck and getflashSaturation(rainbowcolor) or
                            mainRainbowSaturation, rainbowGUICheck and 1 or val)
                    end
                    v.Object.BackgroundColor3 = newcolor
                end
            elseif v.Type == "ExtrasButton" then
                if v.Controller.Enabled then
                    local rainbowcolor = h + (rainbowGUICheck and (-0.025 * buttonColorIndex) or 0)
                    rainbowcolor = rainbowcolor % 1
                    local newcolor = Color3.fromHSV(rainbowcolor,
                        rainbowGUICheck and getflashSaturation(rainbowcolor) or mainRainbowSaturation,
                        rainbowGUICheck and 1 or val)
                    v.Object.ImageColor3 = newcolor
                end
            elseif (v.Type == "Toggle" or v.Type == "ToggleMain") and v.Controller.Enabled then
                v.Object.ToggleFrame1.BackgroundColor3 = Color3.fromHSV(h, mainRainbowSaturation,
                    rainbowGUICheck and 1 or val)
            elseif v.Type == "Slider" or v.Type == "SliderMain" then
                v.Object.Slider.FillSlider.BackgroundColor3 =
                    Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                v.Object.Slider.FillSlider.ButtonSlider.ImageColor3 =
                    Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
            elseif v.Type == "TwoSlider" then
                v.Object.Slider.FillSlider.BackgroundColor3 =
                    Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                v.Object.Slider.ButtonSlider.ImageColor3 = Color3.fromHSV(h, mainRainbowSaturation,
                    rainbowGUICheck and 1 or val)
                v.Object.Slider.ButtonSlider2.ImageColor3 = Color3.fromHSV(h, mainRainbowSaturation,
                    rainbowGUICheck and 1 or val)
            end
        end

        local rainbowcolor = h + (rainbowGUICheck and (-0.025 * buttonColorIndex) or 0)
        rainbowcolor = rainbowcolor % 1
        GuiLibrary.Objects.GUIWindow.Object.Children.Extras.MainButton.ImageColor3 =
            (GUI.GetVisibleIcons() > 0 and Color3.fromHSV(rainbowcolor, getflashSaturation(rainbowcolor), 1) or
                Color3.fromRGB(199, 199, 199))

        for i, v in pairs(ConfigsTextList.ScrollingObject.ScrollingFrame:GetChildren()) do
            if v:IsA("TextButton") and v.ItemText.Text == GuiLibrary.CurrentConfig then
                v.BackgroundColor3 = Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                v.ImageButton.BackgroundColor3 = Color3.fromHSV(h, mainRainbowSaturation, rainbowGUICheck and 1 or val)
                v.ItemText.TextColor3 = Color3.new(1, 1, 1)
                v.ItemText.TextStrokeTransparency = 0.75
            end
        end
    end)
end

GUISettings.CreateToggle({
    Name = "Blur Background",
    Function = function(callback)
        GuiLibrary.MainBlur.Size = (callback and 25 or 0)
        game:GetService("RunService"):SetRobloxGuiFocused(GuiLibrary.MainGui.ScaledGui.ClickGui.Visible and callback)
    end,
    Default = true,
    HoverText = "Blur the background of the GUI"
})
local welcomeMessage = GUISettings.CreateToggle({
    Name = "GUI bind indicator",
    Function = function()
    end,
    Default = true,
    HoverText = 'Displays a message indicating your GUI keybind upon injecting.\nI.E "Press RIGHTSHIFT to open GUI"'
})
GUISettings.CreateToggle({
    Name = "Old Rainbow",
    Function = function(callback)
        oldrainbow = callback
    end,
    HoverText = "Reverts to old rainbow"
})
GUISettings.CreateToggle({
    Name = "Show Tooltips",
    Function = function(callback)
        GuiLibrary.ToggleTooltips = callback
    end,
    Default = true,
    HoverText = "Toggles visibility of these"
})
local GUIRescaleToggle = GUISettings.CreateToggle({
    Name = "Rescale",
    Function = function(callback)
        task.spawn(function()
            GuiLibrary.MainRescale.Scale = (callback and math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1) or 0.99)
            task.wait(0.01)
            GuiLibrary.MainRescale.Scale = (callback and math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1) or 1)
        end)
    end,
    Default = true,
    HoverText = "Rescales the GUI"
})
gameCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if GUIRescaleToggle.Enabled then
        GuiLibrary.MainRescale.Scale = math.clamp(gameCamera.ViewportSize.X / 1920, 0.5, 1)
    end
end)
GUISettings.CreateToggle({
    Name = "Notifications",
    Function = function(callback)
        GuiLibrary.Notifications = callback
    end,
    Default = true,
    HoverText = "Shows notifications"
})
local ToggleNotifications
ToggleNotifications = GUISettings.CreateToggle({
    Name = "Toggle Alert",
    Function = function(callback)
        GuiLibrary.ToggleNotifications = callback
    end,
    Default = true,
    HoverText = "Notifies you if a module is enabled/disabled."
})
ToggleNotifications.Object.BackgroundTransparency = 0
ToggleNotifications.Object.BorderSizePixel = 0
ToggleNotifications.Object.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
GUISettings.CreateSlider({
    Name = "Rainbow Speed",
    Function = function(val)
        GuiLibrary.RainbowSpeed = math.max((val / 10) - 0.4, 0)
    end,
    Min = 1,
    Max = 100,
    Default = 10
})

local GUIbind = GUI.CreateGUIBind()
local teleportConnection = serv.PlayerService.LocalPlayer.OnTeleport:Connect(function(State)
    if (not teleportedServers) then
        teleportedServers = true
        local teleportScript = [[
			shared.flashSwitchServers = true  
			loadstring(game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/".."/Startup.lua", true))()
		]]
        if shared.flashCustomConfig then
            teleportScript = "shared.flashCustomConfig = '" .. shared.flashCustomConfig .. "'\n" .. teleportScript
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
        if (v.Type == "Button" or v.Type == "OptionsButton") and v.Controller.Enabled then
            v.Controller.ToggleButton(false)
        end
    end

    for i, v in pairs(TextGUIConnections) do
        v:Disconnect()
    end
    for i, v in pairs(TextGUIObjects) do
        for i2, v2 in pairs(v) do
            v2.Visible = false
            v2:Destroy()
            v[i2] = nil
        end
    end

    GuiLibrary.SelfDestructEvent:Fire()
    shared.FlashExecuted = nil
    shared.flashSwitchServers = nil
    shared.GuiLibrary = nil
    GuiLibrary.KeyInputHandler:Disconnect()
    if MiddleClickInput then
        MiddleClickInput:Disconnect()
    end
    teleportConnection:Disconnect()
    GuiLibrary.MainGui:Destroy()
    game:GetService("RunService"):SetRobloxGuiFocused(false)
end

GeneralSettings.CreateButton2({
    Name = "RESET CURRENT Config",
    Function = function()
        GuiLibrary.SelfDestruct()
        if delfile then
            delfile(baseDirectory .. "Configs/" ..
                        (GuiLibrary.CurrentConfig ~= "default" and GuiLibrary.CurrentConfig or "") .. game.PlaceId ..
                        ".FlashConfig.txt")
        else
            writefile(baseDirectory .. "Configs/" ..
                          (GuiLibrary.CurrentConfig ~= "default" and GuiLibrary.CurrentConfig or "") .. game.PlaceId ..
                          ".FlashConfig.txt", "")
        end
        shared.flashSwitchServers = true
        shared.flashOpenGui = true
        loadstring(getFromGithub("Startup.lua"))()
    end
})
GUISettings.CreateButton2({
    Name = "RESET GUI POSITIONS",
    Function = function()
        for i, v in pairs(GuiLibrary.Objects) do
            if (v.Type == "Window" or v.Type == "CustomWindow") then
                v.Object.Position = (i == "GUIWindow" and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 223, 0, 6))
            end
        end
    end
})
GUISettings.CreateButton2({
    Name = "SORT GUI",
    Function = function()
        local sorttable = {}
        local movedown = false
        local sortordertable = {
            GUIWindow = 1,
            CombatWindow = 2,
            BlatantWindow = 3,
            RenderWindow = 4,
            UtilityWindow = 5,
            WorldWindow = 6,
            FriendsWindow = 7,
            TargetsWindow = 8,
            ConfigsWindow = 9,
            ["Text GUICustomWindow"] = 10,
            TargetInfoCustomWindow = 11,
            RadarCustomWindow = 12
        }
        local storedpos = {}
        local num = 6
        for i, v in pairs(GuiLibrary.Objects) do
            local obj = GuiLibrary.Objects[i]
            if obj then
                if v.Type == "Window" and v.Object.Visible then
                    local sortordernum = (sortordertable[i] or #sorttable)
                    sorttable[sortordernum] = v.Object
                end
            end
        end
        for i2, v2 in pairs(sorttable) do
            if num > 1697 then
                movedown = true
                num = 6
            end
            v2.Position = UDim2.new(0, num, 0, (movedown and (storedpos[num] and (storedpos[num] + 9) or 400) or 39))
            if not storedpos[num] then
                storedpos[num] = v2.AbsoluteSize.Y
                if v2.Name == "MainWindow" then
                    storedpos[num] = 400
                end
            end
            num = num + 223
        end
    end
})
GeneralSettings.CreateButton2({
    Name = "UNINJECT",
    Function = GuiLibrary.SelfDestruct
})

if isfile("flash/" .. PlaceDirectory) then
    loadstring(readfile("flash/" .. PlaceDirectory))()
else
    if getFromGithub(PlaceDirectory) then
        loadstring(getFromGithub(PlaceDirectory))()
    else
        loadstring(getFromGithub("Universal.lua"))()
    end
end
if #ConfigsTextList.ObjectList == 0 then
    table.insert(ConfigsTextList.ObjectList, "default")
    ConfigsTextList.RefreshValues(ConfigsTextList.ObjectList)
end
GuiLibrary.LoadSettings(shared.flashCustomConfig)
local Configs = {}
for i, v in pairs(GuiLibrary.Configs) do
    table.insert(Configs, i)
end
table.sort(Configs, function(a, b)
    return b == "default" and true or a:lower() < b:lower()
end)
ConfigsTextList.RefreshValues(Configs)
GuiLibrary.UpdateUI(GUIColorSlider.Hue, GUIColorSlider.Sat, GUIColorSlider.Value, true)
if not shared.flashSwitchServers then
    if BlatantModeToggle.Enabled then
        pcall(function()
            local frame = GuiLibrary.CreateNotification("Blatant Enabled", "Flash is now in Blatant Mode.", 5.5,
                "assets/WarningNotification.png")
            frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
        end)
    end
    GuiLibrary.LoadedAnimation(welcomeMessage.Enabled)
else
    shared.flashSwitchServers = nil
end
if shared.flashOpenGui then
    GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = true
    game:GetService("RunService"):SetRobloxGuiFocused(GuiLibrary.MainBlur.Size ~= 0)
    shared.flashOpenGui = nil
end
coroutine.resume(saveSettingsLoop)
