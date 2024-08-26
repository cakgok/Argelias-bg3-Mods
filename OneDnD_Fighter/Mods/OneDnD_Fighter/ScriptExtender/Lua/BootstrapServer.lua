if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") then
    if Mods.BG3MCM.MCMAPI:GetSettingValue("improvedExtraAttackFix", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") then
        Ext.Require("ImprovedExtraAttackFix.lua")
    end
else
    Ext.Require("ImprovedExtraAttackFix.lua")
end

local SecondWindChargeUUID = "6a678987-2391-40a2-99b7-d026a5573f73"
local MovementUUID = "d6b2369d-84f0-4ca4-a3a7-62d2d192a185"

--of course Focus has a more complete implementation, maybe use that
local function increaseResource(entity)
	entity = Ext.Entity.Get(entity)
    if entity.ActionResources.Resources[SecondWindChargeUUID] then
        local resource = entity.ActionResources.Resources[SecondWindChargeUUID][1]
		if resource then
			if resource.Amount < resource.MaxAmount then
				resource.Amount = resource.Amount + 1
			end
		end
    end
    entity:Replicate("ActionResources")
end

local function increaseMovement(entity)
	entity = Ext.Entity.Get(entity)
    if entity.ActionResources.Resources[MovementUUID] then
        local resource = entity.ActionResources.Resources[MovementUUID][1]
		if resource.ResourceUUID == MovementUUID then
			resource.Amount = resource.Amount + (resource.MaxAmount / 2)
		end
    end
    entity:Replicate("ActionResources")
end

local function secondWindRollResult(_, roller, _, resultType, _, _)
    if Osi.HasActiveStatus(roller, "TACTICAL_MIND_BONUS") == 1 then
        Osi.RemoveStatus(roller, "TACTICAL_MIND_BONUS")
        if resultType == 0 then
            increaseResource(roller)
        end
    end
end

local function secondWindBoostMovement(object, status, causee, _)
    if status == "RESTORE_HALF_MOVEMENT" then
        increaseMovement(object)
    end
end

Ext.Osiris.RegisterListener("RollResult", 6, "after", secondWindRollResult)
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", secondWindBoostMovement)
