-----------------------------------------------------------------------------------------------
-- Client Lua Script for DungeonHelper
-- Copyright (c) Alex Martin. Released under MIT license.
-- Edited by Weedze for Veteran and new Dungeons.
-- Edited by RiChess for spelling, grammar and polish.
-- 0.8
 
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GroupLib"
 
-----------------------------------------------------------------------------------------------
-- DungeonHelper Module Definition
-----------------------------------------------------------------------------------------------
local DungeonHelper = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- "Globals" (within the addon context)
-----------------------------------------------------------------------------------------------

local diCrashCourses = {} -- a dictionary of {"mob_name":["Message 1", "Message 2"...], ...}
local arSilencedMobs = {} -- an array of mobs that we have already said "crash course available for mob" once this session.
local strCurrentTarget = ""
local strSlashCommand = "help"
local debug = false
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function DungeonHelper:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function DungeonHelper:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- DungeonHelper OnLoad
-----------------------------------------------------------------------------------------------
function DungeonHelper:OnLoad()
	Apollo.RegisterSlashCommand(strSlashCommand, "OnDungeonHelperOn", self)
	--Apollo.RegisterSlashCommand("getzone", "OnCrashGetZone", self)
	--Apollo.RegisterEventHandler("VarChange_ZoneName", "OnChangeZoneName", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	
	-- init rover
	self:PublishVarsToRover()
	
	-- load mobs
	self:LoadMobs()
end

function DungeonHelper:PublishVarsToRover()
	if debug then
		SendVarToRover("CC: diCrashCourses", diCrashCourses)
		SendVarToRover("CC: arSupportedZones", arSupportedZones)
		SendVarToRover("CC: arSilencedMobs", arSilencedMobs)
		SendVarToRover("CC: strCurrentTarget", strCurrentTarget)
		SendVarToRover("CC: bCurrentZoneSupported", bCurrentZoneSupported)
		SendVarToRover("CC: strCurrentZone", strCurrentZone)
	end
end

-----------------------------------------------------------------------------------------------
-- DungeonHelper Event Handlers
-----------------------------------------------------------------------------------------------

function DungeonHelper:OnTargetUnitChanged(unitTarget)
	if unitTarget == nil then
		strCurrentTarget = ""
		return
	end
	
	strCurrentTarget = unitTarget:GetName()
	if self:MobIsSupported(strCurrentTarget) == true and self:MobOutputIsSilenced(strCurrentTarget) == false then
		table.insert(arSilencedMobs, self:JSONifyString(strCurrentTarget))
		self:WriteLog("Type '/" .. strSlashCommand .. "' to output target")
	end
	
	self:PublishVarsToRover()
end

-----------------------------------------------------------------------------------------------
-- DungeonHelper Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/cc"
function DungeonHelper:OnDungeonHelperOn(cmd, args)
	local strTargetJSON = ""
	
	-- get the mob that we need to output
	if args == "" then
		self:WriteDebug("Showing Strategy for target")
	else
		self:WriteDebug("Showing Strategy for mob: " .. args)
		strCurrentTarget = args
	end
	
	-- get the messages to print
	strTargetJSON = self:JSONifyString(strCurrentTarget)
	self:WriteDebug("Searching for mob: " .. strTargetJSON)
	local arMobMessages = diCrashCourses[strTargetJSON]
	
	-- print the messages
	if arMobMessages ~= nil then
		self:OutputToGroup(" -- Strategy for " .. strCurrentTarget .. " --")
		for _,msg in pairs(arMobMessages) do
			self:OutputToGroup(msg)
		end
	else
		self:WriteLog("No Strategy for this mob")
	end
	
	self:PublishVarsToRover()
end

function DungeonHelper:MobOutputIsSilenced(strMobName)
	local strMobJSON = self:JSONifyString(strMobName)
	
	-- look through the silenced mobs array
	for _,val in pairs(arSilencedMobs) do	
		-- if the mob is there, return true
 		if val == strMobJSON then
    		return true
    	end
 	end

	-- if we get here, return false
	return false
end

function DungeonHelper:OutputToGroup(strText)
	if GroupLib.InInstance() == true then
		ChatSystemLib.Command(string.format("/i %s", strText))
	elseif GroupLib.InGroup() == true then
		ChatSystemLib.Command(string.format("/p %s", strText))
	else
		self:WriteLog(strText)
	end
end

function DungeonHelper:WriteLog(strText)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strText, "Strategy")
end

function DungeonHelper:WriteDebug(strText)
	if debug then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strText, "DungeonHelper Debug")
	end
end

function DungeonHelper:MobIsSupported(strMobName)
	local strMobJSON = self:JSONifyString(strMobName)
	
	-- look through the mobs dictionary
	for key,val in pairs(diCrashCourses) do
	
		-- if the zone is in the array, return true
 		if key == strMobJSON then
    		return true
    	end
 	end

	-- if we get here, return false
	return false
end

function DungeonHelper:JSONifyString(strOriginal)
	-- equivalent to var edited = str.toLowerCase().replace(/[\s]/g, '_').replace(/[^_a-z0-9]/gi, '');
	local strNew = strOriginal:lower()
	strNew = strNew:gsub("%s", "_")
	strNew = strNew:gsub("[^_a-zA-Z0-9]", "")
	return strNew
end

function DungeonHelper:SpellDesc(strName, bInterrupt, iIntArmor, bOptional)
	-- defaults
	iIntArmor = iIntArmor or 0
	bOptional = bOptional or false
	bInterrupt = bInterrupt or false
	
	-- build the string
	local strDesc = strName
	local strInterrupt = "**Interrupt** "
	local strDodge = "Dodge out of "
	local strIntArmor = "(" .. iIntArmor .. " IA)"
	local strOptional = "(Optional)"
	
	if iIntArmor > 0 then
		strDesc = strDesc .. " " .. strIntArmor
	end
	
	if bOptional == true then
		strDesc = strDesc .. " " .. strOptional
	end
	
	if bInterrupt then
		strDesc = strInterrupt .. strDesc
	else
		strDesc = strDodge .. strDesc
	end
	
	return strDesc
end

-----------------------------------------------------------------------------------------------
-- Initialize the "supported mobs" array (it's down here because it's long)
-----------------------------------------------------------------------------------------------

function DungeonHelper:LoadMobs()
	local mobs = {}
	
	-- Kel Vorath
	mobs["grond_the_corpsemaker"] = {
		"Stack on Gronds right or left side, he cleaves in front and behind him",
		"Interrupt Thrash(2IA)",
		"If you have an add following you, kite it into a bone trap.",
	}
	mobs["kythria"] = {
		"Interrupt Void Hunter(3IA) and Desecration Seal(3IA) dodge the rest.",
	}
	mobs["darkwitch_gurka"] = {
		"If she begins to cast Deadly Defilement run immediately and spread out. Thorns spawn at the ground under you. (4-5 Thorns each player, they are circle telegraphs)",
		"If she casts Afflicted Soil just dodge out of the X-telegraph. She often casts it shortly before she casts Deady Defilement.",
		"When she gets low she'll cast Blinding Dark(4IA) interrupt it and finish her.",  
	}
	mobs["slavemaster_drokk"] = {
		"Phase 1",
		"Basic tank & spank phase. Drokk casts missiles on random players. Dodge it.",
		"Drokk disappears, stack in front of the green portal and kill the Bombshell Construct that is right there and only that.",
		"Phase 2",
		"Drokk appears, evade missiles and the blast radius from the Bombshell Constructs. Tank needs to kite him out of the AoEs.",
		"Phase 3",
		"Drokk disappears and everyone must move away from the portal! As Drokk will be targeting one random player with a tracking beacon.",
        "Destruction Constructs will spawn and chase the targeted player. The tracked player must run away from Constructs while the rest of the group stuns, slows and kills them, if failed each Construct explodes for ~30K AoE damage.",
        "The tracked player takes rapid damage ticks, and the healer must follow and heal him while he is targeted or he will die. The beacon changes targets 3 times during this phase.",
        "Phase 4",
        "Drokk appears, tank will kite as before until everyone is teleported and tethered. Use a CC break or kill the tether. Help the tank and healer break their teathers before returning to Drokk. Interrupt Drokk if he casts Suppression Wave (2IA)",
        "During this phase random players will be tethered.", 
        "Phase 5",
        "Phase 3 repeats.",
        "Phase 6",
        "Interrupt Suppression Wave(2IA) and kill him.",
	}   
	mobs["forgemaster_trogun"] = {
		"Phase 1",
		"Do not approach Trogun or the forge until he walks down.",
		"Phase 2",
		"Tank him in middle of the room. Interrupt Volcanic Strike(4IA). !!IF NOT INTERRUPTED, THE TANK WILL TAKE MASSIVE DAMAGE IF HE DOESN'T DODGE, AND HE WILL DIE IN SECONDS!! Divide players into quadrants to gather orbs.",
		"After a short time Trogun casts Forgemasters Call, players must spread out to catch the orbs. The orbs spawns at the edge of the room and move to Trogun. Each Orb gives Trogun or yourself more Power.",
		"Phase 2",
		"At ~50% Trogun runs to his forge and sends waves of saw blades across the room. Run to the entrance, zoom your camera out and dodge the saw blades.",
		"Phase 3",
		"Phase 2 repeats, but during during his Forgemasters Call, he casts saw blades from his position. Evade them and intercept orbs again.", 
	}
	
	-- stormtalon's lair
	mobs["overseer_driftcatcher"] = {
		"Interrupt his Gust Convergence(2IA) or he will summon three adds. When he casts Electro Storm, you need to DPS down his shield and interrupt him(2IA). Avoid the telegraphs. Before and after Shield Phase stack at the healer for dispel and healing.",
	}
	mobs["bladewind_the_invoker"] = {
		"Phase 1",
		"Bladewind cast Thunder Cross(2IA)",
		"Phase 2",
		"At ~60% Bladewind disarms everyone and you move to kill the Thundercall Channelers. They have a static shield, remove it with the Lightning Strikes (circle AoE that targets 1 random player at a time) and finish them one by one. Evade the Thunder Crosses, for each dead channeler a Static Wisp appears that orbits the room and will stun you if not dodged.",
		"Phase 3",
		"Once all four channelers are dead, the boss will disarm the party again. The boss will cast Electrostatic Pulse (2IA) 3 Times in a Row. Avoid the Wisps and the Lightning Strikes.",
	}
	mobs["aethros"] = {
		"Phase 1",
		"When Aethros casts Air Shift three adds spawn at his position and he disappears, kite the adds to one side of the room. Players have to drop their telegraphs on the edge of the Room.",
		"Phase 2",
		"Run to the boss dodging tornados and telegraphs. Interrupt Aethros' cast, Tempest(2IA), or he will one shot the party",
		"Phase 3",
		"DPS Aethros until he casts Air Shift again and kill the adds. This is a repetition of Phase 2.",
		"Phase 4",
		"Finish him while dodging Tornados.",
	}
	mobs["arcanist_breezebinder"] = {
		"Interrupt every possible Gust Convergence(4IA).",
	}
	mobs["stormtalon"] = {
		"Phase 1",
		"All but tank stack on the side of the boss as he does a frontal cleave. After a short period Stormtalon will cast a knockback.",
		"Phase 2",
		"After the knockback use a CC break and run sideways towards Stormtalon and interrupt him (4IA), or he will instantly kill the whole party. Tank should start to kite the boss around the edge of the room when Stormtalon starts casting small AoEs on the floor.",
		"Phase 3",
		"One player gets targeted and is the center of Eye of the Stom. Everyone else runs to that player and follows him without getting hit by the telegraphs. The targeted player should use his CC break to break the disorient (NOTE: Spellslingers cannot CC break this!). Lightning Strikes target the player that is the center of the storm, and he should move slowly to avoid the strikes. This allows the other players to keep up, as the area outside of the storm will quickly kill them.",
	}
	
	-- Skullcano
	mobs["stewshaman_tugga"] = {
		"No tank or healer is needed for this Boss. Everyone should go DPS and bring 3 interrupts. Interrupt all four casts (2IAx4), if an interrupt is missed, the party will likely wipe. When Tugga gets low enough he will knock everyone back and disarm the party. Start the interrupt rotation from the top while DPSing him down.",
	}
	mobs['thunderfoot'] = {
		"If you see 2 overlapping round telegraphs in front of the boss, jump to avoid damage (Thunder Pound). If you see a big round red telegraph run out of it and jump, if the telegraph hits you it's can be a one shot (Pulverize).",
		"This boss can't be interrupted, but the tank should kite him to the mushshrooms to stun him. His auto attack is a frontal cleave, so no one except the tank should be in front of him.",
		"During the fight Moodies outside the bosses room will throw telegraphs on the ground under you, simply move out of them."
	}
	mobs['bosun_octog'] = {
		"Phase 1",
		"Interrupt Shred(4IA) after he cast Hookshoot. Avoid the large square telegraph that periodically covers part of the room. Interrupt the monkey that appears and focus him down.",
		"Phase 2",
		"Random players get blinded during this phase, CC break if possible. The blinded player must move to the edge of the room and run clockwise around the room so the poison trail attached doesn't affect other players. Squid will be launched from the boss, they will grow in size until they explode. Try to dps them down before they exlode.",
		"Phase 3",
		"Phase 1 and 2 repeats.",
	}
	mobs['quartermaster_gruh'] = {
		"Wait until he has no mobs close to him to pull. Spread out and dodge the Kneecap + Deadeye combo that he casts, same for Wild Barrage + Debilitating Fusillade combo.",
		"At low hp he disarm the party. CC break and interrupt Fatal Shot(2IA). If not interrupted he will one shot a targeted player. He will cast it once or twice depending on how quickly he dies.",
			}
	mobs['mordechai_redmoon'] = {
		"Phase 1",
		"On pull he will disappear and 4 beams will appear around the room. Along with those beams there will be random lava pools on the floor that will stun you if not avoided, bring a CC break or this will most likely result in your death. The beams will start moving in a random direction, you need to avoid them as they will instantly kill you.",
		"Phase 2",
		"Beams disappear and Mordechai appears. Stand on a side of him asthere is a large box shaped cleave in the front and back of him. If you see the 'Terraformer is overcharging!' message, look away from the center of the room to avoid being blinded. Small beams appear and will put a high damage DoT on you if you hit them, simply jump over them while DPSing the boss. Mordechai dissapears at the end to start Phase 3.",
		"Phase 3",
		"Same as Phase 1, but the small beams now accompany the large beams. Quickly figure out which is the small one and jump over it while avoiding the large beams.",
		"Phase 4",
		"Same as Phase 2, but he casts Big Bang(2IA). He will jump on and pin one player to the floor, and kills him if not interrupted. You may use your CC break to escape Big Bang.",
		"Phase 3 starting again",
		"Phase 5",
	    "Same as Phase 4, but Mordechai could cast Vicious Barrage(2IA). Interrupt it.",
	}
	
	-- Sanctuary of the Swordmaiden
	mobs["deadringer_shallaos"] = {
	    "This boss will rotate between two phases, then switch into a combined final phase when her health is low.",
	    "Instead of using a normal threat table, she will focus her attacks on the player with the highest stack of a debuff called Resonance",
	    "Torine Chimes: floating crystals that roam the arena throughout the fight. Each time a player hits a chime they will receive one stack of Resonance.",
	    "Torine Chime Detonate: chimes occasionally do a small circular aoe on their location as they move around. It does damage and adds a stack of Resonance to any player hit.",
	    "Resonance: Increases damage taken by 1% per stack and the one with highest stacks get aggro.", 
	    "Phase 1",
	    "She will cleave, don't stand in front of her if she cast Echo. Interrupt it(3IA). Take care to avoid the Chimes.",
	    "Phase 2",
	    "She becomes immune and creates a protection barrier around herself. Echo wave attacks will now radiate from the shrines, moving around the room. Players hit will take damage and receive a stack of Resonance.",
	    "Try to stand in front of her as the Echo Waves aren't as common there.",
	    "Phase 3",
	    "Starts at 25%. Both Phases together.",
   }
   mobs["rayna_darkspeaker"] = {
       "No interrupts are needed for this boss.",
       "Phase 1",
       "After a short time you will get a telegraph around you. Run a little to the edge of the room (entrance) and drop the lava pools there. A player may get tethered, and Rayna will channel Lava Blast at him. Medium or Heavy armor classes can stand still (not stay in lava pools) if the healer has decent gear and is paying attention. Low armor user have to evade the lava blast or CC break.",
       "Phase 2",
       "Molten Wave (wall of fire): Walls of fire appear at the back of the room and move towards the entrance. Each wall has one safe zone that can be used to avoid it. Players who are hit will be knocked down and almost always die.",
       "Phase 3",
       "After the second fire wall phase (under 30% health), Rayna enters a final phase using a combination both Phases. But Molten Wave(fire walls) can spawn from any of the four sides of the room.",
   }
   mobs["ondu_lifeweaver"] = {
       "Interrupt every cast that you can (all 2IA), but his heal totem channel must always be interrupted, or he heals for a large amount. Ondu may enrage (big red hands) the tank needs to kite him, and healer must dispel the slow on him.",
       "At 2 points of the fight all except one player get a root. The free player have to turn around and run through the incoming insects AoEs. If an AoE touches a rooted player, it will instantly kill him",
   }
   mobs["moldwood_overlord_skash"] = {
       "Tank walks through him and tanks him against the wall, the party should be close to the tank.",
       "4 possible things can now happen, if he casts Summon the Swarm, adds spawn at the edge of the room and move to attack players, simply DPS them down. If casts Tentacle Wrath(2IA) interrupt it.",
       "He may cast Corruption Heartseeker. If he does, a message will appear: 'Skash's hammer pulses with dread intent' you will get a red telegraph around you, move fast in the center of the room while avoiding other players. If you touch anyone, both of you will get knocked around and adds will spawn. After a short time circle telegraphs spawn on the boss and attack each player. Stand still and DPS the adds and boss until the phase ends .",
	   "Last cast he may do is Corruption Siphon, you will see eggs/eyes spawn. Immediately run to the other side of the room as they will kill you very quickly if not avoided.",
   }
   mobs["spiritmother_selene_the_corrupted"] = {
       "Interrupt every cast possible. After a short time the room will go dark, run into the pools of light (if the healer is geared, you may stack on the boss). After the darkness phase ends, move to the fountain at the back of the room. The boss will repeatedly blind the party, and the party must stun and kill the shadow adds that appear between the blinds, while avoiding the telegraph wave the boss will send at the party. Reset to the fountain every time the shadow adds disappear so the healer can top up the party in preperation for the next blind",
       "When the last shadow add has been killed, move to the boss and begin attacking. She will cast Shade Prison(4IA) on a player, interrupt the cast, or one player has to dodge when he is tethered (5 bombs). She repeats the Darkness Phase and the kill shadows Phase.",
	   "At the end she will turn the room into a giant red telegraph, with one safe zone. Run to the safe zone and stay in it until it disappears. Interrupt Shade Prison(4IA), and the giant bar telegraph. Finish her off.",
   }
   mobs["corrupted_lifecaller_khalee"] = {
       "She casts very quick a Blind Aoe(2IA) that doesn't have to be interrupted. If she cast Well of Life or she will cast a large AoE on a random player that will damage the group and heal her. At 66% and 33% a fire elemental spawns. Interrupt and kill it.",
   }
   mobs["corrupted_edgesmith_torian"] = {
       "Only the tank stand in front of the miniboss, due to the Bleed DoT. Blade Dance(4IA) should be interrupted.",
   }
   mobs["corrupted_deathbringer_dareia"] = {
       "Frontal cleave autoattack, also casts a frontal wide attack called Wicked Slash. Dodge it. If she cast Whirlwind(2IA) interrupt her. If she casts Warriors Charge dodge it.",
   }
   mobs["hammerfist_moldjaw"] = {
       "Dodge Might Leap, interrupt Mesmerize(2IA) and Foul Scourge(2IA).",
   }
   mobs["lifeweaver_guardian"] = {
       "Interrupt Taste of Death(2IA) and Nature's Fury(2IA). Withering Shout doesn't need to be interrupted.",
   }
   mobs["flamecrazed_demon"] = {
       "No interrupts needed. If he cast Conjure Flames, adds appear and you should walk/run over them to let them explode. If he cast Rain of Fire, simply dodge the telegraphs.",
   }	
	diCrashCourses = mobs
end

-----------------------------------------------------------------------------------------------
-- DungeonHelper Instance
-----------------------------------------------------------------------------------------------
local DungeonHelperInst = DungeonHelper:new()
DungeonHelperInst:Init()
