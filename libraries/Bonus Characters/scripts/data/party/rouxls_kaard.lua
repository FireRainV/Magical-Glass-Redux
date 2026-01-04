local character, super = Class(PartyMember, "rouxls_kaard")

function character:init()
    super.init(self)

    -- Display name
    self.name = "Rouxls K."
    self.short_name = "Rouxls"

    -- Actor (handles overworld/battle sprites)
    self:setActor("rouxls_kaard")

    -- Display level (saved to the save file)
    self.level = 1
    -- Default title / class (saved to the save file)
    self.title = "Duke of Puzzles\nCreates strong\npuzzles for Worms."

    -- Determines which character the soul comes from (higher number = higher priority)
    self.soul_priority = -1
    -- The color of this character's soul (optional, defaults to red)
    self.soul_color = {1, 1, 1}
    -- In which direction will this character's soul face (optional, defaults to facing up)
    self.soul_facing = "down"

    -- Whether the party member can act / use spells
    self.has_act = false
    self.has_spells = true

    -- Whether the party member can use their X-Action
    self.has_xact = true
    -- X-Action name (displayed in this character's spell menu)
    self.xact_name = "R-Action"
    
    -- Spells
    self:addSpell("heal_prayer")

    -- Current health (saved to the save file)
    self.health = 120

    -- Base stats (saved to the save file)
    self.stats = {
        health = 120,
        attack = 8,
        defense = 2,
        magic = 1
    }
    
    -- Max stats from level-ups
    self.max_stats = {
        health = 160
    }

    -- Weapon icon in equip menu
    self.weapon_icon = "ui/menu/equip/box"

    -- Equipment (saved to the save file)
    self:setWeapon("box")
    self:setArmor(1, "amber_card")
    self:setArmor(2, "amber_card")

    -- Default light world equipment item IDs (saves current equipment)
    self.lw_weapon_default = "light/pencil"
    self.lw_armor_default = "light/bandage"

    -- Character color (for action box outline and hp bar)
    self.color = {0, 85/255, 255/255}
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    self.dmg_color = nil
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    self.attack_bar_color = nil
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    self.attack_box_color = {15/255, 0, 98/255}
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    self.xact_color = nil

    -- Head icon in the equip / power menu
    self.menu_icon = "party/rouxls_kaard/head"
    -- Path to head icons used in battle
    self.head_icons = "party/rouxls_kaard/icon"
    -- Name sprite
    self.name_sprite = "party/rouxls_kaard/name"

    -- Effect shown above enemy after attacking it
    self.attack_sprite = "effects/attack/slap_r"
    -- Sound played when this character attacks
    self.attack_sound = "laz_c"
    -- Pitch of the attack sound
    self.attack_pitch = 1

    -- Battle position offset (optional)
    self.battle_offset = {-9, 0}
    -- Head icon position offset (optional)
    self.head_icon_offset = {0, -2}
    -- Menu icon position offset (optional)
    self.menu_icon_offset = nil

    -- Message shown on gameover (optional)
    self.gameover_message = nil
end

function character:lightLVStats()
    return {
        health = self:getLightLV() == 20 and 99 or 16 + self:getLightLV() * 4,
        attack = 9 + self:getLightLV() + math.floor(self:getLightLV() / 3),
        defense = 9 + math.ceil(self:getLightLV() / 4),
        magic = self:getLightLV()
    }
end

function character:onLevelUp(level)
    self:increaseStat("health", 2)
    if level % 10 == 0 then
        self:increaseStat("attack", 1)
        self:increaseStat("magic", 1)
    end
end

function character:drawPowerStat(index, x, y, menu)
    if index == 3 then
        local icon = Assets.getTexture("ui/menu/icon/fire")
        Draw.draw(icon, x-26, y+6, 0, 2, 2)
        love.graphics.print("Guts:", x, y)
        return true
    end
end

return character
