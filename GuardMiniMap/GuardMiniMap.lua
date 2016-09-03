-----------------------------------------------------------------------------------------------
-- Client Lua Script for MiniMap
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "DialogSys"
require "Quest"
require "QuestLib"
require "MailSystemLib"
require "Sound"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "Unit"
require "PublicEvent"
require "PublicEventObjective"
require "FriendshipLib"
require "CraftingLib"
require "LiveEventsLib"
require "LiveEvent"

local GuardMiniMap = {}
local GuardWaypoints

-- TODO: Distinguish markers for different nodes from each other
local kstrMiningNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Mining"
local kcrMiningNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrRelicNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Relic"
local kcrRelicNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFarmingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Plant"
local kcrFarmingNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrSurvivalNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Tree"
local kcrSurvivalNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFishingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Fishing"
local kcrFishingNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local ktConColors =
{
	[Unit.CodeEnumLevelDifferentialAttribute.Grey] 		= CColor.new(0.60, 0.68, 0.64, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Green] 	= CColor.new(0.22, 1, 0, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Cyan] 		= CColor.new(0.28, 1, 1, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Blue] 		= CColor.new(0.19, 0.32, 0.97, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.White] 	= CColor.new(1, 1, 1, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Yellow] 	= CColor.new(1, 0.83, 0, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Orange] 	= CColor.new(1, 0.42, 0, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Red] 		= CColor.new(1, 0, 0, 1),
	[Unit.CodeEnumLevelDifferentialAttribute.Magenta] 	= CColor.new(0.98, 0, 1, 1),
}

local ktPvPZoneTypes =
{
	[GameLib.CodeEnumZonePvpRules.None] 					= "",
	[GameLib.CodeEnumZonePvpRules.ExileStronghold]			= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionStronghold] 		= Apollo.GetString("MiniMap_Dominion"),
	[GameLib.CodeEnumZonePvpRules.Sanctuary] 				= Apollo.GetString("MiniMap_Sanctuary"),
	[GameLib.CodeEnumZonePvpRules.Pvp] 						= Apollo.GetString("MiniMap_PvP"),
	[GameLib.CodeEnumZonePvpRules.ExilePVPStronghold] 		= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionPVPStronghold] 	= Apollo.GetString("MiniMap_Dominion"),
}

local ktTooltipCategories =
{
	QuestNPC = 1,
	TrackedQuest = 2,
	GroupMember = 3,
	NeutralNPC = 4,
	HostileNPC = 5,
	Path = 6,
	Challenge = 7,
	PublicEvent = 8,
	Tradeskill = 9,
	Vendor = 10,
	Service = 11,
	Portal = 12,
	BindPoint = 13,
	Mining = 14,
	Relic = 15,
	Survivalist = 16,
	Farming = 17,
	Friend = 18,
	Rival = 19,
	Taxi = 20,
	CityDirection = 21,
	Other = 22,
	PvPMarker = 23,
	Navpoint = 24,
}

local ktCategoryNames =
{
	[ktTooltipCategories.QuestNPC]		= Apollo.GetString("MiniMap_QuestNPCs"),
	[ktTooltipCategories.TrackedQuest] 	= Apollo.GetString("MiniMap_QuestObjectives"),
	[ktTooltipCategories.GroupMember]	= Apollo.GetString("MiniMap_GroupMembers"),
	[ktTooltipCategories.NeutralNPC] 	= Apollo.GetString("MiniMap_NeutralNPCs"),
	[ktTooltipCategories.HostileNPC] 	= Apollo.GetString("MiniMap_HostileNPCs"),
	[ktTooltipCategories.Path] 			= Apollo.GetString("MiniMap_PathMissions"),
	[ktTooltipCategories.Challenge] 	= Apollo.GetString("MiniMap_Challenges"),	
	[ktTooltipCategories.PublicEvent] 	= Apollo.GetString("ZoneMap_PublicEvent"),
	[ktTooltipCategories.Tradeskill] 	= Apollo.GetString("MiniMap_Tradeskills"),
	[ktTooltipCategories.Vendor] 		= Apollo.GetString("MiniMap_Vendors"),
	[ktTooltipCategories.Service] 		= Apollo.GetString("MiniMap_Services"),
	[ktTooltipCategories.Portal] 		= Apollo.GetString("MiniMap_InstancePortals"),
	[ktTooltipCategories.BindPoint] 	= Apollo.GetString("MiniMap_BindPoints"),
	[ktTooltipCategories.Mining] 		= Apollo.GetString("ZoneMap_MiningNodes"),
	[ktTooltipCategories.Relic] 		= Apollo.GetString("ZoneMap_RelicHunterNodes"),
	[ktTooltipCategories.Survivalist] 	= Apollo.GetString("ZoneMap_SurvivalistNodes"),
	[ktTooltipCategories.Farming] 		= Apollo.GetString("ZoneMap_FarmingNodes"),
	[ktTooltipCategories.Friend] 		= Apollo.GetString("MiniMap_Friends"),
	[ktTooltipCategories.Rival] 		= Apollo.GetString("MiniMap_Rivals"),
	[ktTooltipCategories.Taxi] 			= Apollo.GetString("ZoneMap_Taxis"),
	[ktTooltipCategories.CityDirection] = Apollo.GetString("ZoneMap_CityDirections"),
	[ktTooltipCategories.PvPMarker]		= Apollo.GetString("MiniMap_PvPObjective"),
	[ktTooltipCategories.Navpoint]		= Apollo.GetString("Navpoint"),
}

local ktInstanceSettingTypeStrings =
{
	Veteran = Apollo.GetString("MiniMap_Veteran"),
	Rallied = Apollo.GetString("MiniMap_Rallied"),
}


local knSaveVersion = 4

function GuardMiniMap:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function GuardMiniMap:CreateOverlayObjectTypes()
	self.eObjectTypePublicEvent			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePublicEventKill		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeChallenge			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePing				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCityDirection		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeHazard 				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReward 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReceiving 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNew 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNewSoon 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestTarget 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestKill	 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeTradeskills 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeVendor 				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGuard 				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeAuctioneer 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCommodity 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeInstancePortal 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointActive 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointInactive 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeMiningNode 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeRelicHunterNode 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeSurvivalistNode 	= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFarmingNode 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFishingNode 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeVendorFlight 		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFlightPathNew		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeNeutral	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeHostile	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeFriend	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeRival	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeTrainer	 			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGroupMember			= self.wndMiniMap:CreateOverlayType()
	self.eObjectPvPMarkers				= self.wndMiniMap:CreateOverlayType()

	self.eObjectTypeFlightPath			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCREDDExchange		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeCostume				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeBank				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGuildBank			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGuildRegistrar		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeMail				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeServices			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeConvert				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeNavPoint			= self.wndMiniMap:CreateOverlayType()

	self.eObjectTypeEliteHostile		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeEliteNeutral		= self.wndMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueFarming		= self.wndMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueMining		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeUniqueRelic			= self.wndMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueSurvival		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePathResource		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeLore				= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestItem			= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypePC					= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeQuestCritter		= self.wndMiniMap:CreateOverlayType()
	self.eObjectTypeGuardWaypoint		= self.wndMiniMap:CreateOverlayType()
end

function GuardMiniMap:BuildCustomMarkerInfo()
	self.tMinimapMarkerInfo =
	{
		PvPBlueCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCarry",	bFixedSizeMedium = true	},
		PvPRedCarry				= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCarry",	bFixedSizeMedium = true	},
		PvPNeutralCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCarry",	bFixedSizeMedium = true	},
		PvPExileCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",		bFixedSizeMedium = true	},
		PvPDominionCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",	bFixedSizeMedium = true	},
		PvPNeutralCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",	bFixedSizeMedium = true	},
		PvPExileCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",		bFixedSizeMedium = true	},
		PvPDominionCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",	bFixedSizeMedium = true	},
		PvPNeutralCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",	bFixedSizeMedium = true	},
		PvPBattleAlert			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_BattleAlert",	bFixedSizeMedium = true	},
		IronNode				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		TitaniumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ZephyriteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		PlatinumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		HydrogemNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		XenociteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ShadeslateNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		GalactiumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		NovaciteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		StandardRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AcceleratedRelicNode	= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AdvancedRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		DynamicRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		KineticRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		SpirovineNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BladeleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		YellowbellNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		PummelgranateNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SerpentlilyNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GoldleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HoneywheatNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CrowncornNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CoralscaleNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LogicleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		StoutrootNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GlowmelonNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		FaerybloomNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		WitherwoodNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		FlamefrondNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GrimgourdNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MourningstarNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BloodbriarNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		OctopodNode				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HeartichokeNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		AlgorocTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CelestionTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DeraduneTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		EllevarTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GalerasTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		AuroriaTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WhitevaleTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DreadmoorTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		FarsideTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CoralusTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MurkmireTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WilderrunTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MalgraveTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		HalonRingTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GrimvaultTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		SchoolOfFishNode		= { nOrder = 100, 	objectType = self.eObjectTypeFishingNode,		strIcon = kstrFishingNodeIcon,	crObject = kcrFishingNode,	crEdge = kcrFishingNode },
		Friend					= { nOrder = 2, 	objectType = self.eObjectTypeFriend, 			strIcon = "IconSprites:Icon_Windows_UI_CRB_Friend",	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Rival					= { nOrder = 3, 	objectType = self.eObjectTypeRival, 			strIcon = "IconSprites:Icon_MapNode_Map_Rival", 	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Trainer					= { nOrder = 4, 	objectType = self.eObjectTypeTrainer, 			strIcon = "IconSprites:Icon_MapNode_Map_Trainer", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestKill				= { nOrder = 5, 	objectType = self.eObjectTypeQuestKill, 		strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestTarget				= { nOrder = 6,		objectType = self.eObjectTypeQuestTarget, 		strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventKill			= { nOrder = 7,		objectType = self.eObjectTypePublicEventKill, 	strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventTarget		= { nOrder = 8,		objectType = self.eObjectTypePublicEventTarget, strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestReward				= { nOrder = 9,		objectType = self.eObjectTypeQuestReward, 		strIcon = "sprMM_QuestCompleteUntracked", 	bNeverShowOnEdge = true },
		QuestRewardSoldier		= { nOrder = 10,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Soldier_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardSettler		= { nOrder = 11,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Settler_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardScientist	= { nOrder = 12,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Scientist_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardExplorer		= { nOrder = 13,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Explorer_Accepted", 	bNeverShowOnEdge = true },
		QuestNew				= { nOrder = 14,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewDaily			= { nOrder = 14,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		QuestNewSoldier			= { nOrder = 15,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewSettler			= { nOrder = 16,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewScientist		= { nOrder = 17,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewExplorer		= { nOrder = 18,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewMain			= { nOrder = 19,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewMainSoldier		= { nOrder = 20,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewMainSettler		= { nOrder = 21,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewMainScientist	= { nOrder = 22,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewMainExplorer	= { nOrder = 23,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewRepeatable		= { nOrder = 24,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSoldier = { nOrder = 25,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSettler = { nOrder = 26,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewRepeatableScientist = { nOrder = 27,objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewRepeatableExplorer = { nOrder = 28,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestReceiving			= { nOrder = 29,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "sprMM_QuestCompleteOngoing", 	bNeverShowOnEdge = true },
		QuestReceivingSoldier	= { nOrder = 30,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestReceivingSettler	= { nOrder = 31,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestReceivingScientist	= { nOrder = 32,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestReceivingExplorer	= { nOrder = 33,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewSoon			= { nOrder = 34,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		QuestNewMainSoon		= { nOrder = 35,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		QuestNewTradeskill		= { nOrder = 36,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Tradeskill", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		QuestGivingTradeskill	= { nOrder = 36,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Tradeskill", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		QuestReceivingTradeskill	= { nOrder = 36,	objectType = self.eObjectTypeQuestNewSoon, 	strIcon = "IconSprites:Icon_MapNode_Map_Quest_Tradeskill", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		ConvertItem				= { nOrder = 36,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		ConvertRep				= { nOrder = 37,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Vendor					= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Mail					= { nOrder = 39,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Mailbox", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CityDirections			= { nOrder = 40,	objectType = self.eObjectTypeGuard, 			strIcon = "IconSprites:Icon_MapNode_Map_CityDirections", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },		
		Dye						= { nOrder = 41,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_DyeSpecialist", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathSettler		= { nOrder = 42,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Flight", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPath				= { nOrder = 43,	objectType = self.eObjectTypeVendorFlightPathNew, strIcon = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered", bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathNew			= { nOrder = 44,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Taxi", 	bNeverShowOnEdge = true },
		TalkTo					= { nOrder = 45,	objectType = self.eObjectTypeQuestTarget, 		strIcon = "IconSprites:Icon_MapNode_Map_Chat", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		InstancePortal			= { nOrder = 46,	objectType = self.eObjectTypeInstancePortal, 	strIcon = "IconSprites:Icon_MapNode_Map_Portal", 	bNeverShowOnEdge = true },
		BindPoint				= { nOrder = 47,	objectType = self.eObjectTypeBindPointInactive, strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		BindPointCurrent		= { nOrder = 48,	objectType = self.eObjectTypeBindPointActive, 	strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		TradeskillTrainer		= { nOrder = 49,	objectType = self.eObjectTypeTradeskills, 		strIcon = "IconSprites:Icon_MapNode_Map_Tradeskill", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CraftingStation			= { nOrder = 50,	objectType = self.eObjectTypeTradeskills, 		strIcon = "IconSprites:Icon_MapNode_Map_Tradeskill", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CommodityMarketplace	= { nOrder = 51,	objectType = self.eObjectTypeCommodities, 		strIcon = "IconSprites:Icon_MapNode_Map_CommoditiesExchange", bNeverShowOnEdge = true },
		ItemAuctionhouse		= { nOrder = 52,	objectType = self.eObjectTypeAuctioneer, 		strIcon = "IconSprites:Icon_MapNode_Map_AuctionHouse", 	bNeverShowOnEdge = true },
		SettlerImprovement		= { nOrder = 53,	objectType = GameLib.CodeEnumMapOverlayType.PathObjective, strIcon = "CRB_MinimapSprites:sprMM_SmallIconSettler", bNeverShowOnEdge = true },
		CREDDExchange			= { nOrder = 55,	objectType = self.eObjectTypeCREDDExchange,		strIcon = "IconSprites:Icon_MapNode_Map_CREED",	bNeverShowOnEdge = true, bFixedSizeMedium = true, bHideIfHostile = true },
		Neutral					= { nOrder = 151,	objectType = self.eObjectTypeNeutral, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightYellow") },
		Hostile					= { nOrder = 150,	objectType = self.eObjectTypeHostile, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightRed") },
		GroupMember				= { nOrder = 1,		objectType = self.eObjectTypeGroupMember, 		strIcon = "IconSprites:Icon_MapNode_Map_GroupMember", bFixedSizeLarge = true, strIconEdge = "CRB_MinimapSprites:sprMM_PartyMemberArrow", crEdge = CColor.new(1, 1, 1, 1), bNeverShowOnEdge = false },
		Bank					= { nOrder = 54,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true },
		GuildBank				= { nOrder = 56,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		GuildRegistrar			= { nOrder = 55,	objectType = self.eObjectTypeVendor, 			strIcon = "CRB_MinimapSprites:sprMM_Group", bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		VendorGeneral			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorArmor				= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Armor",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorConsumable		= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Consumable",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorElderGem			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ElderGem",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorHousing			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Housing",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorMount				= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Mount",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorRenown			= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Renown",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorReputation		= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorResourceConversion= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorTradeskill		= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Tradeskill",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorWeapon			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Weapon",		bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPArena			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Arena",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPBattlegrounds	= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Battlegrounds",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPWarplots		= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Warplot",	bNeverShowOnEdge = true, bFixedSizeMedium = true },		
		ContractBoard			= { nOrder = 14,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Contracts", 	bNeverShowOnEdge = true, bHideIfHostile = true },
		EliteHostile			= { nOrder = 40,	objectType = self.eObjectTypeEliteHostile, 		strIcon = "sprNp_Target_HostileSecondary", 	bNeverShowOnEdge = true, bFixedSizeMedium = true, crObject = ApolloColor.new("xkcdBrightRed") },	
		EliteNeutral			= { nOrder = 40,	objectType = self.eObjectTypeEliteNeutral, 		strIcon = "sprNp_Target_NeutralSecondary", 	bNeverShowOnEdge = true, bFixedSizeMedium = true, crObject = ApolloColor.new("xkcdBrightYellow") },
		Spirovine				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Spirovine", bFixedSizeMedium  = true},
		Bladeleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Bladeleaf", bFixedSizeMedium = true},
		Yellowbell				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Yellowbell", bFixedSizeMedium = true},
		Pummelgranate			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Pummelgranate", bFixedSizeMedium = true},
		Serpentlily				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Serpentlily", bFixedSizeMedium = true},
		Goldleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Goldleaf", bFixedSizeMedium = true},
		Honeywheat				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Honeywheat", bFixedSizeMedium = true},
		Crowncorn				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Crowncorn", bFixedSizeMedium = true},
		Coralscale				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Coralscale", bFixedSizeMedium = true},
		Logicleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Logicleaf", bFixedSizeMedium = true},
		Stoutroot				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Stoutroot", bFixedSizeMedium = true},
		Glowmelon				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Glowmelon", bFixedSizeMedium = true},
		Faerybloom				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Faerybloom", bFixedSizeMedium = true},
		Witherwood				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Witherwood", bFixedSizeMedium = true},
		Flamefrond				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Flamefrond", bFixedSizeMedium = true},
		Grimgourd				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Grimgourd", bFixedSizeMedium = true},
		Mourningstar			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Mourningstar", bFixedSizeMedium = true},
		Bloodbriar				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Bloodbriar", bFixedSizeMedium = true},
		Octopod					= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Octopod", bFixedSizeMedium = true},
		Heartichoke				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Heartichoke", bFixedSizeMedium = true},
		SmlGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		MedGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		LrgGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		SmlHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		MedHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		LrgHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		SmlRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		MedRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		LrgRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		Iron					= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Iron", bFixedSizeMedium = true},
		Titanium				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Titanium", bFixedSizeMedium  = true},
		Zephyrite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Zephyrite", bFixedSizeMedium = true},
		Platinum				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Platinum", bFixedSizeMedium = true},
		Hydrogem				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Hydrogem", bFixedSizeMedium = true},
		Xenocite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Xenocite", bFixedSizeMedium = true},
		Shadeslate				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Shadeslate", bFixedSizeMedium = true},
		Galactium				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Galactium", bFixedSizeMedium = true},
		Novacite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Novacite", bFixedSizeMedium = true},
		StandardRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:StandardRelic", bFixedSizeMedium = true},
		AcceleratedRelic		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:AcceleratedRelic", bFixedSizeMedium = true},
		AdvancedRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:AdvancedRelic", bFixedSizeMedium = true},
		DynamicRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:DynamicRelic", bFixedSizeMedium = true},
		KineticRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:KineticRelic", bFixedSizeMedium = true},
		AlgorocTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},		
		CelestionTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},		
		DeraduneTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},
		EllevarTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},
		GalerasTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:IronbarkWood", bFixedSizeMedium = true},
		AuroriaTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:IronbarkWood", bFixedSizeMedium = true},
		WhitevaleTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		DreadmoorTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		FarsideTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		CoralusTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		MurkmireTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		WilderrunTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		MalgraveTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		HalonRingTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		GrimvaultTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		SettlerResource			= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconSettler", bFixedSizeMedium = true},
		ScientistScan			= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconScientist", bFixedSizeMedium = true},
		ExplorerInterest		= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconExplorer", bFixedSizeMedium = true},
		ExplorerTrailblazer		= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconExplorer", bFixedSizeMedium = true, crObject=CColor.new(1.0, 0.0, 0.0, 1.0)},
		LoreBook				= { nOrder = 100, 	objectType = self.eObjectTypeLore,				strIcon = "CRB_HUDAlerts:sprAlert_BookBase", bFixedSizeMedium = true, bAboveOverlay = true, bNeverShowOnEdge = true},
		LoreDatacube			= { nOrder = 100, 	objectType = self.eObjectTypeLore,				strIcon = "GMM_OtherSprites:MinimapDatacube", bFixedSizeMedium = true, bAboveOverlay = true, bNeverShowOnEdge = true},
		QuestCritter			= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true },
		QuestCritterNeutral		= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true, crObject = ApolloColor.new("xkcdBrightYellow") },
		QuestCritterHostile		= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true, crObject = ApolloColor.new("xkcdBrightRed") },
		QuestItemTarget			= { nOrder = 6,		objectType = self.eObjectTypeQuestItem, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true },
		FlaggedPC				= { nOrder = 150,	objectType = self.eObjectTypePC, 				strIcon = "GMM_OtherSprites:GMM_EnemyPC", crObject = ApolloColor.new("xkcdBrightRed") },
		UnflaggedPC				= { nOrder = 150,	objectType = self.eObjectTypePC, 				strIcon = "GMM_OtherSprites:GMM_EnemyPC", crObject = ApolloColor.new("xkcdBrightYellow") }
	}
end

function GuardMiniMap:Init()
	Apollo.RegisterAddon(self)
	-- Moving this event register into the init to make sure no latency spikes or load delay will
	-- cause us to miss units
	Apollo.RegisterEventHandler("UnitCreated", 							"OnUnitCreated", self)
end

function GuardMiniMap:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("guardminimap.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function GuardMiniMap:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	
	Apollo.RegisterEventHandler("CharacterCreated", 					"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("OptionsUpdated_QuestTracker", 			"OnOptionsUpdated", self)
	Apollo.RegisterEventHandler("VarChange_ZoneName", 					"OnChangeZoneName", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 						"OnChangeZoneName", self)

	Apollo.RegisterEventHandler("QuestObjectiveUpdated", 				"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("QuestStateChanged", 					"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("GenericEvent_QuestTrackerRenumbered", 	"OnQuestStateChanged", self)

	Apollo.RegisterEventHandler("FriendshipAdd", 						"OnFriendshipAdd", self)
	Apollo.RegisterEventHandler("FriendshipRemove", 					"OnFriendshipRemove", self)
	Apollo.RegisterEventHandler("FriendshipAccountFriendsRecieved",  	"OnFriendshipAccountFriendsRecieved", self)
	Apollo.RegisterEventHandler("FriendshipAccountFriendRemoved",   	"OnFriendshipAccountFriendRemoved", self)

	Apollo.RegisterEventHandler("ReputationChanged",   					"OnReputationChanged", self)

	Apollo.RegisterEventHandler("TargetUnitChanged", 					"OnTargetChanged", self)

	Apollo.RegisterEventHandler("UnitDestroyed", 						"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitActivationTypeChanged", 			"OnUnitChanged", self)
	Apollo.RegisterEventHandler("UnitMiniMapMarkerChanged", 			"OnUnitChanged", self)

	Apollo.RegisterEventHandler("ChallengeAbandon",						"OnChallengeAbandon", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", 					"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeFailTime", 					"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeFailGeneric", 				"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeAbandonConfirmed", 			"OnRemoveChallengeIcon", self)
	Apollo.RegisterEventHandler("ChallengeActivate", 					"OnAddChallengeIcon", self)
	Apollo.RegisterEventHandler("ChallengeCompleted", 					"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("ChallengeFlashStartLocation", 			"OnFlashChallengeIcon", self)

	Apollo.RegisterEventHandler("PlayerPathMissionActivate", 			"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 				"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionDeactivate", 			"OnPlayerPathMissionDeactivate", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapStarted", 	"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapFailed", 	"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PublicEventStart", 					"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", 			"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("PublicEventEnd", 						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLeave",						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLocationAdded", 			"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventLocationRemoved", 			"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveLocationAdded", 	"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveLocationRemoved", 	"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("NavPointCleared",						"OnNavPointCleared", self)
	Apollo.RegisterEventHandler("NavPointSet",							"OnNavPointSet", self)

	Apollo.RegisterEventHandler("CityDirectionMarked",					"OnCityDirectionMarked", self)
	Apollo.RegisterEventHandler("ZoneMap_TimeOutCityDirectionEvent",	"OnZoneMap_TimeOutCityDirectionEvent", self)

	Apollo.RegisterEventHandler("MapGhostMode", 						"OnMapGhostMode", self)
	Apollo.RegisterEventHandler("ToggleGhostModeMap",					"OnToggleGhostModeMap", self) -- for key input toggle on/off
	Apollo.RegisterEventHandler("HazardShowMinimapUnit", 				"OnHazardShowMinimapUnit", self)
	Apollo.RegisterEventHandler("HazardRemoveMinimapUnit", 				"OnHazardRemoveMinimapUnit", self)
	Apollo.RegisterEventHandler("ZoneMapPing", 							"OnMapPing", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 					"OnUnitPvpFlagsChanged", self)

	Apollo.RegisterTimerHandler("TimeUpdateTimer", 						"OnUpdateTimer", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences", 		"OnUpdateTimer", self)

	Apollo.RegisterEventHandler("PlayerLevelChange",					"UpdateHarvestableNodes", self)

	Apollo.RegisterTimerHandler("ChallengeFlashIconTimer", 				"OnStopChallengeFlashIcon", self)
	Apollo.RegisterTimerHandler("OneSecTimer",							"OnOneSecTimer", self)  
	
	-- Adding a taxi hook to be able to refresh the map after landing
	Apollo.RegisterEventHandler("TaxiWindowClose", 						"OnTaxiWindowClose", self)
	
	Apollo.RegisterTimerHandler("PingTimer",							"OnPingTimer", self)
	Apollo.CreateTimer("PingTimer", 1, false)
	Apollo.StopTimer("PingTimer")

	--Group Events
	Apollo.RegisterEventHandler("Group_Join", 							"OnGroupJoin", self)					-- ()
	Apollo.RegisterEventHandler("Group_Add", 							"OnGroupAdd", self)						-- ( name )
	Apollo.RegisterEventHandler("Group_Remove", 						"OnGroupRemove", self)					-- ( name, result )
	Apollo.RegisterEventHandler("Group_Left", 							"OnGroupLeft", self)					-- ( reason )
	Apollo.RegisterEventHandler("Group_UpdatePosition", 				"OnGroupUpdatePosition", self)			-- ( arMembers )

	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)
	
	Apollo.LoadSprites("GMM_FarmingSprites.xml") 	
	Apollo.LoadSprites("GMM_MiningSprites.xml") 
	Apollo.LoadSprites("GMM_RelicSprites.xml") 
	Apollo.LoadSprites("GMM_SurvivalSprites.xml") 
	Apollo.LoadSprites("GMM_OtherSprites.xml") 
	

	if (self.bSquareMap ~= nil  and self.bSquareMap == true)  then
		if (self.bHideCompass ~= nil  and self.bHideCompass == true) then
			Apollo.LoadSprites("SquareMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("SquareMapTextures.xml")
		end
	else
		if (self.bHideCompass ~= nil  and self.bHideCompass == true) then
			Apollo.LoadSprites("CircleMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("CircleMapTextures.xml")
		end
	end
		
	if self.bCustomPlayerArrow ~= nil and self.bCustomPlayerArrow == true then
		Apollo.LoadSprites("GMM_CustomPlayerArrow.xml")
	end
	
	if self.bSquareMap ~= nil and self.bSquareMap == true then	
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "SquareMinimap", "FixedHudStratum", self)
	else
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "Minimap", "FixedHudStratum", self)
	end
	
	if self.nMapOpacity then
		self.wndMain:SetOpacity(self.nMapOpacity)
	else
		self.nMapOpacity = 1.0
	end

	self.wndMiniMap 		= self.wndMain:FindChild("MapContent")
	self.wndZoneName 		= self.wndMain:FindChild("MapZoneName")
	self.wndPvPFlagName 	= self.wndMain:FindChild("MapZonePvPFlag")
	self.wndRangeLabel 		= self.wndMain:FindChild("RangeToTargetLabel")
	self:UpdateZoneName(GetCurrentZoneName())
	self.wndMinimapButtons 	= self.wndMain:FindChild("ButtonContainer")
	
	if self.strMapFont then
		self.wndZoneName:SetFont( self.strMapFont or "CRB_InterfaceSmall_O" )
		self.wndPvPFlagName:SetFont( self.strMapFont or "CRB_InterfaceSmall_O")
	end
	
	if self.fSavedZoomLevel then
		self.wndMiniMap:SetZoomLevel( self.fSavedZoomLevel)
	end
	
	self.wndMiniMapCoords = Apollo.LoadForm(self.xmlDoc , "MinimapCoords", nil, self)
	self.wndMiniMapCoords:Show(false)
	
	self.wndMinimapOptions 	= Apollo.LoadForm(self.xmlDoc , "MinimapOptions", nil, self)
	self.wndMinimapOptions:Show(false)
		
	if self.bCustomQuestArrow ~= nil  and self.bCustomQuestArrow == true then
		self.wndMinimapOptions:FindChild("OptionsBtnCustomQuestArrow"):SetCheck(true)
	end
		
	if self.bCustomPlayerArrow ~= nil  and self.bCustomPlayerArrow == true then
		self.wndMinimapOptions:FindChild("OptionsBtnCustomPlayerArrow"):SetCheck(true)
	end

	
	if self.bShowCoords ~= nil and self.bShowCoords == true then
		self.wndMiniMapCoords:Show(true)
	else
		self.bShowCoords = false
	end
	
	if self.bShowTime ~= nil and self.bShowTime == false then
		self.wndMain:FindChild("Time"):Show(false)
	else
		self.bShowTime = true
	end
	
	if self.bHideCoordFrame ~= nil and self.bHideCoordFrame == true then
		self.wndMiniMapCoords:RemoveStyle("Border")
	end
	
	if self.bRotateMap ~= nil  and self.bRotateMap == true then
		self.wndMinimapOptions:FindChild("OptionsBtnRotate"):SetCheck(true)
		self.wndMiniMap:SetMapOrientation(2)
	end
	

	if self.bSquareMap ~= nil and self.bSquareMap == true then
		self.wndMinimapOptions:FindChild("OptionsBtnsSquareMap"):SetCheck(true)

	else	
		self.wndMinimapOptions:FindChild("OptionsBtnsSquareMap"):SetCheck(false)
	end
	

	if self.bHideCompass ~= nil and self.bHideCompass == true then
		self.wndMinimapOptions:FindChild("OptionsBtnHideCompass"):SetCheck(true)
	else
		self.wndMinimapOptions:FindChild("OptionsBtnHideCompass"):SetCheck(false)
		self.bHideCompass = false
	end

	if not self.bHideFrame or self.bHideFrame == false then
		self.wndMinimapOptions:FindChild("OptionsBtnHideFrame"):SetCheck(false)

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(true)
		end

		self.bHideFrame = false
	else
		self.wndMinimapOptions:FindChild("OptionsBtnHideFrame"):SetCheck(true)

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(false)
		end
	end

	
	if GameLib.GetPlayerUnit() and GameLib.GetPlayerUnit():IsValid() then
		self.nFactionId = GameLib.GetPlayerUnit():GetFaction()
	end
	
	if not self.strMapFont then
		self.strMapFont = "CRB_InterfaceSmall_O"
	end

	local NonMinimapOptions = Apollo.GetPackage("GMM:NonMinimapOptions-1.1").tPackage
	NonMinimapOptions:Initialize()

	GuardWaypoints = Apollo.GetPackage("GMM:GuardWaypoints-1.7").tPackage

	Apollo.RegisterEventHandler("GuardWaypoints_WaypointAdded",			"OnGuardWaypointAdded", self)
	Apollo.RegisterEventHandler("GuardWaypoints_DefaultColorSet",		"OnGuardWaypointColorSet", self)

	if self.tGuardWaypoints == nil then
		self.tGuardWaypoints = {}
	else
		self.WaypointTimer = ApolloTimer.Create(1.0, false, "InitializeWaypoints", self)
	end

	self.wndMain:FindChild("MapMenuButton"):AttachWindow(self.wndMinimapOptions)

	self.wndMain:SetSizingMinimum(150, 150)
	self.wndMain:SetSizingMaximum(1000, 1000)

	self.wndMegaMapBtnOverlay 	= self.wndMain:FindChild("MapToggleBtnOverlay")
	self.wndMegaMapBtnOverlay:Show(false)

	self:CreateOverlayObjectTypes() -- ** IMPORTANT ** This function must run before you do anything involving overlay types!
	self:BuildCustomMarkerInfo()

	self.tChallengeObjects 			= {}
	self.ChallengeFlashingIconId 	= nil

	self.tObjectsShown 				= {} -- For Challenges which use their own events
	self.tObjectsShown.Challenges 	= {}
	self.tPingObjects 				= {}
	self.arResourceNodes			= {}

	self.tGroupMembers 			= {}
	self.tGroupMemberObjects 	= {}
	
	if not self.tQueuedUnits then
		self.tQueuedUnits = {}--necessary when characters don't have a saved file for minimap
	else
		for idx, unit in pairs(self.tQueuedUnits) do
			self.HandleUnitCreated(unit)
		end
	end
	
	if not self.tUnitsAll then	
		self.tUnitsAll = {}	
	end
	
	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition ~= nil then
		self:OnCharacterCreated()
	end

	if not self.tToggledIcons then
		self.tToggledIcons =
		{
			[self.eObjectTypeHostile] 						= true,
			[self.eObjectTypeNeutral] 						= true,
			[self.eObjectTypeGroupMember] 					= true,
			[self.eObjectTypeQuestReward]					= true,
			[self.eObjectTypeVendor] 						= true,
			[self.eObjectTypeGuard]							= true,
			[self.eObjectTypeBindPointActive] 				= true,
			[self.eObjectTypeInstancePortal] 				= true,
			[self.eObjectTypePublicEvent] 					= true,
			[self.eObjectTypeQuestTarget]					= true, 
			[GameLib.CodeEnumMapOverlayType.QuestObjective] = true,
			[GameLib.CodeEnumMapOverlayType.PathObjective] 	= true,
			[self.eObjectTypeChallenge] 					= true,
			[self.eObjectTypeMiningNode] 					= true,
			[self.eObjectTypeRelicHunterNode] 				= true,
			[self.eObjectTypeSurvivalistNode] 				= true,
			[self.eObjectTypeFarmingNode] 					= true,
			[self.eObjectTypeTradeskills] 					= true,
			[self.eObjectTypeTrainer] 						= true,
			[self.eObjectTypeFriend] 						= true,
			[self.eObjectTypeRival] 						= true,
			[self.eObjectTypeEliteHostile]					= true,
			[self.eObjectTypeEliteNeutral]					= true,
			[self.eObjectTypeUniqueFarming]					= true,
			[self.eObjectTypeUniqueMining]					= true,
			[self.eObjectTypeUniqueRelic]					= true,
			[self.eObjectTypeUniqueSurvival]				= true,
			[self.eObjectTypePathResource]					= true,
			[self.eObjectTypeLore]							= true,
			[self.eObjectTypeQuestItem]						= true,
			[self.eObjectTypeQuestCritter]					= false,
			[self.eObjectTypePC]							= false

		}
	end
	
	self:ReloadPublicEvents()
	self:ReloadMissions()
	self:OnQuestStateChanged()
	
	
	
	local tUIElementToType =
	{
		["OptionsBtnQuests"] 			= self.eObjectTypeQuestReward,
		["OptionsBtnTracked"] 			= GameLib.CodeEnumMapOverlayType.QuestObjective,
		["OptionsBtnMissions"] 			= GameLib.CodeEnumMapOverlayType.PathObjective,
		["OptionsBtnChallenges"] 		= self.eObjectTypeChallenge,
		["OptionsBtnPublicEvents"] 		= self.eObjectTypePublicEvent,
		["OptionsBtnVendors"] 			= self.eObjectTypeVendor,
		["OptionsBtnInstancePortals"] 	= self.eObjectTypeInstancePortal,
		["OptionsBtnBindPoints"] 		= self.eObjectTypeBindPointActive,
		["OptionsBtnMiningNodes"] 		= self.eObjectTypeMiningNode,
		["OptionsBtnRelicNodes"] 		= self.eObjectTypeRelicHunterNode,
		["OptionsBtnSurvivalistNodes"] 	= self.eObjectTypeSurvivalistNode,
		["OptionsBtnFarmingNodes"] 		= self.eObjectTypeFarmingNode,
		["OptionsBtnTradeskills"] 		= self.eObjectTypeTradeskills,
		["OptionsBtnCreaturesN"] 		= self.eObjectTypeNeutral,
		["OptionsBtnCreaturesH"] 		= self.eObjectTypeHostile,
		["OptionsBtnTrainer"] 			= self.eObjectTypeTrainer,
		["OptionsBtnFriends"]			= self.eObjectTypeFriend,
		["OptionsBtnRivals"] 			= self.eObjectTypeRival,
		["OptionsBtnGuards"]			= self.eObjectTypeGuard,
		["OptionsBtnEliteH"]			= self.eObjectTypeEliteHostile,
		["OptionsBtnEliteN"]			= self.eObjectTypeEliteNeutral,
		["OptionsBtnUniqueFarming"]		= self.eObjectTypeUniqueFarming,
		["OptionsBtnUniqueMining"]		= self.eObjectTypeUniqueMining,
		["OptionsBtnUniqueRelic"]		= self.eObjectTypeUniqueRelic,
		["OptionsBtnUniqueSurvival"]	= self.eObjectTypeUniqueSurvival,
		["OptionsBtnPathResources"]		= self.eObjectTypePathResource,
		["OptionsBtnLoreItems"]			= self.eObjectTypeLore,
		["OptionsBtnQuestItems"]		= self.eObjectTypeQuestItem,
		["OptionsBtnEnemyPC"]			= self.eObjectTypePC,
		["OptionsBtnQuestCritters"]		= self.eObjectTypeQuestCritter
	}

	local wndOptionsWindow = self.wndMinimapOptions:FindChild("MapOptionsWindow")
	for strWindowName, eType in pairs(tUIElementToType) do
		local wndOptionsBtn = wndOptionsWindow:FindChild(strWindowName)
		wndOptionsBtn:SetData(eType)
		wndOptionsBtn:SetCheck(self.tToggledIcons[eType])
	end

	if g_wndTheMiniMap == nil then
		g_wndTheMiniMap = self.wndMiniMap
	end
	
	self:UpdateRapidTransportBtn()
	self:OnOptionsUpdated()
	self:OnWindowManagementReady()

	-- scsc: buttons always shown
	if self.bSquareMap then
		local tDispSize = Apollo.GetDisplaySize()
		local dispWidth = tDispSize["nWidth"]
		local dispHeight = tDispSize["nHeight"]
		local x,y = self.wndMain:GetPos()
		local tButtonsLocation = self.wndMain:FindChild("ButtonContainer"):GetLocation():ToTable()
		if y > dispHeight / 2.5 then
			self.wndMain:FindChild("ButtonContainer"):SetAnchorPoints(tButtonsLocation.fPoints[1], 0, tButtonsLocation.fPoints[3], 0)
			self.wndMain:FindChild("ButtonContainer"):SetAnchorOffsets(tButtonsLocation.nOffsets[1], -15, tButtonsLocation.nOffsets[3], 25)
		else
			self.wndMain:FindChild("ButtonContainer"):SetAnchorPoints(tButtonsLocation.fPoints[1], 1, tButtonsLocation.fPoints[3], 1)
			self.wndMain:FindChild("ButtonContainer"):SetAnchorOffsets(tButtonsLocation.nOffsets[1], -25, tButtonsLocation.nOffsets[3], 15)
		end
	end

	self.wndMain:FindChild("ZoomInButton"):Show(true)
	self.wndMain:FindChild("ZoomOutButton"):Show(true)
	self.wndMain:FindChild("MapToggleBtn"):Show(true)
	self.wndMain:FindChild("MapMenuButton"):Show(true)

	if self.bOnArkship == nil or self.bOnArkship == false then
		self.wndMain:FindChild("RapidTransportBtnOverlay"):Show(true)
	end

	if self.wndMain:FindChild("MiniMapResizeArtForPixie") then
		self.wndMain:FindChild("MiniMapResizeArtForPixie"):Show(true)
	end
end

function GuardMiniMap:OnCharacterCreated()
	self:UpdateRapidTransportBtn()	
	Apollo.CreateTimer("TimeUpdateTimer", 1.0, true)
	
	if(not self.unitPlayerDisposition ) then
		self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	end
	local ePath = self.unitPlayerDisposition:GetPlayerPathType()

	if ePath == PlayerPathLib.PlayerPathType_Soldier then
		self.wndMinimapOptions:FindChild("Image_Soldier"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Explorer then
		self.wndMinimapOptions:FindChild("Image_Explorer"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Scientist then
		self.wndMinimapOptions:FindChild("Image_Scientist"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Settler then
		self.wndMinimapOptions:FindChild("Image_Settler"):Show(true)
	end
end

function GuardMiniMap:OnOptionsUpdated()
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance ~= nil then
		self.bQuestTrackerByDistance = g_InterfaceOptions.Carbine.bQuestTrackerByDistance
	else
		self.bQuestTrackerByDistance = true
	end

	self:OnQuestStateChanged()
end

function GuardMiniMap:OnUpdateTimer()

	--Toggle Visibility based on ui preference
	local nVisibility = Apollo.GetConsoleVariable("hud.TimeDisplay")
	
	local tLocalTime = GameLib.GetLocalTime()
	local tServerTime = GameLib.GetServerTime()
	local b24Hour = true
	local nLocalHour = tLocalTime.nHour > 12 and tLocalTime.nHour - 12 or tLocalTime.nHour == 0 and 12 or tLocalTime.nHour
	local nServerHour = tServerTime.nHour > 12 and tServerTime.nHour - 12 or tServerTime.nHour == 0 and 12 or tServerTime.nHour
		
	self.wndMain:FindChild("Time"):SetText(string.format("%02d:%02d", tostring(tLocalTime.nHour), tostring(tLocalTime.nMinute)))
	
	if nVisibility == 2 then --Local 12hr am/pm
		self.wndMain:FindChild("Time"):SetText(string.format("%02d:%02d", tostring(nLocalHour), tostring(tLocalTime.nMinute)))
		
		b24Hour = false
	elseif nVisibility == 3 then --Server 24hr
		self.wndMain:FindChild("Time"):SetText(string.format("%02d:%02d", tostring(tServerTime.nHour), tostring(tServerTime.nMinute)))
	elseif nVisibility == 4 then --Server 12hr am/pm
		self.wndMain:FindChild("Time"):SetText(string.format("%02d:%02d", tostring(nServerHour), tostring(tServerTime.nMinute)))
		
		b24Hour = false
	end
	
	nLocalHour = b24Hour and tLocalTime.nHour or nLocalHour
	nServerHour = b24Hour and tServerTime.nHour or nServerHour
	
	self.wndMain:FindChild("Time"):SetTooltip(
		string.format("%s%02d:%02d\n%s%02d:%02d", 
			Apollo.GetString("OptionsHUD_Local"), tostring(nLocalHour), tostring(tLocalTime.nMinute),
			Apollo.GetString("OptionsHUD_Server"), tostring(nServerHour), tostring(tServerTime.nMinute)
		)
	)
end


---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Account then
		local tAllUnits = {}
	
		if self.tUnitsAll then
			for idUnit, unit in pairs(self.tUnitsAll) do
				tAllUnits[idUnit] = idUnit
			end
		end
	
		local tSavedData =
		{
			fZoomLevel = self.wndMiniMap:GetZoomLevel(),
			tToggled = self.tToggledIcons,
			tSavedAllUnits = tAllUnits,
			tHideCompass = self.bHideCompass,
			tSquareMap = self.bSquareMap,
			bCustomQuestArrow = self.bCustomQuestArrow,
			bHideFrame = self.bHideFrame,
			bShowCoords = self.bShowCoords,
			bHideCoordFrame = self.bHideCoordFrame, 
			bShowTaxisOnZoneMap = self.bShowTaxisOnZoneMap,
			nMapOpacity = self.nMapOpacity,
			bRotateMap = self.bRotateMap,
			bCustomPlayerArrow = self.bCustomPlayerArrow,
			strMapFont = self.strMapFont,
			bShowTime = self.bShowTime
		}

		return tSavedData

	elseif eType == GameLib.CodeEnumAddonSaveLevel.Character then	
		local tSavedData =
		{
			tSavedWaypoints = g_tGuardWaypoints,
			tSavedColor = self.tDefaultColor
		}

		return tSavedData
	end
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData
	if eType == GameLib.CodeEnumAddonSaveLevel.Account then
		if tSavedData.fZoomLevel then
			self.fSavedZoomLevel = tSavedData.fZoomLevel
		end

		if tSavedData.tToggled then
			self.tToggledIcons = tSavedData.tToggled
		end
	
		if tSavedData.tSquareMap then
			self.bSquareMap = tSavedData.tSquareMap
		end
	
		if tSavedData.bHideFrame then
			self.bHideFrame = tSavedData.bHideFrame
		end
	
		if tSavedData.tHideCompass then
			self.bHideCompass = tSavedData.tHideCompass
		end
	
		if tSavedData.bShowCoords then
			self.bShowCoords = tSavedData.bShowCoords
		end
		
		if tSavedData.bShowTime ~= nil then
			self.bShowTime = tSavedData.bShowTime
		else
			self.bShowTime = false
		end
	
		if tSavedData.bRotateMap then
			self.bRotateMap = tSavedData.bRotateMap
		end
	
		if tSavedData.bHideCoordFrame then
			self.bHideCoordFrame = tSavedData.bHideCoordFrame
		end
	
		if tSavedData.bShowTaxisOnZoneMap then
			self.bShowTaxisOnZoneMap = tSavedData.bShowTaxisOnZoneMap
		end
	
		if tSavedData.nMapOpacity then
			self.nMapOpacity = tSavedData.nMapOpacity 
		end
	
		if tSavedData.bCustomQuestArrow then
			self.bCustomQuestArrow = tSavedData.bCustomQuestArrow
		end	
		
		if tSavedData.bCustomPlayerArrow then
			self.bCustomPlayerArrow = tSavedData.bCustomPlayerArrow
		end
		
		if tSavedData.strMapFont then
			self.strMapFont = tSavedData.strMapFont
		else
			self.strMapFont = "CRB_InterfaceSmall_O"
		end

		if not self.tQueuedUnits then
			self.tQueuedUnits = {}
		end

		if not self.tUnitsAll then
			self.tUnitsAll = {}
		end
	
		if tSavedData.tSavedAllUnits then
			for idx, idUnit in pairs(tSavedData.tSavedAllUnits) do
				local unitAll = GameLib.GetUnitById(idUnit)
				if unitAll and unitAll:IsValid() then
					self.tUnitsAll[idUnit] = unitAll
					self.tQueuedUnits[idUnit] = unitAll
				end
			end
		end

	elseif eType == GameLib.CodeEnumAddonSaveLevel.Character then	

		if tSavedData.tSavedWaypoints then
			self.tGuardWaypoints = tSavedData.tSavedWaypoints
		end

		if tSavedData.tSavedColor then
			self.tDefaultColor = tSavedData.tSavedColor
		end
	end
end

function GuardMiniMap:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", { wnd = self.wndMain, strName = "Guard Mini Map"})	
	Event_FireGenericEvent("WindowManagementRegister", { wnd = self.wndMiniMapCoords, strName = "Guard Mini Map - Coords"})	
	--Event_FireGenericEvent("WindowManagementRegister", { wnd = self.wndMinimapOptions , strName = "Guard Mini Map - Options"})
	
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = "Guard Mini Map"})
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMiniMapCoords, strName = "Guard Mini Map - Coords"})	
	--Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMinimapOptions , strName = "Guard Mini Map - Options"})
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:ReloadMissions()
	--self.wndMiniMap:RemoveObjectsByType(GameLib.CodeEnumMapOverlayType.PathObjective)
	local epiCurrent = PlayerPathLib.GetCurrentEpisode()
	if epiCurrent then
		for idx, pmCurr in ipairs(epiCurrent:GetMissions()) do
			self:OnPlayerPathMissionActivate(pmCurr)
		end
	end
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnChangeZoneName(oVar, strNewZone)
	self:UpdateZoneName(strNewZone)
	
	self:UpdateRapidTransportBtn()
	
	self:RefreshMap()
end

function GuardMiniMap:DelayRefreshMap()

	-- Depending on the speed of your system, the call from ChallengeCompleted
	-- to refresh map can finish before the system registers the entire challenge is 
	-- completed, this delay resolves that issue
	if not self.RefreshTimer then
		self.RefreshTimer = ApolloTimer.Create(1, false, "RefreshMap", self)
	end

end

function GuardMiniMap:RefreshMap()
	if self.wndMiniMap == nil or self.tToggledIcons == nil then
		return
	end

	-- update mission indicators
	self:ReloadMissions()

	-- update quest indicators
	 self:UpdateQuestMarkers()

	-- update public events
	self:ReloadPublicEvents()
	
	-- update all already shown units
  	if self.tUnitsAll then
		for idx, tCurrUnit in pairs(self.tUnitsAll) do
			if tCurrUnit then
				self.wndMiniMap:RemoveUnit(tCurrUnit)
				-- Switching to use the base idx in case the tCurrUnit has become invalid
				-- or lost its ID
				self.tUnitsAll[idx] = nil
				self:OnUnitCreated(tCurrUnit)
			end
		end
	end
	
	self:DrawGroupMembers()

	for idx, tCurWaypoint in ipairs(g_tGuardWaypoints) do
		tCurWaypoint:AddToMinimap(self.eObjectTypeGuardWaypoint)
	end
	
	if self.RefreshTimer then
		self.RefreshTimer = nil
	end

	self:OnOneSecTimer()

end

function GuardMiniMap:UpdateZoneName(strZoneName)
	if strZoneName == nil then
		return
	end

	local tInstanceSettingsInfo = GameLib.GetInstanceSettings()

	local strDifficulty = nil
	if tInstanceSettingsInfo.eWorldDifficulty == GroupLib.Difficulty.Veteran then
		strDifficulty = ktInstanceSettingTypeStrings.Veteran
	end

	local strScaled = nil
	if tInstanceSettingsInfo.bWorldForcesLevelScaling == true then
		strScaled = ktInstanceSettingTypeStrings.Rallied
	end

	local strAdjustedZoneName = strZoneName
	if strDifficulty and strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. "-" .. strScaled .. ")"
	elseif strDifficulty then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. ")"
	elseif strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strScaled .. ")"
	end

	self.wndZoneName:SetText(strAdjustedZoneName)
	self:UpdatePvpFlag()
end

function GuardMiniMap:OnUnitPvpFlagsChanged(unitChanged)
	if not unitChanged:IsThePlayer() then
		return
	end
	self:UpdatePvpFlag()
end

function GuardMiniMap:UpdatePvpFlag()
	local nZoneRules = GameLib.GetCurrentZonePvpRules()

	if GameLib.IsPvpServer() == true then
		self.wndPvPFlagName:Show(true)
	else
		self.wndPvPFlagName:Show(nZoneRules ~= GameLib.CodeEnumZonePvpRules.DominionPVPStronghold and nZoneRules ~= GameLib.CodeEnumZonePvpRules.ExilePVPStronghold)
	end

	self.wndPvPFlagName:SetText(ktPvPZoneTypes[nZoneRules] or "")
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnMenuBtn()
	if self.wndMinimapOptions:IsVisible() then
		self.wndMinimapOptions:Show(false)
	else
		self.wndMinimapOptions:Show(true)
		self.wndMain:ToFront()
		self.wndMinimapOptions:ToFront()
	end
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnMenuBtnToggle(wndHandler, wndControl)

local tDispSize = Apollo.GetDisplaySize()
local dispWidth = tDispSize["nWidth"]
local dispHeight = tDispSize["nHeight"]
local x,y = self.wndMain:GetPos()
local tWndLocation = self.wndMinimapOptions:GetLocation():ToTable()

if x > dispWidth / 2 then
	tWndLocation.nOffsets[1] = -469
	tWndLocation.nOffsets[3] = -19
else	
	tWndLocation.nOffsets[1] = -129
	tWndLocation.nOffsets[3] = 321
end

if y > dispHeight / 2.5 then
	tWndLocation.nOffsets[2] = -629
	tWndLocation.nOffsets[4] = -22
else
	tWndLocation.nOffsets[2] = -22	
	tWndLocation.nOffsets[4] = 585
end

--self.wndMinimapOptions:MoveToLocation(tWndLocation)		
self.wndMinimapOptions:SetAnchorOffsets(tWndLocation.nOffsets[1], tWndLocation.nOffsets[2], tWndLocation.nOffsets[3], tWndLocation.nOffsets[4])

	if wndControl:IsChecked() then
		local bIsMiner, bIsRelicHunter, bIsSurvivalist, bIsFarmer = false, false, false, false
		
		for idx, tTradeskill in pairs(CraftingLib.GetKnownTradeskills() or {}) do
	
			local tTradeskillInfo = CraftingLib.GetTradeskillInfo(tTradeskill.eId)
			
			if (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Mining) and tTradeskillInfo.bIsActive then
				bIsMiner = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Relic_Hunter) and tTradeskillInfo.bIsActive then
				bIsRelicHunter = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Survivalist) and tTradeskillInfo.bIsActive then
				bIsSurvivalist = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Farmer) and tTradeskillInfo.bIsActive then
				bIsFarmer = true
			end
		
		end
		
		self.wndMinimapOptions:FindChild("OptionsBtnMiningNodes"):Enable(bIsMiner)
		self.wndMinimapOptions:FindChild("OptionsBtnRelicNodes"):Enable(bIsRelicHunter)
		self.wndMinimapOptions:FindChild("OptionsBtnSurvivalistNodes"):Enable(bIsSurvivalist)
		self.wndMinimapOptions:FindChild("OptionsBtnFarmingNodes"):Enable(bIsFarmer)
	end

	self.wndMinimapOptions:Show(wndControl:IsChecked())
end

---------------------------------------------------------------------------------------------------
--Options
---------------------------------------------------------------------------------------------------

function GuardMiniMap:OnMinusBtn()
	self.wndMiniMap:ZoomOut()
	Sound.Play(Sound.PlayUI15ZoomOutPhysical)
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnPlusBtn()
	self.wndMiniMap:ZoomIn()
	Sound.Play(Sound.PlayUI14ZoomInPhysical)
end

function GuardMiniMap:OnMapToggleBtn()
	Event_FireGenericEvent("ToggleZoneMap")
end

function GuardMiniMap:OnMapGhostMode(bMode) -- Turn on/off the ghost mode notice
	self.wndMegaMapBtnOverlay:Show(bMode)
end

function GuardMiniMap:OnToggleGhostModeMap() -- Turn on/off the ghost mode button (for key input toggle on and off)
	local bShow = not self.wndMegaMapBtnOverlay:IsShown()
	self.wndMegaMapBtnOverlay:Show(bShow)
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnRotateMapCheck()
	--self.wndMinimapOptions:FindChild("OptionsBtnRotate"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLPressed")
	self.bRotateMap = true
	self.wndMiniMap:SetMapOrientation(2)
end

function GuardMiniMap:OnRotateMapUncheck()
	--self.wndMinimapOptions:FindChild("OptionsBtnRotate"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLNormal")
	self.bRotateMap = false
	self.wndMiniMap:SetMapOrientation(0)
end

function GuardMiniMap:OnRangeFinderCheck()
	self.wndMinimapOptions:FindChild("OptionsBtnRange"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLPressed")
	self.bFindRange = true
end

function GuardMiniMap:OnRangeFinderUncheck()
	self.wndMinimapOptions:FindChild("OptionsBtnRange"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLNormal")
	self.bFindRange = false
	self.wndRangeLabel:Show(false)
end

function GuardMiniMap:OnMapPing(idUnit, tPos )

	for idx, tCur in pairs(self.tPingObjects) do
		if tCur.idUnit == idUnit then
			self.wndMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		end
	end

	local tInfo =
	{
		strIcon = "sprMap_PlayerPulseFast",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}

	Sound.Play(Sound.PlayUIMiniMapPing)
	
	table.insert(self.tPingObjects, {["idUnit"] = idUnit, ["objMapPing"] = self.wndMiniMap:AddObject(self.eObjectTypePing, tPos, "", tInfo), ["nTime"] = GameLib.GetGameTime()})
	
	Apollo.StartTimer("PingTimer")

end

function GuardMiniMap:OnPingTimer()

	local nCurTime = GameLib.GetGameTime()
	local nNumUnits = 0
	for idx, tCur in pairs(self.tPingObjects) do
		if (tCur.nTime + 5) < nCurTime then
			self.wndMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		else
			nNumUnits = nNumUnits + 1
		end
	end
		
	if nNumUnits == 0 then
		Apollo.StopTimer("PingTimer")
	else
		Apollo.StartTimer("PingTimer")
	end

end

----------------------------------------------------------------------------------------------
-- Chat commands for range finder option
-----------------------------------------------------------------------------------------------
function GuardMiniMap:OnRangeSlashCommand(cmd, arg1)

end

function GuardMiniMap:OnMouseMove(wndHandler, wndControl, nX, nY)

end

function GuardMiniMap:RemovePing(tPoint)
	local tMapObjects = g_wndTheMiniMap:GetObjectsAtPoint(tPoint.x, tPoint.y)
	if tMapObjects == nil then 
		return 
	end
      
	for idx, tMapObj in ipairs(tMapObjects) do
		if tMapObj.eType == self.eObjectTypePing then
			self.wndMiniMap:RemoveObject(tMapObj.id)
		end
	end
end

function GuardMiniMap:OnMapClick(wndHandler, wndControl, eButton, nX, nY, bDouble)
	local tPoint    = self.wndMiniMap:WindowPointToClientPoint(nX, nY)
	local tWorldLoc = self.wndMiniMap:ClientPointToWorldLoc(tPoint.x, tPoint.y)

	if eButton == 1 and Apollo.IsControlKeyDown() then
		GuardWaypoints:AddNew(tWorldLoc, GameLib.GetCurrentZoneMap(), nil, self.tDefaultColor, false)
		self:RemovePing(tPoint)
	elseif eButton == 1 then
		
		for idx, tCurWaypoint in ipairs(g_tGuardWaypoints) do
			if	tWorldLoc.x >= tCurWaypoint.tWorldLoc.x - 5 and
				tWorldLoc.x <= tCurWaypoint.tWorldLoc.x + 5 and
				tWorldLoc.z >= tCurWaypoint.tWorldLoc.z - 5 and
				tWorldLoc.z <= tCurWaypoint.tWorldLoc.z + 5 then
				
				self:RemovePing(tPoint)
				tCurWaypoint:ShowContextMenu(idx, self.wndMain)
			end
		end
	end
	
end

function GuardMiniMap:OnMouseButtonUp(eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnFailChallenge(tChallengeData)

	if	self.tActiveChallenges then
		self.tActiveChallenges[tChallengeData:GetId()] = nil
	end

	self:OnRemoveChallengeIcon(tChallengeData:GetId())
end

function GuardMiniMap:OnChallengeAbandon(nChalId)

	if	self.tActiveChallenges then
		self.tActiveChallenges[nChalId] = nil
	end

	self:RefreshMap()

end

function GuardMiniMap:OnChallengeCompleted(nChalId)

	if	self.tActiveChallenges then
		self.tActiveChallenges[nChalId] = nil
	end

	self:RefreshMap()

end

function GuardMiniMap:OnRemoveChallengeIcon(chalOwner)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end
	if self.tObjectsShown.Challenges ~= nil then
		for idx, tCurr in pairs(self.tObjectsShown.Challenges) do
			self.wndMiniMap:RemoveObject(idx)
		end
	end
	self.tObjectsShown.Challenges = {}

	self:RefreshMap()
end

function GuardMiniMap:OnAddChallengeIcon(chalOwner, strDescription, tPosition)

	-- Make sure to refresh the map when a challenge begins so the challenge
	-- 'clickies' show up
	if not self.tActiveChallenges then
		self.tActiveChallenges = {}
	end

	self.tActiveChallenges[chalOwner:GetId()] = true
	
	self:RefreshMap()
	
	if self.tChallengeObjects[chalOwner:GetId()] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner:GetId()])
		self.tChallengeObjects[chalOwner:GetId()] = nil

		-- make sure we turn off the flash icon just in case
		self:OnStopChallengeFlashIcon()
	end

	local tInfo =
	{
		strIcon = "MiniMapObject",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_ChallengeArrow",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}
	if tPosition ~= nil then
		if self.tObjectsShown.Challenges == nil then
			self.tObjectsShown.Challenges = {}
		end

		self.tChallengeObjects[chalOwner] = self.wndMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, not self.tToggledIcon[self.eObjectTypeChallenge])
		self.tObjectsShown.Challenges[self.tChallengeObjects[chalOwner]] = {tPosition = tPosition, strDescription = strDescription}
	end
end

function GuardMiniMap:OnFlashChallengeIcon(chalOwner, strDescription, fDuration, tPosition)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end

	if self.tToggledIcons[self.eObjectTypeChallenge] ~= false then
		-- TODO: Need to change the icon to a flashing icon
		local tInfo =
		{
			strIcon 		= "sprMM_QuestZonePulse",
			crObject 		= CColor.new(1, 1, 1, 1),
			strIconEdge 	= "sprMM_PathArrowActive",
			crEdge 			= CColor.new(1, 1, 1, 1),
			bAboveOverlay 	= true,
		}

		self.tChallengeObjects[chalOwner] = self.wndMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, false)
		self.ChallengeFlashingIconId = chalOwner

		-- create the timer to turn off this flashing icon
		Apollo.StopTimer("ChallengeFlashIconTimer")
		Apollo.CreateTimer("ChallengeFlashIconTimer", fDuration, false)
		Apollo.StartTimer("ChallengeFlashIconTimer")
	end
end

function GuardMiniMap:OnStopChallengeFlashIcon()

	if self.ChallengeFlashingIconId and self.tChallengeObjects[self.ChallengeFlashingIconId] then
		self.wndMiniMap:RemoveObject(self.tChallengeObjects[self.ChallengeFlashingIconId])
		self.tChallengeObjects[self.ChallengeFlashingIconId] = nil
	end

	self.ChallengeFlashingIconId = nil
end

---------------------------------------------------------------------------------------------------

function GuardMiniMap:OnPlayerPathMissionActivate(pmActivated)
	if self.tToggledIcons == nil then
		return
	end

	self:OnPlayerPathMissionDeactivate(pmActivated)

	local tInfo =
	{
		strIcon 	= pmActivated:GetMapIcon(),
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	self.wndMiniMap:AddPathIndicator(pmActivated, tInfo, {bNeverShowOnEdge = true, bFixedSizeSmall = false}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.PathObjective])
end

function GuardMiniMap:OnPlayerPathMissionDeactivate(pmDeactivated)
	self.wndMiniMap:RemoveObjectsByUserData(GameLib.CodeEnumMapOverlayType.PathObjective, pmDeactivated)
end

---------------------------------------------------------------------------------------------------

function GuardMiniMap:ReloadPublicEvents()
	local tEvents = PublicEvent.GetActiveEvents()
	for idx, peCurr in ipairs(tEvents) do
		self:OnPublicEventUpdate(peCurr)
	end
end

function GuardMiniMap:OnPublicEventUpdate(peUpdated)
	self:OnPublicEventEnd(peUpdated)

	if not peUpdated:IsActive() or self.tToggledIcons == nil then
		return
	end

	local tInfo =
	{
		strIcon = "sprMM_POI",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_QuestArrowActive",
		crEdge = CColor.new(1, 1, 1, 1),
	}

	for idx, tPos in ipairs(peUpdated:GetLocations()) do
		self.wndMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peUpdated:GetName(), tInfo, {bNeverShowOnEdge = peUpdated:ShouldShowOnMiniMapEdge(), bFixedSizeSmall = false}, not self.tToggledIcons[self.eObjectTypePublicEvent], peUpdated)
	end

	for idx, peoCurr in ipairs(peUpdated:GetObjectives()) do
		self:OnPublicEventObjectiveUpdate(peoCurr)
	end
end

function GuardMiniMap:OnPublicEventEnd(peEnding)
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peEnding)

	for idx, peoCurr in ipairs(peEnding:GetObjectives()) do
		self:OnPublicEventObjectiveEnd(peoCurr)
	end
end

function GuardMiniMap:OnPublicEventObjectiveUpdate(peoUpdated)
	self:OnPublicEventObjectiveEnd(peoUpdated)

	if peoUpdated:GetStatus() ~= PublicEventObjective.PublicEventStatus_Active then
		return
	end

	local tInfo =
	{
		strIcon 	= "sprMM_POI",
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "MiniMapObjectEdge",
		crEdge 		= CColor.new(1,1, 1, 1),
	}

	bHideOnEdge = (peoUpdated:ShouldShowOnMinimapEdge() ~= true)

	for idx, tPos in ipairs(peoUpdated:GetLocations()) do
		self.wndMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peoUpdated:GetShortDescription(), tInfo, {bNeverShowOnEdge = hideOnEdge, bFixedSizeSmall = false}, not self.tToggledIcons[self.eObjectTypePublicEvent], peoUpdated)
	end
end

function GuardMiniMap:OnPublicEventObjectiveEnd(peoUpdated)
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peoUpdated)
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnNavPointCleared()
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() then
		return
	end
	self.wndMiniMap:RemoveObjectsByType(self.eObjectTypeNavPoint)
end

function GuardMiniMap:OnNavPointSet(tLoc)
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() or not tLoc then
		return
	end
	
	local tInfo =
	{
		objectType = self.eObjectTypeNavPoint,
		strIcon = "IconSprites:Icon_MapNode_Map_NavPoint",
		strIconEdge = "sprMM_NavPointArrow",
		strIconAbove = "sprMM_NavPointArrow",
		crEdge = CColor.new(1, 1, 1, 1),
	}
	self.wndMiniMap:RemoveObjectsByType(self.eObjectTypeNavPoint)
	self.wndMiniMap:AddObject(self.eObjectTypeNavPoint, tLoc, "Nav Pt", tInfo, {bOnlyShowOnEdge = false, bFixedSizeMedium = false, bAboveOverlay = true}, false)
end

---------------------------------------------------------------------------------------------------

function GuardMiniMap:OnCityDirectionMarked(tLocInfo)
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() then
		return
	end

	local tInfo =
	{
		strIconEdge = "",
		strIcon 	= "sprMM_QuestTrackedActivate",
		crObject 	= CColor.new(1, 1, 1, 1),
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	-- Only one city direction at a time, so stomp and remove and previous
	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
	self.wndMiniMap:AddObject(self.eObjectTypeCityDirection, tLocInfo.tLoc, tLocInfo.strName, tInfo, {bFixedSizeSmall = false}, false, Apollo.GetString("ZoneMap_CityDirections"))
	Apollo.StartTimer("ZoneMap_TimeOutCityDirectionMarker")
end

function GuardMiniMap:OnZoneMap_TimeOutCityDirectionEvent()
	if not self.wndMiniMap or not self.wndMiniMap:IsValid() then
		return
	end

	self.wndMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnQuestStateChanged()
	self.tEpisodeList = QuestLib.GetTrackedEpisodes(self.bQuestTrackerByDistance)

	self:RefreshMap()
end

function GuardMiniMap:UpdateQuestMarkers()	

	-- Clear episode list
	self.wndMiniMap:RemoveObjectsByType(GameLib.CodeEnumMapOverlayType.QuestObjective)

	-- Iterate over all the episodes adding the active one
	local nCount = 0
	for idx, epiCurr in ipairs(self.tEpisodeList) do

		-- Add entries for each quest in the episode
		for idx2, queCurr in ipairs(epiCurr:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do
			local eQuestState = queCurr:GetState()
			nCount = nCount + 1 -- number the quest

			if queCurr:IsActiveQuest() then
				local tInfo =
				{
					strIcon 	= "ActiveQuestIcon",
					crObject 	= CColor.new(1, 1, 1, 1),
					strIconEdge = "sprMM_QuestArrowActivate",
					crEdge 		= CColor.new(1, 1, 1, 1),
				}
				-- This is a C++ call on the MiniMapWindow class
				self.wndMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bAboveOverlay = true}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])
			elseif not queCurr:IsActiveQuest() and self.tToggledIcons[self.eObjectTypeQuestReward] then
				local tInfo

				if self.bCustomQuestArrow and self.bCustomQuestArrow == true then
					tInfo = 
					{
						strIcon = "sprMM_QuestTracked",
						crObject = CColor.new(1, 1, 1, 1),
						strIconEdge = "GMM_SolidPathArrow",
						crEdge = CColor.new(1, 1, 1, 1),						
						strIconAbove = "IconSprites:Icon_MapNode_Map_QuestMarkerAbove",
						strIconBelow = "IconSprites:Icon_MapNode_Map_QuestMarkerBelow",
					}
				else
					tInfo = 
					{
						strIcon = "sprMM_QuestTracked",
						crObject = CColor.new(1, 1, 1, 1),
						strIconEdge = "sprMM_SolidPathArrow",
						crEdge = CColor.new(1, 1, 1, 1),
						strIconAbove = "IconSprites:Icon_MapNode_Map_QuestMarkerAbove",
						strIconBelow = "IconSprites:Icon_MapNode_Map_QuestMarkerBelow",
					}
				end
				-- This is a C++ call on the MiniMapWindow class
				self.wndMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bFixedSizeMedium = false, bAboveOverlay = true}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

-- There's some weirdness happening with taxis where the minimap is losing
-- content, the UnitCreated is properly called for everything, so this
-- lets me detect when a taxi is taken so I can redraw the map after landing
function GuardMiniMap:OnTaxiWindowClose()
	self.tTaxiTimer = ApolloTimer.Create(1, true, "OnTaxiTimer", self)
end

function GuardMiniMap:OnICCommMessage(channel, strMessage, idMessage) 
	GuardWaypoints:OnICCommMessage(channel, strMessage, idMessage) 
end

function GuardMiniMap:JoinResultEvent(iccomm, eResult)
	GuardWaypoints:JoinResultEvent(iccomm, eResult)
end

function GuardMiniMap:OnICCommSendMessageResult(iccomm, eResult, idMessage)
	GuardWaypoints:OnICCommSendMessageResult(iccomm, eResult, idMessage)
end

function GuardMiniMap:InitializeWaypoints()

	GuardWaypoints:JoinChannel("GuardMiniMap")

	for idx, tCurWaypoint in ipairs(self.tGuardWaypoints) do
		if tCurWaypoint.tColorOverride == nil then
			tCurWaypoint.tColorOverride = { Red = 0, Green = 1, Blue = 0}
		end
		
		GuardWaypoints:AddNew(tCurWaypoint.tWorldLoc, tCurWaypoint.tZoneInfo, tCurWaypoint.strName, tCurWaypoint.tColorOverride, tCurWaypoint.bPermanent)
	end

	self.tGuardWaypoints = {}

end

function GuardMiniMap:OnGuardWaypointAdded(tWaypoint)
	tWaypoint:AddToMinimap(self.eObjectTypeGuardWaypoint)

	--local tInfo =   {
						--strIcon = "sprMM_QuestTracked",
						--crObject = CColor.new(0.5, 1, 0.5, 1),
						--strIconEdge = "GMM_SolidPathArrow",
						--crEdge = CColor.new(1, 1, 1, 1)
					--}
	---- This is a C++ call on the MiniMapWindow class
	--self.wndMiniMap:AddQuestIndicator(nil, "TEMP", tInfo, {bOnlyShowOnEdge = false, bFixedSizeMedium = false, bAboveOverlay = true}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])
end

function GuardMiniMap:OnGuardWaypointColorSet(tDefaultColor)
	self.tDefaultColor = tDefaultColor
end

function GuardMiniMap:OnTaxiTimer()
	if GameLib:GetPlayerTaxiUnit() ~= nil then
		self.bOnTaxi = true
	elseif self.bOnTaxi ~= nil then
		self.tTaxiTimer:Stop()
		self.tTaxiTimer = nil
		self.bOnTaxi = nil
		self:RefreshMap()
	else
		self.tTaxiTimer:Stop()
		self.tTaxiTimer = nil
	end
end

function GuardMiniMap:OnOneSecTimer()
	if GameLib.GetPlayerUnit() and GameLib.GetPlayerUnit():IsValid() then
		local tPlayerPosition = GameLib.GetPlayerUnit():GetPosition()
		self.wndMiniMapCoords:FindChild("lblCoords"):SetText(string.format("%d, %d", tPlayerPosition.x, tPlayerPosition.z))
	else		
		self.wndMiniMapCoords:FindChild("lblCoords"):SetText(string.format("0, 0"))
	end	
	if self.tQueuedUnits == nil then
		return
	end

	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition == nil or not self.unitPlayerDisposition:IsValid() then
		return
	end

	for id,unit in pairs(self.tQueuedUnits) do
		if unit:IsValid() then
			self:HandleUnitCreated(unit)
		end
	end
	
	self.tQueuedUnits = {}
end

function GuardMiniMap:OnTargetChanged(unitNew)
	--if unitNew == nil or not unitNew:IsValid() then
		--return
	--end
--
	--local tAS = unitNew:GetActivationState()
	--
	--local tURI = unitNew:GetRewardInfo()
	--local nRewardCount = self:GetTableLength(tURI)
--
	--Print(nRewardCount)
--
	--if 	tAS ~= nil
		--and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
		--and tURI ~= nil 
		--and ((tAS.Collect ~= nil and tAS.Collect.bCanInteract == true) or (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true)) then
--
	--
	--end
end


function GuardMiniMap:OnUnitCreated(unitNew)
	if self.nNumUnits then
		self.nNumUnits = self.nNumUnits + 1
	else
		self.nNumUnits = 1
	end

	if unitNew == nil or not unitNew:IsValid() or unitNew == GameLib.GetPlayerUnit() then
		return
	end
	
	if not self.tUnitsAll then
		self.tUnitsAll = {}
	end

	if not self.tQueuedUnits then
		self.tQueuedUnits = {}
	end

	self.tUnitsAll[unitNew:GetId()] = unitNew
	self.tQueuedUnits[unitNew:GetId()] = unitNew
end

function GuardMiniMap:GetDefaultUnitInfo()
	local tInfo =
	{
		strIcon = "",
		strIconEdge = "MiniMapObjectEdge",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}
	return tInfo
end

function GuardMiniMap:UpdateHarvestableNodes()
	for idx, unitResource in pairs(self.arResourceNodes) do
		if unitResource:CanBeHarvestedBy(GameLib.GetPlayerUnit()) then
			self:OnUnitChanged(unitResource)
			self.arResourceNodes[unitResource:GetId()] = nil
		end
	end
end

function GuardMiniMap:GetTableLength(curTable)
	local tableLength = 0
	
	if(curTable ~= nil) then
		for key, value in pairs(curTable) do
			tableLength = tableLength + 1
		end
	end
	
	return tableLength 
end

function GuardMiniMap:GetOrderedMarkerInfos(tMarkerStrings, unitNew)
	local tMarkerInfos = {}
	
	-- This is a hack to show explorer trailblazing nodes on the map
--	if self:GetTableLength(tMarkerStrings) == 0 then
--		if 	GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Explorer
--			and self.tToggledIcons[self.eObjectTypePathResource]
--			and unitNew:GetName():find("Explorer Trailblazing Node") then
--					
--			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["ExplorerTrailblazer"])
--		end
--	end
			
	-- Adding logic to allow for displaying Path Resources and Lore items on the minimap
	-- Adding logic to allow for custom "Prime" mob icons to be displayed			
	local tAS = unitNew:GetActivationState()
	local strUnitType = unitNew:GetType()
	local tURI = unitNew:GetRewardInfo()
	local nRewardCount = self:GetTableLength(tURI)
	local eDisposition = unitNew:GetDispositionTo(GameLib.GetPlayerUnit())
	local bActiveChallenge = false
	local bActiveQuestTarget = false
	local bActiveQuestItem = false
	local bShowUnit = unitNew:IsVisibleOnCurrentZoneMinimap()

	if not self.tActiveChallenges then
		self.tActiveChallenges = {}
	end

	-- Only parse through the quest critters if the option is checked
	-- save some processing time for those people who don't want to see them anyway
	if	(self.tToggledIcons[self.eObjectTypeQuestCritter] or self.tToggledIcons[self.eObjectTypeQuestItem])
		and tURI ~= nil
		and nRewardCount > 0 then

		for idx = 1, nRewardCount do

			local strRewardType = tURI[idx].strType

			if strRewardType == "Challenge" 
			   and self.tActiveChallenges[tURI[idx].idChallenge] then

				bActiveChallenge = true

			end

			-- TODO:  There is an issue here still blocking some "critters"
			-- from showing up -- they are alive but are nil level and not interactable
			-- but still needed for a quest
			if	strRewardType == "Quest"
				and (tAS == nil or tAS.Interact == nil)
				and unitNew:GetLevel() ~= nil
				and strUnitType ~= "Simple" then

				bActiveQuestTarget = true

			end

			if strRewardType == "Quest"
				and (tAS == nil or tAS.Interact == nil)
				and (tURI[idx].nNeeded ~= nil and tURI[idx].nCompleted < tURI[idx].nNeeded)
				and strUnitType == "Simple" then

				bActiveQuestItem = true

			end

			if bActiveChallenge or bActiveQuestTarget or bActiveQuestItem then
				break
			end
		end
	end

	if unitNew:IsACharacter()
	   and bShowUnit
	   and (not unitNew:IsRival() or not self.tToggledIcons[self.eObjectTypeRival])
	   and (eDisposition == Unit.CodeEnumDisposition.Hostile or eDisposition == Unit.CodeEnumDisposition.Neutral)
	   and self.tToggledIcons[self.eObjectTypePC] then

	   	if (unitNew:IsPvpFlagged()) then
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["FlaggedPC"])
		else
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["UnflaggedPC"])
		end

	elseif (bActiveChallenge or bActiveQuestTarget) 
			and self.tToggledIcons[self.eObjectTypeQuestCritter]
			and bShowUnit then

		if eDisposition == Unit.CodeEnumDisposition.Hostile then	
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritterHostile"])
		elseif eDisposition == Unit.CodeEnumDisposition.Neutral then	
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritterNeutral"])
		else
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritter"])
		end
	elseif bActiveQuestItem == true 
			and self.tToggledIcons[self.eObjectTypeQuestItem]
			and bShowUnit then
		table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestItemTarget"])					
	else
		for nMarkerIdx, strMarker in ipairs(tMarkerStrings) do
			if strMarker then
				local tMarkerOverride	
			
				if 	tAS ~= nil
					and strUnitType == "Collectible"
					and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler
					and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
					and (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true)
					and (tAS.Spell ~= nil)
					and (tAS.Collect ~= nil and tAS.Collect.bUsePlayerPath == true)
					and self.tToggledIcons[self.eObjectTypePathResource]
					and bShowUnit  then

					tMarkerOverride = self.tMinimapMarkerInfo["SettlerResource"]				
				elseif 	tAS ~= nil
						and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Scientist
						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
						and (tAS.ScientistScannable or tAS.ScientistRawScannable)
						and self.tToggledIcons[self.eObjectTypePathResource]
						and bShowUnit then
					
					tMarkerOverride = self.tMinimapMarkerInfo["ScientistScan"]				
				elseif 	tAS ~= nil
						and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Explorer
						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
						and (tAS.ExplorerInterest) 
						and self.tToggledIcons[self.eObjectTypePathResource]
						and bShowUnit then

					tMarkerOverride = self.tMinimapMarkerInfo["ExplorerInterest"]
				elseif ((self.tToggledIcons[self.eObjectTypeEliteHostile] and eDisposition == Unit.CodeEnumDisposition.Hostile) 
						or (self.tToggledIcons[self.eObjectTypeEliteNeutral] and eDisposition == Unit.CodeEnumDisposition.Neutral))
						and unitNew:GetDifficulty() >= 3 and not (unitNew:IsDead() or unitNew:IsACharacter())
						and bShowUnit then

					tMarkerOverride = self.tMinimapMarkerInfo["Elite" .. strMarker]
				elseif 	tAS ~= nil
						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
						and tURI ~= nil and nRewardCount > 0
						and tAS.Door == nil
						and ((tAS.Collect ~= nil and tAS.Collect.bCanInteract == true) or (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true))
						and self.tToggledIcons[self.eObjectTypeQuestItem]
						and bShowUnit then
					
						tMarkerOverride = self.tMinimapMarkerInfo["QuestItemTarget"]	
				
				elseif 	tAS ~= nil
					and tAS.Datacube ~= nil 
					and self.tToggledIcons[self.eObjectTypeLore] then
					
					if unitNew:GetName():find("DATA") ~= nil then					
						tMarkerOverride = self.tMinimapMarkerInfo["LoreDatacube"]
					else					
						tMarkerOverride = self.tMinimapMarkerInfo["LoreBook"]
					end																
				elseif bShowUnit then
					tMarkerOverride = self.tMinimapMarkerInfo[strMarker]
				end
			
				-- Adding logic to allow for custom harvest node icons to be displayed
				if tMarkerOverride  and 
					((tMarkerOverride.objectType == self.eObjectTypeFarmingNode and self.tToggledIcons[self.eObjectTypeUniqueFarming])
					or (tMarkerOverride.objectType == self.eObjectTypeMiningNode and self.tToggledIcons[self.eObjectTypeUniqueMining])
					or (tMarkerOverride.objectType == self.eObjectTypeRelicHunterNode and self.tToggledIcons[self.eObjectTypeUniqueRelic])
					or (tMarkerOverride.objectType == self.eObjectTypeSurvivalistNode and self.tToggledIcons[self.eObjectTypeUniqueSurvival])) then
				
					tMarkerOverride = self.tMinimapMarkerInfo[strMarker:gsub("Node", "")]
				end
			
				if tMarkerOverride then									
					table.insert(tMarkerInfos, tMarkerOverride)
				end
			end
		end
	end
	
	table.sort(tMarkerInfos, function(x, y) return x.nOrder < y.nOrder end)
	return tMarkerInfos
end

function GuardMiniMap:HandleUnitCreated(unitNew)

	if not unitNew or not unitNew:IsValid() then
		return
	end
	
	if self.tUnitsAll and self.tUnitsAll[unitNew:GetId()] then
		self.wndMiniMap:RemoveUnit(unitNew)
	end

	--local bShowUnit = unitNew:IsVisibleOnCurrentZoneMinimap()
	--
	--if bShowUnit == false then
		--return
	--end
	
	local tMarkers = unitNew:GetMiniMapMarkers()
	if tMarkers == nil then
		return
	end
		
	local tMarkerInfoList = self:GetOrderedMarkerInfos(tMarkers, unitNew)
	
	for nIdx, tMarkerInfo in ipairs(tMarkerInfoList) do
		local tInfo = self:GetDefaultUnitInfo()
		if tMarkerInfo.strIcon  then
			tInfo.strIcon = tMarkerInfo.strIcon
		end
		if tMarkerInfo.crObject then
			tInfo.crObject = tMarkerInfo.crObject
		end
		if tMarkerInfo.crEdge   then
			tInfo.crEdge = tMarkerInfo.crEdge
		end

		local tMarkerOptions = {bNeverShowOnEdge = true}
		if tMarkerInfo.bAboveOverlay then
			tMarkerOptions.bAboveOverlay = tMarkerInfo.bAboveOverlay
		end
		if tMarkerInfo.bShown then
			tMarkerOptions.bShown = tMarkerInfo.bShown
		end
		-- only one of these should be set
		if tMarkerInfo.bFixedSizeSmall then
			tMarkerOptions.bFixedSizeSmall = tMarkerInfo.bFixedSizeSmall
		elseif tMarkerInfo.bFixedSizeMedium then
			tMarkerOptions.bFixedSizeMedium = tMarkerInfo.bFixedSizeMedium
		end

		local objectType = GameLib.CodeEnumMapOverlayType.Unit
		if tMarkerInfo.objectType then
			objectType = tMarkerInfo.objectType
		end
		
		self.wndMiniMap:AddUnit(unitNew, objectType, tInfo, tMarkerOptions, self.tToggledIcons[objectType] ~= nil and not self.tToggledIcons[objectType])	
		
		if objectType == self.eObjectTypeMember then
			for idxMember = 2, Lib.GetMemberCount() do
				local unitMember = Lib.GetUnitForMember(idxMember)
				if unitMember == unitNew then
					if self.tMembers[idxMember] ~= nil then
						if self.tMembers[idxMember].mapObject ~= nil then
							self.wndMiniMap:RemoveObject(self.tMembers[idxMember].mapObject)
						end

						self.tMembers[idxMember].mapObject = mapIconReference
					end
					break
				end
			end
		end

	end

end

function GuardMiniMap:OnHazardShowMinimapUnit(idHazard, unitHazard, bIsBeneficial)

	if unitHazard == nil then
		return
	end

	--local unit = GameLib.GetUnitById(unitId)
	local tInfo

	tInfo =
	{
		strIcon = "",
		strIconEdge = "",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}


	if bIsBeneficial then
		tInfo.strIcon = "sprMM_ZoneBenefit"
	else
		tInfo.strIcon = "sprMM_ZoneHazard"
	end

	self.wndMiniMap:AddUnit(unitHazard, self.eObjectTypeHazard, tInfo, {bNeverShowOnEdge = true, bFixedSizeMedium = true}, false)
end

function GuardMiniMap:OnHazardRemoveMinimapUnit(idHazard, unitHazard)
	if unitHazard == nil then
		return
	end

	self.wndMiniMap:RemoveUnit(unitHazard)
end

function GuardMiniMap:OnUnitChanged(unitUpdated, eType)
	if unitUpdated == nil then
		return
	end

	self.wndMiniMap:RemoveUnit(unitUpdated)
	self.tUnitsAll[unitUpdated:GetId()] = nil
	self:OnUnitCreated(unitUpdated)
end

function GuardMiniMap:OnUnitDestroyed(unitDestroyed)
	self.tUnitsAll[unitDestroyed:GetId()] = nil
	self.arResourceNodes[unitDestroyed:GetId()] = nil
	
	if unitDestroyed:IsInYourGroup() then
		for idxMember = 2, GroupLib.GetMemberCount() do
			local unitMember = GroupLib.GetUnitForGroupMember(idxMember)
			if unitMember == unitDestroyed then
				local tMember = self.tGroupMembers[idxMember]
				if tMember ~= nil then
					tMember.tWorldLoc = unitDestroyed:GetPosition()
					self:DrawGroupMember(tMember)
				end
				break
			end
		end
	end
end

-- GROUP EVENTS

function GuardMiniMap:OnGroupJoin()
	for idx = 2, GroupLib.GetMemberCount() do
		local tInfo = GroupLib.GetGroupMember(idx)
		if tInfo.bIsOnline then
			self.tGroupMembers[idx] =
			{
				nIndex = idx,
				strName = tInfo.strCharacterName,
			}

			local unitMember = GroupLib.GetUnitForGroupMember(idx)
			if unitMember ~= nil and unitMember:IsValid() then
				self:OnUnitCreated(unitMember)
			end
		end
	end
end

function GuardMiniMap:OnGroupAdd(strName)
	for idx = 2, GroupLib.GetMemberCount() do
		local tInfo = GroupLib.GetGroupMember(idx)
		if tInfo.bIsOnline and strName == tInfo.strCharacterName then
			self.tGroupMembers[idx] =
			{
				nIndex = idx,
				strName = tInfo.strCharacterName,
			}

			local unitMember = GroupLib.GetUnitForGroupMember(idx)
			if unitMember ~= nil and unitMember:IsValid() then
				self:OnUnitCreated(unitMember)
			end

			return
		end
	end
end

function GuardMiniMap:OnGroupRemove(strName, eReason)
	for idx, tMember in pairs(self.tGroupMembers) do -- remove all of the group objects
		self.wndMiniMap:RemoveObject(tMember.mapObject)
	end
	
	self:OnRefreshRadar()
	self:DrawGroupMembers()
end

function GuardMiniMap:OnGroupLeft(eReason)
	for idx, tMember in pairs(self.tGroupMembers) do -- remove all of the group objects
		self.wndMiniMap:RemoveObject(tMember.mapObject)
	end

	self.tGroupMembers = {}
	self:OnRefreshRadar()
end

function GuardMiniMap:OnGroupUpdatePosition(arMembers)
	for idx, tMember in pairs(arMembers) do
		if tMember.nIndex ~= 1 then -- this is the player
			local tMemberInfo = GroupLib.GetGroupMember(tMember.nIndex)
			if self.tGroupMembers[tMember.nIndex] == nil then
				local tInfo =
				{
					nIndex = tMember.nIndex,
					tZoneMap = tMember.tZoneMap,
					idWorld = tMember.idWorld,
					tWorldLoc = tMember.tWorldLoc,
					bInCombatPvp = tMember.bInCombatPvp,
					strName = tMemberInfo.strCharacterName,
				}

				self.tGroupMembers[tMember.nIndex] = tInfo
			else
				self.tGroupMembers[tMember.nIndex].tZoneMap = tMember.tZoneMap
				self.tGroupMembers[tMember.nIndex].tWorldLoc = tMember.tWorldLoc
				self.tGroupMembers[tMember.nIndex].strName = tMemberInfo.strCharacterName
				self.tGroupMembers[tMember.nIndex].idWorld = tMember.idWorld
				self.tGroupMembers[tMember.nIndex].bInCombatPvp = tMember.bInCombatPvp
			end
		end
	end

	self:DrawGroupMembers()
end

function GuardMiniMap:DrawGroupMembers()
	for idx = 2, GroupLib.GetMemberCount() do
		local tMember = self.tGroupMembers[idx]
		local unitMember = GroupLib.GetUnitForGroupMember(idx)
		--if unitMember == nil or not unitMember:IsValid() then
			self:DrawGroupMember(self.tGroupMembers[idx])
		--end
	end
end

function GuardMiniMap:DrawGroupMember(tMember)
	
	if tMember == nil or tMember.tWorldLoc == nil then
		return
	end
	if tMember.mapObject ~= nil then
		self.wndMiniMap:RemoveObject(tMember.mapObject)
	end

	if not GroupLib.GetGroupMember(tMember.nIndex).bIsOnline then
		return
	end
	local tZone = GameLib.GetCurrentZoneMap()
	if tZone == nil or tMember.tZoneMap == nil or tMember.tZoneMap.id ~= tZone.id then
		return
	end
	
	local tMarkerInfo = self.tMinimapMarkerInfo.GroupMember
	local tInfo = self:GetDefaultUnitInfo()
	
	if tMarkerInfo.strIcon ~= nil then
		tInfo.strIcon = tMarkerInfo.strIcon
	end
	if tMarkerInfo.crObject ~= nil then
		tInfo.crObject = tMarkerInfo.crObject
	end
	if tMarkerInfo.crEdge ~= nil then
		tInfo.crEdge = tMarkerInfo.crEdge
	end
	if tMarkerInfo.strIconEdge ~= nil then
		tInfo.strIconEdge = tMarkerInfo.strIconEdge
	end
	local tMarkerOptions = { bNeverShowOnEdge = true }
	if tMarkerInfo.bNeverShowOnEdge ~= nil then
		tMarkerOptions.bNeverShowOnEdge = tMarkerInfo.bNeverShowOnEdge
	end
	if tMarkerInfo.bAboveOverlay ~= nil then
		tMarkerOptions.bAboveOverlay = tMarkerInfo.bAboveOverlay
	end
	if tMarkerInfo.bShown ~= nil then
		tMarkerOptions.bShown = tMarkerInfo.bShown
	end
	
	-- only one of these should be set
	if tMarkerInfo.bFixedSizeSmall ~= nil then
		tMarkerOptions.bFixedSizeSmall = tMarkerInfo.bFixedSizeSmall
	elseif tMarkerInfo.bFixedSizeMedium ~= nil then
		tMarkerOptions.bFixedSizeMedium = tMarkerInfo.bFixedSizeMedium
	end
	local strNameFormatted = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"ff31fcf6\">%s</T>", tMember.strName)
	strNameFormatted = String_GetWeaselString(Apollo.GetString("ZoneMap_AppendGroupMemberLabel"), strNameFormatted)
	tMember.mapObject = self.wndMiniMap:AddObject(self.eObjectTypeGroupMember, tMember.tWorldLoc, strNameFormatted, tInfo, tMarkerOptions)
	
end

---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnGenerateTooltip(wndHandler, wndControl, eType, nX, nY)
	local xml = nil
	local crWhite = CColor.new(1, 1, 1, 1)
	if eType ~= Tooltip.TooltipGenerateType_Map then
		wndControl:SetTooltipDoc(nil)
		return
	end

	local nCount = 0
	local bNeedToAddLine = true
	local tClosestObject = nil
	local nShortestDist = 0

	local tMapObjects = self.wndMiniMap:GetObjectsAtPoint(nX, nY)
	if not tMapObjects or #tMapObjects == 0 then
		wndControl:SetTooltipDoc(nil)
		return
	end

	for key, tObject in pairs(tMapObjects) do
		if tObject.unit then
			local nDistSq = (nX - tObject.ptMap.x) * (nX - tObject.ptMap.x) + (nY - tObject.ptMap.y) * (nY - tObject.ptMap.y)
			if tClosestObject == nil or nDistSq < nShortestDist then
				tClosestObject = tObject
				nShortestDist = nDistSq
			end
			nCount = nCount + 1
		end
	end

	if not xml then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		bNeedToAddLine = false
	end

	-- Iterate map objects
	local nObjectCount = 0
	local tStringsAdded = {}
	for key, tObject in pairs(tMapObjects) do
		if nObjectCount == 5 then
			nObjectCount = nObjectCount + 1

			local tInfo =
			{
				["name"] = Apollo.GetString("CRB_Unit"),
				["count"] = nCount
			}
			xml:AddLine(String_GetWeaselString(Apollo.GetString("MiniMap_OtherUnits"), tInfo), crWhite, "CRB_InterfaceMedium")
		elseif nObjectCount > 5 then
			-- Do nothing
		elseif tObject.strName == "" then
			-- Do nothing
		elseif tObject.strName and not tObject.bMarked then
			if bNeedToAddLine then
				xml:AddLine(" ")
			end
			bNeedToAddLine = false

			if not tStringsAdded[tObject.strName] then
				nObjectCount = nObjectCount + 1
				xml:AddLine(tObject.strName, crWhite, "CRB_InterfaceMedium")
				tStringsAdded[tObject.strName] = true
			end
		end
	end
	
	if nObjectCount > 0 then
		wndControl:SetTooltipDoc(xml)
	else
		wndControl:SetTooltipDoc(nil)
	end
end

function GuardMiniMap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	for idx, tFriend in pairs(tFriendAccountList) do
		self:OnRefreshRadar(FriendshipLib.GetUnitById(tFriend.nId))
	end
end

function GuardMiniMap:OnFriendshipAdd(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function GuardMiniMap:OnFriendshipRemove(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function GuardMiniMap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	self:OnRefreshRadar()
end

function GuardMiniMap:OnFriendshipAccountFriendRemoved(nId)
	self:OnRefreshRadar()
end

function GuardMiniMap:OnReputationChanged(tFaction)
	self:OnRefreshRadar()
end

function GuardMiniMap:OnRefreshRadar(newUnit)
	if newUnit ~= nil and newUnit:IsValid() then
		self:OnUnitCreated(newUnit)
	else
		for idx, tCur in pairs(self.tUnitsAll) do
			self:OnUnitCreated(tCur.unitObject)
		end
	end
end

function GuardMiniMap:OnMiniMapMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.bSquareMap then	
		local tDispSize = Apollo.GetDisplaySize()
		local dispWidth = tDispSize["nWidth"]
		local dispHeight = tDispSize["nHeight"]
		local x,y = self.wndMain:GetPos()
		local tButtonsLocation = self.wndMain:FindChild("ButtonContainer"):GetLocation():ToTable()
		if y > dispHeight / 2.5 then
			self.wndMain:FindChild("ButtonContainer"):SetAnchorPoints(tButtonsLocation.fPoints[1], 0, tButtonsLocation.fPoints[3], 0)
			self.wndMain:FindChild("ButtonContainer"):SetAnchorOffsets(tButtonsLocation.nOffsets[1], -15, tButtonsLocation.nOffsets[3], 25)
		else
			self.wndMain:FindChild("ButtonContainer"):SetAnchorPoints(tButtonsLocation.fPoints[1], 1, tButtonsLocation.fPoints[3], 1)
			self.wndMain:FindChild("ButtonContainer"):SetAnchorOffsets(tButtonsLocation.nOffsets[1], -25, tButtonsLocation.nOffsets[3], 15)
		end
	end

	self.wndMain:FindChild("ZoomInButton"):Show(true)
	self.wndMain:FindChild("ZoomOutButton"):Show(true)
	self.wndMain:FindChild("MapToggleBtn"):Show(true)
	self.wndMain:FindChild("MapMenuButton"):Show(true)

	if self.bOnArkship == nil or self.bOnArkship == false then
		self.wndMain:FindChild("RapidTransportBtnOverlay"):Show(true)
	end

	if self.wndMain:FindChild("MiniMapResizeArtForPixie") then
		self.wndMain:FindChild("MiniMapResizeArtForPixie"):Show(true)
	end
end

function GuardMiniMap:OnMiniMapMouseExit(wndHandler, wndControl)
	-- scsc: always show buttons

	--if wndHandler ~= wndControl then
	--	return
	--end
	--self.wndMain:FindChild("ZoomInButton"):Show(false)
	--self.wndMain:FindChild("ZoomOutButton"):Show(false)
	--self.wndMain:FindChild("MapToggleBtn"):Show(false)
	--self.wndMain:FindChild("MapMenuButton"):Show(false)
	--self.wndMain:FindChild("RapidTransportBtnOverlay"):Show(false)
	--
	--if self.wndMain:FindChild("MiniMapResizeArtForPixie") then
	--	self.wndMain:FindChild("MiniMapResizeArtForPixie"):Show(false)
	--end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function GuardMiniMap:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor ~= GameLib.CodeEnumTutorialAnchor.MiniMap then
		return
	end

	local tRect = {}
	tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()

	Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
end

---------------------------------------------------------------------------------------------------
-- MinimapOptions Functions
---------------------------------------------------------------------------------------------------

function GuardMiniMap:OnFilterOptionCheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()
	if data == nil then
		return
	end

	self.tToggledIcons[data] = true

	if data == self.eObjectTypeQuestReward then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestReward)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestReceiving)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestNew)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestNewSoon)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestTarget)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeQuestKill)
	elseif data == self.eObjectTypeBindPointActive then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeBindPointActive)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeBindPointInactive)
	elseif data == self.eObjectTypeVendor then
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeVendor)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeAuctioneer)
		self.wndMiniMap:ShowObjectsByType(self.eObjectTypeCommodity)
	elseif data == self.eObjectTypeEliteNeutral 
			or data == self.eObjectTypeEliteHostile 
			or data == self.eObjectTypeUniqueFarming
			or data == self.eObjectTypeUniqueMining
			or data == self.eObjectTypeUniqueRelic
			or data == self.eObjectTypeUniqueSurvival
			or data == self.eObjectTypeLore
			or data == self.eObjectTypeQuestItem
			or data == self.eObjectTypeQuestCritter
			or data == self.eObjectTypePathResource then
		-- update all already shown units
	  	self:RefreshMap()
	else
		self.wndMiniMap:ShowObjectsByType(data)
	end
end

function GuardMiniMap:OnFilterOptionUncheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()
	if data == nil then
		return
	end

	self.tToggledIcons[data] = false

	if data == self.eObjectTypeQuestReward then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestReward)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestReceiving)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestNew)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestNewSoon)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestTarget)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeQuestKill)
	elseif data == self.eObjectTypeBindPointActive then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeBindPointActive)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeBindPointInactive)
	elseif data == self.eObjectTypeVendor then
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeVendor)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeAuctioneer)
		self.wndMiniMap:HideObjectsByType(self.eObjectTypeCommodity)
	elseif data == self.eObjectTypeEliteNeutral 
			or data == self.eObjectTypeEliteHostile
			or data == self.eObjectTypeUniqueFarming
			or data == self.eObjectTypeUniqueMining
			or data == self.eObjectTypeUniqueRelic
			or data == self.eObjectTypeUniqueSurvival
			or data == self.eObjectTypeLore
			or data == self.eObjectTypeQuestItem
			or data == self.eObjectTypeQuestCritter
			or data == self.eObjectTypePathResource then
		-- update all already shown units
	  	self:RefreshMap()
	else
		self.wndMiniMap:HideObjectsByType(data)
	end
end

function GuardMiniMap:OnSquareMapCheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)
	
	self.bSquareMap = true	
	
	self:RebuildMapWindow()
	self:UpdateRapidTransportBtn()
		
	self.wndZoneName:SetFont( self.strMapFont or "CRB_InterfaceSmall_O" )
	self.wndPvPFlagName:SetFont( self.strMapFont or "CRB_InterfaceSmall_O")

end

function GuardMiniMap:OnSquareMapUncheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)

	self.bSquareMap = false
	
	self:RebuildMapWindow()	
	self:UpdateRapidTransportBtn()
end

function GuardMiniMap:OnHideCompassCheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)

	self.bHideCompass 		= true
	
	self:RebuildMapWindow()
end

function GuardMiniMap:OnHideCompassUncheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)
	
	self.bHideCompass 		= false
	
	self:RebuildMapWindow()
end

function GuardMiniMap:OnCustomQuestCheck( wndHandler, wndControl, eMouseButton )
	self.bCustomQuestArrow = true
	-- update all already shown units
  	self:RefreshMap()
end

function GuardMiniMap:OnCustomQuestUncheck( wndHandler, wndControl, eMouseButton )
	self.bCustomQuestArrow = false
	-- update all already shown units
  	self:RefreshMap()
end

function GuardMiniMap:OnShowCoordsCheck( wndHandler, wndControl, eMouseButton )
	self.bShowCoords = true
	self.wndMiniMapCoords:Show(true)
end

function GuardMiniMap:OnShowCoordsUncheck( wndHandler, wndControl, eMouseButton )
	self.bShowCoords = false
	self.wndMiniMapCoords:Show(false)
end

function GuardMiniMap:OnHideFrameCheck( wndHandler, wndControl, eMouseButton )

	if self.wndMain:FindChild("MapFrame") then
		self.wndMain:FindChild("MapFrame"):Show(false)
	end

	self.bHideFrame = true
end

function GuardMiniMap:OnHideFrameUncheck( wndHandler, wndControl, eMouseButton )
	if self.wndMain:FindChild("MapFrame") then
		self.wndMain:FindChild("MapFrame"):Show(true)
	end

	self.bHideFrame = false
end

function GuardMiniMap:RebuildMapWindow()
	self.wndMain:Destroy()

	if self.bSquareMap and self.bSquareMap == true then	
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "SquareMinimap", "FixedHudStratum", self)
	else
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "Minimap", "FixedHudStratum", self)
	end
	
	if (self.bSquareMap and self.bSquareMap == true)  then
		if (self.bHideCompass and self.bHideCompass == true) then
			Apollo.LoadSprites("SquareMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("SquareMapTextures.xml")
		end
	else
		if (self.bHideCompass and self.bHideCompass == true) then
			Apollo.LoadSprites("CircleMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("CircleMapTextures.xml")
		end
	end
	
	if self.nMapOpacity then
		self.wndMain:SetOpacity(self.nMapOpacity)
	else
		self.nMapOpacity = 1.0
	end

	self.wndMiniMap 		= self.wndMain:FindChild("MapContent")
	self.wndZoneName 		= self.wndMain:FindChild("MapZoneName")
	self.wndPvPFlagName 	= self.wndMain:FindChild("MapZonePvPFlag")
	self.wndRangeLabel 		= self.wndMain:FindChild("RangeToTargetLabel")
	self:UpdateZoneName(GetCurrentZoneName())
	self.wndMinimapButtons 	= self.wndMain:FindChild("ButtonContainer")
	
	if self.fSavedZoomLevel then
		self.wndMiniMap:SetZoomLevel( self.fSavedZoomLevel)
	end
	
	self:OnWindowManagementReady()

	if self.bRotateMap and self.bRotateMap == true then
		self.wndMinimapOptions:FindChild("OptionsBtnRotate"):SetCheck(true)
		self.wndMiniMap:SetMapOrientation(2)
	end 
	
	if not self.bHideFrame or self.bHideFrame == false then

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(true)
		end

		self.bHideFrame = false
	else

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(false)
		end
	end

	g_wndTheMiniMap = self.wndMiniMap

	self.wndMain:FindChild("MapMenuButton"):AttachWindow(self.wndMinimapOptions)
	self.wndMain:SetSizingMinimum(150, 150)
	self.wndMain:SetSizingMaximum(1000, 1000)
  	self:RefreshMap()
end

function GuardMiniMap:OnCustomPlayer_Check( wndHandler, wndControl, eMouseButton )
	Apollo.LoadSprites("GMM_CustomPlayerArrow.xml")

	self.bCustomPlayerArrow = true

	self:RebuildMapWindow()
end

function GuardMiniMap:OnCustomPlayer_Uncheck( wndHandler, wndControl, eMouseButton )
	Apollo.LoadSprites("GMM_DefaultPlayerArrow.xml")

	self.bCustomPlayerArrow = false

	self:RebuildMapWindow()
end

function GuardMiniMap:SetMapFont(strFont)
	self.strMapFont = strFont
	self.wndZoneName:SetFont( strFont or "CRB_InterfaceSmall_O" )
	self.wndPvPFlagName:SetFont( strFont or "CRB_InterfaceSmall_O" )
end

function GuardMiniMap:OnRapidTransportOpen()
	Event_FireGenericEvent("InvokeTaxiWindow")
end

function GuardMiniMap:UpdateRapidTransportBtn()
	local wndRapidTransport = self.wndMain:FindChild("RapidTransportBtnOverlay")
	local tZone = GameLib.GetCurrentZoneMap()
	local nZoneId = 0
	if tZone ~= nil then
		nZoneId = tZone.id
	end
	self.bOnArkship = tZone == nil or GameLib.IsTutorialZone(nZoneId)
end
---------------------------------------------------------------------------------------------------
-- MinimapCoords Functions
---------------------------------------------------------------------------------------------------

function GuardMiniMap:OnClickCoords( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )

end

-----------------------------------------------------------------------------------------------
-- Utility / Helper functions
-- Pulled from NavMate
-----------------------------------------------------------------------------------------------

local function GetAddon(strAddonName)
	local info = Apollo.GetAddonInfo(strAddonName)

	if info and info.bRunning == 1 then 
		return Apollo.GetAddon(strAddonName)
	end
end

---------------------------------------------------------------------------------------------------
-- MiniMap instance
---------------------------------------------------------------------------------------------------
local MiniMapInst = GuardMiniMap:new()
MiniMapInst:Init()
