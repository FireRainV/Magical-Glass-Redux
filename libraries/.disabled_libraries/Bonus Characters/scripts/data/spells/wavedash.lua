local spell, super = Class(Spell, "wavedash")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "WaveDash"
    -- Name displayed when cast (optional)
    self.cast_name = "WAVE DASH"

    -- Battle description
    self.effect = "Gamer\nDamage"
    -- Menu description
    self.description = "Wave-Dashes and deals moderate damage to one\nfoe. Depends on Attack & Magic."
    self.check = {"Wave-Dashes and deals moderate damage to\none foe.", "* Depends on Attack & Magic."}

    -- TP cost
    self.cost = 24

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemy"

    -- Tags that apply to this spell
    self.tags = {"damage"}
end

function spell:getCastMessage(user, target)
    return "* "..user.chara:getName().." used "..self:getCastName().."!"
end

function spell:onCast(user, target)
    local buster_finished = false
    local anim_finished = false
    local function finishAnim()
        anim_finished = true
        if buster_finished then
            Game.battle:finishAction()
        end
    end
    if not user:setAnimation("battle/rude_buster", finishAnim) then
        anim_finished = false
        user:setAnimation("battle/attack", finishAnim)
    end
    Game.battle.timer:after(0.5, function()
        Assets.playSound("halberd_flash")
    end)
    Game.battle.timer:after(1, function()
        Assets.playSound("rudebuster_swing")
        local x, y = user:getRelativePos(user.width, user.height/2 - 10, Game.battle)
        local tx, ty = target:getRelativePos(target.width/2, target.height/2, Game.battle)
        local blast = WavedashBeam(false, x, y, tx, ty, function(pressed)
            local damage = self:getDamage(user, target)
            if pressed then
                damage = damage + 30
                Assets.playSound("scytheburst")
            end
            target:flash()
            target:hurt(damage, user)
            buster_finished = true
            if anim_finished then
                Game.battle:finishAction()
            end
        end)
        blast.layer = BATTLE_LAYERS["above_ui"]
        Game.battle:addChild(blast)
    end)
    return false
end

function spell:onLightCast(user, target)
    user.delay_turn_end = true
    local buster_finished = false
    local anim_finished = false
    local function finishAnim()
        anim_finished = true
        if buster_finished then
            Game.battle:finishAction()
        end
    end
    Game.battle.timer:after(0.5, function()
        Assets.playSound("halberd_flash")
    end)
    Game.battle.timer:after(1, function()
        Assets.playSound("rudebuster_swing")
        local x, y = (SCREEN_WIDTH/2), SCREEN_HEIGHT
        local tx, ty = target:getRelativePos(target.width/2, target.height/2, Game.battle)
        local blast = WavedashBeam(false, x, y, tx, ty, function(pressed)
            local damage = self:getDamage(user, target)
            if pressed then
                damage = damage + 30
                Assets.playSound("scytheburst")
            end
            target:flash()
            target:hurt(damage, user)
            buster_finished = true
            Game.battle:finishAction()
        end)
        blast.layer = LIGHT_BATTLE_LAYERS["above_arena_border"]
        Game.battle:addChild(blast)
    end)
    return false
end

function spell:getDamage(user, target)
    if Game:isLight() then
        return math.ceil((user.chara:getStat("magic") * 3) + (user.chara:getStat("attack") * 5) - (target.defense * 1))
    else
        return math.ceil((user.chara:getStat("magic") * 4) + (user.chara:getStat("attack") * 9) - (target.defense * 2))
    end
end

return spell