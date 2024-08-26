local function pickStatusToApply(roll)
    local effects = {
        [1] = "INCAPACITATED_DND",
        [2] = "BLINDED",
        [3] = "FRIGHTENED",
        [4] = "POISONED",
        [5] = "CHARMED",
        [6] = "PRONE"
    }
    local effect = effects[roll]
    return effect
end

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(target, status, caster, _)
	local rollValue = Ext.Math.Add(Random(6),1)
	if status == "ARCANE_ERUPTION_EXPLOSION_STATUS" then
		local statusToApply = pickStatusToApply(rollValue)
		Osi.ApplyStatus(target, statusToApply, 6, 0, caster)
	end
end)

