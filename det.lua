------------------------------------------------------------
-- DET -----------------------------------------------------
-- WRITTEN BY Amurilon -------------------------------------
------------------------------------------------------------
-- RELEASED UNDER CREATIVE COMMONS BY-NC-ND 3.0 ------------
-- http://www.creativecommons.org/licenses/by-nc-nd/3.0/ ---
------------------------------------------------------------


local VERSION = string.match("1.1", "^v?[%d+.]+....$") or DEV_BUILD or "Build: 2017-06-27T20:14:57Z"


local DET = {
	System = {
		Name = "Det",
		Version = VERSION,
		Author = "Amurilon",
		Path = "Interface/Addons/DET",
		Icon = "interface/icons/shop_goods/fe_marryitem_02",
	},
	Tooltip = {}
}

_G["DET"] = DET

------------------------------------------------------------
-- NAMESPACE DEFINITIONS -----------------------------------
------------------------------------------------------------

local ZZLibrary = ZZLibrary
local System = DET.System

local Functions = {}
local Plugin = {}
local EquipmentTooltip = {}
local Locales, GetLocale = ZZLibrary.LoadLocales(System.Path.."/Locales", "BASE")


local UpdateNeeded = {Equipment=true,Buffs=true,Misc=true}

local Values = {
	Talent 					= {Sum = 0,Equipment={Sum=0,},Buffs={Sum=0,},Misc={Sum=0,}},
	Experience 				= {Sum = 0,Equipment={Sum=0,},Buffs={Sum=0,},Misc={Sum=0,}},
	DropRate 				= {Sum = 0,Equipment={Sum=0,},Buffs={Sum=0,},Misc={Sum=0,}},
	QuestTalent 			= {Sum = 0,Equipment={Sum=0,},Buffs={Sum=0,},Misc={Sum=0,}},
	QuestExperienceTalent 	= {Sum = 0,Equipment={Sum=0,},Buffs={Sum=0,},Misc={Sum=0,}},
}

local LookUp = {
	Wings = {
		 [0] = 0,
		 [1] = 1,
		 [2] = 2,
		 [3] = 3,
		 [4] = 4,
		 [5] = 5,
		 [6] = 7,
		 [7] = 9,
		 [8] = 11,
		 [9] = 13,
		[10] = 15,
		[11] = 17,
		[12] = 20,
		[13] = 23,
		[14] = 26,
		[15] = 29,
		[16] = 33,
		[17] = 37,
		[18] = 41,
		[19] = 45,
		[20] = 49,
		[21] = 53,
		[22] = 57,
		[23] = 61,
		[24] = 65,
		[25] = 69,
		[26] = 73,
		[27] = 77,
		[28] = 71,
		[29] = 75,
		[30] = 79,
	},
	DropRunes = {
		[TEXT("Sys520721_name")] = 10,
		[TEXT("Sys520722_name")] = 20,
		[TEXT("Sys520723_name")] = 30,
		[TEXT("Sys520724_name")] = 40,
		[TEXT("Sys520725_name")] = 50,
		[TEXT("Sys520726_name")] = 60,
		[TEXT("Sys520727_name")] = 70,
		[TEXT("Sys520728_name")] = 80,
		[TEXT("Sys520729_name")] = 90,
		[TEXT("Sys520730_name")] = 100,
	},
	ExpRunes = {
		[TEXT("Sys520741_name")] = 10,
		[TEXT("Sys520742_name")] = 20,
		[TEXT("Sys520743_name")] = 30,
		[TEXT("Sys520744_name")] = 40,
		[TEXT("Sys520745_name")] = 50,
		[TEXT("Sys520746_name")] = 60,
		[TEXT("Sys520747_name")] = 70,
		[TEXT("Sys520748_name")] = 80,
		[TEXT("Sys520749_name")] = 90,
		[TEXT("Sys520750_name")] = 100,
	},
	Talent = {},
	Experience = {},
	DropRate = {},
	QuestTalent = {},
	QuestExperienceTalent = {},
	TitleTP = {},
	TitleEP = {},
	TitleDrop = {},
	TitleXTP = {},
	TitleXEP = {},
	TitleXDrop = {},
}

------------------------------------------------------------
--  Tooltip ------------------------------------------------
------------------------------------------------------------

EquipmentTooltip = CreateUIComponent("Tooltip","DET_GameTooltip","UIParent","GameTooltipTemplate")
EquipmentTooltip:Hide()

------------------------------------------------------------
--  Functions ----------------------------------------------
------------------------------------------------------------

function Functions.Init()
	Functions.ReadFiles()

	ZZLibrary.Event.Register("PET_SUMMON_SUCCEED",		function() Functions.TriggerUpdate("Misc") end, "DET_SummonPet")
	ZZLibrary.Event.Register("PET_RETURN_SUCCEED",		function() Functions.TriggerUpdate("Misc") end, "DET_ReturnPet")
	ZZLibrary.Event.Register("ATF_UPDATE", 				function() Functions.TriggerUpdate("Misc") end, "DET_ATF_UPDATE")
	ZZLibrary.Event.Register("PLAYER_TITLE_ID_CHANGED",	function() Functions.TriggerUpdate("Misc") end, "DET_TitleChanged")
	ZZLibrary.Event.Register("PLAYER_EQUIPMENT_UPDATE", function() Functions.TriggerUpdate("Equipment") end, "DET_ChangeEquipment")
	ZZLibrary.Event.Register("UNIT_BUFF_CHANGED",		function(e,a1) if a1 == "player" then Functions.TriggerUpdate("Buffs") end end, "DET_BuffsChanged")
	ZZLibrary.Event.Register("EXCHANGECLASS_SUCCESS", 	function() Functions.TriggerUpdate() end, "DET_CLASS_CHANGE")

	ZZLibrary.Timer.Add(5, Functions.UpdateValues, "DET_Timer_UpdateValues")

	ATF_Open()
end

function Functions.TriggerUpdate(Cat)
	if Cat == nil then
		for k,v in pairs(UpdateNeeded) do
			UpdateNeeded[k] = true
		end
	elseif UpdateNeeded[Cat] ~= nil then
		UpdateNeeded[Cat] = true
	end
end

function Functions.ReadFiles(self)
	local file,load,err

	file = System.Path.."/data/Drop.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.DropRate = load()
	end

	file = System.Path.."/data/TP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.Talent = load()
	end

	file = System.Path.."/data/EP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.Experience = load()
	end

	file = System.Path.."/data/QEPTP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.QuestExperienceTalent = load()
	end

	file = System.Path.."/data/QTP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.QuestTalent = load()
	end

	file = System.Path.."/data/TitleTP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleTP = load()
	end

	file = System.Path.."/data/TitleEP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleEP = load()
	end

	file = System.Path.."/data/TitleDrop.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleDrop = load()
	end

	file = System.Path.."/data/TitleXDrop.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleXDrop = load()
	end

	file = System.Path.."/data/TitleXEP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleXEP = load()
	end

	file = System.Path.."/data/TitleXTP.lua"
	load, err = loadfile (file)
	if not(err) then
		LookUp.TitleXTP = load()
	end

end

function Functions.UpdateValues(self,UpdateForced)
	if LoadingFrame:IsVisible() then return end
	local UpdateForced = UpdateForced or false

	if UpdateNeeded.Equipment or UpdateForced then
		if GetPlayerCombatState() then
			UpdateNeeded.Equipment = false
		else
			Functions.ParseEquipment()
		end
	end

	if UpdateNeeded.Buffs or UpdateForced then
		Functions.ParseBuffs()
	end

	if UpdateNeeded.Misc or UpdateForced then
		Functions.ParseMisc()
	end

	if UpdateNeeded.Equipment or UpdateNeeded.Buffs or UpdateNeeded.Misc or UpdateForced then
		ZZLibrary.Event.Trigger("DET_VALUES_CHANGED")
		UpdateNeeded.Buffs = false
		UpdateNeeded.Equipment = false
		UpdateNeeded.Misc = false
	end
end

function Functions.ParseEquipment(self)

	--clear-up old values
	for k,v in pairs(Values) do
		v.Sum = v.Sum - v.Equipment.Sum
		v.Equipment.Sum = 0
		for l,w in ipairs(v.Equipment) do
			v.Equipment[l] = nil
		end
	end

	-- Wings

	if (GetInventoryItemType("player", 21) >= 0) and not(GetInventoryItemInvalid("player", 21)) then
		local WingText = ""
		local WingPlus = 0
		EquipmentTooltip:SetOwner("UIParent", "ANCHOR_TOPRIGHT", -10, 0)
		EquipmentTooltip:SetInventoryItem("player", 21)
		WingText = DET_GameTooltipTextLeft1:GetText()
		WingText = string.sub(WingText,#WingText-3,#WingText)
		if (string.sub(WingText,1,1) == "+") then
			WingPlus = tonumber(string.sub(WingText,3,4))
		elseif (string.sub(WingText,2,2) == "+") then
			WingPlus = tonumber(string.sub(WingText,4,4))
		end
		local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 21)

		if WingPlus > 0 then
			WingPlus = LookUp.Wings[WingPlus]
			if ((durableValue > durableMax) or durableValue > 100) then
				WingPlus = WingPlus * 1.2
			end
			table.insert(Values.Talent.Equipment,		{itemName,WingPlus})
			table.insert(Values.Experience.Equipment,	{itemName,WingPlus})
			table.insert(Values.DropRate.Equipment,		{itemName,WingPlus})

			Values.Talent.Equipment.Sum 		= Values.Talent.Equipment.Sum + WingPlus
			Values.Experience.Equipment.Sum 	= Values.Experience.Equipment.Sum + WingPlus
			Values.DropRate.Equipment.Sum 		= Values.DropRate.Equipment.Sum + WingPlus
		end

	end

	-- Weapon 1

	if (GetInventoryItemType("player", 15) >= 0) and not(GetInventoryItemInvalid("player", 15)) then
		EquipmentTooltip:SetOwner("UIParent", "ANCHOR_TOPRIGHT", -10, 0)
		EquipmentTooltip:SetInventoryItem("player", 15)
		for k=60,1,-1 do
			if _G["DET_GameTooltipTextRight"..k]:IsVisible() then
				local Text = _G["DET_GameTooltipTextRight"..k]:GetText()

				if (LookUp.DropRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 15)
					local Value = LookUp.DropRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.DropRate.Equipment,	{Text,Value})
					Values.DropRate.Equipment.Sum 		= Values.DropRate.Equipment.Sum + Value
				end

				if (LookUp.ExpRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 15)
					local Value = LookUp.ExpRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.Experience.Equipment,	{Text,Value})
					Values.Experience.Equipment.Sum 		= Values.Experience.Equipment.Sum + Value
				end

			end
		end
	end

	-- Weapon 2

	if (GetInventoryItemType("player", 16) >= 0) and not(GetInventoryItemInvalid("player", 16)) then
		EquipmentTooltip:SetOwner("UIParent", "ANCHOR_TOPRIGHT", -10, 0)
		EquipmentTooltip:SetInventoryItem("player", 16)
		for k=60,1,-1 do
			if _G["DET_GameTooltipTextRight"..k]:IsVisible() then
				local Text = _G["DET_GameTooltipTextRight"..k]:GetText()

				if (LookUp.DropRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 16)
					local Value = LookUp.DropRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.DropRate.Equipment,	{Text,Value})
					Values.DropRate.Equipment.Sum 		= Values.DropRate.Equipment.Sum + Value
				end

				if (LookUp.ExpRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 15)
					local Value = LookUp.ExpRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.Experience.Equipment,	{Text,Value})
					Values.Experience.Equipment.Sum 		= Values.Experience.Equipment.Sum + Value
				end

			end
		end
	end

	-- Ranged Weapon

	if (GetInventoryItemType("player", 10) >= 0) and not(GetInventoryItemInvalid("player", 10)) then
		EquipmentTooltip:SetOwner("UIParent", "ANCHOR_TOPRIGHT", -10, 0)
		EquipmentTooltip:SetInventoryItem("player", 10)
		for k=60,1,-1 do
			if _G["DET_GameTooltipTextRight"..k]:IsVisible() then
				local Text = _G["DET_GameTooltipTextRight"..k]:GetText()

				if (LookUp.DropRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 10)
					local Value = LookUp.DropRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.DropRate.Equipment,	{Text,Value})
					Values.DropRate.Equipment.Sum 		= Values.DropRate.Equipment.Sum + Value
				end

				if (LookUp.ExpRunes[Text] ~= nil) then
					local durableValue, durableMax, itemName = GetInventoryItemDurable("player", 15)
					local Value = LookUp.ExpRunes[Text]
					if ((durableValue > durableMax) or durableValue > 100) then
						Value = Value * 1.2
					end
					table.insert(Values.Experience.Equipment,	{Text,Value})
					Values.Experience.Equipment.Sum 		= Values.Experience.Equipment.Sum + Value
				end

			end
		end
	end

	-- sum-up new values and hide tooltip

	for k,v in pairs(Values) do
		v.Sum = v.Sum + v.Equipment.Sum
	end

	EquipmentTooltip:Hide()
end

function Functions.ParseBuffs(self)

	-- clear-up old values

	for k,v in pairs(Values) do
		v.Sum = v.Sum - v.Buffs.Sum
		v.Buffs.Sum = 0
		for l,w in ipairs(v.Buffs) do
			v.Buffs[l] = nil
		end
	end

	-- read current buffs

	local k = 1
	while(UnitBuffInfo("player" , k ) ~=nil) do
		local Buffname, Bufficon, Buffcount, BuffID = UnitBuffInfo( "player", k )

		for l,_ in pairs(Values) do
			if LookUp[l][BuffID] ~= nil then
				table.insert(Values[l].Buffs,{Buffname,LookUp[l][BuffID]})
				Values[l].Buffs.Sum = Values[l].Buffs.Sum + LookUp[l][BuffID]
			end
		end

		k = k + 1
	end

	-- sum-up new values

	for k,v in pairs(Values) do
		v.Sum = v.Sum + v.Buffs.Sum
	end
end

function Functions.ParseMisc(self)
	local PetID = 0
	-- clear-up old values

	for k,v in pairs(Values) do
		v.Sum = v.Sum - v.Misc.Sum
		v.Misc.Sum = 0
		for l,w in ipairs(v.Misc) do
			v.Misc[l] = nil
		end
	end

	-- check pet

	for PetID = 1, PET_FRAME_NUM_ITEMS do
		if IsPetSummoned(PetID) then
			local PetSkillName, PetSkillIcon, PetSkillLearned, _, PetSkillLevel   = GetPetItemSkillInfo( PetID, 7 )
			if PetSkillLearned then
				table.insert(Values.DropRate.Misc,{PetSkillName,PetSkillLevel})
				Values.DropRate.Misc.Sum = Values.DropRate.Misc.Sum + PetSkillLevel
			end
		end
	end

	-- check title

	local TitleID,TitleName = GetCurrentTitle()

	if LookUp.TitleTP[TitleID] ~= nil then
		table.insert(Values.Talent.Misc,{TitleName,LookUp.TitleTP[TitleID]})
		Values.Talent.Misc.Sum 		= Values.Talent.Misc.Sum + LookUp.TitleTP[TitleID]
	end

	if LookUp.TitleEP[TitleID] ~= nil then
		table.insert(Values.Experience.Misc,{TitleName,LookUp.TitleEP[TitleID]})
		Values.Experience.Misc.Sum 		= Values.Experience.Misc.Sum + LookUp.TitleEP[TitleID]
	end

	if LookUp.TitleDrop[TitleID] ~= nil then
		table.insert(Values.DropRate.Misc,{TitleName,LookUp.TitleDrop[TitleID]})
		Values.DropRate.Misc.Sum 		= Values.DropRate.Misc.Sum + LookUp.TitleDrop[TitleID]
	end

	-- check title system

	local _,_,ATFRep = GetAncillaryTitleInfo()

	if ATFRep > 0 then
		local ATFFactor = Lua_CheckBuff(621080) and 2 or 1
		for k = 1,4 do
			_,ATFName = GetATF_Title(k)
			if ATFName ~= "? ? ?" then
				if LookUp.TitleXTP[ATFName] ~= nil then
					table.insert(Values.Talent.Misc,{ATFName,ATFFactor*LookUp.TitleXTP[ATFName]})
					Values.Talent.Misc.Sum 		= Values.Talent.Misc.Sum + ATFFactor*LookUp.TitleXTP[ATFName]
				end

				if LookUp.TitleXEP[ATFName] ~= nil then
					table.insert(Values.Experience.Misc,{ATFName,ATFFactor*LookUp.TitleXEP[ATFName]})
					Values.Experience.Misc.Sum 		= Values.Experience.Misc.Sum + ATFFactor*LookUp.TitleXEP[ATFName]
				end

				if LookUp.TitleXDrop[ATFName] ~= nil then
					table.insert(Values.DropRate.Misc,{ATFName,ATFFactor*LookUp.TitleXDrop[ATFName]})
					Values.DropRate.Misc.Sum 		= Values.DropRate.Misc.Sum + ATFFactor*LookUp.TitleXDrop[ATFName]
				end
			end
		end
	end

	-- check rouge luck buff
	local RougeLuck = Functions.RougeLuck()
	if RougeLuck >= 0 then
		table.insert(Values.DropRate.Misc,{TEXT("Sys490316_name"),(5+RougeLuck*0.3)})
		Values.DropRate.Misc.Sum 		= Values.DropRate.Misc.Sum + (5+RougeLuck*0.3)
	end

	-- sum-up new values

	for k,v in pairs(Values) do
		v.Sum = v.Sum + v.Misc.Sum
	end

end

function Functions.RougeLuck()
	local Class = UnitClassToken("player")
	if Class == "THIEF" then
		local NumSkill = GetNumSkill(4)
		for i = 1,NumSkill do
			local SkillName, _, _, _, SkillRank, _, _, _, SkillAvailable = GetSkillDetail(4,i)
			if SkillName == TEXT("Sys490316_name") and SkillAvailable then
				return SkillRank
			end
		end
	end
	return -1
end

------------------------------------------------------------
-- Public Functions ----------------------------------------
------------------------------------------------------------

function DET.GetTalent()
	return Values.Talent.Sum
end

function DET.GetTalentEquipment()
	return Values.Talent.Equipment.Sum
end

function DET.GetTalentBuffs()
	return Values.Talent.Buffs.Sum
end

function DET.GetTalentMisc()
	return Values.Talent.Misc.Sum
end

function DET.GetExperience()
	return Values.Experience.Sum
end

function DET.GetExperienceEquipment()
	return Values.Experience.Equipment.Sum
end

function DET.GetExperienceBuffs()
	return Values.Experience.Buffs.Sum
end

function DET.GetExperienceMisc()
	return Values.Experience.Misc.Sum
end

function DET.GetDropRate()
	return Values.DropRate.Sum
end

function DET.GetDropRateEquipment()
	return Values.DropRate.Equipment.Sum
end

function DET.GetDropRateBuffs()
	return Values.DropRate.Buffs.Sum
end

function DET.GetDropRateMisc()
	return Values.DropRate.Misc.Sum
end

function DET.GetQuestTalent()
	return Values.QuestTalent.Sum
end

function DET.GetQuestTalentEquipment()
	return Values.QuestTalent.Equipment.Sum
end

function DET.GetQuestTalentBuffs()
	return Values.QuestTalent.Buffs.Sum
end

function DET.GetQuestTalentMisc()
	return Values.QuestTalent.Misc.Sum
end

function DET.GetQuestExperienceTalent()
	return Values.QuestExperienceTalent.Sum
end

function DET.GetQuestExperienceTalentEquipment()
	return Values.QuestExperienceTalent.Equipment.Sum
end

function DET.GetQuestExperienceTalentBuffs()
	return Values.QuestExperienceTalent.Buffs.Sum
end

function DET.GetQuestExperienceTalentMisc()
	return Values.QuestExperienceTalent.Misc.Sum
end

------------------------------------------------------------
-- ZZInfoBar Plugin ----------------------------------------
------------------------------------------------------------

Plugin.Settings = {
		{
			Name = "DropRate",
			Default = false,
			Type = "CheckButton",
		},
		{
			Name = "Experience",
			Default = false,
			Type = "CheckButton",
		},
		{
			Name = "Talent",
			Default = false,
			Type = "CheckButton",
		},
		{
			Name = "QuestExperienceTalent",
			Default = false,
			Type = "CheckButton",
		},
		{
			Name = "QuestTalent",
			Default = false,
			Type = "CheckButton",
		},
}

Plugin.Apply = {}

Plugin.Buttons = {}

function Plugin.Init()
	ZZIB.Tools.Config.Check("DET_ZZIB_SAVE", Plugin.Settings)

	Plugin.InitButtons()
	Plugin.ApplyAll()

	ZZIB.Plugins.Add({
		Name = System.Name,
		Icon = System.Icon,
		Version = System.Version,
		Click = function() awsmDropdown.BuildConfig(Plugin.Settings, Locales, DET_ZZIB_SAVE, Plugin.Apply, true) end,
		Tooltip = {
			GetLocale("PLUGIN_DESC"),
			"|cffaaaaaa"..GetLocale("VERSION").." "..System.Version.."|r",
			"|cffaaaaaa"..GetLocale("WRITTEN_BY").." "..System.Author.."|r",
			"|cffaaaaaa"..GetLocale("TRANSLATED_BY").." "..GetLocale("TRANSLATOR").."|r",
		}
	})

end

function Plugin.InitButtons()
	Plugin.Buttons = {
		DropRate = {
			Name = "DETZZIBDropRate",
			Icon = "interface/icons/item_potion_040_004",
			Click = {},
			Events = {["DET_VALUES_CHANGED"] = function() Plugin.UpdateLabel("DropRate") end,},
			ActivateCall = function() Plugin.UpdateLabel("DropRate",true) end,
			ScriptEnter = function() Plugin.UpdateTooltip("DropRate",35) end,
		},
		Experience = {
			Name = "DETZZIBExperience",
			Icon = "interface/icons/item_potion_030_006",
			Click = {},
			Events = {["DET_VALUES_CHANGED"] = function() Plugin.UpdateLabel("Experience") end,},
			ActivateCall = function() Plugin.UpdateLabel("Experience",true) end,
			ScriptEnter = function() Plugin.UpdateTooltip("Experience",34) end,
		},
		Talent = {
			Name = "DETZZIBTalent",
			Icon = "interface/icons/item_potion_030_004",
			Click = {},
			Events = {["DET_VALUES_CHANGED"] = function() Plugin.UpdateLabel("Talent") end,},
			ActivateCall = function() Plugin.UpdateLabel("Talent",true) end,
			ScriptEnter = function() Plugin.UpdateTooltip("Talent",175) end,
		},
		QuestExperienceTalent = {
			Name = "DETZZIBQuestExperienceTalent",
			Icon = "interface/icons/shop_goods/drug_002_01",
			Click = {},
			Events = {["DET_VALUES_CHANGED"] = function() Plugin.UpdateLabel("QuestExperienceTalent") end,},
			ActivateCall = function() Plugin.UpdateLabel("QuestExperienceTalent",true) end,
			ScriptEnter = function() Plugin.UpdateTooltip("QuestExperienceTalent",212) end,
		},
		QuestTalent = {
			Name = "DETZZIBQuestTalent",
			Icon = "interface/icons/shop_goods/drug_002_02",
			Click = {},
			Events = {["DET_VALUES_CHANGED"] = function() Plugin.UpdateLabel("QuestTalent") end,},
			ActivateCall = function() Plugin.UpdateLabel("QuestTalent",true) end,
			ScriptEnter = function() Plugin.UpdateTooltip("QuestTalent",213) end,
		},
	}

	for name, template in pairs(Plugin.Buttons) do
		Plugin.Apply[name] = function()
			ZZIB.Tools.ApplyButtonActive(name, template, DET_ZZIB_SAVE, GetLocale)
		end
	end
end

function Plugin.UpdateLabel(ButtonName,forceUpdate)
	if ButtonName == nil then return end

	local Button = ZZIB.Buttons.List["DETZZIB"..ButtonName]
	if not Button then return end

	local EPBonus, TPBonus = GetPlayerExtraPoint()

	local Bonus = (ButtonName == "Experience" and EPBonus) or (ButtonName == "Talent" and TPBonus) or 0

	if (Button.Value ~= Values[ButtonName].Sum) or (Button.Value2 > 0 and Bonus == 0) or (Button.Value2 == 0 and Bonus > 0) or forceUpdate then
		Button.Value = Values[ButtonName].Sum
		Button.Value2 = Bonus
		ZZIB.Buttons.UpdateText("DETZZIB"..ButtonName, (Bonus > 0 and "|cff00ff00" or "")..Button.Value.."%", true)
	end

end

function Plugin.UpdateAllLabels()
	Plugin.UpdateLabel("DropRate",true)
	Plugin.UpdateLabel("Experience",true)
	Plugin.UpdateLabel("Talent",true)
	Plugin.UpdateLabel("QuestExperienceTalent",true)
	Plugin.UpdateLabel("QuestTalent",true)
end

function Plugin.UpdateTooltip(ButtonName,EqType)
	local Title = TEXT("SYS_WEAREQTYPE_"..EqType)

	local tooltip = {
		Title = Title,
		Content = {},
	}

	table.insert(tooltip.Content,{"|cff00ff00"..GetLocale("BUFFS").."|r",(Values[ButtonName].Buffs.Sum).." %"})
	for k,v in ipairs(Values[ButtonName].Buffs) do
		table.insert(tooltip.Content,{v[1],(v[2]).." %"})
	end
	if #Values[ButtonName].Buffs > 0 then
		table.insert(tooltip.Content,"")
		table.insert(tooltip.Content,"")
	end

	table.insert(tooltip.Content,{"|cff00ff00"..GetLocale("EQUIPMENT").."|r",(Values[ButtonName].Equipment.Sum).." %"})
	for k,v in ipairs(Values[ButtonName].Equipment) do
		table.insert(tooltip.Content,{v[1],(v[2]).." %"})
	end
	if #Values[ButtonName].Equipment > 0 then
		table.insert(tooltip.Content,"")
		table.insert(tooltip.Content,"")
	end

	table.insert(tooltip.Content,{"|cff00ff00"..GetLocale("MISC").."|r",(Values[ButtonName].Misc.Sum).." %"})
	for k,v in ipairs(Values[ButtonName].Misc) do
		table.insert(tooltip.Content,{v[1],(v[2]).." %"})
	end

	table.insert(tooltip.Content,true)
	ZZIB.Buttons.UpdateTooltip("DETZZIB"..ButtonName, tooltip)
end

function Plugin.ApplyAll()
	for _, fn in pairs(Plugin.Apply) do
		fn()
	end
end

------------------------------------------------------------
-- EVENT Handler -------------------------------------------
------------------------------------------------------------

ZZLibrary.Event.Register("VARIABLES_LOADED", Functions.Init, "DET_Init")
ZZLibrary.Event.Register("ZZIB_INITDONE", Plugin.Init, "DET_Init_Plugin")
ZZLibrary.Event.Register("ZZIB_NEEDREDRAW",Plugin.UpdateAllLabels, "DET_UpdateAllLabel")
