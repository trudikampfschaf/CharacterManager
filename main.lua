local version = ".2";
local pname = UnitName("player");
local _, pclass = UnitClass("player");
local dungeons = {"Darkheart Thicket-DHT", "Eye of Azshara-EoA", "Halls of Valor-HoV", "Neltharion's Lair-NL", "Blackrook Hold-BRH", "Maw of Souls-MoS", "Vault of the Wardens-VotW", "Return to Karazhan: Lower-LK", "Return to Karazhan: Upper-UK", "Cathedral of Eternal Night-CoeN", "Court of Stars-CoS", "The Arcway-TA"};
local LA = LibStub:GetLibrary("LegionArtifacts-1.1")

local colors = {
    ["DEATHKNIGHT"] = "|cffC41F3B",
    ["DEMONHUNTER"] = "|cffA330C9",
    ["DRUID"]   = "|cffFF7D0A",
    ["HUNTER"]  = "|cffABD473",
    ["MAGE"]    = "|cff69CCF0",
    ["MONK"]    = "|cff00FF96",
    ["PALADIN"] = "|cffF58CBA",
    ["PRIEST"]  = "|cffffffff",
    ["ROGUE"]   = "|cffFFF569",
    ["SHAMAN"]  = "|cff0070DE",
    ["WARLOCK"] = "|cff9482C9",
    ["WARRIOR"] = "|cffC79C6E",
    ["GOLD"] = "|cffffcc00",
    ["RED"] = "|cffff0000",
};

-- LIGHTRED             |cffff6060
-- LIGHTBLUE           |cff00ccff
-- TORQUISEBLUE	 |cff00C78C
-- SPRINGGREEN	  |cff00FF7F
-- GREENYELLOW    |cffADFF2F
-- BLUE                 |cff0000ff
-- PURPLE		    |cffDA70D6
-- GREEN	        |cff00ff00
-- GOLD            |cffffcc00
-- GOLD2			|cffFFC125
-- GREY            |cff888888
-- WHITE           |cffffffff
-- SUBWHITE        |cffbbbbbb
-- MAGENTA         |cffff00ff
-- YELLOW          |cffffff00
-- ORANGEY		    |cffFF4500
-- CHOCOLATE		|cffCD661D
-- CYAN            |cff00ffff
-- IVORY			|cff8B8B83
-- LIGHTYELLOW	    |cffFFFFE0
-- SEXGREEN		|cff71C671
-- SEXTEAL		    |cff388E8E
-- SEXPINK		    |cffC67171
-- SEXBLUE		    |cff00E5EE
-- SEXHOTPINK	    |cffFF6EB4

local months = {
	[1] = 31,
	[2] = 28,
	[3] = 31,
	[4] = 30,
	[5] = 31,
	[6] = 30,
	[7] = 31,
	[8] = 31,
	[9] = 30,
	[10] = 31,
	[11] = 30,
	[12] = 31,

};

-- main
local cm_frame = CreateFrame("FRAME", "CharacterManager", UIParent, "BasicFrameTemplateWithInset"); -- Need a frame to respond to events
cm_frame:RegisterEvent("ADDON_LOADED");
cm_frame:RegisterEvent("ARTIFACT_UPDATE");
cm_frame:RegisterEvent("PLAYER_ENTERING_WORLD");
cm_frame:RegisterEvent("PLAYER_LOGOUT");

function cm_frame:OnEvent(event, name)
	if event == "ADDON_LOADED" and name == "CharacterManager" then
 		print(colors["GOLD"] .. "CharacterManager " .. version .. " loaded!");

 		
 		cm_frame:UnregisterEvent("ADDON_LOADED");

	 	-- init globals
	 	if _DB_ == nil then
	 		_DB_ = {};
	 	end

	 	if _NAMES_ == nil then
	 		_NAMES_ = {};
	 	end

	 	-- init name
	 	if not contains(_NAMES_, pname)  then 
	 		table.insert(_NAMES_, pname);
	 	end

	 	cm_frame:SetSize(300, (120 * table.getn(_NAMES_) + 50));
		cm_frame:SetPoint("CENTER", UIParent, "CENTER")
		cm_frame:EnableMouse(true);
		cm_frame:SetMovable(true);
		cm_frame:RegisterForDrag("LeftButton");
		cm_frame:SetScript("OnDragStart", cm_frame.StartMoving);
		cm_frame:SetScript("OnDragStop", cm_frame.StopMovingOrSizing);

		cm_frame.title = nil;
		cm_frame.title = cm_frame:CreateFontString();
		cm_frame.title:SetFontObject("GameFontHighlight");
		cm_frame.title:SetPoint("LEFT", cm_frame.TitleBg, "LEFT", 5, 0);
		cm_frame.title:SetText("Eoh's CharacterManager - v"..version);

		cm_frame.content = cm_frame:CreateFontString("CM_CONTENT");
		cm_frame.content:SetPoint("CENTER");
		cm_frame.content:SetFontObject("GameFontHighlight");

		cm_frame:SetScript("OnEvent",function(self)
	    	self.content:SetText(build_content())
		end)

		cm_frame:Hide();
	 	
	 	init();
	 	updates();
	 end
end

cm_frame:SetScript("OnEvent", cm_frame.OnEvent);
SLASH_CM1 = "/eoscm";
function SlashCmdList.CM(msg)
	if msg == "reset" then
		_NAMES_ = {}
		_DB_ = {}
		ReloadUI();

	elseif string.match(msg, "rm") then 
		remove_character(msg);
		ReloadUI();

	else
		init();
		updates();
		cm_frame:Show();
	end
end


function build_content()
	updates();

	s = "\n";
	for i=0, table.getn(_NAMES_) do 
		n = _NAMES_[i];

		if n then 
			s = s .. colors[_DB_[n.."cls"]] .. n .. "|r" .. "\n";
			s = s .. "Finished Key: " .. _DB_[n.."hkey"] .. "\n";
			s = s .. "Inventory: " .. _DB_[n.."bagkey"] .. "\n";
			s = s .. "Artifact lvl: " .. _DB_[n.."artifactlevel"] .. " (AK: " .. _DB_[n.."level"] .. ")" .. "\n";
			s = s .. "Next AK: " .. target_date_to_time(_DB_[n.."akremain"]) .. "\n";
			s = s .. "Seals: " .. _DB_[n.."seals"] .. "/6" .. "\n";
			if _DB_[n.."sealsobt"] == 0 then 
				s = s .. "Seals obtained: " .. colors["RED"] .. _DB_[n.."sealsobt"].. "|r" .. "/3" .. "\n";	
			else
				s = s .. "Seals obtained: " .. _DB_[n.."sealsobt"] .. "/3" .. "\n";	
			end
			s = s .. "Itemlevel: " .. _DB_[n.."itemlevel"] .. "/" .. _DB_[n.."itemlevelbag"] .. "\n";
			s = s .. "OResources: " .. _DB_[n.."orderres"] .. "\n";
			if table.getn(_NAMES_) > 1 and i ~= table.getn(_NAMES_) then 
				s = s .. "\n";
			end
		end
	end

	return s
end


function init()
		 	-- init vars
	 	if not _DB_[pname .. "cls"] then
	 		_DB_[pname .. "cls"] = pclass;
	 	end

	 	if not _DB_[pname .. "level"] then
	 		_DB_[pname .. "level"] = 0;
	 	end

	 	if not _DB_[pname .. "artifactlevel"] then
	 		_DB_[pname .. "artifactlevel"] = 0;
	 	end

	 	if not _DB_[pname .. "hkey"] then
	 		_DB_[pname .. "hkey"] = 0;
	 	end

	 	if not _DB_[pname .. "bagkey"] then
	 		_DB_[pname .. "bagkey"] = 0;
	 	end     

	 	if not _DB_[pname .. "seals"] then
	 		_DB_[pname .. "seals"] = 0;
	 	end

	 	if not _DB_[pname .. "itemlevel"] then
	 		_DB_[pname .. "itemlevel"] = 0;
	 	end

	 	if not _DB_[pname .. "itemlevelbag"] then
	 		_DB_[pname .. "itemlevelbag"] = 0;
	 	end

	 	if not _DB_[pname .. "orderres"] then
	 		_DB_[pname .. "orderres"] = 0;
	 	end

	 	if not _DB_[pname .. "akremain"] then
	 		_DB_[pname .. "akremain"] = "0 0 0 0";
	 	end
end


function updates()
	seals_update();
	seals_obtained_update();
	level_update();
	orderres_update();
	itemlevel_update();
	artifactlevel_update();
	bagkey_update();
	hkey_update();
	akremain_update();
end


-- Helper 
function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end


function tolist(i)
	lst = {};
	for item in i do
		table.insert(lst, item);
	end
	return lst;
end


function find(lst, val)
	for idx, item in ipairs(lst) do
		if item == val then
			return idx;
		end
	end

	return -1;
end


function target_date_to_time()
	local target_day = 0;
	local target_month = 0;
	local target_hour = 0;
	local target_min = "??";
	if _DB_[n.."akremain"] then
		for idx, item in ipairs(tolist(string.gmatch(_DB_[n.."akremain"], "%S+"))) do -- "d-m-h"
			if idx == 1 then
				target_day = item;

			elseif idx == 2 then
				target_month = item;

			elseif idx == 3 then 
				target_hour = item;

			elseif idx == 4 then
				target_min = item;

			end
		end

		local current_day;
		local current_month;
		local current_hour;
		local current_minute;
		for idx, item in ipairs(tolist(string.gmatch(date("%d %m %H %M"), "%S+"))) do
			if idx == 1 then 
				current_day = tonumber(item);
			elseif idx == 2 then
				current_month = tonumber(item);
			elseif idx == 3 then 
				current_hour = tonumber(item); 
			elseif idx == 4 then
				current_minute = tonumber(item);
			end
		end

		if tonumber(current_day) ~= tonumber(target_day) then
			if not string.match(target_min, "??") and tonumber(target_min) < 10 then
				target_min = "0" .. target_min;
			end

			if tonumber(current_minute) < 10 then
				current_minutes = "0" .. current_minute;
			end

			if string.match(target_min, "??") then
				return time_diff(current_month, current_day, current_hour, current_minute, target_month, target_day, target_hour, target_min) .. " (" .. target_day .. "." .. target_month .. " " .. target_hour .. " h)";
			else
				return time_diff(current_month, current_day, current_hour, current_minute, target_month, target_day, target_hour, target_min) .. " (" .. target_day .. "." .. target_month .. " " .. target_hour .. ":" .. target_min .. ")";
			end

		elseif target_hour - current_hour <= 0 and target_min - current_minute <= 0 then
			return colors["GOLD"] .. "PICK IT UP!" .. "|r";

		else
			if tonumber(target_min) < 10 then
				target_min = "0" .. target_min;
			end

			if tonumber(current_minute) < 10 then
				current_minute = "0" .. current_minute;
			end

			return colors["GOLD"] .. "Today" .. "|r" .. " at " .. target_hour .. ":" .. target_min .. " (" .. current_hour .. ":" .. current_minute .. ")";

		end
	else
		return "unknown";
	end
end

-- 2 is later than 1
function time_diff(m1, d1, h1, min1, m2, d2, h2, min2)
	local s = "";

	-- case min2 contains "??"
	-- just days and hr
	if string.match(min2, "??") then
		-- case same month
		if tonumber(m1) == tonumber(m2) then
			d =  tonumber(d2) - tonumber(d1);
			
			h = tonumber(h2) - tonumber(h1);
			if h < 0 then 
				d = d - 1;
				h = 24 - h1 + h2
			end
			s = s .. d .. " days ";
			s = s .. h .. " h"; 

		-- not the same month
		else
			s = s .. tonumber(d2) + tonumber(months[m1]) - tonumber(d1) .. " days ";
			s = s .. math.abs(tonumber(h2)-tonumber(h1)) .. " h"; 

		end

	-- case d1 == d2 => m1 == m2
	-- just hr and min
	elseif tonumber(d1) == tonumber(d2) then
		s = s .. math.abs(tonumber(h2)-tonumber(h1)) .. " h"; 
		s = s .. math.abs(tonumber(min1)-tonumber(min2)) .. " min";  
	end
	
	return s
end


function hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end


-- updater
function highest_key()
	local maps = C_ChallengeMode.GetMapTable();
	local highest_key = 0;
	for _, mapID in pairs(maps) do
		local _, _, level, affixes = C_ChallengeMode.GetMapPlayerStats(mapID);
        if level ~= nil and level > highest_key then
        	highest_key = level;
        end
    end

	return highest_key
end


function key_in_bags()
	for b=0, 5 do 
    	for s=0, GetContainerNumSlots(b) do 
	    	local link = GetContainerItemLink(b,s);
	    	if link then
		    	if string.match(link, "Keystone") then
					printable = gsub(link, "\124", "\124\124");

					firstpos = string.find(printable, ":")+1;
					firstcutoff = string.sub(printable, firstpos);

					secondpos = string.find(firstcutoff, ":")+1;
					secondcutoff = string.sub(firstcutoff, secondpos);

					thirdpos = string.find(secondcutoff, ":");
					thirdcutoff = string.sub(secondcutoff, 0, thirdpos-1);
					
					level = thirdcutoff;

					for i=1, table.getn(dungeons) do
						dungeon = dungeons[i];
						pos = string.find(dungeon, "-");
						short = string.sub(dungeon, pos+1);
						long = string.sub(dungeon, 0, pos-1);

						if string.match(printable, long) then
							return short .. "+" .. level
						end
					end
		    	end
		    end
    	end
    end
end


function artifactlevel_update()
	level = LA:GetPowerPurchased();
	if level then 
		_DB_[pname.."artifactlevel"] = level;
	end
end


function level_update()
	level = C_ArtifactUI.GetArtifactKnowledgeLevel();
	if level then 
		_DB_[pname.."level"] = level;
	end
end


function seals_obtained_update()
	local seals = 0;
	if IsQuestFlaggedCompleted(43510) then
		seals = seals + 1;
	end

	for i,q in ipairs({43892,43893,43894,43895,43896,43897}) do 
		if (IsQuestFlaggedCompleted(q)) then 
			seals = seals + 1;
		end 
	end 

	if _DB_[pname.."sealsobt"] then
		if tonumber(_DB_[pname.."sealsobt"]) < seals then
			_DB_[pname.."sealsobt"] = seals;			
		end
	elseif not _DB_[pname.."sealsobt"] then
		_DB_[pname.."sealsobt"] = seals;
	end
end


function seals_update()
	_, amount, _, _, _, _, _, _ = GetCurrencyInfo(1273);

	if amount then 
		_DB_[pname.."seals"] = amount;
	end
end


function orderres_update()
	_, amount, _, _, _, _, _, _ = GetCurrencyInfo(1220);

	if amount then 
		_DB_[pname.."orderres"] = amount;
	end
end


function itemlevel_update()
	avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel();
	avgItemLevel = math.floor(avgItemLevel*100)/100;
	avgItemLevelEquipped = math.floor(avgItemLevelEquipped*100)/100;

	if avgItemLevel then 
		if math.floor(avgItemLevel) ~= 0 then
			_DB_[pname.."itemlevelbag"] = avgItemLevel;
		end
	end

	if avgItemLevelEquipped then 
		if math.floor(avgItemLevelEquipped) ~= 0 then
			_DB_[pname.."itemlevel"] = avgItemLevelEquipped;
		end
	end
end


function bagkey_update()
 	local bagkey = key_in_bags();
 	if bagkey then
 		_DB_[pname .. "bagkey"] = bagkey;
 	end
end


function hkey_update()
	local hkey = highest_key();
 	if hkey then
 		_DB_[pname .. "hkey"] = hkey;
 	end
end


function akremain_update()
    local remaining_days = 0;
    local remaining_hours = 0;
    local remaining_minutes = 0;
	local current_month = 0;
	local current_day = 0;
	local current_hour = 0;
	local current_minutes = 0;

    local t = C_Garrison.GetLooseShipments(3);
    local i = 1;
    for l = i,#t do 
        local c = C_Garrison.GetLandingPageShipmentInfoByContainerID(C_Garrison.GetLooseShipments(3)[l]);
        if c=="Artifact Research Notes" then 
            i=l;
            break
        end
    end

    if not C_Garrison.GetLooseShipments(3)[i] then
		return 
	end

    local _, _, _, _, _, _, _, tlStr = C_Garrison.GetLandingPageShipmentInfoByContainerID(C_Garrison.GetLooseShipments(3)[i]);

    if tlStr then
		local lst = tolist(string.gmatch(tlStr, "%S+"));

		 -- days and hr
		if string.match(lst[2], "days") and string.match(lst[4], "hr") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_days = item;
		    	elseif idx == 3 then
		    		remaining_hours = item;
		    	end
		    end
		    remaining_minutes = "??";

		-- days only because hours == 0
		elseif string.match(lst[2], "days") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_days = item;
		    	end
		    end
		    remaining_hours = 0;
		    remaining_minutes = "??";

		-- hr and mins
		elseif string.match(lst[2], "hr") and string.match(lst[4], "min") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_hours = item;
		    	elseif idx == 3 then
		    		remaining_minutes = item;
		    	end
		    end

		-- mins only because hrs == 0
		elseif string.match(lst[2], "min") then 
			for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_minutes = item;
		    	end
		    end

		else
			print("No matching time found, AK research may be wrong for this Char");
			print("DEBUGINFO: >" .. tostring(lst[2]) .. "<" .. " and " .. ">" .. tostring(lst[4]) .. "<");
			return 
		end
	    
	    local current_time = date("%d %m %H %M");
		if current_time then
			local lst = tolist(string.gmatch(current_time, "%S+"));

			for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		current_day = tonumber(item);
		    	elseif idx == 2 then
		    		current_month = tonumber(item);
		    	elseif idx == 3 then
		    		current_hour = tonumber(item);
		    	elseif idx == 4 then
		    		current_minutes = tonumber(item);
		    	end
		    end
		end

		local target_day = current_day + remaining_days;
		local target_month = current_month;
		local target_hour = current_hour + tonumber(remaining_hours);

		if not string.match(remaining_minutes, "??") then
			target_min = current_minutes + remaining_minutes;
		else 
			target_min = remaining_minutes;
		end
		
		if not string.match(target_min, "??") and target_min > 60 then
			target_min = target_min - 60;
			target_hour = target_hour + 1;
		end

		if target_hour > 24 then 
			target_hour = target_hour - 24;
			target_day = target_day + 1;

			if target_day > months[tonumber(target_month)] then
				target_day = target_day - months[target_month];
				target_month = target_month + 1;

				if target_month > 12 then
					target_month = 1;
				end
			end
		end

		target_month = tonumber(target_month);
		target_day = tonumber(target_day);
		target_hour = tonumber(target_hour);

		time_string = target_day .. " " .. target_month .. " " .. target_hour .. " " .. target_min;

		if time_string then 
			--print("updating: " .. time_string);
			_DB_[pname .. "akremain"] = time_string; 
		end
	 	
	end
end


function remove_character(msg)
	local lst = tolist(string.gmatch(msg, "%S+"));
	local cmd = lst[1];
	local name_to_remove = lst[2];

	if #lst ~= 2 or lst[1] ~= "rm" then
		print("Command unknown! :(");

	else 
		if contains(lst, name_to_remove) then
			print("Successfully removed: " .. table.remove(_NAMES_, find(_NAMES_, name_to_remove)));

		else
			print("name unknown");
		end
	end
end


-- TODO 
-- wq oneshot?
-- auf aktuellem char auslesen, ob AK rdy
-- id reset

