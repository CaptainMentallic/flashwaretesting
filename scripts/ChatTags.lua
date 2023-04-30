-- Client Sided
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oldChannelTabs = {}

local function onAddMessageToChannel(Self, MessageData)
    if MessageData.FromSpeaker and Players[MessageData.FromSpeaker] then
        local speaker = Players[MessageData.FromSpeaker]
        if speaker:IsInGroup(0x51BF20) then
            MessageData.ExtraData = {
                NameColor = speaker.Team == nil and Color3.new(0x0, 0x0, 0x0) or speaker.TeamColor.Color,
                Tags = {table.unpack(MessageData.ExtraData.Tags), {
                    TagColor = Color3.new(255, 255, 0),
                    TagText = "FLASH USER"
                }}
            }
        end
    end
    return oldChannelTabs[Self](Self, MessageData)
end

for _, v in pairs(getconnections(ReplicatedStorage.DefaultChatSystemChatEvents.OnNewMessage.OnClientEvent)) do
    local func = v.Function
    if func and #debug.getupvalues(func) > 0 then
        local upvalues = debug.getupvalues(func)
        if type(upvalues[1]) == "table" and getmetatable(upvalues[1]) and getmetatable(upvalues[1]).GetChannel then
            local oldGetChannel = getmetatable(upvalues[1]).GetChannel
            getmetatable(upvalues[1]).GetChannel = function(self, name)
                local tab = oldGetChannel(self, name)
                if tab and tab.AddMessageToChannel then
                    if not oldChannelTabs[tab] then
                        oldChannelTabs[tab] = tab.AddMessageToChannel
                        tab.AddMessageToChannel = onAddMessageToChannel
                    end
                end
                return tab
            end
        end
    end
end
