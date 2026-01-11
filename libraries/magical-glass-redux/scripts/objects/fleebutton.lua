local FleeButton, super = Class(ActionButton)

function FleeButton:init()
    super.init(self, "flee")
end

function FleeButton:update()
    super.update(self)
    
    self.disabled = not Game.battle.encounter:canFlee()
end

return FleeButton