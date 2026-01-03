local lib = {}

function lib:init()
    Utils.hook(Encounter, "onDialogueEnd", function(orig, self)
        if self:getEnemyAutoAttack() then
            Game.battle:setState("ENEMYATTACKING")
        else
            orig(self)
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEncounter, "onDialogueEnd", function(orig, self)
            if self:getEnemyAutoAttack() and not self.story and not Game.battle.debug_wave then
                Game.battle:setState("ENEMYATTACKING")
            else
                orig(self)
            end
        end)
    end
    
    Utils.hook(Encounter, "init", function(orig, self)
        orig(self)
        self.party_auto_attack = Kristal.getLibConfig("classic_turn_based_rpg", "classic_party_attack")
        self.enemy_auto_attack = Kristal.getLibConfig("classic_turn_based_rpg", "classic_enemy_attack")
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEncounter, "init", function(orig, self)
            orig(self)
            self.party_auto_attack = Kristal.getLibConfig("classic_turn_based_rpg", "classic_party_attack")
            self.enemy_auto_attack = Kristal.getLibConfig("classic_turn_based_rpg", "classic_enemy_attack")
        end)
    end
    
    Utils.hook(Encounter, "getPartyAutoAttack", function(orig, self)
        return self.party_auto_attack
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEncounter, "getPartyAutoAttack", function(orig, self)
            return self.party_auto_attack
        end)
    end
    
    Utils.hook(Encounter, "getEnemyAutoAttack", function(orig, self)
        return self.enemy_auto_attack
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEncounter, "getEnemyAutoAttack", function(orig, self)
            return self.enemy_auto_attack
        end)
    end
    
    Utils.hook(EnemyBattler, "onAttack", function(orig, self, cutscene)
        local miss = Utils.random(1, 100) <= 10
        local critical_hit = not miss and Utils.random(1, 100) <= 12.5
        local extra_text = ""
        if not miss then
            local battlers = Game.battle:hurt(self.attack * (Game:isLight() and 1 or 5) * (critical_hit and 2 or 1), false, self.current_target)
            if critical_hit then
                extra_text = extra_text .. "\n* A critical hit!"
                Assets.stopAndPlaySound("criticalswing")

                for i = 1, 3 do
                    local sx, sy = self:getRelativePos(0, 0)
                    local sparkle = Sprite("effects/criticalswing/sparkle", sx - Utils.random(50), sy + 30 + Utils.random(30))
                    sparkle:play(4/30, true)
                    sparkle:setScale(2)
                    sparkle.layer = BATTLE_LAYERS["above_battlers"]
                    sparkle.physics.speed_x = -Utils.random(2, 6)
                    sparkle.physics.friction = -0.25
                    sparkle:fadeOutSpeedAndRemove()
                    Game.battle:addChild(sparkle)
                end
            end
            if #battlers == 1 then
                cutscene:text("* "..self.name.." attacked "..battlers[1].chara:getName().."!"..extra_text)
            else
                cutscene:text("* "..self.name.." attacked!"..extra_text)
            end
        else
            cutscene:text("* "..self.name.." missed!"..extra_text)
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEnemyBattler, "onAttack", function(orig, self, cutscene)
            local miss = Utils.random(1, 100) <= 10
            local critical_hit = not miss and Utils.random(1, 100) <= 12.5
            local extra_text = ""
            if not miss then
                local battlers = Game.battle:hurt(self.attack * (Game:isLight() and 1 or 5) * (critical_hit and 2 or 1), false, self.current_target)
                if critical_hit then
                    extra_text = extra_text .. "\n* A critical hit!"
                    Assets.stopAndPlaySound("criticalswing")
                end
                if #battlers == 1 then
                    cutscene:text("* "..self.name.." attacked "..battlers[1].chara:getNameOrYou(true).."."..extra_text)
                else
                    cutscene:text("* "..self.name.." attacked."..extra_text)
                end
            else
                cutscene:text("* "..self.name.." missed."..extra_text)
            end
        end)
    end
    
    Utils.hook(Battle, "onStateChange", function(orig, self, old, new)
        local result = self.encounter:beforeStateChange(old,new)
        if result or self.state ~= new then
            return
        end
    
        if old == "CUTSCENE" and new == "ENEMYATTACKING" then
            Game.battle:setState("ACTIONSELECT", "ENEMYATTACKED")
        elseif new == "ENEMYATTACKING" then
            Game.battle:startCutscene(function(cutscene)
                for _,enemy in ipairs(self:getActiveEnemies()) do
                    enemy:onAttack(cutscene)
                end
            end)
        elseif new == "ATTACKING" and self.encounter:getPartyAutoAttack() then
            for i,battler in ipairs(self.party) do
                local action = self.character_actions[i]
                if action and action.action == "ATTACK" then
                    action.action = "AUTOATTACK"
                    action.cancellable = false
                    if Utils.random(1, 100) <= 5 then
                        action.points = 0 -- miss
                    else
                        action.points = Utils.pick({150,120,120,110})
                    end
                    action.critical = action.points == 150
                end
            end
        end
        return orig(self, old, new)
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "onStateChange", function(orig, self, old, new)
            local result = self.encounter:beforeStateChange(old,new)
            if result or self.state ~= new then
                return
            end
        
            if old == "CUTSCENE" and new == "ENEMYATTACKING" then
                Game.battle:setState("ACTIONSELECT", "ENEMYATTACKED")
            elseif new == "ENEMYATTACKING" then
                Game.battle:startCutscene(function(cutscene)
                    for _,enemy in ipairs(self:getActiveEnemies()) do
                        enemy:onAttack(cutscene)
                    end
                end)
            elseif new == "ATTACKING" and self.encounter:getPartyAutoAttack() then
                for i,battler in ipairs(self.party) do
                    local action = self.character_actions[i]
                    if action and action.action == "ATTACK" then
                        action.action = "AUTOATTACK"
                        action.cancellable = false
                        if Utils.random(1, 100) <= 5 then
                            action.points = 0 -- miss
                        else
                            action.points = Utils.pick({150,120,120,110})
                        end
                        action.critical = action.points == 150
                    end
                end
            end
            return orig(self, old, new)
        end)
    end
    
    if not Mod.libs["ExpandedAttackLib"] then
        Utils.hook(Battle, "processAction", function(orig, self, action)
            local battler = self.party[action.character_id]
            local party_member = battler.chara
            local enemy = action.target

            self.current_processing_action = action

            local next_enemy = self:retargetEnemy()
            if not next_enemy then
                return true
            end

            if enemy and enemy.done_state then
                enemy = next_enemy
                action.target = next_enemy
            end
            
            -- Call mod callbacks for onBattleAction to either add new behaviour for an action or override existing behaviour
            -- Note: non-immediate actions require explicit "return false"!
            local callback_result = Kristal.modCall("onBattleAction", action, action.action, battler, enemy)
            if callback_result ~= nil then
                return callback_result
            end
            for lib_id,_ in Kristal.iterLibraries() do
                callback_result = Kristal.libCall(lib_id, "onBattleAction", action, action.action, battler, enemy)
                if callback_result ~= nil then
                    return callback_result
                end
            end
            
            if action.action == "AUTOATTACK" and action.critical then
                Assets.stopAndPlaySound("criticalswing")

                for i = 1, 3 do
                    local sx, sy = battler:getRelativePos(battler.width, 0)
                    local sparkle = Sprite("effects/criticalswing/sparkle", sx + Utils.random(50), sy + 30 + Utils.random(30))
                    sparkle:play(4/30, true)
                    sparkle:setScale(2)
                    sparkle.layer = BATTLE_LAYERS["above_battlers"]
                    sparkle.physics.speed_x = Utils.random(2, 6)
                    sparkle.physics.friction = -0.25
                    sparkle:fadeOutSpeedAndRemove()
                    self:addChild(sparkle)
                end
            end
            
            return orig(self, action)
        end)
    end
end


return lib