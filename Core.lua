local AddonName, addon = ...

local L = addon.L

-- 키 바인딩 이름은 파일 로드 시점에 정해지므로 클라이언트 언어 기준으로 표시된다.
_G["BINDING_HEADER_HONEYDELVETODAY"] = L.TITLE
_G["BINDING_NAME_HONEYDELVETODAY_DASHBOARD"] = L.BINDING_DASHBOARD
_G["BINDING_NAME_HONEYDELVETODAY_CONFIG"] = L.BINDING_CONFIG

local AceAddon = LibStub("AceAddon-3.0")
local HDT = AceAddon:NewAddon(AddonName, "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local DELVE_ICON = [[Interface/AddOns/HoneyDelveToday/icon]]
local GILDED_STASH_SPELL_ID = 7591
-- 신화 안개문장(12.1) 화폐 ID. 아이콘은 이 화폐 정보에서 가져온다. (12.0 신화 여명문장 아이콘 7639523은 대체됨)
local MYTH_CREST_CURRENCY_ID = 3446
local MYTH_CREST_ICON_FALLBACK = "Interface\\Icons\\Inv_121_crest_myth"
local BOUNTY_QUEST_ID = 86371
local BOUNTY_ITEM_ID = 274374 -- 보물 추적자의 은혜 (12.1 기준 ID, 12.0 기준 ID는 252415)
local DUNDUN_SHARD_CURRENCY_ID = 3376 -- 둔둔의 조각 (넘칠듯한 풍요로움 아이콘용, 12.1 인게임 확인)
local ABUNDANCE_QUEST_ID = 97064 -- 넘칠듯한 풍요로움: 주 1회 둔둔 클릭 시 완료되는 퀘스트 (WeeklyRewards 애드온 delve-abundance 항목 참고)
-- 정순한 마나 수정: 11레벨 풍요로운 구렁 완료 시 획득, 자흐란에게 영웅템 구매용 (주간 상한 250, 보유 상한 1000, 인게임 툴팁으로 ID 확인)
local MANA_CRYSTAL_CURRENCY_ID = 3356
local MANA_CRYSTAL_WEEKLY_CAP_FALLBACK = 250 -- API에서 주간 상한을 못 받아올 때 표시용

-- 구렁로봇 7001 (장난감) 대화상자 자동 선택
-- NPC ID: UnitGUID("npc") = "Vehicle-0-4278-0-25530-232267-00004326BB" 에서 6번째 값 (인게임 dump로 확인)
-- 선택지 ID: 140192 = 한밤 구렁, 140193 = 카즈 알가르 구렁 (인게임 dump로 확인)
-- 판별은 선택지 ID와 NPC ID로만 한다. (언어마다 다른 선택지 글자나 NPC 이름은 비교하지 않는다)
local DELVEBOT_NPC_ID = 232267
local DELVEBOT_MIDNIGHT_OPTION_ID = 140192
local DELVEBOT_KHAZ_OPTION_ID = 140193 -- 카즈 알가르 구렁: 칩 구매 여부와 상관없이 항상 존재하므로 구렁로봇 판별에 사용
local DELVEBOT_BOUNTIFUL_MIN_LEVEL = 90 -- 한밤 풍요로운 구렁 입장 가능 레벨(만렙)

-- 둔둔 (넘칠듯한 풍요로움) 대화상자: 수락 선택지 옆에 보유 중인 복원된 금고 열쇠 개수 표시
-- 선택지 ID: 140123 = "제 구렁을 넘치는 풍요로 채워 주십시오!", 140497 = "사양하겠습니다." (인게임 확인)
-- 넘칠듯한 풍요로움을 사용하면 풍요로운 상자가 2개 나오므로 열쇠가 2개 있어야 모두 열 수 있다.
local DUNDUN_ACCEPT_OPTION_ID = 140123
local DUNDUN_DECLINE_OPTION_ID = 140497
local RESTORED_KEY_CURRENCY_ID = 3028 -- 복원된 금고 열쇠 (인게임 확인)
local DUNDUN_KEY_REQUIRED = 2

-- 위대한 금고 "세계" 행 (구렁/야외 활동/사냥감/의식 지점)
-- Enum.WeeklyRewardChestThresholdType.World = 6
local VAULT_WORLD_TYPE = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World) or 6
local VAULT_ICON = "Interface\\Icons\\INV_Misc_Lockbox_1"

-- 별 문자(U+2605)를 UTF-8 바이트 이스케이프로 표기
local STAR_MARK = "\226\152\133"

-- 잘못 놓여진 진귀품 버프 (구렁 바닥의 잘못 놓여진 진귀품을 주우면 걸리는 버프)
-- 주문 ID 1280098, 아이콘 ID 2967107 (인게임 툴팁으로 확인, 한국어 버프 이름 "은혜")
-- 버프 설명(최대 생명력, 이동 속도 등 누적 수치)은 버프 툴팁 데이터에서 그대로 읽는다.
local CURIO_BUFF_SPELL_ID = 1280098
local CURIO_BUFF_ICON_FALLBACK = 2967107

-- 진귀품 버프 표시용 문구
-- Locale.lua를 고치지 않고 이 파일만 바꿔도 동작하도록 여기에 둔다. (나중에 Locale.lua로 옮겨도 된다)
-- 표시 언어가 koKR이 아니면 enUS 문구를 쓴다.
local CURIO_TEXT = {
    koKR = {
        GROUP = "진귀품 버프 표시",
        DESC = "구렁에서 잘못 놓여진 진귀품을 주우면 걸리는 버프(%s)의 내용을 버프창을 찾아보지 않아도 볼 수 있도록 화면에 띄웁니다.",
        SHOW = "진귀품 버프 내용 표시",
        LOCK = "위치 잠금",
        LOCK_DESC = "잠금을 풀면 버프가 없어도 미리보기 창이 나타나며, 마우스로 끌어서 옮길 수 있습니다.\n위치를 정한 뒤 다시 잠그면 창이 마우스 클릭을 가로채지 않습니다.",
        FONT_SIZE = "글자 크기",
        BG_ALPHA = "배경 투명도",
        RESET_POS = "위치 초기화",
        RESET_POS_DESC = "진귀품 버프 창을 화면 중앙 위쪽으로 되돌립니다.",
        PREVIEW = "(미리보기, 끌어서 이동)",
        SAMPLE = "버프를 얻으면 이곳에 내용이 표시됩니다.",
        BUFF_FALLBACK = "은혜",
    },
    enUS = {
        GROUP = "Curio Buff Display",
        DESC = "Shows the details of the buff (%s) you get from picking up misplaced curios in delves, so you do not have to look for it on the buff bar.",
        SHOW = "Show curio buff details",
        LOCK = "Lock position",
        LOCK_DESC = "When unlocked, a preview window appears even without the buff and can be dragged with the mouse.\nLock it again after positioning so it does not catch mouse clicks.",
        FONT_SIZE = "Font size",
        BG_ALPHA = "Background opacity",
        RESET_POS = "Reset position",
        RESET_POS_DESC = "Moves the curio buff window back to the upper center of the screen.",
        PREVIEW = "(Preview, drag to move)",
        SAMPLE = "The buff details will be shown here once you get the buff.",
        BUFF_FALLBACK = "Curio buff",
    },
}

local function CT(key)
    local code = addon.GetDisplayLocale and addon.GetDisplayLocale()
    local set = CURIO_TEXT[code] or CURIO_TEXT.enUS
    return set[key] or CURIO_TEXT.enUS[key] or key
end

-- 진귀품 버프 이름 (게임에서 읽는다, 실패 시 기본 문구)
local function GetCurioSpellName()
    local ok, name = pcall(function()
        return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(CURIO_BUFF_SPELL_ID)
    end)
    if ok and type(name) == "string" and name ~= "" then return name end
    return CT("BUFF_FALLBACK")
end

-- 지역/구렁 목록은 DB.lua에 있다 (언어와 무관한 데이터)
local ZoneList = addon.ZoneList
local DelveList = addon.DelveList

-- mapID로 지역 정보를 찾기 위한 색인
local ZoneByMapID = {}
for _, zone in ipairs(ZoneList) do
    ZoneByMapID[zone.mapID] = zone
end

-- 전역퀘 요약 캐시 (키: 지역 mapID)
-- 대시보드를 열기 전에도 백그라운드에서 채워두고, UpdateDisplay는 이 캐시를 즉시 읽어서 표시한다.
local WQCache = {}
local wqRetryTicker = nil

-- =========================================================
-- 저장 데이터 (HoneyDelveDB)
-- HoneyDelveDB.Data[변형ID]에는 사용자가 직접 바꾼 값만 저장한다.
--   grade: 사용자가 바꾼 등급 (없으면 DB.lua의 기본 등급)
--   memo : 사용자가 바꾼 메모 (없으면 표시 언어의 기본 메모)
-- 직접 바꾸지 않은 항목은 저장하지 않으므로, 새 버전의 기본값과 언어별 메모가 자동으로 반영된다.
--
-- DataVersion 1 (1.3.3 이하): 모든 변형의 기본 등급/메모를 Data에 복사해 저장했다.
-- DataVersion 2: 사용자가 바꾼 값만 저장한다. 1에서 올라올 때 기본값과 같은 값은 지운다.
-- =========================================================
local DATA_VERSION = 2

local function MigrateDataV2()
    local KO = addon.Locales.koKR
    for id, entry in pairs(HoneyDelveDB.Data) do
        if type(entry) == "table" then
            local koMemo = KO.Memos[id]
            if koMemo and entry.memo == koMemo then
                entry.memo = nil
            end
            local default = addon.DefaultData[id]
            if default and entry.grade == default.grade then
                entry.grade = nil
            end
            if entry.memo == nil and entry.grade == nil then
                HoneyDelveDB.Data[id] = nil
            end
        else
            HoneyDelveDB.Data[id] = nil
        end
    end
end

-- InitializeDB는 기존 유저 데이터(사용자가 바꾼 등급/메모)를 보존한다.
-- forceReset=true일 때만 사용자가 바꾼 값을 전부 지운다.
-- 반환값: 이번 버전에서 새로 추가된 변형 개수(신규 버전 업데이트 안내용)
local function InitializeDB(forceReset)
    HoneyDelveDB = HoneyDelveDB or {}
    local isFresh = (HoneyDelveDB.Data == nil)

    -- 이미 안내한 변형 목록. 처음 만들 때는 기존 저장 데이터에 있던 변형을 기준으로 채운다.
    if HoneyDelveDB.KnownVariants == nil then
        HoneyDelveDB.KnownVariants = {}
        if HoneyDelveDB.Data then
            for id in pairs(HoneyDelveDB.Data) do
                HoneyDelveDB.KnownVariants[id] = true
            end
        end
    end

    if forceReset or not HoneyDelveDB.Data then
        HoneyDelveDB.Data = {}
        HoneyDelveDB.DataVersion = DATA_VERSION
    end
    if (HoneyDelveDB.DataVersion or 1) < 2 then
        MigrateDataV2()
        HoneyDelveDB.DataVersion = 2
    end

    HoneyDelveDB.Minimap = HoneyDelveDB.Minimap or { hide = false }
    if HoneyDelveDB.ShowMemo == nil then HoneyDelveDB.ShowMemo = true end
    if HoneyDelveDB.Alpha == nil then HoneyDelveDB.Alpha = 0.8 end
    if HoneyDelveDB.FontSize == nil then HoneyDelveDB.FontSize = 12 end
    if HoneyDelveDB.ShowGraceAlert == nil then HoneyDelveDB.ShowGraceAlert = true end
    if HoneyDelveDB.ShowBounty == nil then HoneyDelveDB.ShowBounty = true end
    if HoneyDelveDB.ShowWQGold == nil then HoneyDelveDB.ShowWQGold = true end
    if HoneyDelveDB.ShowWQMarl == nil then HoneyDelveDB.ShowWQMarl = true end
    if HoneyDelveDB.ShowWQShard == nil then HoneyDelveDB.ShowWQShard = true end
    if HoneyDelveDB.ShowZoneMeta == nil then HoneyDelveDB.ShowZoneMeta = true end
    if HoneyDelveDB.ShowAbundance == nil then HoneyDelveDB.ShowAbundance = true end
    if HoneyDelveDB.ShowVaultKeyLine == nil then HoneyDelveDB.ShowVaultKeyLine = true end
    if HoneyDelveDB.ShowKeyShardLine == nil then HoneyDelveDB.ShowKeyShardLine = true end
    if HoneyDelveDB.ShowGraceLine == nil then HoneyDelveDB.ShowGraceLine = true end
    if HoneyDelveDB.ShowGildedStashLine == nil then HoneyDelveDB.ShowGildedStashLine = true end
    if HoneyDelveDB.ShowVaultWorldLine == nil then HoneyDelveDB.ShowVaultWorldLine = true end
    if HoneyDelveDB.ShowManaCrystalLine == nil then HoneyDelveDB.ShowManaCrystalLine = true end
    if HoneyDelveDB.AutoDelveBot == nil then HoneyDelveDB.AutoDelveBot = true end
    if HoneyDelveDB.AutoDelveBotRequireBountiful == nil then HoneyDelveDB.AutoDelveBotRequireBountiful = true end
    if HoneyDelveDB.ShowDundunKeyHint == nil then HoneyDelveDB.ShowDundunKeyHint = true end
    if HoneyDelveDB.ShowCurioBuff == nil then HoneyDelveDB.ShowCurioBuff = true end
    if HoneyDelveDB.CurioBuffLocked == nil then HoneyDelveDB.CurioBuffLocked = true end
    if HoneyDelveDB.CurioFontSize == nil then HoneyDelveDB.CurioFontSize = 12 end
    if HoneyDelveDB.CurioAlpha == nil then HoneyDelveDB.CurioAlpha = 0.6 end

    local addedCount = 0
    for id in pairs(addon.DefaultData) do
        if not HoneyDelveDB.KnownVariants[id] then
            HoneyDelveDB.KnownVariants[id] = true
            if not isFresh then addedCount = addedCount + 1 end
        end
    end
    return addedCount
end

-- 등급/메모 조회와 저장
local function GetDefaultGrade(id)
    local default = addon.DefaultData[id]
    return default and default.grade or "A"
end

local function GetGrade(id)
    local entry = HoneyDelveDB.Data[id]
    if entry and entry.grade then return entry.grade end
    return GetDefaultGrade(id)
end

local function GetMemo(id)
    local entry = HoneyDelveDB.Data[id]
    if entry and entry.memo ~= nil then return entry.memo end
    return addon.GetDefaultMemo(id)
end

local function HasMemoOverride(id)
    local entry = HoneyDelveDB.Data[id]
    return entry ~= nil and entry.memo ~= nil
end

-- 값이 기본값과 같으면 저장하지 않는다. 등급과 메모가 모두 비면 항목을 지운다.
local function SetOverride(id, field, value, defaultValue)
    local entry = HoneyDelveDB.Data[id]
    if value == defaultValue then
        if entry then
            entry[field] = nil
            if entry.grade == nil and entry.memo == nil then
                HoneyDelveDB.Data[id] = nil
            end
        end
        return
    end
    if not entry then
        entry = {}
        HoneyDelveDB.Data[id] = entry
    end
    entry[field] = value
end

local function SetGrade(id, value)
    SetOverride(id, "grade", value, GetDefaultGrade(id))
end

local function SetMemo(id, value)
    SetOverride(id, "memo", value, addon.GetDefaultMemo(id))
end

local function ResetMemo(id)
    SetOverride(id, "memo", nil, nil)
end

-- 아이템 개수 조회 (가방 + 은행, 충전 횟수 포함)
-- 12.1.5에서 전역 함수 GetItemCount가 삭제되어 C_Item.GetItemCount를 사용한다.
-- C_Item.GetItemCount가 없는 이전 클라이언트에서만 전역 함수로 대체한다.
local function GetItemCountSafe(itemID)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, true, true) or 0
    end
    if GetItemCount then
        return GetItemCount(itemID, true, true) or 0
    end
    return 0
end

local function GetBountyState()
    local bountyGet = C_QuestLog.IsQuestFlaggedCompleted(BOUNTY_QUEST_ID)
    local hasItem = GetItemCountSafe(BOUNTY_ITEM_ID) > 0
    return bountyGet, hasItem
end

local function GetAbundanceState()
    return C_QuestLog.IsQuestFlaggedCompleted(ABUNDANCE_QUEST_ID)
end

-- 설정창에서 이름이 게임 고유 명칭인 토글 ("복원된 금고 열쇠 표시" 등)
local function ShowNameLabel(nameKey)
    return function() return L.OPT_SHOW_FMT:format(addon.GetName(nameKey)) end
end

-- 보관함 이름: 보관함 위젯(7591)의 주문 ID 1216211 이름을 게임에서 읽는다 (Locale.lua의 Stash)
local function GetStashLabel()
    return addon.GetName("Stash")
end

-- 설정창 구성
-- 표시 언어(설정창의 애드온 언어)는 SavedVariables가 로드된 뒤에 알 수 있으므로 OnInitialize에서 만든다.
local options

local function BuildOptions()
    options = {
        type = "group",
        name = "HoneyDelveToday",
        args = {
            general = {
                type = "group", name = L.OPT_GENERAL, order = 1,
                args = {
                    desc = {
                        type = "description",
                        name = "|cffffff00" .. L.OPT_COMMANDS .. "|r",
                        order = 1, fontSize = "medium", width = "full",
                    },
                    -- 애드온 언어: 화면 문구와 기본 메모의 언어. 바꾸면 UI 다시 불러오기 후 적용된다.
                    -- 저장 값은 HoneyDelveDB.LocaleOverride (nil = 자동)
                    -- 대부분의 사용자에게는 필요 없는 설정이라 맨 아래(데이터 관리 다음)에 둔다.
                    languageGroup = {
                        type = "group", name = L.OPT_LANGUAGE_GROUP, order = 13, inline = true,
                        args = {
                            languageDesc = {
                                type = "description",
                                name = "|cffaaaaaa" .. L.OPT_LANGUAGE_DESC .. "|r",
                                order = 1, fontSize = "medium", width = "full",
                            },
                            language = {
                                type = "select", name = L.OPT_LANGUAGE, order = 2, width = 1.5,
                                values = function()
                                    local values = { auto = L.OPT_LANGUAGE_AUTO }
                                    for _, code in ipairs(addon.LANGUAGE_ORDER) do
                                        if addon.Locales[code] then values[code] = addon.LANGUAGE_NAMES[code] or code end
                                    end
                                    return values
                                end,
                                sorting = function()
                                    local sorting = { "auto" }
                                    for _, code in ipairs(addon.LANGUAGE_ORDER) do
                                        if addon.Locales[code] then sorting[#sorting + 1] = code end
                                    end
                                    return sorting
                                end,
                                get = function() return HoneyDelveDB.LocaleOverride or "auto" end,
                                set = function(_, val)
                                    if val == "auto" then
                                        HoneyDelveDB.LocaleOverride = nil
                                    else
                                        HoneyDelveDB.LocaleOverride = val
                                    end
                                    AceConfigRegistry:NotifyChange(AddonName)
                                end,
                            },
                            reload = {
                                type = "execute", name = L.OPT_RELOAD, order = 3, width = 1.2,
                                desc = L.OPT_RELOAD_DESC,
                                -- 바꾼 언어가 아직 적용되지 않았을 때만 누를 수 있다
                                disabled = function() return addon.GetSavedDisplayLocale() == addon.GetDisplayLocale() end,
                                func = function() ReloadUI() end,
                            },
                            pending = {
                                type = "description", order = 4, fontSize = "medium", width = "full",
                                name = function() return "|cffff8000" .. L.OPT_LANGUAGE_PENDING .. "|r" end,
                                hidden = function() return addon.GetSavedDisplayLocale() == addon.GetDisplayLocale() end,
                            },
                        },
                    },
                    showMinimap = {
                        type = "toggle", name = L.OPT_SHOW_MINIMAP, order = 2, width = "full",
                        get = function() return not HoneyDelveDB.Minimap.hide end,
                        set = function(_, val)
                            HoneyDelveDB.Minimap.hide = not val
                            if val then icon:Show(AddonName) else icon:Hide(AddonName) end
                        end,
                    },
                    showMemo = {
                        type = "toggle", name = L.OPT_SHOW_MEMO, order = 3, width = "full",
                        get = function() return HoneyDelveDB.ShowMemo end,
                        set = function(_, val)
                            HoneyDelveDB.ShowMemo = val
                            if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                        end,
                    },
                    showGraceAlert = {
                        type = "toggle", name = L.OPT_GRACE_ALERT, order = 4, width = "full",
                        desc = function() return L.OPT_GRACE_ALERT_DESC:format(addon.GetName("Grace")) end,
                        get = function() return HoneyDelveDB.ShowGraceAlert end,
                        set = function(_, val)
                            HoneyDelveDB.ShowGraceAlert = val
                            HDT:UpdateGraceAlert()
                        end,
                    },
                    trackerGroup = {
                        type = "group", name = L.OPT_TRACKER_GROUP, order = 5, inline = true,
                        args = {
                            showVaultKeyLine = {
                                type = "toggle", name = ShowNameLabel("RestoredKey"), order = 1, width = "full",
                                get = function() return HoneyDelveDB.ShowVaultKeyLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowVaultKeyLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showKeyShardLine = {
                                type = "toggle", name = ShowNameLabel("KeyShard"), order = 2, width = "full",
                                get = function() return HoneyDelveDB.ShowKeyShardLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowKeyShardLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showGraceLine = {
                                type = "toggle", name = ShowNameLabel("Grace"), order = 4, width = "full",
                                get = function() return HoneyDelveDB.ShowGraceLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowGraceLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showAbundance = {
                                type = "toggle", name = L.OPT_SHOW_FMT:format(L.ABUNDANCE), order = 5, width = "full",
                                get = function() return HoneyDelveDB.ShowAbundance end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowAbundance = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showGildedStashLine = {
                                type = "toggle", order = 6, width = "full",
                                name = function() return L.OPT_SHOW_FMT:format(GetStashLabel()) end,
                                get = function() return HoneyDelveDB.ShowGildedStashLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowGildedStashLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showVaultWorldLine = {
                                type = "toggle", name = L.OPT_SHOW_VAULT_WORLD, order = 7, width = "full",
                                desc = L.OPT_VAULT_WORLD_DESC,
                                get = function() return HoneyDelveDB.ShowVaultWorldLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowVaultWorldLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showManaCrystalLine = {
                                type = "toggle", name = ShowNameLabel("ManaCrystal"), order = 3, width = "full",
                                desc = function() return L.OPT_MANA_CRYSTAL_DESC:format(addon.GetName("ManaCrystal")) end,
                                get = function() return HoneyDelveDB.ShowManaCrystalLine end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowManaCrystalLine = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                        },
                    },
                    displayGroup = {
                        type = "group", name = L.OPT_WQ_GROUP, order = 6, inline = true,
                        args = {
                            showBounty = {
                                type = "toggle", name = L.OPT_SHOW_BOUNTY, order = 1, width = "full",
                                get = function() return HoneyDelveDB.ShowBounty end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowBounty = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showWQGold = {
                                type = "toggle", name = L.OPT_SHOW_WQ_GOLD, order = 2, width = "full",
                                get = function() return HoneyDelveDB.ShowWQGold end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowWQGold = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showWQMarl = {
                                type = "toggle", name = ShowNameLabel("Marl"), order = 3, width = "full",
                                get = function() return HoneyDelveDB.ShowWQMarl end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowWQMarl = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showWQShard = {
                                type = "toggle", name = ShowNameLabel("KeyShard"), order = 4, width = "full",
                                get = function() return HoneyDelveDB.ShowWQShard end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowWQShard = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                            showZoneMeta = {
                                type = "toggle", name = L.OPT_SHOW_ZONE_META, order = 5, width = "full",
                                get = function() return HoneyDelveDB.ShowZoneMeta end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowZoneMeta = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                        },
                    },
                    delveBotGroup = {
                        type = "group", name = L.OPT_DELVEBOT_GROUP, order = 7, inline = true,
                        args = {
                            delveBotDesc = {
                                type = "description",
                                name = "|cffaaaaaa" .. L.OPT_DELVEBOT_DESC .. "|r",
                                order = 1, fontSize = "medium", width = "full",
                            },
                            autoDelveBot = {
                                type = "toggle", name = L.OPT_AUTO_DELVEBOT, order = 2, width = "full",
                                get = function() return HoneyDelveDB.AutoDelveBot end,
                                set = function(_, val) HoneyDelveDB.AutoDelveBot = val end,
                            },
                            autoDelveBotRequireBountiful = {
                                type = "toggle", name = L.OPT_REQUIRE_BOUNTIFUL, order = 3, width = "full",
                                desc = L.OPT_REQUIRE_BOUNTIFUL_DESC,
                                disabled = function() return not HoneyDelveDB.AutoDelveBot end,
                                get = function() return HoneyDelveDB.AutoDelveBotRequireBountiful end,
                                set = function(_, val) HoneyDelveDB.AutoDelveBotRequireBountiful = val end,
                            },
                        },
                    },
                    dundunGroup = {
                        type = "group", name = L.OPT_DUNDUN_GROUP, order = 8, inline = true,
                        args = {
                            dundunDesc = {
                                type = "description",
                                name = function() return "|cffaaaaaa" .. L.OPT_DUNDUN_DESC:format(addon.GetName("RestoredKey")) .. "|r" end,
                                order = 1, fontSize = "medium", width = "full",
                            },
                            showDundunKeyHint = {
                                type = "toggle", order = 2, width = "full",
                                name = function() return L.OPT_SHOW_DUNDUN_HINT:format(addon.GetName("RestoredKey")) end,
                                get = function() return HoneyDelveDB.ShowDundunKeyHint end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowDundunKeyHint = val
                                    HDT:UpdateDundunKeyHint()
                                end,
                            },
                        },
                    },
                    -- 잘못 놓여진 진귀품 버프 내용 표시 창
                    curioGroup = {
                        type = "group", name = CT("GROUP"), order = 9, inline = true,
                        args = {
                            curioDesc = {
                                type = "description",
                                name = function() return "|cffaaaaaa" .. CT("DESC"):format(GetCurioSpellName()) .. "|r" end,
                                order = 1, fontSize = "medium", width = "full",
                            },
                            showCurioBuff = {
                                type = "toggle", name = CT("SHOW"), order = 2, width = "full",
                                get = function() return HoneyDelveDB.ShowCurioBuff end,
                                set = function(_, val)
                                    HoneyDelveDB.ShowCurioBuff = val
                                    HDT:UpdateCurioBuff()
                                end,
                            },
                            curioLocked = {
                                type = "toggle", name = CT("LOCK"), order = 3, width = "full",
                                desc = CT("LOCK_DESC"),
                                disabled = function() return not HoneyDelveDB.ShowCurioBuff end,
                                get = function() return HoneyDelveDB.CurioBuffLocked end,
                                set = function(_, val)
                                    HoneyDelveDB.CurioBuffLocked = val
                                    HDT:UpdateCurioBuff()
                                end,
                            },
                            curioFontSize = {
                                type = "range", name = CT("FONT_SIZE"), order = 4, width = 1.5,
                                min = 10, max = 16, step = 1,
                                disabled = function() return not HoneyDelveDB.ShowCurioBuff end,
                                get = function() return HoneyDelveDB.CurioFontSize end,
                                set = function(_, val)
                                    HoneyDelveDB.CurioFontSize = val
                                    HDT:UpdateCurioBuff()
                                end,
                            },
                            curioAlpha = {
                                type = "range", name = CT("BG_ALPHA"), order = 5, width = 1.5,
                                min = 0, max = 1, step = 0.05,
                                disabled = function() return not HoneyDelveDB.ShowCurioBuff end,
                                get = function() return HoneyDelveDB.CurioAlpha end,
                                set = function(_, val)
                                    HoneyDelveDB.CurioAlpha = val
                                    HDT:UpdateCurioBuff()
                                end,
                            },
                            curioResetPos = {
                                type = "execute", name = CT("RESET_POS"), order = 6, width = 1.2,
                                desc = CT("RESET_POS_DESC"),
                                disabled = function() return not HoneyDelveDB.ShowCurioBuff end,
                                func = function() HDT:ResetCurioPosition() end,
                            },
                        },
                    },
                    layoutGroup = {
                        type = "group", name = L.OPT_LAYOUT_GROUP, order = 10, inline = true,
                        args = {
                            bgAlpha = {
                                type = "range", name = L.OPT_BG_ALPHA, order = 1, width = "full",
                                min = 0, max = 1, step = 0.05,
                                get = function() return HoneyDelveDB.Alpha end,
                                set = function(_, val)
                                    HoneyDelveDB.Alpha = val
                                    if HoneyDelveTodayFrame and HoneyDelveTodayFrame.CustomBg then
                                        HoneyDelveTodayFrame.CustomBg:SetColorTexture(0, 0, 0, val)
                                    end
                                end,
                            },
                            fontSize = {
                                type = "range", name = L.OPT_FONT_SIZE, order = 2, width = "full",
                                min = 10, max = 16, step = 2,
                                get = function() return HoneyDelveDB.FontSize end,
                                set = function(_, val)
                                    HoneyDelveDB.FontSize = val
                                    if HoneyDelveTodayFrame:IsShown() then HDT:UpdateDisplay() end
                                end,
                            },
                        },
                    },
                    keybindsGroup = {
                        type = "group", name = L.OPT_KEYBIND_GROUP, order = 11, inline = true,
                        args = {
                            bindDashboard = {
                                type = "keybinding", name = L.BINDING_DASHBOARD, order = 1, width = 1.5,
                                get = function() return GetBindingKey("HONEYDELVETODAY_DASHBOARD") end,
                                set = function(_, val)
                                    local oldKey = GetBindingKey("HONEYDELVETODAY_DASHBOARD")
                                    if oldKey then SetBinding(oldKey, nil) end
                                    SetBinding(val, "HONEYDELVETODAY_DASHBOARD")
                                    SaveBindings(GetCurrentBindingSet())
                                end,
                            },
                            bindConfig = {
                                type = "keybinding", name = L.BINDING_CONFIG, order = 2, width = 1.5,
                                get = function() return GetBindingKey("HONEYDELVETODAY_CONFIG") end,
                                set = function(_, val)
                                    local oldKey = GetBindingKey("HONEYDELVETODAY_CONFIG")
                                    if oldKey then SetBinding(oldKey, nil) end
                                    SetBinding(val, "HONEYDELVETODAY_CONFIG")
                                    SaveBindings(GetCurrentBindingSet())
                                end,
                            },
                        },
                    },
                    resetGroup = {
                        type = "group", name = L.OPT_DATA_GROUP, order = 12, inline = true,
                        args = {
                            resetDesc = {
                                type = "description",
                                name = "|cffff4444" .. L.OPT_RESET_WARNING .. "|r\n|cffaaaaaa" .. L.OPT_RESET_NOTE .. "|r",
                                order = 1, fontSize = "medium", width = "full",
                            },
                            resetData = {
                                type = "execute",
                                name = L.OPT_RESET_BUTTON,
                                desc = L.OPT_RESET_BUTTON_DESC,
                                order = 2, width = 1.5,
                                confirm = true,
                                confirmText = L.OPT_RESET_CONFIRM,
                                func = function()
                                    InitializeDB(true)
                                    AceConfigRegistry:NotifyChange(AddonName)
                                    HDT:UpdateDisplay()
                                    print("|cffffff00[HoneyDelveToday]|r " .. L.MSG_RESET_DONE)
                                end,
                            },
                        },
                    },
                },
            },
        },
    }
end

-- 지역/구렁/변형별 등급과 메모 설정 트리
-- 그룹 키는 언어와 무관한 값(mapID, 구렁 내부 키, 변형 ID)을 쓰고, 이름만 언어별로 표시한다.
local function BuildOptionsTree()
    local zoneOrder = {}
    for idx, zone in ipairs(ZoneList) do
        zoneOrder[zone.mapID] = idx + 1
    end
    for idx, dData in ipairs(DelveList) do
        local zoneMapID = dData.zone
        local zoneKey = "zone_" .. zoneMapID
        local delveKey = "delve_" .. dData.key
        if not options.args[zoneKey] then
            options.args[zoneKey] = {
                type = "group",
                name = function() return addon.GetZoneName(zoneMapID) end,
                order = zoneOrder[zoneMapID] or 10, childGroups = "tree",
                args = {
                    variantNameNote = {
                        type = "description",
                        name = "|cffaaaaaa" .. L.OPT_VARIANT_NAME_NOTE .. "|r",
                        order = 0, fontSize = "medium", width = "full",
                    },
                },
            }
        end
        if not options.args[zoneKey].args[delveKey] then
            options.args[zoneKey].args[delveKey] = {
                type = "group",
                name = function() return addon.GetDelveName(dData) end,
                order = idx, args = {}
            }
        end
        -- order를 DB.lua의 변형 순서로 고정한다. (지정하지 않으면 이름 순으로 정렬되어 언어마다 순서가 달라진다)
        for vIdx, vID in ipairs(dData.variants) do
            if addon.DefaultData[vID] then
                options.args[zoneKey].args[delveKey].args["id_" .. vID] = {
                    type = "group",
                    name = function()
                        local variantName = addon.GetVariantName(vID)
                        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(vID)
                        if info and info.text ~= "" then return "|cffffff00" .. STAR_MARK .. " " .. variantName .. "|r" end
                        return variantName
                    end,
                    order = vIdx,
                    inline = true,
                    args = {
                        grade = {
                            type = "select", name = L.OPT_GRADE, order = 1, width = 0.5,
                            values = {["S"]="S", ["A"]="A", ["B"]="B", ["C"]="C", ["D"]="D", ["F"]="F", ["-"]="-"},
                            sorting = {"S", "A", "B", "C", "D", "F", "-"},
                            get = function() return GetGrade(vID) end,
                            set = function(_, val) SetGrade(vID, val) AceConfigRegistry:NotifyChange(AddonName) HDT:UpdateDisplay() end,
                        },
                        memo = {
                            type = "input", name = L.OPT_MEMO, order = 2, width = 2.5,
                            get = function() return GetMemo(vID) end,
                            set = function(_, val) SetMemo(vID, val) AceConfigRegistry:NotifyChange(AddonName) HDT:UpdateDisplay() end,
                        },
                        memoReset = {
                            type = "execute", name = L.OPT_MEMO_RESET, order = 3, width = 0.6,
                            desc = L.OPT_MEMO_RESET_DESC,
                            disabled = function() return not HasMemoOverride(vID) end,
                            func = function() ResetMemo(vID) AceConfigRegistry:NotifyChange(AddonName) HDT:UpdateDisplay() end,
                        },
                    }
                }
            end
        end
    end
end

-- 알림 프레임 생성
-- graceAlert 자체는 EnableMouse(false)로 마우스 이벤트를 통과시킵니다.
-- 드래그는 별도 dragHandle 프레임으로, 닫기는 UIPanelCloseButton으로 분리해
-- Hide() 후에도 해당 영역 클릭이 가로채지는 버그를 방지합니다.
local graceAlert = CreateFrame("Frame", "HoneyDelveTodayGraceAlert", UIParent)
graceAlert:SetSize(260, 60)
graceAlert:SetFrameStrata("HIGH")
graceAlert:SetFrameLevel(200)
graceAlert:EnableMouse(false)
graceAlert:SetMovable(true)
graceAlert:Hide()

graceAlert.closedByUser = false

local graceAlertBg = graceAlert:CreateTexture(nil, "BACKGROUND")
graceAlertBg:SetAllPoints(graceAlert)
graceAlertBg:SetColorTexture(0, 0, 0, 0.85)

local graceAlertIcon = graceAlert:CreateTexture(nil, "ARTWORK")
graceAlertIcon:SetSize(36, 36)
graceAlertIcon:SetPoint("LEFT", graceAlert, "LEFT", 12, 0)
graceAlertIcon:SetTexture(1064187)

-- 알림 문구는 표시 언어와 아이템 이름이 정해진 뒤 UpdateGraceAlert에서 넣는다.
local graceAlertText = graceAlert:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
graceAlertText:SetPoint("LEFT", graceAlertIcon, "RIGHT", 10, 0)

-- 드래그 핸들 (프레임 전체 영역에서 드래그 가능)
local dragHandle = CreateFrame("Frame", nil, graceAlert)
dragHandle:SetAllPoints(graceAlert)
dragHandle:EnableMouse(true)
dragHandle:RegisterForDrag("LeftButton")
dragHandle:SetScript("OnDragStart", function() graceAlert:StartMoving() end)
dragHandle:SetScript("OnDragStop", function()
    graceAlert:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = graceAlert:GetPoint()
    HoneyDelveDB.GraceAlertPos = { point, relativePoint, xOfs, yOfs }
end)

-- X 닫기 버튼
local graceAlertClose = CreateFrame("Button", nil, graceAlert, "UIPanelCloseButton")
graceAlertClose:SetPoint("TOPRIGHT", graceAlert, "TOPRIGHT", 4, 4)
graceAlertClose:SetScript("OnClick", function()
    graceAlert.closedByUser = true
    graceAlert:Hide()
end)

function HDT:UpdateGraceAlert()
    -- 90레벨 미만 캐릭터에는 알림 미표시
    if UnitLevel("player") < 90 then
        graceAlert:Hide()
        return
    end
    local _, hasItem = GetBountyState()
    local _, instanceType = IsInInstance()
    -- 설정 ON + 아이템 보유 중 + 구렁(scenario) 내부 + 유저가 직접 닫지 않은 경우
    if HoneyDelveDB.ShowGraceAlert
        and hasItem
        and instanceType == "scenario"
        and not graceAlert.closedByUser
    then
        graceAlertText:SetText("|cffffff00" .. L.GRACE_ALERT:format(addon.GetName("Grace")) .. "|r")
        graceAlert:Show()
    else
        graceAlert:Hide()
    end
end

-- =========================================================
-- 잘못 놓여진 진귀품 버프 내용 표시 창
-- 버프(주문 ID 1280098)가 걸려 있으면 버프 툴팁의 설명 글자를 그대로 읽어 화면에 띄운다.
--   1. C_UnitAuras.GetPlayerAuraBySpellID로 버프를 찾는다.
--   2. C_TooltipInfo.GetUnitBuffByAuraInstanceID로 버프 툴팁 데이터를 받아
--      첫 줄(버프 이름)을 뺀 나머지 줄을 표시한다. (언어와 무관하게 게임이 주는 글자 그대로)
--   툴팁 데이터는 다른 애드온이 GameTooltip에 덧붙인 줄(SpellID, IconID 등)을 포함하지 않는다.
-- 위치 잠금을 풀면 버프가 없어도 미리보기로 나타나며 드래그로 옮길 수 있다.
-- 잠그면 마우스 클릭을 통과시킨다.
--
-- 구렁 안이나 전투 중에는 버프 정보가 보안값(secret value)으로 올 가능성이 있다. (12.x 제한, 인게임 확인 필요)
--   보안값 글자는 가공(줄 나누기, 이어 붙이기)하지 않고 글자 칸에 그대로 넣는다.
--   전투 중에 버프를 못 찾으면 조회가 막힌 것일 수 있으므로 표시를 유지하고 전투가 끝난 뒤 다시 확인한다.
-- =========================================================
local CURIO_PAD = 8                -- 창 안쪽 여백
local CURIO_ICON_SIZE = 20         -- 제목 줄 아이콘 크기
local CURIO_ICON_GAP = 6           -- 아이콘과 제목 사이 간격
local CURIO_TITLE_GAP = 4          -- 제목 줄과 설명 첫 줄 사이 간격
local CURIO_SECRET_WIDTH = 220     -- 보안값 글자라 너비를 잴 수 없을 때 쓰는 창 너비
local CURIO_SECRET_LINES = 9       -- 보안값 글자라 높이를 잴 수 없을 때 가정하는 줄 수
local CURIO_DEFAULT_POS = { "CENTER", "CENTER", 0, 200 }
local CURIO_RETRY_MAX = 5          -- 버프는 있는데 설명을 못 읽었을 때 재시도 횟수

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

-- 함수 결과가 일반 숫자면 그 값을, 오류나 보안값이면 대체값을 반환한다.
local function SafeNumber(fn, fallback)
    local ok, value = pcall(fn)
    if ok and type(value) == "number" and not IsSecret(value) then return value end
    return fallback
end

local function GetCurioIcon()
    local ok, tex = pcall(function()
        return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(CURIO_BUFF_SPELL_ID)
    end)
    if ok and not IsSecret(tex) and tex then return tex end
    return CURIO_BUFF_ICON_FALLBACK
end

local curioFrame = CreateFrame("Frame", "HoneyDelveTodayCurioFrame", UIParent)
curioFrame:SetSize(200, 60)
curioFrame:SetFrameStrata("MEDIUM")
curioFrame:SetFrameLevel(50)
curioFrame:SetClampedToScreen(true)
curioFrame:SetMovable(true)
curioFrame:EnableMouse(false)
curioFrame:Hide()
curioFrame.isPreview = false
curioFrame.lines = {}

curioFrame.bg = curioFrame:CreateTexture(nil, "BACKGROUND")
curioFrame.bg:SetAllPoints(curioFrame)
curioFrame.bg:SetColorTexture(0, 0, 0, 0.6)

curioFrame.icon = curioFrame:CreateTexture(nil, "ARTWORK")
curioFrame.icon:SetSize(CURIO_ICON_SIZE, CURIO_ICON_SIZE)
curioFrame.icon:SetPoint("TOPLEFT", curioFrame, "TOPLEFT", CURIO_PAD, -CURIO_PAD)

curioFrame.title = curioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
curioFrame.title:SetPoint("LEFT", curioFrame.icon, "RIGHT", CURIO_ICON_GAP, 0)
curioFrame.title:SetJustifyH("LEFT")
curioFrame.title:SetWordWrap(false)

-- 드래그 핸들: 잠금을 풀었을 때만 마우스를 받는다 (잠금 상태에서는 클릭이 아래로 통과)
local curioDrag = CreateFrame("Frame", nil, curioFrame)
curioDrag:SetAllPoints(curioFrame)
curioDrag:EnableMouse(false)
curioDrag:RegisterForDrag("LeftButton")
curioDrag:SetScript("OnDragStart", function()
    if HoneyDelveDB and not HoneyDelveDB.CurioBuffLocked then
        curioFrame:StartMoving()
    end
end)
curioDrag:SetScript("OnDragStop", function()
    curioFrame:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = curioFrame:GetPoint()
    HoneyDelveDB.CurioBuffPos = { point, relativePoint, xOfs, yOfs }
end)

local function ApplyCurioPosition()
    local p = HoneyDelveDB.CurioBuffPos or CURIO_DEFAULT_POS
    curioFrame:ClearAllPoints()
    curioFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

-- 진귀품 버프 찾기 (없거나 조회 실패 시 nil)
local function GetCurioAura()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return nil end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, CURIO_BUFF_SPELL_ID)
    if ok and type(aura) == "table" then return aura end
    return nil
end

-- 버프 툴팁에서 설명 줄 목록을 읽는다.
-- 반환값: 줄 목록, 보안값 포함 여부 / 읽을 줄이 없으면 nil
-- 일반 글자는 줄바꿈 기준으로 나누고 빈 줄은 뺀다. 보안값 글자는 나누지 않고 한 칸에 그대로 둔다.
local function ReadCurioLines(aura)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID) then return nil end
    local ok, result, hasSecret = pcall(function()
        local data = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", aura.auraInstanceID)
        if type(data) ~= "table" or type(data.lines) ~= "table" then return nil, false end
        local lines = {}
        local secret = false
        for i = 2, #data.lines do
            local text = data.lines[i] and data.lines[i].leftText
            if IsSecret(text) then
                secret = true
                lines[#lines + 1] = text
            elseif type(text) == "string" then
                for part in text:gmatch("[^\r\n]+") do
                    if part:match("%S") then lines[#lines + 1] = part end
                end
            end
        end
        if #lines == 0 then return nil, false end
        return lines, secret
    end)
    if ok and result then return result, hasSecret end
    return nil
end

local function GetCurioLineFont(index)
    local fs = curioFrame.lines[index]
    if not fs then
        fs = curioFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        curioFrame.lines[index] = fs
    end
    return fs
end

-- 창 내용을 그리고 크기를 내용에 맞춘다.
-- lines: 설명 줄 목록, isPreview: 위치 조정용 미리보기 여부
local function RenderCurio(lines, isPreview)
    local fontPath, _, fontFlags = GameFontNormal:GetFont()
    local fontSize = HoneyDelveDB.CurioFontSize or 12
    local lineHeight = fontSize + 2

    curioFrame.bg:SetColorTexture(0, 0, 0, HoneyDelveDB.CurioAlpha or 0.6)
    curioFrame.icon:SetTexture(GetCurioIcon())

    local titleText = "|cffffd100" .. GetCurioSpellName() .. "|r"
    if isPreview then
        titleText = titleText .. " |cffaaaaaa" .. CT("PREVIEW") .. "|r"
    end
    curioFrame.title:SetFont(fontPath, fontSize + 1, fontFlags)
    curioFrame.title:SetText(titleText)

    local maxWidth = CURIO_ICON_SIZE + CURIO_ICON_GAP
        + SafeNumber(function() return curioFrame.title:GetStringWidth() end, 100)
    local y = CURIO_PAD + CURIO_ICON_SIZE + CURIO_TITLE_GAP

    for i, text in ipairs(lines) do
        local fs = GetCurioLineFont(i)
        fs:SetFont(fontPath, fontSize, fontFlags)
        fs:SetTextColor(1, 1, 1)
        fs:SetText(text)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", curioFrame, "TOPLEFT", CURIO_PAD, -y)
        fs:Show()
        local width, height
        if IsSecret(text) then
            width = SafeNumber(function() return fs:GetStringWidth() end, CURIO_SECRET_WIDTH)
            height = SafeNumber(function() return fs:GetStringHeight() end, lineHeight * CURIO_SECRET_LINES)
        else
            width = SafeNumber(function() return fs:GetStringWidth() end, CURIO_SECRET_WIDTH)
            height = lineHeight
        end
        if width > maxWidth then maxWidth = width end
        y = y + height
    end

    -- 이번에 쓰지 않은 줄은 숨김
    for i = #lines + 1, #curioFrame.lines do
        curioFrame.lines[i]:Hide()
    end

    curioFrame:SetSize(maxWidth + CURIO_PAD * 2, y + CURIO_PAD)
end

local function ShowCurioPreview()
    local cache = HoneyDelveDB.CurioBuffCache
    local lines = (type(cache) == "table" and #cache > 0) and cache or { CT("SAMPLE") }
    RenderCurio(lines, true)
    curioFrame.isPreview = true
    curioFrame:Show()
end

local curioRetryCount = 0
local curioUpdatePending = false

function HDT:UpdateCurioBuff()
    if not HoneyDelveDB then return end
    curioDrag:EnableMouse(not HoneyDelveDB.CurioBuffLocked)

    if not HoneyDelveDB.ShowCurioBuff then
        curioFrame:Hide()
        return
    end

    local aura = GetCurioAura()
    if aura then
        local lines, hasSecret = ReadCurioLines(aura)
        if lines then
            curioRetryCount = 0
            -- 보안값이 섞이지 않은 경우에만 저장 (미리보기에 사용)
            if not hasSecret then HoneyDelveDB.CurioBuffCache = lines end
            RenderCurio(lines, false)
            curioFrame.isPreview = false
            curioFrame:Show()
            return
        end
        -- 버프는 있는데 설명을 아직 못 읽은 경우 (툴팁 데이터 로드 전 등): 잠시 후 다시 시도
        if curioRetryCount < CURIO_RETRY_MAX then
            curioRetryCount = curioRetryCount + 1
            C_Timer.After(0.5, function() HDT:UpdateCurioBuff() end)
        end
        if curioFrame:IsShown() and not curioFrame.isPreview then return end
        RenderCurio({ "..." }, false)
        curioFrame.isPreview = false
        curioFrame:Show()
        return
    end

    curioRetryCount = 0
    -- 전투 중에 버프를 못 찾으면 조회가 막힌 것일 수 있으므로 지금 표시를 유지한다 (전투 종료 후 다시 확인)
    if InCombatLockdown() and curioFrame:IsShown() and not curioFrame.isPreview then
        return
    end

    if not HoneyDelveDB.CurioBuffLocked then
        ShowCurioPreview()
    else
        curioFrame:Hide()
    end
end

function HDT:ResetCurioPosition()
    HoneyDelveDB.CurioBuffPos = nil
    ApplyCurioPosition()
end

-- 버프 변동(UNIT_AURA)은 자주 발생하므로 0.2초에 한 번만 갱신한다.
local function ScheduleCurioUpdate()
    if curioUpdatePending then return end
    curioUpdatePending = true
    C_Timer.After(0.2, function()
        curioUpdatePending = false
        HDT:UpdateCurioBuff()
    end)
end

-- 플레이어 버프 변동만 받기 위해 별도 프레임에서 RegisterUnitEvent를 쓴다. (등록은 OnInitialize에서)
local curioEventFrame = CreateFrame("Frame")
curioEventFrame:SetScript("OnEvent", function() ScheduleCurioUpdate() end)

local f = CreateFrame("Frame", "HoneyDelveTodayFrame", UIParent)
f:SetSize(360, 640)
f:SetPoint("CENTER")
f:Hide()
f:SetFrameStrata("MEDIUM")
f:SetFrameLevel(100)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
tinsert(UISpecialFrames, f:GetName())

local customBg = f:CreateTexture(nil, "BACKGROUND")
customBg:SetAllPoints(f)
customBg:SetColorTexture(0, 0, 0, 0.8)
f.CustomBg = customBg

-- 제목 글자는 표시 언어가 정해진 뒤 OnInitialize에서 넣는다.
f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
f.Title:SetPoint("TOP", f, "TOP", 0, -10)

local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

local memoBtn = CreateFrame("Button", nil, f)
memoBtn:SetSize(20, 20)
memoBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", 0, -6)
memoBtn.text = memoBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
memoBtn.text:SetAllPoints()
memoBtn.text:SetText("M")
memoBtn:SetScript("OnClick", function()
    HoneyDelveDB.ShowMemo = not HoneyDelveDB.ShowMemo
    AceConfigRegistry:NotifyChange(AddonName)
    HDT:UpdateDisplay()
end)

-- =========================================================
-- 대시보드 줄 단위 레이아웃
-- 한 줄을 아이콘(Texture), 글자(FontString), 간격 조각으로 나눠 직접 배치한다.
-- 모든 조각을 줄의 세로 중앙에 맞춰 붙이므로 아이콘과 글자가 항상 가운데 맞춤이 되고,
-- 줄 높이를 코드에서 직접 정하므로 프레임 높이가 실제 그려진 높이와 일치한다.
-- (이전 방식: 문자열 하나에 인라인 아이콘을 넣고 GetStringHeight로 높이를 계산했는데,
--  인라인 아이콘 정렬은 픽셀 오프셋을 추정해야 했고, 높이가 실제보다 크게 측정되어 아래 여백이 남았다)
-- =========================================================
local LAYOUT_PAD_LEFT = 20        -- 왼쪽 여백
local LAYOUT_PAD_RIGHT = 30       -- 오른쪽 여백
local LAYOUT_PAD_TOP = 45         -- 프레임 위쪽에서 첫 줄까지 거리 (제목 영역)
local LAYOUT_PAD_BOTTOM = 20      -- 마지막 줄 아래 여백
local LAYOUT_ROW_SPACING = 2      -- 줄 사이 간격
local LAYOUT_LEAD_ICON_GAP = 6    -- 줄 맨 앞 아이콘과 글자 사이 간격
local LAYOUT_INLINE_ICON_GAP = 2  -- 줄 중간 아이콘(상태/보상 아이콘)과 글자 사이 간격
local LAYOUT_TEXT_Y_NUDGE = 0     -- 글자 세로 위치 미세 조정 (음수 = 아래로, 양수 = 위로)

local rowFrames = {}

-- 줄 구성 정보(spec) 작성 도우미
-- spec은 줄 목록이며, 각 줄은 조각 목록이거나 { blank = true }(빈 줄)이다.
local function NewRow(spec)
    local row = {}
    spec[#spec + 1] = row
    return row
end

local function AddBlankRow(spec)
    spec[#spec + 1] = { blank = true }
end

-- 아이콘 조각: tex는 파일 ID 또는 경로, isAtlas가 true면 아틀라스 이름
-- gap은 아이콘 오른쪽 간격 (생략 시 LAYOUT_INLINE_ICON_GAP)
local function AddIcon(row, tex, size, gap, isAtlas)
    row[#row + 1] = { kind = "icon", tex = tex, size = size, gap = gap or LAYOUT_INLINE_ICON_GAP, isAtlas = isAtlas }
end

-- 글자 조각 (색상 코드 사용 가능)
-- 주의: 공백만 있는 문자열이나 끝 공백은 너비 측정이 불안정할 수 있으므로 간격은 AddGap을 사용한다.
local function AddText(row, text)
    row[#row + 1] = { kind = "text", text = text }
end

-- 빈 간격 조각
local function AddGap(row, width)
    row[#row + 1] = { kind = "gap", width = width }
end

local function GetRowFrame(index)
    local row = rowFrames[index]
    if not row then
        row = CreateFrame("Frame", nil, f)
        row.textures = {}
        row.fonts = {}
        rowFrames[index] = row
    end
    return row
end

-- spec을 실제 화면에 그리고, 내용에 맞춰 대시보드 크기를 조정한다.
local function RenderRows(spec, fontSize)
    local fontPath, _, fontFlags = GameFontNormal:GetFont()
    local textRowHeight = fontSize + 2
    local blankRowHeight = math.max(fontSize - 2, 4)
    local y = 0
    local maxWidth = 0

    for i, rowSpec in ipairs(spec) do
        local row = GetRowFrame(i)
        for _, tex in ipairs(row.textures) do tex:Hide() end
        for _, fs in ipairs(row.fonts) do fs:Hide() end

        local rowHeight
        local x = 0
        if rowSpec.blank then
            rowHeight = blankRowHeight
        else
            -- 줄 높이 = 글자 줄 높이와 이 줄의 아이콘 중 가장 큰 값
            rowHeight = textRowHeight
            for _, seg in ipairs(rowSpec) do
                if seg.kind == "icon" and seg.size > rowHeight then rowHeight = seg.size end
            end

            local texIndex, fontIndex = 0, 0
            for _, seg in ipairs(rowSpec) do
                if seg.kind == "icon" then
                    texIndex = texIndex + 1
                    local tex = row.textures[texIndex]
                    if not tex then
                        tex = row:CreateTexture(nil, "ARTWORK")
                        row.textures[texIndex] = tex
                    end
                    if seg.isAtlas then
                        -- 존재하지 않는 아틀라스면 빈 칸으로 두어 글자 시작 위치만 맞춘다
                        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(seg.tex) then
                            tex:SetAtlas(seg.tex)
                        else
                            tex:SetTexture(nil)
                        end
                    else
                        tex:SetTexture(seg.tex)
                        tex:SetTexCoord(0, 1, 0, 1)
                    end
                    tex:SetSize(seg.size, seg.size)
                    tex:ClearAllPoints()
                    tex:SetPoint("LEFT", row, "LEFT", x, 0)
                    tex:Show()
                    x = x + seg.size + seg.gap
                elseif seg.kind == "gap" then
                    x = x + seg.width
                else
                    fontIndex = fontIndex + 1
                    local fs = row.fonts[fontIndex]
                    if not fs then
                        fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        fs:SetJustifyH("LEFT")
                        fs:SetWordWrap(false)
                        row.fonts[fontIndex] = fs
                    end
                    fs:SetFont(fontPath, fontSize, fontFlags)
                    fs:SetText(seg.text)
                    fs:ClearAllPoints()
                    fs:SetPoint("LEFT", row, "LEFT", x, LAYOUT_TEXT_Y_NUDGE)
                    fs:Show()
                    x = x + fs:GetStringWidth()
                end
            end
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT_PAD_LEFT, -(LAYOUT_PAD_TOP + y))
        row:SetSize(math.max(x, 1), rowHeight)
        row:Show()

        y = y + rowHeight + LAYOUT_ROW_SPACING
        if x > maxWidth then maxWidth = x end
    end

    -- 이번에 쓰지 않은 줄은 숨김 (설정에서 표시 항목을 끈 경우 등)
    for i = #spec + 1, #rowFrames do
        rowFrames[i]:Hide()
    end

    local contentHeight = 0
    if #spec > 0 then contentHeight = y - LAYOUT_ROW_SPACING end
    f:SetSize(math.max(360, maxWidth + LAYOUT_PAD_LEFT + LAYOUT_PAD_RIGHT), LAYOUT_PAD_TOP + contentHeight + LAYOUT_PAD_BOTTOM)
end

local GOLD_WQ_THRESHOLD = 5000000 -- 500골드 이상 (copper 기준)
local MARL_CURRENCY_ID = 3316     -- 공허불빛 이회토
local SHARD_CURRENCY_ID = 3310    -- 금고 열쇠 파편

-- =========================================================
-- 특별 과제 (언어와 무관하게 ID로 판정)
-- 반환값: done=true(해제됨, 수행 가능), done=false+progress=N(잠김, N/3 진행), nil(없음)
--
-- 해제 후: 특별 과제가 전역 퀘스트로 지도에 나온다.
--   1순위: 퀘스트 태그의 worldQuestType이 Enum.QuestTagType.Capstone인지 확인 (언어 무관)
--          Enum에 Capstone 값이 없는 클라이언트에서는 건너뛴다.
--   2순위: 퀘스트 제목이 클라이언트 언어의 SpecialAssignmentTitle("특별 과제:")로 시작하는지 확인
-- 잠김: 지역 지도에 Capstone 아이콘(atlas 이름에 Capstone 포함)이 있다.
--   남은 전역 퀘스트 수는 DB.lua의 metaWidgets 위젯 글자에서 숫자만 읽는다.
--   (이전에는 위젯 글자에 지역 이름이 들어 있는지 비교했는데, 영어 위젯은 "in Eversong"처럼
--    지도 이름 "Eversong Woods"와 다른 표기를 써서 찾지 못했다)
--   잠김 아이콘의 툴팁 위젯 묶음(widgetSetID, tooltipWidgetSet)에 metaWidgets 중 하나가 들어 있으면
--   그 위젯을 우선 사용한다. 이번 주 특별 과제의 위젯을 정확히 고르기 위해서이다.
--   묶음 정보를 못 얻으면 metaWidgets 전체에서 0이 아닌 값을 우선 채택하고, 전부 0이면 0으로 처리한다.
-- =========================================================
local META_TOTAL = 3

local function IsSpecialAssignmentQuest(questID)
    local capstoneType = Enum and Enum.QuestTagType and Enum.QuestTagType.Capstone
    if capstoneType and C_QuestLog.GetQuestTagInfo then
        local ok, tagInfo = pcall(C_QuestLog.GetQuestTagInfo, questID)
        if ok and tagInfo and tagInfo.worldQuestType == capstoneType then
            return true
        end
    end
    local titlePrefix = addon.GetGameText("SpecialAssignmentTitle")
    if titlePrefix then
        local title = C_TaskQuest.GetQuestInfoByQuestID(questID)
        if type(title) == "string" and title:find(titlePrefix, 1, true) == 1 then
            return true
        end
    end
    return false
end

-- 위젯 글자에서 첫 번째 숫자를 읽는다 ("전역 퀘스트 1개를 완료하면 해제", "Complete 1 world quest ...")
local function ReadMetaWidgetNumber(widgetID)
    local ok, text = pcall(function()
        local w = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgetID)
        return w and w.text
    end)
    if not ok or type(text) ~= "string" or text == "" then return nil end
    return tonumber(text:match("%d+"))
end

-- 잠김 아이콘의 툴팁 위젯 묶음에 들어 있는 위젯 ID 목록 (조회 실패 시 빈 목록)
local function GetPOIWidgetIDs(info)
    local ids = {}
    if not (C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID) then return ids end
    for _, setID in ipairs({ info.tooltipWidgetSet, info.widgetSetID }) do
        if type(setID) == "number" and setID > 0 then
            local ok, widgets = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, setID)
            if ok and type(widgets) == "table" then
                for _, w in ipairs(widgets) do
                    if w.widgetID then ids[#ids + 1] = w.widgetID end
                end
            end
        end
    end
    return ids
end

-- 지역에 속한 지도 ID 목록 (대표 지도 먼저, 나머지 allowedMaps는 ID 순)
local function GetZoneMapIDs(zone)
    local ids = { zone.mapID }
    local others = {}
    for mapID in pairs(zone.allowedMaps or {}) do
        if mapID ~= zone.mapID then others[#others + 1] = mapID end
    end
    table.sort(others)
    for _, mapID in ipairs(others) do ids[#ids + 1] = mapID end
    return ids
end

-- 다른 지역 지도에서 이 아이콘이 주 지도(isPrimaryMapForPOI가 false가 아님)로 나오는지 확인
local function IsPrimaryInOtherZone(zone, poiID)
    for _, other in ipairs(ZoneList) do
        if other ~= zone then
            for _, mapID in ipairs(GetZoneMapIDs(other)) do
                for _, id in ipairs(C_AreaPoiInfo.GetAreaPOIForMap(mapID) or {}) do
                    if id == poiID then
                        local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                        if info and info.isPrimaryMapForPOI ~= false then return true end
                    end
                end
            end
        end
    end
    return false
end

-- 지역의 metaWidgets 중 남은 전역 퀘스트 수가 1 이상인 위젯이 있는지 확인
-- 잠김 상태이면 남은 수가 1 이상이어야 하므로, 주 지도 정보가 애매한 아이콘을 이 지역 것으로 볼지 정할 때 쓴다.
local function HasPendingMetaWidget(zone)
    for _, wID in ipairs(zone.metaWidgets or {}) do
        local n = ReadMetaWidgetNumber(wID)
        if n and n > 0 then return true end
    end
    return false
end

-- 지역의 잠김 아이콘 정보 목록
-- 대표 지도뿐 아니라 allowedMaps의 하위 지역 지도에서도 찾는다. 같은 아이콘은 한 번만 넣는다.
-- isPrimaryMapForPOI가 false인 아이콘은 아래 두 조건을 모두 만족할 때만 이 지역 것으로 본다.
--   1. 다른 지역 지도에서 그 아이콘이 주 지도로 나오지 않는다.
--   2. 이 지역 metaWidgets에 남은 전역 퀘스트 수가 1 이상인 위젯이 있다.
-- (2026-10-12: 공허폭풍 잠김 아이콘 8585는 공허폭풍 안에서 조회해도 2405에서 false로 나오고,
--  상위 지도 쿠엘탈라스 2537에는 없어서, false만 보고 제외하면 공허폭풍 특별 과제를 찾지 못했다)
local function GetCapstonePOIs(zone)
    local result = {}
    local seen = {}
    for _, mapID in ipairs(GetZoneMapIDs(zone)) do
        local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
        for _, poiID in ipairs(pois or {}) do
            if not seen[poiID] then
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info and info.atlasName and info.atlasName:find("Capstone") then
                    if info.isPrimaryMapForPOI ~= false
                        or (not IsPrimaryInOtherZone(zone, poiID) and HasPendingMetaWidget(zone)) then
                        seen[poiID] = true
                        info.areaPoiID = info.areaPoiID or poiID
                        info.foundMapID = mapID
                        result[#result + 1] = info
                    end
                end
            end
        end
    end
    return result
end

local function GetMetaRemaining(zone, poiInfo)
    local listed = {}
    for _, wID in ipairs(zone.metaWidgets or {}) do listed[wID] = true end

    -- 1순위: 잠김 아이콘 툴팁에 들어 있는 metaWidgets 위젯
    for _, wID in ipairs(GetPOIWidgetIDs(poiInfo)) do
        if listed[wID] then
            local n = ReadMetaWidgetNumber(wID)
            if n then return n end
        end
    end

    -- 2순위: metaWidgets 전체에서 0이 아닌 값 우선
    local found = nil
    for _, wID in ipairs(zone.metaWidgets or {}) do
        local n = ReadMetaWidgetNumber(wID)
        if n then
            if n > 0 then return n end
            if found == nil then found = n end
        end
    end
    return found
end

local function GetZoneMetaState(zone, quests)
    local allowed = zone.allowedMaps
    for _, v in ipairs(quests) do
        if allowed[v.mapID] and C_QuestLog.IsWorldQuest(v.questID) and IsSpecialAssignmentQuest(v.questID) then
            return true, META_TOTAL
        end
    end

    local capstones = GetCapstonePOIs(zone)
    if #capstones > 0 then
        local remaining = GetMetaRemaining(zone, capstones[1])
        if remaining then
            return false, math.max(0, META_TOTAL - remaining)
        end
        -- 위젯을 읽지 못한 경우 잠김 상태만 표시
        return false, 0
    end
    return nil, 0
end

-- /hdt locale에서 쓰도록 공개
addon.IsSpecialAssignmentQuest = IsSpecialAssignmentQuest
addon.GetCapstonePOIs = GetCapstonePOIs
addon.GetZoneMapIDs = GetZoneMapIDs
addon.GetPOIWidgetIDs = GetPOIWidgetIDs
addon.GetZoneMetaState = GetZoneMetaState

local function GetZoneWQSummary(zone)
    local quests = C_TaskQuest.GetQuestsOnMap(zone.mapID)
    if not quests then return 0, 0, 0, 0, 0, 0, nil, 0, false end
    local goldCount, totalGold = 0, 0
    local marlCount, totalMarl = 0, 0
    local shardCount, totalShard = 0, 0
    local allowed = zone.allowedMaps
    local isLoading = false
    for _, v in ipairs(quests) do
        if allowed[v.mapID] and C_QuestLog.IsWorldQuest(v.questID) then
            -- 퀘스트 정보 로드 여부 판단: GetQuestInfoByQuestID가 nil이면 미로드
            local title = C_TaskQuest.GetQuestInfoByQuestID(v.questID)
            if title == nil then
                isLoading = true
            else
                local gold = GetQuestLogRewardMoney(v.questID) or 0
                if gold >= GOLD_WQ_THRESHOLD then
                    goldCount = goldCount + 1
                    totalGold = totalGold + math.floor(gold / 10000)
                end
                local currencies = C_QuestLog.GetQuestRewardCurrencies and C_QuestLog.GetQuestRewardCurrencies(v.questID)
                if currencies then
                    for _, c in ipairs(currencies) do
                        if c.currencyID == MARL_CURRENCY_ID then
                            marlCount = marlCount + 1
                            totalMarl = totalMarl + (c.totalRewardAmount or c.rewardAmount or 0)
                        elseif c.currencyID == SHARD_CURRENCY_ID then
                            shardCount = shardCount + 1
                            totalShard = totalShard + (c.totalRewardAmount or c.rewardAmount or 0)
                        end
                    end
                end
            end
        end
    end
    local metaDone, metaProgress = GetZoneMetaState(zone, quests)
    return goldCount, totalGold, marlCount, totalMarl, shardCount, totalShard, metaDone, metaProgress, isLoading
end

-- 구렁 이름, 오늘 활성 변형 이름, 화폐/아이템 이름을 게임에서 읽어 이름 캐시에 저장한다.
-- 대시보드를 열지 않아도 설정창에 오늘 본 변형 이름이 남도록 접속할 때 한 번 호출한다.
-- (조회 함수가 이름을 읽을 때 캐시에 저장하므로 여기서는 조회만 하면 된다)
function HDT:RefreshNameCache()
    for _, d in ipairs(DelveList) do
        addon.GetDelveName(d)
        for _, vID in ipairs(d.variants) do
            addon.GetVariantName(vID)
        end
    end
    for _, key in ipairs(addon.NAME_SOURCE_ORDER) do
        addon.GetName(key)
    end
end

-- 모든 지역의 전역퀘 요약을 계산해 WQCache에 채워둔다.
-- 대시보드가 열려있지 않아도 호출 가능하며, 일부 퀘스트 데이터가
-- 아직 서버에서 로드되지 않은 경우(isLoading) 짧은 간격으로 재시도한다.
function HDT:RefreshWQCache()
    local anyLoading = false
    for _, zone in ipairs(ZoneList) do
        local goldCount, totalGold, marlCount, totalMarl, shardCount, totalShard, metaDone, metaProgress, isLoading =
            GetZoneWQSummary(zone)
        if isLoading then
            anyLoading = true
        else
            WQCache[zone.mapID] = {
                goldCount = goldCount, totalGold = totalGold,
                marlCount = marlCount, totalMarl = totalMarl,
                shardCount = shardCount, totalShard = totalShard,
                metaDone = metaDone, metaProgress = metaProgress,
            }
        end
    end
    if f:IsShown() then HDT:UpdateDisplay() end
    if anyLoading then
        if not wqRetryTicker then
            wqRetryTicker = C_Timer.NewTicker(2, function()
                HDT:RefreshWQCache()
            end, 10) -- 최대 10회(20초) 재시도 후 자동 중단
        end
    else
        if wqRetryTicker then
            wqRetryTicker:Cancel()
            wqRetryTicker = nil
        end
    end
end


-- 신화 안개문장 아이콘: 화폐 정보의 iconFileID 사용, 조회 실패 시 아이콘 경로로 대체
local function GetMythCrestIcon()
    local info = C_CurrencyInfo.GetCurrencyInfo(MYTH_CREST_CURRENCY_ID)
    if info and info.iconFileID then return info.iconFileID end
    return MYTH_CREST_ICON_FALLBACK
end

-- 둔둔의 조각 아이콘: 화폐 정보의 iconFileID 사용, 조회 실패 시 nil(기존 아틀라스 아이콘으로 대체)
local function GetDundunShardIcon()
    local info = C_CurrencyInfo.GetCurrencyInfo(DUNDUN_SHARD_CURRENCY_ID)
    if info and info.iconFileID then return info.iconFileID end
    return nil
end

-- "이름 : 값" 형식의 흰 글자 (언어별 구분자: 한국어 " : ", 영어 ": ")
local function LabelValue(label, value)
    return "|cffffffff" .. L.FMT_LABEL_VALUE:format(label, value) .. "|r"
end

-- 신화 안개문장 보관함 줄 추가
local function AddGildedStashRow(spec)
    local row = NewRow(spec)
    AddIcon(row, GetMythCrestIcon(), 20, LAYOUT_LEAD_ICON_GAP)
    local label = GetStashLabel()
    local widget = C_UIWidgetManager.GetSpellDisplayVisualizationInfo(GILDED_STASH_SPELL_ID)
    if widget and widget.spellInfo and widget.spellInfo.tooltip then
        local _, fulfilled = widget.spellInfo.tooltip:match("COLOR:([^%d]*(%d)/4)")
        fulfilled = tonumber(fulfilled) or 0
        -- API에서 값을 가져왔으면 캐싱
        HoneyDelveDB.GildedStashCache = fulfilled
        AddText(row, LabelValue(label, fulfilled .. " / 4"))
        return
    end
    -- API 확인 불가 시 캐싱된 값 사용
    if HoneyDelveDB.GildedStashCache ~= nil then
        AddText(row, LabelValue(label, HoneyDelveDB.GildedStashCache .. " / 4"))
        return
    end
    AddText(row, "|cffffffff" .. label .. " |r |cffaaaaaa" .. L.STASH_IN_DELVE .. "|r")
end

-- 위대한 금고 "세계" 행 정보를 대시보드 줄로 추가한다.
-- 형식: (아이콘) 위대한 금고 영웅템 주차 : 3칸 (8/8) | 11레벨(5) 8레벨(3)
-- N칸: 8레벨 이상 활동만으로 열린 금고 보상 칸 수 (기준치 2/4/8)
-- (a/b): 8레벨 이상 활동 횟수 / 최대 기준치
-- 상위 활동은 C_WeeklyRewards.GetSortedProgressForActivity(6, true)로 조회하며,
-- 반환값 각 항목은 { activityTierID, difficulty, numPoints } 구조이다. (인게임 dump로 확인)
-- 동일 레벨은 한 번 더 합산하고, 최대 기준치(8)까지만 높은 레벨 순으로 잘라서 표시한다.
local VAULT_HERO_LEVEL = 8

local function AddVaultWorldRow(spec)
    local row = NewRow(spec)
    AddIcon(row, VAULT_ICON, 20, LAYOUT_LEAD_ICON_GAP)
    local header = LabelValue(L.VAULT_HEADER, "")
    local unavailable = header .. "|cffaaaaaa" .. L.UNAVAILABLE .. "|r"
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities or not C_WeeklyRewards.GetSortedProgressForActivity then
        AddText(row, unavailable)
        return
    end

    local activities = C_WeeklyRewards.GetActivities(VAULT_WORLD_TYPE)
    if not activities or #activities == 0 then
        AddText(row, unavailable)
        return
    end

    -- 금고 보상 칸 기준치 (보통 2, 4, 8)
    local thresholds = {}
    local maxThreshold = 0
    for _, act in ipairs(activities) do
        local th = act.threshold or 0
        if th > 0 then
            thresholds[#thresholds + 1] = th
            if th > maxThreshold then maxThreshold = th end
        end
    end
    if maxThreshold == 0 then
        AddText(row, unavailable)
        return
    end

    -- 상위 활동을 레벨별로 합산
    local sorted = C_WeeklyRewards.GetSortedProgressForActivity(VAULT_WORLD_TYPE, true)
    local byDifficulty = {}
    local diffList = {}
    if sorted then
        for _, tier in ipairs(sorted) do
            local diff = tier.difficulty or 0
            local pts = tier.numPoints or 0
            if pts > 0 then
                if not byDifficulty[diff] then
                    byDifficulty[diff] = 0
                    diffList[#diffList + 1] = diff
                end
                byDifficulty[diff] = byDifficulty[diff] + pts
            end
        end
    end
    table.sort(diffList, function(a, b) return a > b end)

    -- 높은 레벨 순으로 최대 기준치까지 잘라서 8레벨 이상 활동만 목록 작성 + 횟수 집계
    -- (8레벨 미만은 금고 칸을 채워도 영웅템이 아니므로 목록과 횟수 모두에서 제외)
    local remaining = maxThreshold
    local heroCount = 0
    local parts = {}
    for _, diff in ipairs(diffList) do
        if remaining <= 0 then break end
        local cnt = math.min(byDifficulty[diff], remaining)
        if diff >= VAULT_HERO_LEVEL then
            parts[#parts + 1] = L.VAULT_LEVEL_FMT:format(diff, cnt)
            heroCount = heroCount + cnt
        end
        remaining = remaining - cnt
    end

    -- 8레벨 이상 활동만으로 열린 칸 수
    local heroSlots = 0
    for _, th in ipairs(thresholds) do
        if heroCount >= th then heroSlots = heroSlots + 1 end
    end

    local topText
    if #parts > 0 then
        topText = "|cffffffff" .. table.concat(parts, " ") .. "|r"
    else
        topText = "|cffaaaaaa" .. L.NONE .. "|r"
    end

    -- 영어처럼 단수/복수가 다른 언어를 위해 1칸일 때는 VAULT_SLOT_FMT를 쓴다 (한국어는 두 값이 같다)
    local slotsFmt = (heroSlots == 1) and L.VAULT_SLOT_FMT or L.VAULT_SLOTS_FMT
    AddText(row, header .. "|cffffffff" .. slotsFmt:format(heroSlots, heroCount, maxThreshold) .. "|r |cff808080|||r " .. topText)
end

-- 정순한 마나 수정 줄 추가
-- 형식: (아이콘) 정순한 마나 수정 : 보유량 (이번주획득량 / 250)
local function AddManaCrystalRow(spec)
    local info = C_CurrencyInfo.GetCurrencyInfo(MANA_CRYSTAL_CURRENCY_ID)
    if not info then return end
    local quantity = info.quantity or 0
    local weeklyProg = info.quantityEarnedThisWeek or 0
    local maxWeekly = info.maxWeeklyQuantity or 0
    if maxWeekly <= 0 then maxWeekly = MANA_CRYSTAL_WEEKLY_CAP_FALLBACK end
    local row = NewRow(spec)
    AddIcon(row, info.iconFileID, 20, LAYOUT_LEAD_ICON_GAP)
    AddText(row, LabelValue(addon.GetName("ManaCrystal"), quantity .. " (" .. weeklyProg .. " / " .. maxWeekly .. ")"))
end

-- 천 단위 쉼표 표기 (예: 1976 은 1,976 으로 표시)
local function FormatThousands(num)
    local s = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return s
end

-- 지역 헤더 보상 아이콘 크기, 상단 추적요소 아이콘 크기 등
local ICON_SIZE_TRACKER = 20  -- 상단 추적요소 아이콘
local ICON_SIZE_STATUS = 16   -- 상태 아이콘 (체크/X/느낌표)
local ICON_SIZE_DELVE = 18    -- 구렁 풍요 아이콘
local ICON_SIZE_HEADER = 14   -- 지역 헤더 보상 아이콘
local DELVE_ICON_GAP = 4      -- 구렁 풍요 아이콘과 구렁 이름 사이 간격
local HEADER_ITEM_GAP = 8     -- 지역 헤더 보상 항목 사이 간격
local STATUS_LABEL_GAP = 4    -- "보물 추적자의 은혜" 같은 이름과 상태 아이콘 사이 간격

-- 상태 줄(이름 + 상태 아이콘 + 상태 글자) 추가
local function AddStatusRow(spec, iconTex, iconIsAtlas, label, statusIcon, statusText)
    local row = NewRow(spec)
    AddIcon(row, iconTex, ICON_SIZE_TRACKER, LAYOUT_LEAD_ICON_GAP, iconIsAtlas)
    AddText(row, label)
    AddGap(row, STATUS_LABEL_GAP)
    AddIcon(row, statusIcon, ICON_SIZE_STATUS)
    AddText(row, statusText)
end

-- 지역 헤더 보상 항목(간격 + 아이콘 + 글자) 추가
local function AddHeaderReward(row, iconTex, text)
    AddGap(row, HEADER_ITEM_GAP)
    AddIcon(row, iconTex, ICON_SIZE_HEADER, 1)
    AddText(row, text)
end

-- =========================================================
-- 구렁 지도 아이콘 찾기와 풍요 판정
-- 구렁마다 일반 상태와 풍요 상태의 아이콘 ID가 다르므로 DB.lua의 poiIDs 중 지금 지도에 있는 것을 찾는다.
-- 1순위: DB.lua의 poiIDs / 2순위: 이전에 자동 학습한 ID(HoneyDelveDB.LearnedPOIs)
-- 3순위(자동 학습): 같은 지도의 아이콘 중 어느 구렁에도 등록되지 않은 아이콘의 이름이
--   이 구렁의 이름(게임에서 읽어 저장한 이름, 없으면 클라이언트 언어 기본 이름)과 같으면 그 ID를 학습한다.
-- 풍요 판정은 찾은 아이콘의 atlas가 delves-bountiful인지로 한다. (모든 언어에서 동작)
-- =========================================================
local function GetLearnedPOIs(delve)
    if not HoneyDelveDB then return nil end
    HoneyDelveDB.LearnedPOIs = HoneyDelveDB.LearnedPOIs or {}
    local learned = HoneyDelveDB.LearnedPOIs[delve.key]
    if not learned then
        learned = {}
        HoneyDelveDB.LearnedPOIs[delve.key] = learned
    end
    return learned
end

-- 어느 구렁에든 등록(또는 학습)되어 있거나 제외 목록에 있는 아이콘인지
local function IsKnownDelvePOI(poiID)
    if addon.IgnoredDelvePOIs[poiID] then return true end
    local learnedAll = HoneyDelveDB and HoneyDelveDB.LearnedPOIs
    for _, d in ipairs(DelveList) do
        for _, id in ipairs(d.poiIDs) do
            if id == poiID then return true end
        end
        if learnedAll and learnedAll[d.key] and learnedAll[d.key][poiID] then return true end
    end
    return false
end

local function GetPOIInfoSafe(mapID, poiID)
    local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
    if ok and type(info) == "table" then return info end
    return nil
end

-- 반환값: poiID, 아이콘 정보, 출처("listed" = DB.lua, "learned" = 자동 학습) / 못 찾으면 nil
function addon.FindDelvePOI(delve)
    local ok, pois = pcall(C_AreaPoiInfo.GetDelvesForMap, delve.mapID)
    if not ok or type(pois) ~= "table" then return nil end
    local present = {}
    for _, id in ipairs(pois) do present[id] = true end

    for _, id in ipairs(delve.poiIDs) do
        if present[id] then return id, GetPOIInfoSafe(delve.mapID, id), "listed" end
    end

    local learned = GetLearnedPOIs(delve)
    if learned then
        for id in pairs(learned) do
            if present[id] then return id, GetPOIInfoSafe(delve.mapID, id), "learned" end
        end
    end

    local targetName = addon.GetDelveKnownName(delve)
    if not targetName then return nil end
    for _, id in ipairs(pois) do
        if not IsKnownDelvePOI(id) then
            local info = GetPOIInfoSafe(delve.mapID, id)
            if info and info.name == targetName then
                if learned then learned[id] = true end
                return id, info, "learned"
            end
        end
    end
    return nil
end

function addon.CanDetectBountiful(delve)
    return #delve.poiIDs > 0
end

function addon.IsBountiful(delve)
    local _, info = addon.FindDelvePOI(delve)
    return info ~= nil and info.atlasName == "delves-bountiful"
end

function HDT:UpdateDisplay()
    local spec = {}
    local fontSize = HoneyDelveDB.FontSize

    if HoneyDelveDB.ShowVaultKeyLine then
        local info3028 = C_CurrencyInfo.GetCurrencyInfo(3028)
        if info3028 then
            local row = NewRow(spec)
            AddIcon(row, info3028.iconFileID, ICON_SIZE_TRACKER, LAYOUT_LEAD_ICON_GAP)
            AddText(row, LabelValue(addon.GetName("RestoredKey"), info3028.quantity or 0))
        end
    end
    if HoneyDelveDB.ShowKeyShardLine then
        local info3310 = C_CurrencyInfo.GetCurrencyInfo(3310)
        if info3310 then
            local currentInv = info3310.quantity or 0
            local weeklyProg = info3310.quantityEarnedThisWeek or 0
            local maxWeekly = info3310.maxWeeklyQuantity or 0
            local value = tostring(currentInv)
            if maxWeekly > 0 then value = value .. " (" .. weeklyProg .. " / " .. maxWeekly .. ")" end
            local row = NewRow(spec)
            AddIcon(row, info3310.iconFileID, ICON_SIZE_TRACKER, LAYOUT_LEAD_ICON_GAP)
            AddText(row, LabelValue(addon.GetName("KeyShard"), value))
        end
    end
    -- 같은 형식(보유량 + 주간 획득량)의 화폐끼리 묶어서 금고 열쇠 파편 바로 다음에 표시
    if HoneyDelveDB.ShowManaCrystalLine then
        AddManaCrystalRow(spec)
    end
    if HoneyDelveDB.ShowGraceLine then
        local bountyGet, hasItem = GetBountyState()
        local label = "|cffffffff" .. addon.GetName("Grace") .. "|r"
        if hasItem then
            AddStatusRow(spec, 1064187, false, label, "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew", "|cffffff00" .. L.STATUS_UNUSED .. "|r")
        elseif bountyGet then
            AddStatusRow(spec, 1064187, false, label, "Interface\\RaidFrame\\ReadyCheck-Ready", "|cff00ff00" .. L.STATUS_USED .. "|r")
        else
            AddStatusRow(spec, 1064187, false, label, "Interface\\RaidFrame\\ReadyCheck-NotReady", "|cffff0000" .. L.STATUS_NOT_OBTAINED .. "|r")
        end
    end
    if HoneyDelveDB.ShowAbundance then
        local abundanceDone = GetAbundanceState()
        local label = "|cffffffff" .. L.ABUNDANCE .. "|r"
        -- 둔둔의 조각 아이콘 우선, 찾지 못하면 기존 풍요 구렁 아틀라스로 대체
        local dundunIcon = GetDundunShardIcon()
        local aIcon, aIsAtlas = dundunIcon, false
        if not dundunIcon then
            aIcon, aIsAtlas = "delves-bountiful", true
        end
        if abundanceDone then
            AddStatusRow(spec, aIcon, aIsAtlas, label, "Interface\\RaidFrame\\ReadyCheck-Ready", "|cff00ff00" .. L.STATUS_USED .. "|r")
        else
            AddStatusRow(spec, aIcon, aIsAtlas, label, "Interface\\RaidFrame\\ReadyCheck-NotReady", "|cffff0000" .. L.STATUS_UNUSED .. "|r")
        end
    end
    if HoneyDelveDB.ShowGildedStashLine then
        AddGildedStashRow(spec)
    end
    if HoneyDelveDB.ShowVaultWorldLine then
        AddVaultWorldRow(spec)
    end
    -- 상단 추적요소가 하나라도 있으면 구렁 목록과 사이에 빈 줄
    if #spec > 0 then AddBlankRow(spec) end

    local curZone = nil
    for _, data in ipairs(DelveList) do
        if curZone ~= data.zone then
            if curZone ~= nil then AddBlankRow(spec) end
            curZone = data.zone
            local zone = ZoneByMapID[curZone]

            local headerText = "|cff00ccff" .. addon.GetZoneName(curZone) .. "|r"
            if HoneyDelveDB.ShowBounty then
                local questID = zone and zone.bountyQuest
                if questID == nil then
                    headerText = headerText .. " |cffaaaaaa" .. L.UNAVAILABLE .. "|r"
                elseif C_QuestLog.IsQuestFlaggedCompleted(questID) then
                    headerText = headerText .. " |cff00ff00" .. L.BOUNTY_DONE .. "|r"
                else
                    headerText = headerText .. " |cffff4444" .. L.BOUNTY_NOT_DONE .. "|r"
                end
            end
            local header = NewRow(spec)
            AddText(header, headerText)

            local cached = WQCache[curZone]
            if not cached then
                AddGap(header, HEADER_ITEM_GAP)
                AddText(header, "|cffaaaaaa...|r")
            else
                if HoneyDelveDB.ShowWQGold and cached.goldCount > 0 then
                    AddHeaderReward(header, "Interface\\MoneyFrame\\UI-GoldIcon",
                        "|cffffd700" .. FormatThousands(cached.totalGold) .. "/" .. cached.goldCount .. "|r")
                end
                if HoneyDelveDB.ShowWQMarl and cached.marlCount > 0 then
                    AddHeaderReward(header, "Interface\\Icons\\Inv_112_raidtrinkets_voidprism",
                        "|cffb966f5" .. FormatThousands(cached.totalMarl) .. "/" .. cached.marlCount .. "|r")
                end
                if HoneyDelveDB.ShowWQShard and cached.shardCount > 0 then
                    local shardInfo = C_CurrencyInfo.GetCurrencyInfo(SHARD_CURRENCY_ID)
                    local shardIcon = shardInfo and shardInfo.iconFileID
                    AddHeaderReward(header, shardIcon,
                        "|cff00ccff" .. FormatThousands(cached.totalShard) .. "/" .. cached.shardCount .. "|r")
                end
                -- metaDone=true: 3/3 달성(주황 텍스트), metaDone=false: 진행 중(회색), nil: 없음(표시 안 함)
                if HoneyDelveDB.ShowZoneMeta then
                    if cached.metaDone == true then
                        AddHeaderReward(header, 1542860, "|cffff8000" .. L.META_AVAILABLE .. "|r")
                    elseif cached.metaDone == false then
                        AddHeaderReward(header, 1542860, "|cffaaaaaa" .. L.META_LOCKED_FMT:format(cached.metaProgress) .. "|r")
                    end
                end
            end
        end

        local activeID, activeName = nil, L.LOADING
        for _, vID in ipairs(data.variants) do
            local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(vID)
            if info and info.text ~= "" then
                activeID = vID
                activeName = addon.GetVariantName(vID)
                break
            end
        end
        local grade = activeID and GetGrade(activeID) or "A"
        local memo = activeID and GetMemo(activeID) or ""
        local isB = addon.IsBountiful(data)

        local rowText = "|cffffffff" .. addon.GetDelveName(data) .. " - " .. activeName .. "|r |cffffff00[" .. grade .. "]|r"
        if HoneyDelveDB.ShowMemo and memo ~= "" then rowText = rowText .. " |cff808080 " .. memo .. "|r" end
        local row = NewRow(spec)
        AddIcon(row, isB and "delves-bountiful" or "delves-normal", ICON_SIZE_DELVE, DELVE_ICON_GAP, true)
        AddText(row, rowText)
    end

    RenderRows(spec, fontSize)
end

-- =========================================================
-- 구렁로봇 7001 한밤 구렁 자동 선택
-- =========================================================
local delveBotHandled = false

-- 현재 대화 상대가 구렁로봇 7001인지 확인
-- 1순위: 대화상자 선택지 구성 (한밤 구렁 140192 또는 카즈 알가르 구렁 140193 선택지 존재)
--        구렁(인스턴스) 안에서는 NPC의 GUID와 이름이 보안값(secret value)이라 비교가 불가능하므로
--        유닛 정보를 쓰지 않는 선택지 ID 판별을 우선한다. (인게임 확인: 구렁 안에서 issecretvalue = true)
--        카즈 알가르 구렁 선택지는 한밤 칩 구매 여부와 상관없이 항상 있으므로 칩 미구매자도 판별된다.
-- 2순위: GUID의 NPC ID 비교 (인스턴스 밖 대비)
-- 각 단계는 보안값 등으로 오류가 나도 애드온이 멈추지 않도록 pcall로 감싼다.
-- 주의: select(6, strsplit(...))는 6번째 이후 값을 모두 반환하므로(NPC ID, 스폰 UID)
-- 그대로 tonumber에 넘기면 스폰 UID가 진법(base) 인자로 들어가 오류가 난다.
-- 반드시 지역 변수에 첫 번째 값만 받은 뒤 tonumber를 호출한다.
local function HasDelveBotOptions()
    local ok, result = pcall(function()
        local gossipOptions = C_GossipInfo.GetOptions()
        if not gossipOptions then return false end
        for _, opt in ipairs(gossipOptions) do
            local optID = opt.gossipOptionID
            if optID == DELVEBOT_MIDNIGHT_OPTION_ID or optID == DELVEBOT_KHAZ_OPTION_ID then
                return true
            end
        end
        return false
    end)
    return ok and result == true
end

local function GetNPCIDFromGUID()
    local guid = UnitGUID("npc")
    if not guid then return nil end
    local npcIDStr = select(6, strsplit("-", guid))
    return tonumber(npcIDStr)
end

local function IsDelveBotNPC()
    if HasDelveBotOptions() then return true end
    local okID, npcID = pcall(GetNPCIDFromGUID)
    return okID and npcID == DELVEBOT_NPC_ID
end

-- 풍요로운 한밤 구렁 확인 (대시보드와 동일한 판정 함수 사용)
-- 반환값: 판정 가능 여부, 풍요로운 구렁 존재 여부
-- 판정 가능한 구렁이 하나도 없으면(poiID 미등록) 판정 불가로 보고 자동 선택을 막지 않는다.
local function GetMidnightBountifulState()
    local canDetect = false
    for _, data in ipairs(DelveList) do
        if addon.CanDetectBountiful(data) then
            canDetect = true
            if addon.IsBountiful(data) then
                return true, true
            end
        end
    end
    return canDetect, false
end

-- 대화상자 선택지 중 한밤 구렁 선택지 ID 반환 (gossipOptionID 일치로만 판별)
-- pcall로 감싸 선택지 정보가 보안값이어도 오류 없이 nil을 반환한다.
local function FindMidnightOptionID()
    local okID, foundID = pcall(function()
        local gossipOptions = C_GossipInfo.GetOptions()
        if not gossipOptions then return nil end
        for _, opt in ipairs(gossipOptions) do
            if opt.gossipOptionID == DELVEBOT_MIDNIGHT_OPTION_ID then
                return DELVEBOT_MIDNIGHT_OPTION_ID
            end
        end
        return nil
    end)
    if okID and foundID then return foundID end
    return nil
end

-- 구렁로봇 7001 대화상자 처리 (GOSSIP_SHOW에서 호출)
local function HandleDelveBotGossip()
    if not HoneyDelveDB.AutoDelveBot then return end
    if delveBotHandled then return end
    if not IsDelveBotNPC() then return end
    -- 대화상자 1회 오픈당 1번만 처리 (GOSSIP_CLOSED에서 초기화)
    delveBotHandled = true

    -- Shift를 누른 채 대화하면 자동 선택 건너뜀 (카즈 알가르 구렁을 직접 고르고 싶을 때)
    if IsShiftKeyDown() then
        print("|cffffff00[HDT]|r " .. L.MSG_SHIFT_SKIP)
        return
    end

    -- 풍요로운 한밤 구렁이 없으면 일반 구렁으로 이동되므로 자동 선택하지 않음
    -- 만렙 미만: 풍요로운 구렁 입장 불가로 풍요 표시 자체가 없음
    -- 만렙: 풍요로운 구렁은 매일 4곳이 지정되며, 클리어할 때마다 풍요 표시가 사라짐(불이 꺼짐)
    if HoneyDelveDB.AutoDelveBotRequireBountiful then
        local canDetect, hasBountiful = GetMidnightBountifulState()
        if canDetect and not hasBountiful then
            if UnitLevel("player") < DELVEBOT_BOUNTIFUL_MIN_LEVEL then
                print("|cffffff00[HDT]|r " .. L.MSG_BOUNTIFUL_LEVEL:format(DELVEBOT_BOUNTIFUL_MIN_LEVEL))
            else
                print("|cffffff00[HDT]|r " .. L.MSG_NO_BOUNTIFUL)
            end
            return
        end
    end

    -- 한밤 구렁 선택지는 실버문 상인에게서 업데이트 칩을 구매(계정 단위 해금)해야 나타난다.
    -- 선택지가 없으면 카즈 알가르 구렁을 대신 고르지 않고 안내만 표시한다.
    local optionID = FindMidnightOptionID()
    if not optionID then
        print("|cffffff00[HDT]|r " .. L.MSG_NO_MIDNIGHT_OPTION)
        return
    end

    C_GossipInfo.SelectOption(optionID)
    print("|cffffff00[HDT]|r " .. L.MSG_DELVEBOT_SELECTED)
end

-- =========================================================
-- 둔둔 (넘칠듯한 풍요로움) 선택지 옆 금고 열쇠 개수 표시
-- 둔둔 판별: 대화상자 선택지에 수락 선택지(140123)가 있는지로 판별한다.
--   구렁 안에서는 NPC GUID와 이름이 보안값이지만 선택지 ID는 정상 조회됨 (인게임 확인)
-- 표시 방식: 블리자드 선택지 버튼의 글자는 건드리지 않고,
--   별도 글자(FontString)를 수락 선택지 글자 바로 오른쪽에 겹쳐 붙인다.
--   선택지 버튼은 다른 NPC 대화에서 재사용되므로, 표시용 글자는 버튼이 아닌
--   GossipFrame에 붙인 별도 프레임에 두고 대화상자가 닫히면 숨긴다.
-- 버튼을 찾지 못하는 경우(대화상자를 바꾸는 다른 애드온 사용 등) 채팅창에 안내를 대신 출력한다.
-- =========================================================
local dundunKeyHint = nil
local dundunChatNotified = false

local function GetDundunKeyHintFrame()
    if dundunKeyHint then return dundunKeyHint end
    if not GossipFrame then return nil end
    dundunKeyHint = CreateFrame("Frame", nil, GossipFrame)
    dundunKeyHint:SetSize(1, 1)
    dundunKeyHint.text = dundunKeyHint:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dundunKeyHint.text:SetJustifyH("LEFT")
    dundunKeyHint.text:SetWordWrap(false)
    dundunKeyHint:Hide()
    GossipFrame:HookScript("OnHide", function()
        if dundunKeyHint then dundunKeyHint:Hide() end
    end)
    return dundunKeyHint
end

local function HideDundunKeyHint()
    if dundunKeyHint then dundunKeyHint:Hide() end
end

local function HasDundunOptions()
    local ok, result = pcall(function()
        local gossipOptions = C_GossipInfo.GetOptions()
        if not gossipOptions then return false end
        for _, opt in ipairs(gossipOptions) do
            if opt.gossipOptionID == DUNDUN_ACCEPT_OPTION_ID then
                return true
            end
        end
        return false
    end)
    return ok and result == true
end

-- 기본 대화상자(GossipFrame)의 선택지 버튼 중 지정한 선택지 ID의 버튼을 찾는다.
-- 선택지 버튼의 GetElementData()는 { buttonType, info = 선택지 정보, ... } 구조이다.
local function FindGossipOptionButton(optionID)
    local ok, found = pcall(function()
        local panel = GossipFrame and GossipFrame.GreetingPanel
        local scrollBox = panel and panel.ScrollBox
        if not scrollBox or not scrollBox.ForEachFrame then return nil end
        local result = nil
        scrollBox:ForEachFrame(function(button)
            if result then return end
            local data = button.GetElementData and button:GetElementData()
            local info = data and data.info
            if info and info.gossipOptionID == optionID then
                result = button
            end
        end)
        return result
    end)
    if ok then return found end
    return nil
end

local function GetRestoredKeyCount()
    local info = C_CurrencyInfo.GetCurrencyInfo(RESTORED_KEY_CURRENCY_ID)
    return info and info.quantity or 0
end

-- 복원된 금고 열쇠 아이콘을 글자 안에 넣는 인라인 텍스처 문자열
-- 크기 0은 글자 높이에 맞춘다는 뜻이다. 아이콘 정보를 못 가져오면 "열쇠" 글자로 대체한다.
local function GetRestoredKeyInlineIcon()
    local info = C_CurrencyInfo.GetCurrencyInfo(RESTORED_KEY_CURRENCY_ID)
    if info and info.iconFileID then
        return "|T" .. info.iconFileID .. ":0|t"
    end
    return L.KEY_FALLBACK
end

-- 보유 열쇠 수에 따라 색을 바꾼 표시 문구 (2개 이상 초록, 2개 미만 빨강)
-- 둔둔 대화상자 배경이 양피지(밝은색)라서 어두운 초록/빨강을 사용한다.
-- 선택지 오른쪽 공간이 좁아서 "열쇠" 글자 대신 열쇠 아이콘을 사용한다.
local function GetDundunKeyHintText(keyCount)
    local keyIcon = GetRestoredKeyInlineIcon()
    local color = (keyCount >= DUNDUN_KEY_REQUIRED) and "|cff008000" or "|cffcc0000"
    return color .. L.DUNDUN_HINT_FMT:format(keyIcon, keyCount) .. "|r"
end

-- 수락 선택지 옆에 열쇠 개수를 표시한다. 표시에 성공하면 true를 반환한다.
function HDT:UpdateDundunKeyHint()
    if not HoneyDelveDB.ShowDundunKeyHint
        or not GossipFrame or not GossipFrame:IsShown()
        or not HasDundunOptions()
    then
        HideDundunKeyHint()
        return false
    end

    local button = FindGossipOptionButton(DUNDUN_ACCEPT_OPTION_ID)
    local fs = button and button.GetFontString and button:GetFontString()
    local hint = GetDundunKeyHintFrame()
    if not button or not fs or not hint then
        HideDundunKeyHint()
        return false
    end

    -- 선택지 글자의 실제 너비와 글꼴을 가져온다 (보안값 등으로 실패해도 멈추지 않도록 pcall)
    local okWidth, textWidth = pcall(function() return fs:GetStringWidth() end)
    if not okWidth or type(textWidth) ~= "number" then
        HideDundunKeyHint()
        return false
    end
    local okFont, fontPath, fontSize, fontFlags = pcall(function() return fs:GetFont() end)

    hint:ClearAllPoints()
    hint:SetAllPoints(button)
    hint:SetFrameStrata(button:GetFrameStrata())
    hint:SetFrameLevel(button:GetFrameLevel() + 5)
    if okFont and fontPath then
        hint.text:SetFont(fontPath, fontSize, fontFlags)
    end
    hint.text:SetText(GetDundunKeyHintText(GetRestoredKeyCount()))
    hint.text:ClearAllPoints()
    hint.text:SetPoint("TOPLEFT", fs, "TOPLEFT", textWidth + 4, 0)
    hint:Show()
    return true
end

-- 선택지 버튼을 끝내 찾지 못한 경우 채팅창으로 대신 안내 (대화상자 1회 오픈당 1번)
local function NotifyDundunKeyInChat()
    if dundunChatNotified then return end
    if not HoneyDelveDB.ShowDundunKeyHint or not HasDundunOptions() then return end
    dundunChatNotified = true
    local keyCount = GetRestoredKeyCount()
    local color = (keyCount >= DUNDUN_KEY_REQUIRED) and "|cff00ff00" or "|cffff4444"
    print("|cffffff00[HDT]|r " .. L.MSG_DUNDUN_KEYS:format(L.ABUNDANCE, addon.GetName("RestoredKey"), color, keyCount, DUNDUN_KEY_REQUIRED))
end

-- GOSSIP_SHOW 직후에는 블리자드 대화상자가 아직 선택지 버튼을 다 그리지 않았을 수 있으므로
-- 다음 프레임에 표시를 시도하고, 실패하면 0.2초 뒤 한 번 더 시도한 뒤 채팅 안내로 대체한다.
local function ScheduleDundunKeyHint()
    if not HoneyDelveDB.ShowDundunKeyHint or not HasDundunOptions() then return end
    C_Timer.After(0, function()
        if HDT:UpdateDundunKeyHint() then return end
        C_Timer.After(0.2, function()
            if not HDT:UpdateDundunKeyHint() then
                NotifyDundunKeyInChat()
            end
        end)
    end)
end

function HDT:GOSSIP_SHOW()
    HideDundunKeyHint()
    ScheduleDundunKeyHint()
    HandleDelveBotGossip()
end

function HDT:GOSSIP_CLOSED()
    delveBotHandled = false
    dundunChatNotified = false
    HideDundunKeyHint()
end

-- =========================================================
-- /hdt locale: 번역 기여용 정보 출력
-- 다른 언어 클라이언트 사용자가 언어 파일에 넣을 값(게임 글자, 지도 아이콘 ID 등)을 확인하는 용도.
-- 구렁로봇 7001이나 둔둔과 대화 중에 입력하면 대화상자 선택지도 함께 출력한다.
-- =========================================================
local function DumpPrint(text)
    print("|cffffff00[HDT]|r " .. text)
end

-- toc의 Version 값 (설치된 파일이 어느 판인지 출력 결과만으로 구분하기 위해 사용)
local function GetAddonVersion()
    local ok, version = pcall(function()
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            return C_AddOns.GetAddOnMetadata(AddonName, "Version")
        end
        return GetAddOnMetadata(AddonName, "Version")
    end)
    if ok and version then return version end
    return "?"
end

local function DumpLocaleInfoInner()
    DumpPrint(L.DUMP_HEADER:format(tostring(GetAddonVersion()), tostring(addon.ClientLocale), tostring(addon.GetDisplayLocale())))

    DumpPrint(L.DUMP_ZONES)
    for _, zone in ipairs(ZoneList) do
        local info = C_Map.GetMapInfo(zone.mapID)
        DumpPrint(zone.mapID .. " = " .. tostring(info and info.name))
    end

    -- 구렁마다 애드온이 실제로 판정한 결과를 출력한다.
    -- 형식: 내부 키 / 지도 ID / DB.lua의 poiIDs = 지금 찾은 poiID(출처) 표시 이름 (풍요 여부)
    -- 출처가 learned인 ID는 DB.lua의 poiIDs에 옮겨 적으면 된다.
    DumpPrint(L.DUMP_DELVES)
    for _, d in ipairs(DelveList) do
        local foundID, _, source = addon.FindDelvePOI(d)
        local found = foundID and (foundID .. "(" .. source .. ")") or "not found"
        local state = addon.IsBountiful(d) and "bountiful" or "regular"
        DumpPrint(d.key .. " / " .. d.mapID .. " / " .. table.concat(d.poiIDs, ",") .. " = " .. found .. " " .. tostring(addon.GetDelveName(d)) .. " (" .. state .. ")")
    end

    -- 대시보드에서 제외하는 구렁 아이콘(DB.lua의 IgnoredDelvePOIs)은 출력하지 않는다.
    local seenMaps = {}
    for _, d in ipairs(DelveList) do
        if not seenMaps[d.mapID] then
            seenMaps[d.mapID] = true
            DumpPrint(L.DUMP_POIS:format(d.mapID))
            local pois = C_AreaPoiInfo.GetDelvesForMap(d.mapID) or {}
            for _, poiID in ipairs(pois) do
                if not addon.IgnoredDelvePOIs[poiID] then
                    local info = C_AreaPoiInfo.GetAreaPOIInfo(d.mapID, poiID)
                    DumpPrint(poiID .. " = " .. tostring(info and info.name) .. " (" .. tostring(info and info.atlasName) .. ")")
                end
            end
        end
    end

    -- 이야기 변형 위젯 ID 범위(7000~9000)를 훑는다.
    -- 등록된 변형은 구렁 내부 키와 함께, 등록되지 않은 변형은 VariantPrefix로 시작하는 글자만 표시한다.
    -- (새 구렁이 추가되었을 때 변형 ID를 찾기 위한 용도, VariantPrefix가 없는 언어에서는 등록된 변형만 표시)
    DumpPrint(L.DUMP_VARIANTS)
    local knownVariants = {}
    for _, d in ipairs(DelveList) do
        for _, vID in ipairs(d.variants) do
            knownVariants[vID] = d.key
        end
    end
    local variantPrefix = addon.GetGameText("VariantPrefix")
    for wID = 7000, 9000 do
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(wID)
        if info and info.text and info.text ~= "" then
            if knownVariants[wID] then
                DumpPrint(wID .. " = " .. info.text .. " (" .. knownVariants[wID] .. ")")
            elseif variantPrefix and info.text:sub(1, #variantPrefix) == variantPrefix then
                DumpPrint(wID .. " = " .. info.text .. " " .. L.DUMP_UNKNOWN_VARIANT)
            end
        end
    end

    DumpPrint(L.DUMP_NAMES)
    for _, key in ipairs(addon.NAME_SOURCE_ORDER) do
        DumpPrint(key .. " = " .. tostring(addon.GetRuntimeName(key)))
    end

    -- 특별 과제: 지역별 판정 결과와 근거(잠김 아이콘, 툴팁 위젯, DB.lua 위젯, 특별 과제 퀘스트)를 출력한다.
    local function WidgetText(wID)
        local ok, text = pcall(function()
            local w = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(wID)
            return w and w.text
        end)
        return ok and text or nil
    end
    DumpPrint(L.DUMP_META)
    DumpPrint("Enum.QuestTagType.Capstone = " .. tostring(Enum and Enum.QuestTagType and Enum.QuestTagType.Capstone))
    local knownMetaWidgets = {}
    for _, zone in ipairs(ZoneList) do
        local quests = C_TaskQuest.GetQuestsOnMap(zone.mapID) or {}
        local done, progress = addon.GetZoneMetaState(zone, quests)
        local result = "none"
        if done == true then
            result = "unlocked"
        elseif done == false then
            result = "locked " .. progress .. "/" .. META_TOTAL
        end
        DumpPrint(zone.mapID .. " " .. tostring(addon.GetMapName(zone.mapID)) .. " = " .. result)
        for _, info in ipairs(addon.GetCapstonePOIs(zone)) do
            DumpPrint(L.DUMP_META_POI:format(tostring(info.areaPoiID), tostring(info.name), tostring(info.widgetSetID), tostring(info.tooltipWidgetSet), tostring(info.foundMapID)))
            for _, wID in ipairs(addon.GetPOIWidgetIDs(info)) do
                DumpPrint(L.DUMP_META_WIDGET:format(tostring(wID), tostring(WidgetText(wID))))
            end
        end
        -- 잠김 아이콘을 못 찾은 지역은 지도별 아이콘 전체를 출력해 원인을 확인한다. (구렁 아이콘 제외)
        -- 아이콘이 0개이면 그 지도의 아이콘 정보를 아직 받지 못한 것이고,
        -- 아이콘이 있는데 잠김으로 잡히지 않으면 atlas 이름이나 isPrimaryMapForPOI 값을 보면 된다.
        if done == nil then
            for _, mapID in ipairs(addon.GetZoneMapIDs(zone)) do
                local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID) or {}
                DumpPrint(L.DUMP_META_MAP:format(tostring(mapID), #pois))
                for _, poiID in ipairs(pois) do
                    local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                    local atlas = info and info.atlasName
                    if not (type(atlas) == "string" and atlas:find("^delves%-")) then
                        DumpPrint(L.DUMP_META_ALLPOI:format(tostring(poiID), tostring(info and info.name), tostring(atlas), tostring(info and info.isPrimaryMapForPOI), tostring(info and info.tooltipWidgetSet)))
                    end
                end
            end
        end
        for _, wID in ipairs(zone.metaWidgets or {}) do
            knownMetaWidgets[wID] = true
            DumpPrint(L.DUMP_META_WIDGET:format(tostring(wID), tostring(WidgetText(wID))))
        end
        for _, v in ipairs(quests) do
            if zone.allowedMaps[v.mapID] and C_QuestLog.IsWorldQuest(v.questID) then
                local title = C_TaskQuest.GetQuestInfoByQuestID(v.questID)
                local isMeta = addon.IsSpecialAssignmentQuest(v.questID)
                -- 특별 과제로 판정된 퀘스트와, 제목에 콜론이 있어 특별 과제일 수 있는 퀘스트만 출력
                if isMeta or (type(title) == "string" and title:find(":", 1, true)) then
                    local okTag, tagInfo = pcall(C_QuestLog.GetQuestTagInfo, v.questID)
                    local wqType = okTag and tagInfo and tagInfo.worldQuestType
                    DumpPrint(L.DUMP_META_QUEST:format(tostring(v.questID), tostring(title), tostring(wqType)))
                end
            end
        end
    end

    -- DB.lua에 없는 특별 과제 위젯 찾기 (새 특별 과제 추가 대비)
    -- 지역 지도 이름이 들어 있고 숫자가 있는 위젯 글자만 출력한다.
    -- 위젯 글자의 지역 표기가 지도 이름과 다르면(예: 영어 "in Eversong") 여기에 나오지 않으므로,
    -- 위의 잠김 아이콘 툴팁 위젯 목록도 함께 확인한다.
    DumpPrint(L.DUMP_META_SCAN)
    local zoneNames = {}
    for _, zone in ipairs(ZoneList) do
        local name = addon.GetMapName(zone.mapID)
        if name then zoneNames[#zoneNames + 1] = name end
    end
    for wID = 5000, 9000 do
        if not knownMetaWidgets[wID] then
            local text = WidgetText(wID)
            if type(text) == "string" and text ~= "" and text:find("%d") then
                for _, name in ipairs(zoneNames) do
                    if text:find(name, 1, true) then
                        DumpPrint(wID .. " = " .. text)
                        break
                    end
                end
            end
        end
    end

    -- 아직 화면 문구(언어 파일)로 표시하는 항목의 게임 이름 후보
    -- 게임에서 읽은 값이 실제 명칭과 같은지 확인되면 이후 클라이언트 조회로 바꿀 수 있다.
    DumpPrint(L.DUMP_NAME_CANDIDATES)
    local okQuest, abundanceTitle = pcall(C_QuestLog.GetTitleForQuestID, ABUNDANCE_QUEST_ID)
    DumpPrint("ABUNDANCE quest " .. ABUNDANCE_QUEST_ID .. " = " .. tostring(okQuest and abundanceTitle or nil))
    local okStash, stashSpellID, stashSpellName = pcall(function()
        local widget = C_UIWidgetManager.GetSpellDisplayVisualizationInfo(GILDED_STASH_SPELL_ID)
        local spellID = widget and widget.spellInfo and widget.spellInfo.spellID
        local name = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
        return spellID, name
    end)
    DumpPrint("STASH widget " .. GILDED_STASH_SPELL_ID .. " spellID " .. tostring(okStash and stashSpellID or nil) .. " = " .. tostring(okStash and stashSpellName or nil))

    if GossipFrame and GossipFrame:IsShown() then
        DumpPrint(L.DUMP_GOSSIP)
        local okOpt, gossipOptions = pcall(C_GossipInfo.GetOptions)
        if okOpt and gossipOptions then
            for _, opt in ipairs(gossipOptions) do
                DumpPrint(tostring(opt.gossipOptionID) .. " = " .. tostring(opt.name))
            end
        end
        local okName, npcName = pcall(UnitName, "npc")
        if okName then
            DumpPrint(L.DUMP_NPC:format(tostring(npcName)))
        end
    end

    DumpPrint(L.DUMP_END)
end

function HDT:DumpLocaleInfo()
    local ok, err = pcall(DumpLocaleInfoInner)
    if not ok then
        DumpPrint(L.DUMP_ERROR:format(tostring(err)))
    end
end

-- 슬래시 명령: /hdt (대시보드), /hdt locale (번역 기여용 정보 출력)
-- 애드온 언어 등 설정은 모두 설정창(/hdtset)에서 한다.
function HDT:HandleSlash(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "" then
        HoneyDelveTodayFrame_Toggle()
    elseif msg == "locale" then
        HDT:DumpLocaleInfo()
    else
        print("|cffffff00[HDT]|r " .. L.MSG_USAGE)
    end
end

function HDT:OnInitialize()
    local addedCount = InitializeDB()
    -- 저장된 애드온 언어로 표시 언어를 고정한다 (설정창에서 바꾸면 UI 다시 불러오기 후 적용)
    addon.FreezeDisplayLocale()
    addon.RequestNameData()
    BuildOptions()
    BuildOptionsTree()
    AceConfig:RegisterOptionsTable(AddonName, options)
    AceConfigDialog:SetDefaultSize(AddonName, 850, 600)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
    f.Title:SetText(L.TITLE)
    local HDTLDB = LDB:NewDataObject(AddonName, {
        type = "launcher", text = L.TITLE, icon = DELVE_ICON,
        OnClick = function(_, button) if button == "LeftButton" then HoneyDelveTodayFrame_Toggle() else HoneyDelveTodayConfig_Toggle() end end,
        OnTooltipShow = function(tt) tt:AddLine("|cffffff00" .. L.TITLE .. "|r") tt:AddLine(L.LDB_TOOLTIP) end,
    })
    icon:Register(AddonName, HDTLDB, HoneyDelveDB.Minimap)
    if HoneyDelveTodayFrame.CustomBg then HoneyDelveTodayFrame.CustomBg:SetColorTexture(0, 0, 0, HoneyDelveDB.Alpha) end
    -- 저장된 알림창 위치 복원, 없으면 화면 중앙
    if HoneyDelveDB.GraceAlertPos then
        local p = HoneyDelveDB.GraceAlertPos
        graceAlert:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        graceAlert:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    -- 진귀품 버프 창 위치 복원 (없으면 기본 위치) 및 플레이어 버프 변동 이벤트 등록
    ApplyCurioPosition()
    curioEventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("QUEST_LOG_UPDATE")
    self:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    self:RegisterEvent("GOSSIP_SHOW")
    self:RegisterEvent("GOSSIP_CLOSED")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    HDT:UpdateGraceAlert()
    -- 새 버전 업데이트로 항목이 추가된 경우 안내
    if addedCount > 0 then
        print("|cffffff00[HoneyDelveToday]|r " .. L.MSG_NEW_ENTRIES:format(addedCount))
    end
    -- 애드온 로드 시점부터 대시보드를 띄우기 전이라도 전역퀘 정보를 미리 채워둔다.
    C_Timer.After(1, function() HDT:RefreshWQCache() end)
end

function HDT:BAG_UPDATE()
    HDT:UpdateGraceAlert()
    if f:IsShown() then HDT:UpdateDisplay() end
end

function HDT:QUEST_LOG_UPDATE()
    HDT:RefreshWQCache()
end

-- 위대한 금고 진행도가 갱신되면(구렁 클리어, 야외 활동 완료 등) 대시보드에 즉시 반영
function HDT:WEEKLY_REWARDS_UPDATE()
    if f:IsShown() then HDT:UpdateDisplay() end
end

-- 화폐(정순한 마나 수정, 금고 열쇠 등) 변동 시 대시보드에 즉시 반영
-- 둔둔 대화상자가 열려 있는 동안 열쇠 개수가 바뀌면 선택지 옆 표시도 갱신
function HDT:CURRENCY_DISPLAY_UPDATE()
    if f:IsShown() then HDT:UpdateDisplay() end
    if dundunKeyHint and dundunKeyHint:IsShown() then HDT:UpdateDundunKeyHint() end
end

-- 전투 중에 유지해 둔 진귀품 버프 표시를 전투가 끝나면 다시 확인
function HDT:PLAYER_REGEN_ENABLED()
    HDT:UpdateCurioBuff()
end

function HDT:PLAYER_ENTERING_WORLD()
    graceAlert.closedByUser = false
    -- 순간이동 로딩 중 GOSSIP_CLOSED가 누락되어도 다음 구렁로봇 대화가 막히지 않도록 초기화
    delveBotHandled = false
    dundunChatNotified = false
    HideDundunKeyHint()
    HDT:UpdateGraceAlert()
    -- 골드퀘 데이터 미리 로드 (첫 대시보드 오픈 시 빈 결과 방지)
    for _, zone in ipairs(ZoneList) do
        C_TaskQuest.GetQuestsOnMap(zone.mapID)
    end
    -- 로딩 화면 직후(구렁 입장/퇴장 등) 진귀품 버프 표시를 바로 맞춘다
    HDT:UpdateCurioBuff()
    C_Timer.After(1, function()
        HDT:RefreshWQCache()
        HDT:RefreshNameCache()
        HDT:UpdateCurioBuff()
    end)
end

function HDT:ZONE_CHANGED_NEW_AREA()
    graceAlert.closedByUser = false
    HDT:UpdateGraceAlert()
    C_Timer.After(1, function() HDT:RefreshWQCache() end)
end

function HoneyDelveTodayFrame_Toggle()
    if f:IsShown() then f:Hide() else HDT:UpdateDisplay() f:Show() end
end

function HoneyDelveTodayConfig_Toggle()
    if AceConfigDialog.OpenFrames[AddonName] then AceConfigDialog:Close(AddonName) else AceConfigDialog:Open(AddonName) end
end

SLASH_HONEYDELVE1 = "/hdt"
SlashCmdList["HONEYDELVE"] = function(msg) HDT:HandleSlash(msg) end
SLASH_HDTSET1 = "/hdtset"
SlashCmdList["HDTSET"] = HoneyDelveTodayConfig_Toggle