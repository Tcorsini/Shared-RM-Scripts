#==============================================================================
# Selection color
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 12/06/2025
# Requires: replaces the default text color with TEXT_SELECTED_COLOR_ID when an
# item is selected in the window
#==============================================================================

#==============================================================================
# SELECT_REDRAW
#==============================================================================
module SELECT_REDRAW
  # put the color number from your windowskin that will replace the
  # normal color (white) when the item is selected
  TEXT_SELECTED_COLOR_ID = 14
end #SELECT_REDRAW

#==============================================================================
# Window_Base
#==============================================================================
class Window_Base < Window
  #--------------------------------------------------------------------------
  # new method: selected_color
  #--------------------------------------------------------------------------
  def selected_color; text_color(SELECT_REDRAW::TEXT_SELECTED_COLOR_ID); end
  #--------------------------------------------------------------------------
  # alias method: change_color -> if normal color is chosen, pick selected color
  # instead when @_selected is true
  #--------------------------------------------------------------------------
  alias redraw_change_color change_color
  def change_color(color, enabled = true)
    color = selected_color if @_selected && color == normal_color
    redraw_change_color(color,enabled)
  end
end #Window_Base

#==============================================================================
# Window_Selectable
#==============================================================================
class Window_Selectable < Window_Base
  #--------------------------------------------------------------------------
  # alias method: index=
  #--------------------------------------------------------------------------
  alias redraw_set_index index=
  def index=(index)
    old_index = @index
    redraw_set_index(index)
    redraw_item(old_index)
    redraw_item(index)
  end
  #--------------------------------------------------------------------------
  # new method: draw_item_wrapper -> replace calls to draw_item to this to
  # ensure reselection color
  #--------------------------------------------------------------------------
  def draw_item_wrapper(index)
    @_selected = @index == index
    draw_item(index)
    @_selected = nil
  end
  #--------------------------------------------------------------------------
  # overwrite method: redraw_item
  #--------------------------------------------------------------------------
  def redraw_item(index)
    clear_item(index) if index >= 0
    draw_item_wrapper(index)  if index >= 0 #replaced
  end
  #--------------------------------------------------------------------------
  # overwrite method: draw_all_items
  #--------------------------------------------------------------------------
  def draw_all_items
    item_max.times {|i| draw_item_wrapper(i) }
  end
end #Window_Selectable

#==============================================================================
# Window_Command
#==============================================================================
class Window_Command< Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: redraw_item (avoids crashes)
  #--------------------------------------------------------------------------
  alias command_redraw_redraw_item redraw_item
  def redraw_item(index)
    command_redraw_redraw_item(index) if @list[index]
  end
end #Window_Command