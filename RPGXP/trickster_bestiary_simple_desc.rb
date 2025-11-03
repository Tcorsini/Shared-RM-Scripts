#==============================================================================
# Trickster's Bestiary 1.1 addon - simple description
#------------------------------------------------------------------------------
# Authors: Timtrack, Trihan
# date: 16/10/2025
# Requires: Trickster's Bestiary 1.1 for RPG Maker XP
#==============================================================================
# Description: removes all battle data from the monster to keep only its name,
# its picture and its description
# Added Trihan's contirbutions to remove 'Description' from the text as well as
# the ids of the monsters from the list.
# Rewrites the draw_wrap_text method from Bitmap to deal with text alignment
#==============================================================================
# Installation: put it below the required script
#==============================================================================
# Term of use: credit is not mandatory
#==============================================================================

module SimpleBestiaryDescription
  ALIGNMENT = 1 #0 for text to the left, 1 for middle, 2 for right
end

#==============================================================================
# Bitmap
#==============================================================================
class Bitmap
  #--------------------------------------------------------------------------
  # overload method: draw_wrap_text -> rewrites the method from Method & Class
  # Library to follow version 2.3 and add text alignment
  #--------------------------------------------------------------------------
  def draw_wrap_text(x, y, width, height, text, align = 0)
   # Get Array of Text
   strings = text.split
   #define a line to draw
   line = ''
   _x = 0 #define a starting relative x
   # Run Through Array of Strings
   strings.each do |string|
     # Get Word
     word = string + ' '
     # Get Word Width
     word_width = text_size(word).width
     _x += word_width
     # If Can't Fit on Line move to next one
     if _x > width
       draw_text(x, y, width, height, line, align)
       _x = word_width
       y += height
       line = word
     else
       line += word
     end
   end
   draw_text(x, y, width, height, line, align) unless line.empty?
 end
end #Bitmap

#==============================================================================
# Window_Bestiary
#==============================================================================
class Window_Bestiary < Window_Base
  #--------------------------------------------------------------------------
  # overwrite method: refresh
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    return if @battler == nil || $game_system.seen[@battler.id] == 0
    # Setup Local Variable battler
    battler = @battler
    # Draw Name
    draw_actor_name(battler, 0, 0)
    # Draw Enemy
    draw_enemy(battler, 0, 32, 176, 176)
    # Draw Description
    draw_battler_description(battler, 0, 192) #352
  end
  #--------------------------------------------------------------------------
  # overwrite method: draw_battler_description
  #--------------------------------------------------------------------------
  def draw_battler_description(battler, x, y)
    string = Bestiary::Description[battler.id]
    self.contents.draw_wrap_text(x, y, contents.width, 32, string, SimpleBestiaryDescription::ALIGNMENT)
  end
end #Window_Bestiary

#==============================================================================
# Window_BestiaryCommand
#==============================================================================
class Window_BestiaryCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # overwrite method: draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    enemy_id = $game_system.enemies[index]
    x, y = 4, index * 32
    enemy = $data_enemies[enemy_id]
    name = $game_system.seen[enemy_id] > 0 ? enemy.name : Bestiary::Not_Seen
    self.contents.draw_text(x, y, contents.width, 32, name)
  end
end #Window_BestiaryCommand