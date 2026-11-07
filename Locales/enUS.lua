local AddonName, addon = ...

-- =========================================================
-- English (enUS)
-- Also used for every client language that has no locale file of its own.
-- Names (delves, story variants, currencies, items) are read from the game by the IDs in DB.lua.
-- The Names, Delves and Variants sections here are only the defaults shown until the game value is available.
--   UI       : missing lines fall back to Korean (koKR.lua)
--   Variants : missing names fall back to the name saved from the game, then to Korean
--   Game     : never falls back (it must match the text your client shows)
--   Memos    : missing memos are shown empty instead of Korean
-- /hdt locale prints the in-game values (names, widget texts, map icon IDs) used to fill this file.
-- =========================================================
addon.Locales = addon.Locales or {}

addon.Locales.enUS = {
    -- Dashboard and settings text
    -- Names that cannot be read from the game by ID are written by hand below; all of them were checked on an English client.
    UI = {
        TITLE = "HoneyDelveToday",
        BINDING_DASHBOARD = "Toggle dashboard",
        BINDING_CONFIG = "Toggle settings",
        LDB_TOOLTIP = "Left-click: Dashboard\nRight-click: Settings",
        GRACE_ALERT = "[HDT] Use your %s!",
        GRACE_ALERT_WAIT = "[HDT] Open the hidden chest after the weekly reset",
        GRACE_ALERT_USED = "[HDT] Bounty used",
        GRACE_ALERT_CLICK ="Click to use. (Drag to move)",
        ABUNDANCE = "Abundantly Bountiful",

        -- Settings: General
        OPT_GENERAL = "General",
        OPT_COMMANDS = "Commands: /hdt (dashboard) /hdtset (settings)",
        OPT_LANGUAGE_GROUP = "Addon language",
        OPT_LANGUAGE_DESC = "The language of the dashboard and settings text and of the default memos. Names such as delves, story variants and currencies are always shown in your game client language, regardless of this setting. A new language is applied after reloading the UI.",
        OPT_LANGUAGE = "Language",
        OPT_LANGUAGE_AUTO = "Automatic (game client language)",
        OPT_RELOAD = "Reload UI",
        OPT_RELOAD_DESC = "Reloads the UI to apply the new language. (Same as /reload)",
        OPT_LANGUAGE_PENDING = "The new language will be applied after reloading the UI.",
        OPT_SHOW_MINIMAP = "Show minimap icon",
        OPT_SHOW_MEMO = "Show memos",
        OPT_GRACE_ALERT = "Show bounty item alert",
        OPT_GRACE_ALERT_DESC = "Shows an alert in the middle of the screen inside a delve while you have %s in your bags. Click the alert to use the item. If you already claimed this week's hidden chest reward, it instead warns you to open the hidden chest after the weekly reset while the bounty effect is still active.",

        -- Settings: Dashboard trackers
        OPT_TRACKER_GROUP = "Dashboard trackers",
        OPT_SHOW_FMT = "Show %s",
        OPT_SHOW_VAULT_WORLD = "Show Great Vault hero track progress",
        OPT_VAULT_WORLD_DESC = "Shows how many slots in the World row of the Great Vault are unlocked by tier 8 or higher activities, and this week's top activities.",
        OPT_MANA_CRYSTAL_DESC = "Shows your %s balance and how many you earned this week (weekly cap 250).",

        -- Settings: World quest rewards
        OPT_WQ_GROUP = "World quest rewards",
        OPT_SHOW_BOUNTY = "Show weekly zone bounty status",
        OPT_SHOW_WQ_GOLD = "Show gold world quests",
        OPT_SHOW_ZONE_META = "Show special assignment status",

        -- Settings: Delve-o-Bot 7001 (NPC name as shown in game; the update chip item uses "Delve-O-Bot")
        OPT_DELVEBOT_GROUP = "Delve-o-Bot 7001",
        OPT_DELVEBOT_DESC = "Automatically picks \"Take me to a Midnight delve please.\" when you talk to Delve-o-Bot 7001. Hold Shift while talking to skip it.",
        OPT_AUTO_DELVEBOT = "Auto-select Midnight delve",
        OPT_REQUIRE_BOUNTIFUL = "Don't auto-select when no Bountiful Midnight delve is left",
        OPT_REQUIRE_BOUNTIFUL_DESC = "Without a Bountiful delve, Delve-o-Bot sends you to a random regular delve. With this option on, auto-select is skipped and a notice is shown when you have already cleared today's Bountiful Midnight delves, or when you are below level 90 and cannot enter Bountiful delves.",

        -- Settings: Dundun (Abundantly Bountiful)
        OPT_DUNDUN_GROUP = "Dundun (Abundantly Bountiful)", -- NPC name as written by Icy Veins ("Dundun, the Loa of Abundance")
        OPT_DUNDUN_DESC = "Shows how many %s you have next to Dundun's accept option. Abundantly Bountiful gives two Bountiful chests, so you need two keys to open both. (2 or more in green, fewer in red)",
        OPT_SHOW_DUNDUN_HINT = "Show %s count next to Dundun's option",

        -- Settings: Layout, key bindings, data
        OPT_LAYOUT_GROUP = "Dashboard layout",
        OPT_BG_ALPHA = "Background opacity",
        OPT_FONT_SIZE = "Font size",
        OPT_KEYBIND_GROUP = "Key bindings",
        OPT_DATA_GROUP = "Data",
        OPT_RESET_WARNING = "Warning: the button below permanently deletes every grade and memo you have edited.",
        OPT_RESET_NOTE = "Entries added in new versions, and default memos you have not edited, are applied automatically without a reset.",
        OPT_RESET_BUTTON = "Reset all data (delete all grades and memos)",
        OPT_RESET_BUTTON_DESC = "Deletes every grade and memo you have edited and restores the defaults. This cannot be undone.",
        OPT_RESET_CONFIRM = "Are you sure you want to reset?\nEvery grade and memo you have written will be deleted, and this cannot be undone.\n\nIf you only miss entries added in a new version, logging in again is enough.",

        -- Settings: Story variants
        OPT_GRADE = "Grade",
        OPT_MEMO = "Memo",
        OPT_MEMO_RESET = "Default memo",
        OPT_MEMO_RESET_DESC = "Restores this variant's memo to the default. After that, default memos from new versions are applied automatically.",
        OPT_VARIANT_NAME_NOTE = "Delve and story variant names are shown as read from the game. A story variant name can only be read on the day it is active, so until then the last name read from the game or the addon's default name is shown.",
        VARIANT_UNKNOWN_FMT = "Unseen variant (%d)",

        -- Dashboard
        FMT_LABEL_VALUE = "%s: %s",
        STATUS_UNUSED = "Not used",
        STATUS_USED = "Used",
        STATUS_NOT_OBTAINED = "Not obtained",
        STATUS_ACTIVE = "Active",
        NOTE_OPEN_CHEST = "(open the hidden chest for the reward)",
        NOTE_OPEN_AFTER_RESET = "(open the hidden chest after the reset)",
        NOTE_EXTRA_NEXT_WEEK = "(+1 in bags, use next week)",
        BOUNTY_DONE = "Done",
        BOUNTY_NOT_DONE = "Not done",
        UNAVAILABLE = "Unavailable",
        STASH_IN_DELVE = "Not available inside a delve",
        VAULT_HEADER = "Great Vault hero track",
        VAULT_SLOT_FMT = "%d slot (%d/%d)",
        VAULT_SLOTS_FMT = "%d slots (%d/%d)",
        VAULT_LEVEL_FMT = "T%d(%d)",
        NONE = "None",
        META_AVAILABLE = "Available",
        META_LOCKED_FMT = "Locked (%d/3)",
        LOADING = "Loading",

        -- Dundun gossip window
        DUNDUN_HINT_FMT = "(%s%d)",
        KEY_FALLBACK = "Key",

        -- Chat messages
        MSG_RESET_DONE = "All data has been reset to defaults.",
        MSG_NEW_ENTRIES = "%d new delve/variant entries were added. (Your grades and memos are kept)",
        MSG_SHIFT_SKIP = "Shift is held, auto-select skipped.",
        MSG_BOUNTIFUL_LEVEL = "Bountiful Midnight delves require level %d, so auto-select was skipped.",
        MSG_NO_BOUNTIFUL = "No Bountiful Midnight delve is left today, so auto-select was skipped. (Selecting it would send you to a regular delve)",
        MSG_NO_MIDNIGHT_OPTION = "The Midnight delve option is missing, so auto-select was skipped. (Buy \"Delve-O-Bot 7001: Midnight Software Update Chip\" from the vendor in Silvermoon)",
        MSG_DELVEBOT_SELECTED = "Delve-o-Bot 7001: Midnight delve selected automatically.",
        MSG_DELVEBOT_DEFAULT_OFF = "Delve-o-Bot 7001 auto-select is now off by default. Turn it on in /hdtset if you want to use it.",
        MSG_DUNDUN_KEYS = "%s: %s %s%d|r (%d needed to open both chests)",
        MSG_GRACE_CLAIMED = "Recorded this week's %s reward as claimed.",
        MSG_GRACE_EXTRA = "You already claimed this week's %s reward. Use the new one next week.",
        MSG_USAGE = "Usage: /hdt (dashboard) | /hdtset (settings)",

        -- /hdt locale output
        DUMP_HEADER = "Translation info (version: %s, client: %s, display language: %s)",
        DUMP_ZONES = "[Zones] map ID = in-game zone name",
        DUMP_DELVES = "[Delves] internal key / map ID / poiIDs in DB.lua = found poiID(source) name (state)",
        DUMP_POIS = "[Delve map icons] map ID %d : poiID = name (atlas)",
        DUMP_VARIANTS = "[Active story variants] variant ID = widget text (delve key)",
        DUMP_UNKNOWN_VARIANT = "(not in the addon's list)",
        DUMP_NAMES = "[In-game names] key = name read from the game",
        DUMP_META = "[Special assignments] zone map ID = result",
        DUMP_META_POI = "  locked icon poiID %s = %s (widgetSetID %s, tooltipWidgetSet %s, map %s)",
        DUMP_META_MAP = "  map %s has %d icons (listed below except delve icons)",
        DUMP_META_ALLPOI = "    poiID %s = %s (atlas %s, isPrimaryMapForPOI %s, tooltipWidgetSet %s)",
        DUMP_META_WIDGET = "  widget %s = %s",
        DUMP_META_QUEST = "  quest %s = %s (worldQuestType %s)",
        DUMP_META_SCAN = "[Special assignment widget search] widgets not in DB.lua whose text contains a zone name",
        DUMP_NAME_CANDIDATES = "[Name candidates] in-game name candidates for items still shown with locale text",
        DUMP_GOSSIP = "[Open gossip window] option ID = text",
        DUMP_NPC = "Gossip NPC name = %s",
        DUMP_ERROR = "Error while printing: %s",
        DUMP_END = "End of output. Please paste this into a GitHub issue or pull request.",
    },

    -- Default names (used only when the name cannot be read from the game)
    -- The dashboard and settings show the name read from the game by the IDs in DB.lua first;
    -- these are the fallback until then. Names and Delves were confirmed with /hdt locale on an English client;
    -- Variants come from the HoneyDelveToday name table, checked against the game where it was seen.

    -- Currency, item and spell names (key: NAME_SOURCES in Locale.lua)
    Names = {
        RestoredKey = "Restored Coffer Key",
        KeyShard = "Coffer Key Shards",
        ManaCrystal = "Untainted Mana-Crystals",
        Marl = "Voidlight Marl",
        MythCrest = "Myth Mistcrest",
        Grace = "Trovehunter's Bounty",
        Stash = "Gilded Stash",
    },

    -- Delve names (key: DelveList key)
    -- Used to find a delve's new map icon ID automatically, so they must match the in-game name exactly.
    Delves = {
        -- Eversong Woods (2395)
        UniversityUproar = "Collegiate Calamity",
        ShadowRetreat = "The Shadow Enclave",
        Darkway = "The Darkway",
        MurihaePlaza = "Parhelion Plaza",

        -- Zul'Aman (2437)
        AtalAman = "Atal'Aman", -- straight apostrophe as in the game (name table uses a curly one)
        TwilightCrypt = "Twilight Crypts",

        -- Voidstorm (2405)
        SunkillerSanctum = "Sunkiller Sanctum",
        ShadowguardPoint = "Shadowguard Point",

        -- Harandar (2413)
        BayOfMemory = "The Gulf of Memory",
        GrudgePit = "The Grudge Pit",

        -- The Coiled Isle (2512)
        NaldorIsle = "Gnarldor Isle",
        ArenaOfGlory = "The Ring of Glory",
    },

    -- Story variant names (key: story variant ID)
    -- Defaults from the HoneyDelveToday name table (2026-10-11). Where the game text differs from the table,
    -- the game text is used so the default matches what the game shows.
    Variants = {
        -- Eversong Woods (2395)
        [7423] = "Invasive Glow",
        [7424] = "Academy Under Siege",
        [7425] = "Faculty of Fear",
        [7773] = "An Elementary Antidote", -- game text (name table: "An Elementary Anditode")
        [7429] = "Traitor's Due",
        [7430] = "Shadowy Supplies",
        [7431] = "Mirror Shine",
        [7782] = "Infiltrate and Ameliorate",
        [7435] = "Focusers Under Pressure",
        [7436] = "Leyline Technician",
        [7437] = "Ogre Powered",
        [8268] = "Eggsplosive Growth",
        [7411] = "Holding the Line",
        [7412] = "March of the Arcane Brigade",
        [7413] = "Bombing Run",
        [7753] = "Caustic Crush",

        -- Zul'Aman (2437)
        [7420] = "Totem Annihilation",
        [7421] = "Ritual Interrupted",
        [7422] = "Toadly Unbecoming",
        [8165] = "Venomous Vapors",
        [7432] = "Party Crasher",
        [7433] = "Trapped!",
        [7434] = "Loosed Loa",
        [7677] = "Why Did it Have to Be Snakes?",

        -- Voidstorm (2405)
        [7414] = "Core of the Problem",
        [7415] = "The Gravitational Effect",
        [7416] = "Not What I Expected",
        [7417] = "Stolen Mana",
        [7418] = "Calamitous",
        [7419] = "Captured Wildlife",
        [8173] = "Basalisk Blitz", -- game text (name table: "Basilisk Blitz")

        -- Harandar (2413)
        [7426] = "Descent of the Haranir",
        [7427] = "Alnmoth Munchies",
        [7428] = "Sporasaur Special",
        [7333] = "Dastardly Rotstalk",
        [7334] = "Arena Champion",
        [7335] = "Lightbloom Invasion",
        [7701] = "Fungal Pharmacon",

        -- The Coiled Isle (2512)
        [7976] = "Speaking Their Language",
        [7979] = "Minchi's Osseous Adventure",
        [7980] = "Olds and Ends",
        [7986] = "Adopt-a-thon",
        [7987] = "Game Day",
        [7988] = "Open Night",
    },

    -- Values that describe the format of game text (used only on English clients)
    -- These are not names; names are always read from the game.
    Game = {
        -- Beginning of a special assignment quest title (fallback for the unlocked check; the quest tag is checked first)
        -- Confirmed on the map tooltip ("Special Assignment: The Grand Magister's Drink")
        SpecialAssignmentTitle = "Special Assignment:",
        -- Beginning of the story variant widget text, before the variant name, including the trailing space
        -- Confirmed with /hdt locale ("Story Variant: Ogre Powered")
        VariantPrefix = "Story Variant: ",
    },

    -- Default memos (key: story variant ID)
    -- AI translation (2026-10-11) of the Korean memos in koKR.lua. Some NPC, object and mechanic names may not
    -- match the official English names yet; correct them when they are checked in game.
    -- The comment at the end is "delve / variant" for reference only; the addon reads all names from the game.
    Memos = {
        -- Eversong Woods (2395)
        [7423] = "Clear 70 Pottlings -> kill enemies + destroy light bulbs -> boss (the weed whacker one-shots trash, very short)", -- Collegiate Calamity / Invasive Glow
        [7424] = "Fill the enemy kill bar + activate 4 arcane wards -> boss (simple combat, short route)", -- Collegiate Calamity / Academy Under Siege
        [7425] = "Use the Eye of Revelation to find disguised Blades -> kill enemies -> boss (suspects show yellow / through walls)", -- Collegiate Calamity / Faculty of Fear
        [7773] = "Investigate the antidote with Finley -> cleanse poisoned areas as you go -> boss (fungal salve removes poison pools)", -- Collegiate Calamity / An Elementary Antidote
        [7429] = "Destroy 2 void focus points -> stop 3 rituals + kill enemies -> boss (some early parts can be skipped, boss has an immune phase)", -- The Shadow Enclave / Traitor's Due
        [7430] = "Collect 30 Twilight supplies -> boss (ground objects + mob drops, long gathering route)", -- The Shadow Enclave / Shadowy Supplies
        [7431] = "Use mirrors to destroy 6 shadow nexus points -> boss (carrying and aiming mirrors is tedious)", -- The Shadow Enclave / Mirror Shine
        [7782] = "Infiltrate the Ulatek cultists -> deal with summoners + gather reagents to taint the cauldron -> boss (includes jump mushrooms)", -- The Shadow Enclave / Infiltrate and Ameliorate
        [7435] = "Kill Oglok -> collect and place 6 ley focusers -> boss (watch out for tracking lasers while moving)", -- The Darkway / Focusers Under Pressure
        [7436] = "Adjust ley conduits + kill enemies -> activate 3 focusing crystals -> boss (use each conduit only once)", -- The Darkway / Leyline Technician
        [7437] = "Kill 7 unstable mutants -> boss (simple kill objective, fastest variant)", -- The Darkway / Ogre Powered
        [8268] = "Clear Ulatek egg nests as you go -> boss (cleansing ley devices destroys the eggs safely)", -- The Darkway / Eggsplosive Growth
        [7411] = "Repair barricades + kill invaders -> boss (mount allowed, legendary weapon usable)", -- Parhelion Plaza / Holding the Line
        [7412] = "Kill enemies + use the sentinel to destroy void crystal spires -> boss (requires guiding the machine)", -- Parhelion Plaza / March of the Arcane Brigade
        [7413] = "Carry the arcane device into void portals and destroy them, repeat -> boss (device lasts 40 sec, dropped in combat)", -- Parhelion Plaza / Bombing Run
        [7753] = "Push through Ulatek slime areas + clear the path with fungal salve -> boss (getting hit by the poison wave stuns / deals heavy damage)", -- Parhelion Plaza / Caustic Crush

        -- Zul'Aman (2437)
        [7420] = "Kill enemies + destroy 7 cursed totems -> boss (mount allowed, drums give a speed boost)", -- Atal'Aman / Totem Annihilation
        [7421] = "Rescue 7 captured Spiritpaws -> stop Nalorakk's ritual / waves -> boss (combat is forced)", -- Atal'Aman / Ritual Interrupted
        [7422] = "Kill enemies + free 20 frogs with the hex wand -> boss (movement help makes it fairly quick)", -- Atal'Aman / Toadly Unbecoming
        [8165] = "Cleanse poison with Mala as you go -> boss (use the cleansing tool, watch poison pools / dangerous casts)", -- Atal'Aman / Venomous Vapors
        [7432] = "Kill summoners + pull levers to move between floors -> boss (watch out for bear traps)", -- Twilight Crypts / Party Crasher
        [7433] = "Go through the maze + rescue hostages + find levers -> boss (lots of traps)", -- Twilight Crypts / Trapped!
        [7434] = "Kill the beguilers + destroy totems as you go -> boss (watch out for the roaming loa)", -- Twilight Crypts / Loosed Loa
        [7677] = "Investigate snake relics + step on snakes -> boss (watch out for snake explosions, salve removes poison)", -- Twilight Crypts / Why Did it Have to Be Snakes?

        -- Voidstorm (2405)
        [7414] = "Travel through portals + collect 50 charged cores + kill enemies -> boss (core stacks give more speed / less damage taken)", -- Sunkiller Sanctum / Core of the Problem
        [7415] = "Recover 5 gravity devices -> kill enemies + place 5 devices -> boss (lots of movement mechanics)", -- Sunkiller Sanctum / The Gravitational Effect
        [7416] = "Kill void / Lightbloom enemies + seal Lightbloom crates -> destroy 3 shadowroots (no boss)", -- Sunkiller Sanctum / Not What I Expected
        [7417] = "Disable mana siphons + overload reservoirs -> boss (mount allowed but the map is large)", -- Shadowguard Point / Stolen Mana
        [7418] = "Watch-Captain Meti -> emergency portal -> overload 5 stabilizers + kill enemies -> boss (large map)", -- Shadowguard Point / Calamitous
        [7419] = "Free 12 wildlife + kill enemies -> deal with 4 researchers -> boss (freed beasts can attack you too)", -- Shadowguard Point / Captured Wildlife
        [8173] = "Retake occupied areas + deal with basilisks -> block shields as you go -> boss (touching barriers stuns you)", -- Shadowguard Point / Basalisk Blitz

        -- Harandar (2413)
        [7426] = "4 giant candles + 8 treasures -> rescue 4 Haranir -> kill enemies -> boss (many tentacles / interactions)", -- The Gulf of Memory / Descent of the Haranir
        [7427] = "Use the Alnmoth to eat Lightbloom growths + kill enemies -> boss (extra action button deals AoE damage)", -- The Gulf of Memory / Alnmoth Munchies
        [7428] = "Kill 3 Lightbloom Sporasaurs + kill enemies -> boss (simple objective, spores can be used for damage)", -- The Gulf of Memory / Sporasaur Special
        [7333] = "6 Fan Favor + kick 8 followers -> taunt the crowd + kill enemies -> dig up / kill 8 rivals -> boss (many steps, very long)", -- The Grudge Pit / Dastardly Rotstalk
        [7334] = "Arena waves -> Mirespot / Moldrus / Deathcap -> boss (lots of forced combat)", -- The Grudge Pit / Arena Champion
        [7335] = "Rescue 6 fighters + kill Lightbloom -> defend the center -> blow up 3 thornmaws -> boss (many waves, long)", -- The Grudge Pit / Lightbloom Invasion
        [7701] = "Get 4 fungal salves -> destroy 4 ritual pillars -> boss (salve locations shown on the minimap)", -- The Grudge Pit / Fungal Pharmacon

        -- The Coiled Isle (2512)
        [7976] = "Rescue 3 turtles + recover war turtle gear -> ride the war turtle + kill 50 Gnarldorin -> boss (long because of the 50 kills)", -- Gnarldor Isle / Speaking Their Language
        [7979] = "Investigate 6 bone piles + recover 6 Gnarldorin hearts -> perform the ritual -> boss (a wave at every bone pile, long with lots of combat)", -- Gnarldor Isle / Minchi's Osseous Adventure
        [7980] = "Recover 30 Tortollan relics / supplies + rescue 8 captured Tortollans -> boss (large map, only kill what you need)", -- Gnarldor Isle / Olds and Ends
        [7986] = "Rescue 8 animals + fill the rival kill bar to 100 -> boss (animals run away and are annoying to click, corner them first)", -- The Ring of Glory / Adopt-a-thon
        [7987] = "Get the head ball + score 8 goals on the pillars -> boss (time your kicks between the masks, the same goal can be reused)", -- The Ring of Glory / Game Day
        [7988] = "Clear the arena floor 4 times -> Crushfoot -> 3 murlocs -> Brinebeater -> Guskar -> 3 ghost trolls -> boss (back-to-back minibosses, interrupts matter)", -- The Ring of Glory / Open Night
    },
}