local item, super = Class("light/wristwatch", true)

function item:init()
    super.init(self)

    -- Display name
    self.short_name = "Watch"

    self.price = 100
    if Kristal.getLibConfig("magical-glass", "balanced_undertale_items_price") then
        self.sell_price = 14
    end
end

return item