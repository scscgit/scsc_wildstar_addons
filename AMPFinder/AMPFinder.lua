------------------------------------------------------------------------------------------------
-- Client Lua Script for AMPFinder
-- 2014-04-19, Tomii
-- version 1.6.6, 2014-08-05

-- TODO: fix alignment for prestige
-- TODO: Add currency to tooltips

-- WATCHING: Save/restore window position. Compact window position restored but it is very clunky
-- WATCHING: PVP may not be setting factions we understand. Error message made a bit more obvious to aid troubleshooting.

-- TODO? UpdateArrowVendor and Questgiver -- Show the arrow, but also show a message
-- TODO: UpdateArrowQuestgiver - Display a message if they're ON the quest and haven't completed it 
-- 			an arrow to the questgiver itself is misleading
-- TODO: update vendor display if you learn an amp with the vendor window open


-- special thanks to:
--   Carbine for the fantastic game
--   WildstarNasa crew for their tutorials
--   Woode, FirefoxMetzger, Sinaloit, MacHaggis, and Tomed on the addon forums
--   Skaar, Dathlan, and the Pulse guild (Dominion - EU) for the AMP listings
--	 Curse.com for their excellent support
--   The Curse and WildStar forums community
--   Maekess and @kuribo_power for French translation
--	 _Grim from the WildStar forums (http://www.GrimPlays.de/)
--   EVERYONE who's downloaded and given the addon a try
--   all addon authors and enthusiasts everywhere!

-----------------------------------------------------------------------------------------------
 
require "AbilityBook"
require "ChatSystemLib"
require "Episode"
require "Item"
require "Money"
require "Quest"
require "Window"

-----------------------------------------------------------------------------------------------
-- AMPFinder Module Definition
-----------------------------------------------------------------------------------------------
local AMPFinder = {}

local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("AMPFinder", true)

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local knCategoryUtilityId 			= 1
local knCategorySupportId 			= 2
local knCategoryDamageId 			= 3
local knCategoryDamageSupportId 	= 4
local knCategoryDamageUtilitytId 	= 5
local knCategorySupportUtilityId 	= 6

local karCategoryToConstantData =
{
	[knCategoryUtilityId] 			= {"LightBulbS",	"spr_AMPS_MiddleGlow_S", 	Apollo.GetString("AMP_Utility"),	"LabelUtility",		},
	[knCategorySupportId]			= {"LightBulbNE",	"spr_AMPS_MiddleGlow_NE",	Apollo.GetString("AMP_Support"), 	"LabelSupport",		},
	[knCategoryDamageId] 			= {"LightBulbNW",	"spr_AMPS_MiddleGlow_NW", 	Apollo.GetString("AMP_Assault"),	"LabelAssault",		},
	[knCategoryDamageSupportId] 	= {"LightBulbN",	"spr_AMPS_MiddleGlow_N", 	Apollo.GetString("AMP_Hybrid"),		"LabelHybrid",		},
	[knCategoryDamageUtilitytId] 	= {"LightBulbSE",	"spr_AMPS_MiddleGlow_SW", 	Apollo.GetString("AMP_PvPOffense"),	"LabelPvPOffense",	},
	[knCategorySupportUtilityId] 	= {"LightBulbSW",	"spr_AMPS_MiddleGlow_SE", 	Apollo.GetString("AMP_PvPDefense"),	"LabelPvPDefense",	},
}

local knFastDelay = 0.05
local knSlowDelay = 0.5

local knAmpWarrior		= 394
local knAmpEngineer		= 395
local knAmpMedic		= 396
local knAmpStalker		= 397
local knAmpEsper		= 398
local knAmpSpellslinger	= 399

local knClassWarrior	= GameLib.CodeEnumClass.Warrior 	-- 1
local knClassEngineer	= GameLib.CodeEnumClass.Engineer	-- 2
local knClassEsper		= GameLib.CodeEnumClass.Esper		-- 3
local knClassMedic		= GameLib.CodeEnumClass.Medic		-- 4
local knClassStalker 	= GameLib.CodeEnumClass.Stalker		-- 5
local knClassSpellslinger = GameLib.CodeEnumClass.Spellslinger -- 7

local karClassNames = {
	[knClassWarrior]	= Apollo.GetString("ClassWarrior"),
	[knClassEngineer]	= Apollo.GetString("ClassEngineer"),
	[knClassEsper]		= Apollo.GetString("ClassESPER"),
	[knClassMedic]		= Apollo.GetString("ClassMedic"),
	[knClassStalker]	= Apollo.GetString("ClassStalker"),
	[knClassSpellslinger] = Apollo.GetString("ClassSpellslinger"),
}

-- These are exile locations but we're using them as shorthand for both sides
local knLocAutolearned  =  1
local knLocGlenview		=  2 -- starter 1a
local knLocTremor		=  3 -- starter 1b
local knLocQuest		=  4 -- starter 1a/1b
local knLocGallow		=  5 -- starter 2a
local knLocSylvan		=  6 -- starter 2b
local knLocGallowSylvan	=  7 -- starter 2a/2b
local knLocSkywatch		=  8 -- galeras
local knLocThermock		=  9 -- whitevale
local knLocWalkers		= 10 -- farside
local knLocBravo		= 11 -- farside 2
local knLocFoolsHope	= 12 -- wilderrun
local knLocFCON			= 13 -- thayd
local knLocCommodity	= 14 -- thayd
local knLocUnknown		= 15

local knPaneAlgoroc = 17
local knPaneAlgorocQ = -17
local knPaneAuroria = 6
local knPaneCelestion = 5
local knPaneCelestionQ = -5
local knPaneDeradune = 15
local knPaneDeraduneQ = -15
local knPaneEllevar = 7
local knPaneEllevarQ = -7
local knPaneFarside = 28
local knPaneFarsideD = 88 -- Farside: Virtue's Landing (Dominion)
local knPaneFarsideE = 87 -- Farside: Walker's Landing (Exiles)
local knPaneGaleras = 16
local knPaneIllium = 78
local knPaneIlliumC = -78
local knPaneThayd = 14
local knPaneThaydC = -14
local knPaneWhitevale = 2
local knPaneWilderrun = 26
local knPaneComplete 	= -9999
local knPaneCommodity 	= -9998
local ksQuestPanes = knPaneAlgorocQ.."|"..knPaneCelestionQ..
						"|"..knPaneDeraduneQ.."|"..knPaneEllevarQ
local ksVendorPanes = "|"..    --	"|2|5|6|7|14|15|16|17|26|28|78|87|88|"
	knPaneWhitevale.."|"..
	knPaneCelestion.."|"..
	knPaneAuroria.."|"..
	knPaneEllevar.."|"..
	knPaneThayd.."|"..
	knPaneDeradune.."|"..
	knPaneGaleras.."|"..
	knPaneAlgoroc.."|"..
	knPaneWilderrun.."|"..
	knPaneFarside.."|"..
	knPaneIllium.."|"..
	knPaneFarsideE.."|"..
	knPaneFarsideD.."|"

local ktPaneData = {
	[0]					= { "PaneCurrentZone",	nil,			},
	[knPaneAlgoroc] 	= { "PaneAlgoroc", 		knLocGallow,	},
	[knPaneAlgorocQ] 	= { "PaneAlgorocQ",		knLocTremor, 	},
	[knPaneAuroria]		= { "PaneAuroria",		knLocSkywatch,	},	 
	[knPaneCelestion]	= { "PaneCelestion",	knLocSylvan,	},
	[knPaneCelestionQ]	= { "PaneCelestionQ",	knLocGlenview,	},
	[knPaneDeradune]	= { "PaneDeradune", 	knLocGallow,	},
	[knPaneDeraduneQ]	= { "PaneDeraduneQ", 	knLocGlenview,	},
	[knPaneEllevar]		= { "PaneEllevar", 		knLocSylvan,	},
	[knPaneEllevarQ]	= { "PaneEllevarQ",		knLocTremor,	},
	[knPaneFarside]		= { "PaneFarside",		knLocBravo,		},
	[knPaneFarsideD]	= { "PaneFarsideD",		knLocWalkers,	},
	[knPaneFarsideE]	= { "PaneFarsideE",		knLocWalkers,	},
	[knPaneGaleras]		= { "PaneGaleras",		knLocSkywatch,	},
	[knPaneIllium]		= { "PaneIllium",		knLocFCON,		},
	[knPaneIlliumC]		= { "PaneIlliumC",		knLocCommodity,	},
	[knPaneThayd]		= { "PaneThayd",		knLocFCON,		},
	[knPaneThaydC]		= { "PaneThaydC",		knLocCommodity,	},
	[knPaneWhitevale]	= { "PaneWhitevale",	knLocThermock,	},
	[knPaneWilderrun]	= { "PaneWilderrun",	knLocFoolsHope,	},
	[knPaneComplete]	= { "PaneComplete",		nil,			},
}

local kiImbueSpellId = 1
local kiAmpCategory = 2
local kiAmpRank = 3
local kiLocation = 4
local kiItemId = 5

local knDisplayRank = 0
local knDisplayLoc = 1
local knDisplayPrice = 2

local ktUserPrefs = {
	-- "strFilter", -- strFilter is just a confusing thing to save between sessions. dropping it.
	"bShowFilter",
	"bWindowOpen",
	"bCompact",
}

-- [spellID] = {imbueSpellID, category, rank, knLocation, knAmpID},
local AllAmpData = { -- Generated from amp list.xlsx		
	[knClassEngineer] = {	
		[57097] = {56798, 5, 2, 10, 34752}, -- Blast Back / Walkers
		[57332] = {56787, 2, 3, 15, 34742}, -- Boosted Armor / Unknown
		[43210] = {56792, 1, 2, 12, 34747}, -- Bust and Move / FoolsHope
		[43214] = {56805, 1, 3, 12, 34759}, -- Can't Touch This / FoolsHope
		[43160] = {56785, 3, 3, 12, 34740}, -- Cruisin for a Bruisin / FoolsHope
		[57431] = {56816, 6, 2, 13, 41628}, -- Defense Protocol / FCON
		[43187] = {56793, 1, 2, 8, 34748}, -- Deft Restoration / Skywatch
		[57446] = {56786, 6, 2, 13, 41601}, -- Dirty Tricks / FCON
		[43192] = {56808, 5, 3, 13, 41620}, -- Disciplined Soldier / FCON
		[60639] = {-1, 2, 3, 1, -1}, -- Disruptive Module / Autolearned
		[57334] = {56788, 2, 2, 4, 34743}, -- Enmity / Quest
		[43211] = {56781, 4, 3, 12, 34737}, -- Exploit Weakness / FoolsHope
		[57204] = {56790, 3, 2, 13, 41604}, -- Explosive Ammo / FCON
		[43216] = {57550, 3, 2, 10, 35192}, -- Extra Hurtin' / Walkers
		[57472] = {56804, 4, 2, 15, 34758}, -- Forceful Impact / Unknown
		[43247] = {56811, 4, 2, 13, 41623}, -- Hamstring Tear / FCON
		[57395] = {56801, 1, 3, 10, 34755}, -- Hardened Resolve / Walkers
		[57437] = {56784, 3, 2, 5, 34739}, -- Harmful Hits / Gallow
		[43167] = {56795, 6, 2, 7, 34749}, -- Helpin' Hand / GallowSylvan
		[57427] = {70828, 1, 2, 9, 44280}, -- Keep it Moving / Thermock
		[43219] = {56803, 4, 2, 8, 34757}, -- Keep on Truckin' / Skywatch
		[57178] = {70829, 5, 3, 12, 44389}, -- Keep up the Pace / FoolsHope
		[57407] = {56807, 5, 2, 13, 41619}, -- No Pain, No Pain / FCON
		[57185] = {56810, 6, 3, 13, 41622}, -- Protection by Deflection / FCON
		[57387] = {56815, 2, 2, 8, 34769}, -- Quick Restart / Skywatch
		[57314] = {56813, 4, 3, 13, 41625}, -- Razor's Edge / FCON
		[57098] = {57549, 1, 2, 6, 34771}, -- Reckless Dash / Sylvan
		[43207] = {56800, 1, 2, 12, 34754}, -- Reflexive Actions / FoolsHope
		[43205] = {56789, 2, 2, 8, 34744}, -- Rejuvenating Rain / Skywatch
		[60640] = {-1, 1, 3, 1, -1}, -- Repairbot / Autolearned
		[57262] = {56812, 2, 2, 12, 34766}, -- Repeat Business / FoolsHope
		[43189] = {56796, 2, 2, 4, 34750}, -- Reroute Power / Quest
		[57468] = {56779, 5, 2, 8, 34736}, -- Self-Destruct / Skywatch
		[43095] = {57551, 3, 2, 9, 34751}, -- Shrapnel Rounds / Thermock
		[43091] = {56799, 6, 3, 9, 34753}, -- Survival Instincts / Thermock
		[60638] = {-1, 3, 3, 1, -1}, -- Target Acquisition / Autolearned
		[57168] = {56802, 4, 2, 15, 34756}, -- The Zone / Unknown
		[57433] = {56791, 2, 3, 12, 34746}, -- Try and Hurt Me! / FoolsHope
		[57180] = {56814, 6, 2, 13, 41626}, -- Turn the Tables / FCON
		[57424] = {56809, 3, 3, 13, 41621}, -- Unstable Volatility / FCON
		[57326] = {56806, 5, 2, 13, 41618}, -- Volatile Armor / FCON
		[57403] = {56782, 3, 2, 4, 34738}, -- Volatility Rising / Quest
	},	
	[knClassEsper] = {	
		[41579] = {56746, 4, 3, 12, 34044}, -- B-I-N-G-O / FoolsHope
		[41581] = {56738, 6, 2, 12, 34037}, -- Bounce Back / FoolsHope
		[41593] = {56737, 2, 2, 4, 34036}, -- Build Up / Quest
		[57227] = {71139, 1, 3, 12, 44275}, -- Cheat Death / FoolsHope
		[41595] = {56736, 2, 3, 10, 34035}, -- Companion / Walkers
		[41584] = {56740, 1, 2, 12, 34039}, -- Defensive Maneuvers / FoolsHope
		[57777] = {56752, 5, 2, 13, 41748}, -- Duelist / FCON
		[57191] = {71140, 1, 3, 12, 44276}, -- Feedback / FoolsHope
		[41587] = {56732, 3, 3, 10, 34031}, -- Figment / Walkers
		[41600] = {56749, 4, 3, 10, 34047}, -- Fisticuffs / Walkers
		[33272] = {-1, 1, 3, 1, -1}, -- Fixation / Autolearned
		[57073] = {71129, 2, 2, 8, 44245}, -- Focus Mastery / Skywatch
		[56992] = {56729, 3, 2, 15, 34028}, -- Follow Through / Unknown
		[57806] = {56756, 6, 2, 13, 41752}, -- From the Grave / FCON
		[57159] = {71137, 2, 2, 9, 44273}, -- Hard to Hit / Thermock
		[57077] = {56733, 2, 3, 15, 34032}, -- Healing Touch / Unknown
		[57089] = {56735, 2, 2, 7, 34034}, -- Inspiration / GallowSylvan
		[57747] = {71141, 1, 2, 9, 44277}, -- Inspirational Charge / Thermock
		[57213] = {56739, 1, 2, 5, 34038}, -- Iron Reflexes / Gallow
		[41599] = {56734, 6, 3, 8, 34033}, -- Me Worry? / Skywatch
		[41594] = {56743, 1, 2, 8, 34042}, -- Mental Overflow / Skywatch
		[33366] = {-1, 2, 3, 1, -1}, -- Mirage / Autolearned
		[41586] = {56741, 1, 2, 4, 34040}, -- Molasses / Quest
		[41598] = {56744, 4, 2, 9, 34043}, -- No Pain No... / Thermock
		[57788] = {56751, 5, 2, 13, 41747}, -- No Remorse / FCON
		[41590] = {56747, 4, 2, 12, 34045}, -- Not Snackworthy / FoolsHope
		[57346] = {56757, 6, 3, 13, 41753}, -- Payback / FCON
		[57336] = {56755, 6, 2, 13, 41751}, -- Psychic Barrier / FCON
		[61006] = {56731, 3, 3, 4, 34030}, -- Quick Response / Quest
		[57027] = {56728, 3, 2, 6, 34027}, -- Reckful / Sylvan
		[57019] = {71123, 4, 2, 7, 44235}, -- Refund / GallowSylvan
		[41589] = {56742, 5, 3, 10, 34041}, -- Rupture / Walkers
		[57792] = {56754, 5, 2, 13, 41750}, -- Shocked / FCON
		[56943] = {56727, 5, 3, 12, 34026}, -- Slow it Down / FoolsHope
		[57133] = {71131, 2, 2, 9, 44272}, -- Spectral Shield / Thermock
		[70523] = {-1, 3, 3, 1, -1}, -- Spectral Swarm / Autolearned
		[57295] = {71138, 6, 2, 8, 44274}, -- Stand Strong / Skywatch
		[57012] = {71121, 3, 2, 9, 44234}, -- Superiority / Thermock
		[57745] = {56748, 4, 2, 15, 34046}, -- Tactician / Unknown
		[57037] = {56730, 5, 2, 15, 34029}, -- The Humanity / Unknown
		[57005] = {71120, 3, 2, 9, 44213}, -- The Power! / Thermock
		[57786] = {56750, 3, 2, 13, 41746}, -- True Sight / FCON
	},	
	[knClassMedic] = {	
		[59034] = {57510, 6, 3, 13, 41659}, -- Acerbic Injection / FCON
		[58962] = {57495, 1, 3, 10, 34682}, -- Amorphous Barrier / Walkers
		[58907] = {-1, 3, 3, 1, -1}, -- Annihilation / Autolearned
		[59014] = {57503, 5, 2, 13, 41652}, -- Antigen Isolation / FCON
		[58943] = {57485, 2, 2, 4, 34673}, -- Armor Coating / Quest
		[59032] = {57508, 6, 2, 13, 41657}, -- Attrition / FCON
		[59012] = {57506, 5, 3, 13, 41655}, -- Chemical Burn / FCON
		[59033] = {57509, 1, 2, 13, 41658}, -- Concerted Effort / FCON
		[58882] = {57481, 3, 2, 15, 34669}, -- Core Damage / Unknown
		[58912] = {57480, 3, 3, 10, 34668}, -- Danger Zone / Walkers
		[59036] = {57512, 6, 3, 13, 41661}, -- Debilitative Armor / FCON
		[58980] = {57496, 6, 2, 15, 34683}, -- Defense Mechanism / Unknown
		[60676] = {57511, 2, 2, 13, 41660}, -- Emergency / FCON
		[58942] = {57484, 6, 2, 9, 34672}, -- Emergency Extraction / Thermock
		[58984] = {57476, 3, 2, 4, 34664}, -- Empowering Aura / Quest
		[59016] = {57505, 5, 3, 13, 41654}, -- Energy Pulse / FCON
		[58909] = {57477, 5, 2, 8, 34665}, -- Entrapment / Skywatch
		[58976] = {57492, 1, 3, 6, 34679}, -- Health Probes / Sylvan
		[58946] = {57488, 2, 3, 12, 34676}, -- Hypercharge / FoolsHope
		[60797] = {60798, 3, 2, 10, 37224}, -- In Flux / Walkers
		[58914] = {57482, 3, 3, 15, 34670}, -- Meltdown / Unknown
		[58978] = {57494, 4, 2, 8, 34681}, -- Null Zone / Skywatch
		[58999] = {57501, 4, 3, 12, 34688}, -- Power Cadence / FoolsHope
		[58994] = {57500, 4, 2, 12, 34687}, -- Power Converter / FoolsHope
		[58974] = {-1, 1, 3, 1, -1}, -- Protection Probes / Autolearned
		[58932] = {57483, 2, 2, 15, 34671}, -- Protective Surge / Unknown
		[60393] = {61044, 1, 2, 10, 37648}, -- Quick Dodge / Walkers
		[60677] = {57486, 2, 2, 7, 34674}, -- Reboot / GallowSylvan
		[60648] = {71142, 3, 2, 9, 44278}, -- Recycler / Thermock
		[58977] = {57493, 1, 2, 9, 34680}, -- Regenerator / Thermock
		[58940] = {-1, 2, 3, 1, -1}, -- Rejuvenator / Autolearned
		[58910] = {57478, 4, 3, 9, 34666}, -- Renewable Probes / Thermock
		[58919] = {71143, 2, 3, 12, 44279}, -- Running on Empty / FoolsHope
		[58995] = {57498, 4, 2, 15, 34685}, -- Scalpel! Forceps! / Unknown
		[58981] = {57497, 6, 2, 12, 34684}, -- Shield Protocol / FoolsHope
		[58965] = {57491, 1, 2, 4, 34678}, -- Shield Reboot / Quest
		[58947] = {57490, 1, 2, 12, 34677}, -- Solid State / FoolsHope
		[58892] = {57507, 5, 2, 13, 41656}, -- Stay With Me / FCON
		[58997] = {57499, 4, 2, 9, 34686}, -- Surgical / Thermock
		[60901] = {60899, 2, 2, 10, 37415}, -- Transfusion / Walkers
		[58888] = {57479, 3, 2, 5, 34667}, -- Victory Spark / Gallow
		[58879] = {57504, 5, 2, 13, 41653}, -- Weakness into Strength / FCON
	},	
	[knClassSpellslinger] = {	
		[56645] = {-1, 3, 3, 1, -1}, -- Assassinate / Autolearned
		[57641] = {52103, 2, 2, 4, 30714}, -- Augmented Armor / Quest
		[57644] = {52105, 2, 2, 15, 30716}, -- Burst Power / Unknown
		[61170] = {52104, 2, 2, 8, 30715}, -- Clarity / Skywatch
		[56590] = {61042, 3, 2, 9, 37646}, -- Critical Surge / Thermock
		[56716] = {52125, 5, 2, 13, 41718}, -- Danger Danger / FCON
		[56609] = {52094, 3, 2, 5, 30706}, -- Deadly Chain / Gallow
		[56703] = {52106, 2, 3, 10, 30717}, -- Desperation / Walkers
		[57044] = {52114, 6, 2, 10, 30724}, -- Enhanced Shields / Walkers
		[57035] = {52110, 1, 2, 8, 30720}, -- Evasive Maneuvers / Skywatch
		[56710] = {52112, 6, 3, 7, 30722}, -- Final Salvo / GallowSylvan
		[57135] = {52129, 6, 2, 13, 41722}, -- Flame Armor / FCON
		[57803] = {52121, 4, 2, 10, 30731}, -- Focus Stone / Walkers
		[57085] = {52131, 6, 2, 13, 41724}, -- Frost Armor / FCON
		[57223] = {52095, 1, 2, 4, 30707}, -- Frost Snap / Quest
		[57772] = {52128, 6, 2, 13, 41721}, -- Fury / FCON
		[61163] = {52099, 3, 3, 10, 30710}, -- Gunslinger / Walkers
		[56655] = {52124, 5, 3, 13, 41717}, -- Headhunter / FCON
		[57339] = {52109, 2, 3, 12, 30719}, -- Healing Aura / FoolsHope
		[60956] = {-1, 2, 3, 1, -1}, -- Healing Torrent / Autolearned
		[61351] = {52108, 2, 2, 12, 30718}, -- Holy Roller / FoolsHope
		[61172] = {61043, 1, 3, 12, 37647}, -- Homeward Bound / FoolsHope
		[57034] = {52111, 6, 3, 4, 30721}, -- Hyper Shield / Quest
		[56876] = {52127, 5, 2, 13, 41720}, -- Killer / FCON
		[57028] = {52096, 5, 3, 15, 30708}, -- Overpower / Unknown
		[56856] = {52130, 5, 2, 13, 41723}, -- Penetrating Rounds / FCON
		[56725] = {52117, 4, 2, 15, 30727}, -- Power Surge / Unknown
		[57143] = {52118, 4, 2, 9, 30728}, -- Preparation / Thermock
		[57138] = {52116, 1, 2, 15, 30726}, -- Readiness / Unknown
		[57067] = {52123, 1, 2, 13, 41716}, -- Reorient / FCON
		[56692] = {52102, 2, 2, 6, 30713}, -- Savior / Sylvan
		[61174] = {52119, 4, 3, 15, 30729}, -- Shock & Awe / Unknown
		[57297] = {52113, 1, 3, 15, 30723}, -- Speed of the Void / Unknown
		[57072] = {52126, 1, 2, 13, 41719}, -- Spell Armor / FCON
		[56580] = {71853, 3, 3, 10, 44536}, -- Surge Damage / Walkers
		[61214] = {52120, 4, 3, 12, 30730}, -- The One / FoolsHope
		[61162] = {52100, 3, 2, 15, 30711}, -- Trigger Fingers / Unknown
		[57075] = {52122, 5, 2, 13, 41715}, -- True Sight / FCON
		[57657] = {52115, 4, 2, 10, 30725}, -- Urgency / Walkers
		[56600] = {52097, 3, 2, 15, 30709}, -- Vengeance / Unknown
		[56973] = {-1, 1, 3, 1, -1}, -- Void Pact / Autolearned
		[57253] = {52101, 3, 2, 12, 30712}, -- Withering Magic / FoolsHope
	},	
	[knClassStalker] = {	
		[39642] = {-1, 2, 3, 1, -1}, -- Amplification Spike / Autolearned
		[59389] = {71149, 1, 2, 8, 44286}, -- Assassin / Skywatch
		[59341] = {57524, 2, 2, 4, 34711}, -- Avoidance Mastery / Quest
		[59346] = {71150, 1, 2, 9, 44287}, -- Balanced / Thermock
		[60842] = {57516, 3, 3, 10, 34703}, -- Battle Mastery / Walkers
		[40946] = {57540, 5, 2, 13, 41685}, -- Blood Rush / FCON
		[39497] = {-1, 1, 3, 1, -1}, -- Bloodthirst / Autolearned
		[59443] = {71158, 6, 2, 9, 44289}, -- Boost / Thermock
		[59298] = {71160, 3, 2, 9, 44291}, -- Brutality Mastery / Thermock
		[41152] = {57529, 1, 2, 10, 34716}, -- Can't Stop This / Walkers
		[38973] = {-1, 3, 3, 1, -1}, -- Clone / Autolearned
		[59338] = {57521, 5, 2, 7, 34708}, -- Cutthroat / GallowSylvan
		[59415] = {57535, 6, 2, 15, 34722}, -- Dash for Heals! / Unknown
		[40963] = {57515, 3, 2, 8, 34702}, -- Devastate / Skywatch
		[41008] = {57523, 2, 2, 15, 34710}, -- Don't Call it a Comeback / Unknown
		[59328] = {71163, 2, 2, 9, 44293}, -- Empowered Attack Mastery / Thermock
		[59416] = {57536, 4, 3, 12, 34723}, -- Enabler / FoolsHope
		[40933] = {57514, 3, 3, 12, 34701}, -- Fatal Wounds / FoolsHope
		[59312] = {57518, 4, 2, 12, 34705}, -- Follow Up / FoolsHope
		[59339] = {57522, 2, 2, 8, 34709}, -- Forbearance / Skywatch
		[59437] = {57541, 5, 3, 13, 41686}, -- Heavy Impact / FCON
		[41165] = {57543, 1, 2, 13, 41688}, -- Iron Man / FCON
		[59414] = {57534, 5, 3, 9, 34721}, -- Keep Up / Thermock
		[40899] = {57513, 3, 2, 5, 34700}, -- Killer Instinct / Gallow
		[41079] = {71157, 2, 3, 12, 44288}, -- Last Stand / FoolsHope
		[41178] = {57528, 1, 2, 6, 34715}, -- Left in the Dust / Sylvan
		[41220] = {57531, 1, 3, 12, 34718}, -- Make it Rain / FoolsHope
		[41019] = {57538, 4, 3, 10, 34725}, -- My Turn / Walkers
		[59349] = {71166, 3, 2, 8, 44294}, -- Onslaught / Skywatch
		[59436] = {57530, 3, 2, 15, 34717}, -- Precision / Unknown
		[59459] = {57545, 6, 3, 13, 41690}, -- Quick Reboot / FCON
		[59320] = {71159, 2, 2, 7, 44290}, -- Regeneration / GallowSylvan
		[59438] = {57542, 4, 2, 13, 41687}, -- Riposte / FCON
		[59457] = {57544, 6, 2, 13, 41689}, -- Stay Afloat / FCON
		[59417] = {57537, 4, 2, 12, 34724}, -- Stealth Mastery / FoolsHope
		[59394] = {57527, 1, 3, 10, 34714}, -- Stealth Regen / Walkers
		[59460] = {57546, 6, 3, 13, 41691}, -- Strong-Legged / FCON
		[59335] = {71161, 6, 2, 9, 44292}, -- Tech Mastery / Thermock
		[41139] = {57520, 2, 3, 15, 34707}, -- That's All You Got? / Unknown
		[41180] = {57517, 5, 2, 4, 34704}, -- Trail of Cinders / Quest
		[59400] = {57532, 4, 2, 4, 34719}, -- Unfair Advantage / Quest
		[59435] = {57539, 5, 2, 13, 41684}, -- Who's Next? / FCON
	},	
	[knClassWarrior] = {	
		[59148] = {71370, 6, 2, 9, 44391}, -- Anti-Magic Armor / Thermock
		[59071] = {51531, 3, 3, 10, 30466}, -- Armor Shred / Walkers
		[59058] = {51647, 3, 2, 9, 30506}, -- Bloodlust / Thermock
		[59170] = {-1, 2, 3, 1, -1}, -- Bolstering Strike / Autolearned
		[59144] = {51685, 6, 3, 13, 41590}, -- Bring It / FCON
		[59188] = {51608, 1, 2, 7, 30501}, -- Bust Out / GallowSylvan
		[59210] = {51611, 1, 3, 10, 30504}, -- Can't Stop, Won't Stop / Walkers
		[59054] = {51527, 5, 2, 8, 30464}, -- Cheap Shot / Skywatch
		[59105] = {60973, 5, 2, 13, 41592}, -- Cornered / FCON
		[59077] = {51534, 3, 2, 12, 30467}, -- Detonate / FoolsHope
		[59209] = {51610, 4, 2, 12, 30503}, -- Energy Banks / FoolsHope
		[59106] = {60976, 5, 2, 13, 41593}, -- Festering Blade / FCON
		[59143] = {51684, 2, 3, 13, 41589}, -- Fortify / FCON
		[59159] = {51570, 2, 2, 4, 30488}, -- Full Defense / Quest
		[59160] = {51571, 2, 2, 6, 30489}, -- Full Force / Sylvan
		[59087] = {51648, 4, 3, 12, 30507}, -- Fury / FoolsHope
		[59177] = {51581, 6, 2, 10, 30493}, -- Health Sponge / Walkers
		[59178] = {51582, 2, 2, 15, 30494}, -- Impenetrable / Unknown
		[59126] = {71148, 5, 2, 7, 44285}, -- Killing Spree / GallowSylvan
		[59137] = {51683, 2, 2, 13, 41588}, -- Kinetic Buffer / FCON
		[59208] = {59161, 4, 2, 15, 37485}, -- Kinetic Burst / Unknown
		[59197] = {51609, 1, 2, 15, 30502}, -- Kinetic Drive / Unknown
		[59045] = {71144, 3, 3, 12, 44281}, -- Kinetic Fury / FoolsHope
		[59070] = {51528, 3, 2, 5, 30465}, -- Laceration / Gallow
		[59154] = {51574, 2, 2, 15, 30491}, -- MKII Battle Suit / Unknown
		[59121] = {61008, 1, 3, 13, 41595}, -- No Escape / FCON
		[59082] = {51649, 4, 3, 12, 30508}, -- Overwhelming Presence / FoolsHope
		[59062] = {51515, 3, 2, 4, 30462}, -- Power Hitter / Quest
		[59204] = {-1, 1, 3, 1, -1}, -- Power Link / Autolearned
		[59053] = {51526, 3, 2, 5, 30463}, -- Radiate / Gallow
		[59122] = {61009, 5, 3, 13, 41596}, -- Recklessness / FCON
		[59165] = {71146, 6, 2, 9, 44283}, -- Reserve Power / Thermock
		[59136] = {51607, 1, 2, 7, 30500}, -- Shock Absorber / GallowSylvan
		[59129] = {51682, 1, 2, 13, 41587}, -- Speed Burst / FCON
		[59142] = {71147, 6, 3, 10, 44284}, -- Spiked Armor / Walkers
		[59092] = {51650, 4, 2, 8, 30509}, -- Stance Dancer / Skywatch
		[59104] = {60982, 5, 3, 13, 41594}, -- Sunder / FCON
		[59051] = {71145, 4, 2, 7, 44282}, -- Sure Shot / GallowSylvan
		[59176] = {51580, 2, 3, 15, 30492}, -- To the Pain / Unknown
		[59072] = {-1, 3, 3, 1, -1}, -- Tremor / Autolearned
		[59215] = {51612, 1, 2, 4, 30505}, -- Unyielding / Quest
		[59166] = {51572, 6, 2, 6, 30490}, -- Vigor / Sylvan
	},	
}		

local kiEpisodeNum = 1
local kiEpisodeQuestgiver = 2
local kiEpisodeName = 3
local kiEpisodeQuest1 = 4
local kiEpisodeQuest2 = 5
local kiEpisodeQuest3 = 6
local ktEpisodeInfo = {  -- 541, 309 = knPaneCelestionQ, knPaneDeraduneQ
	[knPaneDeraduneQ]	= {309, "DeraduneQuestgiver", "DeraduneEpisode", 3302, 3304, 5799},
	[knPaneAlgorocQ]	= {392, "AlgorocQuestgiver", "AlgorocEpisode", 4609, 4541, 0},
	[knPaneEllevarQ]	= {538, "EllevarQuestgiver", "EllevarEpisode", 6575, 6576, 6577},
	[knPaneCelestionQ]	= {541, "CelestionQuestgiver", "CelestionEpisode", 6670, 6671, 6672},
}

local karEpisodeTitles = {
	[3302] = "DeraduneQuest1",
	[3304] = "DeraduneQuest2",
	[5799] = "DeraduneQuest3",
	[4609] = "AlgorocQuest1",
	[4541] = "AlgorocQuest2",
	[6575] = "EllevarQuest1",
	[6576] = "EllevarQuest2",
	[6577] = "EllevarQuest3",
	[6670] = "CelestionQuest1",
	[6671] = "CelestionQuest2",
	[6672] = "CelestionQuest3",
}

local knCondQuest = 1
local knCondReputation = 2
local knCondPrestige = 3
local knCondVendor = 4
local knCondQuestgiver = 5
local knCondAMP = 6

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AMPFinder:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function AMPFinder:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {} -- "AbilityAMPs" no longer absolutely needed
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- AMPFinder OnLoad
-----------------------------------------------------------------------------------------------
function AMPFinder:OnLoad()
 	self.xmlDoc = XmlDoc.CreateFromFile("AMPFinder.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-----------------------------------------------------------------------------------------------
-- AMPFinder OnDocumentReady
-----------------------------------------------------------------------------------------------
function AMPFinder:OnDocumentReady()
	self.wndAMPFilter = nil
	self.wndAMPTooltip = nil
	self.timerTooltip = nil
	if (self.bWindowOpen == nil) then self.bWindowOpen = false end
	if (self.strFilter == nil) then self.strFilter = "" end
	if (self.bShowFilter == nil) then self.bShowFilter = true end
	self.nUserSelectedPane = 0
	self.nFaction = nil
	self.nDisplayedPane = 0
	self.TimerSpeed = knSlowDelay
	self.idleTicks = 0
	self.tPlayerPos = { x=0, z=0, }
	self.nHeading = 0
	self.wndHover = nil
	self.wndLeave = nil
	if (self.bCompact == nil) then self.bCompact = false end
	self.bConfirmedCompact = false
	self.nCompleteDisplayMode = knDisplayPrice
	self.bInitialShow = true
	self.bAmpLocations = false
	self.LocationToVendor = {}
	-- self.nIntentionalDelay = 10 -- testing
	self.bDebugMessaged = false
	
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AmpFinderForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, L["CantLoadForm"])
			return
		end
		
		-- don't show it on open, let user open it
	    self.wndMain:Show(false)
		self.wndMain:FindChild("PickerListFrame"):Show(false)
		self.wndMain:FindChild("CompactBtn"):SetCheck(true)
		self.wndMain:FindChild("MiniFrame"):Show(false)
		self.wndMain:FindChild("ClassListFrame"):Show(false)
		
		self.wndMain:FindChild("PickerBtn"):Enable(false) -- Disable, will be enabled on setamploc
		self.wndMain:FindChild("ClassFrame"):FindChild("ClassButton"):Enable(false)
	
		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
		
		Apollo.RegisterEventHandler("AMPFinder_ShowHide", "OnInterfaceMenuShowHide", self)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		
		Apollo.RegisterSlashCommand("ampfinder", "OnSlashCommand", self)
		
		self.timerTooltip = ApolloTimer.Create(1.5, false, "AMPFinderTooltipClose", self)
		
		self.timerInit = ApolloTimer.Create(knSlowDelay, true, "SetAmpLocations", self)
		self.timerInit:Start()	
	
		self:HookAMPWindow()
		self:HookAMPTooltips()
		self:HookTooltips()
	end
end

-- returns 'true' if amp locations were set on this pass.
function AMPFinder:SetAmpLocations()
	if (self.bAmpLocations) then return false end
	
	--[[
	-- this is for debug purposes
	self.nIntentionalDelay = self.nIntentionalDelay - 1
	if (self.nIntentionalDelay > 0) then 
		Print("Intentional testing delay. "..self.nIntentionalDelay.." ticks remaining.")
		return false
	end	
	--]]	
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if (unitPlayer == nil) then return false end  -- if GetPlayerUnit() is undefined then we can't finish
	local intClass = unitPlayer:GetClassId()
	if (intClass == nil) then return false end
	local faction = unitPlayer:GetFaction()
	if (faction == nil) then return false end

	self.nClass = intClass
	self.nClassDisplayed = intClass
	self.nFaction = faction

	self.tMyClassAmps = AllAmpData[intClass]
	
	if (faction == Unit.CodeEnumFaction.ExilesPlayer) then
		---- EXILE VENDORS ---
		self.LocationToVendor = {
			[knLocFCON] =		{	{ "Z_Thayd",		"SZ_FCON",		4211.52, -2254.72,	"NPC_Clayre",			nil},				},
			[knLocFoolsHope] =	{	{ "Z_Wilderrun",	"SZ_FoolsHope",	2074.86, -1729.20,	"NPC_Snowglimmer",		"E_Rep_Wilderrun"},	},
			[knLocGallow] = 	{	{ "Z_Algoroc",		"SZ_Gallow",	4085.17, -3938.71,	"NPC_ClaraClearfield",	"E_Rep_Algoroc"},	},
			[knLocGlenview] = 	{	{ "Z_Celestion",	"SZ_Glenview",	1028.70, -3052.39,	"CelestionQuest1",		nil},				},
			[knLocSkywatch] = 	{	{ "Z_Galeras",		"SZ_Skywatch",	5758.36, -2579.27,	"NPC_Windfree",			"E_Rep_Galeras"},	},
			[knLocSylvan] =		{	{ "Z_Celestion",	"SZ_Sylvan",	2706.62, -2405.68,	"NPC_MelriGladewalker",	"E_Rep_Celestion"}, },
			[knLocThermock] =	{	{ "Z_Whitevale",	"SZ_Thermock",	4584.49, -790.67,	"NPC_FenanSunstrider",	"E_Rep_Whitevale"},	},
			[knLocTremor] = 	{	{ "Z_Algoroc",		"SZ_Tremor",	3767.50, -4645.34,	"AlgorocQuest1", 		nil},				},
			[knLocWalkers] =	{	{ "Z_Farside",		"SZ_Walkers", 	5899.68, -4946.27,	"NPC_ReyaResinbough",	"E_Rep_Farside"},	},
			[knLocBravo] =		{	{ "Z_Farside",		"SZ_Bravo",		4305.31, -5652.43,	"NPC_Zanogez",			"E_Rep_Farside"},	},
			[knLocCommodity] =	{
				{ "Z_Thayd",	"SZ_AcademyCorner",		4294.63, -2405.07,	"NPC_Thualla",	nil},
				{ "Z_Thayd",	"SZ_ArborianGardens",	3778.36, -2026.74, 	"NPC_Jaryth",	nil},
				{ "Z_Thayd",	"SZ_FortunesGround",	4035.35, -1833.44,	"NPC_Dusa",		nil},
			},
		}			
	elseif (faction == Unit.CodeEnumFaction.DominionPlayer) then
		---- DOMINION VENDORS ----
		self.LocationToVendor = {
			[knLocFCON] = 		{	{ "Z_Illium",		"SZ_LegionsWay", 	-2856.84, -495.14,	"NPC_Phenoxia",		nil},				},
			[knLocFoolsHope] =	{	{ "Z_Wilderrun",	"SZ_FtVigilance",	1270.62, -2012.74,	"NPC_Jazira",			"D_Rep_Wilderrun"},	},
			[knLocGallow] =		{	{ "Z_Deradune",		"SZ_Bloodfire",		-5621.64, -710.04,	"NPC_Mika",							"D_Rep_Deradune"},	},
			[knLocGlenview] =	{	{ "Z_Deradune",		"SZ_Spearclaw",		-5487.2, -1088.3,	"DeraduneQuest1",			nil},				},
			[knLocSkywatch] =	{	{ "Z_Auroria",		"SZ_Hycrest",		-2431, -1884.85,	"NPC_Voxic",				"D_Rep_Auroria"},		},
			[knLocSylvan] =		{	{ "Z_Ellevar",		"SZ_Lightreach",	-2548, -3501.42,	"NPC_Saphis",					"D_Rep_Ellevar"},	},
			[knLocThermock] =	{	{ "Z_Whitevale",	"SZ_Palerock",		2137.97, -754.56,	"NPC_Zephix",						"D_Rep_Whitevale"},	},
			[knLocTremor] =		{	{ "Z_Ellevar",		"SZ_VigilantStand",	-3175.2, -3670.9,	"EllevarQuest1",		nil},				},
			[knLocWalkers] =	{	{ "Z_Farside",		"SZ_Virtue", 		5353.69, -4555.38,	"NPC_Dakahari",						"D_Rep_Farside"},		},
			[knLocBravo] =		{	{ "Z_Farside",		"SZ_Sovereign",		4041.86, -5197.45,	"NPC_Noriom",			"D_Rep_Farside"},		},
			[knLocCommodity] =	{	
				{ "Z_Illium",	"SZ_SpaceportAlpha",	-3689.13, -860.79,	"NPC_Lyvire",	nil},
				{ "Z_Illium",	"SZ_FatesLanding",		-2960.37, -1153.7,	"NPC_Kezira",	nil},
				{ "Z_Illium",	"SZ_LegionsWay",		-2926.10, -632.32,	"NPC_Larteia",	nil},
			},
		} 
	else 
		---- UNKNOWN VENDORS ----
		self.LocationToVendor = {
			[knLocFCON] = 		{	{ "SZ_UA_Thayd",		"?", 0,0, "?", nil}, },
			[knLocFoolsHope] =	{	{ "SZ_UA_FoolsHope",				"?", 0,0, "?", nil}, },
			[knLocGallow] =		{	{ "SZ_UA_Gallow",	"?", 0,0, "?", nil}, },
			[knLocGlenview] =	{	{ "SZ_UA_Glenview",	"?", 0,0, "?", nil}, },
			[knLocSkywatch] =	{	{ "SZ_UA_Skywatch",		"?", 0,0, "?", nil}, },
			[knLocSylvan] =		{	{ "SZ_UA_Sylvan",	"?", 0,0, "?", nil}, },
			[knLocThermock] =	{	{ "SZ_UA_Thermock",				"?", 0,0, "?", nil}, },
			[knLocTremor] =		{	{ "SZ_UA_Tremor",	"?", 0,0, "?", nil}, },
			[knLocWalkers] =	{	{ "SZ_UA_Farside",				"?", 0,0, "?", nil}, },
			[knLocBravo] =		{	{ "SZ_UA_Farside",				"?", 0,0, "?", nil}, },
			[knLocCommodity] =	{	{ "SZ_UA_Thayd",		"?", 0,0, "?", nil}, },
		} 
		return false -- keep checking!	
	end

	self.timerInit:Stop()
	self.bAmpLocations = true

	self:CompleteHookup()
end

function AMPFinder:CompleteHookup()
	-- Run by SetAmpLocations as the final stage of setup

	-- self:HookAMPTooltips() -- 1.6.2: now done in ondocumentready
	self:HookVendorLists()
	
	self.wndMain:FindChild("PickerBtn"):Enable(true)
	self.wndMain:FindChild("ClassFrame"):FindChild("ClassButton"):Enable(true)

	Apollo.RegisterEventHandler("VarChange_ZoneName", 		"OnChangeZone", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 			"OnChangeZone", self)

	-- no longer tracking prestige now that we show costs
	-- Apollo.RegisterEventHandler("PlayerCurrencyChanged",	"OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("ReputationChanged", 		"OnReputationChanged", self)
	Apollo.RegisterEventHandler("QuestObjectiveUpdated", 	"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("QuestStateChanged", 		"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("CharacterUnlockedInlaidEldanAugmentation", "OnAMPChanged", self)
		-- called whenever an AMP is unlocked on the pane

	self.timerPos = ApolloTimer.Create(self.TimerSpeed, true, "UpdateArrow", self)
	
	self:UpdateArrow()
	self:HookPosTrack(false)
	
	self:UpdatePane()
	
	-- todo: debug
	-- if (self.bWindowOpen == true) then self.wndMain:Show(true) end
	
	if (self.wndMain ~= nil) then
		--[[
		if (self.bCompact) then 
		 	self:CompactWindow() 
			self.bInitialShow = true  -- force it to redo the windowshow stuff
			self:OnWindowShow()
			self:UpdateInterfaceWindowTrack()
		end
		--]]
		self.wndMain:Show(self.bWindowOpen)
	end	
end

--------------------------------------------------
-- Utility functions 
--------------------------------------------------

local function round(n) 
	return math.floor(n + 0.5)
end

-- Other addons can override these functions if desired~
local function GetAbilityAMPsAddon() 
	local tAddon
	tAddon = Apollo.GetAddon("AbilityAMPs")
		or Apollo.GetAddon("GorynychAbilityAMPs")
	if (tAddon) then return tAddon end
	return nil
end

local function GetVendorAddon() 
	local tAddon
	tAddon = Apollo.GetAddon("Vendor")
	if (tAddon) then return tAddon end
	return nil
end

local function GetTooltipsAddon() 
	local tAddon
	tAddon = Apollo.GetAddon("ToolTips")
		or Apollo.GetAddon("GorynychToolTips")
		or Apollo.GetAddon("VikingTooltips")
	if (tAddon) then return tAddon end
	return nil
end

local function GetOptionsAddon() 
	local tAddon
	tAddon = Apollo.GetAddon("OptionsInterface")
	if (tAddon) then return tAddon end
	return nil
end

-- returns 2 if complete, 1 if in progress, 0 if nothing
local function GetQuestStatus(quest)
	local eQuestStatus = quest:GetState()
	if (eQuestStatus == Quest.QuestState_Completed) then
		return 2
	elseif (eQuestStatus == Quest.QuestState_Accepted)
		or (eQuestStatus == Quest.QuestState_Achieved) then
		return 1
	else
		return 0
	end
end

local function IsKeyComplete(nZoneKey) -- used by extendAugmentationTooltip
	local epiInfo = ktEpisodeInfo[nZoneKey]
	local nEp = epiInfo[kiEpisodeNum]
	local tAllEpisodes = QuestLib.GetAllEpisodes(true)
	local epiKey = nil
	for idx, epiEpisode in pairs(tAllEpisodes) do
		if (nEp == epiEpisode:GetId()) then epiKey = epiEpisode end
	end
	local bCompleteAll = false
	if (epiKey ~= nil) then
		local bComplete1 = false
		local bComplete2 = false
		local bComplete3 = false
		if (epiInfo[kiEpisodeQuest3] == 0) then bComplete3 = true end
		
		for idx, queSelected in pairs(epiKey:GetAllQuests()) do
			local nQuestId = queSelected:GetId()
			
			if		(nQuestId == epiInfo[kiEpisodeQuest1]) then 
				if (GetQuestStatus(queSelected)) == 2 then bComplete1 = true end
			elseif	(nQuestId == epiInfo[kiEpisodeQuest2]) then 
				if (GetQuestStatus(queSelected)) == 2 then bComplete2 = true end	
			elseif	(nQuestId == epiInfo[kiEpisodeQuest3]) then
				if (GetQuestStatus(queSelected)) == 2 then bComplete3 = true end
			end
		end
		if (bComplete1 and bComplete2 and bComplete3) then
			bCompleteAll = true
		end
	end
	return bCompleteAll
end

function AMPFinder:GetDistanceSquared(loc)
	local nX = self.tPlayerPos.x - loc[3]
	local nZ = self.tPlayerPos.z - loc[4]
	
	local nDistSq = math.pow(nX, 2) + math.pow(nZ, 2)

	return nDistSq
end

function AMPFinder:GetDegree(loc)
	local nX = loc[3] - self.tPlayerPos.x
	local nZ = loc[4] - self.tPlayerPos.z
	
	local nTheta = math.atan2(nX, -nZ)
	
	if (nTheta > 0) then
		nTheta = (2 * math.pi) - nTheta
	else
		nTheta = -nTheta
	end
	
	local nFace = self.nHeading - nTheta
	if (nFace < 0) then
		nFace = math.pi*2 + nFace
	end	
	local nDegree = nFace * 180 / math.pi
	
	return nDegree
end


function AMPFinder:GetKeyEpisode(nKey)
	-- Will return an episode if it's at least partially complete.
	-- If it's not complete we'll be pointing them there.
	-- It's possible for the episode to be incomplete and still have the amp, though
	local tAllEpisodes = QuestLib.GetAllEpisodes(true)
	local epiKey = nil
	for idx, epiEpisode in pairs(tAllEpisodes) do
		if (nKey == epiEpisode:GetId()) then epiKey = epiEpisode end
	end
	return epiKey
end

--------------------------------------------------
-- IsLearnedByItem(item)
--   returns intLearned, strTier, tAmp
--           2 if learned
--           1 if locked
--           0 if not found
--   strTier is " (Assault Tier 3)" or " (Hybrid A/S Tier 2)"
--------------------------------------------------
function AMPFinder:IsLearnedByItem(item)
	-- lookup the appropriate chart
	-- This will fail for autolearned spells, but you won't have an item for them anyway
	local nClass = item:GetItemType()
	local tAmpData = {}

	if		(nClass == knAmpWarrior)		then tAmpData = AllAmpData[knClassWarrior]
	elseif	(nClass == knAmpEngineer)		then tAmpData = AllAmpData[knClassEngineer]
	elseif	(nClass == knAmpMedic)			then tAmpData = AllAmpData[knClassMedic]
	elseif	(nClass == knAmpStalker)		then tAmpData = AllAmpData[knClassStalker]
	elseif	(nClass == knAmpEsper)			then tAmpData = AllAmpData[knClassEsper]
	elseif	(nClass == knAmpSpellslinger)	then tAmpData = AllAmpData[knClassSpellslinger]
	end
	
	local itemInfo = item:GetDetailedInfo()
	local nImbueId = itemInfo.tPrimary.arSpells[1].splData:GetId()
	
	local nIndex = nil
	for idx, rec in pairs(tAmpData) do
		if (rec[kiImbueSpellId] == nImbueId) then
			nIndex = idx
			break
		end
	end
	if (nIndex == nil) then
		return 0, "", nil
	else
		return self:IsLearnedBySpellId(nIndex, tAmpData[nIndex])
	end
end

--------------------------------------------------
-- IsLearnedBySpellId(nSpellId, tAmpRecord)
--   returns intLearned, strTier, tAmp
--           2 if learned
--           1 if locked
--           0 if not found
--   strTier is " (Assault Tier 3)" or " (Hybrid A/S Tier 2)"
--------------------------------------------------
function AMPFinder:IsLearnedBySpellId(nSpellId, tAmpRecord)
	local boolFound = false
	local boolLearned = false
	local tEldanAugmentationData = AbilityBook.GetEldanAugmentationData(AbilityBook.GetCurrentSpec())
	
	if not tEldanAugmentationData then return end
	
	local strTier = ""
	if (tAmpRecord ~= nil) then
		strTier = String_GetWeaselString(L["RankLong"],
			karCategoryToConstantData[ tAmpRecord[kiAmpCategory] ][ 3 ],
			tAmpRecord[kiAmpRank])
	end
	
	
	local tFoundAmp = nil
	for idx = 1, #tEldanAugmentationData.tAugments do
		local tAmp = tEldanAugmentationData.tAugments[idx]
		
		if (tAmp.nSpellIdAugment == nSpellId) then
			boolFound = true
			tFoundAmp = tAmp
			if tAmp.eEldanAvailability ~= AbilityBook.CodeEnumEldanAvailability.Unavailable then
				boolLearned = true
			end
			
			-- make sure we identify the amp record if tAmpRecord is nil)
			strTier = String_GetWeaselString(L["RankLong"], 
				karCategoryToConstantData[tAmp.nCategoryId][3],
				tAmp.nCategoryTier)
		end
	end
	
	if (boolFound) then
		if (boolLearned) then
			return 2, strTier, tFoundAmp -- learned
		else 
			return 1, strTier, tFoundAmp -- unlearned
		end
	else 
		return 0, strTier, nil 	 -- if amp is not listed
	end
end


--------------------------------------------------
-- Hook functions
--------------------------------------------------

function AMPFinder:HookAMPWindow()

	local tAbilityAMPs = GetAbilityAMPsAddon() -- Apollo.GetAddon("AbilityAMPs")
	if (tAbilityAMPs == nil) then return end -- can't hook if the addon isn't there
	
	-- change unlocked but non-prerequisited AMPs to blue
	local origRedrawSelections = tAbilityAMPs.RedrawSelections
	
	tAbilityAMPs.RedrawSelections = function(tEldanAugmentationData)
		origRedrawSelections(tEldanAugmentationData)
		
		-- fallthrough for older AbilityAMPs replacement mods
		local wndAmpMain = tAbilityAMPs.tWndRefs and tAbilityAMPs.tWndRefs.wndMain or tAbilityAMPs.wndMain
		if (wndAmpMain == nil) then return end
		self.wndAMPFilter = Apollo.LoadForm(self.xmlDoc, "AmpFilterForm", wndAmpMain, self)		

		local fBox = self.wndAMPFilter:FindChild("FilterBox")
		if (fBox ~= nil) then
			if (self.strFilter == "") then
				fBox:SetText(L["FilterBlank"])
				fBox:ClearFocus()
				self.wndAMPFilter:FindChild("FilterClearBtn"):Show(false)
				self.wndAMPFilter:FindChild("SearchIcon"):Show(true)
				self:UpdateAMPWindow(nil)
			else
				fBox:SetText(self.strFilter)
				self.wndAMPFilter:FindChild("FilterClearBtn"):Show(true)
				self.wndAMPFilter:FindChild("SearchIcon"):Show(false)
				fBox:ClearFocus()
				self:UpdateAMPWindow(self.strFilter)
			end
		end
	end -- end of loop	
end

local function repositionAugmentationTooltip(wndTooltip)
	
	local wndParent = wndTooltip
	while(wndParent:GetParent() ~= nil) do wndParent = wndParent:GetParent() end
	
	local nScreenWidth, nScreenHeight = Apollo:GetScreenSize()
	local parentX, parentY = wndParent:GetPos()
	local nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
	if ((parentX + nRight + 875) > nScreenWidth) then
		wndTooltip:SetAnchorOffsets(-1125, nTop, -875, nBottom)
	elseif ((parentX + nLeft + 875) < 0) then
		wndTooltip:SetAnchorOffsets(25, nTop, 275, nBottom)
	end
end

local function formatLocation(tLocationData, bCX)
	if (tLocationData[2] == "?") then 
		-- degraded data given in case faction not obtainable yet
		return L[ tLocationData[1] ]
		
	else 
		local strVendorName = L[tLocationData[5]]
		if (bCX) then
			strVendorName = L["CX"]
		end	
		local strRep = ""
		if (tLocationData[6] ~= nil) then
			strRep = "|  &lt;" .. L[ tLocationData[6] ] .. "&gt;"
		end
		return String_GetWeaselString(L["LocationTip"], strVendorName, L[tLocationData[2]], L[ tLocationData[1] ], tLocationData[3], tLocationData[4],
			strRep)
	end
end

local function extendAugmentationTooltip(wndTooltip, wndControl, tAmp)
	-- if amp locations have not been set then we can't give meaningful feedback
	local tAmpFinder = Apollo.GetAddon("AMPFinder")
	
	-- exit if the nFaction hasn't been set -- if it's not Exiles or Dominion then that's another story
	if (tAmpFinder.nClass == nil) then return end
	if (tAmpFinder.nFaction == nil) then return end	
	if (tAmpFinder.LocationToVendor[knLocCommodity] == nil) then
		if (tAmpFinder.bDebugMessaged == false) then
			Print(L["LocationTableError"])
			tAmpFinder.bDebugMessaged = true
		end
		return
	end
		
	local wndParent = wndControl:GetParent()
	local tAugment
	if (tAmp ~= nil) then
		tAugment = tAmp
	else
		tAugment = wndParent:GetData() or wndControl:GetData() -- #Drop2 vs #Drop3
	end
	if (tAugment == nil) then return end -- just in case
	local title = tAugment.strTitle or ""
	local eEnum = tAugment.eEldanAvailability
	
	if (eEnum == AbilityBook.CodeEnumEldanAvailability.Unavailable) then -- 0
		local strLoc = ""
		local nLocation = nil
		local tRecord = tAmpFinder.tMyClassAmps[tAugment.nSpellIdAugment]
		if (tRecord ~= nil) then
			nLocation = tRecord[4]
		end

		if (nLocation == knLocQuest) then

			local nCount = 0
			strLoc = L["ObtainQuest"]
			
			if (IsKeyComplete(knPaneCelestionQ) == false) and (IsKeyComplete(knPaneDeraduneQ) == false) then
				local tLocationData1 = tAmpFinder.LocationToVendor[knLocGlenview][1]
				strLoc = strLoc .. formatLocation(tLocationData1, false)
				nCount = nCount+1
			end
			
			if (IsKeyComplete(knPaneAlgorocQ) == false) and (IsKeyComplete(knPaneEllevarQ) == false) then
				if (nCount >= 1) then strLoc = strLoc..L["ObtainBridge1"] end
				
				local tLocationData2 = tAmpFinder.LocationToVendor[knLocTremor][1]
				strLoc = strLoc .. formatLocation(tLocationData2, false)
				nCount = nCount + 1
			end
			
			if (nCount >= 1) then strLoc = strLoc..L["ObtainBridge"] end
			tLocationData = tAmpFinder.LocationToVendor[knLocCommodity][1]
			strLoc = strLoc .. formatLocation(tLocationData, true)
			
		elseif (nLocation == knLocGallowSylvan) then
			tLocationData1 = tAmpFinder.LocationToVendor[knLocGallow][1]
			tLocationData2 = tAmpFinder.LocationToVendor[knLocSylvan][1]
			strLoc = L["ObtainVendor"]
				.. formatLocation(tLocationData1, false)
				.. L["ObtainBridge"]
				.. formatLocation(tLocationData2, false)
				
		elseif (nLocation == knLocUnknown) then
			tLocationData = tAmpFinder.LocationToVendor[knLocCommodity][1]
			strLoc = L["ObtainCX"]
				.. formatLocation(tLocationData, true)
		
		elseif (nLocation ~= nil) then
			-- tLocRecord shouldn't be nil, but it is seeming to be... 
			-- shouldn't happen, but it happens in walatiki temple.
			-- are all amps locked in PVP maps, perhaps?
			-- It may be another not-quite-loading error. Testing for now though. 
	
			local tLocationData = nil
			local tLocRecord = tAmpFinder.LocationToVendor[nLocation]
			if (tLocRecord ~= nil) then tLocationData = tLocRecord[1] end
			if (tLocationData ~= nil) then
				strLoc = L["ObtainVendor"]
					.. formatLocation(tLocationData, false)
			else 
				tLocationData = tAmpFinder.LocationToVendor[knLocCommodity][1]
				strLoc = L["ObtainCX"]
					.. formatLocation(tLocationData, true)
			end		
		else 
			tLocationData = tAmpFinder.LocationToVendor[knLocCommodity][1]
			strLoc = L["ObtainCX"]
					.. formatLocation(tLocationData, true)
		end
		
		strLoc = string.gsub(strLoc, "|", "</P><P TextColor=\"UI_TextHoloBodyHighlight\" Font=\"CRB_InterfaceSmall\">")
		wndTooltip:FindChild("DescriptionLabelWindow"):SetAML(
			"<P TextColor=\"UI_TextHoloBodyHighlight\" Font=\"CRB_InterfaceSmall\">"
		    ..strLoc.."</P>"..			
			"<P TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceSmall\">"
			..tAugment.strDescription.."</P>")
			
		-- resize window now that we've added text
		local nTextWidth, nTextHeight = wndTooltip:FindChild("DescriptionLabelWindow"):SetHeightToContentHeight()
		local nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
		wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + 68)
		
	end -- if eEnum
end

function AMPFinder:HookAMPTooltips()
	local tAbilityAMPs = GetAbilityAMPsAddon() -- Apollo.GetAddon("AbilityAMPs")
	if (tAbilityAMPs == nil) then return end -- can't hook if the addon isn't there
	
	-- extend AMP Dialog tooltip
	local origOnAugmentationTooltip = tAbilityAMPs.OnAugmentationTooltip
	tAbilityAMPs.OnAugmentationTooltip = function(wndHandler, wndControl, eToolTipType, x, y)	
		origOnAugmentationTooltip(wndHandler, wndControl, eToolTipType, x, y)
		extendAugmentationTooltip(tAbilityAMPs.wndTooltip, wndControl)
		if (tAbilityAMPs.OnAugmentationTooltipEnd ~= nil) then  -- only need to reposition tooltip window drop 2 and earlier
			repositionAugmentationTooltip(tAbilityAMPs.wndTooltip)
		end
	end -- tAbilityAMPs.OnAugmentationTooltip
end

function AMPFinder:HookVendorLists()
	local tVendor = GetVendorAddon() -- Apollo.GetAddon("Vendor")
	if (tVendor == nil) then return end
	local origVendorItems = tVendor.DrawListItems
	tVendor.DrawListItems = function(luaCaller, wndParent, tItems)
		local nHeight = origVendorItems(luaCaller, wndParent, tItems)
		
		local tItemWindows = wndParent:GetChildren()
		for key, tCurrItem in ipairs(tItems) do
			local tItemData = tCurrItem.itemData
			if (tItemData ~= nil) then -- fix the items that don't have all their data
				local nItemType = tItemData:GetItemType()
				if (nItemType >= knAmpWarrior) and (nItemType <= knAmpSpellslinger) then
					
					local intFound, strAmpTier = self:IsLearnedByItem(tCurrItem.itemData)
					
					-- we can cheat, there's a 1:1 relationshop between items and their windows
					local wndItem = tItemWindows[key]
					local wndItemLabel = wndItem:FindChild("VendorListItemTitle")
	
					if (intFound == 2) then				
						wndItemLabel:SetText(String_GetWeaselString(Apollo.GetString("Vendor_KnownRecipe"), 
							tCurrItem.itemData:GetName() )  )
					end	
				end
			end
		end
				
		return nHeight
	end
end

function AMPFinder:HookTooltips()
	local tTooltips = GetTooltipsAddon() -- Apollo.GetAddon("ToolTips")
	if (tTooltips == nil) then return end  -- ditch this procedure if user is using a different tooltip mod
	
	-- CreateCallNames is run right after a tooltip is instantiated.
	-- So we can splice code in there.
	-- now passing window args both upstream and downstream - thanks, Tomer!
	local origCreateCallNames = tTooltips.CreateCallNames
	tTooltips.CreateCallNames = function(luaCaller)
		origCreateCallNames(luaCaller)
		local origItemTooltip = Tooltip.GetItemTooltipForm
		Tooltip.GetItemTooltipForm = function(luaCaller, wndControl, item, bStuff, nCount)
			if (item ~= nil) then
				-- in some cases it's possible that 'item' is numeric. trap that case.
				local nItemType = ( (type(item)=="userdata") and (item:GetItemType()) ) or 0
				if (nItemType >= knAmpWarrior) and (nItemType <= knAmpSpellslinger) then
					wndControl:SetTooltipDoc(nil)
					local wndTooltip, wndTooltipComp = origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
					
					local intFound, strTier = self:IsLearnedByItem(item)
					local wndHeader = wndTooltip:FindChild("ItemTooltip_Header")
					local wndTypeTxt = wndHeader:FindChild("ItemTooltip_Header_Types")
					wndTypeTxt:SetText(wndTypeTxt:GetText()..strTier)
					
					return wndTooltip, wndTooltipComp
				else 
					return origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
				end
			else
				return origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
			end
		end
	end
end 

-----------------------------------------------
-- Many whelps, handle it
-----------------------------------------------

function AMPFinder:OnSave(eType)
	if (eType ~= GameLib.CodeEnumAddonSaveLevel.Account) then return end

	self.bWindowOpen = self.wndMain:IsShown()
	
	local tSaveData = {}
	for idx,property in ipairs(ktUserPrefs) do
		tSaveData[property] = self[property]
	end
	
	return tSaveData
end

function AMPFinder:OnRestore(eType, tSavedData)
	if (eType ~= GameLib.CodeEnumAddonSaveLevel.Account) then return end
	
	for idx,property in ipairs(ktUserPrefs) do
		if tSavedData[property] ~= nil then
			self[property] = tSavedData[property]
		end
	end
	
	-- todo: debug
	if (self.wndMain ~= nil) then
		if (self.bCompact) then 
		 	self:CompactWindow() 
			self.bInitialShow = true  -- force it to redo the windowshow stuff
			self:OnWindowShow()
		end
		self.wndMain:Show(self.bWindowOpen)
	end
	
	if (self.wndAMPFilter ~= nil) then
		local fBox = self.wndAMPFilter:FindChild("FilterBox")
		if (fBox ~= nil) then
			fBox:SetText(self.strFilter)
		end
	end
	
	self:ShowOrHideFilter()
	
	-- Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
end

function AMPFinder:OnWindowManagementReady()
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "AMP Finder"})
end

function AMPFinder:OnSlashCommand(strCmd,strArg)
	strArg = string.lower(strArg)
	if (strArg == "") then
		if (self.wndMain ~= nil) then
			self.wndMain:Show(true)
			self.wndMain:ToFront()
			self:UpdatePane()
			if (self.bPosTracking) then self:HookPosTrack(true) end
		end		
	elseif (strArg == "reset") then
		if (self.wndMain ~= nil) then
			self.wndMain:SetAnchorOffsets(20, -175, 406, 246)
			self:UnCompactWindow()
			self.bCompact = false
			self.wndMain:FindChild("CompactBtn"):SetCheck(true)
			ChatSystemLib.PostOnChannel(2,L["AmpFinderReset"])
		end
	elseif (strArg == "filter") then
		if (self.bShowFilter) then
			self.bShowFilter = false
			ChatSystemLib.PostOnChannel(2,L["FilterDisabled"])
		else
			self.bShowFilter = true
			ChatSystemLib.PostOnChannel(2,L["FilterEnabled"])
		end
		self.strFilter = ""
		if (self.wndAMPFilter ~= nil) then
			local fBox = self.wndAMPFilter:FindChild("FilterBox")
			if (fBox ~= nil) then
				self.wndAMPFilter:FindChild("FilterClearBtn"):Show(false)
				self.wndAMPFilter:FindChild("SearchIcon"):Show(true)
				fBox:SetText(L["FilterBlank"])
				fBox:ClearFocus()
			end
		end
		self:ShowOrHideFilter()
		self:UpdateAMPWindow(nil)
	else
		ChatSystemLib.PostOnChannel(2,L["SlashHelp1"]);
		ChatSystemLib.PostOnChannel(2,L["SlashHelp2"]);
		ChatSystemLib.PostOnChannel(2,L["SlashHelp3"]);
		ChatSystemLib.PostOnChannel(2,L["SlashHelp4"]);
	end
end

function AMPFinder:OnCloseWindow( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
end

function AMPFinder:OnChangeZone(oVar, strNewZone)
	self:UpdatePane()
end

function AMPFinder:ShowOrHideFilter()
	if (self.wndAMPFilter ~= nil) then
		self.wndAMPFilter:Show(self.bShowFilter)
	end
end

function AMPFinder:OnFilterClearBtn( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPFilter == nil) then return end
	local fBox = self.wndAMPFilter:FindChild("FilterBox")
	if (fBox == nil) then return end 
	self.wndAMPFilter:FindChild("FilterClearBtn"):Show(false)
	self.wndAMPFilter:FindChild("SearchIcon"):Show(true)
	self.strFilter = ""
	fBox:SetText(L["FilterBlank"])
	fBox:ClearFocus()
	self:UpdateAMPWindow(nil)
end

function AMPFinder:OnFilterChange( wndHandler, wndControl, strText )
	if (self.wndAMPFilter == nil) then return end
	self.strFilter = strText
	if (strText == "") then
		self.wndAMPFilter:FindChild("FilterClearBtn"):Show(false)
		self.wndAMPFilter:FindChild("SearchIcon"):Show(true)
		self:UpdateAMPWindow(nil)
	else 
		self.wndAMPFilter:FindChild("FilterClearBtn"):Show(true)
		self.wndAMPFilter:FindChild("SearchIcon"):Show(false)
		self:UpdateAMPWindow(strText)
	end
end

-- called when the AMP window filter needs to be updated
function AMPFinder:UpdateAMPWindow(filter)
	self:ShowOrHideFilter()
	if (filter ~= nil) then 
		filter = string.lower(filter)
	end
	
	local tAbilityAMPs = GetAbilityAMPsAddon()
	if (tAbilityAMPs == nil) then return end
	local cnt = 0
	
	-- fallthrough for older AbilityAMPs replacement mods
	local wndAmpMain = tAbilityAMPs.tWndRefs and tAbilityAMPs.tWndRefs.wndMain or tAbilityAMPs.wndMain
	if (wndAmpMain == nil) then return end
	local wndAMPs = wndAmpMain:FindChild("ScrollContainer:Amps")
	for idx, wndAmp in pairs(wndAMPs:GetChildren()) do
		local tAmp = wndAmp:GetData()
		local ampname = string.lower(tAmp.strTitle)
		

		if (tAmp.pixieHighlight ~= nil) then
			wndAMPs:DestroyPixie(tAmp.pixieHighlight)
		end
		
		if (filter ~= nil) then
			if (string.find(ampname,filter) ~= nil) then
				local iX, iY = wndAmp:GetPos()
				local tCircle =	{
					loc = {
						fPoints = { 0, 0, 0, 0 },
						nOffsets = { iX+1, iY-1, iX+30, iY+30 },
					},
					
					strSprite = "DatachronSprites:CommIndicator_GreenPulse",
					bLine = false,
				    DT_CENTER = true,
				}
				tAmp.pixieHighlight = wndAMPs:AddPixie(tCircle)
				cnt = cnt + 1
			end
		end
	end
end

function AMPFinder:AMPFinderBtn_Click( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(true)
	self.wndMain:ToFront()
	self:UpdatePane()
	if (self.bPosTracking) then self:HookPosTrack(true) end
end

function AMPFinder:OnHoverCondAmp( wndHandler, wndControl, x, y )
	self.wndHover = wndControl
	Apollo.StopTimer("AMPFinderTooltipCountdown")
	
	local wndParent = wndControl:GetParent()
	local tData = wndParent:GetData()
	if (tData == nil) then return end
	
	local intFound, strAmpTier, tAugment = self:IsLearnedBySpellId(tData[2])

	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	if not self.wndAMPTooltip or not self.wndAMPTooltip:IsValid() then
		self.wndAMPTooltip = Apollo.LoadForm(self.xmlDoc, "AMPTooltip",
			nil, self)
	end
	local wndTip = self.wndAMPTooltip

	local sCat = ""
	local sName = ""
	local sPowerCost = ""
	local sTierLabel = ""
	local sDesc = ""
	if (tAugment ~= nil) then
		sCat = karCategoryToConstantData[tAugment.nCategoryId][3] or ""
		sName = tAugment.strTitle or ""
		sPowerCost = String_GetWeaselString(Apollo.GetString("AMP_PowerCost"),
			tAugment.nPowerCost or "")
		sTierLabel = String_GetWeaselString(Apollo.GetString("AMP_TierLabel"),
			sCat, tAugment.nCategoryTier or "")
		sDesc = tAugment.strDescription	
	else
		local tSpell = GameLib.GetSpell(tData[2])
		nRecord = AllAmpData[ tData[4] ][ tData[2] ]
		sCat = karCategoryToConstantData[ nRecord[kiAmpCategory] ][3]
		
		sName = tSpell:GetName()
		sPowerCost = string.upper(karClassNames[ tData[4] ]).." " -- something's eating the last char. oh well.
		sPowerCost = string.sub( sPowerCost, 1, string.len(sPowerCost)-1 ) 
		sTierLabel = String_GetWeaselString(Apollo.GetString("AMP_TierLabel"),
			sCat, nRecord[kiAmpRank] or "")
		sDesc = tSpell:GetFlavor()
	end
	
	wndTip:FindChild("NameLabelWindow"):SetText(sName)
	wndTip:FindChild("PowerCostLabelWindow"):SetText(sPowerCost)
	wndTip:FindChild("TierLabelWindow"):SetText(sTierLabel)
	wndTip:FindChild("DescriptionLabelWindow"):SetAML("<P TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceSmall\">"
		..sDesc.."</P>")
	
	local nTextWidth, nTextHeight = wndTip:FindChild("DescriptionLabelWindow"):SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wndTip:GetAnchorOffsets()
	wndTip:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + 68)
	
	extendAugmentationTooltip(wndTip, wndControl, tAugment)
	
	nLeft, nTop, nRight, nBottom = wndTip:GetAnchorOffsets()

	local nMainLeft, nMainTop, nMainRight, nMainBottom = self.wndMain:GetAnchorOffsets()
	local tMouse = Apollo.GetMouse()
	wndTip:SetAnchorOffsets(
		nMainRight-30,
		tMouse.y,
		nRight - nLeft + nMainRight-30,
		nBottom - nTop + tMouse.y)
	wndTip:ToFront()
	wndTip:Show(true)
end

function AMPFinder:OnLeaveCondAmp( wndHandler, wndControl, x, y )
	self.wndLeave = wndControl
	self.timerTooltip:Start()
end


function AMPFinder:OnClickCondAmp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local tData = wndControl:GetData()
	if (tData == nil) then return end
	local wndParent = wndControl:GetParent()
	
	-- can't use this on questgivers or thayd/illium, because it holds no meaning
	if (wndParent:GetName() == "AmpQuestgiverForm") then return end
	if (self.nDisplayedPane == knPaneThaydC) then return end
	if (self.nDisplayedPane == knPaneIlliumC) then return end
	
	if (self.nCompleteDisplayMode == knDisplayRank) then
		self.nCompleteDisplayMode = knDisplayLocation
	elseif (self.nCompleteDisplayMode == knDisplayLocation) then
		self.nCompleteDisplayMode = knDisplayPrice
	else
		self.nCompleteDisplayMode = knDisplayRank
	end
	if (wndParent:GetName() == "AmpVendorForm")	and (self.nCompleteDisplayMode == knDisplayLocation) then
		self.nCompleteDisplayMode = knDisplayPrice
	end
		
	for idx, wndCurr in pairs(wndParent:GetChildren()) do
		local tAmpData = wndCurr:GetData()
		local wndRank = wndCurr:FindChild("AMPRank")
		local wndPrice = wndCurr:FindChild("Price")
		if (wndRank ~= nil) then 
			wndRank:DestroyChildren()
			wndPrice:Show(false)
			if (tAmpData ~= nil) then
				if (self.nCompleteDisplayMode == knDisplayLocation) and (wndParent:GetName() == "AmpGenericForm") then

					local nRecord = AllAmpData[ tAmpData[4] ][ tAmpData[2] ]
					
					if (nRecord == nil) then
						wndRank:SetText(L["LocWorldDrop"])
					else
						local nLoc = nRecord[4]
						if (nLoc == nil) or (nLoc == knLocUnknown) then
							wndRank:SetText(L["LocWorldDrop"])
						elseif (nLoc == knLocAutolearned) then
							wndRank:SetText(L["LocAutoLearned"])
						elseif (nLoc == knLocQuest) then
							wndRank:SetText(L["LocQuestReward"])
						elseif (nLoc == knLocGallowSylvan) then
							wndRank:SetText(L[ self.LocationToVendor[knLocGallow][1][1] ] .."/"
							..L[ self.LocationToVendor[knLocSylvan][1][1] ])
						elseif (self.LocationToVendor[nLoc] ~= nil) then
							wndRank:SetText(L[ self.LocationToVendor[nLoc][1][1] ])
						else
							wndRank:SetText("")
						end
					end
				elseif (self.nCompleteDisplayMode == knDisplayPrice) then
					local nRecord = AllAmpData[ tAmpData[4] ][ tAmpData[2] ]
					
					if (nRecord == nil) then
						wndRank:SetText(L["PriceUnknown"])
					else
						local nLoc = nRecord[4]
						local nItemNum = nRecord[5]
						--TODO: Refactor this
						
						if (nLoc == nil) or (nLoc == knLocUnknown) then
							wndRank:SetText(L["PriceNA"])
						elseif (nLoc == knLocAutolearned) then
							wndRank:SetText(L["PriceNA"])
						elseif (nLoc == knLocQuest) then
							wndRank:SetText(L["PriceNA"])
						elseif (nItemNum > 1) then
							wndRank:SetText("")
							local item = Item.GetDataFromId(nItemNum)
							if (item ~= nil) and (item.GetBuyPrice ~= nil) then
								monPrice = item:GetBuyPrice()
								if (monPrice) then
									wndPrice:SetAmount(monPrice, true)
								else
									wndPrice:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
									wndPrice:SetAmount(0, true)
								end
								wndPrice:Show(true)							
							end
						else
							wndRank:SetText("")
						end
					end
				else
					local nRecord = AllAmpData[ tAmpData[4] ][ tAmpData[2] ]

					local nCatId = nRecord[kiAmpCategory]
					local nRank = nRecord[kiAmpRank]
					wndRank:SetText(String_GetWeaselString(L["RankShort"], karCategoryToConstantData[nCatId][3], nRank))
				end
			end -- tAmpData ~= nil
		end -- wndRank ~= nil
	end -- pairs
end -- ClickCondAmp

function AMPFinder:AMPFinderTooltipClose()
	if (Apollo.GetMouseTargetWindow() ~= self.wndHover) then
		if (self.wndAMPTooltip ~= nil) then
			self.wndAMPTooltip:Destroy()
		end
	end
end

function AMPFinder:OnPaneSelectorBtn( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	self.wndMain:FindChild("PickerListFrame"):Show(false)
	self.wndMain:FindChild("PickerBtn"):SetCheck(false)
	self:UpdatePane(wndControl:GetData())
end

function AMPFinder:OnPickerBtnCheck( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	self.wndMain:FindChild("PickerListFrame"):Show(true)
	self.wndMain:FindChild("ClassListFrame"):Show(false)
	self.wndMain:FindChild("ClassFrame"):FindChild("ClassButton"):SetCheck(false)
end

function AMPFinder:OnPickerBtnUncheck( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	local wndListFrame = self.wndMain:FindChild("PickerListFrame")
	if (wndListFrame ~= nil) then
		wndListFrame:Show(false)
	end
end

function AMPFinder:OnClassSelectorBtn( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	self.wndMain:FindChild("ClassListFrame"):Show(false)
	self.wndMain:FindChild("ClassFrame"):FindChild("ClassButton"):SetCheck(false)
	self.nClassDisplayed = wndControl:GetData()
	self:UpdatePane(-1)
end

function AMPFinder:OnClassBtnCheck( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	local wndListFrame = self.wndMain:FindChild("ClassListFrame")
	if (wndListFrame ~= nil) then wndListFrame:Show(true) end
	self.wndMain:FindChild("PickerListFrame"):Show(false)
	self.wndMain:FindChild("PickerBtn"):SetCheck(false)
end

function AMPFinder:OnClassBtnUncheck( wndHandler, wndControl, eMouseButton )
	if (self.wndAMPTooltip ~= nil) then self.wndAMPTooltip:Destroy() end
	local wndListFrame = self.wndMain:FindChild("ClassListFrame")
	if (wndListFrame ~= nil) then wndListFrame:Show(false) end
end

function AMPFinder:OnInterfaceMenuListHasLoaded()

	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "AMP Finder",
		{ "AMPFinder_ShowHide", "", "CRB_Basekit:kitIcon_Holo_HazardRadioactive" } ) 

	self:UpdateInterfaceMenuAlerts()

end

function AMPFinder:UpdateInterfaceMenuAlerts()
	local tEldanAugmentationData = AbilityBook.GetEldanAugmentationData(AbilityBook.GetCurrentSpec())
	local nAmpsUnlearned = 0

	if (tEldanAugmentationData ~= nil) then 
		nAmpsUnlearned = #tEldanAugmentationData.tAugments
	
		for idx = 1, #tEldanAugmentationData.tAugments do
			local tAmp = tEldanAugmentationData.tAugments[idx]
			if tAmp.eEldanAvailability ~= AbilityBook.CodeEnumEldanAvailability.Unavailable then
				nAmpsUnlearned = nAmpsUnlearned - 1
			end
		end
	end
	
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "AMP Finder",
		{false, String_GetWeaselString(L["AmpsRemaining"], nAmpsUnlearned), nAmpsUnlearned } )
end

function AMPFinder:OnInterfaceMenuShowHide() 
	self.wndMain:Show(true)
	self.wndMain:ToFront()
	self:UpdatePane()
	if (self.bPosTracking) then self:HookPosTrack(true) end
end


--------------------------------------
-- AMP Finder functions
--------------------------------------

function AMPFinder:UpdateClassIcon() 
	local nClass = self.nClassDisplayed
	local strIcon = "IconSprites:Icon_Windows_UI_CRB_Infinity"
		
	if     (nClass == knClassWarrior) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Warrior"
	elseif (nClass == knClassEngineer) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Engineer"
	elseif (nClass == knClassEsper) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Esper"
	elseif (nClass == knClassMedic) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Medic"
	elseif (nClass == knClassStalker) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Stalker"
	elseif (nClass == knClassSpellslinger) then
		strIcon = "IconSprites:Icon_Windows_UI_CRB_Spellslinger"
	else
		return -- not sure what this is, but it ain't somethin we can handle
	end
	self.wndMain:FindChild("ClassFrame"):FindChild("ClassIcon"):SetSprite(strIcon)
	self.wndMain:FindChild("ClassFrame"):SetTooltip(String_GetWeaselString(L["CurrentlyShowingTip"],
		karClassNames[self.nClassDisplayed]))
end

function AMPFinder:BuildClassMenu() 
	local wndClassList = self.wndMain:FindChild("ClassListFrame")
	if (#wndClassList:GetChildren() > 0) then return end

	local arClassList = {
		knClassEngineer, knClassEsper, knClassMedic,
		knClassSpellslinger, knClassStalker, knClassWarrior,
	}
	local arIconList = {
		"IconSprites:Icon_Windows_UI_CRB_Engineer",
		"IconSprites:Icon_Windows_UI_CRB_Esper",
		"IconSprites:Icon_Windows_UI_CRB_Medic",
		"IconSprites:Icon_Windows_UI_CRB_Spellslinger",
		"IconSprites:Icon_Windows_UI_CRB_Stalker",
		"IconSprites:Icon_Windows_UI_CRB_Warrior",		
	}
	for idx=1, #arClassList do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "ClassSelectorBtn", wndClassList, self)
		wndCurr:SetData(arClassList[idx])
		wndCurr:FindChild("Label"):SetText(karClassNames[ arClassList[idx] ]) -- arNameList[idx])
		wndCurr:FindChild("Icon"):SetSprite(arIconList[idx])
		if (arClassList[idx] ~= self.nClass) then
			wndCurr:FindChild("Arrow"):Show(false)
		end
	end
	wndClassList:ArrangeChildrenVert(1)
end

-- TODO: Get this working at some point
function AMPFinder.PaneSorter(a, b)
	local txtA = a:GetText()
	local txtB = b:GetText()
	if (txtA == L["PaneComplete"]) then return "ZZZ" < txtB end
	if (txtB == L["PaneComplete"]) then return txtA < "ZZZ" end
	return string.gsub( txtA , "[)( ]", "") < string.gsub( txtB , "[)( ]", "")
end

function AMPFinder:UpdatePane(nZoneId)
	self:UpdateClassIcon()  -- TODO: Move this to the end of the procedure maybe
	local nOldShownZone = self.nDisplayedPane
	if (nZoneId ~= nil) then
		if (nZoneId == -1) then
			nOldShownZone = nil
		else
			self.nUserSelectedPane = nZoneId
		end
	end
	
	if (self.wndMain == nil) then 
		return
	end

	-- make sure this is set sometime
	-- if it's not been set, abort procedure
	if (self.bAmpLocations == false) then
		self.wndMain:FindChild("AMP_Info"):SetText(L["CannotUpdate"])
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()

		return
	end

	local worldid = GameLib.GetCurrentWorldId()
	local zoneid = GameLib.GetCurrentZoneId()
	local tZoneInfo = GameLib.GetCurrentZoneMap()

	if (worldid == nil) then return end
	if (zoneid == nil) then return end
	if (tZoneInfo == nil) then return end

	-- Change zone
	local strZoneName
	if (self.nUserSelectedPane == 0) then
		self.nDisplayedPane = tZoneInfo.id
		
		if (ktPaneData[self.nDisplayedPane] == nil) then
			strZoneName = tZoneInfo.strName
		else
			strZoneName = L[ ktPaneData[self.nDisplayedPane][1] ]
		end
	elseif (self.nUserSelectedPane == tZoneInfo.id) then
		self.nUserSelectedPane = 0
		self.nDisplayedPane = tZoneInfo.id
		strZoneName = L[ ktPaneData[self.nDisplayedPane][1] ]
	else
		self.nDisplayedPane = self.nUserSelectedPane
		strZoneName = L[ ktPaneData[self.nDisplayedPane][1] ]
	end
	
	-- Build zone list
	self.wndMain:FindChild("PickerBtnText"):SetText(strZoneName)
	self.wndMain:FindChild("PickerList"):DestroyChildren()
	local wndPickerList = self.wndMain:FindChild("PickerList")

	self:BuildClassMenu()

	local arZoneList

	if (self.nFaction == Unit.CodeEnumFaction.ExilesPlayer) then
		arZoneList = {knPaneAlgoroc, knPaneAlgorocQ, knPaneCelestion, knPaneCelestionQ, 
			knPaneFarside, knPaneFarsideE, knPaneGaleras, knPaneThayd, knPaneThaydC,
			knPaneWhitevale, knPaneWilderrun, knPaneComplete}
	elseif (self.nFaction == Unit.CodeEnumFaction.DominionPlayer) then
		arZoneList = {knPaneAuroria, knPaneDeradune, knPaneDeraduneQ, knPaneEllevar, 
			knPaneEllevarQ, knPaneFarside, knPaneFarsideD, knPaneIllium, knPaneIlliumC, 
			knPaneWhitevale, knPaneWilderrun, knPaneComplete}
	else
		return
	end
	
	for idx=1, #arZoneList do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "PaneSelectorBtn", wndPickerList, self)
		local idZone = arZoneList[idx]
		wndCurr:SetData(idZone)
		if (idZone == 0) then
			wndCurr:SetText(L["PaneCurrentZone"])
		else
			if (idZone == tZoneInfo.id) then
				wndCurr:SetText("( "..L[ ktPaneData[idZone][1] ].." )")
				wndCurr:SetStyleEx("UseWindowTextColor",true)
			else
				wndCurr:SetText(L[ ktPaneData[idZone][1] ])
				wndCurr:SetStyleEx("UseWindowTextColor",false)
			end
		end
	end

	self.wndMain:FindChild("PickerList"):ArrangeChildrenVert(0, self.PaneSorter)
	self.wndMain:FindChild("PickerList"):SetVScrollPos(0) -- 30 is hardcoded formatting of the list item height
	
	if (nOldShownZone == self.nDisplayedPane) then
		-- don't redraw if you haven't left the zone
		return
	end
	
	self.wndMain:FindChild("CompactBtn"):Enable(true)
	
	if (string.find(ksQuestPanes, '|'..self.nDisplayedPane..'|')) then
	
		self.wndMain:FindChild("AMP_Info"):SetText("")								
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = true
		self:HookPosTrack(true)
		
		local nTop = 70 -- y location
		local vendorTag = ktPaneData[self.nDisplayedPane][2]
		local wndQgiver = Apollo.LoadForm(self.xmlDoc, "AmpQuestgiverForm", self.wndMain:FindChild("AMP_Info"), self)
		local wndQuestgiver, nTop = self:AddConditionQuestgiver(wndQgiver, nTop, vendorTag, self.nDisplayedPane)
		nTop = self:AddConditionAMPs(knLocQuest, nil, wndQgiver, nTop, true)
		self:SetupArrow(2, wndQgiver, wndQuestgiver)
		wndQgiver:SetAnchorOffsets(10, 10, -10, nTop+20)
		
		self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
		self.wndMain:FindChild("AMP_Info"):RecalculateContentExtents()
		self:InvokeWindowPref()
		
	elseif	(self.nDisplayedPane == knPaneThaydC) or
			(self.nDisplayedPane == knPaneIlliumC) then
		
		self.wndMain:FindChild("AMP_Info"):SetText("")								
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = true
		self:HookPosTrack(true)
		
		local nTop = 70
		vendorTag = knLocCommodity				
		local wndVend = Apollo.LoadForm(self.xmlDoc, "AmpVendorForm", self.wndMain:FindChild("AMP_Info"), self)
		local wndVendor, nTop = self:AddConditionVendor(wndVend, nTop, vendorTag)
		nTop = self:AddConditionAMPs(knLocUnknown, knLocQuest, wndVend, nTop)

		self:SetupArrow(1, wndVend, wndVendor)
		wndVend:SetAnchorOffsets(10, 10, -10, nTop+20)
		
		self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
		self.wndMain:FindChild("AMP_Info"):RecalculateContentExtents()
		self:InvokeWindowPref()

	elseif	(self.nDisplayedPane == knPaneThayd) or
			(self.nDisplayedPane == knPaneIllium) then

		self.wndMain:FindChild("AMP_Info"):SetText("")								
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = true
		self:HookPosTrack(true)
				
		local nTop = 70 -- y location
		local vendorTag = knLocFCON
		local wndVend = Apollo.LoadForm(self.xmlDoc, "AmpVendorForm", self.wndMain:FindChild("AMP_Info"), self)
		local wndVendor, nTop = self:AddConditionVendor(wndVend, nTop, vendorTag)
		-- nTop = self:AddConditionPrestige(75, wndVend, nTop)
		nTop = self:AddConditionAMPs(vendorTag, nil, wndVend, nTop)

		self:SetupArrow(1, wndVend, wndVendor)
		wndVend:SetAnchorOffsets(10, 10, -10, nTop+20)
				
		self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
		self.wndMain:FindChild("AMP_Info"):RecalculateContentExtents()
		self:InvokeWindowPref()		

	elseif (string.find(ksVendorPanes,
		"|"..self.nDisplayedPane.."|")) then

		self.wndMain:FindChild("AMP_Info"):SetText("")								
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = true
		self:HookPosTrack(true)

		local nTop = 70 -- y location
		local vendorTag, vendorTag2 = ktPaneData[self.nDisplayedPane][2], nil
		local repTag = self.LocationToVendor[vendorTag][1][6]
		if (vendorTag == knLocGallow) or (vendorTag == knLocSylvan) then vendorTag2 = knLocGallowSylvan
		elseif (vendorTag == knLocBravo) then vendorTag2 = knLocWalkers end
		
		local wndVend = Apollo.LoadForm(self.xmlDoc, "AmpVendorForm", self.wndMain:FindChild("AMP_Info"), self)
		local wndVendor, nTop = self:AddConditionVendor(wndVend, nTop, vendorTag)
		nTop = self:AddConditionReputation(wndVend, nTop, repTag)
		nTop = self:AddConditionAMPs(vendorTag, vendorTag2, wndVend, nTop)
		self:SetupArrow(1, wndVend, wndVendor)
		wndVend:SetAnchorOffsets(10, 10, -10, nTop+20)
		
		self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
		self.wndMain:FindChild("AMP_Info"):RecalculateContentExtents()
		self:InvokeWindowPref()

	elseif (self.nDisplayedPane == knPaneComplete) then

		self:UpdateClassIcon()
		self.wndMain:FindChild("CompactBtn"):Enable(false)
		self.wndMain:FindChild("AMP_Info"):SetText("")								
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = false
		self:HookPosTrack(false)
		self:SetupArrow(0)
		
		local nTop = 10 -- y location
		local wndList = Apollo.LoadForm(self.xmlDoc, "AmpGenericForm", self.wndMain:FindChild("AMP_Info"), self)
		nTop = self:AddConditionAMPs(nil, nil, wndList, nTop)
		wndList:SetAnchorOffsets(10, 10, -10, nTop+20)
													
		self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
		self.wndMain:FindChild("AMP_Info"):RecalculateContentExtents()
		self:InvokeWindowPref()	

	else -- current zone is not in the list
	
		self.wndMain:FindChild("AMP_Info"):SetText(L["NoInfoForCurrentZone"])
		self.wndMain:FindChild("AMP_Info"):DestroyChildren()
		self.bPosTracking = false
		self:HookPosTrack(false)
		self:SetupArrow(0)
		
	end					

end -- UpdatePane

function AMPFinder:SetupArrow(nType, wndPane, wndLabel)
	self.nArrowType = nType
	if (nType == 0) then
		self.wndArrowPane = nil
		self.wndArrowLabel = nil
	elseif (nType == 1) then 
		self.wndArrowPane = wndPane
		self.wndArrowLabel = wndLabel
		self:UpdateArrowVendor(true)
	elseif (nType == 2) then
		self.wndArrowPane = wndPane
		self.wndArrowLabel = wndLabel
		self:UpdateArrowQuestgiver(true)
	end
end

function AMPFinder:AddConditionText(wndParent, nTop, strText)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	wndCurr:FindChild("ConditionField"):SetText(strText)
	wndCurr:FindChild("Image"):SetSprite(nil)
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	return nTop+20
end

function AMPFinder:AddConditionVendor(wndParent, nTop, nVendorTag)
	local tVendorData = self.LocationToVendor[nVendorTag][1]
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	wndParent:FindChild("AddInfo"):SetText(L[ tVendorData[2] ].."\n("..round(tVendorData[3])..","..round(tVendorData[4])..")")
	wndCurr:FindChild("ConditionField"):SetText(L[ tVendorData[5] ])
	wndCurr:FindChild("ConditionField"):SetFont("CRB_InterfaceMedium_BO")
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	wndCurr:SetData({knCondVendor, nVendorTag})
	return wndCurr, nTop+25
end

function AMPFinder:AddConditionQuestgiver(wndParent, nTop, nVendorTag, nZoneTag)
	local tVendorData = self.LocationToVendor[nVendorTag][1]
	local tEp = ktEpisodeInfo[nZoneTag]
	local ep, strQgiver, strQline, q1, q2, q3 = tEp[kiEpisodeNum], L[ tEp[kiEpisodeQuestgiver] ], L[ tEp[kiEpisodeName] ],
		tEp[kiEpisodeQuest1], tEp[kiEpisodeQuest2], tEp[kiEpisodeQuest3]
		
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	wndParent:FindChild("AddInfo"):SetText(L[tVendorData[2]].."\n("..round(tVendorData[3])..","..round(tVendorData[4])..")")
	wndCurr:FindChild("ConditionField"):SetText(L["QuestsFrom"]..strQgiver)
	wndCurr:FindChild("ConditionField"):SetTooltip(L["QuestgiverTip"])
	wndCurr:FindChild("ConditionField"):SetFont("CRB_InterfaceMedium_BO")
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	wndCurr:SetData({knCondQuestgiver, nVendorTag})
	nTop = nTop + 25

	local epiKey = self:GetKeyEpisode(ep)

	if (q1 ~= nil) then
		nTop = self:AddConditionQuest(wndParent, nTop, ep, q1)
	end
	
	if (q2 ~= nil) then
		nTop = self:AddConditionQuest(wndParent, nTop, ep, q2)
	end
	
	if (q3 ~= nil) then
		nTop = self:AddConditionQuest(wndParent, nTop, ep, q3)		
	end
	-- update after adding the other conditions
	return wndCurr, nTop
end

function AMPFinder:AddConditionQuest(wndParent, nTop, nEpId, nQuestId)
	local strQName = karEpisodeTitles[nQuestId]
	if (strQName == nil) then return nTop end
	strQName = L[ strQName ]
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	wndCurr:FindChild("ConditionField"):SetText(L["QuestCondition"]..strQName)
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	wndCurr:SetData({knCondQuest, nEpId, nQuestId})
	wndCurr:SetTooltip(L["EpisodeTip"])
	self:UpdateCondQuest(wndCurr)
	return nTop+20
end

--[[
function AMPFinder:AddConditionPrestige(nAmount, wndParent, nTop)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	wndCurr:SetData({knCondPrestige,nAmount})
	wndCurr:SetTooltip(L["PrestigeTip"])
	self:UpdateCondPrestige(wndCurr)
	return nTop+25
end
--]]

function AMPFinder:AddConditionReputation(wndParent, nTop, strGroupName)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndParent, self)
	strGroupName = L[strGroupName] -- localized groupname
	wndCurr:FindChild("ConditionField"):SetText(strGroupName..": "..
		"0/8000")
	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
	wndCurr:SetData({knCondReputation, strGroupName})
	wndCurr:SetTooltip(L["PopularityTip"])
	self:UpdateCondReputation(wndCurr)
	return nTop+25
end

function AMPFinder:AddConditionAMP(wndParent, nTop, sAmpName, nSpellId, nRecord, questTooltip)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "AMPIndicator", wndParent, self)
	local nLoc = nRecord[4]
	local nItemNum = nRecord[5]
	
	local wndRank = wndCurr:FindChild("AMPRank")
	local wndPrice = wndCurr:FindChild("Price")
	wndPrice:Show(false)
	wndCurr:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Lock")
	wndCurr:FindChild("AMPName"):SetText(sAmpName)
	
	if (self.nCompleteDisplayMode == knDisplayLocation) and (wndParent:GetName() == "AmpGenericForm") then
	
		if (nLoc == nil) or (nLoc == knLocUnknown) then
			wndRank:SetText(L["LocWorldDrop"])
		elseif (nLoc == knLocAutolearned) then
			wndRank:SetText(L["LocAutoLearned"])
		elseif (nLoc == knLocQuest) then
			wndRank:SetText(L["LocQuestReward"])
		elseif (nLoc == knLocGallowSylvan) then
			wndRank:SetText(L[ self.LocationToVendor[knLocGallow][1][1] ].."/"
				..L[ self.LocationToVendor[knLocSylvan][1][1] ])
		elseif (self.LocationToVendor[nLoc] ~= nil) then
			wndRank:SetText(L[ self.LocationToVendor[nLoc][1][1] ])
		else
			wndRank:SetText("")
		end
	
	elseif (self.nCompleteDisplayMode == knDisplayPrice)
		and (wndParent:GetName() ~= "AmpQuestgiverForm")
		and (self.nDisplayedPane ~= knPaneThaydC)
		and (self.nDisplayedPane ~= knPaneIlliumC)
		then
		
		-- TODO: refactor this, we use it twice and should only write once
		if (nLoc == nil) or (nLoc == knLocUnknown) then
			wndRank:SetText(L["PriceNA"])
		elseif (nLoc == knLocAutolearned) then
			wndRank:SetText(L["PriceNA"])
		elseif (nLoc == knLocQuest) then
			wndRank:SetText(L["PriceNA"])
		elseif (nItemNum > 1) then
			wndRank:SetText("")
			local item = Item.GetDataFromId(nItemNum)
			if (item ~= nil) and (item.GetBuyPrice ~= nil) then
					monPrice = item:GetBuyPrice()
					if (monPrice) then
						wndPrice:SetAmount(monPrice, true)
					else
						wndPrice:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
						wndPrice:SetAmount(0, true)
					end
					wndPrice:Show(true)							
			end
		else
			wndRank:SetText("")
		end
	
	else
		local tRecord = AllAmpData[self.nClassDisplayed][nSpellId] -- AllAmpData[nPane][nSpellId]
		strWedgeName = karCategoryToConstantData[ tRecord[kiAmpCategory] ][3]
		wndRank:SetText(String_GetWeaselString(L["RankShort"], strWedgeName, tRecord[kiAmpRank]))	
	end
	
	if (self.nClass == self.nClassDisplayed) then
		wndCurr:SetData( {knCondAMP, nSpellId, false, self.nClassDisplayed} )
	else
		wndCurr:SetData( {knCondAMP, nSpellId, false, self.nClassDisplayed} )
	end

	wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+18)
	
	if (questTooltip) then
		wndCurr:SetTooltip(L["RewardTip"])
	end
	
	if (self.nClass == self.nClassDisplayed) then
		self:UpdateCondAMP(wndCurr)
	end
	
	return nTop+18
end

function AMPFinder:AddConditionAMPs(loc1, loc2, wndVend, nTop, questTooltip)
	local tNameSorter = { }
	local tNameIndex = { }
	
	local tThisClassAmps = AllAmpData[self.nClassDisplayed]
	if (tThisClassAmps == nil) then
		return nTop
	end
	
	if (self.nClass ~= self.nClassDisplayed) then
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "Condition", wndVend, self)
		wndCurr:FindChild("ConditionField"):SetText(String_GetWeaselString(L["NotMyClassHeader"],
			karClassNames[self.nClassDisplayed]))
		wndCurr:FindChild("ConditionField"):SetTextColor("UI_TextHoloBodyHighlight")
		wndCurr:FindChild("Image"):SetSprite(nil)
		wndCurr:SetAnchorOffsets(0, nTop, 0, nTop+25)
		nTop = nTop+20
	end
	
	for idx, rec in pairs(tThisClassAmps) do
		local spellData = GameLib.GetSpell(idx)
		if (spellData ~= nil) then
			local sAmpName = spellData:GetName()
			
			local nRecord = tThisClassAmps[idx]
			if (nRecord ~= nil) then
				local nLoc = nRecord[kiLocation]
				if (nLoc == nil) then nLoc = knLocUnknown end
				if ((nLoc == loc1) or (nLoc == loc2)) or (loc1 == nil) then
					table.insert(tNameSorter, sAmpName)
					tNameIndex[sAmpName] = idx
				end
			end
		end
	end
	table.sort(tNameSorter)
	for i,sAmpName in ipairs(tNameSorter) do
		local nSpellId = tNameIndex[sAmpName]
		local tRecord = tThisClassAmps[nSpellId]
		nTop = self:AddConditionAMP(wndVend, nTop, sAmpName, nSpellId, tRecord, questTooltip)
	end
	return nTop
end


function AMPFinder:HookPosTrack(bHookMe)
	if (self.timerPos == nil) then return end
	
	if (bHookMe) then
		self.timerPos:Start()
	else
		self.timerPos:Stop()
	end
end

function AMPFinder:OnQuestStateChanged() 
	local wndInfo = self.wndMain:FindChild("AMP_Info")
	for idx, wndContent in pairs(wndInfo:GetChildren()) do
		for idx, wndCondition in pairs(wndContent:GetChildren()) do
			local tData = wndCondition:GetData()
			if (tData) then
				if (tData[1] == knCondQuest) then
					self:UpdateCondQuest(wndCondition,tData)
				end
			end -- tData
		end -- wndContent:GetChildren
	end -- wndInfo:GetChildren
end

--[[
function AMPFinder:OnPlayerCurrencyChanged()
	local wndInfo = self.wndMain:FindChild("AMP_Info")
	for idx, wndContent in pairs(wndInfo:GetChildren()) do
		for idx, wndCondition in pairs(wndContent:GetChildren()) do
			local tData = wndCondition:GetData()
			if (tData) then
				if (tData[1] == knCondPrestige) then
					self:UpdateCondPrestige(wndCondition)
				end
			end -- tData
		end -- wndContent:GetChildren
	end -- wndInfo:GetChildren
end
--]]

function AMPFinder:OnReputationChanged(tFaction)
	local wndInfo = self.wndMain:FindChild("AMP_Info")
	for idx, wndContent in pairs(wndInfo:GetChildren()) do
		for idx, wndCondition in pairs(wndContent:GetChildren()) do
			local tData = wndCondition:GetData()
			if (tData) then
				if (tData[1] == knCondReputation) then
					self:UpdateCondReputation(wndCondition)
				end
			end -- tData
		end -- wndContent:GetChildren
	end -- wndInfo:GetChildren
end

-- called whenever an AMP is unlocked on the pane
function AMPFinder:OnAMPChanged() 
	local wndInfo = self.wndMain:FindChild("AMP_Info")
	for idx, wndContent in pairs(wndInfo:GetChildren()) do
		for idx, wndCondition in pairs(wndContent:GetChildren()) do
			local tData = wndCondition:GetData()
			if (tData) then
				if (tData[1] == knCondAMP) then
					self:UpdateCondAMP(wndCondition,tData)
				end
			end -- tData
		end -- wndContent:GetChildren
	end -- wndInfo:GetChildren
	
	self:UpdateInterfaceMenuAlerts()
end

function AMPFinder:UpdateArrowVendor(bForceUpdate) -- (wndVendor, wndParent)
	local wndVendor = self.wndArrowPane
	local wndParent = self.wndArrowLabel
	
	local tData = wndParent:GetData()
	local wndArrow = wndVendor:FindChild("Arrow")
	
	wndArrow:DestroyAllPixies()
	
	-- update purchases
	-- traverse the parent, find any getData. if any rep or locked amps are present, we're not complete
	local bComplete = true
	local strNeedRep = ""
	for idx, wndCondition in pairs(wndVendor:GetChildren()) do
		local tData = wndCondition:GetData()
		if (tData) then
			if (tData[1] == knCondReputation) then
				strNeedRep = "\n<" .. tData[2] .. ">"
				bComplete = false
			elseif (tData[1] == knCondAMP) then
				if (tData[3] == false) then
					bComplete = false
				end
			end
		end -- tData
	end
	
	if (bComplete) then
		wndParent:SetTooltip(L["PurchasedAllAmps"])
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextTextPureGreen")
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Checkmark")
		
	end
	
	if (self.bAmpLocations == false) then return end
		
	if (self.bMoving) or (bForceUpdate) then
	
		local tZoneInfo = GameLib.GetCurrentZoneMap()
		
		if (tZoneInfo == nil) or (tZoneInfo.id ~= math.abs(self.nDisplayedPane)) then
			strShownZoneName = L[ ktPaneData[self.nDisplayedPane][1] ]
			wndArrow:SetTooltip("")
			wndArrow:SetTextFlags("DT_CENTER", true)
			wndArrow:SetTextFlags("DT_VCENTER", true)
			wndArrow:SetTextFlags("DT_WORDBREAK", true)

			if (bComplete) then
				wndArrow:SetText(L["PurchasedAllAmps"])
			else
				wndArrow:SetText(String_GetWeaselString(L["TravelTo"]..strNeedRep, strShownZoneName))
				if (strNeedRep ~= "") then
					wndArrow:SetTooltip(L["PopularityTip"])
				end
			end
			return
			
		end
		
		wndArrow:SetTooltip("")
		wndArrow:SetTextFlags("DT_CENTER", false)
		wndArrow:SetTextFlags("DT_VCENTER", false)
		wndArrow:SetTextFlags("DT_WORDBREAK", false)

		local arLocations = self.LocationToVendor[tData[2]]
		if (arLocations == nil) then return end
		local nNearestIdx = 1 -- fallback
		local nNearestDist = 99999999
		for idx = 1, #arLocations do
			local dist = self:GetDistanceSquared(arLocations[idx])
			if (dist < nNearestDist) then
				nNearestIdx = idx
				nNearestDist = dist
			end
		end	

		-- sqrt is expensive, so only sqrt once
		local distance = math.sqrt(nNearestDist)
		wndArrow:SetText(math.floor(distance).."m")	
		local tVendorData = arLocations[nNearestIdx]
		if (tVendorData == nil) then return end  -- bugcheck
		
		-- TODO: Cache text changes so we aren't changing the vendor constantly
		wndVendor:FindChild("AddInfo"):SetText(L[tVendorData[2]].."\n("..round(tVendorData[3])..","..round(tVendorData[4])..")")
		wndParent:FindChild("ConditionField"):SetText(L[tVendorData[5]]);
			
		local strSpriteName
		if (distance < 5) then
			local nPixieId = wndArrow:AddPixie({
			  bLine = false,
			  strSprite = "Crafting_CoordSprites:sprCoord_Checkmark",
			  fRotation = 0,
			  loc = {
			    fPoints = {0,0,1,1},
			    nOffsets = {20,0,-20,0}
			  },
			})	
		else
			local nPixieId = wndArrow:AddPixie({
			  bLine = false,
			  strSprite = "ClientSprites:MiniMapPlayerArrow",
			  fRotation = self:GetDegree(arLocations[nNearestIdx]), -- nDegree,
			  loc = {
			    fPoints = {0,0,1,1},
			    nOffsets = {20,0,-20,0}
			  },
			})	
		end
		
	end -- if moving
end -- update arrow vendor

function AMPFinder:UpdateArrowQuestgiver(bForceUpdate) -- (wndVendor, wndParent)
	local wndVendor = self.wndArrowPane
	local wndParent = self.wndArrowLabel
	
	local tData = wndParent:GetData()
	local wndArrow = wndVendor:FindChild("Arrow")
	
	wndArrow:DestroyAllPixies()

	-- update quest progress
	-- traverse the parent, find any getData. if any quests aren't complete, we're not complete
	local bComplete = true
	for idx, wndCondition in pairs(wndVendor:GetChildren()) do
		local tData = wndCondition:GetData()
		if (tData) then
			if (tData[1] == knCondQuest) then bComplete = false end
		end -- tData
	end

	if (bComplete) then
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextTextPureGreen")
		wndParent:FindChild("ConditionField"):SetTooltip(L["NoMoreRewards"])
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Checkmark")
	end
	
	if (self.bAmpLocations == false) then return end
	
	if (self.bMoving) or (bForceUpdate) then
		local tZoneInfo = GameLib.GetCurrentZoneMap()
		
		if (tZoneInfo == nil) or (tZoneInfo.id ~= math.abs(self.nDisplayedPane)) then
			strShownZoneName = L[ ktPaneData[self.nDisplayedPane][1] ]
	
			wndArrow:SetTextFlags("DT_CENTER", true)
			wndArrow:SetTextFlags("DT_VCENTER", true)
			wndArrow:SetTextFlags("DT_WORDBREAK", true)
			if (bComplete) then
				wndArrow:SetText(L["ObtainedReward"])
			else
				wndArrow:SetText(String_GetWeaselString(L["TravelTo"], strShownZoneName))
			end
			return
			
		end
		
		wndArrow:SetTextFlags("DT_CENTER", false)
		wndArrow:SetTextFlags("DT_VCENTER", false)
		wndArrow:SetTextFlags("DT_WORDBREAK", false)
	
		-- Questgivers can only have one valid location		
		local arLocations = self.LocationToVendor[tData[2]]
		local distance = math.sqrt(self:GetDistanceSquared(arLocations[1]))
		wndArrow:SetText(math.floor(distance).."m")	
		
		local tVendorData = arLocations[1]

		local strSpriteName
		if (distance < 5) then 
			local nPixieId = wndArrow:AddPixie({
			  bLine = false,
			  strSprite = "Crafting_CoordSprites:sprCoord_Checkmark",
			  fRotation = 0,
			  loc = {
			    fPoints = {0,0,1,1},
			    nOffsets = {20,0,-20,0}
			  },
			})	
		else
			local nPixieId = wndArrow:AddPixie({
			  bLine = false,
			  strSprite = "ClientSprites:MiniMapPlayerArrow",
			  fRotation = self:GetDegree(arLocations[1]),
			  loc = {
			    fPoints = {0,0,1,1},
			    nOffsets = {20,0,-20,0}
			  },
			})	
		end
	end -- if moving
end

function AMPFinder:UpdateCondQuest(wndParent)
	local tData = wndParent:GetData()
	
	local epiKey = self:GetKeyEpisode(tData[2])
	local bComplete = false
	local bInProgress = false
	if (epiKey ~= nil) then
		-- TESTING
		-- Print("ep " .. epiKey:GetId() .. ": " .. epiKey:GetTitle())
		tEpisodeProgress = epiKey:GetProgress()
		for idx, queSelected in pairs(epiKey:GetAllQuests()) do
			local nQuestId = queSelected:GetId()
			if (nQuestId == tData[3]) then
				-- TESTING
				-- Print("quest " .. nQuestId .. ": " .. queSelected:GetTitle())
				local nStatus = GetQuestStatus(queSelected)
				if (nStatus == 2) then
					bComplete = true
				elseif (nStatus == 1) then
					bInProgress = true
				end
			end
		end
	end
	if (bComplete) then
		wndParent:SetData(nil) -- prevent future updates, it's complete
		wndParent:SetTooltip("")
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Checkmark")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextTextPureGreen")
	elseif (bInProgress) then  -- experimental
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kiticon_Holo_Forward")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_BtnTextHoloListNormal")	
	else
		wndParent:FindChild("Image"):SetSprite(nil)
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextDefault")
	end
end

--[[
function AMPFinder:UpdateCondPrestige(wndParent)
	local tData = wndParent:GetData()
	local nCurrent = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Prestige):GetAmount()
	wndParent:FindChild("ConditionField"):SetText(nCurrent.."/"..tData[2].." "..Apollo.GetString("CRB_Prestige"))
	if (nCurrent > tData[2]) then
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Checkmark")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextTextPureGreen")
	else
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_X")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextDefault")
	end
end
--]]

function AMPFinder:UpdateCondReputation(wndParent)
	local tData = wndParent:GetData()
	local tReputationInfo = GameLib.GetReputationInfo()
	local tThisRep
	for idx, tRep in pairs(tReputationInfo) do
		if (tRep.strName == tData[2]) then tThisRep = tRep end
	end
	
	if (tThisRep == nil) then
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_QuestionMark")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextDefault")
	elseif (tThisRep.nCurrent >= 8000) then
		wndParent:SetData(nil) -- prevent future updates, rep attained
		wndParent:SetTooltip("")
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_Checkmark")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextTextPureGreen")
		wndParent:FindChild("ConditionField"):SetText(tThisRep.strName..": "..
			"8000/8000")

	else
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kiticon_Holo_Forward")
		wndParent:FindChild("ConditionField"):SetTextColor("UI_WindowTextDefault")
		wndParent:FindChild("ConditionField"):SetText(tThisRep.strName..": "..
			tThisRep.nCurrent.."/8000")
	end	
end

function AMPFinder:UpdateCondAMP(wndParent) 
	local tData = wndParent:GetData()
	local intFound, strAmpTier, tAmp = self:IsLearnedBySpellId(tData[2])
	if (tAmp ~= nil) and (tAmp.eEldanAvailability ~= AbilityBook.CodeEnumEldanAvailability.Unavailable) then
		wndParent:SetData( { tData[1], tData[2], true, tData[4] } )  -- set data to 'true' to indicate it's okay
		wndParent:FindChild("Image"):SetSprite(nil)
	else 
		wndParent:FindChild("Image"):SetSprite("CRB_Basekit:kitIcon_Holo_LockDisabled")
	end
end

function AMPFinder:UpdateCharacterPosition()
	-- Updates character position and changes framerate
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if (unitPlayer == nil) then return end
	
	local tPlayerPos = unitPlayer:GetPosition()
	local nHeading = unitPlayer:GetHeading()
	if (tPlayerPos == nil) then return end
	if (nHeading == nil) then return end

	local nDeltaX = tPlayerPos.x - self.tPlayerPos.x
	local nDeltaZ = tPlayerPos.z - self.tPlayerPos.z
	local nDeltaH = nHeading - self.nHeading
	
	if (nDeltaX ~= 0) or (nDeltaZ ~= 0) or (nDeltaH ~= 0) then
		self.bMoving = true
		self.idleTicks = 0
		
		if (GameLib:GetFrameRate() > 15) then
			self.TimerSpeed = knFastDelay
		else 
			self.TimerSpeed = knSlowDelay
		end
		
		self.timerPos:Set(self.TimerSpeed, true)		
	else
		self.bMoving = false
		self.idleTicks = self.idleTicks + 1
		
		if (self.idleTicks == 50) then
			self.TimerSpeed = knSlowDelay
			self.timerPos:Set(self.TimerSpeed, true)
		end
	end
	
	self.tPlayerPos = tPlayerPos
	self.nHeading = nHeading
	
	local tZoneInfo = GameLib.GetCurrentZoneMap()
	if (tZoneInfo ~= nil) then
		self.nZoneId = tZoneInfo.id
	end
end

function AMPFinder:UpdateArrow()
	-- Each vendor/questgiver window has an "arrow" associated with it.
	-- If no arrow, exit function

	if (self.bPosTracking == false) then
		self:HookPosTrack(false)
		return
	end

	if (self.bAmpLocations == false) then return end
	
	self:UpdateCharacterPosition()
	
	if (self.bMoving) then
	
		if (self.nArrowType == 0) then
			return
		elseif (self.nArrowType == 1) then
			self:UpdateArrowVendor()
		elseif (self.nArrowType == 2) then
			self:UpdateArrowQuestgiver()
		end
		
	end
	
	if (self.wndMain:IsShown() == false) then
		self:HookPosTrack(false)
		return
	end

	
end

function AMPFinder:InvokeWindowPref()
	-- TODO: allow the window to be persistent if set by user preference.
	-- this is where we would force window to be shown if it weren't already, on a zone change
	-- self.wndMain:Invoke()
end

---------------------------------------------------------------------------------------------------
-- AMPFinder Functions
---------------------------------------------------------------------------------------------------

function AMPFinder:CompactWindow()
	self.wndMain:FindChild("MiniFrame"):Show(true)
	self.wndMain:FindChild("CloseBtn"):Show(false)
	self.wndMain:FindChild("BGPane"):Show(false)
	self.wndMain:FindChild("Frame"):Show(false)
	self.wndMain:FindChild("WindowTitle"):Show(false)
	self.wndMain:FindChild("PickerBtn"):SetCheck(false)
	self.wndMain:FindChild("PickerBtn"):Show(false)
	self.wndMain:FindChild("PickerListFrame"):Show(false)
	self.wndMain:FindChild("PickerFrame"):Show(false)
	self.wndMain:FindChild("ClassFrame"):Show(false)
	self.wndMain:FindChild("ClassFrame"):FindChild("ClassButton"):SetCheck(false)
	self.wndMain:FindChild("ClassListFrame"):Show(false)
	self.wndMain:FindChild("AMP_Info"):SetStyle("VScroll", false)
	self.wndMain:FindChild("AMP_Info"):SetVScrollPos(0)
	self.wndMain:FindChild("AMP_Info"):SetAnchorOffsets(-28, -11, 288, 90)
	self.wndMain:FindChild("MiniFrame"):SetAnchorOffsets(0, -3, 241, 95)
	self.wndMain:FindChild("CompactBtn"):SetAnchorOffsets(211, -4, 243, 28)
end

function AMPFinder:UnCompactWindow()
	self.wndMain:FindChild("MiniFrame"):Show(false)
	self.wndMain:FindChild("CloseBtn"):Show(true)
	self.wndMain:FindChild("BGPane"):Show(true)
	self.wndMain:FindChild("Frame"):Show(true)
	self.wndMain:FindChild("WindowTitle"):Show(true)
	self.wndMain:FindChild("PickerBtn"):Show(true)
	self.wndMain:FindChild("PickerFrame"):Show(true)
	self.wndMain:FindChild("ClassFrame"):Show(true)
	self.wndMain:FindChild("AMP_Info"):SetStyle("VScroll", true)
	self.wndMain:FindChild("AMP_Info"):SetAnchorOffsets(35, 115, 351, 390)
	self.wndMain:FindChild("MiniFrame"):SetAnchorOffsets(83, 21, 324, 119)
	self.wndMain:FindChild("CompactBtn"):SetAnchorOffsets(294, 20, 326, 52)
end

function AMPFinder:OnCompactShrink( wndHandler, wndControl, eMouseButton )
	if (self.bCompact) then return end
	self.bConfirmedCompact = true
	self.bCompact = true
	self:CompactWindow()
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft+83, nTop+24, nLeft+83+245, nTop+24+100)

	self:UpdateInterfaceWindowTrack()
end

function AMPFinder:OnCompactRestore( wndHandler, wndControl, eMouseButton )
	if (self.bCompact == false) then return end
	self.bConfirmedCompact = true
	self.bCompact = false
	self:UnCompactWindow()
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft-83, nTop-24, nLeft-83+386, nTop-24+421)
	
	self:UpdateInterfaceWindowTrack()
end

-- tells the OptionsInterface addon to update its stored position
function AMPFinder:UpdateInterfaceWindowTrack()
	-- thanks to sinaloit :)
	local OptInterface = GetOptionsAddon()
	if (OptInterface ~= nil) then
	    OptInterface:UpdateTrackedWindow(self.wndMain)
	end
end

-- If window is offscreen, then reposition it.
function AMPFinder:OnWindowShow( wndHandler, wndControl )
	if (self.bInitialShow == false) then return end
	self.bInitialShow = false
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	if (nBottom-nTop < 421) then
		self.bCompact = true
		self.wndMain:FindChild("CompactBtn"):SetCheck(false)
		self:CompactWindow()
	else
		self.bCompact = false
		self.wndMain:FindChild("CompactBtn"):SetCheck(true)
		self:UnCompactWindow()
	end
end

-- A bit hacky - if the window is resized smaller than 421 tall, then it's compact.
-- Only runs when the user resizes so it shouldn't be a huge performance hit.
-- Once WindowManagement restores a window to compacted state, we can stop checking.
function AMPFinder:OnWindowResize( wndHandler, wndControl )
	if (self.bConfirmedCompact) then return end
	
	if (self.wndMain == nil) then return end
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	if (nBottom-nTop < 421) then
		if (self.bCompact == false) then
			self.bConfirmedCompact = true
			self.bCompact = true
			self.wndMain:FindChild("CompactBtn"):SetCheck(false)
			self:CompactWindow()
		end
		-- Print("Compact")
	else
		-- Print("Full-sized")
	end	
end

------------------------------------------------------------------
-- AMPFinder Instance
-----------------------------------------------------------------------------------------------
local AMPFinderInst = AMPFinder:new()
AMPFinderInst:Init()
