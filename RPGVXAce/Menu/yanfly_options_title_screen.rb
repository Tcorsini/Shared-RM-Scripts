#==============================================================================
# YEA - System Options addon - Title Screen Options
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 26/09/2025
# Requires Yanfly's system options
#==============================================================================
# Description: A rework of a script by Roninator2 that adds Yanfly's option 
# menu to the title screen. The options will now be stored into a file with name 
# OPTION_FILE in module, this file will be shared among ALL saves.
# If you use custom swicthes or variables in yanfly's option, then the switches
# and variables will be overtaken by the option file.
#==============================================================================
# Term of use: Free to use in free or commercial games
#==============================================================================
# Installation: put it below Yanfly's script
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YEA-SO-addon-titleScreen"] = true

#============================================================================
# TitleOptions
#============================================================================
module TitleOptions
  #set this to a filename that suits you
  OPTION_FILE = "Options.rvdata2"

#==============================================================================
# ▼ Editting anything past this point is at your own risk
#==============================================================================
  #attributes that yanfly's options script modifies
  SYSTEM_ATTRIBUTES = [:@window_tone, :@volume, :@autodash, :@instantmsg, :@animations]
  #swicthes modified by Yanfly's option (intersection between the commands used 
  #and the ons related to swicthes, then stores the actual swicth id)
  SWITCHES = (YEA::SYSTEM::COMMANDS & YEA::SYSTEM::CUSTOM_SWITCHES.keys).map{|k| YEA::SYSTEM::CUSTOM_SWITCHES[k][0]}
  #variables modified by Yanfly's option
  VARIABLES = (YEA::SYSTEM::COMMANDS & YEA::SYSTEM::CUSTOM_VARIABLES.keys).map{|k| YEA::SYSTEM::CUSTOM_VARIABLES[k][0]}
end #TitleOptions

#============================================================================
# YEA_Options_Data -> stores the values after the options are done and save it
# into a file
#============================================================================
class YEA_Options_Data
  #--------------------------------------------------------------------------
  # method: initialize
  #--------------------------------------------------------------------------
  def initialize
    get_data
  end
  #--------------------------------------------------------------------------
  # method: get_data -> get all variables, swicthes and attributes handled by 
  # Yanfly's script
  #--------------------------------------------------------------------------
  def get_data
    @system_data = TitleOptions::SYSTEM_ATTRIBUTES.map{|attr| $game_system.instance_variable_get(attr)}
    @switches = TitleOptions::SWITCHES.map{|id| $game_switches[id]}
    @variables = TitleOptions::VARIABLES.map{|id| $game_variables[id]}
  end
  #--------------------------------------------------------------------------
  # method: set_data -> set all variables, swicthes and attributes handled by 
  # Yanfly's script
  #--------------------------------------------------------------------------
  def set_data
    TitleOptions::SYSTEM_ATTRIBUTES.each_with_index do |attr,i|
      $game_system.instance_variable_set(attr, @system_data[i])
    end
    TitleOptions::SWITCHES.each_with_index do |s_id,i|
      $game_switches[s_id] = @switches[i]
    end
    TitleOptions::VARIABLES.each_with_index do |v_id,i|
      $game_variables[v_id] = @variables[i]
    end
  end
end #YEA_Options_Data

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # new method: load_options
  #--------------------------------------------------------------------------
  def self.load_options
    return unless File.exists?(TitleOptions::OPTION_FILE)
    File.open(TitleOptions::OPTION_FILE, "rb") do |file|
      o_d = Marshal.load(file)
      o_d.set_data if o_d.is_a?(YEA_Options_Data)
    end
  end
  #--------------------------------------------------------------------------
  # new method: save_options (assumes the data is already here)
  #--------------------------------------------------------------------------
  def self.save_options
    File.open(TitleOptions::OPTION_FILE, "wb") do |file|
      Marshal.dump(YEA_Options_Data.new, file)
    end
  end
  #--------------------------------------------------------------------------
  # alias method: load_game -> loads the option file
  #--------------------------------------------------------------------------
  class << self; alias title_options_load_game load_game; end
  def self.load_game(index)
    r = title_options_load_game(index)
    load_options if r
    return r
  end
  #--------------------------------------------------------------------------
  # alias method: create_game_objects -> saves 
  #--------------------------------------------------------------------------
  class << self; alias create_game_objects_global_options create_game_objects; end
  def self.create_game_objects
    create_game_objects_global_options
    load_options
  end
end #DataManager

#============================================================================
# Window_TitleCommand
#============================================================================
class Window_TitleCommand < Window_Command
  #--------------------------------------------------------------------------
  # overwrite method: make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(Vocab::new_game, :new_game)
    add_command(Vocab::continue, :continue, continue_enabled)
    add_command("Options", :options)
    add_command(Vocab::shutdown, :shutdown)
  end
end #Window_TitleCommand

#============================================================================
# Scene_Title
#============================================================================
class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias title_options_start start
  def start
    title_options_start
    DataManager.create_game_objects if $game_switches.nil?
  end
  #--------------------------------------------------------------------------
  # alias method: create_command_window
  #--------------------------------------------------------------------------
  alias title_options_create_command_window create_command_window
  def create_command_window
    title_options_create_command_window
    @command_window.set_handler(:options, method(:command_options))
  end
  #--------------------------------------------------------------------------
  # new method: command_options
  #--------------------------------------------------------------------------
  def command_options
    close_command_window
    SceneManager.call(Scene_System)
  end
end #Scene_Title

#============================================================================
# Scene_System
#============================================================================
class Scene_System < Scene_MenuBase
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias title_options_start start
  def start
    DataManager.create_game_objects if $game_switches.nil?
    title_options_start
  end
  #--------------------------------------------------------------------------
  # alias method: terminate
  #--------------------------------------------------------------------------
  alias title_options_terminate terminate
  def terminate
    DataManager.save_options
    title_options_terminate
  end
end #Scene_System