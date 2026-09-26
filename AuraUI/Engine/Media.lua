-- Engine/Media.lua: Statusbar textures, fonts & border style registry
local addonName, addonTable = ...

local Media = {}
addonTable.engine.Media = Media

-- Built-in texture definitions (falling back to standard WoW client assets)
Media.textures = {
    Flat = "Interface\\TargetingFrame\\UI-StatusBar",
    Glossy = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    Smooth = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
    Glass = "Interface\\Buttons\\WHITE8X8",
}

-- Built-in font definitions
Media.fonts = {
    Default = "Fonts\\FRIZQT__.TTF",
    Number = "Fonts\\ARIALN.TTF",
    Header = "Fonts\\MORPHEUS.TTF",
}

--- Retrieves a texture path by key or fallback.
--- @param name string
--- @return string
function Media:GetTexture(name)
    return self.textures[name] or self.textures.Flat
end

--- Retrieves a font path by key or fallback.
--- @param name string
--- @return string
function Media:GetFont(name)
    return self.fonts[name] or self.fonts.Default
end

--- Applies status bar texture and font styling to a given status bar element.
--- @param statusBar StatusBar
--- @param textureName string
--- @param fontName string
--- @param fontSize number
function Media:StyleStatusBar(statusBar, textureName, fontName, fontSize)
    if not statusBar then return end

    local tex = self:GetTexture(textureName)
    statusBar:SetStatusBarTexture(tex)

    if statusBar.Text then
        local fontPath = self:GetFont(fontName)
        statusBar.Text:SetFont(fontPath, fontSize or 12, "OUTLINE")
    end
end
