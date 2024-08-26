local CF_MOD_GUID = "67fbbd53-7c7d-4cfa-9409-6d737b4d92a9"
local MCM_MOD_GUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"

if not Ext.Mod.IsModLoaded(CF_MOD_GUID) then return end

local function getConfigSettings()
    local defaults = {studiedAttacks = true, improvedExtraAttackFix = true}
    
    if not Ext.Mod.IsModLoaded(MCM_MOD_GUID) then return defaults end
    
    return {
        studiedAttacks = Mods.BG3MCM.MCMAPI:GetSettingValue("studiedAttacks", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac"),
        improvedExtraAttackFix = Mods.BG3MCM.MCMAPI:GetSettingValue("improvedExtraAttackFix", "562aa89a-6a6a-4278-8cfa-e59f73b2cdac")
    }
end

local function createStudiedAttacksPayload(settings)
    if Ext.Mod.IsModLoaded("a2c4b0fc-e745-41df-81b7-fa53950d86a0") or Ext.Mod.IsModLoaded("d903677e-f24b-48ec-ab20-98dcc116a371") then
        return {
            modGuid = "562aa89a-6a6a-4278-8cfa-e59f73b2cdac",
            Target = "30bc922d-9cb5-4761-8d5c-7a2a18867fde",
            FileType = "Progression",
            Type = "PassivesAdded",
            Strings = {"StudiedAttacks"}
        }
    elseif settings.studiedAttacks then
        return {
            modGuid = "562aa89a-6a6a-4278-8cfa-e59f73b2cdac",
            Target = "ddf55c97-9032-4aa1-af76-4ae669a6b53b",
            FileType = "Progression",
            Type = "PassivesAdded",
            Strings = {"StudiedAttacks"}
        }
    end
end

local function createExtraAttackPayloads(settings)
    if not settings.improvedExtraAttackFix then return {} end

    return {
        {
            modGuid = "562aa89a-6a6a-4278-8cfa-e59f73b2cdac",
            Target = "d393b47c-629b-4c26-a857-741f9ef2eff2",
            FileType = "Progression",
            Type = "PassivesAdded",
            Strings = {"ExtraAttack_2_EK"}
        },
  		{
		    modGuid = "562aa89a-6a6a-4278-8cfa-e59f73b2cdac",
            Target = "d393b47c-629b-4c26-a857-741f9ef2eff2",
            FileType = "Progression",
			Type = "PassivesRemoved",
            Strings = {"ExtraAttack_2"}
        }
    }
end

local function OnStatsLoaded()
    local settings = getConfigSettings()
    local payloads = {}

    local studiedAttacksPayload = createStudiedAttacksPayload(settings)
    if studiedAttacksPayload then table.insert(payloads, studiedAttacksPayload) end

    for _, payload in ipairs(createExtraAttackPayloads(settings)) do
        table.insert(payloads, payload)
    end

    for _, payload in ipairs(payloads) do
        Mods.SubclassCompatibilityFramework.Api.InsertPassives({payload})
    end
end

Ext.Events.StatsLoaded:Subscribe(OnStatsLoaded)