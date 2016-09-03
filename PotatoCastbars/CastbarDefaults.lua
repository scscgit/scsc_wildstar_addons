-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoCastbars Defaults
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local Defaults  = {} 
Defaults.__index = Defaults

setmetatable(Defaults, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

Defaults.luaSpecialCastbar = {
	name = "Special Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	anchors = {0.5, 1, 0.5, 1},
	offsets = {-175, -335,  175, -300}
}

Defaults.luaSpecialCastbar.tMultitap = {
	tiers = {},
	
	texture = "Aluminum",
	color = "FF0000",
	transparency = 100,
	
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},

}

Defaults.luaSpecialCastbar.tCharged = {
	tiers = {},
	previous = 1,
	
	showFirst = false,
		
	texture = "Aluminum",
	colorCharging = "00AAAA",
	transCharging = 100,
	colorCharged = "CC00CC",
	transCharged = 100,
	colorBackground = "FFFFFF",
	transBackground = 100,
	
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},

}

Defaults.luaPlayerCastbar = {
	name = "Player Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	anchors = {0.5, 1, 0.5, 1},
	offsets = {-370, -128,  -10, -108}
}

Defaults.luaTargetCastbar = {
	name = "Target Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},	
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	anchors = {0.5, 1, 0.5, 1},
	offsets = {  10, -128,  370, -108}
}

Defaults.luaToTCastbar = {
	name = "ToT Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},	
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	anchors = {0.5, 1, 0.5, 1},
	offsets = { 270, -240,  500, -225}
}

Defaults.luaFocusCastbar = {
	name = "Focus Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},	
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},
	anchors = {0.5, 0, 0.5, 0},
	offsets =  {-100,  130,  100,  145}
}
--[[Defaults.luaPet1Castbar = {
	name = "Player Castbar",
	name = "Target Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},	
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	anchors = {0.5, 1, 0.5, 1},
	offsets =  {-300, -150, -200, -100}
}
Defaults.luaPet2Castbar = {
	name = "Player Castbar",
	name = "Target Castbar",
	showFrame = 1,
	border = {
		show = true,
		color = "000000",
		transparency = "67",
		size = 2
	},
	background = {
		show = true,
		color = "000000",
		transparency = "47"
	},
	texture = "Minimalist",
	color = "FEB308",
	transparency = 100,
	barGrowth = 1,
	showIcon = 1,
	textLeft = {
		type = 1,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	
	textMid = {
		type = 0,
		font = {
				base = "CRB_Interface",
				size = "10",
				props = ""
		}
	},	
	textRight = {
		type = 2,
		font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
	},	anchors = {0.5, 1, 0.5, 1},
	offsets =  {-300, -150, -200, -100}
}]]--

Defaults.tSpellNameToSprite = {
--Warrior
    ["Unstoppable Force"] = "ClientSprites:Icon_SkillWarrior_Unstoppable_Force",
    ["Relentless Strikes"] = "Icon_SkillPhysical_UI_wr_lng",
    ["Leap"] = "Icon_SkillPhysical_UI_wr_leap",
    ["Atomic Spear"] = "Icon_SkillWarrior_Atomic_Spear",
    ["Grapple"] = "Icon_SkillPhysical_UI_wr_whip",
    ["Flash Bang"] = "Icon_SkillPhysical_UI_wr_grenade",
    ["Plasma Blast"] = "ClientSprites:Icon_SkillWarrior_Plasma_Blast",
    ["Bolstering Strike"] = "Icon_SkillMisc_UI_wr_dfgrp",
    ["Atomic Surge"] = "ClientSprites:Icon_SkillWarrior_Plasma_Pulse",
    ["Breaching Strikes"] = "Icon_SkillPhysical_UI_wr_clv",
    ["Emergency Reserves"] = "Icon_SkillWarrior_Emergency_Reserves",
    ["Whirlwind"] = "Icon_SkillPhysical_UI_wr_wrlwnd",
    ["Tremor"] = "ClientSprites:Icon_SkillWarrior_Tremor_Strike",
    ["Plasma Wall"] = "ClientSprites:Icon_SkillWarrior_Plasma_Wall",
    ["Polarity Field"] = "ClientSprites:Icon_SkillWarrior_Polarity_Field",
    ["Augmented Blade"] = "Icon_SkillMisc_UI_m_amplfydmg",
    ["Expulsion"] = "ClientSprites:Icon_SkillWarrior_Explusion",
    ["Tether Bolt"] = "ClientSprites:Icon_SkillWarrior_Tether_Anchor",
    ["Power"] = "Icon_SkillPhysical_UI_wr_fume",
    ["Power Link"] = "ClientSprites:Icon_SkillWarrior_Power_Link",
    ["Jolt"] = "Icon_SkillWarrior_Cannon_Volley",
    ["Sentinel"] = "ClientSprites:Icon_SkillMisc_UI_espr_tlkntcshld",
    ["Defense Grid"] = "Icon_SkillWarrior_Defense_Grid",
    ["Savage Strikes"] = "Icon_SkillPhysical_UI_wr_cntrsrk",
    ["Shield Burst"] = "ClientSprites:Icon_SkillWarrior_Shield_Burst",
    ["Smackdown"] = "Icon_SkillPhysical_UI_wr_slap",
    ["Rampage"] = "Icon_SkillMisc_UI_wr_offgrp",
    ["Kick"] = "Icon_SkillPhysical_UI_wr_punt",
    ["Bum Rush"] = "Icon_SkillNature_UI_srcr_wndwlk",
    ["Ripsaw"] = "Icon_SkillPhysical_UI_wr_saw",

--Engineer
    ["Energy Auger"] = "Icon_SkillEngineer_Energy_Trail",
    ["Urgent Withdrawal"] = "ClientSprites:Icon_SkillEngineer_Urgent_Withdrawal",
    ["Particle Ejector"] = "Icon_SkillEngineer_Particule_Ejector",
    ["Unstable Anomaly"] = "Icon_SkillEngineer_Anomaly_Launcher",
    ["Bolt Caster"] = "Icon_SkillEngineer_Bolt_Caster",
    ["Target Acquisition"] = "ClientSprites:Icon_SkillEngineer_Target_Acquistion",
    ["Hyper Wave"] = "Icon_SkillEngineer_Hyper_Wave",
    ["Electrocute"] = "Icon_SkillEngineer_Electrocute",
    ["Bio Shell"] = "Icon_SkillEngineer_BioShell",
    ["Flak Cannon"] = "Icon_SkillEngineer_Flak_Cannon",
    ["Ricochet"] = "ClientSprites:Icon_SkillEngineer_Ricochet",
    ["Zap"] = "ClientSprites:Icon_SkillEngineer_Zap",
    ["Quick Burst"] = "ClientSprites:Icon_SkillEngineer_Quick_Burst",
    ["Unsteady Miasma"] = "Icon_SkillEngineer_Give_Em_Gas",
    ["Mortar Strike"] = "Icon_SkillEngineer_Mortar_Strike",
    ["Code Red"] = "Icon_SkillEngineer_Code_Red",
    ["Volatile Injection"] = "ClientSprites:Icon_SkillEngineer_Volatile_Injection",
    ["Disruptive Module"] = "Icon_SkillEngineer_Disruptive_Mod",
    ["Feedback"] = "Icon_SkillEngineer_Feedback",
    ["Pulse Blast"] = "ClientSprites:Icon_SkillEngineer_Pulse_Blast",
    ["Recursive Matrix"] = "ClientSprites:Icon_SkillEngineer_Recursive_Matrix",
    ["Shock Pulse"] = "ClientSprites:Icon_SkillEngineer_Shock_Pulse",
    ["Shatter Impairment"] = "ClientSprites:Icon_SkillEngineer_Shatter_Impairment",
    ["Repairbot"] = "ClientSprites:Icon_SkillEngineer_Repair_Bot",
    ["Artillerybot"] = "Icon_SkillEngineer_Artillery_Bot",
    ["Diminisherbot"] = "Icon_SkillEngineer_Diminisher_Bot",
    ["Bruiserbot"] = "Icon_SkillEngineer_Bruiser_Bot",
    ["Personal Defense Unit"] = "ClientSprites:Icon_SkillEngineer_Personal_Defense_Unit",
	
--Stalker
    ["Shred"] = "Icon_SkillShadow_UI_sm_rip",
    ["Impale"] = "Icon_SkillShadow_UI_stlkr_tacticalthrust",
    ["Stagger"] = "Icon_SkillShadow_UI_stlkr_staggeringthrust",
    ["Analyze Weakness"] = "ClientSprites:Icon_SkillStalker_Analyze_Weakness",
    ["Cripple"] = "ClientSprites:Icon_SkillStalker_Cripple",
    ["Neutralize"] = "ClientSprites:Icon_SkillStalker_Neutralize",
    ["Ruin"] = "Icon_SkillStalker_overload",
    ["Tether Mine"] = "Icon_SkillStalker_Tether_Mine",
    ["Phlebotomize"] = "ClientSprites:Icon_SkillStalker_Phlebotomizing_Missile",
    ["Tactical Retreat"] = "Icon_SkillShadow_UI_stlkr_emergencystealth",
    ["Clone"] = "Icon_SkillStalker_Clone",
    ["Whiplash"] = "ClientSprites:Icon_SkillStalker_Whiplash",
    ["Nano Field"] = "ClientSprites:Icon_SkillStalker_Nano_Field",
    ["False Retreat"] = "Icon_SkillShadow_UI_stlkr_shadowdash",
    ["Razor Disk"] = "ClientSprites:Icon_SkillStalker_Razor_Disk",
    ["Nano Virus"] = "ClientSprites:Icon_SkillStalker_Nano_Virus",
    ["Frenzy"] = "Icon_SkillShadow_UI_stlkr_shredarmor",
    ["Reaver"] = "ClientSprites:Icon_SkillStalker_Reaver",
    ["Collapse"] = "Icon_SkillShadow_UI_stlkr_ragingslash",
    ["Bloodthirst"] = "ClientSprites:Icon_SkillStalker_Blood_Thirst",
    ["Razor Storm"] = "Icon_SkillShadow_UI_SM_envelop",
    ["Stim Drone"] = "ClientSprites:Icon_SkillStalker_Augment_Drone",
    ["Nano Dart"] = "ClientSprites:Icon_SkillStalker_Nano_Dart",
    ["Amplification Spike"] = "ClientSprites:Icon_SkillStalker_Amplifide_Spike",
    ["Concussive Kicks"] = "ClientSprites:Icon_SkillStalker_Concussive_Kicks",
    ["Pounce"] = "Icon_SkillShadow_UI_stlkr_pounce",
    ["Decimate"] = "ClientSprites:Icon_SkillStalker_Destructive_Sweep",
    ["Steadfast"] = "Icon_SkillStalker_Steadfast",
    ["Punish"] = "ClientSprites:Icon_SkillStalker_Punish",
    ["Preparation"] = "ClientSprites:Icon_SkillStalker_Preparation",

--Medic
    ["Gamma Rays"] = "ClientSprites:Icon_SkillMedic_gammarays",
    ["Triage"] = "ClientSprites:Icon_SkillMedic_MedicIconTreatWounds",
    ["Shield Surge"] = "ClientSprites:Icon_SkillMedic_sheildsurge",
    ["Restrictor"] = "ClientSprites:Icon_SkillMedic_restraintgrind",
    ["Rejuvenator"] = "ClientSprites:Icon_SkillMedic_repairstation",
    ["Mending Probes"] = "ClientSprites:Icon_SkillMedic_repairprobes1",
    ["Barrier"] = "ClientSprites:Icon_SkillMedic_Barrier",
    ["Crisis Wave"] = "ClientSprites:Icon_SkillMedic_fieldsurgeon",
    ["Field Probes"] = "ClientSprites:Icon_SkillMedic_fieldprobes1",
    ["Protection Probes"] = "ClientSprites:Icon_SkillMedic_protectionprobe1",
    ["Antidote"] = "ClientSprites:Icon_SkillMedic_suture",
    ["Devastator Probes"] = "ClientSprites:Icon_SkillMedic_devastatorprobes1",
    ["Atomize"] = "ClientSprites:Icon_SkillMedic_atomize",
    ["Empowering Probes"] = "ClientSprites:Icon_SkillMedic_empowerprobe",
    ["Dematerialize"] = "Icon_SkillEnergy_UI_srcr_shckcntrp",
    ["Urgency"] = "ClientSprites:Icon_SkillMedic_urgency",
    ["Calm"] = "ClientSprites:Icon_SkillMedic_Calm",
    ["Fissure"] = "ClientSprites:Icon_SkillMedic_Fissure",
    ["Quantum Cascade"] = "ClientSprites:Icon_SkillMedic_quantumcascade",
    ["Flash"] = "ClientSprites:Icon_SkillMedic_healingnova",
    ["Extricate"] = "ClientSprites:Icon_SkillMedic_extricate",
    ["Magnetic Lockdown"] = "ClientSprites:Icon_SkillMedic_magneticlockdown",
    ["Paralytic Surge"] = "ClientSprites:Icon_SkillMedic_paralyticsurge",
    ["Recharge"] = "ClientSprites:Icon_SkillMedic_recharge",
    ["Annihilation"] = "ClientSprites:Icon_SkillMedic_annihilation",
    ["Nullifier"] = "ClientSprites:Icon_SkillMedic_nullifyfield",
    ["Discharge"] = "ClientSprites:Icon_SkillMedic_discharge",
    ["Emission"] = "ClientSprites:Icon_SkillMedic_Emission",
    ["Collider"] = "ClientSprites:Icon_SkillMedic_particlecollider",
    ["Dual Shock"] = "ClientSprites:Icon_SkillMedic_paddleshock",


--Esper
    ["Mind Burst"] = "Icon_SkillMind_UI_espr_mndstb",
    ["Crush"] = "Icon_SkillMind_UI_espr_crush",
    ["Telekinetic Storm"] = "Icon_SkillEnergy_UI_srcr_elctrcshck",
    ["Restraint"] = "Icon_SkillMisc_UI_misc_vlnrbl",
    ["Meditate"] = "Icon_SkillMind_UI_espr_mdt",
    ["Shockwave"] = "Icon_SkillMind_UI_espr_shockwave",
    ["Mind Over Body"] = "ClientSprites:Icon_SkillEsper_Mind_Over_Body",
    ["Bolster"] = "Icon_SkillMind_UI_espr_bolster",
    ["Phantasmal Armor"] = "Icon_SkillMind_UI_espr_phnstmlarmor",
    ["Telekinetic Strike"] = "Icon_SkillMisc_UI_srcr_enhncesns",
    ["Reap"] = "Icon_SkillShadow_UI_SM_rprrsh",
    ["Haunt"] = "Icon_SkillMind_UI_espr_phbmve",
    ["Blade Dance"] = "ClientSprites:Icon_SkillEsper_Blade_Dance",
    ["Fade Out"] = "ClientSprites:Icon_SkillEsper_Fade_Out",
    ["Soothe"] = "ClientSprites:Icon_SkillEsper_Soothe",
    ["Reverie"] = "Icon_SkillMisc_UI_m_flsh",
    ["Mental Boon"] = "ClientSprites:Icon_SkillEsper_Mental_Boon",
    ["Catharsis"] = "ClientSprites:Icon_SkillEsper_Awaken_Alt",
    ["Fixation"] = "Icon_SkillShadow_UI_SM_eye",
    ["Mending Banner"] = "Icon_SkillMind_UI_espr_moverb",
    ["Incapacitate"] = "ClientSprites:Icon_SkillEsper_Sudden_Quiet",
    ["Mirage"] = "ClientSprites:Icon_SkillEsper_Mirage",
    ["Warden"] = "ClientSprites:Icon_SkillEsper_Warden",
    ["Psychic Frenzy"] = "ClientSprites:Icon_SkillEsper_Spectral_Frenzy",
    ["Geist"] = "ClientSprites:Icon_SkillEsper_Geist",
    ["Spectral Swarm"] = "Icon_SkillShadow_UI_SM_undrwrlddrms",
    ["Projected Spirit"] = "ClientSprites:Icon_SkillEsper_Projected_Spirit",
    ["Pyrokinetic Flame"] = "ClientSprites:Icon_SkillEsper_Dislodge_Essence",	


--Spellslinger
    ["Spatial Shift"] = "Icon_SkillSpellslinger_spatial_shift",
    ["Flash Freeze"] = "Icon_SkillSpellslinger_frozen_bolt",
    ["Gate"] = "Icon_SkillSpellslinger_gate",
    ["Charged Shot"] = "Icon_SkillSpellslinger_charged_shot",
    ["Ignite"] = "Icon_SkillSpellslinger_ignite",
    ["Wild Barrage"] = "Icon_SkillSpellslinger_wild_barrage",
    ["Phase Shift"] = "Icon_SkillSpellslinger_phase_shift",
    ["Rapid Fire"] = "Icon_SkillSpellslinger_rapid_fire",
    ["Astral Infusion"] = "Icon_SkillSpellslinger_arcane_infusion",
    ["True Shot"] = "Icon_SkillSpellslinger_Trueshot",
    ["Runic Healing"] = "Icon_SkillSpellslinger_runic_healing",
    ["Purify"] = "Icon_SkillSpellslinger_purify",
    ["Assassinate"] = "Icon_SkillSpellslinger_assassinate",
    ["Affinity"] = "Icon_SkillSpellslinger_affinity",
    ["Dual Fire"] = "Icon_SkillSpellslinger_dual_fire",
    ["Runes of Protection"] = "Icon_SkillSpellslinger_distortion",
    ["Healing Torrent"] = "Icon_SkillSpellslinger_healing_torrent",
    ["Healing Salve"] = "Icon_SkillSpellslinger_healing_salve",
    ["Vitality Burst"] = "Icon_SkillSpellslinger_vitality_burst",
    ["Voidspring"] = "Icon_SkillSpellslinger_call_the_void",
    ["Gather Focus"] = "Icon_SkillSpellslinger_gather_mana",
    ["Regenerative Pulse"] = "Icon_SkillSpellslinger_regenerative_pulse",
    ["Sustain"] = "Icon_SkillSpellslinger_sustain",
    ["Quick Draw"] = "Icon_SkillSpellslinger_mobile_fire",
    ["Arcane Missiles"] = "Icon_SkillSpellslinger_magic_missile",
    ["Chill"] = "Icon_SkillSpellslinger_cone_of_frost",
    ["Arcane Shock"] = "Icon_SkillSpellslinger_arcane_shock",
    ["Flame Burst"] = "Icon_SkillSpellslinger_flame_burst",
    ["Void Pact"] = "Icon_SkillSpellslinger_void_pact",
    ["Void Slip"] = "Icon_SkillSpellslinger_void_slip",

--Soldier
    ["Combat Supply Drop"] = "Icon_ItemMisc_Crate_of_Cogs",
    ["Back into the Fray"] = "ClientSprites:Icon_Modifier_health_max_001",
    ["Bail Out!"] = "ClientSprites:Icon_ItemArmorShield_shield_0001",
	
--Explorer
    ["Explorer&apos;s Safe Fall"] = "Icon_SkillMisc_Explorer_safefail",
    ["Translocate Beacon"] = "Icon_SkillMisc_Explorer_teleportbeaconplacement",
    ["Air Brakes"] = "Icon_ItemMisc_UI_Item_Leaf",

--Scientist

--Settler
    ["Settler&apos;s Campfire"] = "Icon_SkillFire_UI_ss_srngblst",
	["Summon: Vendbot"] = "Icon_ItemMisc_bag_0004",
    ["Summon: Mail Box"] = "IconSprites:Icon_ItemMisc_letter_0004",
    ["Summon: Crafting Station"] = "ClientSprites:Icon_TutorialMedium_UI_Tradeskill_Gen_Crafting_Station",
	
--Mounts
    ["Strain Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Strain",
    ["Alien Velocirex Mount"] = "ClientSprites:Icon_ItemMount_Cassian_Human_Mount",
    ["Marauder Orbitron Mount"] = "ClientSprites:Icon_ItemMount_Chua_Mount",
    ["Retroblade  Mount"] = "ClientSprites:Icon_ItemMount_Mechari_Mount",
    ["Hot Rod Uniblade Mount"] = "ClientSprites:Icon_ItemMount_Mechari_Mount",
    ["Savage Warpig Mount"] = "ClientSprites:Icon_ItemMount_Draken_Mount",
    ["Luminous Equivar Mount"] = "ClientSprites:Icon_ItemMount_Exile_Human_Mount",
    ["Dreg Trask Mount"] = "ClientSprites:Icon_ItemMount_Mordesh_Mount",
    ["War Woolie Mount"] = "ClientSprites:Icon_ItemMount_Aurin_Mount",
    ["Rally Grinder Mount"] = "ClientSprites:Icon_ItemMount_Granok_Mount",
	
	
	
	["Velocirex Mount"] = "ClientSprites:Icon_ItemMount_Cassian_Human_Mount",
    ["Woolie Mount"] = "ClientSprites:Icon_ItemMount_Aurin_Mount",
    ["Uncustomizable Hoverboard Mount"] = "ClientSprites:Icon_ItemMount_Hoverboard",
    ["Plasmatic Hyperboard Mount"] = "IconSprites:Icon_ItemMount_Hoverboard_Eldan",
    ["Spike Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Fang",
    ["The Beast Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Berserker",
    ["Go-Go Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_GoGo",
    ["Hellion Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_HotRod",
    ["Bulldog Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Hound",
    ["Manta Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Manta",
    ["Vortex Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Ringer",
    ["Rosie Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Rosie",
    ["Cyclone Hoverboard"] = "IconSprites:Icon_ItemMount_Hoverboard_Turbine",
    ["Uniblade Mount"] = "ClientSprites:Icon_ItemMount_Mechari_Mount",
    ["Orbitron Mount"] = "ClientSprites:Icon_ItemMount_Chua_Mount",
    ["Flux Hoverboard Mount"] = "ClientSprites:Icon_ItemMount_Hoverboard",
    ["Equivar Mount"] = "ClientSprites:Icon_ItemMount_Exile_Human_Mount",
    ["Grinder Mount"] = "ClientSprites:Icon_ItemMount_Granok_Mount",
    ["Trask Mount"] = "ClientSprites:Icon_ItemMount_Mordesh_Mount",
    ["Warpig Mount"] = "ClientSprites:Icon_ItemMount_Draken_Mount"
}

if _G["PUIDefaults"] == nil then
	_G["PUIDefaults"] = { }
end
_G["PUIDefaults"]["Castbar"] = Defaults
