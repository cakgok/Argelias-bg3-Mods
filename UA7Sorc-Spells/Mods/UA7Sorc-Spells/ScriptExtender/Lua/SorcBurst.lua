local isHandlingExplosions = false

local EXPLOSION_SPELLS = {
	Sorc_Blast_Acid = "Sorc_Blast_Explosion_Acid",
	Sorc_Blast_Cold = "Sorc_Blast_Explosion_Cold",
	Sorc_Blast_Fire = "Sorc_Blast_Explosion_Fire",
	Sorc_Blast_Lightning = "Sorc_Blast_Explosion_Lightning",
	Sorc_Blast_Psychic = "Sorc_Blast_Explosion_Psychic",
	Sorc_Blast_Poison = "Sorc_Blast_Explosion_Poison",
	Sorc_Blast_Thunder = "Sorc_Blast_Explosion_Thunder"		
}

local function handleExplosions(Inflicter, spellTarget, explosionSpell, maxRerolls, explosionsGotten, handlerExtra)
	
	if maxRerolls <= 0 or explosionsGotten <= 0 or isHandlingExplosions then
        return
    end
	
	isHandlingExplosions = true
	
	if handlerExtra then
		Ext.Events.BeforeDealDamage:Unsubscribe(handlerExtra)
		handlerExtra = nil
	end
	
	Osi.UseSpell(Inflicter, explosionSpell, spellTarget)
	maxRerolls = Ext.Math.Sub(maxRerolls, 1)
	explosionsGotten = Ext.Math.Sub(explosionsGotten,1)
	
	handlerExtra = Ext.Events.BeforeDealDamage:Subscribe(function(ex)
		if ex.Hit ~= nil and ex.Hit.Inflicter ~= nil and ex.Hit.Results ~= nil and ex.Hit.SpellId == explosionSpell then
			
			if ex.Hit.Results.ConditionRoll.RollParams[1].Result.NaturalRoll == 8 then
				explosionsGotten = Ext.Math.Add(explosionsGotten,1)
			end
			
			Ext.OnNextTick(function()
				isHandlingExplosions = false 
				handleExplosions(Inflicter, spellTarget, explosionSpell, maxRerolls, explosionsGotten, handlerExtra)
			end)
		end
	end)
	Ext.OnNextTick(function()
		isHandlingExplosions = false
	end)
end

local function handleDamage(caster, target, spell)
    local explosionSpell
    local spellTarget = target
    local Inflicter = caster
    local explosionsGotten = 0
    local maxRerolls = 0
    local handler
    local handlerExtra
    local isCrit

	local explosionSpell = EXPLOSION_SPELLS[spell]
    
    handler = Ext.Events.BeforeDealDamage:Subscribe(function(e)
        if e.Hit ~= nil and e.Hit.Inflicter ~= nil and e.Hit.Results ~= nil and e.Hit.SpellId == spell then
            isCrit = e.Hit.ConditionRolls[1].Roll.Result.Critical == "Success" 
            Inflicter = e.Hit.Inflicter.Uuid.EntityUuid
            maxRerolls = e.Hit.ConditionRolls[1].Roll.Metadata.AbilityBoosts.Charisma
                
            if not isCrit then
                for _, rollResult in ipairs(e.Hit.Results.ConditionRoll.RollParams) do
                    if rollResult.Result.NaturalRoll ==8 then
                        explosionsGotten = Ext.Math.Add(explosionsGotten,1)
                    end
                end
				
            else
                for _, rollResult in ipairs(e.Hit.Results.ConditionRoll.RollParams) do
                    if rollResult.Result.NaturalRoll == 16 then
						explosionsGotten = Ext.Math.Add(explosionsGotten,2)
					elseif rollResult.Result.NaturalRoll >= 12 then
                        explosionsGotten = Ext.Math.Add(explosionsGotten,1)
                    end
                end
            end
            
            Ext.OnNextTick(function()
                if handler then
                    Ext.Events.BeforeDealDamage:Unsubscribe(handler)
                    handler = nil
                end
				
                if maxRerolls > 0 and explosionsGotten > 0 then
                    handleExplosions(Inflicter, spellTarget, explosionSpell, maxRerolls, explosionsGotten)
                end
            end)
        end
    end)
end

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, _, _, _)
	if EXPLOSION_SPELLS[spell] then
        handleDamage(caster, target, spell)
    end
end)