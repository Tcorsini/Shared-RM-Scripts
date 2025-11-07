#==============================================================================
# Simple Notetag Config v1.2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 06/11/2025
# inspired by Clarabel's notetags reading in GTBS
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-SimpleNotetagConfig"] = true

#==============================================================================
# Version History
#------------------------------------------------------------------------------
# 08/09/2025 - Original release
# 03/11/2025 - v1.1 added tileset notetags support, fixed crash for battle test
# 06/11/2025 - v1.2 added hash support, extended the matching support to cover
#                   more complicated objects
#==============================================================================
# Description: a utility script for those tired of writing the same multiple
# lines of code to setup data from notetags. This script will allow, with a few
# line of code, to create attributes to objects from the database with a default
# value and a basic assignation value through notetag reading.
#
# This script is for advanced users with enough knowledge in notetags setup,
# you must understand basic code and regexp.
#==============================================================================
# Term of use: Free to use in free or commercial games, please give credit.
#==============================================================================
# Installation & Configuration: put the script above main, set your own code in
# method self.prepare_metadata to create attributes to be read in notetags
#
# Add to DATA_ arrays Notetag_Data objects that will be turned into attributes
# inside rpg maker database objects.
# DATA can be DATA_SKILLS, DATA_ITEMS, DATA_WEAPONS, DATA_ARMORS, DATA_TILESETS,
# DATA_STATES, DATA_ENEMIES, DATA_ACTORS, DATA_CLASSES, DATA_MAPS or DATA_TROOPS
#
# For each DATA_X, the attribute will be read from the notetags regexp and will
# be stored inside $data_x at the launch of the game when loading the database.
# There are two exceptions:
# For DATA_MAPS, the data will be stored in $data_mapinfos
# For DATA_TROOPS, the data will be read from comments in every page of the
# troop (regardless of their conditions)
#
# To add an entry, put in the corresponding(s) arrays:
#   Notetag_Data.new(symbol, default, regexp, type)
#
# symb    is the name of the attribute added to the database, it will be set as
#         an accessor, for instance:
#         symb=:range means that obj.range will be accessible from the database
# default is the value set by default when no matching line to the regexp was
#         found
# regexp  is a regular expression set to find the value, it will be interpreted
#         with type
# type    is an integer related to AssignationModes indices
#         0/none provided -> the data is read and evaluated (int, bool, float,
#                            symbols, arrays)
#         1               -> the string is stored as is (files, texts)
#         2               -> will replace the default value by true if the
#                            regexp is found
#         3               -> to deal with hash tables, will eval the two values
#                            set ($1,$2) and do hash[eval($1)] = eval($2)
#
# You can put a Notetag_Data object x to multiple arrays by calling
#   x.add_to(a1,a2,...)
#
# Example:
#  n = Notetag_Data.new(:required_level, 1, /^<min_level\s*=\s*(\d+)\s*>/i, 0)
#  n.add_to(DATA_WEAPONS,DATA_ARMORS)
# If the weapon with id 5 has in a notetag <min_level = 3>, then
# $data_weapons[5].min_level will be 3,
# If no such notetag was given, the default value will be stored instead (ex: 1)
#
# If for some reason you need to perform some specific postprocessing action to
# the added attributes, you can redefine method post_metadata_notetags_reading
# in RPG::BaseItem, RPG::MapInfo, RPG::Tileset, RPG::Troop and their subclasses
#============================================================================

if $imported["TIM-SimpleNotetagConfig"]

#============================================================================
# SNC/SimpleNotetagConfig -> module that you must configure
#============================================================================
module SNC
  #--------------------------------------------------------------------------
  # method: prepare_metadata -> called while loading the database at the start
  # of the game, fill the arrays with Notetag_Data objects here
  #--------------------------------------------------------------------------
  def self.prepare_metadata
    #You modify the arrays like this:
    # DATA_SKILLS.concat([
    #   Notetag_Data.new(:var_symb, default_value, regexp, regexp_read_type_id),
    #   Notetag_Data.new(:var_symb2, default_value2, regexp2, regexp_read_type_id2),
    # ])
    #
    #You can also add the same notetag object to multiple data arrays:
    # obj.add_to(DATA_WEAPONS,DATA_ARMORS,DATA_STATES)
    #
    #example code:
    #n = Notetag_Data.new(:required_level, 1, /^<min_level\s*=\s*(\d+)\s*>/i, 0)
    #n.add_to(DATA_WEAPONS,DATA_ARMORS,DATA_MAPS,DATA_TROOPS)
  end

#============================================================================
# Editing anything past this point is not recommended
#============================================================================
  #DATA_SKILLS Config (modify RPG::Skill)
  DATA_SKILLS = []
  #DATA_ITEMS Config (modify RPG::Item)
  DATA_ITEMS = []
  #DATA_WEAPONS Config (modify RPG::Weapon)
  DATA_WEAPONS = []
  #DATA_ARMORS Config (modify RPG::Armor)
  DATA_ARMORS = []
  #DATA_STATES Config (modify RPG::State)
  DATA_STATES = []
  #DATA_ENEMIES Config (modify RPG::Enemy)
  DATA_ENEMIES = []
  #DATA_ACTORS Config (modify RPG::Actor)
  DATA_ACTORS = []
  #DATA_CLASSES Config (modify RPG::Class)
  DATA_CLASSES = []
  #DATA_MAPS Config (modify RPG::MapInfo)
  DATA_MAPS = []
  #DATA_TROOPS Config (modify RPG::Troop)
  DATA_TROOPS = []
  #DATA_TILESETS Config (modify RPG::Tileset)
  DATA_TILESETS = []

  #--------------------------------------------------------------------------
  # common cache: load_notetags_metadata
  # data_list is an array of Notetag_Data
  #--------------------------------------------------------------------------
  def self.load_notetags_metadata(obj,data_list,note)
    data_list.each do |d|
      obj.instance_variable_set(d.attribute_name,d.default_value)
      obj.class.send(:attr_accessor, d.symbol)
    end
    note.split(/[\r\n]+/).each { |line|
      data_list.each do |d|
        matches = line.scan(d.regexp)
        matches.each do |str_values|
          original_v = obj.instance_variable_get(d.attribute_name)
          new_val = d.value(original_v, str_values)
          obj.instance_variable_set(d.attribute_name, new_val)
        end
      end
    } # self.note.split
    obj.post_metadata_notetags_reading
  end
end #SNC

#============================================================================
# Notetag_Data -> represents how notetags are read for most items
#============================================================================
class Notetag_Data
  #eval: to save int, floats or arrays
  #string: to save the evaluated data as a string
  #activate: to put a value to true when data matches the regexp
  #hash: to put inside the hash the second value with key the first value
  AssignationModes = [:eval, :string, :activate, :hash]
  #accessors:
  attr_accessor :symbol, :default_value, :regexp, :assignation_mode
  #--------------------------------------------------------------------------
  # method: initialize
  #--------------------------------------------------------------------------
  def initialize(symb,default,regexp,assign_mode_id=0)
    @symbol = symb
    @default_value = default
    @regexp = regexp
    @assignation_mode = AssignationModes[assign_mode_id]
  end
  #--------------------------------------------------------------------------
  # method: attribute_name -> turns symb :s into @s for instance get/set
  #--------------------------------------------------------------------------
  def attribute_name
    return "@"+@symbol.id2name
  end
  #--------------------------------------------------------------------------
  # method: value -> returns a value to store into the object
  # parameters:
  # -original_value : the current object's value
  # -str_l a list of string identified by the regexp
  #--------------------------------------------------------------------------
  def value(original_value, str_l)
    case @assignation_mode
    when :eval; eval(str_l[0])
    when :string; str_l[0]
    when :activate; true
    when :hash
      key  = eval(str_l[0])
      value = eval(str_l[1])
      original_value = original_value.dup
      original_value[key] = value
      return original_value
    end
  end
  #--------------------------------------------------------------------------
  # method: add_to -> add itself to each given arrays
  #--------------------------------------------------------------------------
  def add_to(*args)
    args.each{|a| a.push(self)}
  end
end #Notetag_Data

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_metadata load_database; end
  def self.load_database
    load_database_metadata
    load_notetags_metadata
  end

  #--------------------------------------------------------------------------
  # alias method: load_battle_test_database -> loads map data
  #--------------------------------------------------------------------------
  class <<self; alias load_battle_test_database_metadata load_battle_test_database; end
  def self.load_battle_test_database
    load_battle_test_database_metadata
    $data_mapinfos = load_data("Data/MapInfos.rvdata2")
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_metadata
  #--------------------------------------------------------------------------
  def self.load_notetags_metadata
    SNC.prepare_metadata
    pairs = [
      [$data_actors,  SNC::DATA_ACTORS],
      [$data_classes, SNC::DATA_CLASSES],
      [$data_weapons, SNC::DATA_WEAPONS],
      [$data_armors,  SNC::DATA_ARMORS],
      [$data_enemies, SNC::DATA_ENEMIES],
      [$data_states,  SNC::DATA_STATES],
      [$data_items,   SNC::DATA_ITEMS],
      [$data_skills,  SNC::DATA_SKILLS],
      [$data_troops,  SNC::DATA_TROOPS],
      [$data_tilesets,SNC::DATA_TILESETS],
    ]
    #for any RPG::BaseItem or RPG::Troop
    pairs.each do |group,data_l|
      group.each do |obj|
        SNC.load_notetags_metadata(obj,data_l,obj.note) if obj
      end
    end
    #load map data, mapinfo will read RPG::Map notetags:
    $data_mapinfos.each_pair do |key,mapinfo|
      next unless mapinfo
      filename = sprintf("Data/Map%03d.rvdata2", key)
      #next unless File.exist?(filename)
      note = load_data(filename).note
      SNC.load_notetags_metadata(mapinfo, SNC::DATA_MAPS,note)
    end
  end
end # DataManager

#============================================================================
# RPG::BaseItem -> parent class of actor, class, skill, item, weapon, armor,
# enemy, and state.
#============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # new method: post_metadata_notetags_reading -> postprocessing
  #--------------------------------------------------------------------------
  def post_metadata_notetags_reading
  end
end #RPG::BaseItem

#============================================================================
# RPG::MapInfo -> The data class for map information
#============================================================================
class RPG::MapInfo
  #--------------------------------------------------------------------------
  # new method: post_metadata_notetags_reading -> postprocessing
  #--------------------------------------------------------------------------
  def post_metadata_notetags_reading
  end
end #RPG::MapInfo

#============================================================================
# RPG::Tileset -> The data class for tilesets
#============================================================================
class RPG::Tileset
  #--------------------------------------------------------------------------
  # new method: post_metadata_notetags_reading -> postprocessing
  #--------------------------------------------------------------------------
  def post_metadata_notetags_reading
  end
end #RPG::Tileset

#============================================================================
# RPG::Troop -> The data class for enemy troop
#============================================================================
class RPG::Troop
  #--------------------------------------------------------------------------
  # new method: note
  #--------------------------------------------------------------------------
  # Reads all comments in all pages and returns them as 'notes'
  #--------------------------------------------------------------------------
  def note
    comment_list = []
    return @notes if @notes
    for page in @pages
      next unless (page && page.list && page.list.size > 0)
      note_page = page.list.dup

      note_page.each do |item|
        next unless item && (item.code == 108 || item.code == 408)
        comment_list.push(item.parameters[0])
      end
    end
    @notes = comment_list.join("\r\n")
    return @notes
  end
  #--------------------------------------------------------------------------
  # new method: post_metadata_notetags_reading -> postprocessing
  #--------------------------------------------------------------------------
  def post_metadata_notetags_reading
  end
end #RPG::Troop

end #$imported["TIM-SimpleNotetagConfig"]
