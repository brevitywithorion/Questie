---@class QuestieTraceMenu
local QuestieTraceMenu = QuestieLoader:CreateModule("QuestieTraceMenu")

---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")
local TRACE_RUNNING_COLOR = { 0.25, 1.0, 0.25 }
local TRACE_STOPPED_COLOR = { 1.0, 0.25, 0.25 }

---Returns whether QuestieTrace has permission to start a capture.
---@param trace QuestieTraceCore
---@return boolean
local function hasConsent(trace)
    if type(trace.GetConsentState) == "function" then
        return trace.GetConsentState() == true
    end

    -- Keep compatibility with QuestieTrace versions predating GetConsentState.
    local settings = rawget(_G, "QuestieTrace")
    return type(settings) ~= "table"
        or type(settings.settings) ~= "table"
        or settings.settings.dataCollectionConsent == true
end

---Returns whether QuestieTrace currently has an active capture.
---@param trace QuestieTraceCore
---@return boolean isRunning
local function getIsRunning(trace)
    if type(trace.GetStatusData) ~= "function" then
        return false
    end

    local ok, status = pcall(trace.GetStatusData)
    return ok and type(status) == "table" and status.isRunning == true
end

---Colors the dropdown indicator according to the current capture state.
---@param button Button
---@param isRunning boolean
local function tintButton(button, isRunning)
    if not button then
        return
    end

    local check = button.Check
    local uncheck = button.UnCheck
    if not check or not uncheck then
        return
    end

    local color = isRunning and TRACE_RUNNING_COLOR or TRACE_STOPPED_COLOR
    check:SetVertexColor(unpack(color))
    uncheck:SetVertexColor(unpack(color))
    uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
    uncheck:SetTexCoord(0.0, 0.5, 0.5, 1.0)
end

---Refreshes the dropdown indicator after LibUIDropDownMenu finishes its click update.
---@param button Button
---@param trace QuestieTraceCore
local function deferRefresh(button, trace)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            QuestieTraceMenu.RefreshButton(button, trace)
        end)
    else
        QuestieTraceMenu.RefreshButton(button, trace)
    end
end

---Builds the optional QuestieTrace entry for the Questie menu.
---@param onClick fun(trace: QuestieTraceCore, button: string?)
---@return table?
function QuestieTraceMenu.Build(onClick)
    local trace = rawget(_G, "QuestieTraceCore")
    if type(trace) ~= "table" or type(trace.ShowExportWindow) ~= "function" then
        return nil
    end

    return {
        text = "QuestieTrace",
        func = function(button, _, _, _, clickButton)
            onClick(trace, clickButton)
            if clickButton == "RightButton" then
                -- LibUIDropDownMenu changes the check textures before calling this callback. Defer
                -- the refresh so a refused StartCapture cannot leave the menu falsely green.
                deferRefresh(button, trace)
            end
        end,
        checked = function(button)
            local isRunning = getIsRunning(trace)
            tintButton(button, isRunning)
            return isRunning
        end,
        registerForRightClick = true,
        keepShownOnClick = true,
        isNotRadio = false,
    }
end

---Opens the trace export window without undoing an explicit stopped state.
---@param trace QuestieTraceCore
function QuestieTraceMenu.ShowExportWindow(trace)
    local wasRunning = getIsRunning(trace)
    trace.ShowExportWindow()
    -- QuestieTrace rotates the session after exporting and may auto-start a new one. Preserve an
    -- explicit stop made before this menu click without changing normal export behavior.
    if not wasRunning and getIsRunning(trace) and type(trace.StopCapture) == "function" then
        trace.StopCapture()
    end
end

---Synchronizes a dropdown button with QuestieTrace's actual capture state.
---@param button Button
---@param trace QuestieTraceCore
function QuestieTraceMenu.RefreshButton(button, trace)
    if not button then
        return
    end

    local isRunning = getIsRunning(trace)
    tintButton(button, isRunning)
    button.checked = isRunning
    button.Check:SetShown(isRunning)
    button.UnCheck:SetShown(not isRunning)
    if isRunning then
        button:LockHighlight()
    else
        button:UnlockHighlight()
    end
end

---Starts or stops QuestieTrace from the menu.
---@param trace QuestieTraceCore
function QuestieTraceMenu.Toggle(trace)
    local status = trace.GetStatusData()
    if status.isRunning then
        trace.StopCapture()
        Questie:Print(l10n("QuestieTrace stopped"))
    else
        if not hasConsent(trace) then
            if type(trace.ShowConsentPrompt) == "function" then
                trace.ShowConsentPrompt()
            end
            return
        end

        -- Preserve a stopped session before starting the next one.
        trace.SaveCapture()
        trace.StartCapture()
        Questie:Print(l10n("QuestieTrace started"))
    end
end
