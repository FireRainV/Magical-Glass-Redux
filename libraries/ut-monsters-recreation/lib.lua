local lib = {}

function lib:init()
    self.weak_hit = false
    
    Utils.hook(LightBullet, "onDamage", function(orig, self, soul)
        if self.attacker and Utils.containsValue({"froggit", "moldsmal"}, self.attacker.id) then
            lib.weak_hit = true
        end
        local battlers = orig(self, soul)
        lib.weak_hit = false
        return battlers
    end)
    
    Utils.hook(LightPartyBattler, "calculateDamage", function(orig, self, amount)
        if lib.weak_hit then
            local def = self.chara:getStat("defense")
            local max_hp = self.chara:getStat("health")
            local hp = self.chara:getHealth()
            
            if Game:isLight() then
                local bonus = 0 -- no bonus damage
                amount = Utils.round(amount + bonus - def / 5)
            else
                local threshold_a = (max_hp / 5)
                local threshold_b = (max_hp / 8)
                for i = 1, def do
                    if amount > threshold_a then
                        amount = amount - 3
                    elseif amount > threshold_b then
                        amount = amount - 2
                    else
                        amount = amount - 1
                    end
                    if amount <= 0 or def == math.huge then
                        amount = 0
                        break
                    end
                end
            end

            return math.max(amount, 1)
        else
            return orig(self, amount)
        end
    end)
end

return lib