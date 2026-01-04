local actor, super = Class(Actor, "rouxls_kaard")

function actor:init()
    -- Display name (optional)
    self.name = "Rouxls K."

    -- Width and height for this actor, used to determine its center
    self.width = 47
    self.height = 57

    -- Hitbox for this actor in the overworld (optional, uses width and height by default)
    self.hitbox = {13, 41, 21, 15}
    
    -- A table that defines where the Soul should be placed on this actor if they are a player.
    -- First value is x, second value is y.
    self.soul_offset = {23.5, 26}

    -- Color for this actor used in outline areas (optional, defaults to red)
    self.color = {0, 0, 1}

    -- Whether this actor flips horizontally (optional, values are "right" or "left", indicating the flip direction)
    -- APPARENTLY this is optional, but I get a crash if it's not set. sooooooo...
    self.flip = "left"

    -- Path to this actor's sprites (defaults to "")
    self.path = "party/rouxls_kaard/dark"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    self.default = "walk"

    -- Sound to play when this actor speaks (optional)
    self.voice = nil
    -- Path to this actor's portrait for dialogue (optional)
    self.portrait_path = nil
    -- Offset position for this actor's portrait (optional)
    self.portrait_offset = nil

    -- Whether this actor as a follower will blush when close to the player
    self.can_blush = false

    -- Table of talk sprites and their talk speeds (default 0.25)
    self.talk_sprites = {}

    -- Table of sprite animations
    self.animations = {
    }

    -- Table of sprite offsets (indexed by sprite name)
    self.offsets = {
    }
end

-- Function overrides go here

return actor