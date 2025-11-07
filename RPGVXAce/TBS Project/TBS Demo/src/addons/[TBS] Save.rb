#==============================================================================
# TBS Save in battle
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 03/06/2025
# Requires: [TBS] by Timtrack
# Special thanks to Another Fen for providing a script to save vanilla battle data
# https://forums.rpgmakerweb.com/index.php?threads/opening-another-scene-mid-battle-and-saving-mid-battle.177182/
#
# Includes compatibility with Yanfly Save Engine and my script Neo Save-like
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Save"] = true #set to false if to disable this script

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows to save in tbs battles and load the saves to return to battle
#==============================================================================
# Installation: put it below TBS core and Yanfly Save Engine if you use it
#==============================================================================
# Compatibility: requires TBS patchub to work with dodger451's Threat System
#==============================================================================
# Terms of use: same as TBS project, I suggest you give credit to Another Fen
# as this script is 80% dones by them ~
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
# Don't edit anything past this point unless you know what you are doing!
#============================================================================

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
    @save_pre_tbs = !$BTEST && TBS::Save::PREBATTLE_MENU
    @save_mid_tbs = !$BTEST && TBS::Save::MIDBATTLE_MENU
    tbs_save_gs_init
  end
end #Game_System

#============================================================================
# Scene_TBS_Battle
#============================================================================
class Scene_TBS_Battle
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
  end

  #--------------------------------------------------------------------------
  # new method: open_save_menu -> called by interpreter too
  #--------------------------------------------------------------------------
  def open_save_menu(load_menu = false)
    Scene_Map.take_picture if $imported["TIM-NeoSave"]
    scene_class = load_menu ? Scene_Load : Scene_Save
    SceneManager.call(scene_class)
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
  # ---
  # Modify the marshal data to only skip commands if the interpreter was started
  # ---
  #--------------------------------------------------------------------------
  # alias method: clear
  #--------------------------------------------------------------------------
  alias clear_after_ResetStartedFlag clear
  def clear
    @interpreter_started = false
    clear_after_ResetStartedFlag
  end

  #--------------------------------------------------------------------------
  # alias method: run
  #--------------------------------------------------------------------------
  # Note: If the game can be saved (again) while the interpreter is waiting
  # for the message window, additional safeguards will be needed.
  alias run_after_SetStartedFlag run
  def run
    @interpreter_started = true
    run_after_SetStartedFlag
  end

  #--------------------------------------------------------------------------
  # alias method: marshal_dump
  #--------------------------------------------------------------------------
  alias marshal_dump_before_StartedFlag marshal_dump
  def marshal_dump
    result = marshal_dump_before_StartedFlag
    result.push(@interpreter_started ? nil : @index)
    return result
  end

  #--------------------------------------------------------------------------
  # alias method: marshal_load
  #--------------------------------------------------------------------------
  alias marshal_load_during_StartedFlag marshal_load
  def marshal_load(obj)
    raise "Incompatible Save Data"  if obj.length < 7  # Basic Consistency Check
    idle_index = obj.pop
    marshal_load_during_StartedFlag(obj)
    @index = idle_index  if idle_index
    @interpreter_started = false
  end

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
      SceneManager.call(Scene_TBS_Battle)  if $game_temp.save_was_in_tbs? && $game_system.tbs_enabled?
    end
  end #Scene_Load
end #$imported["YEA-SaveEngine"]

end #$imported["TIM-TBS-Save"]
