#==============================================================================
# Tim's Extra Stats
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 03/11/2025
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-ExtraStats"] = true

#==============================================================================
# Version History
#------------------------------------------------------------------------------
# 03/11/2025: Original release
#==============================================================================
# Description: Adds extra stats to battlers (actors and enemies) taking
# inspiration from Nelderson's N.A.S.T.Y. Extra Stats script.
#
# You can define new stats in STATS table:
#  :stat_name => ["formula", min_value, max_value (, bfloat)],
#
# - :stat_name is the name of your new stat, use a name that is not used yet!
# - formula by default is evaluated each time the stat is seeked, it is called 
#   by a Game_Battler so a valid formula could be "hp*5 + atk - 2". You can 
#   also use level for both actors and enemies (the latter will have level 0 
#   unless you use another script with enemies level).
#   The formula value is replaced by any formula you set in your actor/class or 
#   enemy.
# - min_value is a lower bound on your final stat, if you put nil, 
#   then the stat will have no lower bound!
# - max_value is the same as min_value but for the upper_bound
# - bfloat is either true or false, if true, then your stat can have decimal 
#   values, if true then the stat will be set to an integer. Setting bfloat
#   is optionnal, by default it is false.
#
# When a stat :stat_name is defined, you can access it from battler b by using 
# script calls:
#   b.xstat(:stat_name)
# if you've set CLASS_ACCESS to true you can also use:
#   b.stat_name
#
# You can add values to the stat of battler b with script call:
#   b.add_xstat(:stat_name, value)
# if you've set CLASS_ACCESS to true you can also use:
#   b.add_stat_name(value)
#
# You can reset the added values with script call:
#   b.reset_xstat(:stat_name)
# or reset all of them with:
#   b.reset_xstats
#
# How to set extra stats:
# For actors, classes and enemies, in their notetags you can set custom base
# formula:
#
#   <xstat_base stat_name = formula>
# or
#   <xstat_base>
#     stat_name1 = formula
#     stat_name2 = formula2
#/    ...
#   </xstat_base>
#
# Examples (observe that the ':' is optional):
#    <xstat_base :str = 100*level>
#    <xstat_base wis = 10 + mhp>
#    <xstat_base> 
#       :dex = agi
#       int = mat / 5
#    </xstat_base>
#
# If you don't set a custom formula, the default one from STATS is used.
# Note that an actor's formula will take priority over their class formula
#
# You can also have actors, classes, enemies, weapons, armors and states add
# extra stats as long as they are used, they even can multiply the extra stat 
# by a ratio (multiple ratio effects are multiplicative).
#
# To add/remove a constant to a stat by a passive effect, use:
#   <xstat stat_name = v>
# or
#   <xstat>
#     stat_name1 = v
#     stat_name2 = v
#/    ...
#   </xstat>
# v here is an int, positive or negative like -2, 5, 0
#
# To put a ratio, use:
#   <xstat_rate stat_name = v>
# or
#   <xstat_rate>
#     stat_name1 = v
#     stat_name2 = v
#/    ...
#   </xstat_rate>
# v here is a non-negative int or float value, like 5, 0 or 1.2
#
# Examples (once again, the ':' is optional):
#    <xstat :str = -4>
#    <xstat_rate wis = 1.5>
#    <xstat> 
#       :dex = 3
#       int = -1
#    </xstat>
#    <xstat_rate> 
#       :dex = 0.5
#       int = 0
#    </xstat_rate>
#==============================================================================
# Term of use: Free to use in free or commercial games if you give credit
#==============================================================================
# Installation & Compatibility: put the script above main, this script is not
# compatible with N.A.S.T.Y. Extra Stats!
# You should start a new game for the script to work properly! Changing stats 
# list mid-playthrough should be fine.
#==============================================================================

#==============================================================================
# Configuration
#==============================================================================
module TIM
  module ExtraStats
    #set this to true if you want to access the extra stat :extra of a battler 
    #b by using b.extra instead of b.xstat(:extra), it will also create a 
    #method b.add_extra(v) which can replace b.add_xstat(:extra,v)
    #use this only if all your added stats have a key that is not a preexisting
    #method for battlers! (or if you want to replace these methods somehow)
    CLASS_ACCESS = true
    
    #set your extra stats here:
    STATS = {
      #:stat_name => ["formula", min_value, max_value (, bfloat)], 
      #formula can use the battler's stats such as level, enemy level is 0 
      #        unless level is already defined by another script
      #setting min_value or max_value to nil 
      #        means the stat has no min (or max) value
      #bfloat is an optionnal boolean: 
      #       -true if you want your stat to be a float, 
      #       -false (default) if you want it to be an int
      :str => ["10*(level+1)",0,999],
      :wis => ["5 + mat.to_f / 10",nil,10000,true],
    } #don't remove this!
    
#============================================================================
# Don't edit anything past this point unless you know what you are doing!
#============================================================================

    module REGEXP
      #single line
      XSTAT_BASE    =  /<xstat_base\s+:?(\S+)\s*=\s*(.+)>/i
      XSTAT         =  /<xstat\s+:?(\S+)\s*=\s*(-?\d+)>/i
      XSTAT_RATE    =  /<xstat_rate\s+:?(\S+)\s*=\s*(\d+(\.\d+)?)>/i
      
      #multi line
      XSTAT_BASE_S  =  /<xstat_base>/i
      XSTAT_BASE_E  =  /<\/xstat_base>/i
      XSTAT_S       =  /<xstat>/i
      XSTAT_E       =  /<\/xstat>/i
      XSTAT_RATE_S  =  /<xstat_rate>/i
      XSTAT_RATE_E  =  /<\/xstat_rate>/i
      
      #inside environment
      XSTAT_BASE_SET     = /\s*:?(\S+)\s*=\s*(.+)/i
      XSTAT_SET          = /\s*:?(\S+)\s*=\s*(-?\d+)/i
      XSTAT_RATE_SET     = /\s*:?(\S+)\s*=\s*(\d+(\.\d+)?)/i
    end #REGEXP
  end #ExtraStats
end #TIM

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_tim_xstats load_database; end
  def self.load_database
    load_database_tim_xstats
    load_notetags_tim_xstats
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_tim_xstats
  #--------------------------------------------------------------------------
  def self.load_notetags_tim_xstats
    #set base formula to actors, classes and enemies
    base_groups = [$data_actors,$data_classes,$data_enemies]
    base_groups.each{|g| g.each{|o| o.load_xstat_base if o}}
    #allow extra stats and rate to actors, classes, enemies, weapons, armors 
    #and states
    all_groups = base_groups + [$data_weapons,$data_armors,$data_states]
    all_groups.each do |g| 
      g.each do |o| 
        next unless o
        o.load_xstat
        o.load_xstat_rate
      end
    end
  end
end # DataManager

#==============================================================================
# RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # new method: load_xstat
  #--------------------------------------------------------------------------
  def load_xstat
    @xstat = {}
    multi = false #multi stat flag
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::ExtraStats::REGEXP::XSTAT
        unless multi
          sym = $1.to_sym
          @xstat[sym] = $2.to_i
        end
      when TIM::ExtraStats::REGEXP::XSTAT_S
        multi = true
      when TIM::ExtraStats::REGEXP::XSTAT_E
        multi = false
      when TIM::ExtraStats::REGEXP::XSTAT_SET
        if multi
          sym = $1.to_sym
          @xstat[sym] = $2.to_i
        end
      end
    } # self.note.split
  end
  #--------------------------------------------------------------------------
  # new method: load_xstat_base
  #--------------------------------------------------------------------------
  def load_xstat_base
    @xstat_base = {}
    multi = false #multi stat flag
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::ExtraStats::REGEXP::XSTAT_BASE
        unless multi
          sym = $1.to_sym
          @xstat_base[sym] = $2
        end
      when TIM::ExtraStats::REGEXP::XSTAT_BASE_S
        multi = true
      when TIM::ExtraStats::REGEXP::XSTAT_BASE_E
        multi = false
      when TIM::ExtraStats::REGEXP::XSTAT_BASE_SET
        if multi
          sym = $1.to_sym
          @xstat_base[sym] = $2
        end
      end
    } # self.note.split
  end
  #--------------------------------------------------------------------------
  # new method: load_xstat_rate
  #--------------------------------------------------------------------------
  def load_xstat_rate
    @xstat_rate = {}
    multi = false #multi stat flag
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::ExtraStats::REGEXP::XSTAT_RATE
        unless multi
          sym = $1.to_sym
          @xstat_rate[sym] = $2.to_f
        end
      when TIM::ExtraStats::REGEXP::XSTAT_RATE_S
        multi = true
      when TIM::ExtraStats::REGEXP::XSTAT_RATE_E
        multi = false
      when TIM::ExtraStats::REGEXP::XSTAT_RATE_SET
        if multi
          sym = $1.to_sym
          @xstat_rate[sym] = $2.to_f
        end
      end
    } # self.note.split
  end
  #--------------------------------------------------------------------------
  # new method: xstat
  #--------------------------------------------------------------------------
  def xstat(symb)
    @xstat[symb] || 0
  end
  #--------------------------------------------------------------------------
  # new method: xstat_base
  #--------------------------------------------------------------------------
  def xstat_base(symb)
    @xstat_base[symb]
  end
  #--------------------------------------------------------------------------
  # new method: xstat_rate
  #--------------------------------------------------------------------------
  def xstat_rate(symb)
    @xstat_rate[symb] || 1.0
  end
end #RPG::BaseItem

#==============================================================================
# Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # new methods for each extra stat
  # example: stat with symbol :str will set methods str and add_str(value)
  #--------------------------------------------------------------------------
  if TIM::ExtraStats::CLASS_ACCESS
    TIM::ExtraStats::STATS.keys.each do |symb| 
      define_method(symb){xstat(symb)}
      define_method("add_#{symb}"){|v| add_xstat(symb,v)}
    end
  end
  #--------------------------------------------------------------------------
  # alias method: clear_param_plus
  #--------------------------------------------------------------------------
  alias tim_xstats_clear_param_plus clear_param_plus
  def clear_param_plus
    tim_xstats_clear_param_plus
    reset_xstats
  end
  #--------------------------------------------------------------------------
  # new method: xstat -> similar to method param but for extra stats
  #--------------------------------------------------------------------------
  def xstat(symb)
    #first line is optional, avoids weird behavior if you call an undefined stat
    raise "Undefined xstat #{symb.to_s}" unless TIM::ExtraStats::STATS[symb]
    value = xstat_base(symb) + xstat_plus(symb)
    value *= xstat_rate(symb)
    _, min_v, max_v, bfloat = TIM::ExtraStats::STATS[symb]
    value = [value, max_v].min if max_v
    value = [value, min_v].max if min_v
    value = value.to_i unless bfloat
    return value
  end
  #--------------------------------------------------------------------------
  # new method: add_xstat -> similar to method add_param
  #--------------------------------------------------------------------------
  def add_xstat(symb,v)
    @xstats_plus[symb] ||= 0 #set to 0 if not defined
    @xstats_plus[symb] += v
    refresh
  end
  #--------------------------------------------------------------------------
  # new method: xstat_base -> similar to method param_base
  #--------------------------------------------------------------------------
  def xstat_base(symb)
    formula = TIM::ExtraStats::STATS[symb][0]
    eval(formula)
  end
  #--------------------------------------------------------------------------
  # new method: xstat_base -> similar to method param_plus
  #--------------------------------------------------------------------------
  def xstat_plus(symb)
    v = @xstats_plus[symb] ||= 0 #set to 0 if not defined, return the value
    states.inject(v){|r,s| r += s.xstate(symb)}
  end
  #--------------------------------------------------------------------------
  # new method: xstat_base -> similar to method param_rate
  #--------------------------------------------------------------------------
  def xstat_rate(symb)
    states.inject(1.0){|r,s| r *= s.xstate_rate(symb)}
  end
  #--------------------------------------------------------------------------
  # new method: reset_xstats -> clear a specific additionnal parameter
  #--------------------------------------------------------------------------  
  def reset_xstat(symb)
    @xstats_plus[symb] = 0
  end
  #--------------------------------------------------------------------------
  # new method: reset_xstats -> clear all addiitonnal parameters
  #--------------------------------------------------------------------------  
  def reset_xstats
    @xstats_plus = {}
    TIM::ExtraStats::STATS.keys.each do |symb|
      @xstats_plus[symb] = 0
    end
  end
end #Game_BattlerBase

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # override method: xstat_base -> gets the actor's or their class stats if 
  # they exist
  #--------------------------------------------------------------------------
  def xstat_base(symb)
    formula = actor.xstat_base(symb)
    return eval(formula) if formula
    formula = self.class.xstat_base(symb)
    return eval(formula) if formula
    super
  end
  #--------------------------------------------------------------------------
  # override method: xstat_plus -> gets the enemy's stats if they exist
  #--------------------------------------------------------------------------
  def xstat_plus(symb)
    r = equips.compact.inject(super){|r,e| r += e.xstat(symb)}
    r += actor.xstat(symb)
    r += self.class.xstat(symb)
  end
  #--------------------------------------------------------------------------
  # override method: xstat_rate -> gets the enemy's stats if they exist
  #--------------------------------------------------------------------------
  def xstat_rate(symb)
    r = equips.compact.inject(super){|r,e| r *= e.xstat_rate(symb)}
    r *= actor.xstat_rate(symb)
    r *= self.class.xstat_rate(symb)
  end
end #Game_Enemy

#==============================================================================
# Game_BattlerBase
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # new method: level -> set it to 0 if method does not exists
  #--------------------------------------------------------------------------
  unless method_defined?(:level); def level; 0; end; end
  #--------------------------------------------------------------------------
  # override method: xstat_plus -> gets the enemy's added stats if they exist
  #--------------------------------------------------------------------------
  def xstat_plus(symb)
    super + enemy.xstat(symb)
  end
  #--------------------------------------------------------------------------
  # override method: xstat_base -> gets the enemy's stats if they exist
  #--------------------------------------------------------------------------
  def xstat_base(symb)
    formula = enemy.xstat_base(symb)
    return eval(formula) if formula
    super
  end
end #Game_Enemy