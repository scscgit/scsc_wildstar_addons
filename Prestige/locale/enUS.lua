local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Prestige", "enUS", true)
if not L then return end
	  
	      L["P_HAVE"] = "You possess"	
	      L["P_BAGS"] = "bag(s)"
         L["P_STOCK"] = "in stock."
	    L["P_DETAIL"] = "for detail"
		    L["P_IN"] = "in"
		   L["P_BAG"] = Apollo.GetString("InterfaceMenu_Inventory")
		  L["P_BANK"] = Apollo.GetString("Bank_Header")
		  L["P_MAIL"] = Apollo.GetString("InterfaceMenu_Mail")
		  L["P_DESC"] = "In brackets you see Prestige for unopened PvP bags."