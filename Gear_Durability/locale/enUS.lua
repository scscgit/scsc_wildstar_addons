local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Gear_Durability", "enUS", true)
if not L then return end

          L["GP_FLAVOR"] = "Stay informed about Items Durability."
	  L["GP_O_SETTINGS"] = "Durability"
	 L["GP_O_SETTING_1"] = "Durability Alarm <"
     L["GP_O_SETTING_2"] = "Show Durability in %"
	 L["GP_O_SETTING_3"] = "Item Location"
     L["GP_O_SETTING_4"] = "Item Progress Bar"
	       L["GP_FIRED"] = "Alarm Trigger at &lt;"	-- xml	 
	-- location
	       L["GP_LOC_0"] = "Missing"
	       L["GP_LOC_1"] = Apollo.GetString("InterfaceMenu_Inventory")
	       L["GP_LOC_2"] = Apollo.GetString("Bank_Header")
	       L["GP_LOC_3"] = "Equipped"	     			
