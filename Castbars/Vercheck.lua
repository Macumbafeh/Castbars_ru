
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local CreateFrame = CreateFrame

local myname = UnitName("player")
versionCB = GetAddOnMetadata("Castbars", "Version")

local spamt = 0
local timeneedtospam = 180
do
    local SendMessageWaitingCB
    local SendRecieveGroupSizeCB = 0
    function SendMessage_CB()
        if GetNumRaidMembers() > 1 then
            local _, instanceType = IsInInstance()
            if instanceType == "pvp" then
                SendAddonMessage("CBVC", versionCB, "BATTLEGROUND")
            else
                SendAddonMessage("CBVC", versionCB, "RAID")
            end
        elseif GetNumPartyMembers() > 0 then
            SendAddonMessage("CBVC", versionCB, "PARTY")
        elseif IsInGuild() then
            SendAddonMessage("CBVC", versionCB, "GUILD")
        end
        SendMessageWaitingCB = nil
    end

    local function SendRecieve_CB(_, event, prefix, message, _, sender)
        if event == "CHAT_MSG_ADDON" then
            -- print(argtime)
            if prefix ~= "CBVC" then return end
            if not sender or sender == myname then return end

            local ver = tonumber(versionCB)
            message = tonumber(message)

            local  timenow = time()
            if message and (message > ver) then
                if timenow - spamt >= timeneedtospam then
                    print("|cff1784d1".."RaidBrowser".."|r".." (".."|cffff0000"..ver.."|r"..") устарел. Вы можете загрузить последнюю версию (".."|cff00ff00"..message.."|r"..") из ".."|cffffcc00".."https://github.com/fxpw/RaidBrowser-ru-for-sirus".."|r")
                    -- spamt = time()
                    spamt = time()
                end
            end
        end


        if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            local numRaid = GetNumRaidMembers()
            local num = numRaid > 0 and numRaid or (GetNumPartyMembers() + 1)
            if num ~= SendRecieveGroupSizeCB then
                if num > 1 and num > SendRecieveGroupSizeCB then
                    if not SendMessageWaitingCB then
                        SendMessage_CB()
                        -- SendMessageWaitingBB = E:Delay(10,SendMessage_BB )
                    end
                end
                SendRecieveGroupSizeCB = num
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
                    if not SendMessageWaitingCB then
                        SendMessage_CB()
                        -- SendMessageWaitingBB = E:Delay(10, SendMessage_BB)
                    end

            end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", SendRecieve_CB)
end