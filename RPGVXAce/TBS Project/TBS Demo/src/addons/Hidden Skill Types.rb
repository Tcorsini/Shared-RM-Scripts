#==============================================================================
# Hidden Skill Types v1.1
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 27/02/2025
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
#==============================================================================
# Installation: put it above Main and any other script using it
#==============================================================================
# Terms of use: free for commercial and non-commercial project, credit is not mandatory
#==============================================================================

#==============================================================================
# ■ HST
#==============================================================================

module HST
  SKILL_TYPES = {}
  ITEM_TYPES = {}

  module REGEXP
    TYPE          = /<stype:\s*(\d+(?:\s*,\s*\d+)*)>/i
  end # REGEXP

  def self.item_types(item_id)
    return [0] unless ITEM_TYPES[item_id]
    return ITEM_TYPES[item_id].include?(0) ? ITEM_TYPES[item_id] : [0] + ITEM_TYPES[item_id]
  end

  def self.skill_types(skill_id)
    sid = $data_skills[skill_id].stype_id
    return [sid] unless SKILL_TYPES[skill_id]
    return SKILL_TYPES[skill_id].include?(sid) ? SKILL_TYPES[skill_id] : [sid] + SKILL_TYPES[skill_id]
  end

  def self.item_of_type?(item_id, type)
    return HST.item_types(item_id).include?(type)
  end

  def self.skill_of_type?(skill_id,type)
    return HST.skill_types(skill_id).include?(type)
  end
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
# ■ RPG::Item
#==============================================================================

class RPG::Item
  #--------------------------------------------------------------------------
  # common cache: load_notetags_jst
  #--------------------------------------------------------------------------
  def load_notetags_hst
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when HST::REGEXP::TYPE
        l = []
        $1.scan(/\d+/).each { |num| l.push(num.to_i) if num.to_i > 0 }
        HST::ITEM_TYPES[id] = l
      #---
      end
    } # self.note.split
    #---
  end
end # RPG::Item

#==============================================================================
# ■ RPG::Skill
#==============================================================================
class RPG::Skill
  #--------------------------------------------------------------------------
  # common cache: load_notetags_hst
  #--------------------------------------------------------------------------
  def load_notetags_hst
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when HST::REGEXP::TYPE
        l = []
        $1.scan(/\d+/).each { |num| l.push(num.to_i) if num.to_i > 0 }
        HST::SKILL_TYPES[id] = l
      #---
      end
    } # self.note.split
    #---
  end
end # RPG::Item
