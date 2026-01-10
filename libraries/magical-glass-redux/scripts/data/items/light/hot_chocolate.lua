local item, super = Class("light/hot_chocolate", true)

function item:init()
    super.init(self)

    self.short_name = "HotChoc"

    self.price = 18
    if Kristal.getLibConfig("magical-glass", "balanced_undertale_items_price") then
        self.sell_price = 6
    end
end

function item:getLightBattleText(user, target)
    return "* You drank the hot chocolate."
end

function item:onLightBattleUse(user, target)
    Assets.playSound("swallow")
    Game.battle:battleText(self:getLightBattleText(user, target))
end

function item:onBattleUse(user, target)
    Assets.playSound("swallow")
end

return item