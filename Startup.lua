local errorPopupShown = false
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or function() end
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or function() return 8 end

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
    if not isfile("flash/" .. scripturl) then
        local suc, res
        task.delay(15, function()
            if not res and not errorPopupShown then
                errorPopupShown = true
                displayErrorPopup("The connection to github is taking a while...")
            end
        end)
        suc, res = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/" .. scripturl, true)
        end)
        if not suc or res == "404: Not Found" then
            displayErrorPopup("Failed to connect to github : flash/" .. scripturl .. " : " .. res)
            error(res)
        end
        if scripturl:find(".lua") then
            res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.\n" .. res
        end
        writefile("flash/" .. scripturl, res)
    end
    return readfile("flash/" .. scripturl)
end

if isfolder("flash") then
    if ((not isfile("flash/version.txt")) or (readfile("flash/version.txt") < getFromGithub("version.txt"))) then
        for i, v in pairs({"flash/Universal.lua", "flash/MainScript.lua", "flash/GuiLibrary.lua"}) do
            if isfile(v) and readfile(v):find(
                "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.") then
                delfile(v)
            end
        end
        if isfolder("flash/CustomModules") then
            for i, v in pairs(listfiles("flash/CustomModules")) do
                if isfile(v) and readfile(v):find(
                    "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.") then
                    delfile(v)
                end
            end
        end
        if isfolder("flash/Libraries") then
            for i, v in pairs(listfiles("flash/Libraries")) do
                if isfile(v) and readfile(v):find(
                    "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.") then
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
