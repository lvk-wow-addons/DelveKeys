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

function DelveKeys:Report(all)
    local first = true
    for k, v in pairs(DelveKeysDB.characters) do
        if v.keys > 0 or v.obtained < v.obtainable or all then
            if first then
                LVK:Print("|y|Delve Keys Report|<|:")
                first = false
            end

            if GetRealmName() == v.realm then
                LVK:Print("   |y|%s |g|@%s|<|:", v.name, v.realm)
            else
                LVK:Print("   |y|%s |r|@%s|<|:", v.name, v.realm)
            end
            LVK:Print("      |y|Restored Coffer Key%s|<|: |g|%d|<|", v.keys == 1 and "" or "s", v.keys)
            if v.obtained < v.obtainable then
                LVK:Print("      |y|Obtained Keys|<|: |g|%d|<| / |g|%d|<|", v.obtained, v.obtainable)
            else
                LVK:Print("      |y|Obtained Keys|<|: |r|%d|<| / |g|%d|<|", v.obtained, v.obtainable)
            end

            local left = v.keys + (v.obtainable - v.obtained)
            if left > 0 then
                LVK:Print("      |y|Key%s left to run|<|: |g|%d|<|", left == 1 and "" or "s", left)
            end
        end
    end
end

function DelveKeys:Slash_Report(all)
    if type(all) == "table" then
        all = all[1]
    end
    DelveKeys:Report(all == "all")
end

local frame = LVK:EventHandler()
frame.RegisterEvent("ADDON_LOADED", function(addon, ...)
    if addon == "DelveKeys" then
        frame.UnregisterEvent("ADDON_LOADED")
        LVK:AnnounceAddon("DelveKeys")

        DelveKeys:UpdateState()
        DelveKeys:CheckAndUpdate()
    end
end)

SLASH_DELVEKEYS1 = "/dk"
SLASH_DELVEKEYS2 = "/delvekeys"
SlashCmdList["DELVEKEYS"] = function(msg)
    LVK:ExecuteSlash(msg, DelveKeys)
end