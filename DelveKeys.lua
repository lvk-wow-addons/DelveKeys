DelveKeys = {
    quests = {
        84736,
        84737,
        84738,
        84739
    }
}

DelveKeysDB = {}

function DelveKeys:GetNumberOfKeys()
    local currency = C_CurrencyInfo.GetCurrencyInfo(3028)
    return currency.quantity or 0
end

function DelveKeys:GetKeysObtainedThisReset()
    local count = 0
    for i = 1, #DelveKeys.quests do
        if C_QuestLog.IsQuestFlaggedCompleted(DelveKeys.quests[i]) then
            count = count + 1
        end
    end
    return count
end

function DelveKeys:GetNumberOfObtainableKeys()
    return #DelveKeys.quests
end

function DelveKeys:WeeklyReset()
    for k, v in pairs(DelveKeysDB.characters) do
        v.obtained = 0
    end
end

function DelveKeys:GetCharacterKey()
    return UnitName("player") .. "@" .. GetRealmName()
end

function DelveKeys:UpdateState()
    if not DelveKeysDB.version then
        LVK:Print("|y|DelveKeys|<|: Initializing settings")
        DelveKeysDB = {
            version = 1,
            characters = { },
        }
    end
end

function DelveKeys:GetCurrentCharacterState()
    return {
        name = UnitName("player"),
        realm = GetRealmName(),
        keys = DelveKeys:GetNumberOfKeys(),
        obtained = DelveKeys:GetKeysObtainedThisReset(),
        obtainable = DelveKeys:GetNumberOfObtainableKeys()
    }
end

function DelveKeys:CheckAndUpdate()
    if UnitLevel("player") < 80 then
        return
    end

    local key = DelveKeys:GetCharacterKey()
    local state = DelveKeysDB.characters[key]
    if state then
        if DelveKeys:GetKeysObtainedThisReset() < state.obtained then
            LVK:Print("|y|DelveKeys|<|: Weekly reset detected, resetting obtainable keys to 0 for all characters")
            DelveKeys:WeeklyReset()
        end
    end

    DelveKeysDB.characters[key] = DelveKeys:GetCurrentCharacterState()
end

function DelveKeys:Report(filter)
    local first = true
    local all = filter == "all"
    for k, v in pairs(DelveKeysDB.characters) do
        local hasKeys = v.keys > 0 or v.obtained < v.obtainable
        local include = false
        if filter == "player" then
            include = UnitName("player") == k
        elseif all or hasKeys then
            include = true
        end
        if include then
            if first then
                LVK:Print("|y|Delve Keys Report|<|:")
                first = false
            end

            local indent = "   "
            if UnitName("player") == v.name and GetRealmName() == v.realm then
                indent = LVK:Colorize("|r|>|<| ")
            end

            local s = LVK:Colorize("%s|y|%s|<|", indent, v.name)
            if GetRealmName() == v.realm then
                s = s .. LVK:Colorize(" |g|@%s|<|:", v.realm)
            else
                s = s .. LVK:Colorize(" |r|@%s|<|:", v.realm)
            end
            s = s .. LVK:Colorize(" |y|%d|<|", v.keys)
            if v.obtained < v.obtainable then
                s = s .. LVK:Colorize(" + |g|%d|<|", v.obtainable - v.obtained)
            end

            print(s)
        end
    end
end

function DelveKeys:Slash_Report(all)
    if type(all) == "table" then
        all = all[1]
    end
    DelveKeys:Report(all)
end

function DelveKeys:Slash_Status()
    DelveKeys:Report("player")
end

local frame = LVK:EventHandler()
frame.RegisterEvent("ADDON_LOADED", function(addon, ...)
    if addon == "DelveKeys" then
        frame.UnregisterEvent("ADDON_LOADED")
        LVK:AnnounceAddon("DelveKeys")

        DelveKeys:UpdateState()
    end
end)

frame.RegisterEvent("PET_JOURNAL_LIST_UPDATE", function(...)
    frame.UnregisterEvent("PET_JOURNAL_LIST_UPDATE")

    C_Timer.After(2, function()
        DelveKeys:CheckAndUpdate()
        DelveKeys:Report("player")

        frame.RegisterEvent({ "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "CHAT_MSG_CURRENCY", "LOOT_CLOSED", "CRITERIA_UPDATE", "CURRENCY_DISPLAY_UPDATE", "SHOW_LOOT_TOAST", "CHAT_MSG_SYSTEM" }, function(...)
            DelveKeys:CheckAndUpdate()
        end)
    end)
end)

SLASH_DELVEKEYS1 = "/dk"
SLASH_DELVEKEYS2 = "/delvekeys"
SlashCmdList["DELVEKEYS"] = function(msg)
    LVK:ExecuteSlash(msg, DelveKeys)
end