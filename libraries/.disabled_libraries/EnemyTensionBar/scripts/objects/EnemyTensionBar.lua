local EnemyTensionBar, super = Class(Object)

function EnemyTensionBar:init(x, y, dont_animate)
    if Game.world and (not x) then
        local x2 = Game.world.camera:getRect()
        x = x2 - 25
    end

    super.init(self, x or SCREEN_WIDTH+32, y or 40)

    self.layer = BATTLE_LAYERS["ui"] - 1

    self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill")
    self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline")

    self.width = self.tp_bar_outline:getWidth()
    self.height = self.tp_bar_outline:getHeight()

    self.nTension = 0
    self.nMaxtension = 100

    self.nApparent = 0
    self.nCurrent = 0

    self.change = 0
    self.changetimer = 15
    self.font = Assets.getFont("main")
    self.tp_text = Assets.getTexture("ui/battle/tp_text")

    self.parallax_y = 0

    -- still dont understand nil logic
    if dont_animate then
        self.animating_in = false
    else
        self.animating_in = true
    end

    self.animation_timer = 0

    self.tsiner = 0

    self.tension_preview = 0
    self.shown = false
    
    self.timer = self:addChild(Timer())
    
    self.tension_bar_color_bg = Game.battle.encounter.enemy_tension_bar_color_bg
    self.tension_bar_color_fill = Game.battle.encounter.enemy_tension_bar_color_fill
    self.tension_bar_color_decrease = Game.battle.encounter.enemy_tension_bar_color_decrease
    self.tension_bar_color_max = Game.battle.encounter.enemy_tension_bar_color_max 
    self.tension_bar_MAX_color = Game.battle.encounter.enemy_tension_bar_MAX_color 
end

function EnemyTensionBar:show()
    if not self.shown then
        self:resetPhysics()
        self.x = self.init_x
        self.shown = true

        self.physics.speed_x = -13
        self.physics.friction = 1.2
    end
end

function EnemyTensionBar:hide()
    if self.shown then
        self.animating_in = false
        self.shown = false
        self.physics.speed_x = 10
        self.physics.friction = -0.4
    end
end

function EnemyTensionBar:flash()
    -- Spawn the flash if needed
    if self.current_flash == nil or self.current_flash:isRemoved() then
        self.current_flash = self:addChild(TensionBarGlow()) --[[@as TensionBarGlow]]
    else
        -- Still exists, reuse it
        self.current_flash.current_alpha = 1
    end

    -- Spawn 3-5 sparkles
    for _ = 1, love.math.random(3, 5) do
        local x = self.x + love.math.random(0, 25)
        local y = self.y + 40 + love.math.random(0, 160)
        local sparkle = self.parent:addChild(Sprite("effects/spare/star", x, y))
        sparkle.layer = 999
        sparkle.alpha = 1

        local duration = 10 + love.math.random(0, 5)

        sparkle:play(1 / (30 * (5 / duration)), true)
        sparkle.physics.speed = 3 + love.math.random() * 3
        sparkle.physics.direction = -math.rad(90)
        sparkle:fadeTo(0.25, duration / 30)
        self.timer:tween(duration / 30, sparkle.physics, { speed = 0 }, "linear")

        self.timer:after(duration / 30, function()
            sparkle:remove()
        end)
    end
end

function EnemyTensionBar:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Tension: "  .. Utils.round(self:getPercentageFor(self.nTension) * 100) .. "%")
    table.insert(info, "Apparent: " .. Utils.round(self.nApparent / 2.5))
    table.insert(info, "Current: "  .. Utils.round(self.nCurrent / 2.5))
    return info
end

function EnemyTensionBar:setTension(amount, dont_clamp)
    self.nTension = dont_clamp and amount or Utils.clamp(amount, 0, self.nMaxtension)
end

function EnemyTensionBar:giveTension(amount, dont_clamp)
    self.nTension = self.nTension+(dont_clamp and amount or Utils.clamp(amount, 0, self.nMaxtension))
end

function EnemyTensionBar:removeTension(amount)
    self.nTension = self.nTension-amount
    if self.nTension<0 then
        self.nTension=0
    end
end

function EnemyTensionBar:getTension()
    return self.nTension or 0
end

function EnemyTensionBar:getTension250()
    return self:getPercentageFor(self:getTension()) * 250
end

function EnemyTensionBar:setTensionPreview(amount)
    self.tension_preview = amount
end

function EnemyTensionBar:getPercentageFor(variable)
    return variable / self.nMaxtension
end

function EnemyTensionBar:getPercentageFor250(variable)
    return variable / 250
end

function EnemyTensionBar:update()
    self.visible = self.x - 30 <= SCREEN_WIDTH
    if (math.abs((self.nApparent - self:getTension250())) < 20) then
        self.nApparent = self:getTension250()
    elseif (self.nApparent < self:getTension250()) then
        self.nApparent = self.nApparent + (20 * DTMULT)
    elseif (self.nApparent > self:getTension250()) then
        self.nApparent = self.nApparent - (20 * DTMULT)
    end
    if (self.nApparent ~= self.nCurrent) then
        self.changetimer = self.changetimer + (1 * DTMULT)
        if (self.changetimer > 15) then
            if ((self.nApparent - self.nCurrent) > 0) then
                self.nCurrent = self.nCurrent + (2 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) > 10) then
                self.nCurrent = self.nCurrent + (2 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) > 25) then
                self.nCurrent = self.nCurrent + (3 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) > 50) then
                self.nCurrent = self.nCurrent + (4 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) > 100) then
                self.nCurrent = self.nCurrent + (5 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) < 0) then
                self.nCurrent = self.nCurrent - (2 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) < -10) then
                self.nCurrent = self.nCurrent - (2 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) < -25) then
                self.nCurrent = self.nCurrent - (3 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) < -50) then
                self.nCurrent = self.nCurrent - (4 * DTMULT)
            end
            if ((self.nApparent - self.nCurrent) < -100) then
                self.nCurrent = self.nCurrent - (5 * DTMULT)
            end
            if (math.abs((self.nApparent - self.nCurrent)) < 3) then
                self.nCurrent = self.nApparent
            end
        end
    end

    if (self.tension_preview > 0) then
        self.tsiner = self.tsiner + DTMULT
    end

    super.update(self)
end

function EnemyTensionBar:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_bar_outline, 0, 0)

    love.graphics.setColor(self.tension_bar_color_bg)
    Draw.pushScissor()
    Draw.scissorPoints(0, 0, 25, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 1)
    love.graphics.draw(self.tp_bar_fill, 0, 0)
    Draw.popScissor()

    if (self.nApparent < self.nCurrent) then
        love.graphics.setColor(self.tension_bar_color_decrease)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(self.tension_bar_color_fill)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nApparent) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.nApparent > self.nCurrent) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nApparent) * 196) + 1, 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(self.tension_bar_color_fill)
        if (self.maxed) then
            love.graphics.setColor(self.tension_bar_color_max)
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.nApparent == self.nCurrent) then
        love.graphics.setColor(self.tension_bar_color_fill)
        if (self.maxed) then
            love.graphics.setColor(self.tension_bar_color_max)
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 1 + (self:getPercentageFor(self.tension_preview) * 196), 25, 196)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    if (self.tension_preview > 0) then
        local alpha = (math.abs((math.sin((self.tsiner / 8)) * 0.5)) + 0.2)
        local color_to_set = {1, 1, 1, alpha}

        local theight = 196 - (self:getPercentageFor250(self.nCurrent) * 196)
        local theight2 = theight + (self:getPercentageFor(self.tension_preview) * 196)
        -- Note: causes a visual bug.
        if (theight2 > ((0 + 196) - 1)) then
            theight2 = ((0 + 196) - 1)
            color_to_set = {COLORS.dkgray[1], COLORS.dkgray[2], COLORS.dkgray[3], 0.7}
        end

        Draw.pushScissor()
        Draw.scissorPoints(0, theight2 + 1, 25, theight + 1)

        -- No idea how Deltarune draws this, cause this code was added in Kristal:
        local r,g,b,_ = love.graphics.getColor()
        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        -- And back to the translated code:
        love.graphics.setColor(color_to_set)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        love.graphics.setColor(1, 1, 1, 1)
    end


    if ((self.nApparent > 20) and (self.nApparent < 250)) then
        love.graphics.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 1, 25, 196 - (self:getPercentageFor250(self.nCurrent) * 196) + 3)
        love.graphics.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.tp_text, -30, 30)

    local tamt = math.floor(self:getPercentageFor250(self.nApparent) * 100)
    self.maxed = false
    love.graphics.setFont(self.font)
    if (tamt < 100) then
        love.graphics.print(tostring(math.floor(self:getPercentageFor250(self.nApparent) * 100)), -30, 70)
        love.graphics.print("%", -25, 95)
    end
    if (tamt >= 100) then
        self.maxed = true

        love.graphics.setColor(self.tension_bar_MAX_color)

        love.graphics.print("M", -28, 70)
        love.graphics.print("A", -24, 90)
        love.graphics.print("X", -20, 110)
    end

    super.draw(self)
end

return EnemyTensionBar