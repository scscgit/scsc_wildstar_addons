local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Gear_Durability", "frFR")
if not L then return end

          L["GP_FLAVOR"] = "Durabilité des Objets pour chaque Profil."
	  L["GP_O_SETTINGS"] = "Durabilité"
	 L["GP_O_SETTING_1"] = "Déclencher l'Alarme lorsque l'état est < "
	 L["GP_O_SETTING_2"] = "Afficher la Durabilité en %"
	 L["GP_O_SETTING_3"] = "Indiquer la Localisation de l'Équipement"
	 L["GP_O_SETTING_4"] = "Voir une Jauge sur chaque Objet"
	       L["GP_FIRED"] = "Déclenchement de l'Alarme à &lt;"	-- xml
	 -- location
		   L["GP_LOC_0"] = "Non trouvé" -- xml
	       L["GP_LOC_1"] = Apollo.GetString("InterfaceMenu_Inventory") -- xml
	       L["GP_LOC_2"] = Apollo.GetString("Bank_Header") -- xml
           L["GP_LOC_3"] = "Équipé" -- xml