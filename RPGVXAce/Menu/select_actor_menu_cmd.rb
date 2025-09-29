#==============================================================================
# Select Actor Common Event Menu
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 26/04/2025
#
# source of discussion:
# https://forums.rpgmakerweb.com/index.php?threads/add-a-opinion-menu-to-the-pause-menu.177149/page-2
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-SelectActorCEM"] = true

#==============================================================================
# Adds a common event command in the main menu that will first ask to select a list of actors in
# the menu. Then, the command will call the common event with id COMMON_EVENT
#
# The ids of the actors selected are stored in the variables with ids
# ACTOR_VARIABLES.
# For instance, if ACTOR_VARIABLES = [4,2,5], then 3 actors must be selected,
# the first one is stored in $game_variables[4], the second one in $game_variables[2]
# and the third one in $game_variables[5].
#
# If ACTOR_VARIABLES = [], then the script directly calls the common event
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

#==============================================================================
# SelectActorCEM -> set up the parameters here
#==============================================================================
module SelectActorCEM
  COMMON_EVENT = 5 #the id of the common event called
  CMD_NAME = "Talk" #the name of the menu command
 
  #the id of the switch that, set to true will deactivate the command,
  #put <= 0 value to disable this feature
  CONTROL_SWITCH = 0
  #list the ids of the variables that are altered by an actor input,
  #first variable stores first selected actor, second one the second etc.
  ACTOR_VARIABLES = [10]
 
  #--------------------------------------------------------------------------
  # new method: select_allowed?
  # Return true iff picking actor_id as the ith selected actor is ok
  # By default, will forbid to pick the same actor twice
  #--------------------------------------------------------------------------
  def self.select_allowed?(actor_id, i)
    return false if ACTOR_VARIABLES.slice(0,i).any?{|v| $game_variables[v] == actor_id} #exclude already picked actors
    #put addtionnal chekings here
    true
  end
end #SelectActorCEM

#==============================================================================
# Window_MenuCommand -> adds the command to the list in the menu
#==============================================================================
class Window_MenuCommand < Window_Command
  #--------------------------------------------------------------------------
  # alias method: add_original_commands
  #--------------------------------------------------------------------------
  alias sacem_add_original_commands add_original_commands
  def add_original_commands
    add_command(SelectActorCEM::CMD_NAME, :common_events_menu,   sacem_command_enabled)
    sacem_add_original_commands
  end
 
  #--------------------------------------------------------------------------
  # new method: sacem_command_enabled
  #--------------------------------------------------------------------------
  #the command won't be available if there are less party members than variables to fill
  def sacem_command_enabled
    $game_party.members.size >= SelectActorCEM::ACTOR_VARIABLES.size && (SelectActorCEM::CONTROL_SWITCH <= 0 || !$game_switches[CALL_EVENT_MENU::CONTROL_SWITCH])
  end
end #Window_MenuCommand

#==============================================================================
# Scene_Menu -> sets the results of the command
#==============================================================================
class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # alias method: create_command_window
  #--------------------------------------------------------------------------
  alias sacem_create_command_window create_command_window
  def create_command_window
    sacem_create_command_window
    @command_window.set_handler(:common_events_menu, method(:command_sacem))
  end
 
  #--------------------------------------------------------------------------
  # new method: command_sacem -> calls the status menu (actor list)
  #--------------------------------------------------------------------------
  def command_sacem
    @select_level = 0 #counts how many times the actors are selected
    return on_command_sacem_ok if SelectActorCEM::ACTOR_VARIABLES.empty?
    @status_window.sacem_mode = true
    @status_window.select_last
    @status_window.activate
    @status_window.set_handler(:ok,     method(:on_command_sacem_ok))
    @status_window.set_handler(:cancel, method(:on_command_sacem_cancel))
  end
 
  #--------------------------------------------------------------------------
  # new method: on_command_sacem_ok -> adds the actor_id to the variable
  # and call the event if all actors are selected or ask for the next actor
  #--------------------------------------------------------------------------
  def on_command_sacem_ok
    if @select_level < SelectActorCEM::ACTOR_VARIABLES.size
      actor_id = $game_party.members[@status_window.index].id
      $game_variables[SelectActorCEM::ACTOR_VARIABLES[@select_level]] = actor_id
      @select_level += 1
      @status_window.pending_list.push(@status_window.index)
      @status_window.redraw_item(@status_window.index)
    end
    #when all actors are selected -> call the common_event
    if @select_level >= SelectActorCEM::ACTOR_VARIABLES.size
      @status_window.pending_list.clear
      @status_window.sacem_mode = false
      SceneManager.goto(Scene_Map)
      $game_temp.reserve_common_event(SelectActorCEM::COMMON_EVENT)
    else #There are still actors to pick
      @status_window.activate
    end
  end
 
  #--------------------------------------------------------------------------
  # new method: on_command_sacem_cancel -> cancels the last selected actor
  # or return to the previous menu if stack is empty
  #--------------------------------------------------------------------------
  def on_command_sacem_cancel
    if @select_level <= 0
      @status_window.sacem_mode = false
      return on_personal_cancel
    end
    @select_level -= 1
    @status_window.select(@status_window.pending_list.pop)
    @status_window.redraw_item(@status_window.index)
    @status_window.activate
  end
end #Scene_Menu

#==============================================================================
# Window_MenuStatus -> highlight selected actors and controls which can be selected
#==============================================================================
class Window_MenuStatus < Window_Selectable
  attr_accessor :sacem_mode #boolean to activate under this script selection
  attr_reader :pending_list #stores index in the list that are pending
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias sacem_winmenu_status_init initialize
  def initialize(x, y)
    @sacem_mode = false
    @pending_list = []
    sacem_winmenu_status_init(x,y)
  end
  #--------------------------------------------------------------------------
  # alias method: draw_item_background
  #--------------------------------------------------------------------------
  alias sacem_draw_item_background draw_item_background
  def draw_item_background(index)
    contents.fill_rect(item_rect(index), pending_color) if @pending_list.include?(index)
    sacem_draw_item_background(index)
  end
  #--------------------------------------------------------------------------
  # alias method: current_item_enabled?
  #--------------------------------------------------------------------------
  alias sacem_current_item_enabled? current_item_enabled?
  def current_item_enabled?
    return sacem_current_item_enabled? && (!sacem_mode || SelectActorCEM.select_allowed?($game_party.members[index].id,@pending_list.size))
  end
end #Window_MenuStatus