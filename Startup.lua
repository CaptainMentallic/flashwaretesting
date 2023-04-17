local errorPopupShown = false
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or function() end
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or function() return 8 end
local cachedfiles = "flash/cachedfiles.txt"

local function displayErrorPopup(text, func)
    local oldidentity = getidentity()
    setidentity(8)
    local ErrorPrompt = getrenv().require(game:GetService("CoreGui").RobloxGui.Modules.ErrorPrompt)
    local prompt = ErrorPrompt.new("Default")
    prompt._hideErrorCode = true
    local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    prompt:setErrorTitle("FlashWare")
    prompt:updateButtons({{
        Text = "OK",
        Callback = function()
            prompt:_close()
            if func then
                func()
            end
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
            local success, _ = pcall(wait, 15)
            if not isfile(filepath) and not warningShown then
                warningShown = true
                displayErrorPopup("The connection to GitHub is slow...")
            end
        end)
        local url = string.format("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/%s", scripturl)
        local success, response = pcall(http.RequestAsync, http, {
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

if isfolder("flash") then
    if ((not isfile("flash/version.txt")) or readfile("flash/version.txt") < getFromGithub("version.txt")) then
        for i, v in pairs({"flash/Universal.lua", "flash/MainScript.lua", "flash/GuiLibrary.lua"}) do
            if isfile(v) and readfile(cachedfiles):find(v) then
                delfile(v)
            end
        end
        if isfolder("flash/Games") then
            for i, v in pairs(listfiles("flash/Games")) do
                if isfile(v) and readfile(cachedfiles):find(v) then
                    delfile(v)
                end
            end
        end
        if isfolder("flash/Libraries") then
            for i, v in pairs(listfiles("flash/Libraries")) do
                if isfile(v) and readfile(cachedfiles):find(v) then
                    delfile(v)
                end
            end
        end
		writefile("flash/version.txt", getFromGithub("version.txt"))
    end
else
    makefolder("flash")
    writefile("flash/version.txt", getFromGithub("version.txt"))
end

return loadstring(getFromGithub("MainScript.lua"))()
