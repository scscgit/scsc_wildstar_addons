local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Gear_Durability", "deDE")
if not L then return end

          L["GP_FLAVOR"] = "Bleiben Sie informiert über Artikel Haltbarkeit."
	  L["GP_O_SETTINGS"] = "Haltbarkeit"
	 L["GP_O_SETTING_1"] = "Haltbarkeitsalarm <"
     L["GP_O_SETTING_2"] = "Zeigen Sie Haltbarkeit in %"
	 L["GP_O_SETTING_3"] = "Artikellokalisierung"
     L["GP_O_SETTING_4"] = "Einzelteilfortschritt"
	       L["GP_FIRED"] = "Alarmauslöser bei &lt;"	-- xml	 
	-- location
	       L["GP_LOC_0"] = "fehlend"
	       L["GP_LOC_1"] = Apollo.GetString("InterfaceMenu_Inventory")
	       L["GP_LOC_2"] = Apollo.GetString("Bank_Header")
	       L["GP_LOC_3"] = "Ausgerüstet"		        	      
