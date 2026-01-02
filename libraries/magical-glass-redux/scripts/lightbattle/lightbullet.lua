local LightBullet, super = Class(Bullet)

function LightBullet:init(x, y, texture)
    super.init(self, x, y, texture)
    
    self.destroy_on_hit = "alt"
    self.layer = LIGHT_BATTLE_LAYERS["bullets"]
    self.remove_outside_of_arena = false
    self.can_collide_while_not_defending = false
end

function LightBullet:update()
    super.update(self)
    
    local x, y = self:getScreenPos()
    if self.remove_outside_of_arena and
        (x < Game.battle.arena.left or
        x > Game.battle.arena.right or
        y > Game.battle.arena.bottom or
        y < Game.battle.arena.top)
        then
        self:remove()
    end
end

function LightBullet:onCollide(soul)
    if Game.battle:getState() == "DEFENDING" or self.can_collide_while_not_defending then
        if soul.inv_timer == 0 then
            self:onDamage(soul)
            if self.destroy_on_hit then
                self:remove()
            end
        elseif self.destroy_on_hit == true then
            self:remove()
        end
    end
end

return LightBullet