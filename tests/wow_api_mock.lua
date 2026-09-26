-- tests/wow_api_mock.lua: Mock implementation of World of Warcraft API environment for standalone CLI testing

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        print("[WoW Chat] " .. tostring(msg))
    end
}

_G.UIParent = {
    GetEffectiveScale = function() return 1.0 end
}

_G.RAID_CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER  = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE   = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE    = { r = 0.41, g = 0.80, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    MONK    = { r = 0.00, g = 1.00, b = 0.59 },
    DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER  = { r = 0.20, g = 0.58, b = 0.50 },
}

_G.SlashCmdList = {}
_G.C_AddOns = {
    IsAddOnLoaded = function(name) return false end,
    LoadAddOn = function(name) return true, nil end
}

_G.GetLocale = function() return "enUS" end
_G.GetTime = function() return 1000 end
_G.GetFramerate = function() return 120 end
_G.GetNetStats = function() return 0, 0, 15, 15 end
_G.GetMoney = function() return 5000000 end
_G.GetSpecialization = function() return 1 end
_G.GetSpecializationInfo = function(spec) return 70, "Protection", "Tank", "Interface\\Icons\\Spell_Holy_DevotionAura" end
_G.UnitClass = function(unit) return "Paladin", "PALADIN" end
_G.UnitHealth = function(unit) return 100000 end
_G.UnitHealthMax = function(unit) return 100000 end
_G.UnitPower = function(unit) return 100 end
_G.UnitPowerMax = function(unit) return 100 end
_G.UnitExists = function(unit) return true end
_G.UnitIsPlayer = function(unit) return true end
_G.UnitIsEnemy = function(player, unit) return false end
_G.UnitXP = function(unit) return 5000 end
_G.UnitXPMax = function(unit) return 10000 end
_G.RegisterUnitWatch = function(frame) end
_G.InCombatLockdown = function() return false end
_G.GetCursorPosition = function() return 500, 500 end

--- Mock Frame Factory
_G.CreateFrame = function(frameType, name, parent, template)
    local frame = {
        name = name,
        type = frameType,
        parent = parent,
        template = template,
        shown = false,
        scripts = {},
        attributes = {},
        points = {},
    }

    function frame:SetSize(w, h) self.w, self.h = w, h end
    function frame:GetWidth() return self.w or 100 end
    function frame:GetHeight() return self.h or 30 end
    function frame:SetPoint(point, relTo, relPoint, x, y)
        table.insert(self.points, { point = point, relTo = relTo, relPoint = relPoint, x = x, y = y })
    end
    function frame:GetPoint()
        local pt = self.points[#self.points]
        if pt then return pt.point, pt.relTo, pt.relPoint, pt.x, pt.y end
        return "CENTER", nil, "CENTER", 0, 0
    end
    function frame:ClearAllPoints() self.points = {} end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end
    function frame:SetParent(p) self.parent = p end
    function frame:SetBackdrop(b) self.backdrop = b end
    function frame:SetBackdropColor(...) end
    function frame:SetBackdropBorderColor(...) end
    function frame:SetFrameStrata(s) self.strata = s end
    function frame:SetClampedToScreen(c) end
    function frame:SetMovable(m) end
    function frame:EnableMouse(m) end
    function frame:RegisterForDrag(...) end
    function frame:RegisterForClicks(...) end
    function frame:RegisterEvent(...) end
    function frame:UnregisterEvent(...) end
    function frame:SetScript(handler, fn) self.scripts[handler] = fn end
    function frame:GetScript(handler) return self.scripts[handler] end
    function frame:SetAttribute(k, v) self.attributes[k] = v end

    function frame:CreateFontString(name, layer, fontObject)
        local fs = { text = "" }
        function fs:SetPoint(...) end
        function fs:SetText(t) self.text = t end
        function fs:GetText() return self.text end
        function fs:SetFont(...) end
        function fs:SetVertexColor(...) end
        return fs
    end

    function frame:CreateTexture(name, layer)
        local tex = {}
        function tex:SetAllPoints(...) end
        function tex:SetTexture(...) end
        function tex:SetColorTexture(...) end
        function tex:SetVertexColor(...) end
        return tex
    end

    function frame:SetStatusBarTexture(...) end
    function frame:SetStatusBarColor(...) end
    function frame:SetMinMaxValues(...) end
    function frame:SetValue(...) end

    return frame
end
