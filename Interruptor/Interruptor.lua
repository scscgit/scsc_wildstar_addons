-----------------------------------------------------------------------------------------------
-- Client Lua Script for Interruptor
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Unit"
require "GameLib"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- Interruptor Module Definition
-----------------------------------------------------------------------------------------------
local Interruptor = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("Interruptor", true)
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local kstrDefaultProfile = "Carbinish"

local tIconSprites = {
"ClientSprites:Icon_SkillMisc_UI_misc_knkdwn","ClientSprites:Icon_SkillMisc_UI_ss_sglfire","ClientSprites:Icon_SkillMisc_UI_ss_sglrcvry","ClientSprites:Icon_SkillMisc_UI_ss_sglpain","ClientSprites:Icon_SkillMind_UI_espr_mndstb","ClientSprites:Icon_SkillMind_UI_espr_phnstmlarmor","ClientSprites:Icon_SkillPhysical_UI_wr_rcklsswngs","ClientSprites:Icon_SkillEngineer_Anomaly_Launcher","ClientSprites:Icon_SkillEngineer_Electrocute","ClientSprites:Icon_SkillSpellslinger_cone_of_frost","ClientSprites:Icon_SkillMedic_paralyticsurge","ClientSprites:Icon_SkillWarrior_Polarity_Field","ClientSprites:Icon_SkillMedic_magneticlockdown",
"ClientSprites:Icon_SkillStalker_Stance_Antagonistic","ClientSprites:Icon_SkillMisc_UI_m_enrgypls","ClientSprites:Icon_SkillSpellslinger_Trueshot","ClientSprites:Icon_SkillMisc_UI_ss_infusefire","ClientSprites:Icon_SkillSpellslinger_arcane_infusion","ClientSprites:Icon_SkillSpellslinger_power_torrent","ClientSprites:Icon_SkillShadow_UI_stlkr_stealth","ClientSprites:Icon_SkillMisc_UI_misc_vlnrbl","ClientSprites:Icon_SkillMedic_gammarays","ClientSprites:Icon_SkillMedic_MedicIconTreatWounds","ClientSprites:Icon_SkillMedic_sheildsurge","ClientSprites:Icon_SkillWarrior_Unstoppable_Force",
"ClientSprites:Icon_SkillMisc_UI_ss_infuseice","ClientSprites:Icon_SkillEsper_Mind_Over_Body","ClientSprites:Icon_SkillMisc_UI_srcr_frecho","ClientSprites:Icon_SkillShadow_UI_stlkr_pounce","ClientSprites:Icon_SkillMisc_UI_srcr_coldecho","ClientSprites:Icon_SkillSpellslinger_flame_burst","ClientSprites:Icon_SkillShadow_UI_SM_envelop","ClientSprites:Icon_SkillWarrior_Plasma_Blast","ClientSprites:Icon_SkillWarrior_Plasma_Pulse","ClientSprites:Icon_SkillEngineer_BioShell","ClientSprites:Icon_SkillMisc_UI_srcr_elctrcecho","ClientSprites:Icon_SkillFire_UI_srcr_frblt","ClientSprites:Icon_SkillEngineer_Target_Acquistion",
"ClientSprites:Icon_SkillEngineer_Shock_Wave","ClientSprites:Icon_SkillEsper_Awaken","ClientSprites:Icon_SkillEsper_Blade_Dance","ClientSprites:Icon_SkillEsper_Fade_Out","ClientSprites:Icon_SkillEsper_Soothe","ClientSprites:Icon_SkillEsper_Mental_Boon","ClientSprites:Icon_SkillMedic_recharge","ClientSprites:Icon_SkillEsper_Awaken_Alt","ClientSprites:Icon_SkillEnergy_UI_ss_offblnblst","ClientSprites:Icon_SkillEsper_Sudden_Quiet","ClientSprites:Icon_SkillEsper_Mirage","ClientSprites:Icon_SkillEsper_Warden","ClientSprites:Icon_SkillEnergy_UI_ss_gate","ClientSprites:Icon_SkillSpellslinger_healing_salve",
"ClientSprites:Icon_SkillEngineer_Recursive_Matrix","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Attack","ClientSprites:Icon_SkillEngineer_Mortar_Strike","ClientSprites:Icon_SkillSpellslinger_void_pact","ClientSprites:Icon_SkillEsper_Soothe_Alt","ClientSprites:Icon_SkillStalker_Nano_Dart","ClientSprites:Icon_SkillMisc_UI_m_flsh","ClientSprites:Icon_SkillEngineer_Urgent_Withdrawal","ClientSprites:Icon_SkillEngineer_Zap","ClientSprites:Icon_SkillWarrior_Explusion","ClientSprites:Icon_SkillMind_UI_espr_phbmve","ClientSprites:Icon_SkillWarrior_Juggernaut","ClientSprites:Icon_SkillStalker_Amplifide_Spike",
"ClientSprites:Icon_SkillWarrior_Plasma_Shield","ClientSprites:Icon_SkillMedic_particlecollider","ClientSprites:Icon_SkillPhysical_UI_wr_smsh","ClientSprites:Icon_SkillEsper_Geist","ClientSprites:Icon_SkillEngineer_Pet_Ability_Shield_Restore","ClientSprites:Icon_SkillPhysical_DeathWarrant","ClientSprites:Icon_SkillEsper_Spectral_Frenzy","ClientSprites:Icon_SkillMind_UI_espr_rpls","ClientSprites:Icon_SkillStalker_Whiplash","ClientSprites:Icon_SkillSpellslinger_magic_missile","ClientSprites:Icon_SkillWarrior_Tremor_Strike","ClientSprites:Icon_SkillEsper_Projected_Spirit","ClientSprites:Icon_SkillShadow_UI_SM_mkrsmrk",
"ClientSprites:Icon_SkillEngineer_Hyper_Wave","ClientSprites:Icon_SkillEngineer_Flak_Cannon","ClientSprites:Icon_SkillStalker_overload","ClientSprites:Icon_SkillPhysical_UI_wr_stall","ClientSprites:Icon_SkillEngineer_Bolt_Caster","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Stay","ClientSprites:Icon_SkillSpellslinger_runic_healing","ClientSprites:Icon_SkillMedic_fieldsurgeon","ClientSprites:Icon_SkillEsper_Dislodge_Essence","ClientSprites:Icon_SkillMedic_fieldprobes1","ClientSprites:Icon_SkillMedic_empowerprobe","ClientSprites:Icon_SkillEngineer_Pulse_Blast","ClientSprites:Icon_SkillMedic_restraintgrind",
"ClientSprites:Icon_SkillPetCommand_Combat_Pet_Despawn","ClientSprites:Icon_SkillSpellslinger_regenerative_pulse","ClientSprites:Icon_SkillWarrior_Plasma_Wall","ClientSprites:Icon_SkillStalker_Analyze_Weakness","ClientSprites:Icon_SkillStalker_Cripple","ClientSprites:Icon_SkillStalker_Neutralize","ClientSprites:Icon_SkillStalker_Phlebotomizing_Missile","ClientSprites:Icon_SkillStalker_Nano_Field","ClientSprites:Icon_SkillStalker_Razor_Disk","ClientSprites:Icon_SkillStalker_Nano_Virus","ClientSprites:Icon_SkillStalker_Reaver","ClientSprites:Icon_SkillStalker_Combat_Stealth","ClientSprites:Icon_SkillStalker_Blood_Thirst",
"ClientSprites:Icon_SkillEngineer_Feedback","ClientSprites:Icon_SkillStalker_Augment_Drone","ClientSprites:Icon_SkillStalker_Concussive_Kicks","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Go_To_Location","ClientSprites:Icon_SkillSpellslinger_healing_torrent","ClientSprites:Icon_SkillFire_UI_srcr_frybrrg","ClientSprites:Icon_SkillMisc_UI_srcr_airecho","ClientSprites:Icon_SkillMisc_UI_m_slvo","ClientSprites:Icon_SkillMedic_repairstation","ClientSprites:Icon_SkillPhysical_UI_wr_whip","ClientSprites:Icon_SkillMisc_UI_misc_root","ClientSprites:Icon_SkillWarrior_Cannon_Volley_Alt",
"ClientSprites:Icon_SkillEngineer_Disruptive_Mod","ClientSprites:Icon_SkillMedic_discharge","ClientSprites:Icon_SkillMedic_repairprobes1","ClientSprites:Icon_SkillMedic_Barrier","ClientSprites:Icon_SkillMind_UI_espr_slp","ClientSprites:Icon_SkillMedic_protectionprobe1","ClientSprites:Icon_SkillMedic_suture","ClientSprites:Icon_SkillEngineer_Ricochet","ClientSprites:Icon_SkillMedic_devastatorprobes1","ClientSprites:Icon_SkillEngineer_Quick_Burst","ClientSprites:Icon_SkillMedic_atomize","ClientSprites:Icon_SkillEngineer_Survival_Mode","ClientSprites:Icon_SkillMedic_urgency","ClientSprites:Icon_SkillMedic_energize",
"ClientSprites:Icon_SkillMedic_Calm","ClientSprites:Icon_SkillMedic_annihilation","ClientSprites:Icon_SkillEnergy_UI_srcr_shckcntrp","ClientSprites:Icon_SkillShadow_UI_SM_undrwrlddrms","ClientSprites:Icon_SkillEngineer_Volatile_Injection","ClientSprites:Icon_SkillMedic_Fissure","ClientSprites:Icon_SkillMedic_quantumcascade","ClientSprites:Icon_SkillMisc_UI_ss_crpplngblst","ClientSprites:Icon_SkillMedic_healingnova","ClientSprites:Icon_SkillMind_UI_espr_mdlsh","ClientSprites:Icon_SkillMedic_extricate","ClientSprites:Icon_SkillMind_UI_espr_cnfs","ClientSprites:Icon_SkillMedic_fieldprobes2","ClientSprites:Icon_SkillEngineer_Shock_Pulse",
"ClientSprites:Icon_SkillMind_UI_espr_bldstrm","ClientSprites:Icon_SkillEngineer_Shatter_Impairment","ClientSprites:Icon_SkillEngineer_Repair_Bot","ClientSprites:Icon_SkillShadow_UI_stlkr_onslaught","ClientSprites:Icon_SkillMind_UI_espr_crush","ClientSprites:Icon_SkillShadow_UI_SM_crrptngprsnc","ClientSprites:Icon_SkillFire_UI_srcr_twncst","ClientSprites:Icon_SkillMind_UI_espr_rsrgnc","ClientSprites:Icon_SkillShadow_UI_SM_rprrsh","ClientSprites:Icon_SkillMind_UI_espr_mndlsh","ClientSprites:Icon_SkillMisc_UI_m_trnsfsenrgy","ClientSprites:Icon_SkillMind_UI_espr_bolster",
"ClientSprites:Icon_SkillShadow_UI_stlkr_shredarmor","ClientSprites:Icon_SkillMind_UI_espr_mdt","ClientSprites:Icon_SkillEnergy_UI_ss_spacialshift","ClientSprites:Icon_SkillEsper_Illusionary_Blades","ClientSprites:Icon_SkillStalker_Tether_Mine","ClientSprites:Icon_SkillSpellslinger_arcane_shock","ClientSprites:Icon_SkillWarrior_Detonate","ClientSprites:Icon_SkillEngineer_Thresher","ClientSprites:Icon_SkillShadow_UI_stlkr_shadowdash","ClientSprites:Icon_SkillMisc_UI_ss_srsht","ClientSprites:Icon_SkillPhysical_UI_wr_leap","ClientSprites:Icon_SkillEngineer_Personal_Defense_Unit","ClientSprites:Icon_SkillEnergy_UI_srcr_getouttadodge",
"ClientSprites:Icon_SkillShadow_UI_SM_sacrstrk","ClientSprites:Icon_SkillEnergy_UI_srcr_thebigguns","ClientSprites:Icon_SkillFire_UI_ss_srngblst","ClientSprites:Icon_SkillPhysical_UI_wr_slap","ClientSprites:Icon_SkillMind_UI_espr_moverb","ClientSprites:Icon_SkillShadow_UI_SM_eye","ClientSprites:Icon_SkillStalker_Stance_Offensive","ClientSprites:Icon_SkillStalker_Stance_Defensive","ClientSprites:Icon_SkillPhysical_UI_wr_offblnc","ClientSprites:Icon_SkillEnergy_UI_srcr_surgeengine","ClientSprites:Icon_SkillMisc_UI_ss_gate","ClientSprites:Icon_SkillPhysical_UI_wr_grenade",
"ClientSprites:Icon_SkillMisc_UI_ss_sglprot","ClientSprites:Icon_SkillEnergy_UI_srcr_elctrcshck","ClientSprites:Icon_SkillPhysical_UI_wr_wrlwnd","ClientSprites:Icon_SkillPhysical_ThickSkull","ClientSprites:Icon_SkillPhysical_UI_wr_vrtx","ClientSprites:Icon_SkillMisc_UI_ss_knckdwnsgl","ClientSprites:Icon_SkillMisc_UI_ss_infuselng","ClientSprites:Icon_SkillPhysical_UI_wr_fume","ClientSprites:Icon_SkillMisc_UI_ss_clldshtlg","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Passive","ClientSprites:Icon_SkillEnergy_UI_ss_plsmasht","ClientSprites:Icon_SkillMisc_UI_ss_recharge","ClientSprites:Icon_SkillPhysical_UI_wr_bludgeon",
"ClientSprites:Icon_SkillShadow_UI_stlkr_partialcamo","ClientSprites:Icon_SkillEnergy_UI_ss_plasmabrge","ClientSprites:Icon_SkillMisc_UI_ss_sglstop","ClientSprites:Icon_SkillShadow_UI_SM_ghstshft","ClientSprites:Icon_SkillEngineer_Code_Red","ClientSprites:Icon_SkillMisc_UI_srcr_spatialdistortion","ClientSprites:Icon_SkillMind_UI_espr_shockwave","ClientSprites:Icon_SkillShadow_UI_SM_cnsmgprsnc","ClientSprites:Icon_SkillMisc_UI_srcr_enhncesns","ClientSprites:Icon_SkillMisc_UI_m_enrgybrst","ClientSprites:Icon_SkillMedic_paddleshock","ClientSprites:Icon_SkillSpellslinger_phase_shift","ClientSprites:Icon_SkillStalker_Destructive_Sweep",
"ClientSprites:Icon_SkillShadow_UI_stlkr_emergencystealth","ClientSprites:Icon_SkillPhysical_Vulnerable","ClientSprites:Icon_SkillStalker_Punish","ClientSprites:Icon_SkillMisc_UI_m_dschrgshld","ClientSprites:Icon_SkillWarrior_Tether_Anchor","ClientSprites:Icon_SkillEngineer_Give_Em_Gas","ClientSprites:Icon_SkillStalker_Preparation","ClientSprites:Icon_SkillWarrior_Plasma_Pulse_Alt","ClientSprites:Icon_SkillMind_UI_espr_fltr","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Assist","ClientSprites:Icon_SkillPhysical_UI_wr_lng","ClientSprites:Icon_SkillSpellslinger_vitality_burst",
"ClientSprites:Icon_SkillShadow_UI_stlkr_concealedslash","ClientSprites:Icon_SkillMisc_UI_m_jolt","ClientSprites:Icon_SkillShadow_UI_SM_bldbnd","ClientSprites:Icon_SkillWarrior_Power_Link","ClientSprites:Icon_SkillShadow_UI_stlkr_ragingslash","ClientSprites:Icon_SkillShadow_UI_SM_maul","ClientSprites:Icon_SkillWarrior_Shield_Burst","ClientSprites:Icon_SkillShadow_UI_SM_rip","ClientSprites:Icon_SkillEsper_Catharsis_Alt","ClientSprites:Icon_SkillPhysical_FountainOfBlood","ClientSprites:Icon_SkillShadow_UI_SM_reprisal","ClientSprites:Icon_SkillMedic_Emission","ClientSprites:Icon_SkillMedic_nullifyfield",
"ClientSprites:Icon_SkillPhysical_UI_wr_saw","ClientSprites:Icon_SkillMisc_Scientist_CreatePortal_HomeCity_Thayd","ClientSprites:Icon_SkillMisc_Scientist_CreatePortal_HomeCity_Illium","ClientSprites:Icon_SkillPhysical_UI_wr_punt","ClientSprites:Icon_SkillWarrior_Guarded_Strikes","ClientSprites:Icon_SkillPetCommand_Combat_Pet_Aggressive","ClientSprites:Icon_SkillEngineer_Eradication_Mode","ClientSprites:Icon_SkillEsper_Catharsis","ClientSprites:Icon_SkillEsper_Replicate","ClientSprites:Icon_SkillSpellslinger_charged_shot","ClientSprites:Icon_SkillMedic_repairprobes2","ClientSprites:Icon_SkillWarrior_Cannon_Volley",
"ClientSprites:Icon_SkillSpellslinger_frozen_bolt","ClientSprites:Icon_SkillMisc_UI_m_chnltng","ClientSprites:Icon_SkillEsper_Catharsis_Alt_Yellow","ClientSprites:Icon_SkillSpellslinger_aura","ClientSprites:Icon_SkillEsper_Catharsis_Alt_Blue","ClientSprites:Icon_SkillEsper_Catharsis_Alt_Red","ClientSprites:Icon_SkillEsper_Catharsis_Alt_Orange","ClientSprites:Icon_SkillSpellslinger_call_the_void","IconSprites:Icon_SkillIce_UI_srcr_avlnch","IconSprites:Icon_SkillIce_UI_srcr_iceshrds","IconSprites:Icon_SkillNature_UI_srcr_dstdvl","IconSprites:Icon_SkillNature_UI_srcr_wndwlk"}
 
local tRandomMap ={ 98,  6, 85,150, 36, 23,112,164,135,207,169,  5, 26, 64,165,219,
       61, 20, 68, 89,130, 63, 52,102, 24,229,132,245, 80,216,195,115,
       90,168,156,203,177,120,  2,190,188,  7,100,185,174,243,162, 10,
      237, 18,253,225,  8,208,172,244,255,126,101, 79,145,235,228,121,
      123,251, 67,250,161,  0,107, 97,241,111,181, 82,249, 33, 69, 55,
       59,153, 29,  9,213,167, 84, 93, 30, 46, 94, 75,151,114, 73,222,
      197, 96,210, 45, 16,227,248,202, 51,152,252,125, 81,206,215,186,
       39,158,178,187,131,136,  1, 49, 50, 17,141, 91, 47,129, 60, 99,
      154, 35, 86,171,105, 34, 38,200,147, 58, 77,118,173,246, 76,254,
      133,232,196,144,198,124, 53,  4,108, 74,223,234,134,230,157,139,
      189,205,199,128,176, 19,211,236,127,192,231, 70,233, 88,146, 44,
      183,201, 22, 83, 13,214,116,109,159, 32, 95,226,140,220, 57, 12,
      221, 31,209,182,143, 92,149,184,148, 62,113, 65, 37, 27,106,166,
        3, 14,204, 72, 21, 41, 56, 66, 28,193, 40,217, 25, 54,179,117,
      238, 87,240,155,180,170,242,212,191,163, 78,218,137,194,175,110,
       43,119,224, 71,122,142, 42,160,104, 48,247,103, 15, 11,138,239 }

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Loc = GeminiLocale:GetLocale("Interruptor", true)
local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

local function XMLHelper(tXML, strName, strPath, nX, nY)
table.insert(tXML, 
		{ -- Form
			__XmlNode="Sprite", Name=strName, Cycle="1",
			{
				__XmlNode="Frame", Texture= strPath,
				x0="0", x1="0", x2="0", x3="0", x4=nX.."", x5=nX.."",
				y0="0", y1="0", y2="0", y3="0", y4=nY.."", y5=nY.."",
				Stretchy="1", HotspotX="0", HotspotY="0", Duration="1.000",
				StartColor="white", EndColor="white",
			},
		} )
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function Interruptor:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
    -- initialize variables here
	--self.cookie = "new"

    return o
end
--]]


function Interruptor:OnInitialize()
	
	local tDefaultProfile

	for index, tProfile in pairs(self.tProfilesFile) do
		if tProfile.Name == kstrDefaultProfile then
			tDefaultProfile = tProfile
			break
		end
	end
	
	local tDefaults = {
		char = {
			tAnchorOffsets = {-106,-56,146,-32},
			tIAOffsets = {-1,10,1,22},
			--strTargetType = "Focus",
			--bNoAlt = false,
			bIcons = true,
			nDistributionValue = 0,
			bHideTCB = false,
			bHideFCB = false,
			bIALock = true,
			bIconBig = true,
			bIAOnCast = false,
			nIDMoOIcon = 2,
			tidxTargeting = {"MaxRank", "Focus", "Target"},
			tTargetingInfo = {MaxRank = {bInCombat = true, bFriendly = false, bPlayers = false, bEnabled = true}, Focus = {bInCombat = false, bFriendly = false, bPlayers = false, bEnabled = true}, Target = {bInCombat = false, bFriendly = true, bPlayers = true, bEnabled = true}}
		},
		profile = tDefaultProfile		
		,
		global = {
			tHighlights = {}
		}
	}
	
	self.tDefaultPositioning = {tAnchorOffsets = tDefaults.char.tAnchorOffsets, tIAOffsets = tDefaults.char.tIAOffsets}
	
	tDefaults.profile.strBasis = kstrDefaultProfile

	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, tDefaults, true)


	
	self.tPredefinedProfiles = {}
	self.nPredefinedProfiles = 0
	for index, tProfile in pairs(self.tProfilesFile) do
		self.db.profiles[tProfile.Name] = tProfile
		self.tPredefinedProfiles[tProfile.Name] = true
		self.nPredefinedProfiles = 	self.nPredefinedProfiles + 1
	end
	
	local tSpritesXML = {
		__XmlNode = "Sprites"
	}
	
	self.tBorderTextures = {}
	self.tBorderGapMultipliers = {}
	
	local tBorderSides = {TOP = {"XTop", "Thickness"},BOTTOM = {"XTop", "Thickness"},LEFT = {"Thickness", "YLeft"},RIGHT = {"Thickness", "YLeft"}, TOPLEFT = {"Thickness", "Thickness"}, TOPRIGHT = {"Thickness", "Thickness"}, BOTTOMLEFT = {"Thickness", "Thickness"}, BOTTOMRIGHT = {"Thickness", "Thickness"}} --#StylePatch Xtop, YLeft, Corners

	for index, tBorderSetup in pairs(self.tBorderFile) do
		self.tBorderTextures[tBorderSetup.Name] = {}
		for strSide, tIndices in pairs(tBorderSides) do
			XMLHelper(tSpritesXML, tBorderSetup.Name..strSide, "Interruptor\\Style\\BorderTextures\\"..tBorderSetup.Name.."\\"..strSide.."."..tBorderSetup.Ext, tBorderSetup[tIndices[1]],tBorderSetup[tIndices[2]])
			self.tBorderTextures[tBorderSetup.Name][strSide] = "IRSprites:"..tBorderSetup.Name..strSide
		end
		self.tBorderGapMultipliers[tBorderSetup.Name] = {RIGHT = tBorderSetup.RightGapMultiplier or 1, BOTTOM = tBorderSetup.BottomGapMultiplier or 1}
	end
	self.tRegularTextures = {}
	self.tNumberedTextures = {}
			
	for index, tRegularSetup in pairs(self.tRegularFile) do
		XMLHelper(tSpritesXML, tRegularSetup.Name, "Interruptor\\Style\\RegularTextures\\"..tRegularSetup.Name.."."..tRegularSetup.Ext, tRegularSetup.SizeX,tRegularSetup.SizeY,0,tRegularSetup.SizeX,0,tRegularSetup.SizeY)
		self.tRegularTextures[tRegularSetup.Name] = "IRSprites:"..tRegularSetup.Name
		table.insert(self.tNumberedTextures, tRegularSetup.Name)
	end
	

	for index, tCarbineSetup in pairs(self.tCarbineFile) do
		if tCarbineSetup.Type == "regular" then
			self.tRegularTextures[tCarbineSetup.Name] = tCarbineSetup.Texture
			table.insert(self.tNumberedTextures, 1,tCarbineSetup.Name)
		else
			self.tBorderTextures[tCarbineSetup.Name] = {}
			for strSide, strTexture in pairs(tCarbineSetup.Textures) do
				self.tBorderTextures[tCarbineSetup.Name][strSide] = strTexture
			end
			self.tBorderGapMultipliers[tCarbineSetup.Name] = {RIGHT = tCarbineSetup.RightGapMultiplier or 1, BOTTOM = tCarbineSetup.BottomGapMultiplier or 1}
		end
	end
	
				self.bTestValue= true

	local xmlSprites = XmlDoc.CreateFromTable(tSpritesXML)
	Apollo.LoadSprites(xmlSprites, "IRSprites")
	
	self.tBorderFile = nil
	self.tRegularFile = nil
	self.tCarbineFile = nil
	
	
	self.nIconOffset = 0
	self.nLastCCArmorMax = 0
	self.nLastCCArmorValue = 0
	self.tArmorFrames = {}
	self.fLastCastElapsed = 10000
	self.fLastVulnerable = 0
	self.bConfig = false
	self.strCCStatus = "interruptable"
	self.nOneBossRank = -1
	self.nSelfDestroyed = 0
	self.tTargetingFrames = {}
	--self.tCColors = {}

	--Apollo.LoadSprites("NewSprite.xml")
	--Apollo.LoadSprites("IRSprites.xml")
	self.xmlDoc = XmlDoc.CreateFromFile("Interruptor.xml")

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BaseForm", nil, self)
	self.wndConfig = Apollo.LoadForm(self.xmlDoc, "Config", nil, self)
	
	self.wndBarFrame = self.wndMain:FindChild("BarFrame")
	self.wndBar = self.wndBarFrame:FindChild("ProgressBar")
	self.wndDuration = self.wndBar:FindChild("Duration")

	self.wndIcon = self.wndBarFrame:FindChild("IconFrame")
	self.wndCastbarBC = self.wndBarFrame:FindChild("BorderClipper")
	self.wndIconBC = self.wndIcon:FindChild("BorderClipper")


	self.wndCCArmor = self.wndMain:FindChild("CastingContainer")
	self.wndIAContainer = self.wndCCArmor:FindChild("IAFrame:IAContainer")
	self.wndInterruptArmorBC = self.wndCCArmor:FindChild("IAFrame:BorderClipper")
	
	self.wndConfigGeneral = self.wndConfig:FindChild("GeneralTabContainer")
	self.wndConfigStyle = self.wndConfig:FindChild("StyleTabContainer")
	self.wndConfig:SetRadioSel("Tabs", 1)

	self.db.RegisterCallback(self, "OnDatabaseImport", "ImportHighlightList")

	Apollo.RegisterEventHandler("NextFrame","OnFrame", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnFocusUnitChanged", self)
	Apollo.RegisterEventHandler("CombatLogCCState", 						"OnCombatLogCCState", self)
	--Apollo.RegisterEventHandler("CombatLogDamage", 						"OnCombatLogDmg", self)
	Apollo.RegisterEventHandler("CombatLogInterrupted", 						"OnCombatLogInterrupted", self)
	--Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterLoaded", self)
	--Apollo.RegisterEventHandler("CombatLogModifyInterruptArmor", "OnArmorChange", self)
	--Apollo.RegisterEventHandler("ChangeWorld", 						"UpdatePlayerUnit", self)
	Apollo.RegisterSlashCommand("interruptor","OnConfigure", self)

	--self.fTime = 0 --test
	--self:SetupConfig()
	--self.timerTest = ApolloTimer.Create(0, false, "OnTest", self) --test
	--self.strTest = "Load"
	GeminiLocale:TranslateWindow(Loc, self.wndConfig)
	
--	self.strDocumentTest = self.strDocumentTest .. " success!"
--	self.wndTest = Apollo.LoadForm(self.xmlDoc, "NewBase", nil, self)
--	self.wndTesti = self.wndTest:FindChild("BorderContainer")

end

--function Interruptor:OnTest()
--self.strTest = self.strTest .. "-Timer"
--end
function Interruptor:ImportHighlightList(strCallback,db ,level,savedData, stopDefault)
	if level == GameLib.CodeEnumAddonSaveLevel.Character and savedData.tHighlights and (not self.db.global.bImported) then
		self.db.global.tHighlights = savedData.tHighlights
		--Print("restored highlights")
		self.db.global.bImported = true
	end
--	self.db.char[level] = savedData
end


function Interruptor:OnEnable()
	self.wndMain:SetAnchorOffsets(unpack(self.db.char.tAnchorOffsets))
	self.wndCCArmor:SetAnchorOffsets(unpack(self.db.char.tIAOffsets))
--[[	if self.tSaved.bMinimal then
		self.wndCCArmor:FindChild("BackgroundTexture"):SetSprite("")
		self.wndBarFrame:SetSprite("")
		self.wndIcon:SetSprite("")
		self.wndBar:SetEmptySprite("IRSprites:FullBlack") --do this?
		self.nIconXOffset = 12
	end--]]
	self.wndConfigGeneral:SetRadioSel("MoOIcon", self.db.char.nIDMoOIcon)
	--self.wndConfigGeneral:FindChild("CheckNoAlt"):SetCheck(self.db.char.bNoAlt)
	self.wndConfigGeneral:FindChild("CheckIcons"):SetCheck(self.db.char.bIcons)
	self.wndConfigGeneral:FindChild("Distribution"):SetText(self.db.char.nDistributionValue.."")
	self.wndConfigGeneral:FindChild("CheckHideTFrame"):SetCheck(self.db.char.bHideTCB)
	self.wndConfigGeneral:FindChild("CheckHideFFrame"):SetCheck(self.db.char.bHideFCB)
	self.wndConfigGeneral:FindChild("CheckLocked"):SetCheck(self.db.char.bIALock)
	self.wndConfigGeneral:FindChild("CheckIconScale"):SetCheck(self.db.char.bIconBig)
	self.wndConfigGeneral:FindChild("CheckIconScale"):Enable(self.db.char.bIALock)
	self.wndConfigGeneral:FindChild("CheckIAOnlyOnCast"):SetCheck(self.db.char.bIAOnCast)
	if self.db.char.bIAOnCast then
		self.wndCCArmor:Show(false, true)
	end
	--self.wndConfig:FindChild("CheckMinimal"):SetCheck(self.db.char.bMinimal)
	
	--for key, value in pairs(self.tSaved.tColors) do
		--self.tCColors[key] = CColor.new(unpack(value))
	--	self.wndConfig:FindChild(key):FindChild("ColorWindow"):SetBGColor(value)
	--end
	
	--targeting
	for idx, strTargetType in ipairs(self.db.char.tidxTargeting) do
		self.tTargetingFrames[strTargetType] = Apollo.LoadForm(self.xmlDoc, "TargetListItemForm", self.wndConfigGeneral:FindChild("TargetingContainer"), self)
		self.tTargetingFrames[strTargetType]:SetName(strTargetType)
		self.tTargetingFrames[strTargetType]:FindChild("Text"):SetText(Loc[strTargetType])--set text
		for strKey, bValue in pairs(self.db.char.tTargetingInfo[strTargetType]) do
			self.tTargetingFrames[strTargetType]:FindChild(strKey):SetCheck(bValue)
		end
		GeminiLocale:TranslateWindow(Loc, self.tTargetingFrames[strTargetType])
	end
	self.wndConfigGeneral:FindChild("TargetingContainer"):ArrangeChildrenVert()
	
	
	self:SetupStyleConfig()
	self.wndConfigStyle:FindChild("ProfileContainer:DropdownBase"):SetText(self.db:GetCurrentProfile())
	self.nIconOffset = 0


	local unitPlayer = GameLib.GetPlayerUnit() 
		--if unitPlayer then
	self.unitTarget = unitPlayer:GetTarget()
	self.unitFocus = unitPlayer:GetAlternateTarget()
	self:NewUnit()
	self.timerTFrame = ApolloTimer.Create(2, false, "OnTargetFrameHide", self)
end

function Interruptor:SetupStyleConfig()
	for strKey, tCategory in pairs(self.db.profile) do
	if type(tCategory) == "table" then
		for strName, strColor in pairs(tCategory.Colors) do
			self.wndConfigStyle:FindChild(strKey):FindChild(strName):FindChild("ColorWindow"):SetBGColor(strColor)
		end
		for strName, strTexture in pairs(tCategory.Textures) do
			self.wndConfigStyle:FindChild(strKey):FindChild("Dropdown"..strName):SetText(strTexture)
				if strName == "border" then
					self:ApplyBorderTexture(strKey, strTexture)
				else
					self:ApplyRegularTexture(strKey, strName, strTexture)
				end
		end
		for strName, nValue in pairs(tCategory.Sliders) do
			self.wndConfigStyle:FindChild(strKey):FindChild("Slider"..strName):FindChild("Slider"):SetValue(nValue)
			self.wndConfigStyle:FindChild(strKey):FindChild("Slider"..strName):FindChild("Number"):SetText(nValue.."")
		end
		self:ResizeBorders(strKey, tCategory.Sliders.bordersize)
		self:ResizePadding(strKey, tCategory.Sliders.padding)
		self:ColorBackground(strKey, tCategory.Colors.background)
		self:ColorBorders(strKey, tCategory.Colors.border)
	end
	end
	self.wndConfigStyle:FindChild("ProfileContainer:DropdownProfile"):SetText(self.db:GetCurrentProfile())
	if self.bConfig then
		self.wndBar:SetBarColor(self.db.profile.Castbar.Colors["interruptable"])
		self.tArmorFrames[1]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.destroyed)
		self.tArmorFrames[2]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.selfdestroyed)
		self.tArmorFrames[3]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.undestroyed)
		for key, wndParent in pairs(self.tArmorFrames) do
			wndParent:FindChild("BarTexture"):SetAnchorOffsets(0,0,-1*self.db.profile.InterruptArmor.Sliders.gap,0)
		end
	end
end


-----------------------------------------------------------------------------------------------
-- Interruptor Functions
-----------------------------------------------------------------------------------------------
function Interruptor:OnConfigure(strCommand, strParam) --true in registerAddon
--Print(self.strTest)--test
--Sound.Play(Sound.PlayUIDatachronIncoming)
--Print(string.sub(string.gsub(debug.getinfo(1).source, "^(.+[\\/])[^\\/]+$", "%1"), 2, -1))
if strParam and strParam:find("highlight") then
	local strCastName = strParam:match('"(.*)"')
	if self.unitTheUnit and self.unitTheUnit:ShouldShowCastBar() then
		strCastName = self.unitTheUnit:GetCastName()
	end
	if strCastName and strCastName:len() > 0  then
		local nSound = 0
		if strParam:find("1") then
			--Print("sound1")
			nSound = 1
		elseif strParam:find("2") then
			--Print("sound2")
			nSound = 2
		elseif strParam:find("3") then
			--Print("sound2")
			nSound = 3
		end
		if self.db.global.tHighlights[strCastName] == nSound then
			self.db.global.tHighlights[strCastName] = nil
		else
			self.db.global.tHighlights[strCastName] = nSound
		end
	end
else
--self.wndConfig:Show(true)
self.wndConfig:Invoke()
self:OnUnlock()
--if not ColorPicker then
--	self.wndConfig:FindChild("ErrorColorPicker"):Show(true, true)
--	self.bNoColorPicker = true
--end
end

end



function Interruptor:OnTargetFrameHide()
	local addonTargetFrame = Apollo.GetAddon("TargetFrame")
	if self.db.char.bHideTCB and addonTargetFrame and addonTargetFrame.luaTargetFrame then
		addonTargetFrame.luaTargetFrame.UpdateCastingBar = function() end
		addonTargetFrame.luaTargetFrame.wndMainClusterFrame:FindChild("CastingFrame"):Show(false,true)
	--else Print("noAddon")
	end
	if self.db.char.bHideFCB and addonTargetFrame and addonTargetFrame.luaFocusFrame then
		addonTargetFrame.luaFocusFrame.UpdateCastingBar = function() end
		addonTargetFrame.luaFocusFrame.wndMainClusterFrame:FindChild("CastingFrame"):Show(false,true)
	--else Print("noAddon")
	end
end



function Interruptor:OnCombatLogCCState(tEventArgs)
--	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InterruptArmorReduced then
--		self:TableInspect(tEventArgs)
--	end
--Print(tEventArgs.nInterruptArmorHit)
if tEventArgs.unitCaster ~= GameLib.GetPlayerUnit() or tEventArgs.unitTarget ~= self.unitTheUnit then return end
if tEventArgs.nInterruptArmorHit and tEventArgs.nInterruptArmorHit > 0 then
	--armor destroyed
	--self:OnFrame()
	--Print(self.nLastCCArmorMax)
	--Print(self.nLastCCArmorValue)
	--for i= self.nLastCCArmorMax-self.nLastCCArmorValue - tEventArgs.nInterruptArmorHit +1,self.nLastCCArmorMax-self.nLastCCArmorValue do
	--		self.tArmorFrames[i]:FindChild("BarTexture"):SetBGColor(self.tColors.selfdestroyed)	
	--end
	self.nSelfDestroyed = self.nSelfDestroyed + tEventArgs.nInterruptArmorHit
	--Print(self.nSelfDestroyed)
end
end

function Interruptor:OnCombatLogInterrupted(tEventArgs)
if tEventArgs.unitCaster ~= GameLib.GetPlayerUnit() or tEventArgs.unitTarget ~= self.unitTheUnit then return end
--Print("Interrupted.")
--self.wndCCArmor:SetSprite("CRB_NameplateSprites:sprNp_WhiteBarFlash")
self.wndCCArmor:FindChild("IAFrame:Flash"):SetBGColor(self.db.profile.InterruptArmor.Colors.selfdestroyed)
self.wndCCArmor:FindChild("IAFrame:Flash"):SetSpriteProgress(0)
end
--[[
function Interruptor:OnCombatLogDmg(tEventArgs)
--Print(tEventArgs.splCallingSpell:GetId())
if tEventArgs.unitCaster ~= GameLib.GetPlayerUnit() or tEventArgs.unitTarget ~= self.unitTheUnit then return end
--Print(tEventArgs.splCallingSpell:GetId()..tostring(tEventArgs.splCallingSpell:GetId() == 46160))
if tEventArgs.splCallingSpell:GetId() == 46160 then --47202
	self:OnFrame()
	Print("dmg:"..self.nLastCCArmorValue)
	if self.nLastCCArmorValue > 0 and self.nLastCCArmorValue < self.nLastCCArmorMax then
		self.tArmorFrames[self.nLastCCArmorMax - self.nLastCCArmorValue]:FindChild("BarTexture"):SetBGColor(self.tColors.selfdestroyed)
	end
	--self.nSelfDestroyed = self.nSelfDestroyed + 1
end
end

function Interruptor:OnArmorChange(tEventArgs)
	Print("TSL:"..GameLib.GetGameTime() - self.fTime)
	self.fTime = GameLib.GetGameTime()
	self:TableInspect(tEventArgs)
	
end

function Interruptor:TableInspect(tTable)
	for key, value in pairs(tTable) do
		if type(value) == "table" then
			Print("table:"..key)
			self:TableInspect(value)
			Print("/table:"..key)
		--elseif type(value) == "userdata" then
		--	Print(key..":userdata")
		else
			Print(key..":"..tostring(value))
		end
	end
end
--]]
function Interruptor:SetIcon(strSpellName)
local h = self.db.char.nDistributionValue
for i=1, #strSpellName do
  local char = strSpellName:sub(i,i)
local nvalue = string.byte(char)
local index = bit32.bxor(h,nvalue)
h = tRandomMap[index+1]
end
self.wndIcon:FindChild("Icon"):SetSprite(tIconSprites[h+1])
end

function Interruptor:OnEnteredCombat(unitChanged,bInCombat)
	if unitChanged == GameLib.GetPlayerUnit() then
		if bInCombat then
			self.bPlayerInCombat = true
			self:NewUnit()
		else
			self.unitMaxRank = nil
			self.nOneBossRank = -1
			self.bPlayerInCombat = false
			self:NewUnit()
		end
	end
	--if unitChanged:GetType() == "Player" or (unitChanged:GetDispositionTo(GameLib.GetPlayerUnit()) ~= Unit.CodeEnumDisposition.Hostile and unitChanged:GetDispositionTo(GameLib.GetPlayerUnit()) ~= Unit.CodeEnumDisposition.Neutral) then return end
	if bInCombat and unitChanged:GetRank() > self.nOneBossRank then
		self.nOneBossRank = unitChanged:GetRank()
		self.unitMaxRank = unitChanged
		self:NewUnit()
	elseif bInCombat and unitChanged:GetRank() == self.nOneBossRank then
		self.unitMaxRank = nil
		self:NewUnit()
	end
end

function Interruptor:OnTargetUnitChanged(unitNew)
	self.unitTarget = unitNew
	self:NewUnit()
	--Print("newtarget")
end

function Interruptor:OnFocusUnitChanged(unitNew)
	self.unitFocus = unitNew
	self:NewUnit()
end

--[[function Interruptor:NewUnit()
	if self.bConfig then return end
	if self.db.char.strTargetType == "Target" then
		self.unitTheUnit = self.unitTarget
	else
		self.unitTheUnit = self.unitFocus
	end
	if self.db.char.bNoAlt or self.unitTheUnit then
		self.wndMain:Show(self.unitTheUnit ~= nil, true)

	 return end
	local unitRemaining = self.unitFocus or self.unitTarget
		--Print("no prime unit.")
	if unitRemaining and unitRemaining:GetType() ~= "Player" and (unitRemaining:GetDispositionTo(GameLib.GetPlayerUnit()) == Unit.CodeEnumDisposition.Hostile or unitRemaining:GetDispositionTo(GameLib.GetPlayerUnit()) == Unit.CodeEnumDisposition.Neutral) then
		--Print("altunit selected.")
		self.unitTheUnit = unitRemaining
	elseif self.bPlayerInCombat then
		self.unitTheUnit = self.unitMaxRank
	end
	self.wndMain:Show(self.unitTheUnit ~= nil, true)
	--if self.unitTheUnit then
	Print(self.unitTheUnit:GetName().."what??")
	else
	Print("no target")
	end comment finished
end--]]

function Interruptor:NewUnit()
	if self.bConfig then return end
	for idx, strTargetType in ipairs(self.db.char.tidxTargeting) do
		if self.db.char.tTargetingInfo[strTargetType].bEnabled and
		self["unit"..strTargetType] and
		self["unit"..strTargetType]:IsValid() and
		(self.db.char.tTargetingInfo[strTargetType].bFriendly or self["unit"..strTargetType]:GetDispositionTo(GameLib.GetPlayerUnit()) ~= Unit.CodeEnumDisposition.Friendly) and
		(self.db.char.tTargetingInfo[strTargetType].bPlayers or self["unit"..strTargetType]:GetType() ~= "Player") and
		((not self.db.char.tTargetingInfo[strTargetType].bInCombat) or self.bPlayerInCombat ) then
			self.unitTheUnit = self["unit"..strTargetType]
			self.wndMain:Show(true, true)
			return
		end
	end
	self.wndMain:Show(false, true)
end 

-- Define general functions here
function Interruptor:OnFrame()
--if self.bConfig then return end --maybe unregister handler
local unitTarget = self.unitTheUnit
if not unitTarget then --Print("meh")
 return end
local fvulnerabletime = unitTarget:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0
local nCCArmorValue = unitTarget:GetInterruptArmorValue()
local nCCArmorMax = unitTarget:GetInterruptArmorMax()
--local nCCArmorMaxNotNegative

if nCCArmorMax ~= self.nLastCCArmorMax then
	--Print("Update Max:"..nCCArmorMax)
	self:NewMaxArmor(nCCArmorMax)
	self.nLastCCArmorMax = nCCArmorMax
end


if nCCArmorValue ~= self.nLastCCArmorValue then
	if nCCArmorValue > nCCArmorMax then --does happen :-)
		--Print("Lag:"..nCCArmorMax..","..nCCArmorValue)
		nCCArmorValue = nCCArmorMax
	end
	--Print("Update Value:"..nCCArmorValue)
	self:UpdateCCArmor(nCCArmorValue)
	self.nLastCCArmorValue = nCCArmorValue
end

if fvulnerabletime ~= 0 then
	self:UpdateVulnerable(fvulnerabletime, unitTarget)-- unitTarget parameter added to function call changes made by Pax on 4/7/2015
elseif unitTarget:ShouldShowCastBar() then
	self:UpdateCast(unitTarget)
elseif self.bCastbarVisibility or self.fLastVulnerable ~= 0 then
	--Print("hide castbar")
	self.fLastVulnerable = 0
	self.wndBarFrame:Show(false, true)
	self.bCastbarVisibility = false
end


end

function Interruptor:UpdateVulnerable(fvulnerabletime, unitTarget)-- unitTarget parameter added to function call changes made by Pax on 4/7/2015
	if fvulnerabletime > self.fLastVulnerable then --(not self.bCastbarVisibility) or 
		self.wndBarFrame:Show(true, true)
		if self.db.char.nIDMoOIcon == 1 then
			self.wndIcon:Show(false, true)
		--elseif self.db.char.nIDMoOIcon == 2 then
		elseif self.db.char.nIDMoOIcon == 3 then
			self.wndIcon:FindChild("Icon"):SetSprite("IconSprites:Icon_BuffWarplots_strikethrough")
		end
		self.wndBar:SetBarColor(self.db.profile.Castbar.Colors["vulnerable"])
		self.fCastMax = unitTarget:GetCCStateTotalTime(Unit.CodeEnumCCState.Vulnerability) -- changes made by Pax on 4/7/2015 now should properly handle the vulnerability state
		self.wndBar:SetMax(self.fCastMax)
		--self.wndBar:SetMax(fvulnerabletime)
		--self.fCastMax = fvulnerabletime -- commented out by pax 8 july 2015
		--Print("Max:"..fvulnerabletime)
		--self.bNewCast = false
		self.wndDuration:SetText("")
		self.wndBar:SetTextFlags("DT_CENTER", true)
		self.bCastbarVisibility = false
	end
	self.wndBar:SetProgress(fvulnerabletime)
	self.wndBar:SetText(string.format("%.1f", fvulnerabletime).."/"..string.format("%.1f", self.fCastMax))
	self.fLastVulnerable = fvulnerabletime
end

function Interruptor:UpdateCast(unitTarget)
	local fCastElapsed = unitTarget:GetCastElapsed()
	--Print(fCastElapsed..","..self.fLastCastElapsed)
	if (not self.bCastbarVisibility) or fCastElapsed < self.fLastCastElapsed then
		--Print("New Cast")
		self.wndBarFrame:Show(true, true)
		local strCastName = unitTarget:GetCastName()
		if self.db.char.bIcons then
			self.wndIcon:Show(true, true)
			self:SetIcon(strCastName)
		end
		if self.db.global.tHighlights[strCastName] then
			self.wndBar:SetBarColor(self.db.profile.Castbar.Colors["highlighted"])
			if self.db.global.tHighlights[strCastName] == 1 then
				Sound.Play(184)
			elseif self.db.global.tHighlights[strCastName] == 2 then
				Sound.PlayFile("HighlightSound.wav")
			elseif self.db.global.tHighlights[strCastName] == 3 then
				Sound.Play(212)
			end
		else
			self.wndBar:SetBarColor(self.db.profile.Castbar.Colors[self.strCCStatus])
		end
		self.fCastMax = unitTarget:GetCastDuration()
		self.wndBar:SetMax(self.fCastMax)
		self.wndBar:SetText("  "..strCastName)
		self.wndBar:SetTextFlags("DT_CENTER", false)
	end
	self.fLastCastElapsed = fCastElapsed
	self.wndBar:SetProgress(fCastElapsed)
	self.wndDuration:SetText(string.format("%.1f", fCastElapsed/1000).."/"..string.format("%.1f", self.fCastMax/1000))
	self.bCastbarVisibility = true
end

function Interruptor:NewMaxArmor(nCCArmorMax)
	if nCCArmorMax == -1 then
		self.strCCStatus = "uninterruptable"
		nCCArmorMax = 0
	else
		--Print("armor")
		self.strCCStatus = "interruptable"
		self.nLastCCArmorMax = (self.nLastCCArmorMax >= 0) and self.nLastCCArmorMax or 0
	end
	if self.bCastbarVisibility then
		self.wndBar:SetBarColor(self.db.profile.Castbar.Colors[self.strCCStatus])
	end
	self:DrawCCArmorFrames(nCCArmorMax)
	--return nCCArmorMax
end

function Interruptor:DrawCCArmorFrames(nCCArmorMax)
	if nCCArmorMax == 0 then
		self.wndCCArmor:FindChild("IAFrame"):Show(false, true)
		self.nIconOffset = 0
		local nRightGap = self.tBorderGapMultipliers[self.db.profile.Icon.Textures.border].RIGHT * self.db.profile.Icon.Sliders.bordersize
		self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset+nRightGap),0,-1*nRightGap,self.nIconOffset)	
	else
		self.wndCCArmor:FindChild("IAFrame"):Show(true, true)
		--self.wndCCArmor:FindChild("Flash"):SetSpriteProgress(0)
		--self.wndCCArmor:FindChild("Flash"):SetSpriteTime(0)
		if self.db.char.bIconBig then
			self.nIconOffset = self.wndCCArmor:GetHeight()+self.tBorderGapMultipliers[self.db.profile.Castbar.Textures.border].BOTTOM * self.db.profile.Castbar.Sliders.bordersize
			local nRightGap = self.tBorderGapMultipliers[self.db.profile.Icon.Textures.border].RIGHT * self.db.profile.Icon.Sliders.bordersize
			self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset+nRightGap),0,-1*nRightGap,self.nIconOffset)	
		end
	end
	if nCCArmorMax > self.nLastCCArmorMax then
		for i=self.nLastCCArmorMax+1,nCCArmorMax do
			self.tArmorFrames[i] = Apollo.LoadForm(self.xmlDoc, "IAForm", self.wndIAContainer, self)
			self.tArmorFrames[i]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.undestroyed)
			self.tArmorFrames[i]:FindChild("BarTexture"):SetSprite(self.tRegularTextures[self.db.profile.InterruptArmor.Textures.main])
			self.tArmorFrames[i]:FindChild("BarTexture"):SetAnchorOffsets(0,0,-1*self.db.profile.InterruptArmor.Sliders.gap,0)
		end
		self.nLastCCArmorValue = self.nLastCCArmorValue - self.nLastCCArmorMax + nCCArmorMax
	else
		for i=nCCArmorMax+1,self.nLastCCArmorMax do
			self.tArmorFrames[i]:Destroy()
			self.tArmorFrames[i] = nil
		end
		if self.nLastCCArmorValue > nCCArmorMax then
			self.nLastCCArmorValue = nCCArmorMax
		--	Print("Lowering:"..nCCArmorMax)
		end
	end
	for i=1,nCCArmorMax do
	self.tArmorFrames[i]:SetAnchorPoints((i-1)/nCCArmorMax,0,i/nCCArmorMax,1)
	end
	self.nSelfDestroyed = 0
end


function Interruptor:UpdateCCArmor(nCCArmorValue)
	--if nCCArmorValue == -1 then Print("happens") end
	self.nLastCCArmorValue = (self.nLastCCArmorValue >= 0) and self.nLastCCArmorValue or 0
	nCCArmorValue = (nCCArmorValue >= 0) and nCCArmorValue or 0
	--Print(nCCArmorValue..","..self.nLastCCArmorValue)
--Print((self.nLastCCArmorMax-nCCArmorValue+1)..","..self.nLastCCArmorMax-self.nLastCCArmorValue..","..(self.nLastCCArmorMax-self.nLastCCArmorValue+1)..","..self.nLastCCArmorMax-nCCArmorValue)
	if nCCArmorValue > self.nLastCCArmorValue then
	--Print("TSLA:"..GameLib.GetGameTime() - self.fTime)--only test
	--Print("TSLC:"..GameLib.GetGameTime() - self.fTime2)--only test
		for i= self.nLastCCArmorMax-nCCArmorValue+1,self.nLastCCArmorMax-self.nLastCCArmorValue do
			self.tArmorFrames[i]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.undestroyed)
		--	self.tArmorFrames[i]:FindChild("BarTexture"):SetSprite("CRB_Basekit:kitIProgBar_HoloFrame_FillBlue") --important
		end
		self.nSelfDestroyed = 0
	else
	--self.fTime = GameLib.GetGameTime()--test
	local nFinal = self.nLastCCArmorMax - nCCArmorValue
		for i= self.nLastCCArmorMax-self.nLastCCArmorValue+1,nFinal do
			--Print(self.nSelfDestroyed)
			if nFinal - i+1 <= self.nSelfDestroyed then
				self.nSelfDestroyed = self.nSelfDestroyed - 1
				--self.tArmorFrames[i]:FindChild("BarTexture"):SetSprite("CRB_Basekit:kitIProgBar_HoloFrame_FillRed") --important
				self.tArmorFrames[i]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.selfdestroyed)
			else
				self.tArmorFrames[i]:FindChild("BarTexture"):SetBGColor(self.db.profile.InterruptArmor.Colors.destroyed)
			--	self.tArmorFrames[i]:FindChild("BarTexture"):SetSprite("CRB_Basekit:kitIProgBar_HoloFrame_FillBlue") --important
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Config Functions
---------------------------------------------------------------------------------------------------

--[[function Interruptor:OnNoAltChecked( wndHandler, wndControl, eMouseButton )
self.db.char.bNoAlt = true
self:NewUnit()
end

function Interruptor:OnNoAltUnchecked( wndHandler, wndControl, eMouseButton )
self.db.char.bNoAlt = false
self:NewUnit()
end--]]

function Interruptor:OnUnlock( wndHandler, wndControl, eMouseButton )
	self.bConfig = true
	Apollo.RemoveEventHandler("NextFrame", self)
	self.wndMain:AddStyle("Moveable")
	self.wndMain:AddStyle("Sizable")
	self.wndMain:RemoveStyle("IgnoreMouse")
	self.wndCCArmor:AddStyle("Moveable")
	self.wndCCArmor:AddStyle("Sizable")
	self.wndCCArmor:RemoveStyle("IgnoreMouse")
--	Apollo.RemoveEventHandler("NextFrame","OnFrame", self)
	self.wndMain:Show(true, true)
	self.wndBarFrame:Show(true, true)
	self:DrawCCArmorFrames(3)
	self.nLastCCArmorMax = 3
	self:UpdateCCArmor(1)
	if self.db.char.bIcons then
		self.wndIcon:Show(true, true)
	end
	self:SetIcon("Test Cast")
	self.wndBar:SetBarColor(self.db.profile.Castbar.Colors["interruptable"])
	self.wndBar:SetMax(1200)
	self.wndBar:SetText("  Test Cast")
	self.wndBar:SetProgress(700)
	self.wndDuration:SetText(string.format("%.1f", 700/1000).."/"..string.format("%.1f", 1200/1000))
			--self.wndCCArmor:Show(true, true)
		--self.nLastCCArmorMax = 3
	self.wndConfig:FindChild("UnlockButton"):SetText(Loc["Lock Castbar"])
	self.wndCCArmor:Show(true, true)
end

--[[function Interruptor:OnSelectFocus( wndHandler, wndControl, eMouseButton )
self.db.char.strTargetType = "Focus"
self:NewUnit()
--Print("selecting focus")
end

function Interruptor:OnSelectTarget( wndHandler, wndControl, eMouseButton )
self.db.char.strTargetType = "Target"
self:NewUnit()
--Print("selecting target")
end--]]

function Interruptor:OnCloseConfig( wndHandler, wndControl, eMouseButton )
self.wndConfig:Show(false)
if self.bConfig then
	self.bConfig = false
	Apollo.RegisterEventHandler("NextFrame","OnFrame", self)
	self.wndMain:RemoveStyle("Moveable")
	self.wndMain:RemoveStyle("Sizable")
	self.wndMain:AddStyle("IgnoreMouse")
	self.wndCCArmor:RemoveStyle("Moveable")
	self.wndCCArmor:RemoveStyle("Sizable")
	self.wndCCArmor:AddStyle("IgnoreMouse")
	self.wndMain:Show(false, true)
	self.wndBarFrame:Show(false, true)
	self:DrawCCArmorFrames(0)
	self.nLastCCArmorMax = 0
	--self.wndCCArmor:Show((self.strCCStatus == "interruptable"), true)
	self.db.char.tAnchorOffsets = {self.wndMain:GetAnchorOffsets()}
	self.db.char.tIAOffsets = {self.wndCCArmor:GetAnchorOffsets()}
	self.wndConfig:FindChild("UnlockButton"):SetText(Loc["Unlock Castbar"])
	if self.db.char.bIAOnCast then
		self.wndCCArmor:Show(false, true)
	end
	--self.wndIcon:SetAnchorOffsets(-1*self.wndBar:GetHeight(),0,0,0)
	self:NewUnit()
end
end

function Interruptor:OnIconsChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIcons = true
	self.wndIcon:Show(true, true)
	self:UpdateGaps()
end

function Interruptor:OnIconsUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIcons = false
	self.wndIcon:Show(false, true)
end

function Interruptor:OnDistributionChange( wndHandler, wndControl, strText )
	--Print("Distribution changed.")
	local nInput = tonumber(strText)
	if type(nInput) == "number" and nInput >= 0 and nInput <= 255 and nInput % 1 == 0 then
		self.db.char.nDistributionValue = nInput
	end
end


function Interruptor:OnTCBChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bHideTCB = true
	self:OnTargetFrameHide()
end

function Interruptor:OnTCBUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bHideTCB = false
end

function Interruptor:OnFCBChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bHideFCB = true
	self:OnTargetFrameHide()
end

function Interruptor:OnFCBUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bHideFCB = false
end

function Interruptor:OnColorClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end
	local strGroup = wndControl:GetParent():GetParent():GetName()
	local strIdentifier = wndControl:GetParent():GetName()
		GeminiColor:ShowColorPicker(self, {callback = "OnGeminiColor", bCustomColor = true, bAlpha = true, strInitialColor = self.db.profile[strGroup].Colors[strIdentifier]}, strGroup, strIdentifier)
end


function Interruptor:OnGeminiColor(strColor, strGroup, strIdentifier)
--Print(strColor)
--Print(strIdentifier..": "..strColor)
	self.wndConfigStyle:FindChild(strGroup):FindChild(strIdentifier):FindChild("ColorWindow"):SetBGColor(strColor)
	self.db.profile[strGroup].Colors[strIdentifier] = strColor
	if strIdentifier == "background" then
		self:ColorBackground(strGroup, strColor)
	elseif strIdentifier == "border" then
		self:ColorBorders(strGroup, strColor)
	elseif self.bConfig then
		if strGroup == "InterruptArmor" then
			self.tArmorFrames[2]:FindChild("BarTexture"):SetBGColor(strColor)
		else
			self.wndBar:SetBarColor(strColor)
		end
	end
end

function Interruptor:ColorBackground(strCategory, strColor)
	local twndBackground = {Castbar = self.wndBarFrame, InterruptArmor = self.wndCCArmor:FindChild("IAFrame"), Icon = self.wndIcon}
	twndBackground[strCategory]:SetBGColor(strColor)
end

function Interruptor:ColorBorders(strCategory, strColor)
	local wndContainer = self["wnd"..strCategory.."BC"]:FindChild("BorderContainer")
	local tBorderSides = {"TOP","BOTTOM","LEFT","RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
	for key, strSide in pairs(tBorderSides) do
		wndContainer:FindChild(strSide):SetBGColor(strColor)
	end
end

function Interruptor:OnColorReset( wndHandler, wndControl, eMouseButton ) --#StylePatch
	if wndHandler ~= wndControl then return end
	local strCategory = wndControl:GetParent():GetParent():GetName()
	local strIdentifier = wndControl:GetParent():GetName()
	if self.db.profiles[self.db.profile.strBasis] and self.db.profiles[self.db.profile.strBasis][strCategory] and self.db.profiles[self.db.profile.strBasis][strCategory].Colors and self.db.profiles[self.db.profile.strBasis][strCategory].Colors[strIdentifier] then
		self:OnGeminiColor(self.db.profiles[self.db.profile.strBasis][strCategory].Colors[strIdentifier], strCategory, strIdentifier)
	else
		self:OnGeminiColor(self.db.profiles[kstrDefaultProfile][strCategory].Colors[strIdentifier], strCategory, strIdentifier)
	end
end

function Interruptor:OnResetPositioning( wndHandler, wndControl, eMouseButton )
	self.db.char.tAnchorOffsets = self.tDefaultPositioning.tAnchorOffsets
	self.db.char.tIAOffsets = self.tDefaultPositioning.tIAOffsets
	self.wndMain:SetAnchorOffsets(unpack(self.db.char.tAnchorOffsets))
	self.wndCCArmor:SetAnchorOffsets(unpack(self.db.char.tIAOffsets))
	self:UpdateGaps()
end

function Interruptor:OnIALockChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIALock = true
	self:UpdateGaps()
	self.wndConfig:FindChild("CheckIconScale"):Enable(true)
end

function Interruptor:OnIALockUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIALock = false
	self.wndConfig:FindChild("CheckIconScale"):Enable(false)
	self.wndConfig:FindChild("CheckIconScale"):SetCheck(false)
	self:OnIconBigUnchecked()
end

function Interruptor:OnIconBigChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIconBig = true
	self:UpdateGaps()
end

function Interruptor:OnIconBigUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIconBig = false
	self.nIconOffset = 0
	self:UpdateGaps()
end

--[[function Interruptor:OnMinimalChecked( wndHandler, wndControl, eMouseButton )
	self.tSaved.bMinimal = true
	self.wndCCArmor:FindChild("BackgroundTexture"):SetSprite("")
	self.wndBarFrame:SetSprite("")
	self.wndIcon:SetSprite("")
	self.wndBar:SetEmptySprite("IRSprites:FullBlack") --do this?
	self.nIconXOffset = 12
	self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset-self.nIconXOffset+1),0,self.nIconXOffset,self.nIconOffset)
end

function Interruptor:OnMinimalUnchecked( wndHandler, wndControl, eMouseButton )
	self.tSaved.bMinimal = false
	self.wndCCArmor:FindChild("BackgroundTexture"):SetSprite("IRSprites:BarFrame")
	self.wndBarFrame:SetSprite("IRSprites:BarFrame")
	self.wndIcon:SetSprite("IRSprites:IconSprite")
	self.wndBar:SetEmptySprite("IRSprites:Inlay") --do this?
	--self.wndBar:SetFillSprite("IRSprites:BarGrey")
	self.nIconXOffset = 3
	self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset-self.nIconXOffset+1),0,self.nIconXOffset,self.nIconOffset)
end--]]

function Interruptor:OnPaddingChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	if wndHandler ~= wndControl then return end
	local strCategory = wndControl:GetParent():GetParent():GetName()
	self.db.profile[strCategory].Sliders.padding = fNewValue
	wndControl:GetParent():FindChild("Number"):SetText(fNewValue.."")
	self:ResizePadding(strCategory, fNewValue)
end

function Interruptor:ResizePadding(strCategory, fNewValue)
	local twndContent = {Castbar = self.wndBar, InterruptArmor = self.wndIAContainer, Icon = self.wndIcon:FindChild("Icon")}
	if strCategory == "InterruptArmor" then
		twndContent[strCategory]:SetAnchorOffsets(fNewValue,fNewValue,-1 * fNewValue +	self.db.profile.InterruptArmor.Sliders.gap ,-1 * fNewValue)
	else
		twndContent[strCategory]:SetAnchorOffsets(fNewValue,fNewValue,-1 * fNewValue ,-1 * fNewValue)
	end
end

function Interruptor:OnBorderResize( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	if wndHandler ~= wndControl then return end
	local strCategory = wndControl:GetParent():GetParent():GetName()
	self.db.profile[strCategory].Sliders.bordersize = fNewValue
	wndControl:GetParent():FindChild("Number"):SetText(fNewValue.."")
	self:ResizeBorders(strCategory, fNewValue)
end

function Interruptor:ResizeBorders(strCategory, fNewValue)
	local wndContainer = self["wnd"..strCategory.."BC"]:FindChild("BorderContainer")
	local tBorderSides = {TOP = {1,0,-1,1},BOTTOM = {1,-1,-1,0},LEFT = {0,1,1,-1},RIGHT = {-1,1,0,-1}, TOPLEFT = {0,0,1,1}, TOPRIGHT = {-1,0,0,1}, BOTTOMLEFT = {0,-1,1,0}, BOTTOMRIGHT = {-1,-1,0,0}}
	for strSide, tMultiplier in pairs(tBorderSides) do
		wndContainer:FindChild(strSide):SetAnchorOffsets(tMultiplier[1] * fNewValue,tMultiplier[2] * fNewValue,tMultiplier[3] * fNewValue,tMultiplier[4] * fNewValue)
	end
	wndContainer:GetParent():SetAnchorOffsets(-1*fNewValue,-1*fNewValue,fNewValue,fNewValue)
	self:UpdateGaps()
end

function Interruptor:OnBGTexCheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	self:OnRegularCheck(wndControl, "background", self.db.profile[wndControl:GetParent():GetName()].Colors.background)
end

function Interruptor:OnFlyoutClose( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	wndControl:GetParent():SetCheck(false)
end

function Interruptor:OnBorderTexCheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local wndContainer = wndControl:FindChild("Flyout:Container")
	wndControl:FindChild("Flyout"):Show(true, true)
	wndContainer:DestroyChildren()
	for strName, tPaths in pairs(self.tBorderTextures) do
		local wndElement = Apollo.LoadForm(self.xmlDoc, "ListTextureForm", wndContainer, self)
		wndElement:SetText(strName)
		wndElement:SetSprite(tPaths.TOP)
		wndElement:SetBGColor(self.db.profile[wndControl:GetParent():GetName()].Colors.border)
		local tData = {strGroup = wndControl:GetParent():GetName(), strIdentifier = "border", strTextureName = strName}
		wndElement:SetData(tData)
	end
	wndContainer:ArrangeChildrenVert()
end

function Interruptor:OnMainTexCheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	if wndControl:GetParent():GetName() == "Castbar" then
		self:OnRegularCheck(wndControl, "main", self.db.profile.Castbar.Colors.interruptable)
	else
		self:OnRegularCheck(wndControl, "main", self.db.profile.InterruptArmor.Colors.undestroyed)
	end
end

function Interruptor:OnTexUncheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	wndControl:FindChild("Flyout"):Show(false, true)
end

function Interruptor:OnRegularCheck(wndControl, strIdentifier, strColor)
	local wndContainer = wndControl:FindChild("Flyout:Container")
	wndControl:FindChild("Flyout"):Show(true, true)
	wndContainer:DestroyChildren()
	for idx, strName in pairs(self.tNumberedTextures) do
		local wndElement = Apollo.LoadForm(self.xmlDoc, "ListTextureForm", wndContainer, self)
		wndElement:SetText(strName)
		wndElement:SetSprite(self.tRegularTextures[strName])
		wndElement:SetBGColor(strColor)
		local tData = {strGroup = wndControl:GetParent():GetName(), strIdentifier = strIdentifier, strTextureName = strName}
		wndElement:SetData(tData)
	end
	wndContainer:ArrangeChildrenVert()
end

function Interruptor:OnProfileCheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local wndContainer = wndControl:FindChild("Flyout:Container")
	wndControl:FindChild("Flyout"):Show(true, true)
	wndContainer:DestroyChildren()
	local tProfiles, nProfiles = self.db:GetProfiles()
	local i = 1
	for index, strName in pairs(tProfiles) do
		if not self.tPredefinedProfiles[strName] then
			local wndElement = Apollo.LoadForm(self.xmlDoc, "ListItemForm", wndContainer, self)
			wndElement:SetText(strName)
			if i == 1 and nProfiles - self.nPredefinedProfiles == 1 then
				wndElement:ChangeArt("BK3:btnHolo_ListView_Simple")
			elseif i == 1 then
				wndElement:ChangeArt("BK3:btnHolo_ListView_Top")
			elseif i == nProfiles - self.nPredefinedProfiles then
				wndElement:ChangeArt("BK3:btnHolo_ListView_Btm")
			end
			wndElement:SetData(strName)
			i = i + 1
		end
	end
	wndContainer:ArrangeChildrenVert()
	wndControl:FindChild("Flyout"):SetAnchorOffsets(-50,0,50,97+(i-1)*30)
end

function Interruptor:OnBasisCheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local wndContainer = wndControl:FindChild("Flyout:Container")
	wndControl:FindChild("Flyout"):Show(true, true)
	wndContainer:DestroyChildren()
	local tProfiles, nProfiles = self.db:GetProfiles()
	local i = 1
	for index, strName in pairs(tProfiles) do
		local wndElement = Apollo.LoadForm(self.xmlDoc, "ListItemBasisForm", wndContainer, self)
		wndElement:SetText(strName)
		if i == 1 and nProfiles == 1 then
			wndElement:ChangeArt("BK3:btnHolo_ListView_Simple")
		elseif i == 1 then
			wndElement:ChangeArt("BK3:btnHolo_ListView_Top")
		elseif i == nProfiles then
			wndElement:ChangeArt("BK3:btnHolo_ListView_Btm")
		end
		wndElement:SetData(strName)
		i = i + 1
	end
	wndContainer:ArrangeChildrenVert()
	wndControl:FindChild("Flyout"):SetAnchorOffsets(-50,0,50,97+(i-1)*30)
end

function Interruptor:OnProfileCreate( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local strBasis = wndControl:GetParent():FindChild("DropdownBase"):GetText()
	local strName = wndControl:GetParent():FindChild("NameInput"):GetText()
	for index, strExistingName in pairs(self.db:GetProfiles()) do
		if strName == strExistingName then return end
	end
	self.db:SetProfile(strName)
	self.db:CopyProfile(strBasis)
	self.db.profile.strBasis = strBasis
	strBasis = wndControl:GetParent():FindChild("DropdownProfile"):SetText(strName)
	self:SetupStyleConfig()
end



function Interruptor:OnIAOnCastChecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIAOnCast = true
end

function Interruptor:OnIAOnCastUnchecked( wndHandler, wndControl, eMouseButton )
	self.db.char.bIAOnCast = false
	--self.wndCCArmor:Show(true, true)
end

function Interruptor:OnSelectMoONoIcon( wndHandler, wndControl, eMouseButton )
	self.db.char.nIDMoOIcon = 1
end

function Interruptor:OnSelectMoOKeepIcon( wndHandler, wndControl, eMouseButton )
	self.db.char.nIDMoOIcon = 2
end

function Interruptor:OnSelectMoOOwnIcon( wndHandler, wndControl, eMouseButton )
	self.db.char.nIDMoOIcon = 3
end
--IconSprites:Icon_BuffWarplots_strikethrough
function Interruptor:OnIAGapChange( wndHandler, wndControl, fNewValue, fOldValue )
	if wndControl ~= wndHandler then return end
	self.db.profile.InterruptArmor.Sliders.gap = fNewValue
	wndControl:GetParent():FindChild("Number"):SetText(fNewValue.."")
	for key, wndParent in pairs(self.tArmorFrames) do
		--Print((wndParent ~= nil and "y" or "n") ..","..(wndParent:FindChild("BarTexture") ~= nil and "y" or "n"))
		wndParent:FindChild("BarTexture"):SetAnchorOffsets(0,0,-1*fNewValue,0)
	end
	self:ResizePadding("InterruptArmor",self.db.profile.InterruptArmor.Sliders.padding)
end

---------------------------------------------------------------------------------------------------
-- BaseForm Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnIconResize( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	if self.bConfig and (not self.bResizeThrottle) then
	--Print("Windowsize changed.")
	self.bResizeThrottle = self.db.char.bIALock --true
	--[[if self.db.char.bIALock then
		self.wndCCArmor:SetAnchorOffsets(-1,10,1,self.wndCCArmor:GetHeight()+10)
		if self.db.char.bIconBig then
		self.nIconOffset = self.wndCCArmor:GetHeight()+10
		end
	end
	self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset-self.nIconXOffset+1),0,self.nIconXOffset,self.nIconOffset)--]]
	self:UpdateGaps()
	else
	self.bResizeThrottle = false
	end
end

function Interruptor:UpdateGaps()
	if self.db.char.bIALock then
		local nBtmGap = self.tBorderGapMultipliers[self.db.profile.Castbar.Textures.border].BOTTOM * self.db.profile.Castbar.Sliders.bordersize
		self.wndCCArmor:SetAnchorOffsets(0,nBtmGap,0,self.wndCCArmor:GetHeight()+nBtmGap)
		if self.db.char.bIconBig and self.bConfig then
			self.nIconOffset = self.wndCCArmor:GetHeight()+nBtmGap
		end
	end
	local nRightGap = self.tBorderGapMultipliers[self.db.profile.Icon.Textures.border].RIGHT * self.db.profile.Icon.Sliders.bordersize
	self.wndIcon:SetAnchorOffsets(-1*(self.wndBarFrame:GetHeight()+self.nIconOffset+nRightGap),0,-1*nRightGap,self.nIconOffset)
	self:OnCastbarShowHide(self.wndBarFrame, self.wndBarFrame)
end

function Interruptor:OnIconShowHide( wndHandler, wndControl )
	--local nBorder = self.db.profile.Castbar.Sliders.bordersize
		--self.wndCastbarBC:SetAnchorOffsets(0,-1 * nBorder, nBorder, nBorder)
		--self.wndCastbarBC:FindChild("Container"):SetAnchorOffsets(-1*nBorder, 0, 0, 0)
	self.wndInterruptArmorBC:FindChild("BorderContainer"):FindChild("LEFT"):Show(not (wndControl:IsVisible() and self.db.char.bIconBig), true)
	self.wndInterruptArmorBC:FindChild("BorderContainer"):FindChild("BOTTOMLEFT"):Show(not (wndControl:IsVisible() and self.db.char.bIconBig), true)
	if wndControl ~= wndHandler then return end
	self.wndCastbarBC:FindChild("BorderContainer"):FindChild("LEFT"):Show(not wndControl:IsShown(), true)
	self.wndCastbarBC:FindChild("BorderContainer"):FindChild("TOPLEFT"):Show(not wndControl:IsShown(), true)
	self.wndCastbarBC:FindChild("BorderContainer"):FindChild("BOTTOMLEFT"):Show(not wndControl:IsShown(), true)
end


function Interruptor:OnCastbarShowHide( wndHandler, wndControl )
	if wndControl ~= wndHandler then return end
	self.wndInterruptArmorBC:FindChild("BorderContainer"):FindChild("TOPLEFT"):Show(not (wndControl:IsShown() and self.db.char.bIALock), true)
	self.wndInterruptArmorBC:FindChild("BorderContainer"):FindChild("TOP"):Show(not (wndControl:IsShown() and self.db.char.bIALock), true)
	self.wndInterruptArmorBC:FindChild("BorderContainer"):FindChild("TOPRIGHT"):Show(not (wndControl:IsShown() and self.db.char.bIALock), true)
	self:OnIconShowHide(wndControl, self.wndIcon)
	if self.db.char.bIAOnCast then
		self.wndCCArmor:Show(wndControl:IsShown() ,true)
	end
end



---------------------------------------------------------------------------------------------------
-- NewConfig Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnConfigTabUncheck( wndHandler, wndControl, eMouseButton )
	if wndControl ~= wndHandler then return end
	wndControl:GetParent():FindChild(wndControl:GetName().."Container"):Show(false, true)
end

function Interruptor:OnConfigTabCheck( wndHandler, wndControl, eMouseButton )
	if wndControl ~= wndHandler then return end
	wndControl:GetParent():FindChild(wndControl:GetName().."Container"):Show(true, true)
end

---------------------------------------------------------------------------------------------------
-- ListTextureForm Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnTextureClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end
	local tData = wndControl:GetData()
	self.db.profile[tData.strGroup].Textures[tData.strIdentifier] = tData.strTextureName
	if tData.strIdentifier == "border" then
		self:ApplyBorderTexture(tData.strGroup, tData.strTextureName)
	else
		self:ApplyRegularTexture(tData.strGroup, tData.strIdentifier, tData.strTextureName)
	end
	local wndFlyout = wndControl:GetParent():GetParent()
	wndFlyout:Show(false, true)
	wndFlyout:GetParent():SetText(tData.strTextureName)
	wndFlyout:GetParent():SetCheck(false)
end

function Interruptor:ApplyRegularTexture(strCategory, strIdentifier, strTextureName)
	if strCategory == "Castbar" and strIdentifier == "main" then
		self.wndBar:SetFillSprite(self.tRegularTextures[strTextureName])
	elseif strCategory == "InterruptArmor" and strIdentifier == "main" then
		for key, wndChild in pairs(self.tArmorFrames) do
			wndChild:FindChild("BarTexture"):SetSprite(self.tRegularTextures[strTextureName])
		end
	else
		local twndBackground = {Castbar = self.wndBarFrame, InterruptArmor = self.wndCCArmor:FindChild("IAFrame"), Icon = self.wndIcon}
		twndBackground[strCategory]:SetSprite(self.tRegularTextures[strTextureName])
	end
end

function Interruptor:ApplyBorderTexture(strCategory, strTextureName)
	local wndContainer = self["wnd"..strCategory.."BC"]:FindChild("BorderContainer")
	for strSide, strTexture in pairs(self.tBorderTextures[strTextureName]) do
		wndContainer:FindChild(strSide):SetSprite(strTexture)
	end
	self:UpdateGaps()
end
---------------------------------------------------------------------------------------------------
-- ListItemForm Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnProfileListSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	self.db:SetProfile(wndControl:GetData())
	local wndFlyout = wndControl:GetParent():GetParent()
	wndFlyout:Show(false, true)
	wndFlyout:GetParent():SetText(wndControl:GetData())
	wndFlyout:GetParent():SetCheck(false)
	self:SetupStyleConfig()
end

function Interruptor:DeleteProfile( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local strName = wndControl:GetParent():GetData()
	if self.db:GetCurrentProfile() ~= strName then
		self.db:DeleteProfile(strName)
		local wndCheckbox = wndControl:GetParent():GetParent():GetParent():GetParent()
		self:OnProfileCheck(wndCheckbox, wndCheckbox)
	end
end

---------------------------------------------------------------------------------------------------
-- ListItemBasisForm Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnBasisListSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local wndFlyout = wndControl:GetParent():GetParent()
	wndFlyout:Show(false, true)
	wndFlyout:GetParent():SetText(wndControl:GetData())
	wndFlyout:GetParent():SetCheck(false)
end

---------------------------------------------------------------------------------------------------
-- TargetListItemForm Functions
---------------------------------------------------------------------------------------------------

function Interruptor:OnTargetUpButton( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local nKey
	for idx, strTargetType in ipairs(self.db.char.tidxTargeting) do
		if strTargetType == wndControl:GetParent():GetName() then
			nKey = idx
		end
	end
	if nKey == 1 then return end
	local tOffsets = {wndControl:GetParent():GetAnchorOffsets()}
	wndControl:GetParent():SetAnchorOffsets(self.tTargetingFrames[self.db.char.tidxTargeting[nKey-1]]:GetAnchorOffsets())
	self.tTargetingFrames[self.db.char.tidxTargeting[nKey-1]]:SetAnchorOffsets(unpack(tOffsets))
	table.remove(self.db.char.tidxTargeting, nKey)
	table.insert(self.db.char.tidxTargeting, nKey-1, wndControl:GetParent():GetName())
end

function Interruptor:OnTargetDownButton( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local nKey
	for idx, strTargetType in ipairs(self.db.char.tidxTargeting) do
		if strTargetType == wndControl:GetParent():GetName() then
			nKey = idx
		end
	end
	if nKey == #self.db.char.tidxTargeting then return end
	local tOffsets = {wndControl:GetParent():GetAnchorOffsets()}
	wndControl:GetParent():SetAnchorOffsets(self.tTargetingFrames[self.db.char.tidxTargeting[nKey+1]]:GetAnchorOffsets())
	self.tTargetingFrames[self.db.char.tidxTargeting[nKey+1]]:SetAnchorOffsets(unpack(tOffsets))
	table.remove(self.db.char.tidxTargeting, nKey)
	table.insert(self.db.char.tidxTargeting, nKey+1, wndControl:GetParent():GetName())
end

function Interruptor:OnTargetCheckUncheck( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	self.db.char.tTargetingInfo[wndControl:GetParent():GetName()][wndControl:GetName()] = wndControl:IsChecked()
end


-----------------------------------------------------------------------------------------------
-- Interruptor Instance
-----------------------------------------------------------------------------------------------
--local InterruptorInst = Interruptor:new()
--InterruptorInst:Init()
