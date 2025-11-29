local Dummy, super = Class(LightEncounter)

function Dummy:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = "* You encountered the Dummy...?"

    -- Battle music ("battleut" is undertale)
    -- self.music = nil
    self.music = Game:isLight() and "prebattle_ut" or "prebattle_dt"

    -- Add the dummy enemy to the encounter
    self:addEnemy("dummy")
    
    self.wave_mode = false
    self.bg_siners = {0, 15, 30, 45, 60, 75}
end

function Dummy:update()
    super.update(self)

    for i = 1, #self.bg_siners do
        self.bg_siners[i] = self.bg_siners[i] + DTMULT
    end
end

function Dummy:drawBackground()
    if self.wave_mode then
        local offset = 0
        for i = 1, 6 do
            local sine = (math.sin(self.bg_siners[i] / 14) * 8) + 12
            Draw.setColor(0, 107/255, 183/255)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", 18 + offset, sine, 101, 118)
            love.graphics.rectangle("line", 18 + offset, sine + 118, 101, 118)
            offset = offset + 101
        end
    else
        super.drawBackground(self)
    end
end

-- function Dummy:setBattleState()
    -- super.setBattleState(self)
    -- Game:getActiveMusic():stop()
-- end

return Dummy