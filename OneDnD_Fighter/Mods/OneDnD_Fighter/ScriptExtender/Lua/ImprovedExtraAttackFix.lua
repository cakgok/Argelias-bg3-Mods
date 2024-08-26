local debugEnabled = false

if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") and Mods.BG3MCM.MCMAPI:GetSettingValue("debugToggle", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") then
	debugEnabled = Mods.BG3MCM.MCMAPI:GetSettingValue("debugToggle", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac") 
end

local function debugLog(...)
    if debugEnabled then print(...) end
end

local EXTRA_ATTACK_BLOCKED_TAG = "d0e9dcd3-d65c-4c43-933d-af3fd9c30fb0"
local entityStates = {}

local function safeGetEntityUuid(entity)
    local success, result = pcall(function()
        return Ext.Entity.Get(entity).Uuid.EntityUuid
    end)
    if success then
        return result
    else
        debugLog("Error getting entity UUID: " .. tostring(result))
        return nil
    end
end

local function canUseExtraAttack(entity)
    return Osi.HasPassive(entity, "ExtraAttack_2_EK") == 1
       and Osi.IsTagged(entity, EXTRA_ATTACK_BLOCKED_TAG) == 0
       and Osi.HasActiveStatus(entity, "SLAYER_PLAYER") == 0
       and Osi.HasPassive(entity, "WarMagic_EK") == 1
end

local function applyExtraAttackStatus(entity)
    Osi.ApplyStatus(entity, "EXTRA_ATTACK_2_EK", 6)
    debugLog("Status EXTRA_ATTACK_2_EK applied to " .. tostring(entity))
end

local function applyExtraAttackCantripStatus(entity)
    Osi.ApplyStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP", 6)
    debugLog("Status EXTRA_ATTACK_2_EK_CANTRIP applied to " .. tostring(entity))
end

local function removeExtraAttackCantripStatus(entity)
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP")
    debugLog("Removed extra attack cantrip status from " .. tostring(entity))
end

local function removeExtraAttackStatuses(entity)
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK_CANTRIP")
    Osi.RemoveStatus(entity, "EXTRA_ATTACK_2_EK")
    debugLog("Removed extra attack statuses from " .. tostring(entity))
end

--------------------------
-----Cleanup-and Init-----
--------------------------
local function resetEntityState(entity)
    local entityUuid = Ext.Entity.Get(entity).Uuid.EntityUuid
    if canUseExtraAttack(entity) then
        entityStates[entityUuid] = { attacksLeft = 3, cantripUsed = false }
        debugLog("Reset state for entity: " .. entityUuid)
    end
end

local function cleanupEntityState(entity)
    local entityUuid = Ext.Entity.Get(entity).Uuid.EntityUuid
    if entityStates[entityUuid] then
        entityStates[entityUuid] = nil
        removeExtraAttackStatuses(entity)
        debugLog("Cleaned up state for entity: " .. entityUuid)
    end
end
---------------------------

local function handleSpellCast(entity, spell, state)
    local spellStats = Ext.Stats.Get(spell)

    if spell == "Shout_ActionSurge" then
        state.cantripUsed = false
        state.attacksLeft = 3
        debugLog("ActionSurge used, resetting attacksLeft to 3")
    end

    debugLog("CantripUsed before check:", state.cantripUsed)
    debugLog("Attacks left before action:", state.attacksLeft)

    if state.attacksLeft > 0 then
        debugLog("Starting with " .. state.attacksLeft .. " attacks left")
        
        if spellStats.Level == 0 and Osi.SpellHasSpellFlag(spell, "IsSpell") == 1 then
            debugLog("Cantrip detected")
            if not state.cantripUsed then
                debugLog("First cantrip use")
                state.cantripUsed = true
                applyExtraAttackStatus(entity)
            else
                debugLog("Cantrip already used, no extra attack granted")
            end
            removeExtraAttackCantripStatus(entity)
            state.attacksLeft = state.attacksLeft - 1

        elseif Osi.SpellHasSpellFlag(spell, "IsAttack") == 1 then
            if not state.cantripUsed then
                applyExtraAttackCantripStatus(entity)
            end
            debugLog("Attack spell detected")
            applyExtraAttackStatus(entity)
            state.attacksLeft = state.attacksLeft - 1
        else
            debugLog("Used Extra Attack incompatible action: Cleaning up")
            cleanupEntityState(entity)
        end
        debugLog("Attacks left after action: " .. state.attacksLeft)
    end

    if state.attacksLeft == 0 then
        removeExtraAttackStatuses(entity)
        entityStates[Ext.Entity.Get(entity).Uuid.EntityUuid] = nil
        debugLog("Removed state for entity: " .. Ext.Entity.Get(entity).Uuid.EntityUuid)
    end
end

-- Listener for spell casts
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(attacker, spell, _, _, _)
    local attackerUuid = Ext.Entity.Get(attacker).Uuid.EntityUuid
    local state = entityStates[attackerUuid]

    -- Initialize state if not already present
    if not state then
        resetEntityState(attacker)
    end

    if state then
        handleSpellCast(attacker, spell, state)
    end
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", resetEntityState)
Ext.Osiris.RegisterListener("EnteredForceTurnBased", 1, "after", resetEntityState)
Ext.Osiris.RegisterListener("TurnEnded", 1, "after", cleanupEntityState)
Ext.Osiris.RegisterListener("LeftForceTurnBased", 1, "after", cleanupEntityState)
