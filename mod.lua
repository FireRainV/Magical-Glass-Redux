function Mod:init()
    print("Loaded "..self.info.name.."!")
    
    -- -- Flavor Color (Like Deltatraveler)
    -- Utils.hook(LightActionButton, "draw", function(orig, self)
        -- if self.selectable and self.hovered then
            -- love.graphics.draw(self.hover_tex or self.tex)
        -- else
            -- love.graphics.draw(self.tex)
        -- end
        
        -- if self.rainbow then
            -- self:removeFX(ShaderFX)
            -- self:setColor(Utils.hslToRgb(Kristal.getTime() / 0.75 % 1, 1, 0.69))
        -- elseif not self:getFX(ShaderFX) then
            -- local function flavor()
                -- if self.selectable and self.hovered then
                    -- return {1, 0.69, 1, 1}
                -- else
                    -- return {1, 0, 1, 1}
                -- end
            -- end
            -- self:addFX(ShaderFX(MagicalGlassLib:colorShader(), {["targetColor"] = flavor}))
        -- end
        
        -- Object.draw(self)
    -- end)
    
    --[[
    for _,item in pairs(Registry.items) do
        local item = item()
        if item.light == false and item.type == "item" and #item:getShortName() > 11 then
            print(item:getShortName())
        end 
    end
    ]]
end

function Mod:load(data, new_file)
    if new_file then
        Game.money = Kristal.getLibConfig("magical-glass", "debug") and 1000 or 0
        Game.lw_money = Kristal.getLibConfig("magical-glass", "debug") and 1000 or 0
        MagicalGlassLib:setLightBattleShakingText(true)
        MagicalGlassLib:setCellCallsRearrangement(true)
        -- local party = Game:getPartyMember("noelle")
        -- party:setLightEXP(69420)
        -- party.lw_health = party.lw_stats.health
        
        Game.world:registerCall("Dimensional Box A", "cell.box_a")
        Game.world:registerCall("Dimensional Box B", "cell.box_b")
        Game.world:registerCall("Settings", "cell.settings")
        Game.world:registerCall("Recruits Menu", "cell.recruits")
    end
end

-- function Mod:getUISkin()
    -- return "dark"
-- end

-- function Mod:postUpdate()
    -- -- Text shakiness depending on HP
    -- if Game.state == "BATTLE" and Game.battle.light then
        -- local current_hp = 0
        -- local max_hp = 0
        -- for _,party in ipairs (Game.battle.party) do
             -- current_hp = current_hp + party.chara:getHealth()
             -- max_hp = max_hp + party.chara:getStat("health")
        -- end
        -- local average_hp = math.ceil(max_hp / current_hp / #Game.battle.party)
        -- MagicalGlassLib:setLightBattleShakingText(Utils.clamp((average_hp - 1) / 4, 0.501, 2))
    -- end
-- end

-- function Mod:getLightActionButtons(battler, buttons)
    -- return {"fight", "mercy", "defend"}
-- end

-- function Mod:getActionButtons(battler, buttons)
    -- return {"act", "spare", "flee"}
-- end

-- function Mod:getLightActionButtonPairs(pairs)
    -- for _,pair in ipairs(pairs) do
        -- if Utils.containsValue(pair, "act") then
            -- table.insert(pair, "mercy")
            -- break
        -- end
    -- end
-- end