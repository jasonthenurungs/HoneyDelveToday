# HoneyDelveToday

A World of Warcraft addon that shows today's delve information at a glance: which delves are Bountiful, which story variant is active in each delve, how good that variant is, and your weekly delve progress.

Supports Korean (koKR) and English (enUS) clients.

[한국어 설명은 아래에 있습니다.](#한국어)

## Features

### Dashboard (`/hdt`)

- Weekly trackers: Restored Coffer Key, Coffer Key Shards, Untainted Mana-Crystals, Trovehunter's Bounty, Abundantly Bountiful, Gilded Stash, and Great Vault hero track progress
- For each zone: weekly bounty status, gold / Voidlight Marl / Coffer Key Shard world quests, and special assignment status
- For each delve: Bountiful icon, today's story variant, its grade (S to F), and a short route memo

### Helpers

- Delve-o-Bot 7001: automatically picks the Midnight delve option when you talk to it (hold Shift to skip). It can skip auto-selection when no Bountiful Midnight delve is left.
- Dundun: shows how many Restored Coffer Keys you have next to the Abundantly Bountiful option (two keys are needed to open both chests).
- An on-screen alert inside a delve while you still have an unused Trovehunter's Bounty.

### Settings (`/hdtset`)

- Show or hide every dashboard tracker
- Edit the grade and memo of each story variant (your edits are kept across updates)
- Background opacity, font size, key bindings, minimap icon
- Addon language (Automatic / 한국어 / English)

## Supported zones

Eversong Woods, Zul'Aman, Voidstorm, Harandar, The Coiled Isle (Midnight Season 2)

## How names work

Delve, story variant, currency and item names are read from your game client by ID, so they always match what your game shows. The addon only keeps default names to show until the game value is available.

English memos are AI-translated from the Korean memos. Some NPC, object and mechanic names may differ from the official English names.

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/honeydelvetoday) or from the [Releases](../../releases) page of this repository.
2. Extract it so that the folder is `World of Warcraft/_retail_/Interface/AddOns/HoneyDelveToday`.
3. Restart the game or type `/reload`.

Please do not use GitHub's "Download ZIP" button. It renames the folder to `HoneyDelveToday-main`, which breaks the addon icon.

## Files

| File | What it holds |
| --- | --- |
| `HoneyDelveToday.toc` | Addon metadata and load order |
| `Bindings.xml` | Key binding definitions |
| `Locales/koKR.lua`, `Locales/enUS.lua` | UI text, default names and memos for each language |
| `Locales/Locale.lua` | Language selection and reading names from the game |
| `DB.lua` | Language independent data: map IDs, delve icon IDs, story variant IDs, default grades |
| `Core.lua` | Dashboard, settings and all addon logic |
| `libs/` | Ace3, LibDataBroker, LibDBIcon (each under its own license) |

## Feedback

Bug reports and feedback are welcome. [GitHub Issues](https://github.com/jasonthenurungs/HoneyDelveToday/issues) are recommended because reports stay on record and are easy to follow up. You can also leave a message in the [CurseForge comments](https://www.curseforge.com/wow/addons/honeydelvetoday/comments).

When reporting a bug, please include your client language and, if possible, the output of `/hdt locale`.

This addon is developed as a personal hobby project, so code contributions (pull requests) are not accepted.

## Credits

- Author: Nurungs
- Special thanks to 김귀태 for the HoneyDelveToday FanFix and the story variant memos

## License

The addon code is released under the MIT License. The libraries in `libs/` keep their own licenses.

---

# 한국어

오늘의 구렁 정보를 한눈에 보여주는 월드 오브 워크래프트 애드온입니다. 오늘 풍요로운 구렁이 어디인지, 구렁마다 어떤 이야기 변형이 열렸는지, 그 변형이 얼마나 좋은지, 그리고 이번 주 구렁 진행 상황을 보여줍니다.

한국어(koKR)와 영어(enUS) 클라이언트를 지원합니다.

## 기능

### 대시보드 (`/hdt`)

- 주간 추적 요소: 복원된 금고 열쇠, 금고 열쇠 파편, 정순한 마나 수정, 보물 추적자의 은혜, 넘칠듯한 풍요로움, 금빛 보관함, 위대한 금고 영웅템 주차
- 지역별: 주간 평판(영예) 획득 여부, 골드 / 공허불빛 이회토 / 금고 열쇠 파편 전역 퀘스트, 특별과제 상태
- 구렁별: 풍요 아이콘, 오늘의 이야기 변형, 변형 등급(S~F), 공략 메모

### 편의 기능

- 구렁로봇 7001: 대화하면 한밤 구렁을 자동으로 선택합니다. (Shift를 누른 채 대화하면 건너뜀) 풍요로운 한밤 구렁이 없으면 자동 선택을 하지 않도록 설정할 수 있습니다.
- 둔둔: 넘칠듯한 풍요로움 선택지 옆에 보유 중인 복원된 금고 열쇠 개수를 표시합니다. (상자 2개를 모두 열려면 열쇠 2개 필요)
- 구렁 안에서 보물 추적자의 은혜를 아직 사용하지 않았으면 화면에 알림을 띄웁니다.

### 설정창 (`/hdtset`)

- 대시보드 추적 요소별 표시 여부
- 이야기 변형별 등급과 메모 수정 (직접 수정한 내용은 업데이트 후에도 유지)
- 배경 투명도, 글씨 크기, 단축키, 미니맵 아이콘
- 애드온 언어 (자동 / 한국어 / English)

## 지원 지역

영원노래 숲, 줄아만, 공허폭풍, 하란다르, 똬리의 섬 (한밤 2시즌)

## 이름 표시 방식

구렁, 이야기 변형, 화폐, 아이템 이름은 ID 기준으로 게임 클라이언트에서 읽어 와서 항상 게임과 같은 이름으로 표시합니다. 애드온에는 게임에서 읽기 전까지 보여줄 기본 이름만 들어 있습니다.

영어 클라이언트의 메모는 한국어 메모를 AI로 번역한 것이라, 일부 NPC, 오브젝트, 기믹 이름이 공식 영문 명칭과 다를 수 있습니다.

## 설치

1. [커스포지](https://www.curseforge.com/wow/addons/honeydelvetoday) 또는 이 저장소의 [Releases](../../releases) 페이지에서 최신 버전을 내려받습니다.
2. 압축을 풀어 `World of Warcraft/_retail_/Interface/AddOns/HoneyDelveToday` 폴더가 되도록 넣습니다.
3. 게임을 다시 시작하거나 `/reload`를 입력합니다.

GitHub의 "Download ZIP" 버튼은 사용하지 마세요. 폴더 이름이 `HoneyDelveToday-main`으로 바뀌어 애드온 아이콘이 깨집니다.

## 파일 구성

| 파일 | 내용 |
| --- | --- |
| `HoneyDelveToday.toc` | 애드온 정보와 불러오는 순서 |
| `Bindings.xml` | 단축키 정의 |
| `Locales/koKR.lua`, `Locales/enUS.lua` | 언어별 화면 문구, 기본 이름, 메모 |
| `Locales/Locale.lua` | 언어 선택과 게임 이름 조회 |
| `DB.lua` | 언어와 무관한 데이터: 지도 ID, 구렁 아이콘 ID, 이야기 변형 ID, 기본 등급 |
| `Core.lua` | 대시보드, 설정창 등 애드온 동작 전체 |
| `libs/` | Ace3, LibDataBroker, LibDBIcon (각 라이브러리 고유 라이선스) |

## 피드백

버그 제보와 의견은 언제나 환영합니다. 기록이 남아 처리 상황을 확인하기 쉬운 [깃허브 이슈](https://github.com/jasonthenurungs/HoneyDelveToday/issues)를 권장하며, [커스포지 댓글](https://www.curseforge.com/wow/addons/honeydelvetoday/comments)로 남기셔도 됩니다.

버그를 제보하실 때는 게임 클라이언트 언어와, 가능하면 `/hdt locale` 출력 결과를 함께 적어 주세요.

개인 취미로 개발하는 애드온이라 코드 기여(풀 리퀘스트)는 받지 않습니다.

## 크레딧

- 제작: Nurungs
- HoneyDelveToday FanFix와 이야기 변형 메모를 제공해 주신 김귀태님께 감사드립니다.

## 라이선스

애드온 코드는 MIT 라이선스로 공개합니다. `libs/` 폴더의 라이브러리는 각자의 라이선스를 따릅니다.
