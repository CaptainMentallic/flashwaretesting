local errorPopupShown = false
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or function() end
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or function() return 8 end
local baseDirectory = "flash/"

local betterisfile = function(file) local suc, res = pcall(function() return readfile(file) end) return suc and res ~= nil end

local serv = setmetatable({}, { __index = function(self, name) local pass, service = pcall(game.GetService, game, name) if pass then self[name] = service return service end end})
local cachedfiles = "flash/cachedfiles.txt"
if not betterisfile(cachedfiles) then
	if not isfolder("flash") then makefolder("flash") end
    writefile(cachedfiles, game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/cachedfiles.txt", true))
end

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

if betterisfile("flash/version.txt") then print("Old Downloaded Version: ".. readfile("flash/version.txt")) else print("Old Downloaded Version: 0") end
local newestVersion = getFromGithub("version.txt", true)
print("GitHub Version: "..newestVersion)
print("Current Downloaded Version: "..readfile("flash/version.txt"))
if isfolder("flash") then
    if (readfile("flash/version.txt") < newestVersion) then
        for i, v in pairs({"flash/Universal.lua", "flash/MainScript.lua", "flash/GuiLibrary.lua", "flash/scripts/ChatTags.lua"}) do
            if betterisfile(v) and readfile(cachedfiles):find(v) then
                delfile(v)
            end
        end
        if isfolder("flash/Games") then
            for i, v in pairs(listfiles("flash/Games")) do
                if betterisfile(v) and readfile(cachedfiles):find(v) then
                    delfile(v)
                end
            end
        end
        if isfolder("flash/Libraries") then
            for i, v in pairs(listfiles("flash/Libraries")) do
                if betterisfile(v) and readfile(cachedfiles):find(v) then
                    delfile(v)
                end
            end
        end
		if isfolder("flash/scripts") then
            for i, v in pairs(listfiles("flash/scripts")) do
                if betterisfile(v) and readfile(cachedfiles):find(v) then
                    delfile(v)
                end
            end
        end
    end
	writefile("flash/version.txt", newestVersion)
end

return LoadScript("MainScript.lua")
