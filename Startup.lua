local errorPopupShown = false
local setidentity = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity or function() end
local getidentity = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity or function() return 8 end
local baseDirectory = "flash/"

local serv = setmetatable({}, { __index = function(self, name) local pass, service = pcall(game.GetService, game, name) if pass then self[name] = service return service end end})
local cachedfiles = "flash/cachedfiles.txt"
if not isfile(cachedfiles) then
    cachedfiles = game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/cachedfiles.txt", true)
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

local function getFromGithub(scripturl)
    local filepath = baseDirectory .. scripturl
	if not isfile(filepath) then
		local suc, res
		task.delay(15, function()
			if not res and not errorPopupShown then 
				errorPopupShown = true
				displayErrorPopup("The connection to GitHub is being slow, or there was an error with the script. \n Please wait a little or check logs")
			end
		end)
		suc, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/CaptainMentallic/flashwaretesting/main/"..scripturl, true) end)
		if not suc or res == "404: Not Found" then
			displayErrorPopup("Couldn't connect to github : flash/"..scripturl.." : "..res)
			error(res)
		end

        local cached = readfile(cachedfiles)
		if cached:find(".lua") then cached = scripturl.."\n"..cached end
        
        writefile("flash/cachedfiles.txt", cached)
		writefile(filepath, res)
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
