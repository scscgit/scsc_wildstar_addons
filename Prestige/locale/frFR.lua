local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Prestige", "frFR")
if not L then return end
	  
	      L["P_HAVE"] = "Vous possédez"	
	      L["P_BAGS"] = "sac(s)"
         L["P_STOCK"] = "en stock."
        L["P_DETAIL"] = "pour le détail"
		    L["P_IN"] = "dans"
		   L["P_BAG"] = Apollo.GetString("InterfaceMenu_Inventory")
		  L["P_BANK"] = Apollo.GetString("Bank_Header")
		  L["P_MAIL"] = Apollo.GetString("InterfaceMenu_Mail")
		  L["P_DESC"] = "Entre crochets vous voyez le Prestige pour les sacs JcJ non ouverts."