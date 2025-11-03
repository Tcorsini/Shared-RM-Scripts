#==============================================================================
# Neo Save System for VX ace v2
# Recreates the Neo Save System on VX ace using Yanfly Save Manager and Zeus Bitmap Export
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 11/09/2025
# Requires: 
# -Ace Save Engine 1.03 by Yanfly 
# -Bitmap Export v5.4 by Zeus81
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-NeoSave"] = true

if $imported["TIM-NeoSave"]
  
raise "Neo save requires Ace Save Engine by Yanfly!" unless $imported["YEA-SaveEngine"]
raise "Neo save requires Zeus Bitmap Export!" unless $imported[:Zeus_Bitmap_Export]
#==============================================================================
# Version History
#------------------------------------------------------------------------------
# 24/02/2025: Original release
# 30/04/2025: v1.1 to access the take picture method from other scripts
# 09/05/2025: v1.2 to have a black border around the screenshot
# 11/09/2025: v2   removes the picture file and saves it directly into the 
#                  savefile header instead (makes savefiles heavier)
#==============================================================================
# Description
#------------------------------------------------------------------------------
# This script will display a screenshot of the map the characters are in 
# the save/load menu.
#
# The display will look like this:
# ------------------------------------------------
# Gold                                    Playtime
#                       
#                     Picture
#
#
# Location name
# Party members
# Variables -> hidden deppending on the size of the picture
#==============================================================================
# Installation: put it after the required scripts and before main, configure
# module NeoSave if you want to change the size of the picture.
# Compatibility: with almost anything except scripts modifying file save display
#==============================================================================
# Terms of use: free for commercial and non-commercial project, 
# credit is not mandatory but nice if you do
#==============================================================================

#==============================================================================
# NeoSave -> you can change the constants here to modify the height of the 
# picture, the size of the border around it or its color
#==============================================================================
module NeoSave
  SCREENSHOT_HEIGHT = 140#200
  MAP_BORDER_COLOR = Color.new(0,0,0,200)
  MAP_BORDER_SIZE = 2 #in pixels
end #NeoSave

#==============================================================================
# Editing anything past this point is at your own risk
#==============================================================================

#==============================================================================
# DataManager -> saves the screenshot into the savefile
#==============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: self.make_save_header
  #--------------------------------------------------------------------------
  class <<self; alias neo_make_save_header make_save_header; end
  def self.make_save_header
    header = neo_make_save_header
    header[:neo_save_screenshot] = Scene_Map.temp_bit_map#Marshal.load(Marshal.dump(Scene_Map.temp_bit_map))
    header
  end
end # DataManager

#==============================================================================
# Window_FileStatus
#==============================================================================
class Window_FileStatus < Window_Base
  #--------------------------------------------------------------------------
  # overwrite method: draw_save_contents
  #--------------------------------------------------------------------------
  def draw_save_contents
    #draw_save_slot(4, 0, contents.width/2-8)
    draw_save_playtime(contents.width/2+4, 0, contents.width/2-8)
    #draw_save_total_saves(4, line_height, contents.width/2-8)
    draw_save_gold(4, 0, contents.width/2-8)
    draw_map_picture(4,line_height, contents.width-8)
    dy = NeoSave::SCREENSHOT_HEIGHT + line_height
    draw_save_location(4, dy, contents.width-8) #line_height*2
    draw_save_characters(0, dy+line_height*3 + line_height/3)
    draw_save_column1(16, dy+line_height*5, contents.width/2-48)
    draw_save_column2(contents.width/2+16, dy+line_height*5, contents.width/2-48)
  end
  
  #--------------------------------------------------------------------------
  # new method: draw_map_picture
  #--------------------------------------------------------------------------
  def draw_map_picture(dx, dy, dw)
    bitmap = get_screenshot_bitmap
    return unless bitmap
    shift_x = (bitmap.width - dw)/2
    shift_y = (bitmap.height - NeoSave::SCREENSHOT_HEIGHT)/2
    
    inside_rect = Rect.new(dx,dy,dw,NeoSave::SCREENSHOT_HEIGHT)
    contents.fill_rect(inside_rect, NeoSave::MAP_BORDER_COLOR)
    
    d = NeoSave::MAP_BORDER_SIZE
    rect = Rect.new(shift_x,shift_y,dw-2*d,NeoSave::SCREENSHOT_HEIGHT-2*d)
    contents.blt(dx+d, dy+d, bitmap, rect, 255)
    bitmap.dispose
  end
  
  #--------------------------------------------------------------------------
  # new method: get_screenshot_bitmap
  #--------------------------------------------------------------------------
  def get_screenshot_bitmap
    @header[:neo_save_screenshot]
  end
end #Window_FileStatus

#==============================================================================
# Scene_Map
#==============================================================================
class Scene_Map < Scene_Base
  @@tmp_bitmap = nil
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias neo_save_map_start start
  def start
    if @@tmp_bitmap
      @@tmp_bitmap.dispose
      @@tmp_bitmap = nil
    end
    neo_save_map_start
  end
  
  #--------------------------------------------------------------------------
  # alias method: terminate
  #--------------------------------------------------------------------------
  alias neo_save_map_terminate terminate
  def terminate
    Scene_Map.take_picture
    neo_save_map_terminate
  end
  
  #--------------------------------------------------------------------------
  # new class method: temp_bit_map
  #--------------------------------------------------------------------------
  def self.temp_bit_map
    return @@tmp_bitmap
  end
  
  #--------------------------------------------------------------------------
  # new class method: take_picture
  #--------------------------------------------------------------------------
  def self.take_picture
    @@tmp_bitmap.dispose unless @@tmp_bitmap.nil?
    @@tmp_bitmap = Graphics.snap_to_bitmap
  end
end #Scene_Map

end