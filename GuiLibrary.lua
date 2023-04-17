if shared.FlashExecuted then
    local Version = readfile("flash/version.txt")
    local baseDirectory = "flash/"
    local universalRainbowValue = 0
    local getcustomasset = getsynasset or getcustomasset or function(location)
        return "rbxasset://" .. location
    end
    local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or
                            request or function()
    end
    local isfile = isfile or function(file)
        local suc, res = pcall(function()
            return readfile(file)
        end)
        return suc and res ~= nil
    end
    local loadedsuccessfully = false

    local GuiLibrary = {
        Settings = {},
        Configs = {
            Default = {
                Selected = true
            }
        },
        RainbowSpeed = 0.6,
        GUIKeybind = "RightShift",
        CurrentConfig = "Default",
        KeybindCaptured = false,
        PressedKeybindKey = "",
        ToggleNotifications = false,
        Notifications = false,
        ToggleTooltips = false,
        Objects = {
            SavedObjects = {

            }
        },
        Colors = {
            BACKGROUND_COLOR = Color3.fromRGB(62, 66, 71),
            ACTIVE_BACKGROUND_COLOR = Color3.fromRGB(76, 79, 87),
            DIVIDER_COLOR = Color3.fromRGB(101, 106, 116),
            LABEL_COLOR = Color3.fromRGB(255, 255, 255),
            DISABLED = Color3.fromRGB(114, 118, 124),
            THEMES = {
                RED = Color3.fromRGB(243, 64, 72),
                ORANGE = Color3.fromRGB(248, 152, 82),
                PURPLE = Color3.fromRGB(110, 139, 212),
                BLUE = Color3.fromRGB(37, 85, 198),
                CYAN = Color3.fromRGB(60, 227, 216)
            },
            CURRENT_THEME = GuiLibrary.Colors.THEMES.RED
        }
    }

    local inputService = game:GetService("UserInputService")
    local httpService = game:GetService("HttpService")
    local tweenService = game:GetService("TweenService")
    local guiService = game:GetService("GuiService")
    local textService = game:GetService("TextService")

    coroutine.resume(coroutine.create(function()
        repeat
            task.wait(0.01)
            universalRainbowValue = universalRainbowValue + 0.005 * GuiLibrary["RainbowSpeed"]
            if universalRainbowValue > 1 then
                universalRainbowValue = universalRainbowValue - 1
            end
        until not shared.FlashExecuted
    end))

    local capturedslider = nil
    local mainui = {
        ["Visible"] = true
    }

    local function randomString()
        local randomlength = math.random(10, 100)
        local array = {}

        for i = 1, randomlength do
            array[i] = string.char(math.random(32, 126))
        end

        return table.concat(array)
    end

    local function CalculateRelativePosition(GuiObject, location)
        local absPos = GuiObject.AbsolutePosition
        local absSize = GuiObject.AbsoluteSize

        local x = math.clamp((location.X - absPos.X), 0, absSize.X)
        local y = math.clamp((location.Y - absPos.Y), 0, absSize.Y)
        local xscale = (x / absSize.X)
        local x2 = math.clamp(x, 4, (absSize.X - 6))
        local xscale2 = (x2 / absSize.X)

        return x, y, xscale, (y / absSize.Y), xscale2
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = randomString()
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn = false
    gui.OnTopOfCoreBlur = true
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui.Parent = game:GetService("CoreGui")
    end

    GuiLibrary["MainGui"] = gui

    local function getFromGithub(scripturl)
        if not isfile("flash/" .. scripturl) then
            local suc, res
            task.delay(15, function()
                if not res and not errorPopupShown then
                    errorPopupShown = true
                    displayErrorPopup("The connection to github is slow...")
                end
            end)
            suc, res = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/" ..
                                        scripturl, true)
            end)
            if not suc or res == "404: Not Found" then
                displayErrorPopup("Failed to connect to github : flash/" .. scripturl .. " : " .. res)
                error(res)
            end
            if scripturl:find(".lua") then
                local cached = readfile(cachedfiles)
                res = scripturl .. "\n" .. cached .. "\n"
            end
            writefile("flash/" .. scripturl, res)
        end
        return readfile("flash/" .. scripturl)
    end

    local function downloadAsset(path)
        if not isfile(path) then
            task.spawn(function()
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
                repeat
                    task.wait()
                until isfile(path)
                textlabel:Destroy()
            end)
            local suc, req = pcall(function()
                return getFromGithub(path:gsub("flash/assets", "assets"))
            end)
            if suc and req then
                writefile(path, req)
            else
                return ""
            end
        end
        if not cachedAssets[path] then
            cachedAssets[path] = getcustomasset(path)
        end
        return cachedAssets[path]
    end

    GuiLibrary["UpdateHudEvent"] = Instance.new("BindableEvent")
    GuiLibrary["SelfDestructEvent"] = Instance.new("BindableEvent")
    GuiLibrary["LoadSettingsEvent"] = Instance.new("BindableEvent")

    local scaledgui = Instance.new("Frame")
    scaledgui.Name = "ScaledGui"
    scaledgui.Size = UDim2.new(1, 0, 1, 0)
    scaledgui.AnchorPoint = Vector2.new(0.5, 0.5)
    scaledgui.Position = UDim2.new(0.5, 0, 0.5, 0)
    scaledgui.BackgroundTransparency = 1
    scaledgui.Parent = gui

    local mainui = Instance.new("Frame")
    mainui.Name = "MainUI"
    mainui.Size = UDim2.new(1, 0, 1, 0)
    scaledgui.AnchorPoint = Vector2.new(0.5, 0.5)
    scaledgui.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainui.BackgroundTransparency = 1
    mainui.Visible = false
    mainui.Parent = scaledgui

    local searchbarmain = Instance.new("Frame")
    searchbarmain.Name = "SearchBar"
    searchbarmain.Size = UDim2.new(0.181, 0, 0.059, 0)
    searchbarmain.Position = UDim2.new(0.41, 0, 0.055, 0)
    searchbarmain.ClipsDescendants = false
    searchbarmain.ZIndex = 10
    searchbarmain.BackgroundColor3 = GuiLibrary.Colors.BACKGROUND_COLOR
    searchbarmain.Parent = mainui

    local searchbarcorner = Instance.new("UICorner")
    searchbarcorner.CornerRadius = UDim.new(0.19, 0)
    searchbarcorner.Parent = searchbarmain

    local searchbar = Instance.new("TextBox")
    searchbar.PlaceholderText = "Search Features"
    searchbar.Text = ""
    searchbar.ZIndex = 10
    searchbar.PlaceholderColor3 = Color3.fromRGB(195, 195, 195)
    searchbar.TextColor3 = Color3.fromRGB(121, 121, 121)
    searchbar.Size = UDim2.new(0.941, 0, 1, 0)
    searchbar.Font = Enum.Font.Arial
    searchbar.TextXAlignment = Enum.TextXAlignment.Left
    searchbar.TextSize = 12
    searchbar.TextScaled = true
    searchbar.Position = UDim2.new(0.059, 0, 0, 0)
    searchbar.BackgroundTransparency = 1
    searchbar.Parent = searchbarmain

    local searchbarTextConstrant = Instance.new("UITextSizeConstraint")
    searchbarTextConstrant.MaxTextSize = 12
    searchbarTextConstrant.MinTextSize = 1
    searchbarTextConstrant.Parent = searchbar

    local notificationwindow = Instance.new("Frame")
    notificationwindow.BackgroundTransparency = 1
    notificationwindow.Active = false
    notificationwindow.Size = UDim2.new(1, 0, 1, 0)
    notificationwindow.Parent = GuiLibrary["MainGui"]

    local vTextSize = textService:GetTextSize("v" .. Version, 25, Enum.Font.DenkOne, Vector2.new(999999, 999999))

    local hudgui = Instance.new("Frame")
    hudgui.Name = "HudGui"
    hudgui.Size = UDim2.new(1, 0, 1, 0)
    hudgui.BackgroundTransparency = 1
    hudgui.Visible = true
    hudgui.Parent = scaledgui

    GuiLibrary["MainBlur"] = {
        Size = 25
    }
    GuiLibrary["MainRescale"] = Instance.new("UIScale")
    GuiLibrary["MainRescale"].Parent = scaledgui

    local function dragGUI(gui)
        task.spawn(function()
            local dragging
            local dragInput
            local dragStart = Vector3.new(0, 0, 0)
            local startPos
            local function update(input)
                local delta = input.Position - dragStart
                local Position = UDim2.new(startPos.X.Scale,
                    startPos.X.Offset + (delta.X * (1 / GuiLibrary["MainRescale"].Scale)), startPos.Y.Scale,
                    startPos.Y.Offset + (delta.Y * (1 / GuiLibrary["MainRescale"].Scale)))
                tweenService:Create(gui, TweenInfo.new(.20), {
                    Position = Position
                }):Play()
            end
            gui.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType ==
                    Enum.UserInputType.Touch and dragging == false then
                    dragStart = input.Position
                    local delta = (dragStart - Vector3.new(gui.AbsolutePosition.X, gui.AbsolutePosition.Y, 0)) *
                                      (1 / GuiLibrary["MainRescale"].Scale)
                    if delta.Y <= 40 then
                        dragging = mainui.Visible
                        startPos = gui.Position

                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end)
                    end
                end
            end)
            gui.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType ==
                    Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)
            inputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end)
        end)
    end

    GuiLibrary.SaveSettings = function()
        if loadedsuccessfully then
            writefile(baseDirectory .. "Configs/" .. game.PlaceId .. ".FlashConfigs.txt", httpService:JSONEncode(GuiLibrary.Configs))
            local WindowTable = {}
            for i, v in pairs(GuiLibrary.Objects.SavedObjects) do
                if v.Type == "MainWindow" then
                    WindowTable[i] = {
                        ["Type"] = "MainWindow",
                        ["Visible"] = v.Object.Visible,
                        ["Position"] = v.Object.Position
                    }
                end
                if v.Type == "ControlFrame" then
                    WindowTable[i] = {
                        ["Type"] = "ControlFrame",
                        ["Name"] = v.Object.Name,
                        ["Visible"] = v.Object.Visible,
                        ["Position"] = v.Object.Position
                    }
                end
                if v.Type == "Tab" then
                    WindowTable[i] = {
                        ["Type"] = "Tab",
                        ["Name"] = v.Object.Name,
                        ["LayoutOrder"] = v.Object.LayoutOrder,
                        ["Visible"] = v.Object.Visible,
                        ["Position"] = v.Object.Position
                    }
                end
                if (v.Type == "ToggleButton") then
                    WindowTable[i] = {
                        ["Type"] = "ToggleButton",
                        ["Name"] = v.Object.Name,
                        ["LayoutOrder"] = v.Object.LayoutOrder,
                        ["Visible"] = v.Object.Visible,
                        ["Column"] = v.Object.Parent.Name,
                        ["ControlFrame"] = v.Object.Parent.Parent.Name,
                        ["Enabled"] = v["Controller"]["Enabled"]
                    }
                end
                if v.Type == "Slider" then
                    WindowTable[i] = {
                        ["Type"] = "Slider",
                        ["Name"] = v.Object.Name,
                        ["LayoutOrder"] = v.Object.LayoutOrder,
                        ["Visible"] = v.Object.Visible,
                        ["Column"] = v.Object.Parent.Name,
                        ["ControlFrame"] = v.Object.Parent.Parent.Name,
                        ["Value"] = v["Controller"]["Value"]
                    }
                end
                if v.Type == "Divider" then
                    WindowTable[i] = {
                        ["Type"] = "Slider",
                        ["Name"] = v.Object.Name,
                        ["LayoutOrder"] = v.Object.LayoutOrder,
                        ["Column"] = v.Object.Parent.Name,
                        ["ControlFrame"] = v.Object.Parent.Parent.Name
                    }
                end
                -- if v.Type == "Dropdown" then
                --     WindowTable[i] = {
                --         ["Type"] = "Dropdown",
                --         ["Value"] = v["controller"]["Value"]
                --     }
                -- end
            end
            WindowTable["GUIKeybind"] = {
                ["Type"] = "GUIKeybind",
                ["Value"] = GuiLibrary["GUIKeybind"]
            }
            writefile(baseDirectory .. "Configs/" .. GuiLibrary.CurrentConfig .. "." .. game.PlaceId .. ".FlashConfig.txt", httpService:JSONEncode(GuiLibrary.Settings))
            writefile(baseDirectory .. "Configs/" .. game.GameId .. "UISettings.FlashConfig.txt", httpService:JSONEncode(WindowTable))
        end
    end

    GuiLibrary.LoadSettings = function(customconfig)
        local success, result = pcall(function()
            return httpService:JSONDecode(readfile(baseDirectory .. "Configs/" .. game.PlaceId .. ".FlashConfigs.txt"))
        end)
        if success and type(result) == "table" then
            GuiLibrary.Configs = result
        end
        for i, v in pairs(GuiLibrary.Configs) do
            if v.Selected then
                GuiLibrary.CurrentConfig = i
            end
        end
        if customconfig then
            GuiLibrary.Configs[GuiLibrary.CurrentConfig]["Selected"] = false
            GuiLibrary.Configs[customconfig] = GuiLibrary.Configs[customconfig] or {
                ["Selected"] = true
            }
            GuiLibrary.CurrentConfig = customconfig
        end
        local success1, result1 = pcall(function()
            return httpService:JSONDecode(readfile(baseDirectory .. "Configs/" .. (game.GameId) .. "UISettings.FlashConfig.txt"))
        end)
        if success1 and type(result1) == "table" then
            for i, v in pairs(result1) do
                local obj = GuiLibrary.Objects[i]
                if obj then
                    if v.Type == "Window" then
                        obj.Object.Position = UDim2.new(v["Position"][1], v["Position"][2], v["Position"][3],
                            v["Position"][4])
                        obj.Object.Visible = v["Visible"]
                        if v["Expanded"] then
                            obj["controller"]["ExpandToggle"]()
                        end
                    end
                    if v.Type == "CustomWindow" then
                        obj.Object.Position = UDim2.new(v["Position"][1], v["Position"][2], v["Position"][3],
                            v["Position"][4])
                        obj.Object.Visible = v["Visible"]
                        if v["Pinned"] then
                            obj["controller"]["PinnedToggle"]()
                        end
                        obj["controller"]["CheckVis"]()
                    end
                    if v.Type == "ButtonMain" then
                        if obj["Type"] == "ToggleMain" then
                            obj["controller"]["ToggleFrame"](v["Enabled"], true)
                            if v["Keybind"] ~= "" then
                                obj["controller"]["Keybind"] = v["Keybind"]
                            end
                        else
                            if v["Enabled"] then
                                obj["controller"]["ToggleFrame"](false)
                                if v["Keybind"] ~= "" then
                                    obj["controller"]["SetKeybind"](v["Keybind"])
                                end
                            end
                        end
                    end
                    if v.Type == "DropdownMain" then
                        obj["controller"]["SetValue"](v["Value"])
                    end
                    if v.Type == "ColorSliderMain" then
                        local valcheck = v["Hue"] ~= nil
                        obj["controller"]["SetValue"](valcheck and v["Hue"] or v["Value"] or 0.44,
                            valcheck or v["Sat"] or 1, valcheck and v["Value"] or 1)
                        obj["controller"]["SetRainbow"](v["RainbowValue"])
                    end
                    if v.Type == "ColorSliderGUI" then
                        local valcheck = v["Hue"] ~= nil
                        obj["controller"]["SetValue"](valcheck and v["Hue"] and (v["Hue"] / 7) - 0.1 or v["Value"] or
                                                          0.44, valcheck or v["Sat"] or 1, valcheck and v["Value"] or 1)
                        obj["controller"]["SetRainbow"](v["RainbowValue"])
                    end
                    if v.Type == "SliderMain" then
                        obj["controller"]["SetValue"](v["Value"])
                    end
                    if v.Type == "TextBoxMain" then
                        obj["controller"]["SetValue"](v["Value"])
                    end
                end
                if v.Type == "GUIKeybind" then
                    GuiLibrary["GUIKeybind"] = v["Value"]
                end
            end
        end
        local success, result = pcall(function()
            return httpService:JSONDecode(readfile(baseDirectory .. "Configs/" ..
                                                       (GuiLibrary.CurrentConfig == "Default" and "" or
                                                           GuiLibrary.CurrentConfig) ..
                                                       game.PlaceId .. ".FlashConfig.txt"))
        end)
        if success and type(result) == "table" then
            GuiLibrary["LoadSettingsEvent"]:Fire(result)
            for i, v in pairs(result) do
                if v.Type == "Custom" and GuiLibrary.Settings[i] then
                    GuiLibrary.Settings[i] = v
                end
                local obj = GuiLibrary.Objects[i]
                if obj then
                    local starttick = tick()
                    if v.Type == "Dropdown" then
                        obj["controller"]["SetValue"](v["Value"])
                    end
                    if v.Type == "CustomWindow" then
                        obj.Object.Position = UDim2.new(v["Position"][1], v["Position"][2], v["Position"][3],
                            v["Position"][4])
                        obj.Object.Visible = v["Visible"]
                        if v["Pinned"] then
                            obj["controller"]["PinnedToggle"]()
                        end
                        obj["controller"]["CheckVis"]()
                    end
                    if v.Type == "Button" then
                        if obj["Type"] == "Toggle" then
                            obj["controller"]["ToggleFrame"](v["Enabled"], true)
                            if v["Keybind"] ~= "" then
                                obj["controller"]["Keybind"] = v["Keybind"]
                            end
                        elseif obj["Type"] == "TargetButton" then
                            obj["controller"]["ToggleFrame"](v["Enabled"], true)
                        else
                            if v["Enabled"] then
                                obj["controller"]["ToggleFrame"](false)
                                if v["Keybind"] ~= "" then
                                    obj["controller"]["SetKeybind"](v["Keybind"])
                                end
                            end
                        end
                    end
                    if v.Type == "NewToggle" then
                        obj["controller"]["ToggleFrame"](v["Enabled"], true)
                        if v["Keybind"] ~= "" then
                            obj["controller"]["Keybind"] = v["Keybind"]
                        end
                    end
                    if v.Type == "Slider" then
                        obj["controller"]["SetValue"](v["OldMax"] ~= obj["controller"]["Max"] and v["Value"] >
                                                          obj["controller"]["Max"] and obj["controller"]["Max"] or
                                                          (v["OldDefault"] ~= obj["controller"]["Default"] and
                                                              v["Value"] == v["OldDefault"] and
                                                              obj["controller"]["Default"] or v["Value"]))
                    end
                    if v.Type == "TextBox" then
                        obj["controller"]["SetValue"](v["Value"])
                    end
                    if v.Type == "TextList" then
                        obj["controller"]["RefreshValues"]((v["ObjectTable"] or {}))
                    end
                    if v.Type == "TextCircleList" then
                        obj["controller"]["RefreshValues"]((v["ObjectTable"] or {}), (v["ObjectTableEnabled"] or {}))
                    end
                    if v.Type == "TwoSlider" then
                        obj["controller"]["SetValue"](v["Value"] == obj["controller"]["Min"] and 0 or v["Value"])
                        obj["controller"]["SetValue2"](v["Value2"])
                        obj.Object.Slider.ButtonSlider.Position = UDim2.new(v["SliderPos1"], -8, 1, -9)
                        obj.Object.Slider.ButtonBarClipping.Position = UDim2.new(v["SliderPos2"], -8, 1, -9)
                        obj.Object.Slider.FillSlider.Size = UDim2.new(0, obj.Object.Slider.ButtonBarClipping
                            .AbsolutePosition.X - obj.Object.Slider.ButtonSlider.AbsolutePosition.X, 1, 0)
                        obj.Object.Slider.FillSlider.Position = UDim2.new(
                            obj.Object.Slider.ButtonSlider.Position.X.Scale, 0, 0, 0)
                        -- obj.Object.Slider.FillSlider.Size = UDim2.new((v["Value"] < obj["controller"]["Max"] and v["Value"] or obj["controller"]["Max"]) / obj["controller"]["Max"], 0, 1, 0)
                    end
                    if v.Type == "ColorSlider" then
                        v["Hue"] = v["Hue"] or 0.44
                        v["Sat"] = v["Sat"] or 1
                        v["Value"] = v["Value"] or 1
                        obj["controller"]["SetValue"](v["Hue"], v["Sat"], v["Value"])
                        obj["controller"]["SetRainbow"](v["RainbowValue"])
                        obj.Object.Slider.ButtonSlider.Position = UDim2.new(math.clamp(v["Hue"], 0.02, 0.95), -9, 0, -7)
                        pcall(function()
                            obj["Object2"].Slider.ButtonSlider.Position =
                                UDim2.new(math.clamp(v["Sat"], 0.02, 0.95), -9, 0, -7)
                            obj["Object3"].Slider.ButtonSlider.Position =
                                UDim2.new(math.clamp(v["Value"], 0.02, 0.95), -9, 0, -7)
                        end)
                    end
                end
            end
            for i, v in pairs(result) do
                local obj = GuiLibrary.Objects[i]
                if obj then
                    if v.Type == "OptionsButton" then
                        if v["Enabled"] then
                            GuiLibrary.Objects[i]["controller"]["ToggleFrame"](false)
                        end
                        if v["Keybind"] ~= "" then
                            GuiLibrary.Objects[i]["controller"]["SetKeybind"](v["Keybind"])
                        end
                    end
                end
            end
        end
        loadedsuccessfully = true
    end

    GuiLibrary["SwitchConfig"] = function(configname)
        GuiLibrary.Configs[GuiLibrary.CurrentConfig]["Selected"] = false
        GuiLibrary.Configs[configname]["Selected"] = true
        if (not isfile(baseDirectory .. "Configs/" .. (configname == "Default" and "" or configname) ..
                           game.PlaceId .. ".FlashConfig.txt")) then
            local realconfig = GuiLibrary.CurrentConfig
            GuiLibrary.CurrentConfig = configname
            GuiLibrary.SaveSettings()
            GuiLibrary.CurrentConfig = realconfig
        end
        local oldindependent = shared.flashIndependent
        GuiLibrary.SelfDestruct()
        if not oldindependent then
            shared.flashSwitchServers = true
            shared.flashOpenGui = (mainui.Visible)
            loadstring(getFromGithub("Startup.lua"))()
        end
    end

    GuiLibrary["CreateMainWindow"] = function()
        local windowcontroller = {}
        local settingsexithovercolor = Color3.fromRGB(20, 20, 20)

        local window = Instance.new("Frame")
        window.Name = "MainWindow"
        window.BackgroundColor3 = GuiLibrary.Colors.BACKGROUND_COLOR
        window.Size = UDim2.new(0.631, 0, 0.745, 0)
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Position = UDim2.new(0.5, 0, 0.5, 0)
        window.Parent = mainui

        local windowCorner = Instance.new("UICorner")
        windowCorner.CornerRadius = UDim.new(0.015, 0)
        windowCorner.Parent = window

        local LogoLabel = Instance.new("TextLabel")
        LogoLabel.Name = "LogoLabel"
        LogoLabel.BackgroundTransparency = 1
        LogoLabel.Font = Enum.Font.DenkOne
        LogoLabel.Text = "FlashWare"
        LogoLabel.Size = UDim2.new(0.2, 0, 0.074, 0)
        LogoLabel.Position = UDim2.new(0.01, 0, 0.034, 0)
        LogoLabel.TextColor3 = GuiLibrary.Colors.LABEL_COLOR
        LogoLabel.TextSize = 38
        LogoLabel.TextScaled = true
        LogoLabel.Parent = window

        local LogoLabelConstraint = Instance.new("UITextSizeConstraint")
        LogoLabelConstraint.MaxTextSize = 38
        LogoLabelConstraint.MinTextSize = 1
        LogoLabelConstraint.Parent = LogoLabel

        local GameLabel = Instance.new("TextLabel")
        GameLabel.Name = "GameLabel"
        GameLabel.BackgroundTransparency = 1
        GameLabel.Font = Enum.Font.DenkOne
        GameLabel.Text = shared.CurrentLoad
        GameLabel.Size = UDim2.new(0.2, 0, 0.074, 0)
        GameLabel.Position = UDim2.new(1.092, 0, 1.096, 0)
        GameLabel.TextColor3 = GuiLibrary.Colors.LABEL_COLOR
        GameLabel.TextSize = 38
        GameLabel.TextScaled = true
        GameLabel.ZIndex = 2
        GameLabel.Parent = window

        local GameLabelConstraint = Instance.new("UITextSizeConstraint")
        GameLabelConstraint.MaxTextSize = 38
        GameLabelConstraint.MinTextSize = 1
        GameLabelConstraint.Parent = GameLabel

        local GameLabelShadow = Instance.new("TextLabel")
        GameLabelShadow.Name = "GameLabelShadow"
        GameLabelShadow.BackgroundTransparency = 1
        GameLabelShadow.Font = Enum.Font.DenkOne
        GameLabelShadow.Text = shared.CurrentLoad
        GameLabelShadow.Size = UDim2.new(1, 0, 1, 0)
        GameLabelShadow.Position = UDim2.new(0.019, 0, 0.029, 0)
        GameLabelShadow.TextColor3 = Color3.fromRGB(157, 157, 157)
        GameLabelShadow.TextSize = 38
        GameLabelShadow.TextScaled = true
        GameLabelShadow.Parent = GameLabel

        local GameLabelShadowConstraint = Instance.new("UITextSizeConstraint")
        GameLabelShadowConstraint.MaxTextSize = 38
        GameLabelShadowConstraint.MinTextSize = 1
        GameLabelShadowConstraint.Parent = GameLabelShadow

        local vText = Instance.new("TextLabel")
        vText.Name = "Version"
        vText.Size = UDim2.new(0.2, 0, 0.074, 0)
        vText.Position = UDim2.new(0.009, 0, 0.1, 0)
        vText.Font = Enum.Font.DenkOne
        vText.TextColor3 = Color3.new(1, 1, 1)
        vText.Active = false
        vText.TextSize = 38
        vText.BackgroundTransparency = 1
        vText.Text = "v" .. Version
        vText.ZIndex = 2
        vText.TextScaled = true
        vText.Parent = window

        local VTextConstraint = Instance.new("UITextSizeConstraint")
        VTextConstraint.MaxTextSize = 38
        VTextConstraint.MinTextSize = 1
        VTextConstraint.Parent = vText

        local TabsFrame = Instance.new("ScrollingFrame")
        TabsFrame.Name = "Tabs"
        TabsFrame.Active = true
        TabsFrame.BackgroundColor3 = GuiLibrary.Colors.LABEL_COLOR
        TabsFrame.BackgroundTransparency = 1.000
        TabsFrame.Size = UDim2.new(0.191, 0, 0.766, 0)
        TabsFrame.Position = UDim2.new(0.026, 0, 0.187, 0)
        TabsFrame.CanvasSize = UDim2.new(0, 0, 1.3, 0)
        TabsFrame.ScrollBarThickness = 0
        TabsFrame.Parent = window

        local tabsUIGrid = Instance.new("UIGridLayout")
        tabsUIGrid.CellSize = UDim2.new(1.05, 0, 0.135, 0)
        tabsUIGrid.CellPadding = UDim2.new(0, 0, 0.01, 0)
        tabsUIGrid.SortOrder = Enum.SortOrder.LayoutOrder
        tabsUIGrid.Parent = TabsFrame

        local DefaultControlsFrame = Instance.new("Frame")
        DefaultControlsFrame.Name = "DefaultControlsFrame"
        DefaultControlsFrame.BackgroundColor3 = GuiLibrary.Colors.ACTIVE_BACKGROUND_COLOR
        DefaultControlsFrame.Size = UDim2.new(0.754, 0, 0.909, 0)
        DefaultControlsFrame.Position = UDim2.new(0.215, 0, 0.045, 0)

        local DefaultControlsFrameCorner = Instance.new("UICorner")
        DefaultControlsFrameCorner.CornerRadius = UDim.new(0.025, 0)
        DefaultControlsFrameCorner.Parent = DefaultControlsFrame

        local DefaultControlsColumn1 = Instance.new("ScrollingFrame")
        DefaultControlsColumn1.Name = "Column1"
        DefaultControlsColumn1.BackgroundTransparency = 1
        DefaultControlsColumn1.HorizontalAlignment = Enum.HorizontalAlignment.Center
        DefaultControlsColumn1.Position = UDim2.new(0.02, 0, 0.022, 0)
        DefaultControlsColumn1.Size = UDim2.new(0.312, 0, 0.979, 0)
        DefaultControlsColumn1.BorderSizePixel = 0
        DefaultControlsColumn1.ClipsDescendants = true
        DefaultControlsColumn1.CanvasSize = UDim2.new(0, 0, 1.3, 0)
        DefaultControlsColumn1.ScrollBarThickness = 0
        DefaultControlsColumn1.Parent = DefaultControlsFrame

        local Defaultcontrolslistlayout = Instance.new("UIListLayout")
        Defaultcontrolslistlayout.Padding = UDim.new(0.01, 0)
        Defaultcontrolslistlayout.Parent = DefaultControlsColumn1

        local DefaultControlsColumn2 = DefaultControlsColumn1:Clone()
        DefaultControlsColumn2.Name = "Column2"
        DefaultControlsColumn2.Position = UDim2.new(0.343, 0, 0.022, 0)
        DefaultControlsColumn2.Parent = DefaultControlsFrame

        local DefaultControlsColumn3 = DefaultControlsColumn1:Clone()
        DefaultControlsColumn3.Name = "Column3"
        DefaultControlsColumn3.Position = UDim2.new(0.67, 0, 0.022, 0)
        DefaultControlsColumn3.Parent = DefaultControlsFrame

        repeat 
            local oldValue = shared.CurrentLoad
            task.wait(0.5)
            if oldValue ~= shared.CurrentLoad then
                GameLabel.Text = shared.CurrentLoad
                GameLabelShadow.Text = shared.CurrentLoad
            end
        until not shared.FlashExecuted

        dragGUI(window)

        GuiLibrary.Objects["GUIWindow"] = {
            ["ControlFrames"] = {},
            ["MainWindow"] = window,
            ["Type"] = "Window",
            ["Controller"] = windowcontroller,
            ["SavedItems"] = {}
        }

        windowcontroller["CreateTab"] = function(args) -- Name Order Icon
            local tabcontroller = {}

            local frame = Instance.new("Frame")
            frame.Name = args["Name"]
            frame.BackgroundColor3 = GuiLibrary.Colors.BACKGROUND_COLOR
            frame.ZIndex = 2
            frame.LayoutOrder = args["Order"]
            frame.Parent = TabsFrame

            local framecorner = Instance.new("UICorner")
            framecorner.CornerRadius = UDim.new(0.15, 0)
            framecorner.Parent = frame

            local tabbutton = Instance.new("TextButton")
            tabbutton.Name = "Click"
            tabbutton.BackgroundTransparency = 1
            tabbutton.Size = UDim2.new(1, 0, 1, 0)
            tabbutton.Text = ""
            tabbutton.ZIndex = 3
            tabbutton.Parent = frame

            local tabimage = Instance.new("ImageLabel")
            tabimage.Name = args["Name"] .. "Icon"
            tabimage.BackgroundTransparency = 1
            tabimage.BackgroundColor3 = GuiLibrary.Colors.LABEL_COLOR
            tabimage.Size = UDim2.new(0.28, 0, 0.525, 0)
            tabimage.Position = UDim2.new(0.297, 0, 0.297, 0)
            tabimage.Image = downloadAsset(args["Icon"])
            tabimage.ZIndex = 2
            tabimage.Parent = frame

            local tablabel = Instance.new("TextLabel")
            tablabel.Name = args["Name"] .. "Label"
            tablabel.BackgroundTransparency = 1
            tablabel.BackgroundColor3 = GuiLibrary.Colors.LABEL_COLOR
            tablabel.Size = UDim2.new(0.94, 0, 0.262, 0)
            tablabel.Position = UDim2.new(-0.03, 0, 0.043, 0)
            tablabel.Font = Enum.Font.GothamBold
            tablabel.Text = args["Name"]
            tablabel.TextColor3 = GuiLibrary.Colors.LABEL_COLOR
            tablabel.TextSize = 18
            tablabel.TextScaled = true
            tablabel.TextWrapped = true
            tablabel.ZIndex = 2
            tablabel.Parent = frame

            local tablabelconstraint = Instance.new("UITextSizeConstraint")
            tablabelconstraint.MaxTextSize = 18
            tablabelconstraint.MinTextSize = 1
            tablabelconstraint.Parent = tablabel

            local newframe = DefaultControlsFrame:Clone()
            newframe.Name = args["Name"] .. "ControlsFrame"
            newframe.Parent = window
            GuiLibrary.Objects["GUIWindow"]["ControlFrames"][args["Name"] .. "ControlsFrame"] = newframe

            tabbutton.MouseButton1Click:Connect(function()
                for _, frame in pairs(GuiLibrary.Objects["GUIWindow"]["ControlFrames"]) do
                    frame.Visible = false
                    frame.BackgroundColor3 = GuiLibrary.Colors.BACKGROUND_COLOR
                end
                newframe.Visible = not newframe.Visible
                if newframe.Visible then
                    newframe.BackgroundColor3 = GuiLibrary.Colors.ACTIVE_BACKGROUND_COLOR
                end
            end)

            tabcontroller["CreateDivider"] = function(args) -- Column
                local column = newframe:FindFirstChild("Column" .. args["Column"])
                local amount = #column:GetChildren()

                local divider = Instance.new("Frame")
                divider.Name = "Divider" .. amount
                divider.Size = UDim2.new(0, 181, 0, 2)
                divider.LayoutOrder = amount
                divider.BackgroundColor3 = GuiLibrary.Colors.DIVIDER_COLOR
                divider.BorderSizePixel = 0
                divider.Parent = column
            end

            tabcontroller["CreateToggle"] = function(args) -- Column LabelText DefaultToggle | Returns function with the bool
                local togglecontroller = {}
                local column = newframe:FindFirstChild("Column" .. args["Column"])

                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = "ToggleFrame"
                ToggleFrame.Size = UDim2.new(0, 163, 0, 29)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Parent = column

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = ToggleButton
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(0.706, 0, 0.818, 0)
                Label.Position = UDim2.new(0.294, 0, 0.091, 0)
                Label.Font = Enum.Font.Arial
                Label.Text = args["LabelText"]
                Label.TextColor3 = GuiLibrary.Colors.LABEL_COLOR
                Label.TextSize = 21
                Label.TextWrapped = true
                Label.TextXAlignment = Enum.TextXAlignment.Left

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Name = "ToggleButton"
                ToggleButton.Parent = ToggleFrame
                ToggleButton.BackgroundColor3 = GuiLibrary.Colors.THEMES.CURRENT_THEME
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Text = ""
                ToggleButton.AutoButtonColor = false
                ToggleButton.Size = UDim2.new(0.221, 0, 0.758, 0)
                ToggleButton.Position = UDim2.new(0.011, 0, 0.121, 0)

                local ToggleButtonCorner = Instance.new("UICorner")
                ToggleButtonCorner.CornerRadius = UDim.new(0.5, 0)
                ToggleButtonCorner.Parent = ToggleButton

                local CircleFrame = Instance.new("Frame")
                CircleFrame.Parent = ToggleButton
                CircleFrame.BackgroundColor3 = GuiLibrary.Colors.LABEL_COLOR
                CircleFrame.BorderSizePixel = 0
                CircleFrame.Size = UDim2.new(0.5, 0, 0.82, 0)
                CircleFrame.Position = UDim2.new(0.45, 0, 0.09, 0)

                local CircleFrameCorner = Instance.new("UICorner")
                CircleFrameCorner.CornerRadius = UDim.new(1, 0)
                CircleFrameCorner.Parent = CircleFrame

                togglecontroller["Toggle"] = function(toggle)
                    togglecontroller["Enabled"] = toggle

                    if togglecontroller["Enabled"] then
                        CircleFrame:TweenPosition(UDim2.new(0.45, 0, 0.1, 0), Enum.EasingDirection.InOut,
                            Enum.EasingStyle.Linear, 0.1, true)
                        ToggleButton.BackgroundColor3 = GuiLibrary.Colors.THEMES.CURRENT_THEME
                    else
                        ToggleButton.BackgroundColor3 = GuiLibrary.Colors.DISABLED
                        CircleFrame:TweenPosition(UDim2.new(0.05, 0, 0.1, 0), Enum.EasingDirection.InOut,
                            Enum.EasingStyle.Linear, 0.1, true)
                    end

                    args["Function"](togglecontroller["Enabled"])
                end

                togglecontroller["Toggle"](args["DefaultToggle"])

                ToggleFrame.MouseButton1Click:Connect(function()
                    togglecontroller["Toggle"](not togglecontroller["Enabled"])
                end)
                return togglecontroller
            end

            tabcontroller["CreateSlider"] = function(args) -- DefaultValue Min Max | Returns function with the current slider value
                local slidercontroller = {}
                local column = newframe:FindFirstChild("Column" .. args["Column"])

                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = "SliderFrame"
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.BorderSizePixel = 0
                SliderFrame.LayoutOrder = 3
                SliderFrame.Size = UDim2.new(0, 153, 0, 33)
                SliderFrame.ZIndex = 0
                SliderFrame.Parent = column

                local Bar = Instance.new("Frame")
                Bar.Name = "Bar"
                Bar.BackgroundColor3 = Color3.fromRGB(64, 67, 72)
                Bar.Size = UDim2.new(1, 0, 0.259, 0)
                Bar.Position = UDim2.new(0, 0, 0.479, 0)
                Bar.Parent = SliderFrame

                local BarCorner = Instance.new("UICorner")
                BarCorner.CornerRadius = UDim.new(1, 0)
                BarCorner.Parent = Bar

                local Dragger = Instance.new("TextButton")
                Dragger.Name = "Dragger"
                Dragger.BackgroundColor3 = GuiLibrary.Colors.LABEL_COLOR
                Dragger.BorderSizePixel = 0
                Dragger.Size = UDim2.new(0.05, 0, 2, 0)
                Dragger.Position = UDim2.new(0.45, 0, -0.585, 0)
                Dragger.ZIndex = 2
                Dragger.AutoButtonColor = false
                Dragger.Text = ""
                Dragger.Parent = Bar

                local DraggerCorner = Instance.new("UICorner")
                DraggerCorner.CornerRadius = UDim.new(1, 0)
                DraggerCorner.Parent = Dragger

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Name = "Value"
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Size = UDim2.new(1.377, 0, 0.243, 0)
                ValueLabel.Position = UDim2.new(-0.2, 0, -0.5, 0)
                ValueLabel.Font = Enum.Font.ArialBold
                ValueLabel.Text = "0"
                ValueLabel.TextColor3 = GuiLibrary.Colors.LABEL_COLOR
                ValueLabel.TextSize = 10
                ValueLabel.Parent = Dragger

                local BarClipping = Instance.new("Frame")
                BarClipping.Name = "BarClipping"
                BarClipping.BackgroundColor3 = GuiLibrary.Colors.CURRENT_THEME
                BarClipping.Size = UDim2.new(0.5, 0, 1, 0)
                BarClipping.Position = UDim2.new(0, 0, 0, 0)
                BarClipping.Parent = Bar

                local ClippingCorner = Instance.new("UICorner")
                ClippingCorner.CornerRadius = UDim.new(1, 0)
                ClippingCorner.Parent = BarClipping

                slidercontroller["SetValue"] = function(value)
                    slidercontroller["Value"] = value
                    local valRange = args["Max"] - args["Min"]
                    local normalizedValue = (value - args["Min"]) / valRange
                    local clampedValue = math.clamp(normalizedValue, 0.02, 0.97)
                    BarClipping.Size = UDim2.new(clampedValue, 0, 1, 0)

                    ValueLabel.Text = slidercontroller["Value"] .. ".0 "

                    args["Function"](value)
                end

                slidercontroller["SetValue"](args["DefaultValue"])

                function updateSlider()
                    local x, y, xscale = CalculateRelativePosition(Bar, inputService:GetMouseLocation())
                    local diff = (args["Max"] - args["Min"])
                    local value = math.floor(args["Min"] + (diff * xscale))
                
                    slidercontroller["SetValue"](value)
                    ValueLabel.Text = tostring(slidercontroller["Value"])
                
                    local xscale2 = math.clamp(xscale, 0.02, 1)
                    BarClipping.Size = UDim2.new(xscale2, 0, 1, 0)
                    
                    local yDraggerPos = UDim.new(-0.585, 0)
                    local xDraggerPos = UDim.new((xscale2 - 0.05), 0)
                
                    Dragger.Position = UDim2.new(xDraggerPos, yDraggerPos)
                end

                Dragger.MouseButton1Down:Connect(function()
                    updateSlider()

                    local moved
                    local stopped
                    moved = inputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement then
                            updateSlider()
                        end
                    end)
                    stopped = inputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            moved:Disconnect()
                            stopped:Disconnect()
                        end
                    end)
                end)
                return slidercontroller
            end

            tabcontroller["CreateDropdown"] = function(args)
                local dropdownController = {}
                

                
                return dropdownController
            end
            return tabcontroller
        end
        return windowcontroller
    end

    -- work on later
    -- windowcontroller["CreateGUIBind"] = function()
    -- 	local amount2 = #children2:GetChildren()
    -- 	local frame = Instance.new("TextLabel")
    -- 	frame.Size = UDim2.new(0, 220, 0, 40)
    -- 	frame.BackgroundTransparency = 1
    -- 	frame.TextSize = 17
    -- 	frame.TextColor3 = Color3.fromRGB(151, 151, 151)
    -- 	frame.Font = Enum.Font.SourceSans
    -- 	frame.Text = "   Rebind GUI"
    -- 	frame.LayoutOrder = amount2
    -- 	frame.Name = "Rebind GUI"
    -- 	frame.TextXAlignment = Enum.TextXAlignment.Left
    -- 	frame.Parent = children2
    -- 	local bindbkg = Instance.new("TextButton")
    -- 	bindbkg.Text = ""
    -- 	bindbkg.AutoButtonColor = false
    -- 	bindbkg.Size = UDim2.new(0, 20, 0, 21)
    -- 	bindbkg.Position = UDim2.new(1, -50, 0, 10)
    -- 	bindbkg.BorderSizePixel = 0
    -- 	bindbkg.BackgroundColor3 = Color3.fromRGB(40, 41, 40)
    -- 	bindbkg.BackgroundTransparency = 0
    -- 	bindbkg.Visible = true
    -- 	bindbkg.Parent = frame
    -- 	local bindimg = Instance.new("ImageLabel")
    -- 	bindimg.Image = downloadAsset("flash/assets/KeybindIcon.png")
    -- 	bindimg.BackgroundTransparency = 1
    -- 	bindimg.ImageColor3 = Color3.fromRGB(225, 225, 225)
    -- 	bindimg.Size = UDim2.new(0, 12, 0, 12)
    -- 	bindimg.Position = UDim2.new(0.5, -6, 0, 5)
    -- 	bindimg.Active = false
    -- 	bindimg.Visible = (GuiLibrary["GUIKeybind"] == "")
    -- 	bindimg.Parent = bindbkg
    -- 	local bindtext = Instance.new("TextLabel")
    -- 	bindtext.Active = false
    -- 	bindtext.BackgroundTransparency = 1
    -- 	bindtext.TextSize = 16
    -- 	bindtext.Parent = bindbkg
    -- 	bindtext.Font = Enum.Font.SourceSans
    -- 	bindtext.Size = UDim2.new(1, 0, 1, 0)
    -- 	bindtext.TextColor3 = Color3.fromRGB(80, 80, 80)
    -- 	bindtext.Visible = (GuiLibrary["GUIKeybind"] ~= "")
    -- 	local bindValueLabel = Instance.new("ImageLabel")
    -- 	bindValueLabel.Size = UDim2.new(0, 154, 0, 41)
    -- 	bindValueLabel.Image = downloadAsset("flash/assets/BindBackground.png")
    -- 	bindValueLabel.BackgroundTransparency = 1
    -- 	bindValueLabel.ScaleType = Enum.ScaleType.Slice
    -- 	bindValueLabel.SliceCenter = Rect.new(0, 0, 140, 41)
    -- 	bindValueLabel.Visible = false
    -- 	bindValueLabel.Parent = frame
    -- 	local bindtext3 = Instance.new("TextLabel")
    -- 	bindtext3.Text = "  PRESS  KEY TO BIND"
    -- 	bindtext3.Size = UDim2.new(0, 150, 0, 33)
    -- 	bindtext3.Font = Enum.Font.SourceSans
    -- 	bindtext3.TextXAlignment = Enum.TextXAlignment.Left
    -- 	bindtext3.TextSize = 17
    -- 	bindtext3.TextColor3 = Color3.fromRGB(44, 44, 44)
    -- 	bindtext3.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    -- 	bindtext3.BorderSizePixel = 0
    -- 	bindtext3.Parent = bindValueLabel
    -- 	local bindround = Instance.new("UICorner")
    -- 	bindround.CornerRadius = UDim.new(0, 6)
    -- 	bindround.Parent = bindbkg
    -- 	bindbkg.MouseButton1Click:Connect(function()
    -- 		if GuiLibrary["KeybindCaptured"] == false then
    -- 			GuiLibrary["KeybindCaptured"] = true
    -- 			task.spawn(function()
    -- 				bindValueLabel.Visible = true
    -- 				repeat task.wait() until GuiLibrary["PressedKeybindKey"] ~= ""
    -- 				local key = GuiLibrary["PressedKeybindKey"]
    -- 				local textsize = textService:GetTextSize(key, 16, bindtext.Font, Vector2.new(99999, 99999))
    -- 				newsize = UDim2.new(0, 13 + textsize.X, 0, 21)
    -- 				GuiLibrary["GUIKeybind"] = key
    -- 				bindbkg.Visible = true
    -- 				bindbkg.Size = newsize
    -- 				bindbkg.Position = UDim2.new(1, -(10 + newsize.X.Offset), 0, 10)
    -- 				bindimg.Visible = false
    -- 				bindtext.Visible = true
    -- 				bindtext.Text = key
    -- 				GuiLibrary["PressedKeybindKey"] = ""
    -- 				GuiLibrary["KeybindCaptured"] = false
    -- 				bindValueLabel.Visible = false
    -- 			end)
    -- 		end
    -- 	end)
    -- 	bindbkg.MouseEnter:Connect(function() 
    -- 		bindimg.Image = downloadAsset("flash/assets/PencilIcon.png") 
    -- 		bindimg.Visible = true
    -- 		bindtext.Visible = false
    -- 	end)
    -- 	bindbkg.MouseLeave:Connect(function() 
    -- 		bindimg.Image = downloadAsset("flash/assets/KeybindIcon.png")
    -- 		if GuiLibrary["GUIKeybind"] ~= "" then
    -- 			bindimg.Visible = false
    -- 			bindtext.Visible = true
    -- 			bindbkg.Size = newsize
    -- 			bindbkg.Position = UDim2.new(1, -(10 + newsize.X.Offset), 0, 10)
    -- 		end
    -- 	end)
    -- 	if GuiLibrary["GUIKeybind"] ~= "" then
    -- 		bindtext.Text = GuiLibrary["GUIKeybind"]
    -- 		local textsize = textService:GetTextSize(GuiLibrary["GUIKeybind"], 16, bindtext.Font, Vector2.new(99999, 99999))
    -- 		newsize = UDim2.new(0, 13 + textsize.X, 0, 21)
    -- 		bindbkg.Size = newsize
    -- 		bindbkg.Position = UDim2.new(1, -(10 + newsize.X.Offset), 0, 10)
    -- 	end
    -- 	return {
    -- 		["Reload"] = function()
    -- 			if GuiLibrary["GUIKeybind"] ~= "" then
    -- 				bindtext.Text = GuiLibrary["GUIKeybind"]
    -- 				local textsize = textService:GetTextSize(GuiLibrary["GUIKeybind"], 16, bindtext.Font, Vector2.new(99999, 99999))
    -- 				newsize = UDim2.new(0, 13 + textsize.X, 0, 21)
    -- 				bindbkg.Size = newsize
    -- 				bindbkg.Position = UDim2.new(1, -(10 + newsize.X.Offset), 0, 10)
    -- 			end
    -- 		end
    -- 	}
    -- end

    local function bettertween(obj, newpos, dir, style, tim, override)
        task.spawn(function()
            local frame = Instance.new("Frame")
            frame.Visible = false
            frame.Position = obj.Position
            frame.Parent = GuiLibrary["MainGui"]
            frame:GetPropertyChangedSignal("Position"):Connect(function()
                obj.Position = UDim2.new(obj.Position.X.Scale, obj.Position.X.Offset, frame.Position.Y.Scale,
                    frame.Position.Y.Offset)
            end)
            pcall(function()
                frame:TweenPosition(newpos, dir, style, tim, override)
            end)
            frame.Parent = nil
            task.wait(tim)
            frame:Remove()
        end)
    end

    local function bettertween2(obj, newpos, dir, style, tim, override)
        task.spawn(function()
            local frame = Instance.new("Frame")
            frame.Visible = false
            frame.Position = obj.Position
            frame.Parent = GuiLibrary["MainGui"]
            frame:GetPropertyChangedSignal("Position"):Connect(function()
                obj.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, obj.Position.Y.Scale,
                    obj.Position.Y.Offset)
            end)
            pcall(function()
                frame:TweenPosition(newpos, dir, style, tim, override)
            end)
            frame.Parent = nil
            task.wait(tim)
            frame:Remove()
        end)
    end

    notificationwindow.ChildRemoved:Connect(function()
        for i, v in pairs(notificationwindow:GetChildren()) do
            bettertween(v, UDim2.new(1, v.Position.X.Offset, 1, -(150 + 80 * (i - 1))), Enum.EasingDirection.In,
                Enum.EasingStyle.Sine, 0.15, true)
        end
    end)

    local function removeTags(str)
        str = str:gsub("<br%s*/>", "\n")
        return (str:gsub("<[^<>]->", ""))
    end

    GuiLibrary["CreateNotification"] = function(top, bottom, duration, customicon)
        local size = math.max(textService:GetTextSize(removeTags(bottom), 13, Enum.Font.Gotham,
                                  Vector2.new(99999, 99999)).X + 60, 266)
        local offset = #notificationwindow:GetChildren()
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, size, 0, 75)
        frame.Position = UDim2.new(1, 0, 1, -(150 + 80 * offset))
        frame.BackgroundTransparency = 1
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BorderSizePixel = 0
        frame.Parent = notificationwindow
        frame.Visible = GuiLibrary["Notifications"]
        frame.ClipsDescendants = false
        local image = Instance.new("ImageLabel")
        image.SliceCenter = Rect.new(67, 59, 323, 120)
        image.Position = UDim2.new(0, -61, 0, -50)
        image.BackgroundTransparency = 1
        image.Name = "Frame"
        image.ScaleType = Enum.ScaleType.Slice
        image.Image = downloadAsset("flash/assets/NotificationBackground.png")
        image.Size = UDim2.new(1, 61, 0, 159)
        image.Parent = frame
        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 6)
        uicorner.Parent = frame
        local frame2 = Instance.new("ImageLabel")
        frame2.BackgroundColor3 = Color3.fromRGB(1, 1, 1)
        frame2.Name = "Frame"
        frame2:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
            frame2.ImageColor3 = frame2.BackgroundColor3
        end)
        frame2.BackgroundTransparency = 1
        frame2.SliceCenter = Rect.new(2, 0, 224, 2)
        frame2.Size = UDim2.new(1, -61, 0, 2)
        frame2.ScaleType = Enum.ScaleType.Slice
        frame2.Position = UDim2.new(0, 63, 1, -36)
        frame2.ZIndex = 2
        frame2.Image = downloadAsset("flash/assets/NotificationBar.png")
        frame2.BorderSizePixel = 0
        frame2.Parent = image
        local icon = Instance.new("ImageLabel")
        icon.Name = "IconLabel"
        icon.Image = downloadAsset(customicon and "flash/" .. customicon or "flash/assets/InfoNotification.png")
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(0, -6, 0, -6)
        icon.Size = UDim2.new(0, 60, 0, 60)
        icon.Parent = frame
        local icon2 = icon:Clone()
        icon2.ImageColor3 = Color3.new(0, 0, 0)
        icon2.ZIndex = -1
        icon2.Position = UDim2.new(0, 1, 0, 1)
        icon2.ImageTransparency = 0.5
        icon2.Parent = icon
        local textlabel1 = Instance.new("TextLabel")
        textlabel1.Font = Enum.Font.Gotham
        textlabel1.TextSize = 13
        textlabel1.RichText = true
        textlabel1.TextTransparency = 0.1
        textlabel1.TextColor3 = Color3.new(1, 1, 1)
        textlabel1.BackgroundTransparency = 1
        textlabel1.Position = UDim2.new(0, 46, 0, 18)
        textlabel1.TextXAlignment = Enum.TextXAlignment.Left
        textlabel1.TextYAlignment = Enum.TextYAlignment.Top
        textlabel1.Text = "<b>" .. (translations[top] ~= nil and translations[top] or top) .. "</b>"
        textlabel1.Parent = frame
        local textlabel2 = textlabel1:Clone()
        textlabel2.Position = UDim2.new(0, 46, 0, 44)
        textlabel2.Font = Enum.Font.Gotham
        textlabel2.TextTransparency = 0
        textlabel2.TextColor3 = Color3.new(0.5, 0.5, 0.5)
        textlabel2.RichText = true
        textlabel2.Text = bottom
        textlabel2.Parent = frame
        local textlabel3 = textlabel2:Clone()
        textlabel3.Position = UDim2.new(0, 1, 0, 1)
        textlabel3.TextTransparency = 0.5
        textlabel3.TextColor3 = Color3.new(0, 0, 0)
        textlabel3.ZIndex = -1
        textlabel3.Parent = textlabel2
        task.spawn(function()
            pcall(function()
                bettertween2(frame, UDim2.new(1, -(size - 4), 1, -(150 + 80 * offset)), Enum.EasingDirection.In,
                    Enum.EasingStyle.Sine, 0.15, true)
                task.wait(0.15)
                frame2:TweenSize(UDim2.new(0, 0, 0, 2), Enum.EasingDirection.In, Enum.EasingStyle.Linear, duration, true)
                task.wait(duration)
                bettertween2(frame, UDim2.new(1, 0, 1, frame.Position.Y.Offset), Enum.EasingDirection.In,
                    Enum.EasingStyle.Sine, 0.15, true)
                task.wait(0.15)
                frame:Remove()
            end)
        end)
        return frame
    end

    GuiLibrary["LoadedAnimation"] = function(enabled)
        if enabled then
            GuiLibrary["CreateNotification"]("Finished Loading",
                "Press " .. string.upper(GuiLibrary["GUIKeybind"]) .. " to open GUI", 5)
        end
    end

    local holdingalt = false
    local uninjected = false

    GuiLibrary["KeyInputHandler"] = inputService.InputBegan:Connect(function(input1)
        if inputService:GetFocusedTextBox() == nil then
            if input1.KeyCode == Enum.KeyCode[GuiLibrary["GUIKeybind"]] and GuiLibrary["KeybindCaptured"] == false then
                mainui.Visible = not mainui.Visible
                inputService.OverrideMouseIconBehavior = (mainui.Visible and Enum.OverrideMouseIconBehavior.ForceShow or
                                                             game:GetService("VRService").VREnabled and
                                                             Enum.OverrideMouseIconBehavior.ForceHide or
                                                             Enum.OverrideMouseIconBehavior.None)
                game:GetService("RunService"):SetRobloxGuiFocused(
                    mainui.Visible and GuiLibrary["MainBlur"].Size ~= 0 or guiService:GetErrorType() ~=
                        Enum.ConnectionError.OK)
                if OnlineConfigsBigFrame.Visible then
                    OnlineConfigsBigFrame.Visible = false
                end
            end
            if input1.KeyCode == Enum.KeyCode.RightAlt then
                holdingalt = true
            end
            if input1.KeyCode == Enum.KeyCode.Home and holdingalt and (not uninjected) then
                GuiLibrary["SelfDestruct"]()
                uninjected = true
            end
            if GuiLibrary["KeybindCaptured"] and input1.KeyCode ~= Enum.KeyCode.LeftShift then
                local hah = string.gsub(tostring(input1.KeyCode), "Enum.KeyCode.", "")
                GuiLibrary["PressedKeybindKey"] = (hah ~= "Unknown" and hah or "")
            end
            for modules, aGuiLibrary in pairs(GuiLibrary.Objects) do
                if (aGuiLibrary["Type"] == "OptionsButton" or aGuiLibrary["Type"] == "Button") and
                    (aGuiLibrary["controller"]["Keybind"] ~= nil and aGuiLibrary["controller"]["Keybind"] ~= "") and
                    GuiLibrary["KeybindCaptured"] == false then
                    if input1.KeyCode == Enum.KeyCode[aGuiLibrary["controller"]["Keybind"]] and
                        aGuiLibrary["controller"]["Keybind"] ~= GuiLibrary["GUIKeybind"] then
                        aGuiLibrary["controller"]["ToggleFrame"](false)
                        if GuiLibrary["ToggleNotifications"] then
                            GuiLibrary["CreateNotification"]("Module Toggled",
                                aGuiLibrary["controller"]["Name"] ..
                                    ' <font color="#FFFFFF">has been</font> <font color="' ..
                                    (aGuiLibrary["controller"]["Enabled"] and '#32CD32' or '#FF6464') .. '">' ..
                                    (aGuiLibrary["controller"]["Enabled"] and "Enabled" or "Disabled") ..
                                    '</font><font color="#FFFFFF">!</font>', 1)
                        end
                    end
                end
            end
            for confignametext, configtab in pairs(GuiLibrary.Configs) do
                if (configtab["Keybind"] ~= nil and configtab["Keybind"] ~= "") and GuiLibrary["KeybindCaptured"] ==
                    false and confignametext ~= GuiLibrary.CurrentConfig then
                    if input1.KeyCode == Enum.KeyCode[configtab["Keybind"]] then
                        GuiLibrary["SwitchConfig"](confignametext)
                    end
                end
            end
        end
    end)

    GuiLibrary["KeyInputHandler2"] = inputService.InputEnded:Connect(function(input1)
        if input1.KeyCode == Enum.KeyCode.RightAlt then
            holdingalt = false
        end
    end)

    searchbar:GetPropertyChangedSignal("Text"):Connect(function()
        searchbarchildren:ClearAllChildren()
        if searchbar.Text == "" then
            searchbarmain.Size = UDim2.new(0, 220, 0, 37)
        else
            local optionbuttons = {}
            for i, v in pairs(GuiLibrary.Objects) do
                if i:find("OptionsButton") and i:sub(1, searchbar.Text:len()):lower() == searchbar.Text:lower() then
                    local button = Instance.new("TextButton")
                    button.Name = v.Object.Name
                    button.AutoButtonColor = false
                    button.Active = true
                    button.Size = UDim2.new(1, 0, 0, 40)
                    button.BorderSizePixel = 0
                    button.Position = UDim2.new(0, 0, 0, 40 * #optionbuttons)
                    button.ZIndex = 10
                    button.BackgroundColor3 = v.Object.BackgroundColor3
                    button.Text = ""
                    button.LayoutOrder = amount
                    button.Parent = searchbarchildren
                    v.Object:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                        button.BackgroundColor3 = v.Object.BackgroundColor3
                    end)
                    local buttonactiveborder = Instance.new("Frame")
                    buttonactiveborder.BackgroundTransparency = 0.75
                    buttonactiveborder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    buttonactiveborder.BorderSizePixel = 0
                    buttonactiveborder.Size = UDim2.new(1, 0, 0, 1)
                    buttonactiveborder.Position = UDim2.new(0, 0, 1, -1)
                    buttonactiveborder.ZIndex = 10
                    buttonactiveborder.Visible = false
                    buttonactiveborder.Parent = button
                    local button2 = Instance.new("ImageButton")
                    button2.BackgroundTransparency = 1
                    button2.Size = UDim2.new(0, 10, 0, 20)
                    button2.Position = UDim2.new(1, -24, 0, 10)
                    button2.Name = "OptionsButton"
                    button2.ZIndex = 10
                    button2.Image = v.Object.OptionsButton.Image
                    button2.Parent = button
                    v.Object.OptionsButton:GetPropertyChangedSignal("Image"):Connect(function()
                        button2.Image = v.Object.OptionsButton.Image
                    end)
                    local buttontext = Instance.new("TextLabel")
                    buttontext.BackgroundTransparency = 1
                    buttontext.Name = "ButtonText"
                    buttontext.Text = (translations[v.Object.Name:gsub("Button", "")] ~= nil and
                                          translations[v.Object.Name:gsub("Button", "")] or
                                          v.Object.Name:gsub("Button", ""))
                    buttontext.Size = UDim2.new(0, 118, 0, 39)
                    buttontext.Active = false
                    buttontext.ZIndex = 10
                    buttontext.TextColor3 = v.Object.ButtonText.TextColor3
                    v.Object.ButtonText:GetPropertyChangedSignal("TextColor3"):Connect(function()
                        buttontext.TextColor3 = v.Object.ButtonText.TextColor3
                    end)
                    buttontext.TextSize = 17
                    buttontext.Font = Enum.Font.SourceSans
                    buttontext.TextXAlignment = Enum.TextXAlignment.Left
                    buttontext.Position = UDim2.new(0, 12, 0, 0)
                    buttontext.Parent = button
                    button.MouseButton1Click:Connect(function()
                        v["controller"]["ToggleFrame"](false)
                    end)
                    table.insert(optionbuttons, v)
                end
            end
            searchbarmain.Size = UDim2.new(0, 220, 0, 39 + (40 * #optionbuttons))
        end
    end)
    GuiLibrary["MainRescale"]:GetPropertyChangedSignal("Scale"):Connect(function()
        searchbarmain.Position = UDim2.new(0.5 / GuiLibrary["MainRescale"].Scale, -110, 0, -23)
    end)

    return GuiLibrary
end
