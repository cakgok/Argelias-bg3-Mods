local debugEnabled = false
local removeActionPointEnabled = true
local disableOutOfCombat = false
local skillCheck = "SpellCastingAbility"
local MCM_MOD_GUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"

if Ext.Mod.IsModLoaded(MCM_MOD_GUID) then
    removeActionPointEnabled = Mods.BG3MCM.MCMAPI:GetSettingValue("removeAP", "5fa193de-bedb-4303-af32-f2199193776c")
    debugEnabled = Mods.BG3MCM.MCMAPI:GetSettingValue("debugToggle", "5fa193de-bedb-4303-af32-f2199193776c")
    disableOutOfCombat = Mods.BG3MCM.MCMAPI:GetSettingValue("disableOutOfCombat", "5fa193de-bedb-4303-af32-f2199193776c")
    skillCheck = Mods.BG3MCM.MCMAPI:GetSettingValue("skillCheck", "5fa193de-bedb-4303-af32-f2199193776c")
end

local function debugPrint(...)
    if debugEnabled then
        print(...)
    end
end

local scrollTag = "dd86c045-0370-4ec9-b7c5-b0b160706f09"
local actionPointUUID = "734cbcfb-8922-4b6d-8330-b2a7e4c14b6a"

local scrollData = {
    [0] = { dc = "a491e4a0-d8c9-44fd-baf9-606f20c09c0d" },
    [1] = { dc = "7a49a44c-4e9c-436f-b98b-df320b054bf3" },
    [2] = { dc = "470288cd-d004-4ca2-9e42-74146df4b046" },
    [3] = { dc = "5ac278da-50fb-4811-99da-a368c4d7e57b" },
    [4] = { dc = "6a69333d-3bd8-47df-b72e-b6a9bb0259dc" },
    [5] = { dc = "e2ea8ff5-a39c-48f2-8d55-64d08e22c8a9" },
    [6] = { dc = "7b0b4731-d129-4f0e-946c-5f6ac3040b3c" },
}

local classAbilityMap = {
    ["92cd50b6-eb1b-4824-8adb-853e90c34c90"] = 7, -- Bard, Charisma
    ["784001e2-c96d-4153-beb6-2adbef5abc92"] = 7, -- Sorcerer, Charisma
    ["b4225a4b-4bbe-4d97-9e3c-4719dbd1487c"] = 7, -- Warlock, Charisma
    ["ff4d9497-023c-434a-bd14-82fc367e991c"] = 7, -- Paladin, Charisma
    ["114e7aee-d1d4-4371-8d90-8a2080592faf"] = 6, -- Cleric, Wisdom
    ["457d0a6e-9da8-4f95-a225-18382f0e94b5"] = 6, -- Druid, Wisdom
    ["36be18ba-23db-4dff-bfa6-ae105ce43144"] = 6, -- Ranger, Wisdom
    ["a865965f-501b-46e9-9eaa-7748e8c04d09"] = 5, -- Wizard, Intelligence
    ["03f972eb-de3c-4cdb-9050-e8e3fa0526eb"] = 5,  -- Artificer, Intelligence
	["84bfb42b-7200-4eda-aabc-d4273da53bc2"] = 5,  -- Blood Hunter, Intelligence
	["52296c38-fbb5-4e3a-a728-0420884ed152"] = 7,  -- DK, Charisma
	["ce03beac-fb46-4161-b826-06a377c3716d"] = 7,  -- Harlequin, Charisma
	["04a74cef-c7a8-44d0-996c-f45555555555"] = 5,  -- Magus, Intelligence
	["b9b47ec2-35de-43d0-9593-7bee0bf9e808"] = 5,  -- Mystic, Intelligence
	["47bcebb4-164d-409e-935f-7270447bab0a"] = 6,  -- Shaman, Wisdom
	["b448c84e-31f1-4b08-8b65-1d29b605afee"] = 7,  -- Succubus, Charisma
	["0aac9776-7ba5-4707-a11e-998f69eb5c08"] = 7,  -- Troubadour, Charisma
	["452e548b-9143-4f97-b390-ba0ce8a63017"] = 6,  -- Voidborne, Wisdom
	["2ed35e79-add5-41d4-9f54-12541231fd75"] = 6,  -- Witch, Wisdom
	["79046310-7183-42f4-9ce6-4ffdb8d65e9b"] = 7,  -- Another DK, Charisma
}

local subClassAbilityMap = {
	["c296bed5-341e-498a-9933-e9900d17a6f8"] = 5  --Green Lantern Fighter or Something, Wisdom
}

local excludedScrolls = {
    "LOOT_Scroll_ISF_Refill_Player_1",
    "LOOT_Scroll_ISF_Refill_Player_2",
    "LOOT_Scroll_ISF_Refill_Player_3",
    "LOOT_Scroll_ISF_Refill_Player_4",
    "LOOT_Scroll_ISF_Uninstall",
    "LOOT_Scroll_ISF_Reset_Tutorial_Chest",
    "LOOT_SCROLL_TrueResurrection",
}

local function isExcludedScroll(scroll)
    debugPrint("Checking if scroll is excluded: ", scroll)
    for _, excludedScroll in ipairs(excludedScrolls) do
        if string.find(scroll, excludedScroll) then
            debugPrint("Scroll is excluded: ", scroll)
            return true
        end
    end
    debugPrint("Scroll is not excluded: ", scroll)
    return false
end

local function removeActionPoint(entity)
    entity = Ext.Entity.Get(entity)
    if entity.ActionResources.Resources[actionPointUUID] then
        local resource = entity.ActionResources.Resources[actionPointUUID][1]
        if resource.ResourceUUID == actionPointUUID then
			resource.Amount = resource.Amount - 1
        end
    end
    entity:Replicate("ActionResources")
end

local abilityNames = {"empty", "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" }
local spellSlots_UUID = "d136c5d9-0ff0-43da-acce-a74a07f8d6bf"
local warlockSpellSlots_UUID = "e9127b70-22b7-42a1-b172-d02f828f260a"

local function getMaxResourceId(slot)
    local maxResourceId = -1
    for _, resourceEntry in ipairs(slot) do
        maxResourceId = math.max(maxResourceId, resourceEntry.ResourceId)
    end
    return maxResourceId
end

local function getMaxSpellLevel(caster)
    local casterTable = Ext.Entity.Get(caster)
    local resources = casterTable.ActionResources.Resources

    local highestSpellSlot = resources[spellSlots_UUID] and getMaxResourceId(resources[spellSlots_UUID]) or -1
    local highestWarlockSlot = resources[warlockSpellSlots_UUID] and getMaxResourceId(resources[warlockSpellSlots_UUID]) or -1

    return math.max(highestSpellSlot, highestWarlockSlot)
end

local function getSpellCastingAbility(caster)
    local entity = Ext.Entity.Get(caster)
    local abilities = entity.Stats.Abilities

    local spellCastingAbility = "Intelligence"
    local highestScore = abilities[5] -- Default to Intelligence score

    local classes = entity.Classes.Classes
    for _, classInfo in ipairs(classes) do
        local classUUID = classInfo.ClassUUID
		local subClassUUID = classInfo.SubClassUUID
		local abilityIndex = (subClassUUID and subClassAbilityMap[subClassUUID]) or classAbilityMap[classUUID]
        if abilityIndex and abilities[abilityIndex] > highestScore then
            highestScore = abilities[abilityIndex]
            spellCastingAbility = abilityNames[abilityIndex]
        end
    end

    return spellCastingAbility
end

--------------------------
----Main function here----

--Added a mutex because container scrolls trigger two PassiveRolls for some reason
local isRequestingPassiveRoll = false

local function handleScrollUse(character, scrollRoot, scroll, _)

    if Osi.IsTagged(scroll, scrollTag) == 1 and not isExcludedScroll(scroll)  then
        local spell = Ext.Entity.Get(scroll).SpellBook.Spells[1]
        local scrollLevel = Ext.Stats.Get(spell.Id.OriginatorPrototype).Level
        local spellScroll = tostring(spell.Id.OriginatorPrototype) --don't pass it as object so we can "smuggle" it into inside listener

        local scrollCastHandler --get an id to unsub later

        scrollCastHandler = Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function(caster, usedSpell)
            if disableOutOfCombat and  Ext.Entity.Get(caster).TurnBased.IsInCombat_M == false then return end

            if string.find(usedSpell, spellScroll) then --To handle container spells
                local spellCastingAbility
                --[[Skipping for now, broken in devel(18)
                if Ext.Mod.IsModLoaded("112e0acf-1655-40a1-845e-abe3-a2a52604") then
                    local subClassGuid = _casterEntity.Classes.Classes[#_casterEntity.Classes.Classes].SubClassUUID
                    spellCastingAbility = Ext.StaticData.Get(subClassGuid, "ClassDescription").SpellCastingAbility or "Intelligence"
                else
                    spellCastingAbility = getSpellCastingAbility(caster)
                end
                ]]--
                spellCastingAbility = getSpellCastingAbility(caster) --don't forget to remove this after you enable the function above
                local maxCasterSpellLevel = getMaxSpellLevel(caster)

                if scrollLevel > maxCasterSpellLevel then
                    local levelData = scrollData[scrollLevel]
                    
                    -- If another request is already in progress, return without doing anything
                    if isRequestingPassiveRoll then return end
                    isRequestingPassiveRoll = true
                    if skillCheck == "SpellCastingAbility" then
                        Osi.RequestPassiveRoll(caster, scroll, "RawAbility", spellCastingAbility, levelData.dc, 0, "scrollCastRoll")
                    elseif skillCheck == "Arcana" then
                        Osi.RequestPassiveRoll(caster, scroll, "SkillCheck", "Arcana", levelData.dc, 0, "scrollCastRoll")
                    elseif skillCheck == "Religion" then
                        Osi.RequestPassiveRoll(caster, scroll, "SkillCheck", "Religion", levelData.dc, 0, "scrollCastRoll")
					elseif skillCheck == "Intelligence" then
                        Osi.RequestPassiveRoll(caster, scroll, "RawAbility", "Intelligence", levelData.dc, 0, "scrollCastRoll")
                    end
                    --Osi.RequestPassiveRoll(caster, scroll, "RawAbility", spellCastingAbility, "36a5be3e-74f4-4ae2-aa1a-a2ea7ec36e8d" , 0, "scrollCastRoll") --testDC25
                end
            end
            Ext.Osiris.UnregisterListener(scrollCastHandler) --Unregister so we won't listen to unneccessary spell casts.
        end)

    end
end

local function handleRollResult(eventName, roller, scroll, resultType, _, _)
    if eventName == "scrollCastRoll" and resultType == 0 then
        local entityRoller = Ext.Entity.Get(roller)
        local scrollRoot = Osi.GetTemplate(scroll)
        Osi.UseSpell(roller, "Shout_Dash", roller)              --Any spell as long as you purge the queue after
        Osi.PurgeOsirisQueue(roller)                            --Actually, you can only purge forced actions, but game purges the whole queue as a side effect
        Osi.TemplateRemoveFromUser(scrollRoot, roller, 1)       --That's why you need an Osi call before Purge
        if removeActionPointEnabled and (entityRoller.TurnBased.IsInCombat_M or Osi.IsInForceTurnBasedMode(roller) == 1) then
            removeActionPoint(roller)
        end
    end
	isRequestingPassiveRoll = false
end

Ext.Osiris.RegisterListener("TemplateUseFinished", 4, "after", handleScrollUse)
Ext.Osiris.RegisterListener("RollResult", 6, "after", handleRollResult)
