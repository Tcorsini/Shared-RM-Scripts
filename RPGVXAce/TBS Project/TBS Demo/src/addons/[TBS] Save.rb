#==============================================================================
# TBS Save in battle
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 03/05/2025
# Requires: [TBS] by Timtrack
# Special thanks Another Fen for providing a script to save vanilla battle data
# https://forums.rpgmakerweb.com/index.php?threads/opening-another-scene-mid-battle-and-saving-mid-battle.177182/
#
# Includes compatibility with Yanfly Save Engine and my script Neo Save-like
#==============================================================================

$imported = {} if $imported.nil?
raise "TBS Save in battle requires TBS by Timtrack" unless $imported["TIM-TBS"]
$imported["TIM-TBS-Save"] = true #set to false if you wish to disable this feature

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows to save in tbs battles and load the saves to return to battle
#==============================================================================
# Installation: put it below TBS core and Yanfly Save Engine if you use it
#==============================================================================
# Compatibility: requires TBS patchub to work with dodger451's Threat System
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

if $imported["TIM-TBS-Save"]
  
module TBS
  module Save
    #the default parameters for saving in battle, will be stored in $game_system and modifiable ingame
    PREBATTLE_MENU = true #give access to the save menu in prebattle phase
    MIDBATTLE_MENU = true #give access to the save menu in the middle of battle
  end #Save
end #TBS

#============================================================================
# Game_System -> set the options of displaying the saving menu
#============================================================================
class Game_System
  attr_accessor :save_mid_tbs, :save_pre_tbs
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tbs_save_gs_init initialize
  def initialize
    @save_pre_tbs = TBS::Save::PREBATTLE_MENU
    @save_mid_tbs = TBS::Save::MIDBATTLE_MENU
    tbs_save_gs_init
  end
end #Game_System

#============================================================================
# Game_Temp -> store the tbs scene data for easier retrieval
#============================================================================
class Game_Temp
  attr_accessor :tbs_scene_data
  #--------------------------------------------------------------------------
  # new method: save_was_in_tbs?
  #--------------------------------------------------------------------------
  def save_was_in_tbs?
    @tbs_scene_data #&& !@tbs_scene_data[:@phase].nil?
  end
end #Game_Temp

#============================================================================
# Scene_TBS_Battle
#============================================================================
class Scene_TBS_Battle
  #--------------------------------------------------------------------------
  # alias method: setup_map -> loads the saved parameters if any
  # if saved data, then the current map (stored in @map_id) is already the right
  # one, loads its data just in case but it might be discarded if phase is late
  #--------------------------------------------------------------------------
  alias tbs_save_setup_map setup_map
  def setup_map
    return $game_map.setup_tbs_events if retrieve_battle_state
    return tbs_save_setup_map
  end

  #--------------------------------------------------------------------------
  # alias method: create_battlers -> don't create battlers after loading saved content
  #--------------------------------------------------------------------------
  alias tbs_save_create_battlers create_battlers
  def create_battlers(map_tbs_data)
    #default behavior, only when no saved data was retrieved
    return tbs_save_create_battlers(map_tbs_data) unless @phase
    return if @phase == :battle #skip if already in battle, nothing to load here
    @places_loc, extra_battlers, obstacles_list, enemy_loc, actor_loc = map_tbs_data
    placed_bats = $game_map.targeted_battlers(@places_loc[TBS::TEAMS::TEAM_ACTORS])
    #select actors but don't omit the already placed actors
    @place_candidates = $game_party.all_members.select{|actor| actor.can_battle? && (!actor.tbs_battler || placed_bats.include?(actor))}
    return
  end
  
  #--------------------------------------------------------------------------
  # alias method: return_to_map -> skip its call when reloading the map
  #--------------------------------------------------------------------------
  alias save_return_to_map return_to_map
  def return_to_map
    save_return_to_map unless @reloading
  end
  
  #--------------------------------------------------------------------------
  # new method: save_battle_state
  #--------------------------------------------------------------------------
  def save_battle_state
    #list the attributes from this scene that will be saved
    variables = [:@phase,:@turnWheel,:@tbs_battlers,:@map_id]
    $game_temp.tbs_scene_data = Hash.new
    $game_temp.tbs_scene_data[:battledata] = Hash[variables.map { |i| [i, instance_variable_get(i)] }]
    #$game_temp.tbs_scene_data = Hash[variables.map { |i| [i, instance_variable_get(i)] }]
  end
  
  #--------------------------------------------------------------------------
  # new method: retrieve_battle_state return true iff there was data to retrieve
  #--------------------------------------------------------------------------
  def retrieve_battle_state
    return false unless $game_temp.save_was_in_tbs?
    $game_temp.tbs_scene_data[:battledata].each_pair { |key, value| instance_variable_set(key, value) }
    $game_temp.tbs_scene_data = nil
    return true
  end
  
  #--------------------------------------------------------------------------
  # alias method: pre_battle_start -> skip place phase if already in battle
  #--------------------------------------------------------------------------
  alias tbs_save_pre_battle_start pre_battle_start
  def pre_battle_start
    return tbs_save_pre_battle_start unless @phase == :battle
    @confirm_window.set_mode(:start_battle)
    on_confirm_ok
  end
  
  #--------------------------------------------------------------------------
  # alias method: battle_start -> skip battle start if already in battle
  #--------------------------------------------------------------------------
  alias tbs_save_battle_start battle_start
  def battle_start
    return tbs_save_battle_start unless @phase == :battle
    @active_battlers = @turnWheel.getActiveBattlers
    @cursor.moveto_bat(@active_battlers[0]) if @active_battlers.size > 0
    command_cursor_select
  end
  
  #--------------------------------------------------------------------------
  # alias method: create_global_command_window
  #--------------------------------------------------------------------------
  alias tbs_save_create_global_command_window create_global_command_window
  def create_global_command_window
    tbs_save_create_global_command_window
    @party_command_window.set_handler(:save, method(:command_save_menu))
  end
  
  #--------------------------------------------------------------------------
  # alias method: create_place_command_window
  #--------------------------------------------------------------------------
  alias tbs_save_create_place_command_window create_place_command_window
  def create_place_command_window
    tbs_save_create_place_command_window
    @place_command_window.set_handler(:save, method(:command_save_menu))
  end
  
  #--------------------------------------------------------------------------
  # new method: command_save_menu
  #--------------------------------------------------------------------------
  def command_save_menu
    @place_command_window.hide
    @party_command_window.hide
    open_save_menu
    @place_command_window.show
    @party_command_window.show
    open_global_commands
  end
  
  #--------------------------------------------------------------------------
  # new method: open_save_menu -> called by interpreter too
  #--------------------------------------------------------------------------
  def open_save_menu(load_menu = false)
    save_battle_state
    Scene_Map.take_picture if $imported["TIM-NeoSave"]
    SceneManager.snapshot_for_background
    scene_class = load_menu ? Scene_Load : Scene_Save
    SceneManager.call(scene_class)
    SceneManager.scene.main #will loop until we leave Scene_Save/Scene_Load
    return @reloading = true if SceneManager.scene != self #skip other stuff when loading a save
    $game_temp.tbs_scene_data = nil       #discard tmp tbs saved data
    SceneManager.scene.perform_transition #updates the graphics back
  end
end #Scene_TBS_Battle

#code here from save battle script provided by Another Fen:
# https://forums.rpgmakerweb.com/index.php?threads/opening-another-scene-mid-battle-and-saving-mid-battle.177182/
#
# Store/Load BattleManager Status in a savefile:
# - The @method_wait_for_message variable is incompatible, but will be updated
#   when entering the battle scene anyways.
# - The "Battle Processing..." event callback proc needs to be made compatible
# - The "@event_flags" from $game_troop need to be refreshed, since the troop
#   event page objects will be different

#============================================================================
# BattleManager
#============================================================================
module BattleManager
  #--------------------------------------------------------------------------
  # new method: memorize_state
  #--------------------------------------------------------------------------
  def self.memorize_state
    variables = instance_variables - [:@method_wait_for_message]
    return Hash[variables.map { |i| [i, instance_variable_get(i)] }]
  end
  #--------------------------------------------------------------------------
  # new method: restore_state
  #--------------------------------------------------------------------------
  def self.restore_state(contents)
    contents.each_pair { |key, value| instance_variable_set(key, value) }
  end
end #BattleManager

#============================================================================
# Game_Troop
#============================================================================
class Game_Troop
  #--------------------------------------------------------------------------
  # new method: memorize_event_flags
  #--------------------------------------------------------------------------
  def memorize_event_flags
    flags = Hash[@event_flags.map { |key, val| [troop.pages.index(key), val] }]
    raise "Page reassociation error!"  if flags.has_key?(nil)
    return flags
  end
 #--------------------------------------------------------------------------
  # new method: restore_event_flags
  #--------------------------------------------------------------------------
  def restore_event_flags(contents)
    @event_flags.clear
    contents.each_pair { |id, value| @event_flags[troop.pages[id]] = value }
  end
end #Game_Troop

#==============================================================================
# Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # new class: Event_Proc -> Marshal-compatible event callback for in-battle saves
  #--------------------------------------------------------------------------
  class Event_Proc
    def initialize(branch, indent)
      @branch = branch
      @indent = indent
    end
 
    def call(value)
      @branch[@indent] = value
    end
  end #Event_Proc
 
  #--------------------------------------------------------------------------
  # overwrite method: command 301
  #--------------------------------------------------------------------------
  def command_301
    return if $game_party.in_battle
    if @params[0] == 0                      # Direct designation
      troop_id = @params[1]
    elsif @params[0] == 1                   # Designation with variables
      troop_id = $game_variables[@params[1]]
    else                                    # Map-designated troop
      troop_id = $game_player.make_encounter_troop_id
    end
    if $data_troops[troop_id]
      BattleManager.setup(troop_id, @params[2], @params[3])
      # --- Modified:
      BattleManager.event_proc = Event_Proc.new(@branch, @indent)
      #BattleManager.event_proc = Proc.new {|n| @branch[@indent] = n }
      # ---
      $game_player.make_encounter_count
      SceneManager.call(Scene_Battle)
    end
    Fiber.yield
  end
  
  #--------------------------------------------------------------------------
  # alias method: command_352 -> calls save menu
  #--------------------------------------------------------------------------
  alias tbs_save_command_352 command_352
  def command_352
    return tbs_save_command_352 unless SceneManager.scene_is?(Scene_TBS_Battle)
    SceneManager.scene.open_save_menu
    Fiber.yield
  end
end #Game_Interpreter
#end of code from save battle script


if $imported["YEA-SaveEngine"]
  #==============================================================================
  # Scene_File
  #==============================================================================
  class Scene_File
    #--------------------------------------------------------------------------
    # alias method: on_load_success
    #--------------------------------------------------------------------------
    alias tbs_save_on_load_success on_load_success
    def on_load_success
      tbs_save_on_load_success
      #modify?
      #puts "TBS State"
      #puts $game_temp.save_was_in_tbs?
      SceneManager.call(Scene_TBS_Battle)  if $game_temp.save_was_in_tbs? && $game_system.tbs_enabled?
    end
  end #Scene_File
else #vanilla
  #==============================================================================
  # Scene_Load
  #==============================================================================
  class Scene_Load
    #--------------------------------------------------------------------------
    # alias method: on_load_success
    #--------------------------------------------------------------------------
    alias tbs_save_on_load_success on_load_success
    def on_load_success
      tbs_save_on_load_success
      #this line should be modified
      SceneManager.call(Scene_TBS_Battle)  if $game_temp.save_was_in_tbs? && $game_system.tbs_enabled?
    end
  end #Scene_Load
end #$imported["YEA-SaveEngine"]

#==============================================================================
# DataManager
#==============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # alias method: make_save_contents
  #--------------------------------------------------------------------------
  alias tbs_save_make_save_contents make_save_contents
  def make_save_contents
    contents = tbs_save_make_save_contents
    if $game_temp.tbs_scene_data && $game_system.tbs_enabled?
      contents[:battle_state] = BattleManager.memorize_state
      contents[:troop_event_flags] = $game_troop.memorize_event_flags
      contents[:tbs_scene_data] = $game_temp.tbs_scene_data
    end
    contents
  end
 
  #--------------------------------------------------------------------------
  # alias method: extract_save_contents
  #--------------------------------------------------------------------------
  alias tbs_save_extract_save_contents extract_save_contents
  def extract_save_contents(contents)
    tbs_save_extract_save_contents(contents)
    $game_temp.tbs_scene_data = contents[:tbs_scene_data]
    if $game_temp.tbs_scene_data && $game_system.tbs_enabled?
      BattleManager.restore_state(contents[:battle_state])
      $game_troop.restore_event_flags(contents[:troop_event_flags])
    end
  end
end #DataManager

end #$imported["TIM-TBS-Save"]