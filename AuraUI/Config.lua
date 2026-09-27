-- Config.lua: Database schemas & default profile values for all modules
local addonName, addonTable = ...

--- Table deep copy helper function.
--- @param orig table
--- @return table copy
function addonTable:CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[addonTable:CopyTable(orig_key)] = addonTable:CopyTable(orig_value)
        end
        setmetatable(copy, addonTable:CopyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Complete default profile schema with configurations for every module
addonTable.defaultProfile = {
    layout = {
        PlayerFrame      = { point = "BOTTOM", relPoint = "BOTTOM", x = -240, y = 260 },
        TargetFrame      = { point = "BOTTOM", relPoint = "BOTTOM", x = 240, y = 260 },
        FocusFrame       = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 250, y = 350 },
        PetFrame         = { point = "BOTTOM", relPoint = "BOTTOM", x = -400, y = 260 },
        RaidFrames       = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 20, y = -140 },
        Minimap          = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -20, y = -20 },
        ActionBar1       = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 40 },
        ActionBar2       = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 82 },
        Cooldowns        = { point = "CENTER", relPoint = "CENTER", x = 0, y = -100 },
        ResourceBars     = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 310 },
        BuffReminders    = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 20, y = -20 },
        MythicPlus       = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 200, y = -20 },
        SkyridingHUD     = { point = "CENTER", relPoint = "CENTER", x = 0, y = -160 },
        DamageMeter      = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -20, y = 40 },
        QuestTracker     = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -20, y = -240 },
        DataBars         = { point = "TOP", relPoint = "TOP", x = 0, y = -5 },
        SpellQueue       = { point = "CENTER", relPoint = "CENTER", x = 0, y = -120 },
        ThreatMeter      = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 200, y = -200 },
        DebuffTracker    = { point = "CENTER", relPoint = "CENTER", x = 0, y = -200 },
        LootAnnounce     = { point = "CENTER", relPoint = "CENTER", x = 300, y = 0 },
        MapNotes         = { point = "CENTER", relPoint = "CENTER", x = 100, y = 0 },
        GuildNotes       = { point = "CENTER", relPoint = "CENTER", x = -100, y = 0 },
        AutoMarker       = { point = "CENTER", relPoint = "CENTER", x = 0, y = -260 },
        LootCouncil      = { point = "CENTER", relPoint = "CENTER", x = 0, y = 50 },
    },
    actionBars = {
        buttonScale = 1.0,
        buttonPadding = 4,
        showKeybinds = true,
        showMacroNames = false,
        hideMicroMenu = false,
    },
    unitFrames = {
        texture = "Flat",
        font = "Default",
        fontSize = 12,
        playerWidth = 220,
        playerHeight = 38,
        targetWidth = 220,
        targetHeight = 38,
        showPortraits = true,
        smoothBars = true,
    },
    nameplates = {
        enabled = true,
        width = 140,
        height = 14,
        healthTexture = "Flat",
        showCastBars = true,
        classColorEnemies = true,
        targetGlow = true,
    },
    raidFrames = {
        enabled = true,
        width = 75,
        height = 42,
        showRoleIcons = true,
        showPower = false,
        groupBy = "GROUP", -- "GROUP" or "CLASS"
    },
    cooldowns = {
        enabled = true,
        iconSize = 36,
        showAudioAlerts = true,
        fontSize = 14,
    },
    resourceBars = {
        enabled = true,
        height = 14,
        width = 220,
        showNumeric = true,
    },
    buffReminders = {
        enabled = true,
        reminderIcons = true,
        checkFlask = true,
        checkFood = true,
        checkWeaponEnchants = true,
    },
    skinning = {
        enabled = true,
        skinTooltips = true,
        skinPopups = true,
        skinWindows = true,
    },
    cursorEffects = {
        enabled = true,
        trailType = "Glow", -- "Glow", "Circle", "Star"
        trailColor = { r = 0, g = 0.9, b = 1 },
    },
    qualityOfLife = {
        autoSellJunk = true,
        autoRepair = true,
        useGuildBankForRepair = true,
        fastLoot = true,
        skipDialogs = false,
    },
    mythicPlus = {
        enabled = true,
        showDeaths = true,
        showTimer = true,
        showAffixes = true,
    },
    skyridingHUD = {
        enabled = true,
        showSpeedometer = true,
        showVigor = true,
    },
    minimap = {
        style = "Square",
        size = 180,
        showDatatexts = true,
    },
    friendsList = {
        enabled = true,
        classColors = true,
        showZone = true,
    },
    chat = {
        enabled = true,
        skinChat = true,
        shortChannelNames = true,
        urlLinks = true,
        timestamps = true,
    },
    questTracker = {
        enabled = true,
        autoCollapseInDungeons = true,
        skinTracker = true,
    },
    damageMeter = {
        enabled = true,
        maxBars = 6,
        showThreat = true,
    },
    bags = {
        enabled = true,
        combinedBags = true,
        showQualityBorders = true,
        iconSize = 34,
    },
    dataBars = {
        enabled = true,
        showXP = true,
        showReputation = true,
        showHonor = true,
    },
    partyMode = {
        enabled = true,
        levelUpCelebration = true,
        dungeonCompleteAnnounce = true,
    },
    uiUtilities = {
        showItemLevelOnCharacter = true,
        raidMarkerBar = true,
        fastCombatText = true,
    },
    spellQueue = {
        enabled = true,
    },
    threatMeter = {
        enabled = true,
        threshold = 90,
    },
    debuffTracker = {
        enabled = true,
        warnThreshold = 3.0,
    },
    lootAnnounce = {
        enabled = true,
        announceInGroup = true,
    },
    procEffects = {
        enabled = true,
        intensity = "Full",
        soundOn = true,
    },
    mapNotes = {
        enabled = true,
    },
    guildNotes = {
        enabled = true,
    },
    autoMarker = {
        enabled = true,
        autoMark = true,
    },
    lootCouncil = {
        enabled = true,
    },
    soundPackCustomizer = {
        activePack = "Classic",
    },
    style = "Flat",
}

-- Root Global Database Schema
local DEFAULT_GLOBAL = {
    version = "1.0.0",
    debugMode = false,
    useSpecProfiles = true,
    profiles = {
        Default = addonTable:CopyTable(addonTable.defaultProfile),
    }
}

--- Initializes global and character databases.
function addonTable:InitDatabase()
    if type(AuraUIDB) ~= "table" then
        AuraUIDB = {}
    end

    if not AuraUIDB.version then
        AuraUIDB.version = DEFAULT_GLOBAL.version
    end

    if AuraUIDB.debugMode == nil then
        AuraUIDB.debugMode = DEFAULT_GLOBAL.debugMode
    end

    if AuraUIDB.useSpecProfiles == nil then
        AuraUIDB.useSpecProfiles = DEFAULT_GLOBAL.useSpecProfiles
    end

    if not AuraUIDB.profiles then
        AuraUIDB.profiles = {}
        AuraUIDB.profiles["Default"] = addonTable:CopyTable(addonTable.defaultProfile)
    end

    addonTable.db = {
        global = AuraUIDB,
    }
end

