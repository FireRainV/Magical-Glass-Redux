local character, super = Class("kris", true)

function character:init()
    super.init(self)
    
    -- In which direction will this character's soul face (optional, defaults to facing up)
    self.soul_facing = "up"
end

return character