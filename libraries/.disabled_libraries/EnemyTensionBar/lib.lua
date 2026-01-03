local lib = {}

function lib:init()
    Utils.hook(Battle, "postInit", function(orig, self, state, encounter)
        orig(self, state, encounter)
        
        self.enemy_tension_bar = EnemyTensionBar(SCREEN_WIDTH+32, 40, true)
        self:addChild(self.enemy_tension_bar)
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "postInit", function(orig, self, state, encounter)
            orig(self, state, encounter)
            
            self.enemy_tension_bar = LightEnemyTensionBar(SCREEN_WIDTH-52, 55, true)
            if not self.encounter.enemy_tension_bar_on_start then
                self.enemy_tension_bar:hide()
            end
            self:addChild(self.enemy_tension_bar)
        end)
    end
    
    Utils.hook(Battle, "showUI", function(orig, self)
        orig(self)
        if self.enemy_tension_bar and self.encounter.enemy_tension_bar_on_start then
            self.enemy_tension_bar:show()
        end
    end)
    
    Utils.hook(Battle, "onStateChange", function(orig, self, old, new)
        if new == "VICTORY" then
            self.enemy_tension_bar:hide()
        end
        
        orig(self, old, new)
    end)
    
    if Kristal.getLibConfig("enemy_tension_bar", "grazing_tp") then
        Utils.hook(Soul, "onGraze", function(orig, self, bullet, old_graze)
            if old_graze then
                if Game.battle.enemy_tension_bar and Game.battle.enemy_tension_bar.shown then
                    Game.battle.enemy_tension_bar:giveTension(bullet:getGrazeTension() * DT * self.graze_tp_factor)
                end
            else
                if Game.battle.enemy_tension_bar and Game.battle.enemy_tension_bar.shown then
                    Game.battle.enemy_tension_bar:giveTension(bullet:getGrazeTension() * self.graze_tp_factor)
                end
            end
            
            orig(self, bullet, old_graze)
        end)
        
        if Mod.libs["magical-glass"] then
            Utils.hook(LightSoul, "onGraze", function(orig, self, bullet, old_graze)
                if old_graze then
                    if Game.battle.enemy_tension_bar and Game.battle.enemy_tension_bar.visible then
                        Game.battle.enemy_tension_bar:giveTension(bullet:getGrazeTension() * DT * self.graze_tp_factor)
                    end
                else
                    if Game.battle.enemy_tension_bar and Game.battle.enemy_tension_bar.visible then
                        Game.battle.enemy_tension_bar:giveTension(bullet:getGrazeTension() * self.graze_tp_factor)
                    end
                end
                
                orig(self, bullet, old_graze)
            end)
        end
    end
    
    Utils.hook(Encounter, "init", function(orig, self)
        orig(self)
        
        self.enemy_tension_bar_on_start = false
        
        self.enemy_tension_bar_color_bg = {0, 0, 114 / 255}
        self.enemy_tension_bar_color_fill = {100 / 255, 100 / 255, 255 / 255}
        self.enemy_tension_bar_color_decrease = {1, 0, 0}
        self.enemy_tension_bar_color_max = {200 / 255, 200 / 255, 255 / 255}
        self.enemy_tension_bar_MAX_color = {109 / 255, 153 / 255, 255 / 255}
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightEncounter, "init", function(orig, self)
            orig(self)
            
            self.enemy_tension_bar_on_start = false
            
            self.enemy_tension_bar_color_bg = {0, 0, 114 / 255}
            self.enemy_tension_bar_color_fill = {100 / 255, 100 / 255, 255 / 255}
            self.enemy_tension_bar_color_decrease = {1, 0, 0}
            self.enemy_tension_bar_color_max = {200 / 255, 200 / 255, 255 / 255}
            self.enemy_tension_bar_MAX_color = {109 / 255, 153 / 255, 255 / 255}
        end)
    end
    
end


return lib