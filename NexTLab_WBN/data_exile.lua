local wbEventIds = {
	[855] = { 
		boss_name = "Scorchwing",
		boss_short = "SW",
		location = "Blighthaven",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },  
			{ button = {bText="Use the teleporter to Nursery Trading Post in Blighthaven", unit_enum = "exile_blighthaven"} },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=2321.2370605469, y=-840.67517089844, z=-6725.43359375}, zone_id=4152 } }
		}
	},
	[586] = {
		boss_name = "Mechathorn",
		boss_short = "MT",
		location = "Farside",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" }, 
			{ button = {bText="Use the Teleporter to Sovereign's Landing in Farside", unit_enum = "exile_farside"} },
			{ button = {bText="Use the Teleporter to the Touchdown Site Bravo next to the point you spawned and next to the 'Back to Thayd' teleporter", unit_enum = "exile_bravo"} },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=3779.2463378906, y=-718.32330322266, z=-5813.6567382813}, zone_id=4944} }
		}
	},
	[169] = {
		boss_name = "Kraggar",
		boss_short = "Krag",
		location = "Algoroc",
		way_to = {
			{ text = "Goto Thayd if not already there" },
			{ text = "Leave Thayd to the NORTH (by mount) and enter Algoroc" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=3552, y=-927, z=-3335}, zone_id=27 } }
		}
	},
	[593] = {
		boss_name = "Grendelus",
		boss_short = "Gren",
		location = "Celestion",
		way_to = {
			{ text = "In Thayd:" },
			{ button = {bText="Get to the Taxi", unit_enum = "exile_thayd_taxi"} },
			{ text = "Fly to Sylvan Glade (Celestion)" },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=2769, y=0, z=-1473}, zone_id= 300} } 
		}
	}, 
	[590] = {
		boss_name = "Dreamspore",
		boss_short = "DS",
		location = "Ellevar",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the Teleporter to Fool's Hope in Wilderrun", unit_enum="exile_wilderrun"} },
			{ button = {bText="Walk straight ahead and enter the MIDDLE Teleporter (out of 3) in opposite of your spawn location to get to Ellevar.", unit_enum = "exile_wilderrun_middle"} },
			{ text = "You will now be standing right before the Boss sight or perhaps the boss him self" }
		}
	}, 
	[150] = {
		boss_name = "Metal Maw",
		boss_short = "MM",
		location = "Deradune",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the Teleporter to Fool's Hope in Wilderrun", unit_enum="exile_wilderrun"} },
			{ button = {bText="Walk straight ahead and enter the LEFT Teleporter (out of 3) in opposite of your spawn location to get to Deradune.", unit_enum = "exile_wilderrun_left"} },
			{ text = "You will now be standing right before the Boss sight or perhaps the boss him self" }
		}
	},
	[372] = {
		boss_name = "King Honeygrave",
		boss_short = "KHG",
		location = "Auroria",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the Teleporter to Fool's Hope in Wilderrun", unit_enum="exile_wilderrun"} },
			{ button = {bText="Walk straight ahead and enter the RIGHT Teleporter (out of 3) in opposite of your spawn location to get to Auroria.", unit_enum="exile_wilderrun_right"} },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=-754.47192382813, y=-829.42950439453, z=-2244.4721679688}, zone_id=4852 } }
		}
	},
	[852] = {
		boss_name = "Gargantua",
		boss_short = "Garg",
		location = "The Defile",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the teleporter to Hope's Dare in The Defile", unit_enum = "exile_defile"} },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=4588.5170898438, y=-955.30914306641, z=-4536.7416992188}, zone_id=4158} }
		}
	}, 
	[847] = {
		boss_name = "King Plush",
		boss_short = "KP",
		location = "Galeras",
		way_to = {
			{ text = "In Thayd:" },
			{ button = {bText="Get to the Taxi", unit_enum = "exile_thayd_taxi"} },
			{ text = "Fly to Skywatch (Galeras)" },
			{ text = "Alternative: Use rapid transport (Button on the Minimap) to Stormwing Fortress (Galeras)" },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ text = "Note (when not using rapid transport): while moving towards the boss you cross the Stormwing Fortress.\nAs you follow the way through you will find a tornado.\nJump into it to get ported up to King Plush" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=6895, y=0, z=-2361}, zone_id=979} }
		}
	},
	[177] = {
		boss_name = "Metal Maw Prime",
		boss_short = "MMP",
		location = "Whitevale",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the Teleporter to Whitevale", unit_enmu = "exile_whitevale"} },
			{ text = "Alternative: Use rapid transport (Button on the Minimap) to the Wigwalli-Village (Whitevale)" },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=2014, y=0, z=338}, zone_id=240} }}
	},
	[491] = {
		boss_name = "Zoetic",
		boss_short = "Zoe",
		location = "Wilderrun",
		way_to = {
			{ text = "In Thayd: get the teleporters in sight" },
			{ button = {bText="Use the teleporter to Fool's Hope in Wilderrun", unit_enum = "exile_wilderrun"} },
			{ text = "Alternative: Use the rapid transport (Button on the Minimap) to the Deathbringer Hollow in Wilderrun" },
			{ text = "Press [M] (default to open the World Map) and go to where all your Raid-members are" },
			{ text = "\n" },
			{ button = {bText="You can also set a waypoint for the Boss spot", coords = {x=1094.7696533203, y=-699.96722412109, z=-3595.9206542969}, zone_id=1403} }
		}
	}
}

Apollo.RegisterPackage(wbEventIds, "wbEventIdsExile", 1, {})