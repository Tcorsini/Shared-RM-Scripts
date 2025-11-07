#==============================================================================
# Hidden Skill Types v1.2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 28/03/2025
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-HiddenSkillTypes"] = true

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allow skills and items to have more than one type.
# Skills have their type from the database + eventual additionnal skill types
# Items have types 0 + eventual additionnal skill types
#
# This script does not do anything on its own except adding new methods and
# reading the notetags, you should use it alongside another script refering to it.
#
# To link a skill/item to its type, write in its notetag:
# <stype: a> if you link type number a
# or <stype: a,b,..> if you link more than one type
#==============================================================================
# Updates History
#------------------------------------------------------------------------------
# 27/02/2025: start and end of HST
# 28/03/2025: v1.1  bugfix for skill type reading
# 02/10/2025: v1.2  moved lists inside skills and items objects
#==============================================================================
# Installation: put it above Main and any other script using it
#==============================================================================
# Terms of use: free for commercial and non-commercial project, credit is not mandatory
#==============================================================================

#==============================================================================
# ■ HST
#==============================================================================

module HST
  module REGEXP
    TYPE          = /<stype:\s*(\d+(?:\s*,\s*\d+)*)>/i
  end # REGEXP
end #HST

#==============================================================================
# ■ DataManager
#==============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_hst load_database; end
  def self.load_database
    load_database_hst
    load_notetags_hst
  end
  #--------------------------------------------------------------------------
  # new method: load_notetags_hst
  #--------------------------------------------------------------------------
  def self.load_notetags_hst
    groups = [$data_items,$data_skills]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_hst
      end
    end
  end
end # DataManager

#==============================================================================
# ■ RPG::UsableItem
#==============================================================================
class RPG::UsableItem
  attr_accessor :stype_list
  #--------------------------------------------------------------------------
  # new method: default_stype
  #--------------------------------------------------------------------------
  def default_stype; 0; end
  #--------------------------------------------------------------------------
  # new method: has_type?
  #--------------------------------------------------------------------------
  def has_type?(stype)
    stype_list.include?(stype)
  end
  #--------------------------------------------------------------------------
  # common cache: load_notetags_jst
  #--------------------------------------------------------------------------
  def load_notetags_hst
    @stype_list = [default_stype]
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when HST::REGEXP::TYPE
        l = []
        $1.scan(/\d+/).each { |num| @stype_list.push(num.to_i) if num.to_i > 0 }
      #---
      end
    } # self.note.split
    #---
  end
end #RPG::UsableItem

#==============================================================================
# ■ RPG::Skill
#==============================================================================
class RPG::Skill
  #--------------------------------------------------------------------------
  # override method: default_stype
  #--------------------------------------------------------------------------
  def default_stype; @stype_id; end
  def stype_list; super; end
end # RPG::Skill
