local character, super = Class("susie", true)

function character:init()
    super.init(self)
    
    -- The color of this character's soul (optional, defaults to red)
    self.soul_color = {1, 1, 1}
    -- In which direction will this character's soul face (optional, defaults to facing up)
    self.soul_facing = "down"
end

return character