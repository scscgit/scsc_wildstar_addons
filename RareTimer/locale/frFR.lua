-- Thanks to Leosky for the proper translations. The butchered ones are my own. :D

local Locale = "frFR"
local IsDefaultLocale = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)
if not L then return end

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer registre d'�tat:" 
L["AlertHeading"] = "Alerte de RareTimer:"
L["Name"] = "Nom"
L["Status"] = "Condition"
L["Last kill"] = "Tu�"
L["Health"] = "Vie"

--Msgs
L["NewVersionMsg"] = "Une nouvelle version de RareTimer est disponible."
L["ObsoleteVersionMsg"] = "RareTimer n'est pas � jour et ne recevra plus de mises � jour d'autres clients."
L["SnoozeMsg"] = "RareTimer: N'alerter pas pour %s minutes."
L["SnoozeResetMsg"] = "RareTimer: Rappel d'alarme remise � z�ro."
L["Y"] = "O" -- Yes
L["N"] = "N" -- No

--Button strings
L["Snooze"] = "Rappel"

--Option strings
L["OptSnoozeTimeout"] = "Dur�e du rappel d'alarme (minutes)"
L["OptSnoozeTimeoutDesc"] = "Dur�e pendant qu'on n'alerte pas apres rappel d'alarm."
L["OptSnoozeReset"] = "Remiser � z�ro le rappel d'alarm"
L["OptSnoozeResetDesc"] = "Remiser � z�ro le rappel d'alarm"
L["OptTargetTimeout"] = "N'alerter pas apr�s avoir cibl� (minutes)"
L["OptTargetTimeoutDesc"] = "N'alerter pas si on a cibl� l'ennemi dans le d�lai."
L["OptPlaySound"] = "Faire sonner"
L["OptPlaySoundDesc"] = "Faire sonner lorsque l'alerte est d�clencher."

--Time strings
L["s"] = "s" -- Seconds
L["m"] = "m" -- Minutes
L["h"] = "h" -- Hours
L["d"] = "j" -- Days

-- State strings
L["StateUnknown"] = 'Inconnu'
L["StateKilled"] = 'Tu� � %s'
L["StateDead"] = 'Tu� au plus tard � %s'
L["StatePending"] = 'Devrait reparaitre avant %s'
L["StateAlive"] = 'En vie (%s)'
L["StateInCombat"] = 'En combat'
L["StateExpired"] = 'Inconnu (vu la derni�re fois � %s)'
L["StateTimerSoon"] = 'Bient�t (%s)'
L["StateTimerTick"] = 'Commenc� � %s'
L["StateTimerRunning"] = 'Prochain � %s'
 
-- Mob names
L["Aggregor the Dust Eater"] = "Aggregor le M�chepoussi�re"
L["Bugwit"] = "Bugwit"
L["Critical Containment"] = "Tissu d'horreurs"
L["Defensive Protocol Unit"] = "Unit� de protocoles d�fensifs"
L["Doomthorn the Ancient"] = "Funest�pine l'Ancien"
L["Gargantua"] = "Gargantua"
L["Grendelus the Guardian"] = "Gardien Grendelus"
L["Grinder"] = "Broyeur" 
L["Hoarding Stemdragon"] = "Plandragon avide"
L["KE-27 Sentinel"] = "Sentinelle KE-27"
L["King Honeygrave"] = "Roi Nectaruine"
L["Kraggar the Earth-Render"] = "Kraggar le Cr�ve-terre"
L["Metal Maw"] = "Gueule d'acier"
L["Metal Maw Prime"] = "Primo Gueule d'acier"
L["Scorchwing"] = 'Ailardente'
L["Subject J - Fiend"] = "Sujet J : d�mon"
L["Subject K - Brute"] = "Sujet K : brute"
L["Subject Tau"] = "Sujet Tau"
L["Subject V - Tempest"] = "Sujet V : temp�te"
L["Zoetic"] = "Zoetic"
L["Star-Comm Basin"] = "Star-Comm Basin"