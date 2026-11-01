local AddonName, addon = ...

-- =========================================================
-- 언어와 무관한 데이터
-- 고유명사(지역, 구렁, 이야기 변형, 화폐, 아이템 이름)는 이 파일의 ID로 게임에서 읽어 최신 값으로 표시한다.
-- 게임에서 읽을 수 없을 때 쓰는 기본 이름과 기본 메모, 화면 문구는 Locales 폴더의 언어 파일에 있다.
-- 이 파일에는 ID, 등급, 내부 키처럼 언어가 바뀌어도 그대로인 값만 둔다.
-- =========================================================

-- 지역 목록 (대시보드 표시 순서)
-- mapID: 지역 대표 지도 ID이자 지역의 내부 키
-- allowedMaps: GetQuestsOnMap이 인접 지역 퀘스트도 섞어서 반환하므로 이 지역으로 인정할 서브맵 ID 셋
-- bountyQuest: 지역 주간 현상금(평판/영예) 퀘스트 ID
-- metaWidgets: 특별 과제 잠김 상태 위젯 ID ("전역 퀘스트 N개를 완료하면 해제" 문구)
--   2026-10-11 한국어/영어 클라이언트 /hdt locale 출력으로 지역별로 확인한 값이다.
--   위젯 글자에서 숫자만 읽으므로 언어와 상관없이 동작한다.
--   지역마다 위젯이 2개 이상 있는 것은 주마다 바뀌는 특별 과제별로 위젯이 따로 있기 때문으로 보인다.
--   새 특별 과제가 추가되어 위젯 ID가 늘어나면 /hdt locale의 [특별 과제 위젯 검색]에 표시된다.
addon.ZoneList = {
    { mapID = 2395, allowedMaps = { [2393] = true, [2395] = true, [2424] = true }, bountyQuest = 93821, metaWidgets = {7710, 7876} },
    { mapID = 2437, allowedMaps = { [2437] = true }, bountyQuest = 93819, metaWidgets = {7672, 7675} },
    { mapID = 2405, allowedMaps = { [2405] = true, [2444] = true }, bountyQuest = 93820, metaWidgets = {7659, 7668} },
    { mapID = 2413, allowedMaps = { [2413] = true }, bountyQuest = 93822, metaWidgets = {7618, 7621} },
    -- 똬리의 섬: 인접 서브맵 ID 미확인, 추후 확인되면 allowedMaps에 추가
    -- bountyQuest 99222: 줄자라의 군대 주간 현상금 (부캐 교차검증으로 확정: 98501=false, 99222=true)
    { mapID = 2512, allowedMaps = { [2512] = true }, bountyQuest = 99222, metaWidgets = {8259, 8263, 8264} },
}

-- 구렁 목록 (대시보드 표시 순서)
-- key: 언어 파일의 기본 구렁 이름(Delves)과 설정창 그룹을 찾는 내부 키 (공식 명칭이 아니다)
-- zone: 소속 지역의 mapID (ZoneList의 mapID)
-- mapID: 구렁 지도 아이콘(POI)을 조회할 지도 ID
--        같은 아이콘이 인접 지역 지도에도 나오므로(예: 어둠의 은거처가 2395와 2437에 모두 표시) 구렁마다 한 지도로 고정한다.
-- poiIDs: 구렁 지도 아이콘 ID 목록. 풍요 판정과 구렁 이름 조회를 이 ID로 하므로 모든 언어에서 동작한다.
--         구렁마다 일반 상태 아이콘과 풍요 상태 아이콘의 ID가 서로 다르다.
--         (2026-10-11 오전 출력과 같은 날 2차 출력을 비교해 확인: 풍요 상태가 바뀐 구렁은 모두 ID가 바뀌었다)
--         아직 한쪽 ID만 확인된 구렁은 1개만 적혀 있다. 확인되지 않은 ID의 아이콘이 나타나면
--         같은 지도에서 이름이 같은 미등록 아이콘을 찾아 자동으로 학습하고(HoneyDelveDB.LearnedPOIs),
--         /hdt locale에 "learned"로 표시한다. 그 값을 여기에 옮겨 적으면 된다.
-- variants: 이야기 변형 ID 목록
addon.DelveList = {
    { key = "UniversityUproar",  zone = 2395, mapID = 2395, poiIDs = {8425, 8426}, variants = {7423, 7424, 7425, 7773} },
    { key = "ShadowRetreat",     zone = 2395, mapID = 2395, poiIDs = {8437, 8438}, variants = {7429, 7430, 7431, 7782} },
    { key = "Darkway",           zone = 2395, mapID = 2395, poiIDs = {8439, 8440}, variants = {7435, 7436, 7437, 8268} },
    { key = "MurihaePlaza",      zone = 2395, mapID = 2424, poiIDs = {8427, 8428}, variants = {7411, 7412, 7413, 7753} },
    { key = "AtalAman",          zone = 2437, mapID = 2437, poiIDs = {8443, 8444}, variants = {7420, 7421, 7422, 8165} },
    { key = "TwilightCrypt",     zone = 2437, mapID = 2437, poiIDs = {8441, 8442}, variants = {7432, 7433, 7434, 7677} }, -- 8442: 2026-10-12 자동 학습으로 확인
    { key = "SunkillerSanctum",  zone = 2405, mapID = 2405, poiIDs = {8429},       variants = {7414, 7415, 7416} },       -- 풍요 아이콘 ID 미확인
    { key = "ShadowguardPoint",  zone = 2405, mapID = 2405, poiIDs = {8431},       variants = {7417, 7418, 7419, 8173} }, -- 풍요 아이콘 ID 미확인
    { key = "BayOfMemory",       zone = 2413, mapID = 2413, poiIDs = {8435, 8436}, variants = {7426, 7427, 7428} },       -- 8436: 2026-10-12 자동 학습으로 확인
    { key = "GrudgePit",         zone = 2413, mapID = 2413, poiIDs = {8433, 8434}, variants = {7333, 7334, 7335, 7701} },
    { key = "NaldorIsle",        zone = 2512, mapID = 2512, poiIDs = {8760, 8761}, variants = {7976, 7979, 7980} },
    { key = "ArenaOfGlory",      zone = 2512, mapID = 2512, poiIDs = {8763, 8764}, variants = {7986, 7987, 7988} },
}

-- 대시보드에서 제외하는 구렁 지도 아이콘 (poiID)
-- 대시보드는 DelveList에 있는 구렁만 표시하므로 이 목록은 /hdt locale 출력에서 빼는 용도이다.
-- 8779: 맹독폭포 심연 (시즌별 구렁 숙적이 등장하는 특수 구렁, 줄아만과 똬리의 섬 지도에 표시됨)
addon.IgnoredDelvePOIs = {
    [8779] = true,
}

-- 이야기 변형 기본 등급 (이야기 변형 ID를 키로 사용)
-- 등급은 언어와 무관하므로 여기에 둔다. 사용자가 설정창에서 바꾸면 SavedVariables에 따로 저장된다.
addon.DefaultData = {
    -- 영원노래 숲 (2395)
    [7423] = { grade = "A" },
    [7424] = { grade = "B" },
    [7425] = { grade = "D" },
    [7773] = { grade = "D" },
    [7429] = { grade = "C" },
    [7430] = { grade = "F" },
    [7431] = { grade = "F" },
    [7782] = { grade = "F" },
    [7435] = { grade = "C" },
    [7436] = { grade = "F" },
    [7437] = { grade = "A" },
    [8268] = { grade = "B" },
    [7411] = { grade = "A" },
    [7412] = { grade = "F" },
    [7413] = { grade = "F" },
    [7753] = { grade = "F" },

    -- 줄아만 (2437)
    [7420] = { grade = "D" },
    [7421] = { grade = "D" },
    [7422] = { grade = "C" },
    [8165] = { grade = "D" },
    [7432] = { grade = "B" },
    [7433] = { grade = "C" },
    [7434] = { grade = "D" },
    [7677] = { grade = "F" },

    -- 공허폭풍 (2405)
    [7414] = { grade = "B" },
    [7415] = { grade = "F" },
    [7416] = { grade = "D" },
    [7417] = { grade = "F" },
    [7418] = { grade = "C" },
    [7419] = { grade = "F" },
    [8173] = { grade = "D" },

    -- 하란다르 (2413)
    [7333] = { grade = "F" },
    [7334] = { grade = "D" },
    [7335] = { grade = "F" },
    [7701] = { grade = "F" },
    [7426] = { grade = "F" },
    [7427] = { grade = "D" },
    [7428] = { grade = "S" },

    -- 똬리의 섬 (2512)
    [7976] = { grade = "F" },
    [7980] = { grade = "F" },
    [7979] = { grade = "F" },
    [7986] = { grade = "A" },
    [7987] = { grade = "C" },
    [7988] = { grade = "C" },
}
