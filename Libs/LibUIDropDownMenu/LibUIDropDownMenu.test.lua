dofile("setupTests.lua")
dofile("Localization/l10n.lua")
dofile("Modules/QuestieMenu/QuestieTraceMenu.lua")

local SOURCE = "Libs/LibUIDropDownMenu/LibUIDropDownMenu.lua"

local function makeTexture(env, name)
    local texture = {
        color = {1, 1, 1, 1},
        shown = true,
    }
    function texture:SetVertexColor(r, g, b, a)
        self.color = {r, g, b, a}
    end
    function texture:GetVertexColor()
        return unpack(self.color)
    end
    function texture:SetShown(shown) self.shown = shown end
    function texture:Show() self.shown = true end
    function texture:Hide() self.shown = false end
    function texture:IsShown() return self.shown end
    function texture:SetTexture() end
    function texture:SetTexCoord() end
    function texture:SetSize() end
    function texture:SetWidth() end
    function texture:SetHeight() end
    function texture:GetWidth() return 0 end
    function texture:SetPoint() end
    function texture:SetAllPoints() end
    function texture:SetBlendMode() end
    function texture:SetDesaturated() end
    function texture:SetAlpha() end
    function texture:SetScript() end
    if name then env[name] = texture end
    return texture
end

local function makeFontString(env, name)
    local fontString = {
        text = "",
    }
    function fontString:SetText(text) self.text = text end
    function fontString:GetText() return self.text end
    function fontString:GetWidth() return 0 end
    function fontString:GetFont() return nil, 10, nil end
    function fontString:SetPoint() end
    function fontString:ClearAllPoints() end
    function fontString:SetFontObject() end
    function fontString:SetWordWrap() end
    function fontString:SetJustifyH() end
    function fontString:SetSize() end
    if name then env[name] = fontString end
    return fontString
end

local function makeFrame(env, frameType, name, parent)
    local frame = {
        frameType = frameType,
        name = name,
        parent = parent,
        shown = true,
        enabled = true,
        attributes = {},
        scripts = {},
        numButtons = 0,
    }
    function frame:GetName() return self.name end
    function frame:GetParent() return self.parent end
    function frame:GetFrameLevel() return 0 end
    function frame:SetParent(value) self.parent = value end
    function frame:SetScript(script, callback) self.scripts[script] = callback end
    function frame:GetScript(script) return self.scripts[script] end
    function frame:SetAttribute(attribute, value)
        self.attributes[attribute] = value
        if self.scripts.OnAttributeChanged then
            self.scripts.OnAttributeChanged(self, attribute, value)
        end
    end
    function frame:GetAttribute(attribute) return self.attributes[attribute] end
    function frame:SetID(id) self.id = id end
    function frame:GetID() return self.id end
    function frame:SetWidth(width) self.width = width end
    function frame:SetHeight(height) self.height = height end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:GetWidth() return self.width or 0 end
    function frame:GetHeight() return self.height or 0 end
    function frame:SetFrameLevel() end
    function frame:SetFrameStrata() end
    function frame:SetToplevel() end
    function frame:EnableMouse() end
    function frame:SetAllPoints() end
    function frame:SetPoint() end
    function frame:GetPoint() return nil end
    function frame:SetBackdropBorderColor() end
    function frame:SetBackdropColor() end
    function frame:SetMotionScriptsWhileDisabled() end
    function frame:SetFontString(fontString) self.fontString = fontString end
    function frame:SetNormalFontObject() end
    function frame:SetHighlightFontObject() end
    function frame:SetDisabledFontObject() end
    function frame:RegisterForClicks() end
    function frame:SetText(text) self.fontString:SetText(text) end
    function frame:GetText() return self.fontString:GetText() end
    function frame:Enable() self.enabled = true end
    function frame:Disable() self.enabled = false end
    function frame:IsEnabled() return self.enabled end
    function frame:SetEnabled(enabled) self.enabled = enabled end
    function frame:SetShown(shown) self.shown = shown end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown end
    function frame:LockHighlight() self.highlightLocked = true end
    function frame:UnlockHighlight() self.highlightLocked = false end
    function frame:ClearAllPoints() end
    function frame:CreateTexture(textureName)
        return makeTexture(env, textureName)
    end
    function frame:CreateFontString(fontStringName)
        return makeFontString(env, fontStringName)
    end
    function frame:SetNormalTexture() end
    function frame:SetPushedTexture() end
    function frame:SetDisabledTexture() end
    function frame:SetHighlightTexture() end
    if name then env[name] = frame end
    return frame
end

local function makeEnvironment()
    local env
    env = setmetatable({
        WOW_PROJECT_ID = 2,
        WOW_PROJECT_MAINLINE = 1,
        WOW_PROJECT_CLASSIC = 2,
        WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5,
        WOW_PROJECT_CATACLYSM_CLASSIC = 14,
        WOW_PROJECT_MISTS_CLASSIC = 19,
        SOUNDKIT = {IG_MAINMENU_OPTION_CHECKBOX_ON = 1},
        TOOLTIP_DEFAULT_COLOR = {r = 1, g = 1, b = 1},
        TOOLTIP_DEFAULT_BACKGROUND_COLOR = {r = 0, g = 0, b = 0},
        BackdropTemplateMixin = nil,
        TooltipBackdropTemplateMixin = nil,
        DropDownMenuButtonMixin = nil,
        GameTooltip = {},
        NORMAL_FONT_COLOR = {r = 1, g = 1, b = 1},
        HIGHLIGHT_FONT_COLOR = {r = 1, g = 1, b = 1},
        EventRegistry = {TriggerEvent = function() end},
        LibStub = {},
        CreateFromMixins = function(...) return setmetatable({}, {__index = select(1, ...)}) end,
    }, {__index = _G})
    env._G = env
    env.GetCurrentEnvironment = function() return env end
    env.GetAppropriateTooltip = function() return env.GameTooltip end
    env.GetCursorPosition = function() return 0, 0 end
    env.GetCVar = function() return nil end
    env.GetScreenHeight = function() return 800 end
    env.GetScreenWidth = function() return 1200 end
    env.PlaySound = function() end
    env.CloseMenus = function() end
    env.ShowUIPanel = function() end
    env.GetValueOrCallFunction = function(object, key) return object[key] end
    env.GameTooltip_SetTitle = function() end
    env.GameTooltip_AddInstructionLine = function() end
    env.GameTooltip_AddNormalLine = function() end
    env.GameTooltip_AddColoredLine = function() end
    env.securecall = function() end
    env.securecallfunction = function(callback, ...) return callback(...) end
    env.hooksecurefunc = function() end
    env.CreateFrame = function(frameType, name, parent)
        return makeFrame(env, frameType, name, parent)
    end
    env.LibStub.NewLibrary = function(self, majorVersion)
        self.library = {}
        self.library.majorVersion = majorVersion
        return self.library
    end
    return env
end

local function loadLibrary(env)
    local chunk = assert(loadfile(SOURCE))
    setfenv(chunk, env)()
    return env.LibStub.library
end

describe("LibUIDropDownMenu", function()
    local originalTrace

    before_each(function()
        originalTrace = _G.QuestieTraceCore
    end)

    after_each(function()
        _G.QuestieTraceCore = originalTrace
    end)

    it("resets a tinted pooled check texture for the next normal entry", function()
        local env = makeEnvironment()
        local lib = loadLibrary(env)
        _G.QuestieTraceCore = {
            GetStatusData = function() return {isRunning = true} end,
            ShowExportWindow = function() end,
        }
        local QuestieTraceMenu = QuestieLoader:ImportModule("QuestieTraceMenu")
        local traceEntry = QuestieTraceMenu.Build(function() end)

        lib:UIDropDownMenu_AddButton(traceEntry, 1)
        local button = env.L_DropDownListQuestie1Button1
        assert.are_same({0.25, 1, 0.25}, {button.Check:GetVertexColor()})
        assert.are_same({0.25, 1, 0.25}, {button.UnCheck:GetVertexColor()})

        -- Reinitializing a menu reuses the first pooled button for a new entry.
        env.L_DropDownListQuestie1.numButtons = 0
        lib:UIDropDownMenu_AddButton({text = "Normal entry", checked = false}, 1)

        assert.are_same({1, 1, 1, 1}, {button.Check:GetVertexColor()})
        assert.are_same({1, 1, 1, 1}, {button.UnCheck:GetVertexColor()})
    end)
end)
