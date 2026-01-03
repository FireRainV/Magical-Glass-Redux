local lib = {}

function lib:init()
    if Mod.libs["multiplayer"] then
        return -- disable the library
    end
    
    Utils.hook(Encounter, "getSoulFacing", function(orig, self) end)
    
    Utils.hook(Soul, "setFacing", function(orig, self, face)
        if self.sprite then
            if face and not Assets.data.texture["player/heart_dodge"] and Assets.getTexture("player/"..face.."/heart_dodge") then
                self.sprite:setSprite("player/"..face.."/heart_dodge")
            else
                self.sprite:setSprite("player/heart_dodge")
            end
        end
        if self.graze_sprite then
            if face and not Assets.data.texture["player/graze"] and Assets.getTexture("player/"..face.."/graze") then
                self.graze_sprite.texture = Assets.getTexture("player/"..face.."/graze")
            else
                self.graze_sprite.texture = Assets.getTexture("player/graze")
            end
        end
    end)
    
    Utils.hook(PartyMember, "init", function(orig, self)
        orig(self)
        
        -- In which direction will this character's soul face (optional, defaults to facing up)
        self.soul_facing = "up"
    end)
    
    Utils.hook(PartyMember, "getSoulFacing", function(orig, self) return self.soul_facing end)
    
    Utils.hook(Game, "getSoulFacing", function(orig, self)
        if Game.state == "BATTLE" and Game.battle and Game.battle.encounter and Game.battle.encounter.getSoulFacing and Game.battle.encounter:getSoulFacing() then
            return Game.battle.encounter:getSoulFacing()
        end

        local chara = Game:getSoulPartyMember()

        if chara and chara:getSoulPriority() >= 0 and chara:getSoulFacing() then
            return chara:getSoulFacing()
        end

        return "up"
    end)
    
    Utils.hook(Assets, "getTexture", function(orig, path)
        return Assets.data.texture[lib:check_overwrite(path)] or orig(path)
    end)
    
    Utils.hook(Assets, "getTextureData", function(orig, path)
        return Assets.data.texture_data[lib:check_overwrite(path)] or orig(path)
    end)
    
    Utils.hook(Assets, "getFrames", function(orig, path)
        return Assets.data.frames[lib:check_overwrite(path)] or orig(path)
    end)
    
    Utils.hook(Assets, "getFrameIds", function(orig, path)
        return Assets.data.frame_ids[lib:check_overwrite(path)] or orig(path)
    end)
end

function lib:check_overwrite(path)
    if string.sub(path, 1, 7) == "player/" and select(2, string.gsub(path, "/", "/")) == 1 then
        path = string.sub(path, 1, 7)..Game:getSoulFacing().."/"..string.sub(path, 8)
    end
    return path
end

return lib