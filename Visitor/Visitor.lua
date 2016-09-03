--mmaybe@gmail.com

--   todo
-- check if name is on neighborlist
-- check for part of name??
-- lowercase - check
-- favorites - check
-- zone check
-- textbox lose focus/ReadOnly on Go! - check
-- click on user in chat - check


-----------------------------------------------------------------------------------------------
-- Client Lua Script for Visitor
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Visitor Module Definition
-----------------------------------------------------------------------------------------------
local Visitor = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
golook = false;
showfavorites = false;
favorites = {};
housenames = {};
notes = {"",""};
MainWindow = nil;
errors = {"","Still a normal search, hold on","Taking quite long...","Hmm this is odd","Are you sure its a public house?"};
errorlevels = {0,300,500,800,1200};



-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Visitor:new(o)

    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Visitor:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Visitor OnLoad
-----------------------------------------------------------------------------------------------
function Visitor:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Visitor.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	


	
	
	   self.contextMenu = Apollo.GetAddon("ContextMenuPlayer")


-- Add an extra button to the player context menu
    local oldRedrawAll = self.contextMenu.RedrawAll
    self.contextMenu.RedrawAll = function(context)
        if self.contextMenu.wndMain ~= nil then
            local wndButtonList = self.contextMenu.wndMain:FindChild("ButtonList")
            if wndButtonList ~= nil then
                local wndNew = wndButtonList:FindChildByUserData(tObject)
                if not wndNew then
                    wndNew = Apollo.LoadForm(self.contextMenu.xmlDoc, "BtnRegular", wndButtonList, self.contextMenu)
                    -- scsc wndNew is null
                    if wndNew then
                        wndNew:SetData("BtnVisitorButtonHome")
                    end
                end
                -- scsc wndNew is null
                if wndNew then
                    wndNew:FindChild("BtnText"):SetText("Visit Home")
                end
            end
        end
        oldRedrawAll(context)
    end

    -- catch the event fired when the player clicks the context menu
    local oldContextClick = self.contextMenu.ProcessContextClick
    self.contextMenu.ProcessContextClick = function(context, eButtonType)
        if eButtonType == "BtnVisitorButtonHome" then
            Visitor:FindThis(self.contextMenu.strTarget)
        else
            oldContextClick(context, eButtonType)
        end
    end


	
	
	
end

-----------------------------------------------------------------------------------------------
-- Visitor OnDocLoaded
-----------------------------------------------------------------------------------------------
function Visitor:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "VisitorForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	MainWindow=self.wndMain;

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("visit", "OnVisitorOn", self)
Apollo.RegisterEventHandler("HousingRandomResidenceListRecieved", "TimeToCheck", self)

		-- Do additi6onal Addon initialization here
		

			self.totalnamelist = {}
			self.totalsearches = 0;

		
		
		
		
		
	end
end

-----------------------------------------------------------------------------------------------
-- Visitor Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function Visitor:RefreshFavorites()
	--update favorite list
		local gridRoster = MainWindow:FindChild("FavoriteList");
		gridRoster:DeleteAll();
		i=0;
		while favorites[i+1] ~= nil  do
 			i=i+1;
local iCurrRow = gridRoster :AddRow("")
		gridRoster:SetCellText(iCurrRow,1,favorites[i]);
		gridRoster:SetCellText(iCurrRow,2,housenames[i]);


--			gridRoster:SetCellLuaData(i,3,notes[i]);
		end

end

function Visitor:AddFavorite(TargetName)
		i=0;
		while favorites[i+1] ~= nil  do
 			i=i+1;
			if string.lower(favorites[i])==string.lower(TargetName) then return end
			
		end
		favorites[#favorites+1]=TargetName;
		housenames[#housenames+1]="Not scanned yet";
		notes[#notes+1]="<>";
		Visitor:RefreshFavorites();

end

function Visitor:RemoveFavorite(TargetName)
		i=0;
		while favorites[i+1] ~= nil  do
 			i=i+1;
			if string.lower(favorites[i])==string.lower(TargetName) then 
			 table.remove(favorites,i);
			 table.remove(housenames,i);
			 table.remove(notes,i);
			Visitor:RefreshFavorites();
  			 return;
			end
		end
		
end


-- on SlashCommand "/visit"
function Visitor:OnVisitorOn()
Visitor:StopSearch();
	self.wndMain:Invoke(); -- show the window
	Visitor:FixWindowSize();
	Visitor:RefreshFavorites();
						

	--HousingLib.VisitNeighborResidence(1);
--HousingLib.GetPlot()
--HousingLib.RequestRandomVisit(1);

--Hearths Garden [Hearth]
--Print (table.tostring(aaa));
--Print(aaa[1].nId);

--Print("debug : ");

	end
function Visitor:FindThis(TargetName)
	MainWindow:Invoke();
	Visitor:FixWindowSize();
	Visitor:RefreshFavorites();

	if golook==true then 
	Print("Stop current search first!");
	return;
	end

	 MainWindow:FindChild("FindMe"):SetText(""..TargetName);
	 Visitor:StartSearch();
	
	
	
end
	
	function Visitor:UpdateFavoriteHouseName(tarPlayerName, TheHouseName)
		ii=0;
	--	Print("totalfavorites : "..#favorites);
		while ii < #favorites  do
 			ii=ii+1;
			if favorites[ii] == nil then return end
		--	Print("CheckingFavorite : "..ii);

			if string.lower(tarPlayerName) == string.lower(favorites[ii]) then 
				favorites[ii]=tarPlayerName;
				oldhousename = housenames[ii];
				housenames[ii]=TheHouseName;
				if oldhousename ~= housenames[ii] then Visitor:RefreshFavorites() end
				
				return;
				end
				

		end
	
	end

function Visitor:TimeToCheck()
	if HousingLib.IsHousingWorld() == false then
	 MainWindow:FindChild("MessageToUser"):SetText("Stopped : Not in a house");
 	 Visitor:StopSearch();
	 return;
	end;
		
	
	if golook == false then 
--	Print("Bailed");
	return;
	end
		self.wndMain:FindChild("Counter"):SetText("Searches : " .. self.totalsearches .. "");
--		Print("Looking");
	local targetname = string.lower(self.wndMain:FindChild("FindMe"):GetText());

	
	local found = false;
	local aaa = HousingLib.GetRandomResidenceList();
	--Print(#aaa);

	local i=0;
		while i < #aaa do
    	i=i+1;
		if aaa[i] == nil  then
		i=i+100;
		else
		   --update favorite
			local name = aaa[i].strCharacterName;
			local hname=aaa[i].strResidenceName;
			Visitor:UpdateFavoriteHouseName(name,hname);
			
			self.totalnamelist[name]=1;
			
			

--	Print(table.tostring(aaa[1]));
			if string.lower(name) == targetname  then 
				found = true;
				golook = false;
				self.totalsearches = 0
				self.totalnamelist = {}
 				HousingLib.RequestRandomVisit(aaa[i].nId);
				MainWindow:FindChild("FindMe"):RemoveStyleEx("ReadOnly");
				return
			end
		end
	
  	end
if found == false then 
MainWindow:FindChild("MessageToUser"):SetText("Total unique houses received : "..tablelength(self.totalnamelist));


self.totalsearches =self.totalsearches +1;
i=0;
while errorlevels[i+1] == not nil do
i=i+1;
 if self.totalsearches > errorlevels[i] then 
 -- self.wndMain:FindChild("MessageToUser"):SetText(errors[i]);
 end
end


end
HousingLib.RequestRandomResidenceList();
end

	
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end
-----------------------------------------------------------------------------------------------
-- VisitorForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Visitor:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function Visitor:OnCancel()
	self.wndMain:Close() -- hide the window
end

function Visitor:StartSearch()


MainWindow:FindChild("MessageToUser"):SetText("");
--check zone
if HousingLib.IsHousingWorld() == false then
 MainWindow:FindChild("MessageToUser"):SetText("Enter a house first!");
 return;
end;
self.totalsearches = 1;
self.totalnamelist = {}
--check if neighbor
thename = string.lower(MainWindow:FindChild("FindMe"):GetText());
nblist=HousingLib.GetNeighborList();
j=0;
while nblist[j+1] ~= nil do
 j=j+1;
 if string.lower(nblist[j].strCharacterName) == thename then 
HousingLib.VisitNeighborResidence(nblist[j].nId);
return;

 end

end




--find target

MainWindow:FindChild("FindMe"):AddStyleEx("ReadOnly");
golook = true;
self.totalsearches = 1;
self.totalnamelist = {}

HousingLib.RequestRandomResidenceList();


end



function Visitor:GoFindIt( wndHandler, wndControl, eMouseButton )
if golook==true then 
 MainWindow:FindChild("MessageToUser"):SetText("Stop current search first!");
return;
end
self.totalsearches = 0;
self.totalnamelist = {}
Visitor:StartSearch();
end

function Visitor:StopIt()
golook = false;
MainWindow:FindChild("FindMe"):RemoveStyleEx("ReadOnly");
end

function Visitor:ToggleFavorites( wndHandler, wndControl, eMouseButton )
showfavorites = not showfavorites;
Visitor:FixWindowSize();
end

function Visitor:StopSearch( wndHandler, wndControl, eMouseButton )
Visitor:StopIt();


end

function Visitor:FixWindowSize()
local x1,y1,x2,y2 = MainWindow:GetAnchorOffsets();
--self.wndMain:GetAnchorOffsets
--Print(x1.." "..y1.." "..x2.." "..y2);

if showfavorites == false then
 MainWindow:SetAnchorOffsets(x1,y1,x1+299,y1+309);
-- self.wndMain:FindChild("FavoriteList"):IsVisible = true;
-- MainWindow:FindChild("FavoriteList"):Hide();
MainWindow:FindChild("FavoriteList"):SetOpacity(0.0,100.0);
end


if showfavorites == true then
 MainWindow:SetAnchorOffsets(x1,y1,x1+532,y1+309);
--MainWindow:FindChild("FavoriteList"):Show();
-- MainWindow:FindChild("FavoriteList"):SetAttribute("Visible","1");
MainWindow:FindChild("FavoriteList"):SetOpacity(1.0,100.0);

end

end

function Visitor:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Realm then
        return nil
    end

    -- create a table to hold our data
    local tSave = {}
	i=0;
	while favorites[i+1] ~= nil  do
    	i=i+1;
        -- for each player in our list, create a table using the name as our key
        tSave[i] = {}
        -- save a table version of the color
        tSave[i].name = favorites[i];
        tSave[i].house = housenames[i];
        tSave[i].note = notes[i];


    end

    -- simply return this value and Apollo will save the file!
    return tSave
end

function Visitor:OnRestore(eLevel, tData)
--	Print(table.tostring(tData));
		iii=0;
	while tData[iii+1] ~= nil  do
		iii=iii+1;
    	favorites[iii] = tData[iii].name;
    	housenames[iii] = tData[iii].house;
    	notes[iii] = tData[iii].note;
	end

--	Print(#favorites);

end

function Visitor:PressAddFav( wndHandler, wndControl, eMouseButton )
self:AddFavorite(self.wndMain:FindChild("FindMe"):GetText());
end

function Visitor:PressRemoveFav( wndHandler, wndControl, eMouseButton )
self:RemoveFavorite(self.wndMain:FindChild("FindMe"):GetText());
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


function Visitor:FavoriteListClick(wndControl, wndHandler, iRow, iCol, eClick)
 celltext = MainWindow:FindChild("FavoriteList"):GetCellText(iRow,1);
 if golook == false and celltext ~= nil and celltext ~= "" then 
  MainWindow:FindChild("FindMe"):SetText(celltext);
 end

end

function Visitor:TeleportHome( wndHandler, wndControl, eMouseButton )
if HousingLib.IsHousingWorld() == false then 

else
 HousingLib.RequestTakeMeHome();
end
end

-----------------------------------------------------------------------------------------------
-- Visitor Instance
-----------------------------------------------------------------------------------------------
local VisitorInst = Visitor:new()
VisitorInst:Init()
