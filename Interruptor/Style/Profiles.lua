Apollo.GetAddon("Interruptor").tProfilesFile = {

{ Name = "Carbinish",
	Castbar = {
		Colors = {
			vulnerable = "ffa00499",
			interruptable = "ff00ff00",  
			uninterruptable = "ff990000",
			highlighted = "fffe3c06",
			background = "ff0f2c2e",
			border = "ff00cdb4"}, --ff00f7df
		Textures = {
			main = "BarStandard",
			border = "Carbinish",
			background = "Plain"},
		Sliders = {
			padding = 2,
			bordersize = 6 }
	},
	InterruptArmor = {
		Colors = {
			destroyed = "ff00ff00",
			undestroyed = "ff00aeff",
			selfdestroyed = "ffffff00",
			background = "ff0f2c2e",
			border = "ff00cdb4"},
		Textures = {
			main = "IAStandard",
			border = "Carbinish",
			background = "Plain"},
		Sliders = {
			padding = 2,
			bordersize = 6,
			gap = 4 }
	},
	Icon = {
		Colors = {
			background = "ff0f2c2e",
			border = "ff00cdb4"},
		Textures = {
			border = "CarbinishIcon",
			background = "Plain"},
		Sliders = {
			padding = 1,
			bordersize = 6 }
	}
},

{ Name = "SCastbar",
	Castbar = {
		Colors = {
			vulnerable = "ffa00499",
			interruptable = "ff0d75f8",  --ff0066ff
			uninterruptable = "ff990000",
			highlighted = "fffe3c06",
			background = "ff282828",
			border = "ff000000"},
		Textures = {
			main = "Texture 46",
			border = "Plain",
			background = "Plain"},
		Sliders = {
			padding = 1,
			bordersize = 2 }
	},
	InterruptArmor = {
		Colors = {
			destroyed = "ff00ff00",
			undestroyed = "ff0d75f8",
			selfdestroyed = "ffffff00",
			background = "ff282828",
			border = "ff000000"},
		Textures = {
			main = "IAStandard",
			border = "Plain",
			background = "Plain"},
		Sliders = {
			padding = 1,
			bordersize = 2,
			gap = 4 }
	},
	Icon = {
		Colors = {
			background = "ff282828",
			border = "ff000000"},
		Textures = {
			border = "Plain",
			background = "Plain"},
		Sliders = {
			padding = 1,
			bordersize = 2 }
	}
}
}