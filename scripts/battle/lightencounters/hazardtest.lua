local encounter, super = Class(LightEncounter)

function encounter:init()
    super.init(self)

    self.music = false
    
    self.event = true
    self.event_waves = {"basic"}
    
    self.background = false
    
    self.fast_transition = true
end

return encounter