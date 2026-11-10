dofile("setupTests.lua")

describe("QuestieTraceMenu", function()
    local QuestieTraceMenu
    local originalTrace

    local function makeButton()
        local function makeTexture()
            return {
                SetVertexColor = function() end,
                SetTexture = function() end,
                SetTexCoord = function() end,
                SetShown = function() end,
            }
        end
        return {
            Check = makeTexture(),
            UnCheck = makeTexture(),
            SetShown = function() end,
            LockHighlight = function() end,
            UnlockHighlight = function() end,
        }
    end

    before_each(function()
        originalTrace = _G.QuestieTraceCore
        _G.QuestieTraceCore = nil
        dofile("Localization/l10n.lua")
        dofile("Modules/QuestieMenu/QuestieTraceMenu.lua")
        QuestieTraceMenu = QuestieLoader:ImportModule("QuestieTraceMenu")
    end)

    after_each(function()
        _G.QuestieTraceCore = originalTrace
    end)

    it("does not add a menu entry when QuestieTrace is not installed", function()
        assert.is_nil(QuestieTraceMenu.Build(function() end))
    end)

    it("opens the export window through the QuestieMenu callback and shows green while capture is running", function()
        local originalLibStub = _G.LibStub
        local originalTinsert = _G.tinsert
        local originalDb = Questie.db
        local menuTable
        local shown = 0
        local trace = {
            GetStatusData = function() return {isRunning = true} end,
            ShowExportWindow = function() shown = shown + 1 end,
        }
        local questieLib = QuestieLoader:ImportModule("QuestieLib")
        local questieProfessions = QuestieLoader:ImportModule("QuestieProfessions")
        local townsfolk = QuestieLoader:ImportModule("Townsfolk")
        local professionKeys = {}
        for _, key in ipairs({
            "FIRST_AID", "BLACKSMITHING", "LEATHERWORKING", "ALCHEMY", "HERBALISM", "COOKING", "MINING",
            "TAILORING", "ENGINEERING", "ENCHANTING", "FISHING", "SKINNING", "JEWELCRAFTING", "ARCHAEOLOGY",
            "INSCRIPTION", "RIDING",
        }) do
            professionKeys[key] = key
        end

        questieLib.AddonPath = ""
        questieProfessions.professionKeys = professionKeys
        questieProfessions.HasProfessionAndSkillLevel = function() return false end
        townsfolk.townsfolk = {}
        townsfolk.professionTrainers = {}
        Questie.db = {
            char = {townsfolk = {}, vendorList = {}},
            profile = {townsfolkConfig = {}, debugEnabled = false},
        }
        _G.QuestieTraceCore = trace

        local dropdown = {
            Create_UIDropDownMenu = function() return {} end,
            EasyMenu = function(_, entries) menuTable = entries end,
            CloseDropDownMenus = spy.new(function() end),
        }
        local questiePopup = QuestieLoader:ImportModule("QuestiePopup")
        questiePopup.Dialogs = questiePopup.Dialogs or {}
        _G.tinsert = table.insert
        _G.LibStub = {GetLibrary = function() return dropdown end}
        dofile("Modules/QuestieMenu/QuestieMenu.lua")
        local QuestieMenu = QuestieLoader:ImportModule("QuestieMenu")
        QuestieMenu.menu = nil
        QuestieMenu.Hide = spy.new(function() end)
        QuestieMenu:Show()

        local entry
        for _, menuEntry in ipairs(menuTable) do
            if menuEntry.text == "QuestieTrace" then
                entry = menuEntry
                break
            end
        end
        assert.is_not_nil(entry)
        assert.is_true(entry.checked(makeButton()))
        assert.is_true(entry.registerForRightClick)
        assert.is_true(entry.keepShownOnClick)
        entry.func(nil, nil, nil, nil, "LeftButton")
        assert.spy(QuestieMenu.Hide).was.called(1)
        assert.are_equal(1, shown)

        _G.LibStub = originalLibStub
        _G.tinsert = originalTinsert
        Questie.db = originalDb
    end)

    it("shows red when capture is not running", function()
        _G.QuestieTraceCore = {
            GetStatusData = function() return {isRunning = false} end,
            ShowExportWindow = function() end,
        }

        local entry = QuestieTraceMenu.Build(function() end)
        assert.is_false(entry.checked(makeButton()))
    end)

    it("refreshes the indicator after a refused right-click start", function()
        local originalTimer = _G.C_Timer
        local deferred
        _G.C_Timer = {After = function(_, callback) deferred = callback end}
        local running = false
        local trace = {
            GetStatusData = function() return {isRunning = running} end,
            StartCapture = function() end,
            ShowExportWindow = function() end,
        }
        _G.QuestieTraceCore = trace
        local entry = QuestieTraceMenu.Build(function(currentTrace, button)
            if button == "RightButton" then currentTrace.StartCapture() end
        end)
        local button = makeButton()
        button.checked = true
        entry.func(button, nil, nil, true, "RightButton")
        assert.is_true(button.checked)
        deferred()
        assert.is_false(button.checked)
        _G.C_Timer = originalTimer
    end)

    it("keeps an explicitly stopped capture stopped after export", function()
        local running = false
        local stopped = 0
        local trace = {
            GetStatusData = function() return {isRunning = running} end,
            ShowExportWindow = function() running = true end,
            StopCapture = function() running = false; stopped = stopped + 1 end,
        }

        QuestieTraceMenu.ShowExportWindow(trace)
        assert.are_equal(1, stopped)
        assert.is_false(running)
    end)

    it("stops a running capture", function()
        local calls = {}
        local trace = {
            GetStatusData = function() return {isRunning = true} end,
            StopCapture = function() calls[#calls + 1] = "stop" end,
            SaveCapture = function() calls[#calls + 1] = "save" end,
            StartCapture = function() calls[#calls + 1] = "start" end,
        }

        QuestieTraceMenu.Toggle(trace)
        assert.are_same({"stop"}, calls)
    end)

    it("saves a stopped capture before starting the next one", function()
        local calls = {}
        local trace = {
            GetStatusData = function() return {isRunning = false} end,
            StopCapture = function() calls[#calls + 1] = "stop" end,
            SaveCapture = function() calls[#calls + 1] = "save" end,
            StartCapture = function() calls[#calls + 1] = "start" end,
        }

        QuestieTraceMenu.Toggle(trace)
        assert.are_same({"save", "start"}, calls)
    end)

    it("shows the consent prompt instead of starting after consent was declined", function()
        local calls = {}
        local trace = {
            GetStatusData = function() return {isRunning = false} end,
            GetConsentState = function() return false end,
            ShowConsentPrompt = function() calls[#calls + 1] = "prompt" end,
            SaveCapture = function() calls[#calls + 1] = "save" end,
            StartCapture = function() calls[#calls + 1] = "start" end,
        }

        QuestieTraceMenu.Toggle(trace)
        assert.are_same({"prompt"}, calls)
    end)

    it("prints the QuestieTrace start and stop messages", function()
        local originalPrint = Questie.Print
        local messages = {}
        local running = false
        Questie.Print = function(_, message) messages[#messages + 1] = message end
        local trace = {
            GetStatusData = function() return {isRunning = running} end,
            GetConsentState = function() return true end,
            SaveCapture = function() end,
            StartCapture = function() running = true end,
            StopCapture = function() running = false end,
        }

        QuestieTraceMenu.Toggle(trace)
        QuestieTraceMenu.Toggle(trace)
        Questie.Print = originalPrint

        assert.are_same({"QuestieTrace started", "QuestieTrace stopped"}, messages)
    end)
end)
