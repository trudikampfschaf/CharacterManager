local version = ".5";
local pname = UnitName("player");
local _, pclass = UnitClass("player");
local LA = LibStub:GetLibrary("LegionArtifacts-1.1")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local week = 604800;
local na_reset  = 1486479600;
local eu_reset  = 1485327600;

local dungeons = {"Darkheart Thicket-DHT", "Eye of Azshara-EoA", "Halls of Valor-HoV", "Neltharion's Lair-NL", "Blackrook Hold-BRH", "Maw of Souls-MoS", "Vault of the Wardens-VotW", "Return to Karazhan: Lower-LK", "Return to Karazhan: Upper-UK", "Cathedral of Eternal Night-CoeN", "Court of Stars-CoS", "The Arcway-TA"};
local world_quest_one_shot = {"DEATHKNIGHT", "DEMONHUNTER", "MAGE", "PALADIN", "WARLOCK", "WARRIOR"};
local world_quest_one_shot_ids = {["DEATHKNIGHT"]=221557, ["DEMONHUNTER"]=221561, ["MAGE"]=221602, ["PALADIN"]=221587, ["WARLOCK"]=219540, ["WARRIOR"]=221597};

local option_choices = {"Mythic+ Info", "Artifact level (AK)", "AK research", "Current seals", "Seals obtained", "Itemlevel", "OResources", "Nighthold ID", "WQ 1shot", "Minimap Icon"};

local window_shown = false;
local options_shown = false;

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
    ["UNKNOWN"]  = "|cffffffff",
    ["GREEN"] = "|cff00ff00",
    ["WHITE"] = "|cffffffff",
};


-- LIGHTRED             |cffff6060
-- LIGHTBLUE           |cff00ccff
-- TORQUISEBLUE	 |cff00C78C
-- SPRINGGREEN	  |cff00FF7F
-- GREENYELLOW    |cffADFF2F
-- BLUE                 |cff0000ff
-- PURPLE		    |cffDA70D6
-- GOLD            |cffffcc00
-- GOLD2			|cffFFC125
-- GREY            |cff888888
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

-------------------------------------------------------------------------------------
local addon = LibStub("AceAddon-3.0"):NewAddon("CharacterManager", "AceConsole-3.0")
local eoscmLDB = LibStub("LibDataBroker-1.1"):NewDataObject("eoscm_minimap", {
	type = "data source",
	text = "CharacterManager",
	icon = "Interface\\AddOns\\CharacterManager\\eoscm",
	OnClick = function() show_window() end,
	OnTooltipShow = function(tt)
		tt:AddLine("Eoh's CharacterManager");
		tt:AddLine(colors["WHITE"] .. "Click|r to open Eoh's CharacterManager");
		tt:AddLine(colors["WHITE"] .. "Click and hold|r to drag the icon");
	end,
})
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	-- Obviously you'll need a ## SavedVariables: BunniesDB line in your TOC, duh!
	self.db = LibStub("AceDB-3.0"):New("_EOSCM_DB_", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	icon:Register("eoscm_minimap", eoscmLDB, self.db.profile.minimap)
	self:RegisterChatCommand("hidemm", "HideMiniMap")
end

function addon:HideMiniMap()
	self.db.profile.minimap.hide = not self.db.profile.minimap.hide
	if self.db.profile.minimap.hide then
		icon:Hide("eoscm_minimap")
	else
		icon:Show("eoscm_minimap")
	end
end
-------------------------------------------------------------------------------------


-- main
local cm_frame = CreateFrame("FRAME", "CharacterManager", UIParent, "BasicFrameTemplateWithInset"); -- Need a frame to respond to events
cm_frame:RegisterEvent("ADDON_LOADED");
cm_frame:RegisterEvent("ARTIFACT_UPDATE");
cm_frame:RegisterEvent("PLAYER_ENTERING_WORLD");
cm_frame:RegisterEvent("PLAYER_LOGOUT");
cm_frame:RegisterEvent("QUEST_FINISHED");

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

	  	if _NEXT_RESET_ == nil then
	 		_NEXT_RESET_ = 0;
	 	end

	 	if _OPTIONS_ == nil then
	 		_OPTIONS_ = {
				["Mythic+ Info"] = true, 
				["Artifact level (AK)"] = true, 
				["AK research"] = true, 
				["Current seals"] = true, 
				["Seals obtained"] = true, 
				["Itemlevel"] = true, 
				["OResources"] = true, 
				["Nighthold ID"] = true,
				["WQ 1shot"] = true,
			};
		end

		if _TRACKED_CHARS_ == nil then
	 		_TRACKED_CHARS_ = {};

	 		for _, item in ipairs(_NAMES_) do 
	 			if _TRACKED_CHARS_[item] == nil then
	 				_TRACKED_CHARS_[item] = true;
	 			end
	 		end
	 	end


	 	-- init name
	 	if not contains(_NAMES_, pname)  then 
	 		table.insert(_NAMES_, pname);
	 	end

	 	if _TRACKED_CHARS_[pname] == nil then 
	 		_TRACKED_CHARS_[pname] = true;
	 	end

	 	-- init class
	 	if not _DB_[pname.."cls"] then 
	 		_DB_[pname.."cls"] = pclass;
	 	end

	 	if _DB_[pname.."cls"] == "" or _DB_[pname.."cls"] == "UNKNOWN" then 
	 		_DB_[pname.."cls"] = pclass;
	 	end

	 	local options_checked = 0;
	 	for idx, item in ipairs(option_choices) do
	 		if _OPTIONS_[option_choices[idx]] then 
	 			options_checked = options_checked + 1;
	 		end
	 	end

	 	local tracked_chars = 0;
		for idx, item in ipairs(_NAMES_) do
			if _TRACKED_CHARS_[item] ~= nil and _TRACKED_CHARS_[item] == true then
				tracked_chars = tracked_chars + 1;
			end
		end
	 	cm_frame:SetSize(300, (tracked_chars *  (150 * (options_checked * table.getn(_NAMES_) / table.getn(option_choices)) / table.getn(_NAMES_)) + 135));
		cm_frame:SetPoint("CENTER", UIParent, "CENTER");
		cm_frame:EnableMouse(true);
		cm_frame:SetMovable(true);
		cm_frame:RegisterForDrag("LeftButton");
		cm_frame:SetScript("OnDragStart", cm_frame.StartMoving);
		cm_frame:SetScript("OnDragStop", cm_frame.StopMovingOrSizing);

		cm_frame.title = cm_frame:CreateFontString();
		cm_frame.title:SetFontObject("GameFontHighlight");
		cm_frame.title:SetPoint("LEFT", cm_frame.TitleBg, "LEFT", 5, 0);
		cm_frame.title:SetText("Eoh's CharacterManager - v"..version);

		cm_frame.options_button = CreateFrame("Button", "options_button", cm_frame, "GameMenuButtonTemplate");
		cm_frame.options_button:SetPoint("BOTTOMLEFT", cm_frame, "BOTTOMLEFT", 10, 10);
		cm_frame.options_button:SetSize(70, 25);
		cm_frame.options_button:SetText("config");
		cm_frame.options_button:SetNormalFontObject("GameFontNormalLarge");
		cm_frame.options_button:SetHighlightFontObject("GameFontHighlightLarge");
		cm_frame.options_button:Hide();
		cm_frame.options_button:SetScript("OnClick", toggle_options_window);

		cm_frame.reload_button = CreateFrame("Button", "reload_button", cm_frame, "GameMenuButtonTemplate");
		cm_frame.reload_button:SetPoint("BOTTOMRIGHT", cm_frame, "BOTTOMRIGHT", -10, 10);
		cm_frame.reload_button:SetSize(70, 25);
		cm_frame.reload_button:SetText("/reload");
		cm_frame.reload_button:SetNormalFontObject("GameFontNormalLarge");
		cm_frame.reload_button:SetHighlightFontObject("GameFontHighlightLarge");
		cm_frame.reload_button:Hide();
		cm_frame.reload_button:SetScript("OnClick", ReloadUI);

		cm_frame.content = cm_frame:CreateFontString("CM_CONTENT");
		cm_frame.content:SetPoint("CENTER");
		cm_frame.content:SetFontObject("GameFontHighlight");

		cm_frame:SetScript("OnEvent", function(self)
	    	self.content:SetText(build_content())
		end)

		cm_frame:Hide();
	 	
	 	init();
	 	updates();
	else 
	 	updates();
	end
end


function toggle_options_window()
	if options_shown == false then
		show_options();
	else
		hide_options();
	end
end


function show_options()
	if not cm_frame.options_frame then
		init_options_window();
	end
	options_shown = true;
	cm_frame.options_frame:Show();
	cm_frame.options_frame.weekly_button:Show();
	cm_frame.options_frame.reset_button:Show();
end


function hide_options()
	if not cm_frame.options_frame then
		init_options_window();
	end
	options_shown = false;
	cm_frame.options_frame:Hide();
	cm_frame.options_frame.weekly_button:Hide();
	cm_frame.options_frame.reset_button:Hide();
end


function init_options_window()
	local tracked_chars = 0;
	for idx, item in ipairs(_NAMES_) do
		if _TRACKED_CHARS_[item] ~= nil and _TRACKED_CHARS_[item] == true then
			tracked_chars = tracked_chars + 1;
		end
	end

	cm_frame.options_frame = CreateFrame("FRAME", "CharacterManagerOptions", cm_frame, "BasicFrameTemplateWithInset");
 	cm_frame.options_frame:SetSize(250, (45 * table.getn(option_choices) + 50 + 45 * tracked_chars));
	cm_frame.options_frame:SetPoint("TOPLEFT", cm_frame, "TOPRIGHT");
	cm_frame.options_frame:SetScript("OnHide", hide_options);

	local retarded_space_solutions_ltd = "                                    ";

	cm_frame.options_frame.button1 = CreateFrame("CheckButton", option_choices[1], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button1:SetPoint("CENTER", cm_frame.options_frame, "TOP", -55, -65);
	cm_frame.options_frame.button1:SetText(retarded_space_solutions_ltd .. option_choices[1]);
	cm_frame.options_frame.button1:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[1]] then
		cm_frame.options_frame.button1:Click();
	end
	cm_frame.options_frame.button1:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)



	cm_frame.options_frame.button2 = CreateFrame("CheckButton", option_choices[2], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button2:SetPoint("TOP", cm_frame.options_frame.button1, "BOTTOM");
	cm_frame.options_frame.button2:SetText(retarded_space_solutions_ltd .. option_choices[2]);
	cm_frame.options_frame.button2:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[2]] then
		cm_frame.options_frame.button2:Click();
	end
	cm_frame.options_frame.button2:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)	


	cm_frame.options_frame.button3 = CreateFrame("CheckButton", option_choices[3], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button3:SetPoint("TOP", cm_frame.options_frame.button2, "BOTTOM");
	cm_frame.options_frame.button3:SetText(retarded_space_solutions_ltd .. option_choices[3]);
	cm_frame.options_frame.button3:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[3]] then
		cm_frame.options_frame.button3:Click();
	end
	cm_frame.options_frame.button3:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)
	
	cm_frame.options_frame.button4 = CreateFrame("CheckButton", option_choices[4], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button4:SetPoint("TOP", cm_frame.options_frame.button3, "BOTTOM");
	cm_frame.options_frame.button4:SetText(retarded_space_solutions_ltd .. option_choices[4]);
	cm_frame.options_frame.button4:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[4]] then
		cm_frame.options_frame.button4:Click();
	end
	cm_frame.options_frame.button4:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)
	
	cm_frame.options_frame.button5 = CreateFrame("CheckButton", option_choices[5], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button5:SetPoint("TOP", cm_frame.options_frame.button4, "BOTTOM");
	cm_frame.options_frame.button5:SetText(retarded_space_solutions_ltd .. option_choices[5]);
	cm_frame.options_frame.button5:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[5]] then
		cm_frame.options_frame.button5:Click();
	end
	cm_frame.options_frame.button5:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)
	
	cm_frame.options_frame.button6 = CreateFrame("CheckButton", option_choices[6], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button6:SetPoint("TOP", cm_frame.options_frame.button5, "BOTTOM");
	cm_frame.options_frame.button6:SetText(retarded_space_solutions_ltd .. option_choices[6]);
	cm_frame.options_frame.button6:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[6]] then
		cm_frame.options_frame.button6:Click();
	end
	cm_frame.options_frame.button6:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)
	
	cm_frame.options_frame.button7 = CreateFrame("CheckButton", option_choices[7], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button7:SetPoint("TOP", cm_frame.options_frame.button6, "BOTTOM");
	cm_frame.options_frame.button7:SetText(retarded_space_solutions_ltd .. option_choices[7]);
	cm_frame.options_frame.button7:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[7]] then
		cm_frame.options_frame.button7:Click();
	end
	cm_frame.options_frame.button7:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)
	
	cm_frame.options_frame.button8 = CreateFrame("CheckButton", option_choices[8], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button8:SetPoint("TOP", cm_frame.options_frame.button7, "BOTTOM");
	cm_frame.options_frame.button8:SetText(retarded_space_solutions_ltd .. option_choices[8]);
	cm_frame.options_frame.button8:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[8]] then
		cm_frame.options_frame.button8:Click();
	end
	cm_frame.options_frame.button8:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)

	cm_frame.options_frame.button9 = CreateFrame("CheckButton", option_choices[9], cm_frame.options_frame, "UICheckButtonTemplate")
	cm_frame.options_frame.button9:SetPoint("TOP", cm_frame.options_frame.button8, "BOTTOM");
	cm_frame.options_frame.button9:SetText(retarded_space_solutions_ltd .. option_choices[9]);
	cm_frame.options_frame.button9:SetNormalFontObject("GameFontNormalLarge");
	if _OPTIONS_[option_choices[9]] then
		cm_frame.options_frame.button9:Click();
	end
	cm_frame.options_frame.button9:SetScript("OnClick", function(self)
		_OPTIONS_[self:GetName()] = self:GetChecked();
	end)


	local last_button = cm_frame.options_frame.button9;
	for idx, item in ipairs(_NAMES_) do

		if _TRACKED_CHARS_[item] ~= nil then
			cm_frame.options_frame.track_button = CreateFrame("CheckButton", item, cm_frame.options_frame, "UICheckButtonTemplate")
			
			if idx == 1 then
				cm_frame.options_frame.track_button:SetPoint("TOP", last_button, "BOTTOM", 0, -35);
			else
				cm_frame.options_frame.track_button:SetPoint("TOP", last_button, "BOTTOM");
			end
			last_button = cm_frame.options_frame.track_button;

			cm_frame.options_frame.track_button:SetText(retarded_space_solutions_ltd .. item);
			cm_frame.options_frame.track_button:SetNormalFontObject("GameFontNormalLarge");
			if _TRACKED_CHARS_[item] then
				cm_frame.options_frame.track_button:Click();
			end

			cm_frame.options_frame.track_button:SetScript("OnClick", function(self)
				_TRACKED_CHARS_[self:GetName()] = self:GetChecked();

			end)
		end
	end


	cm_frame.options_frame.weekly_button = CreateFrame("Button", "weekly_button", cm_frame.options_frame, "GameMenuButtonTemplate");
	cm_frame.options_frame.weekly_button:SetPoint("BOTTOMLEFT", cm_frame.options_frame, "BOTTOMLEFT", 10, 10);
	cm_frame.options_frame.weekly_button:SetSize(70, 25);
	cm_frame.options_frame.weekly_button:SetText("/weekly");
	cm_frame.options_frame.weekly_button:SetNormalFontObject("GameFontNormalLarge");
	cm_frame.options_frame.weekly_button:SetHighlightFontObject("GameFontHighlightLarge")
	cm_frame.options_frame.weekly_button:SetScript("OnClick", weekly);
	cm_frame.options_frame.weekly_button:Hide();

	cm_frame.options_frame.reset_button = CreateFrame("Button", "reset_button", cm_frame.options_frame, "GameMenuButtonTemplate");
	cm_frame.options_frame.reset_button:SetPoint("BOTTOMRIGHT", cm_frame.options_frame, "BOTTOMRIGHT", -10, 10);
	cm_frame.options_frame.reset_button:SetSize(70, 25);
	cm_frame.options_frame.reset_button:SetText("/reset");
	cm_frame.options_frame.reset_button:SetNormalFontObject("GameFontNormalLarge");
	cm_frame.options_frame.reset_button:SetHighlightFontObject("GameFontHighlightLarge");
	cm_frame.options_frame.reset_button:SetScript("OnClick", complete_reset);
	cm_frame.options_frame.reset_button:Hide();

end


cm_frame:SetScript("OnEvent", cm_frame.OnEvent);
SLASH_CM1 = "/eoscm";
function SlashCmdList.CM(msg)
	if msg == "reset" then
		complete_reset();

	elseif string.match(msg, "rm") then 
		remove_character(msg);
		ReloadUI();

	elseif msg == "weekly" then 
		weekly_reset(msg);
		ReloadUI();

	elseif msg == "debug" then
		debug();

	else
		show_window();
	end
end


function toogle_window()
	if window_shown == false then
		window_shown = true;
		init();
		updates();
		cm_frame:Show();
		cm_frame.options_button:Show();
		cm_frame.reload_button:Show();
	else
		window_shown = false;
		cm_frame:Hide();
		cm_frame.options_button:Hide();
		cm_frame.reload_button:Hide();
	end
end


function show_window()
	window_shown = true;
	init();
	updates();
	cm_frame:Show();
	cm_frame.options_button:Show();
	cm_frame.reload_button:Show();
end


function build_content()
	updates();

	local s = "";
	for i=0, table.getn(_NAMES_) do 
		local n = _NAMES_[i];

		if n and _TRACKED_CHARS_[n] then 
			s = s .. colors[_DB_[n.."cls"]] .. n .. "|r" .. "\n";

			if _OPTIONS_[option_choices[1]] then
				s = s .. "M+ done: " .. _DB_[n.."hkey"] .. " (Bag " .. _DB_[n.."bagkey"] .. ")\n";
			end

			if _OPTIONS_[option_choices[2]] then
				s = s .. "Artifact lvl: " .. _DB_[n.."artifactlevel"] .. " (AK: " .. _DB_[n.."level"] .. ")" .. "\n";
			end
			
			if _OPTIONS_[option_choices[3]] then
				s = s .. "Next AK: " .. target_date_to_time(n) .. "\n";
			end

			if _OPTIONS_[option_choices[4]] then
				s = s .. "Seals: " .. _DB_[n.."seals"] .. "/6" .. "\n";
			end

			if _OPTIONS_[option_choices[5]] then
				if _DB_[n.."sealsobt"] == 0 then 
					s = s .. "Seals obtained: " .. colors["RED"] .. _DB_[n.."sealsobt"].. "|r" .. "/3" .. "\n";	
				else
					s = s .. "Seals obtained: " .. _DB_[n.."sealsobt"] .. "/3" .. "\n";	
				end
			end

			if _OPTIONS_[option_choices[6]] then
				s = s .. "Itemlevel: " .. _DB_[n.."itemlevel"] .. "/" .. _DB_[n.."itemlevelbag"] .. "\n";
			end

			if _OPTIONS_[option_choices[7]] then
				s = s .. "OResources: " .. _DB_[n.."orderres"] .. "\n";
			end

			if _OPTIONS_[option_choices[8]] then
				if _DB_[n.."nhraidid"] ~= "-" then
					s = s .. "Nighthold: " .. _DB_[n.."nhraidid"] .. "\n";
				end
			end

			if _OPTIONS_[option_choices[9]] then
				if _DB_[n.."wqoneshot"] ~= -1 then
					if GetTime() > _DB_[n.."wqoneshot"] then
						s = s .. "WQ 1shot: " .. colors["GREEN"] .. "UP" .. "|r" .. "\n";
					else
						
						s = s .. "WQ 1shot in: " .. wq_oneshot_remaining(n) .. "\n";
					end
				end
			end			

			if table.getn(_NAMES_) > 1 and i ~= table.getn(_NAMES_) then 
				s = s .. "\n";
			end
		end
	end
	s = s .. "\n\n\n" .. colors["RED"] .. "Open your artifact weapon to force a data refresh." .. "|r" .. "\n" 
	s = s .. colors["RED"] .. "The window only resizes after reloads." .. "|r" .. "\n" 
	return s
end


function init()
	-- init name
	if not contains(_NAMES_, pname)  then 
		table.insert(_NAMES_, pname);
	end

	if _NAMES_ == nil then
		_NAMES_ = {};
	end

	for _, char_name in ipairs(_NAMES_) do 
		-- init vars
	 	if not _DB_[char_name .. "cls"] then
	 		_DB_[char_name .. "cls"] = "UNKNOWN";
	 	end

	 	if not _DB_[char_name .. "level"] then
	 		_DB_[char_name .. "level"] = 0;
	 	end

	 	if not _DB_[char_name .. "artifactlevel"] then
	 		_DB_[char_name .. "artifactlevel"] = 0;
	 	end

	 	if not _DB_[char_name .. "hkey"] then
	 		_DB_[char_name .. "hkey"] = 0;
	 	end

	 	if not _DB_[char_name .. "bagkey"] then
	 		_DB_[char_name .. "bagkey"] = "no key";
	 	end     

	 	if not _DB_[char_name .. "seals"] then
	 		_DB_[char_name .. "seals"] = 0;
	 	end

	 	if not _DB_[char_name .. "itemlevel"] then
	 		_DB_[char_name .. "itemlevel"] = 0;
	 	end

	 	if not _DB_[char_name .. "itemlevelbag"] then
	 		_DB_[char_name .. "itemlevelbag"] = 0;
	 	end

	 	if not _DB_[char_name .. "orderres"] then
	 		_DB_[char_name .. "orderres"] = 0;
	 	end

	 	if not _DB_[char_name .. "akremain"] then
	 		_DB_[char_name .. "akremain"] = "0 0 0 0";
	 	end

	 	if not _DB_[char_name .. "nhraidid"] then
	 		_DB_[char_name .. "nhraidid"] = "?";
	 	end

	 	if not _DB_[char_name .. "wqoneshot"] then
	 		_DB_[char_name .. "wqoneshot"] = -1;
	 	end
	 end
end


function updates()
	check_for_id_reset();

	seals_update();
	seals_obtained_update();
	level_update();
	orderres_update();
	itemlevel_update();
	artifactlevel_update();
	bagkey_update();
	hkey_update();
	akremain_update();
	update_raidid();
	update_wqoneshot();

	new_shit();
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


function target_date_to_time(n)
	-- check if u can pick up akr on current char
	local t = C_Garrison.GetLooseShipments(3);
    local i = 1;
    for l = i,#t do 
        local c = C_Garrison.GetLandingPageShipmentInfoByContainerID(C_Garrison.GetLooseShipments(3)[l]);
        if c=="Artifact Research Notes" then 
            i=l;
            break
        end
    end

    if C_Garrison.GetLooseShipments(3)[i] then
	    local _, _, _, shipmentsReady, _, _, _, _ = C_Garrison.GetLandingPageShipmentInfoByContainerID(C_Garrison.GetLooseShipments(3)[i]);

	    if shipmentsReady and shipmentsReady == 1 and n == pname then
	    	return colors["GOLD"] .. "PICK IT UP!" .. "|r";
	    end
	end

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

		--print("target date: " .. target_day .. "." .. target_month .. "  " .. target_hour .. ":" .. target_min);

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

		--print("current date: " .. current_day .. "." .. current_month .. "  " .. current_hour .. ":" .. current_minute);

		-- in the past
		-- today
		if tonumber(current_day) == tonumber(target_day) and tonumber(current_hour) > tonumber(target_hour) then
			return colors["GOLD"] .. "PICK IT UP!" .. "|r";

		-- today last update less than 60 mins before
		elseif target_min ~= "??" and tonumber(current_day) == tonumber(target_day) and tonumber(current_hour) == tonumber(target_hour) and tonumber(current_minute) > tonumber(target_min) then
			return colors["GOLD"] .. "PICK IT UP!" .. "|r";

		-- last month
		elseif tonumber(current_month) > tonumber(target_month) then
			return colors["GOLD"] .. "PICK IT UP!" .. "|r";

		-- not today, this month but in the past
		elseif tonumber(current_day) > tonumber(target_day) and tonumber(current_month) == tonumber(target_month) then
			return colors["GOLD"] .. "PICK IT UP!" .. "|r";

		-- not today, but in the future	
		elseif tonumber(current_day) ~= tonumber(target_day) then
			if tostring(target_min) ~= "??" and tonumber(target_min) < 10 then
				target_min = "0" .. target_min;
			end

			if tonumber(current_minute) < 10 then
				current_minute = "0" .. current_minute;
			end

			if tostring(target_min) == "??" then
				return time_diff(current_month, current_day, current_hour, current_minute, target_month, target_day, target_hour, target_min) .. 
				" (" .. target_day .. "." .. target_month .. " around " .. target_hour .. " h)";
			else
				return time_diff(current_month, current_day, current_hour, current_minute, target_month, target_day, target_hour, target_min) .. 
				" (" .. target_day .. "." .. target_month .. " " .. target_hour .. ":" .. target_min .. ")";
			end

		else
			-- same day
			local h = tonumber(target_hour) - tonumber(current_hour); -- works cus same day
			local m = tonumber(target_min) - tonumber(current_minute); --  may be negative

			if m < 0 then
				h = h - 1;
				m = m + 60;
			end

			if tonumber(h) > 0 then
				return colors["GOLD"] .. "Today" .. "|r" .. " in " .. h .. " h and " .. m .. " min";
			else
				return colors["GOLD"] .. "Today" .. "|r" .. " in " .. m .. " min";
			end
		end
	else
		return "unknown";
	end
end


function wq_oneshot_remaining(char_name)
	local oneshot_time = _DB_[char_name.."wqoneshot"] - GetTime();
	local oneshot_hour = math.floor(oneshot_time / 3600);
	local oneshot_minute = math.floor(math.floor(oneshot_time % 3600) / 60) ;

	return oneshot_hour .. " h and " .. oneshot_minute .. " min"

end


-- 2 is later than 1
function time_diff(m1, d1, h1, min1, m2, d2, h2, min2)
	local s = "";

	-- case min2 contains "??"
	-- just days and hr
	if tostring(min2) == "??" then
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
		local h = tonumber(h2) - tonumber(h1);
		local min = 60 - tonumber(min1) + tonumber(min2);

		if min >= 60 then
			h = h + 1;
			min = min - 60;
		end
		s = s .. tostring(h) .. " h";
		s = s .. tostring(min) .. min;


	else 
		-- different days -- next day i guess
		--print(h1 .. " " .. min1);
		--print(h2 .. " " .. min2);
		local h = 24 - tonumber(h1) + tonumber(h2);

		local min = -1;

		if tonumber(min1) > tonumber(min2) then
			min = 60 - tonumber(min1) + tonumber(min2);
			h = h - 1;

		else
			min = min2 - min1;
		end

		s = s .. tostring(h) .. " h ";
		s = s .. tostring(min) .. " min";  
	end
	
	return s
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
	local current_minute = 0;

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

    local _, _, _, shipmentsReady, _, _, _, tlStr = C_Garrison.GetLandingPageShipmentInfoByContainerID(C_Garrison.GetLooseShipments(3)[i]);

    if tlStr then
		local lst = tolist(string.gmatch(tlStr, "%S+"));
		 -- days and hr
		if lst[4] and lst[2] and string.match(lst[2], "days") and string.match(lst[4], "hr") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_days = item;
		    	elseif idx == 3 then
		    		remaining_hours = item;
		    	end
		    end
		    remaining_minutes = "??";

		-- days only because hours == 0
		elseif lst[2] and string.match(lst[2], "days") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_days = item;
		    	end
		    end
		    remaining_hours = 0;
		    remaining_minutes = "??";

		-- hr and mins
		elseif lst[2] and lst[4] and string.match(lst[2], "hr") and string.match(lst[4], "min") then
		    for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_hours = item;
		    	elseif idx == 3 then
		    		remaining_minutes = item;
		    	end
		    end

		-- mins only because hrs == 0
		elseif lst[2] and string.match(lst[2], "min") then 
			for idx, item in ipairs(lst) do
		    	if idx == 1 then
		    		remaining_minutes = item;
		    	end
		    end

		else
			--print("No matching time found, AK research may be wrong for this Char");
			--print("DEBUGINFO: >" .. tostring(lst[2]) .. "<" .. " and " .. ">" .. tostring(lst[4]) .. "<");
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
		    		current_minute = tonumber(item);
		    	end
		    end
		end

		local target_day = current_day + remaining_days;
		local target_month = current_month;
		local target_hour = current_hour + tonumber(remaining_hours);

		if tostring(remaining_minutes) ~= "??" then
			target_min = current_minute + remaining_minutes;
		else 
			target_min = remaining_minutes;
		end
		
		if tostring(target_min) ~= "??" and target_min > 60 then
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
			--print("updating timestring: " .. time_string);
			_DB_[pname .. "akremain"] = time_string; 
		end
	 	
	end
end


function update_raidid()
	instances = GetNumSavedInstances();
	local s = "";

	for i=1, instances do
		name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i);

		if name == "The Nighthold" and difficultyName == "Mythic" and locked then
			if encounterProgress < numEncounters then
			 	s = s .. colors["RED"] .. tostring(encounterProgress) .. "|r" .. "/" .. tostring(numEncounters) .. "M ";
			else
				s = s .. tostring(encounterProgress) .. "/" .. tostring(numEncounters) .. "M ";
			end

		elseif name == "The Nighthold" and difficultyName == "Heroic" and locked then
			if encounterProgress < numEncounters then
				s = s .. colors["RED"] .. tostring(encounterProgress) .. "|r" .. "/" .. tostring(numEncounters) .. "H ";
			else
				s = s .. tostring(encounterProgress) .. "/" .. tostring(numEncounters) .. "H ";
			end

		elseif name == "The Nighthold" and difficultyName == "Normal" and locked then
			if encounterProgress < numEncounters then
				s = s .. colors["RED"] .. tostring(encounterProgress) .. "|r" .. "/" .. tostring(numEncounters) .. "N ";
			else
				s = s .. tostring(encounterProgress) .. "/" .. tostring(numEncounters) .. "N ";
			end

		end
	end
	if s == "" then 
		s = "-";
	end
	_DB_[pname.."nhraidid"] = s;
end


function update_wqoneshot()
	if contains(world_quest_one_shot, pclass) then
		local start, duration, enable = GetSpellCooldown(world_quest_one_shot_ids[pclass]);
		local finish = math.floor(start) + duration
		--print(start .. ".." .. duration.. ".." .. tostring(enable));
		--print(finish);
		_DB_[pname .. "wqoneshot"] = math.floor(finish);
	end
end


-- cmd functions
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


function weekly_reset(msg)
	for idx, item in ipairs(_NAMES_) do
		-- reset finished key
		_DB_[item.."hkey"] = 0;

		-- reset bag key
		_DB_[item.."bagkey"] = "?";

		-- reset seals obtained
		_DB_[item.."sealsobt"] = 0;

		-- reset raid ids
		_DB_[item.."nhraidid"] = "-";
	end
end


function check_for_id_reset()
	-- init needed values
	local reset = 0;
	local region = GetCurrentRegion();

	if region == 1 then 
		reset = na_reset;
	elseif region == 3 then
		reset = eu_reset;
	end

	server_time = GetServerTime();

	-- case _NEXT_RESET_ is not initialized
	if _NEXT_RESET_ == 0 then
		while reset < server_time do 
			reset = reset + week;
		end
		_NEXT_RESET_ = reset;
 	end

 	-- case no reset needed
 	if _NEXT_RESET_ > server_time then 
 		return

 	else 
 		while reset < server_time do 
			reset = reset + week;
		end
		_NEXT_RESET_ = reset;
		weekly_reset();
 	end
end


function weekly()
	weekly_reset("weekly");
	ReloadUI();
end


function complete_reset()
	_NAMES_ = nil;
	_DB_ = nil;
	_NEXT_RESET_ = nil;
	_TRACKED_CHARS_ = nil;
	_OPTIONS_ = nil;
	ReloadUI();
end


function debug()
	--print(colors["RED"] .. "oh oh, you shouldnt do this" .. "|r")

	--_NEXT_RESET_ = _NEXT_RESET_ - 172800;
end


-- function testeing
function new_shit()
	--print("new shit");
	--print("return: " .. time_diff(5, 17, 12, 2, 5, 18, 11, 3));
	--print("return: " .. time_diff(5, 17, 12, 3, 5, 18, 11, 3));
	--print("return: " .. time_diff(5, 17, 12, 3, 5, 18, 11, 2));

	return
end

-- TODO 
-- wq oneshot?
-- auf aktuellem char auslesen, ob AK rdy
-- split files