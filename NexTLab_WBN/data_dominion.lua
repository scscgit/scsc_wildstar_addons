local wbEventIds = {
	[855] = { 
		boss_name = "Scorchwing",
		boss_short = "SW",
		location = "Blighthaven",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Blighthaven;\n2. Head North-West to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Nursery Trading (Blighthaven)" }
		}
	},
	[586] = {
		boss_name = "Mechathorn",
		boss_short = "MT",
		location = "Farside",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Farside;\n2. Use the teleporter to Touchdown Site Bravo;\n3. Head North to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Warbringer's Break (Farside)" }
		}
	},
	[169] = {
		boss_name = "Kraggar",
		boss_short = "Krag",
		location = "Algoroc",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Wilderrun;\n2. Climb up the hill and enter the right teleporter in Palerock Post;\n3. Head North to the yellow hexagon on the map." }
		}
	},
	[593] = {
		boss_name = "Grendelus",
		boss_short = "Gren",
		location = "Celestion",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Wilderrun;\n2. Climb up the hill and enter the middle teleporter in Palerock Post;\n3. Head South to the yellow hexagon on the map." }
		}
	}, 
	[590] = {
		boss_name = "Dreamspore",
		boss_short = "DS",
		location = "Ellevar",
		way_to = {
			{ text = "From Illium:\n\n1. Take the Taxi to Lightreach Mission (Ellevar);\n2. Head North, through the spider caves, to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Lightreach Mission (Ellevar)" }
		}
	}, 
	[150] = {
		boss_name = "Metal Maw",
		boss_short = "MM",
		location = "Deradune",
		way_to = {
			{ text = "From Illium:\n\n1. Take the Taxi to Feralplain Testing Range (Deradune);\n2. Head South to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Outreach Post (Deradune)" }
		}
	}, 
	[852] = {
		boss_name = "Gargantua",
		boss_short = "Garg",
		location = "The Defile",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Defile;\n2. Head East to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to The Black Focus (Defile)" }
		}
	}, 
	[847] = {
		boss_name = "King Plush",
		boss_short = "KP", 
		location = "Galeras",
		way_to = {
			{ text = "From Illium:\n1. Use the teleporter to Wilderrun;\n2. Climb up the hill and enter the left teleporter in Palerock Post;\n3. Jump down from the platform and into the tornado." }
		}
	},
	[177] = {
		boss_name = "Metal Maw Prime",
		boss_short = "MMP",
		location = "Whitevale",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Whitevale;\n2. Take the Taxi to Prosperity Junction (Whitevale);\n2. Head West to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Camp Virtue (Whitevale)" }
		}
	},
	[372] = {
		boss_name = "King Honeygrave",
		boss_short = "KHG",
		location = "Auroria",
		way_to = {
			{ text = "From Illium:\n\n1. Take the Taxi to Protostar Cubig Farms (Auroria);\n2. Head East to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Protostar Honeyworks (Auroria)" }
		}
	},
	[491] = {
		boss_name = "Zoetic",
		boss_short = "Zoe",
		location = "Wilderrun",
		way_to = {
			{ text = "From Illium:\n\n1. Use the teleporter to Wilderrun;\n2. Take the Taxi to Marshal's Haven (Wilderrun);\n3. Head West to the yellow hexagon on the map.\n\nAlternative: Use rapid transport to Deathbringer Hollow (Wilderrun)" }
		}
	}
}

Apollo.RegisterPackage(wbEventIds, "wbEventIdsDominion", 1, {})