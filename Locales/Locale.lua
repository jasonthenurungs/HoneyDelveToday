local AddonName, addon = ...

-- =========================================================
-- 언어 선택과 조회 함수
-- 이 파일은 모든 언어 파일(koKR.lua, enUS.lua 등)을 불러온 뒤에 로드되어야 한다.
--
-- 고유명사(지역, 구렁, 이야기 변형, 화폐, 아이템 이름)
--   DB.lua의 ID로 게임에서 읽은 값을 최신 값으로 표시한다.
--   게임에서 읽을 수 없을 때(그날 활성화되지 않은 이야기 변형, 아직 로드되지 않은 아이템 등)는
--   이전에 게임에서 읽어 저장한 값, 언어 파일의 기본 이름 순서로 대신 표시한다.
--   고유명사는 설정창의 애드온 언어와 상관없이 항상 클라이언트 언어 기준이다.
--   조회 순서: 게임 값, 저장 값(NameCache), 클라이언트 언어 기본 이름, 영어 기본 이름, 한국어 기본 이름
--
-- 그 밖의 언어 파일 내용
-- 1) 표시 언어(display locale)를 따르는 것: 화면 문구(UI)와 기본 메모(Memos)
--    한국어 클라이언트는 koKR, 그 외 클라이언트는 언어 파일이 있으면 그 언어, 없으면 enUS를 쓴다.
--    화면 문구가 없으면 한국어로 대체하고, 메모가 없으면 빈 메모로 둔다.
--    설정창 일반 탭의 애드온 언어에서 바꿀 수 있다 (UI 다시 불러오기 후 적용).
-- 2) 클라이언트 언어(client locale)를 따르는 것: 게임 글자 처리용 값(Game)
--    게임 글자는 클라이언트 언어로만 나오므로 다른 언어 값으로 대체하지 않는다.
-- =========================================================

addon.Locales = addon.Locales or {}
local Locales = addon.Locales
local KO = Locales.koKR
local EN = Locales.enUS

local clientLocale = GetLocale()
if clientLocale == "enGB" then clientLocale = "enUS" end
addon.ClientLocale = clientLocale

local function GetAutoDisplayLocale()
    if Locales[clientLocale] then return clientLocale end
    return "enUS"
end

-- 설정창 애드온 언어 선택지에 표시할 언어 이름 (각 언어 자신의 표기, 번역하지 않는다)
-- 언어 파일을 추가하면 여기에도 추가한다.
addon.LANGUAGE_NAMES = {
    koKR = "한국어",
    enUS = "English",
}
addon.LANGUAGE_ORDER = { "koKR", "enUS" }

-- 저장된 설정 기준 표시 언어 (설정창에서 바꾸면 바로 바뀐다)
function addon.GetSavedDisplayLocale()
    local override = HoneyDelveDB and HoneyDelveDB.LocaleOverride
    if override and Locales[override] then return override end
    return GetAutoDisplayLocale()
end

-- 실제로 쓰는 표시 언어
-- 설정창 등 화면 대부분이 로드 시점에 만들어지므로, 설정을 바꿔도 일부만 바뀌어 섞이지 않도록
-- 애드온 초기화(OnInitialize) 때 한 번 고정한다. 바꾼 설정은 UI를 다시 불러온 뒤 적용된다.
-- 고정 전(파일 로드 중, 키 바인딩 이름 등)에는 저장 데이터가 아직 없으므로 클라이언트 언어를 따른다.
local frozenDisplayLocale = nil

function addon.FreezeDisplayLocale()
    frozenDisplayLocale = addon.GetSavedDisplayLocale()
end

function addon.GetDisplayLocale()
    return frozenDisplayLocale or addon.GetSavedDisplayLocale()
end

local function DisplayData()
    return Locales[addon.GetDisplayLocale()] or KO
end

local function ClientData()
    return Locales[clientLocale]
end

-- 언어 파일에서 주석만 풀고 값을 비워둔 경우("")도 값이 없는 것으로 처리
local function Filled(value)
    if value == nil or value == "" then return nil end
    return value
end

-- 화면 문구 테이블: 표시 언어에 없으면 한국어, 한국어에도 없으면 키 이름을 그대로 반환
-- 표시 언어가 고정되기 전과 후 모두 올바른 값을 주도록 값을 캐싱하지 않는다.
addon.L = setmetatable({}, {
    __index = function(_, key)
        local data = DisplayData()
        local value = data.UI and Filled(data.UI[key])
        if value == nil then value = KO.UI[key] end
        if value == nil then value = key end
        return value
    end,
})

-- 게임 글자 처리용 값 (클라이언트 언어 전용, 다른 언어로 대체하지 않음)
function addon.GetGameText(key)
    local data = ClientData()
    return data and data.Game and Filled(data.Game[key]) or nil
end

-- =========================================================
-- 기본 이름 (언어 파일의 Names, Delves, Variants)
-- section: "Names", "Delves", "Variants"
-- ClientDefaultName: 클라이언트 언어 기본 이름만 (자동 학습 이름 비교용, 다른 언어로 대체하지 않음)
-- DefaultName: 클라이언트 언어, 영어, 한국어 순서로 대체
-- =========================================================
local function SectionValue(data, section, key)
    local t = data and data[section]
    return t and Filled(t[key]) or nil
end

local function ClientDefaultName(section, key)
    return SectionValue(ClientData(), section, key)
end

local function DefaultName(section, key)
    return SectionValue(ClientData(), section, key)
        or SectionValue(EN, section, key)
        or SectionValue(KO, section, key)
end

-- =========================================================
-- 저장 값 (HoneyDelveDB.NameCache[클라이언트 언어])
-- 게임에서 이름을 읽을 때마다 저장해 두고, 게임에서 읽을 수 없을 때 기본 이름보다 먼저 쓴다.
-- 계정 공용 저장 데이터라 어느 캐릭터에서 본 이름이든 함께 쌓이고,
-- 클라이언트 언어별로 따로 저장하므로 클라이언트 언어를 바꿔도 다른 언어 이름이 섞이지 않는다.
--   name: 화폐/아이템/주문 이름 (키: Names 키)
--   delve: 구렁 이름 (키: DelveList의 key)
--   variant: 이야기 변형 이름 (키: 변형 ID)
-- =========================================================
local function GetCache(kind)
    if not HoneyDelveDB then return nil end
    HoneyDelveDB.NameCache = HoneyDelveDB.NameCache or {}
    local byLocale = HoneyDelveDB.NameCache[clientLocale]
    if not byLocale then
        byLocale = {}
        HoneyDelveDB.NameCache[clientLocale] = byLocale
    end
    if not byLocale[kind] then byLocale[kind] = {} end
    return byLocale[kind]
end

local function CacheGet(kind, key)
    local cache = GetCache(kind)
    return cache and cache[key] or nil
end

local function CacheSet(kind, key, value)
    local cache = GetCache(kind)
    if cache then cache[key] = value end
end

-- 문자열로 정상 반환된 경우만 이름으로 인정 (빈 문자열, 보안값 등은 제외)
local function SafeName(fn)
    local ok, name = pcall(fn)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

-- =========================================================
-- 화폐, 아이템, 주문 이름 (키: 언어 파일의 Names 키)
-- =========================================================
local NAME_SOURCES = {
    RestoredKey = { currency = 3028 },  -- 복원된 금고 열쇠
    KeyShard    = { currency = 3310 },  -- 금고 열쇠 파편
    ManaCrystal = { currency = 3356 },  -- 정순한 마나 수정
    Marl        = { currency = 3316 },  -- 공허불빛 이회토
    MythCrest   = { currency = 3446 },  -- 신화 안개문장
    Grace       = { item = 274374 },    -- 보물 추적자의 은혜
    Stash       = { spell = 1216211 },  -- 보관함 (보관함 위젯 7591의 주문 ID, 2026-10-11 영어 출력에서 확인)
}
addon.NAME_SOURCE_ORDER = { "RestoredKey", "KeyShard", "ManaCrystal", "Marl", "MythCrest", "Grace", "Stash" }

-- 아이템 이름은 캐시에 없으면 nil이 나오므로 미리 요청해 둔다.
function addon.RequestNameData()
    for _, src in pairs(NAME_SOURCES) do
        if src.item and C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, src.item)
        end
    end
end

function addon.GetRuntimeName(key)
    local src = NAME_SOURCES[key]
    if not src then return nil end
    return SafeName(function()
        if src.currency then
            local info = C_CurrencyInfo.GetCurrencyInfo(src.currency)
            return info and info.name
        elseif src.item and C_Item and C_Item.GetItemNameByID then
            return C_Item.GetItemNameByID(src.item)
        elseif src.spell and C_Spell and C_Spell.GetSpellName then
            return C_Spell.GetSpellName(src.spell)
        end
        return nil
    end)
end

function addon.GetName(key)
    local value = addon.GetRuntimeName(key)
    if value then
        CacheSet("name", key, value)
        return value
    end
    return CacheGet("name", key) or DefaultName("Names", key) or key
end

-- =========================================================
-- 지역 이름: 게임 지도 이름 (지도 정보는 어디서나 조회되므로 기본 이름을 두지 않는다)
-- =========================================================
function addon.GetMapName(mapID)
    return SafeName(function()
        local info = C_Map.GetMapInfo(mapID)
        return info and info.name
    end)
end

function addon.GetZoneName(mapID)
    return addon.GetMapName(mapID) or ("#" .. tostring(mapID))
end

-- =========================================================
-- 구렁 이름: 지금 지도에 있는 구렁 아이콘 이름(Core.lua의 FindDelvePOI), 저장 값, 기본 이름 순서
-- =========================================================
function addon.GetDelveName(delve)
    local _, info = addon.FindDelvePOI(delve)
    local value = info and type(info.name) == "string" and info.name ~= "" and info.name or nil
    if value then
        CacheSet("delve", delve.key, value)
        return value
    end
    return CacheGet("delve", delve.key) or DefaultName("Delves", delve.key) or delve.key
end

-- 자동 학습에서 미등록 아이콘과 비교할 이름: 저장 값, 클라이언트 언어 기본 이름 (다른 언어로 대체하지 않음)
function addon.GetDelveKnownName(delve)
    return CacheGet("delve", delve.key) or ClientDefaultName("Delves", delve.key)
end

-- =========================================================
-- 이야기 변형 이름: 활성 변형의 위젯 글자, 저장 값, 기본 이름 순서
-- 위젯 글자는 "이야기 변형: 기초적인 해독제"처럼 앞부분이 붙어 나오므로 앞부분을 떼고 쓴다.
--   클라이언트 언어의 VariantPrefix가 있으면 그 글자를 떼고,
--   없으면 첫 번째 콜론(:)까지를 떼고, 콜론도 없으면 글자 전체를 쓴다.
-- =========================================================
function addon.GetActiveVariantTitle(variantID)
    local text = SafeName(function()
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(variantID)
        return info and info.text
    end)
    if not text then return nil end
    local prefix = addon.GetGameText("VariantPrefix")
    if prefix and text:sub(1, #prefix) == prefix then
        return Filled(text:sub(#prefix + 1))
    end
    local afterColon = text:match("^[^:]+:%s*(.+)$")
    return afterColon or text
end

function addon.GetVariantName(variantID)
    local title = addon.GetActiveVariantTitle(variantID)
    if title then
        CacheSet("variant", variantID, title)
        return title
    end
    return CacheGet("variant", variantID)
        or DefaultName("Variants", variantID)
        or addon.L.VARIANT_UNKNOWN_FMT:format(variantID)
end

-- =========================================================
-- 기본 메모: 표시 언어 값만 사용 (번역 전에는 빈 메모)
-- =========================================================
function addon.GetDefaultMemo(variantID)
    local data = DisplayData()
    return (data.Memos and data.Memos[variantID]) or ""
end
