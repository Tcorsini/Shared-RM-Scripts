#==============================================================================
# Window_OBar
#==============================================================================
class Window_OBar < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: refresh (adopt similar pattern to original refresh)
  #--------------------------------------------------------------------------
  alias select_display_patch_refresh refresh
  def refresh(temp_value)
    @tmp_value = temp_value
    super()
  end
  #--------------------------------------------------------------------------
  # overwrite method: draw_item (was empty before) -> does the same as previous
  # refresh method
  #--------------------------------------------------------------------------
  def draw_item(index)
    return unless @tmp_value
    select_display_patch_refresh(@tmp_value)
  end
end #Window_OBar