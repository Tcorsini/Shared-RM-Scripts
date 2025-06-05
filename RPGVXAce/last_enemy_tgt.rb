#==============================================================================
# Last enemy select
#------------------------------------------------------------------------------
# Author: Timtrack (no need for credit)
# date: 23/03/2025
#==============================================================================
# The enemy window will save the last enemy targeted for future uses,
# if the enemy is not in the list anymore, the window goes back to the first enemy
#
# You may set the enemy targeted by calling
# target_enemy(i)
# with i the index of the enemy in the troop
#
# Includes compatibility patch with Yanfly Battle Engine
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # * new method: target_enemy
  #--------------------------------------------------------------------------
  def target_enemy(index)
    SceneManager.scene.enemy_window.select_by_index(index) if SceneManager.scene_is?(Scene_Battle)
  end
end

class Scene_Battle < Scene_Base
  attr_reader :enemy_window #to access the enemy window
end

class Window_BattleEnemy < Window_Selectable
  #--------------------------------------------------------------------------
  # * alias method: hide
  #--------------------------------------------------------------------------
  alias hide_wbe_tles hide
  def hide
    @last_enemy = enemy
    hide_wbe_tles
  end
  
  #--------------------------------------------------------------------------
  # * new method: select_last_enemy
  #--------------------------------------------------------------------------
  def select_last_enemy
    i = enemy_list.index(@last_enemy)
    i = 0 if i.nil?
    select(i)
  end
  
  #--------------------------------------------------------------------------
  # * new method: select_by_index
  #--------------------------------------------------------------------------
  def select_by_index(enemy_index)
    i = enemy_list.index {|en| en.index == enemy_index}
    if i
      @last_enemy = enemy_list[i]
      select(i)
    end
  end
  
if $imported["YEA-BattleEngine"]
  #--------------------------------------------------------------------------
  # * new method: enemy_list
  #--------------------------------------------------------------------------
  def enemy_list
    @data
  end
  #--------------------------------------------------------------------------
  # * alias method: create_flags
  #--------------------------------------------------------------------------
  alias create_flags_wbe_tles create_flags
  def create_flags
    create_flags_wbe_tles
    select_last_enemy
  end
else #vanilla rpg maker
  #--------------------------------------------------------------------------
  # * new method: enemy_list
  #--------------------------------------------------------------------------
  def enemy_list
    $game_troop.alive_members
  end
  #--------------------------------------------------------------------------
  # * overwrite method: show
  #--------------------------------------------------------------------------
  def show
    if @info_viewport
      width_remain = Graphics.width - width
      self.x = width_remain
      @info_viewport.rect.width = width_remain
      select_last_enemy #select(0)
    end
    super
  end
end #$imported["YEA-BattleEngine"]
end #Window_BattleEnemy