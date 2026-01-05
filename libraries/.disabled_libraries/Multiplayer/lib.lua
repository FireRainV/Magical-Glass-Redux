local Lib = {}

function Lib:load()
    self.clearInput = true
end

function Lib:init()
    self.colors = {COLORS.white, COLORS.gray, COLORS.dkgray}
    self.max_players = Utils.clamp(Kristal.getLibConfig("multiplayer", "max_players"), 1, Mod.libs["moreparty"] and 4 or 3)
    self.gamepad_bindings = Input.gamepad_bindings
    Input.gamepad_bindings = {}
    self.gamepad_pressed = {}
    self.gamepad_order = {}
    
    Utils.hook(Input, "getControllerType", function(orig)
        return Kristal.getLibConfig("multiplayer", "controller_type")
    end)
    
    Utils.hook(Input, "getTexture", function(orig, alias, gamepad)
        if Lib.gamepad_bindings[alias] and Lib.gamepad_bindings[alias][1] then
            return Input.getButtonTexture(Lib.gamepad_bindings[alias][1])
        else
            return Assets.getTexture("kristal/buttons/unknown")
        end
    end)
    
    Utils.hook(Input, "usingGamepad", function(orig)
        return Input.hasGamepad()
    end)
    
    Utils.hook(World, "init", function(orig, self, map)
        orig(self, map)
        self.other_players = {}
        self.other_souls = {}
    end)
    
    Utils.hook(World, "onKeyPressed", function(orig, self, key)
        orig(self, key)
        if self.state == "GAMEPLAY" then
            for _,player in ipairs(self.other_players) do
                if Input.is("p".. player.index + 1 .."_confirm", key) and not self:hasCutscene() then
                    if player:interact() then
                        Input.clear("confirm")
                    end
                end
            end
        end
    end)
    
    Utils.hook(World, "spawnParty", function(orig, self, marker, party, extra, facing)
        party = party or Game.party or {"kris"}
        for _,player in pairs(self.other_players) do
            self:removeChild(player)
        end
        for _,soul in pairs(self.other_souls) do
            self:removeChild(soul)
        end
        if #party > 0 then
            for i,chara in ipairs(party) do
                if type(chara) == "string" then
                    party[i] = Game:getPartyMember(chara)
                end
            end
            if type(marker) == "table" then
                self:spawnPlayer(marker[1], marker[2], party[1]:getActor(), party[1].id)
                for i = 2, Lib.max_players do
                    if party[i] then
                        self:spawnOtherPlayer(i-1, marker[1], marker[2], party[i]:getActor(), party[i].id)
                    end
                end
            else
                self:spawnPlayer(marker or "spawn", party[1]:getActor(), party[1].id)
                for i = 2, math.min(Lib.max_players, #party) do
                    self:spawnOtherPlayer(i-1, marker or "spawn", party[i]:getActor(), party[i].id)
                end
            end
            if facing then
                self.player:setFacing(facing)
                for _,player in ipairs(self.other_players) do
                    player:setFacing(facing)
                end
            end
            for i = 2 + #self.other_players, #party do
                local follower = self:spawnFollower(party[i]:getActor(), {party = party[i].id})
                follower:setFacing(facing or self.player.facing)
            end
            for _,actor in ipairs(extra or Game.temp_followers or {}) do
                if type(actor) == "table" then
                    local follower = self:spawnFollower(actor[1], {index = actor[2]})
                    follower:setFacing(facing or self.player.facing)
                else
                    local follower = self:spawnFollower(actor)
                    follower:setFacing(facing or self.player.facing)
                end
            end
        end
    end)
    
    Utils.hook(World, "spawnOtherPlayer", function(orig, self, player, ...)
        local args = {...}

        local x, y = 0, 0
        local chara = self.other_players[player] and self.other_players[player].actor
        local party
        if #args > 0 then
            if type(args[1]) == "number" then
                x, y = args[1], args[2]
                chara = args[3] or chara
                party = args[4]
            elseif type(args[1]) == "string" then
                x, y = self.map:getMarker(args[1])
                chara = args[2] or chara
                party = args[3]
            end
        end

        if type(chara) == "string" then
            chara = Registry.createActor(chara)
        end

        local facing = "down"

        if Game.world.player then
            facing = Game.world.player.facing
        end

        self.other_players[player] = Mod.libs["magical-glass"] and Game.party[player + 1]:getUndertaleMovement() and OtherUnderPlayer(chara, x, y, player) or OtherPlayer(chara, x, y, player)
        self.other_players[player].layer = self.map.object_layer
        self.other_players[player]:setFacing(facing)
        self:addChild(self.other_players[player])
        

        if party then
            self.other_players[player].party = party
        end
        
        self.other_souls[player] = OverworldSoul(self.other_players[player]:getRelativePos(self.other_players[player].actor:getSoulOffset()))
        self.other_souls[player].index = player
        self.other_souls[player]:setColor(Game:getSoulColor())
        if Game.party[player + 1] then
            self.other_souls[player]:setColor(Game.party[player + 1]:getColor())
            if Game.party[player + 1].soul_priority < 2 then
                self.other_souls[player].rotation = math.pi
            end
        end
        self.other_souls[player].layer = WORLD_LAYERS["soul"]
        self:addChild(self.other_souls[player])
    end)
    
    if not Mod.libs["magical-glass"] then
        Utils.hook(World, "spawnPlayer", function(orig, self, ...)
            orig(self, ...)
            if Game.party[1] then
                self.soul:setColor(Game.party[1]:getColor())
                if Game.party[1].soul_priority < 2 then
                    self.soul.rotation = math.pi
                end
            end
        end)
    end
    
    Utils.hook(World, "getPartyCharacterInParty", function(orig, self, party)
        if type(party) == "string" then
            party = Game:getPartyMember(party)
        end
        if self.player and Game:hasPartyMember(self.player:getPartyMember()) and party == self.player:getPartyMember() then
            return self.player
        else
            for _,player in ipairs(self.other_players) do
                if Game:hasPartyMember(player:getPartyMember()) and party == player:getPartyMember() then
                    return player
                end
            end
            for _,follower in ipairs(self.followers) do
                if Game:hasPartyMember(follower:getPartyMember()) and party == follower:getPartyMember() then
                    return follower
                end
            end
        end
    end)
    
    Utils.hook(SlideArea, "update", function(orig, self)
        orig(self)
        
        for _,player in ipairs(Game.world.other_players) do
            local stopped = false

            Object.startCache()

            if player.y > self.y + self.height and not player:collidesWith(self.collider) then
                self.solid = true

                if player.state == "SLIDE" and player.current_slide_area == self then
                    stopped = true
                end
            else
                self.solid = false
            end

            if not stopped and player.state == "SLIDE" and player.current_slide_area == self then
                stopped = self:checkAgainstWall(player)
            end

            Object.endCache()

            if stopped then
                player:setState("WALK")

                player.current_slide_area = nil
            end
        end
    end)
    
    Utils.hook(OverworldSoul, "init", function(orig, self, x, y)
        self.index = 0
        orig(self, x, y)
    end)
    
    Utils.hook(OverworldSoul, "update", function(orig, self)
        -- Bullet collision !!! Yay
        if self.inv_timer > 0 then
            self.inv_timer = Utils.approach(self.inv_timer, 0, DT)
        end

        self.sprite.alpha = 1 -- ??????

        Object.startCache()
        for _,bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
            if bullet:collidesWith(self.collider) then
                self:onCollide(bullet)
            end
        end
        Object.endCache()

        if self.inv_timer > 0 then
            self.inv_flash_timer = self.inv_flash_timer + DT
            local amt = math.floor(self.inv_flash_timer / (4/30))
            if (amt % 2) == 1 then
                self.sprite:setColor(0.5, 0.5, 0.5)
            else
                self.sprite:setColor(1, 1, 1)
            end
        else
            self.inv_flash_timer = 0
            self.sprite:setColor(1, 1, 1)
        end

        local sx, sy = self.x, self.y
        local progress = 0

        local tx, ty
        if self.index == 0 then
            local soul_character = Game.world.player
            if soul_character then
                sx, sy = soul_character:getRelativePos(soul_character.actor:getSoulOffset())
            end

            tx, ty = sx, sy

            if Game.world.player and Game.world.player.battle_alpha > 0 then
                tx, ty = Game.world.player:getRelativePos(Game.world.player.actor:getSoulOffset())
                progress = Game.world.player.battle_alpha * 2
            end
        else
            local soul_character = Game.world.other_players[self.index]
            if soul_character then
                sx, sy = soul_character:getRelativePos(soul_character.actor:getSoulOffset())
            end

            tx, ty = sx, sy

            if Game.world.other_players[self.index] and Game.world.other_players[self.index].battle_alpha > 0 then
                tx, ty = Game.world.other_players[self.index]:getRelativePos(Game.world.other_players[self.index].actor:getSoulOffset())
                progress = Game.world.other_players[self.index].battle_alpha * 2
            end
        end

        self.x = Utils.lerp(sx, tx, progress * 1.5)
        self.y = Utils.lerp(sy, ty, progress * 1.5)
        self.alpha = progress

        Object.update(self)
    end)
    
    Utils.hook(Battle, "init", function(orig, self)
        self.other_souls = {}
        orig(self)
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "init", function(orig, self)
            self.other_souls = {}
            orig(self)
        end)
    end
    
    Utils.hook(Battle, "spawnOtherSoul", function(orig, self, x, y, index)
        self.other_souls[index] = self.encounter:createSoul(x, y, self.party[index+1] and (Mod.libs["magical-glass"] and Kristal.getLibConfig("magical-glass", "light_world_dark_battle_color_override") == true and Game:isLight() and self.party[index+1].chara.color or {self.party[index+1].chara:getColor()}) or Lib.colors[index])
        self.other_souls[index].index = index
        self.other_souls[index].inv_timer = self.soul.inv_timer
        if (self.party[index+1] and self.party[index+1].chara.soul_priority < 2 or not self.party[index+1]) and Utils.getClassName(self.other_souls[index]) == "Soul" then
            self.other_souls[index].rotation = math.pi
        end
        self:addChild(self.other_souls[index])
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "spawnOtherSoul", function(orig, self, x, y, index)
            self.other_souls[index] = self.encounter:createSoul(x, y, self.party[index+1] and {self.party[index+1].chara:getColor()} or Lib.colors[index])
            self.other_souls[index].alpha = 1
            self.other_souls[index].sprite:set("player/heart_light")
            self.other_souls[index].index = index
            if (self.party[index+1] and self.party[index+1].chara.soul_priority < 2 or not self.party[index+1]) and Utils.getClassName(self.other_souls[index]) == "LightSoul" then
                self.other_souls[index].rotation = math.pi
            end
            self:addChild(self.other_souls[index])
        end)
    end
    
    Utils.hook(Battle, "swapSoul", function(orig, self, object)
        orig(self, object)
        self.timer:after(1/30, function()
            self.soul:setColor(Mod.libs["magical-glass"] and Kristal.getLibConfig("magical-glass", "light_world_dark_battle_color_override") == true and Game:isLight() and self.party[1].chara.color or {self.party[1].chara:getColor()})
        end)
        local objects = {}
        for i = 1, #self.other_souls do
            local index = i
            if self.other_souls[i] then
                index = self.other_souls[i].index
                self.other_souls[i]:remove()
            end
            objects[i] = Utils.copy(object, true)
            objects[i]:setPosition(self.other_souls[i]:getPosition())
            objects[i].layer = self.other_souls[i].layer
            self.other_souls[i] = objects[i]
            self.other_souls[i].index = index
            self:addChild(objects[i])
            self.timer:after(1/30, function()
                self.other_souls[i]:setColor(self.party[i+1] and (Mod.libs["magical-glass"] and Kristal.getLibConfig("magical-glass", "light_world_dark_battle_color_override") == true and Game:isLight() and self.party[i+1].chara.color or {self.party[i+1].chara:getColor()}) or Lib.colors[i])
            end)
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "swapSoul", function(orig, self, object)
            orig(self, object)
            if Game.battle:getState() == "DEFENDING" then
                self.timer:after(1/30, function()
                    self.soul:setColor({self.party[1].chara:getColor()})
                end)
            end
            local objects = {}
            for i = 1, #self.other_souls do
                local index = i
                if self.other_souls[i] then
                    index = self.other_souls[i].index
                    self.other_souls[i]:remove()
                end
                objects[i] = Utils.copy(object, true)
                objects[i]:setPosition(self.other_souls[i]:getPosition())
                objects[i].layer = self.other_souls[i].layer
                self.other_souls[i] = objects[i]
                self.other_souls[i].index = index
                self:addChild(objects[i])
                self.timer:after(1/30, function()
                    self.other_souls[i]:setColor(self.party[i+1] and {self.party[i+1].chara:getColor()} or Lib.colors[i])
                end)
            end
        end)
    end
    
    Utils.hook(Battle, "onStateChange", function(orig, self, old, new)
        orig(self, old, new)
        if new == "DEFENDING" then
            if self.soul then
                local x, y = self:getSoulLocation()
                for i = 1, Lib.max_players - 1 do
                    self:spawnOtherSoul(x, y, i)
                    self.other_souls[i]:setColor(self.party[i+1] and (Mod.libs["magical-glass"] and Kristal.getLibConfig("magical-glass", "light_world_dark_battle_color_override") == true and Game:isLight() and self.party[i+1].chara.color or {self.party[i+1].chara:getColor()}) or Lib.colors[i])
                end
                self.soul:setColor(Mod.libs["magical-glass"] and Kristal.getLibConfig("magical-glass", "light_world_dark_battle_color_override") == true and Game:isLight() and self.party[1].chara.color or {self.party[1].chara:getColor()})
                if self.party[1].chara.soul_priority < 2 and Utils.getClassName(self.soul) == "Soul" then
                    self.soul.rotation = math.pi
                end
            end
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "update", function(orig, self)
            orig(self)
            if self.soul then
                for _,soul in ipairs(self.other_souls) do
                    soul.visible = self.soul.visible
                    soul.collidable = self.soul.collidable
                end
            end
        end)
        
        Utils.hook(LightBattle, "onStateChange", function(orig, self, old, new)
            orig(self, old, new)
            if new == "DEFENDING" then
                if self.soul then
                    local x, y = self:getSoulLocation()
                    for i = 1, Lib.max_players - 1 do
                        self:spawnOtherSoul(x, y, i)
                        self.other_souls[i]:setColor(self.party[i+1] and {self.party[i+1].chara:getColor()} or Lib.colors[i])
                    end
                    self.soul:setColor({self.party[1].chara:getColor()})
                    if self.party[1].chara.soul_priority < 2 and Utils.getClassName(self.soul) == "LightSoul" then
                        self.soul.rotation = math.pi
                    end
                end
            end
            if new == "DEFENDINGEND" then
                if self.soul then
                    self.soul:setColor({self.encounter:getSoulColor()})
                    if not self.soul:includes(YellowSoul) then
                        self.soul.rotation = 0
                    end
                end
                for _,soul in ipairs(self.other_souls) do
                    soul:remove()
                end
            end
        end)
    end
    
    Utils.hook(Battle, "returnSoul", function(orig, self, dont_destroy)
        if self.soul then
            self.soul:setColor({self.encounter:getSoulColor()})
            if not self.soul:includes(YellowSoul) then
                self.soul.rotation = 0
            end
        end
        orig(self, dont_destroy)
        for _,soul in ipairs(self.other_souls) do
            soul:remove()
        end
    end)
    
    Utils.hook(Battle, "createPartyBattlers", function(orig, self)
        for i = 1, #Game.party do
            local party_member = Game.party[i]

            if Game.world.player and Game.world.player.visible and Game.world.player.actor.id == party_member:getActor().id then
                -- Create the player battler
                local player_x, player_y = Game.world.player:getScreenPos()
                local player_battler = PartyBattler(party_member, player_x, player_y)
                player_battler:setAnimation("battle/transition")
                self:addChild(player_battler)
                table.insert(self.party,player_battler)
                table.insert(self.party_beginning_positions, {player_x, player_y})
                self.party_world_characters[party_member.id] = Game.world.player

                Game.world.player.visible = false
            else
                local found = false
                for _,follower in ipairs(Game.world.followers) do
                    if follower.visible and follower.actor.id == party_member:getActor().id then
                        local chara_x, chara_y = follower:getScreenPos()
                        local chara_battler = PartyBattler(party_member, chara_x, chara_y)
                        chara_battler:setAnimation("battle/transition")
                        self:addChild(chara_battler)
                        table.insert(self.party, chara_battler)
                        table.insert(self.party_beginning_positions, {chara_x, chara_y})
                        self.party_world_characters[party_member.id] = follower

                        follower.visible = false

                        found = true
                        break
                    end
                end
                for _,player in ipairs(Game.world.other_players) do
                    if player.visible and player.actor.id == party_member:getActor().id then
                        local chara_x, chara_y = player:getScreenPos()
                        local chara_battler = PartyBattler(party_member, chara_x, chara_y)
                        chara_battler:setAnimation("battle/transition")
                        self:addChild(chara_battler)
                        table.insert(self.party, chara_battler)
                        table.insert(self.party_beginning_positions, {chara_x, chara_y})
                        self.party_world_characters[party_member.id] = player

                        player.visible = false

                        found = true
                        break
                    end
                end
                if not found then
                    local chara_battler = PartyBattler(party_member, SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
                    chara_battler:setAnimation("battle/transition")
                    self:addChild(chara_battler)
                    table.insert(self.party, chara_battler)
                    table.insert(self.party_beginning_positions, {chara_battler.x, chara_battler.y})
                end
            end
        end
    end)
    
    Utils.hook(Battle, "handleAttackingInput", function(orig, self, key)
        if Input.isConfirm(key) then
            if not self.attack_done and not self.cancel_attack and #self.battle_ui.attack_boxes > 0 then
                local closest
                local closest_attacks = {}

                for _,attack in ipairs(self.battle_ui.attack_boxes) do
                    if not attack.attacked and (Utils.getIndex(Game.battle.party, attack.battler) == 1 or Utils.getIndex(Game.battle.party, attack.battler) > Lib.max_players) then
                        local close = attack:getClose()
                        if not closest then
                            closest = close
                            table.insert(closest_attacks, attack)
                        elseif close == closest then
                            table.insert(closest_attacks, attack)
                        elseif close < closest then
                            closest = close
                            closest_attacks = {attack}
                        end
                    end
                end

                if closest and closest < 14.2 and closest > -2 then
                    for _,attack in ipairs(closest_attacks) do
                        local points = attack:hit()

                        local action = self:getActionBy(attack.battler, true)
                        action.points = points

                        if self:processAction(action) then
                            self:finishAction(action)
                        end
                    end
                end
            end
        end
        for i = 2, math.min(Lib.max_players, #Game.battle.party) do
            if Input.is("p".. i .."_confirm", key) then
                if not self.attack_done and not self.cancel_attack and #self.battle_ui.attack_boxes > 0 then
                    local closest
                    local closest_attacks = {}

                    for _,attack in ipairs(self.battle_ui.attack_boxes) do
                        if not attack.attacked and Utils.getIndex(Game.battle.party, attack.battler) == i then
                            local close = attack:getClose()
                            if not closest then
                                closest = close
                                table.insert(closest_attacks, attack)
                            elseif close == closest then
                                table.insert(closest_attacks, attack)
                            elseif close < closest then
                                closest = close
                                closest_attacks = {attack}
                            end
                        end
                    end

                    if closest and closest < 14.2 and closest > -2 then
                        for _,attack in ipairs(closest_attacks) do
                            local points = attack:hit()

                            local action = self:getActionBy(attack.battler, true)
                            action.points = points

                            if self:processAction(action) then
                                self:finishAction(action)
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightBattle, "handleAttackingInput", function(orig, self, key)
            if Input.isConfirm(key) then
                if not self.attack_done and not self.cancel_attack and self.battle_ui.attack_box then
                    local closest
                    local closest_attacks = {}
                    local close

                    for _,attack in ipairs(self.battle_ui.attack_box.lanes) do
                        if not attack.attacked and (Utils.getIndex(Game.battle.party, attack.battler) == 1 or Utils.getIndex(Game.battle.party, attack.battler) > Lib.max_players) then
                            close = self.battle_ui.attack_box:getFirstBolt(attack)
                            if not closest then
                                closest = close
                                table.insert(closest_attacks, attack)
                            elseif close == closest then
                                table.insert(closest_attacks, attack)
                            elseif close < closest then
                                closest = close
                                closest_attacks = {attack}
                            end
                        end
                    end

                    if closest and (closest <= 280 or not Game.battle.multi_mode) then
                        for _,attack in ipairs(closest_attacks) do
                            local points, stretch = self.battle_ui.attack_box:hit(attack)

                            local action = self:getActionBy(attack.battler)
                            action.points = points
                            action.stretch = stretch

                            if self:processAction(action) then
                                self:finishAction(action)
                            end
                        end
                    end
                end
            end
            for i = 2, math.min(Lib.max_players, #Game.battle.party) do
                if Input.is("p".. i .."_confirm", key) then
                    if not self.attack_done and not self.cancel_attack and self.battle_ui.attack_box then
                        local closest
                        local closest_attacks = {}
                        local close

                        for _,attack in ipairs(self.battle_ui.attack_box.lanes) do
                            if not attack.attacked and Utils.getIndex(Game.battle.party, attack.battler) == i then
                                close = self.battle_ui.attack_box:getFirstBolt(attack)
                                if not closest then
                                    closest = close
                                    table.insert(closest_attacks, attack)
                                elseif close == closest then
                                    table.insert(closest_attacks, attack)
                                elseif close < closest then
                                    closest = close
                                    closest_attacks = {attack}
                                end
                            end
                        end

                        if closest and (closest <= 280 or not Game.battle.multi_mode) then
                            for _,attack in ipairs(closest_attacks) do
                                local points, stretch = self.battle_ui.attack_box:hit(attack)

                                local action = self:getActionBy(attack.battler)
                                action.points = points
                                action.stretch = stretch

                                if self:processAction(action) then
                                    self:finishAction(action)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    
    Utils.hook(Arena, "update", function(orig, self)
        orig(self)
        
        for _,soul in ipairs(Game.battle.other_souls) do
            if soul.collidable then
                Object.startCache()
                local angle_diff = self.clockwise and -(math.pi/2) or (math.pi/2)
                for _,line in ipairs(self.collider.colliders) do
                    local angle
                    while soul:collidesWith(line) do
                        if not angle then
                            local x1, y1 = self:getRelativePos(line.x, line.y, Game.battle)
                            local x2, y2 = self:getRelativePos(line.x2, line.y2, Game.battle)
                            angle = Utils.angle(x1, y1, x2, y2)
                        end
                        Object.uncache(soul)
                        soul:setPosition(
                            soul.x + (math.cos(angle + angle_diff)),
                            soul.y + (math.sin(angle + angle_diff))
                        )
                    end
                end
                Object.endCache()
            end
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightArena, "update", function(orig, self)
            orig(self)
            
            local other_souls = Game.battle and Game.battle.other_souls
            if other_souls then
                for _,soul in ipairs(other_souls) do
                    if soul.collidable then
                        Object.startCache()
                        local angle_diff = self.clockwise and -(math.pi/2) or (math.pi/2)
                        for _,line in ipairs(self.collider.colliders) do
                            local angle
                            while soul:collidesWith(line) do
                                if not angle then
                                    local x1, y1 = self:getRelativePos(line.x, line.y, Game.battle)
                                    local x2, y2 = self:getRelativePos(line.x2, line.y2, Game.battle)
                                    angle = Utils.angle(x1, y1, x2, y2)
                                end
                                Object.uncache(soul)
                                soul:setPosition(
                                    soul.x + (math.cos(angle + angle_diff)),
                                    soul.y + (math.sin(angle + angle_diff))
                                )
                            end
                        end
                        Object.endCache()
                    end
                end
            end
        end)
    end
    
    Utils.hook(Soul, "doMovement", function(orig, self)
        if not self.index then
            orig(self)
        else
            local speed = self.speed

            -- Do speed calculations here if required.

            if self.allow_focus then
                if Input.down("p".. self.index + 1 .."_cancel") then speed = speed / 2 end -- Focus mode.
            end

            local move_x, move_y = 0, 0

            -- Keyboard input:
            if Input.down("p".. self.index + 1 .."_left")  then move_x = move_x - 1 end
            if Input.down("p".. self.index + 1 .."_right") then move_x = move_x + 1 end
            if Input.down("p".. self.index + 1 .."_up")    then move_y = move_y - 1 end
            if Input.down("p".. self.index + 1 .."_down")  then move_y = move_y + 1 end

            self.moving_x = move_x
            self.moving_y = move_y

            if move_x ~= 0 or move_y ~= 0 then
                if not self:move(move_x, move_y, speed * DTMULT) then
                    self.moving_x = 0
                    self.moving_y = 0
                end
            end
        end
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightSoul, "doMovement", function(orig, self)
            if not self.index then
                orig(self)
            else
                local speed = self.speed

                -- Do speed calculations here if required.

                if self.allow_focus then
                    if Input.down("p".. self.index + 1 .."_cancel") then speed = speed / 2 end -- Focus mode.
                end

                local move_x, move_y = 0, 0

                -- Keyboard input:
                if Input.down("p".. self.index + 1 .."_left")  then move_x = move_x - 1 end
                if Input.down("p".. self.index + 1 .."_right") then move_x = move_x + 1 end
                if Input.down("p".. self.index + 1 .."_up")    then move_y = move_y - 1 end
                if Input.down("p".. self.index + 1 .."_down")  then move_y = move_y + 1 end

                self.moving_x = move_x
                self.moving_y = move_y

                if move_x ~= 0 or move_y ~= 0 then
                    if not self:move(move_x, move_y, speed * DTMULT) then
                        self.moving_x = 0
                        self.moving_y = 0
                    end
                end
            end
        end)
    end
    
    Utils.hook(Bullet, "onDamage", function(orig, self, soul)
        local damage = self:getDamage()
        if damage > 0 then
            soul.inv_timer = self.inv_timer
            return soul:onDamage(self, damage)
        end
        return {}
    end)
    
    Utils.hook(Soul, "onDamage", function(orig, self, bullet, amount)
        orig(self, bullet, amount)
        
        if bullet:getTarget() == "ANY" and (not self.index or Game.battle.party[self.index+1]) then
            if not self.index then
                if not Game.battle.party[1].is_down then
                    Game.battle.party[1]:hurt(amount)
                    return Game.battle.party[1]
                else
                    Game.battle:hurt(amount, false, bullet:getTarget())
                end
            else
                if not Game.battle.party[self.index+1].is_down then
                    Game.battle.party[self.index+1]:hurt(amount)
                    return Game.battle.party[self.index+1]
                else
                    Game.battle:hurt(amount, false, bullet:getTarget())
                end
            end
        else
            Game.battle:hurt(amount, false, bullet:getTarget())
        end
        return bullet:getTarget()
    end)
    
    if Mod.libs["magical-glass"] then
        Utils.hook(LightSoul, "onDamage", function(orig, self, bullet, amount)
            orig(self, bullet, amount)
            
            if bullet:getTarget() == "ANY" and (not self.index or Game.battle.party[self.index+1]) then
                if not self.index then
                    if not Game.battle.party[1].is_down then
                        Game.battle.party[1]:hurt(amount)
                        return Game.battle.party[1]
                    else
                        Game.battle:hurt(amount, false, bullet:getTarget())
                    end
                else
                    if not Game.battle.party[self.index+1].is_down then
                        Game.battle.party[self.index+1]:hurt(amount)
                        return Game.battle.party[self.index+1]
                    else
                        Game.battle:hurt(amount, false, bullet:getTarget())
                    end
                end
            else
                Game.battle:hurt(amount, false, bullet:getTarget())
            end
            return bullet:getTarget()
        end)
    end
    
    if not Mod.libs["moreparty"] and not Mod.libs["ExpandedAttackLib"] then
        Utils.hook(AttackBox, "update", function(orig, self)
            orig(self)
            local pressed_confirm = false
            for i = 2, math.min(Lib.max_players, #Game.battle.party) do
                if Input.pressed("p".. i .."_confirm") then
                    pressed_confirm = true
                end
            end
            if not Game.battle.cancel_attack and pressed_confirm then
                self.flash = 1
            end
        end)
    end
    
    if Mod.libs["yellowsoul"] then -- Compactiblity with the Yellow Soul Library
        Utils.hook(YellowSoul, "update", function(orig, self)
            if not self.index then
                orig(self)
            else
                Soul.update(self)
                if self.transitioning then
                    if self.charge_sfx then
                        self.charge_sfx:stop()
                        self.charge_sfx = nil
                    end
                    return
                end

                if not self:canShoot() then return end
                
                if Input.down("p".. self.index + 1 .."_confirm") and self.hold_timer == 0 and self:canUseShots() then -- fire normal shot
                    self:fireShot(false)
                end
                if self:canUseBigShot() then
                    -- check release before checking hold, since if held is false it sets the timer to 0
                    if not Input.down("p".. self.index + 1 .."_confirm") then -- fire big shot
                        if self.hold_timer >= 10 and self.hold_timer < 40 then -- didn't hold long enough, fire normal shot
                            self:fireShot(false)
                        elseif self.hold_timer >= 40 then -- fire big shot
                            if self:canCheat() and Input.down("p".. self.index + 1 .."_confirm") then -- they are cheating
                                self:onCheat()
                            end
                            self:fireShot(true)
                            if self.teaching then
                                self.teaching = false
                            end
                        end
                        if not self:canCheat() then -- reset hold timer if cheating is disabled
                            self.hold_timer = 0
                        end
                    end

                    if Input.down("p".. self.index + 1 .."_confirm") then -- charge a big shot
                        self.hold_timer = self.hold_timer + DTMULT*self:getChargeSpeed()

                        if self.hold_timer >= 20 and not self.charge_sfx then -- start charging sfx
                            self.charge_sfx = Assets.getSound("chargeshot_charge")
                            self.charge_sfx:setLooping(true)
                            self.charge_sfx:setPitch(0.1)
                            self.charge_sfx:setVolume(0)
                            local timer = 0
                            Game.battle.timer:during(2/3, function()
                                timer = timer + DT
                                if self.charge_sfx then
                                    self.charge_sfx:setVolume(Utils.clampMap(timer, 0,2/3, 0,0.3))
                                end
                            end, function()
                                if self.charge_sfx then
                                    self.charge_sfx:setVolume(0.3)
                                end    
                            end)
                            self.charge_sfx:play()
                        end
                        if self.hold_timer >= 20 and self.hold_timer < 40 then
                            self.charge_sfx:setPitch(Utils.clampMap(self.hold_timer, 20,40, 0.1,1))
                        end
                    else
                        self.hold_timer = 0
                        if self.charge_sfx then
                            self.charge_sfx:stop()
                            self.charge_sfx = nil
                        end
                    end
                end
            end
        end)
        
        Utils.hook(YellowSoul, "fireShot", function(orig, self, big)
            if big then
                local shot = Game.battle:addChild(YellowSoulBigShot(self.x, self.y, self.rotation + math.pi/2))
                Assets.playSound("chargeshot_fire")
            else
                if #Game.stage:getObjects(YellowSoulShot) >= Lib.max_players * 3 then return end -- only allow 3 * players at once
                local shot = Game.battle:addChild(YellowSoulShot(self.x, self.y, self.rotation + math.pi/2))
                Assets.playSound("heartshot")
            end
        end)
    end
    
    Utils.hook(DarkConfigMenu, "update", function(orig, self)
        if self.state == "MAIN" and Input.pressed("confirm") and self.currently_selected == 2 then
            Input.gamepad_bindings = Lib.gamepad_bindings
            Lib.gamepad_bindings = {}
        end
        orig(self)
    end)
    
    Utils.hook(DarkConfigMenu, "onKeyPressed", function(orig, self, key)
        local clear_gamepad = false
        if self.state == "CONTROLS" and Input.pressed("confirm") and self.currently_selected == 9 then
            Lib.gamepad_bindings = Input.gamepad_bindings
            clear_gamepad = true
        end
        orig(self, key)
        if clear_gamepad then
            Input.gamepad_bindings = {}
        end
    end)
end

function Lib:sharedControl(menu_mode)
    local play_mode = not OVERLAY_OPEN and not Game.lock_movement and Game.state == "OVERWORLD" and Game.world.player and Game.world.player.world.state == "GAMEPLAY"
    if menu_mode then
        return Game.world.player and play_mode
    else
        return Game.world.player and not play_mode and Game.state ~= "BATTLE" or Game.state == "BATTLE" and Game.battle:getState() ~= "DEFENDING" and Game.battle:getState() ~= "ATTACKING" or not Game.world.player and Game.state ~= "BATTLE"
    end
end

function Lib:onKeyPressed(key, is_repeat)
    if not is_repeat then
        if Lib:sharedControl(false) then
            for i = 2, Lib.max_players do
                if Game.state ~= "BATTLE" or Game.battle and (Game.battle.current_selecting == i or Game.battle.current_selecting == 0) then
                    if Input.is("p".. i .."_left", key) then
                        Input.onKeyPressed(Input.getBoundKeys("left", false)[1])
                    end
                    if Input.is("p".. i .."_up", key) then
                        Input.onKeyPressed(Input.getBoundKeys("up", false)[1])
                    end
                    if Input.is("p".. i .."_down", key) then
                        Input.onKeyPressed(Input.getBoundKeys("down", false)[1])
                    end
                    if Input.is("p".. i .."_right", key) then
                        Input.onKeyPressed(Input.getBoundKeys("right", false)[1])
                    end
                    if Input.is("p".. i .."_confirm", key) then
                        Input.onKeyPressed(Input.getBoundKeys("confirm", false)[1])
                    end
                    if Input.is("p".. i .."_cancel", key) then
                        Input.onKeyPressed(Input.getBoundKeys("cancel", false)[1])
                    end
                    if Input.is("p".. i .."_menu", key) then
                        Input.onKeyPressed(Input.getBoundKeys("menu", false)[1])
                    end
                end
            end
        elseif Lib:sharedControl(true) then
            for i = 2, Lib.max_players do
                if Input.is("p".. i .."_menu", key) then
                    Input.onKeyPressed(Input.getBoundKeys("menu", false)[1])
                end
            end
        end
    end
end

function Lib:onKeyReleased(key)
    if Lib:sharedControl(false) then
        for i = 2, Lib.max_players do
            if Game.state ~= "BATTLE" or Game.battle and (Game.battle.current_selecting == i or Game.battle.current_selecting == 0) then
                if Input.is("p".. i .."_left", key) then
                    Input.onKeyReleased(Input.getBoundKeys("left", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_up", key) then
                    Input.onKeyReleased(Input.getBoundKeys("up", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_down", key) then
                    Input.onKeyReleased(Input.getBoundKeys("down", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_right", key) then
                    Input.onKeyReleased(Input.getBoundKeys("right", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_confirm", key) then
                    Input.onKeyReleased(Input.getBoundKeys("confirm", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_cancel", key) then
                    Input.onKeyReleased(Input.getBoundKeys("cancel", false)[1])
                    Lib.clearInput = true
                end
                if Input.is("p".. i .."_menu", key) then
                    Input.onKeyReleased(Input.getBoundKeys("menu", false)[1])
                    Lib.clearInput = true
                end
            end
        end
    elseif Lib:sharedControl(true) then
        for i = 2, Lib.max_players do
            if Input.is("p".. i .."_menu", key) then
                Input.onKeyReleased(Input.getBoundKeys("menu", false)[1])
            end
        end
    end
end

function Lib:gamepad_to_game_control(pressed, button, joystick)
    -- Unique key based on joystick and button
    local key_prefix = "joy#" .. joystick .. "_"

    -- Add joystick to gamepad_order if it's new
    if pressed and not Utils.containsValue(self.gamepad_order, joystick) then
        table.insert(self.gamepad_order, joystick)
    end

    local i = Utils.getIndex(self.gamepad_order, joystick)
    if i then
        local key = key_prefix .. button  -- Unique key for this joystick and button
        if pressed and not (i == 1 and Game.battle and Game.battle.current_selecting > 1 and Game.battle.current_selecting <= self.max_players) then
            if i == 1 and not self.gamepad_pressed[key] and Input.getBoundKeys(button, false) and #Input.getBoundKeys(button, false) > 0 then
                Input.onKeyPressed(Input.getBoundKeys(button, false)[1])
                self.gamepad_pressed[key] = true
            end
            if i > 1 and not self.gamepad_pressed[key] and Input.getBoundKeys("p" .. i .. "_" .. button, false) and #Input.getBoundKeys("p" .. i .. "_" .. button, false) > 0 then
                Input.onKeyPressed(Input.getBoundKeys("p" .. i .. "_" .. button, false)[1])
                self.gamepad_pressed[key] = true
            end
        else
            if i == 1 and self.gamepad_pressed[key] and Input.getBoundKeys(button, false) and #Input.getBoundKeys(button, false) > 0 then
                Input.onKeyReleased(Input.getBoundKeys(button, false)[1])
                self.gamepad_pressed[key] = false
            end
            if i > 1 and self.gamepad_pressed[key] and Input.getBoundKeys("p" .. i .. "_" .. button, false) and #Input.getBoundKeys("p" .. i .. "_" .. button, false) > 0 then
                Input.onKeyReleased(Input.getBoundKeys("p" .. i .. "_" .. button, false)[1])
                self.gamepad_pressed[key] = false
            end
        end
    end
end

function Lib:preUpdate()
    local joysticks = love.joystick.getJoysticks()
    local stick_threshold = 0.5
    local trigger_threshold = 0.9

    for _,joystick in ipairs(joysticks) do
        for btn,input in pairs(self.gamepad_bindings) do
            local pressed = false
            for j,gamepadkey in ipairs(input) do
                local key = select(2, Utils.startsWith(gamepadkey, "gamepad:"))
                if key then
                    if string.sub(key, 1, 2) == "ls" or string.sub(key, 1, 2) == "rs" or string.sub(key, -7) == "trigger" then
                        local side = "left"
                        local stick = "ls"
                        if string.sub(key, 1, 2) == "rs" then
                            side = "right"
                            stick = "rs"
                        elseif string.sub(key, -7) == "trigger" then
                            side = string.sub(key, 1, -8)
                            stick = nil
                        end
                            
                        if stick and (key == stick.."left" and joystick:getGamepadAxis(side.."x") < -stick_threshold or 
                        key == stick.."right" and joystick:getGamepadAxis(side.."x") > stick_threshold or
                        key == stick.."up" and joystick:getGamepadAxis(side.."y") < -stick_threshold or
                        key == stick.."down" and joystick:getGamepadAxis(side.."y") > stick_threshold) or
                        not stick and key == side.."trigger" and joystick:getGamepadAxis("trigger"..side) > trigger_threshold then
                            pressed = true
                        end
                    else
                        if joystick:isGamepadDown(key) then
                            pressed = true
                        end
                    end
                end
            end
            self:gamepad_to_game_control(pressed, btn, joystick:getID())
        end
    end

    if Lib.clearInput and not Lib:sharedControl(false) then
        Input.onKeyReleased(Input.getBoundKeys("left", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("up", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("down", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("right", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("confirm", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("cancel", false)[1])
        Input.onKeyReleased(Input.getBoundKeys("menu", false)[1])
        Lib.clearInput = false
    end
end

return Lib