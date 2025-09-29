#==============================================================================
# Slash Abilties v2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 29/04/2025
# v2 alters the results of the effects by ratio
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-Slash-Abilties"] = true

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows abilities (skills or items) to damage battlers next to the original
# target.
# The effects of the ability may be nerfed or increased by a ratio depending on
# the distance.
# If the next battler in a direction is defeated or empty, pick the next one.
#==============================================================================
# Installation: put it above Main and as low as possible in your load order but
# higher than any script changing the item_effect methods in Game_Battler
#
# In skills or items notetags you may put the following comments:
# <slash: a,b,c>
# This will damage with ratio a the first target, then with ratio b the battlers 
# on the left and the right and with ratio c the battlers after.
# Example <slash: 0.8,0.3> will damage to 80% the target and 30% the battlers next to it
#
# The number of ratios after the slash command can be anything.
# Putting a 0 value as ratio means that the target will be skipped
# 
# Alternatively you may use:
# <slash_right: a,b,c,d> to only affect battlers on the right
# <slash_left: a,b,c,d> to only affect battlers on the left
# If you want asymmetrical behavior you may use the two commands above (note that a will be replaced by the last command)
#==============================================================================
# Terms of use: free for both commercial and non-commercial if you give credit
#==============================================================================

module SlashAbilities
  PARTY_SLASHED = true #if you wish slashing abilties to also affect multiple party members
  
  #choose between :zero, :ratio, :full
  #:zero will skip the effects (healing, states, buffs, stat growth) applied to additional targets
  #:full will apply the effects to their full power to the additionnal targets
  #:ratio will nerf or improve the effects based on the ratio
  #for better script compatibility, use :zero or :full as :ratio will overwrite some methods!
  EFFECTS_ON_ADDTIONNAL_TARGETS = :ratio
  
  module REGEXP
    CENTER = /<slash:\s*(\d+(\.\d+)?(\s*,\s*\d+(\.\d+)?)*)\s*>/i
    LEFT   = /<slash_left:\s*(\d+(\.\d+)?(\s*,\s*\d+(\.\d+)?)*)\s*>/i
    RIGHT  = /<slash_right:\s*(\d+(\.\d+)?(\s*,\s*\d+(\.\d+)?)*)\s*>/i
  end #REGEXP
end #SlashAbilities

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_slash load_database; end
  def self.load_database
    load_database_slash
    for data in [$data_items,$data_skills]
      data.each{|obj| obj.load_notetags_slash if obj}
    end
  end
end # DataManager

#============================================================================
# RPG::UsableItem -> store slash data for items and skills
#============================================================================
class RPG::UsableItem
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :slash_center, :slash_left, :slash_right
  #--------------------------------------------------------------------------
  # common cache: load_notetags_range_cst
  #--------------------------------------------------------------------------
  def load_notetags_slash
    @slash_center = 1
    @slash_left = []  #contains [l1,l2,l3,...]
    @slash_right = [] #contains [r1,r2,r3,...]
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when SlashAbilities::REGEXP::CENTER
        l = $1.scan(/(([0-9]*[.])?[0-9]+)/).map {|s| s[0].to_f}
        @slash_center = l.slice!(0) #remove the first value and add it to center
        @slash_left = l.dup
        @slash_right = l.dup
      when SlashAbilities::REGEXP::LEFT
        l = $1.scan(/(([0-9]*[.])?[0-9]+)/).map {|s| s[0].to_f}
        @slash_center = l.slice!(0)
        @slash_left = l.dup
      when SlashAbilities::REGEXP::RIGHT
        l = $1.scan(/(([0-9]*[.])?[0-9]+)/).map {|s| s[0].to_f}
        @slash_center = l.slice!(0)
        @slash_right = l.dup
      end
    } # self.note.split
  end
end # RPG::BaseItem

#============================================================================
# Game_BattlerBase
#============================================================================
class Game_BattlerBase
  attr_accessor :slash_ratio, :is_original_tgt
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias slash_game_batbase_init initialize
  def initialize
    @slash_ratio = 1
    @is_original_tgt = true
    slash_game_batbase_init
  end
end #Game_BattlerBase

if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS != :full
#============================================================================
# Game_Battler -> overwrites many item_effect methods
#============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # alias method: item_effect_recover_hp (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_recover_hp item_effect_recover_hp
  def item_effect_recover_hp(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_recover_hp(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    value = (mhp * effect.value1 + effect.value2) * rec
    value *= slash_ratio #added line
    value *= user.pha if item.is_a?(RPG::Item)
    value = value.to_i
    @result.hp_damage -= value
    @result.success = true
    self.hp += value
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_recover_mp (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_recover_mp item_effect_recover_mp
  def item_effect_recover_mp(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_recover_mp(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    value = (mmp * effect.value1 + effect.value2) * rec
    value *= slash_ratio #added line
    value *= user.pha if item.is_a?(RPG::Item)
    value = value.to_i
    @result.mp_damage -= value
    @result.success = true if value != 0
    self.mp += value
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_gain_tp (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_gain_tp item_effect_gain_tp
  def item_effect_gain_tp(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_recover_tp(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    #modified:
    value = effect.value1#.to_i
    value *= slash_ratio 
    value = value.to_i
    #----
    @result.tp_damage -= value
    @result.success = true if value != 0
    self.tp += value
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_add_state_attack (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_add_state_attack item_effect_add_state_attack
  def item_effect_add_state_attack(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_add_state_attack(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    user.atk_states.each do |state_id|
      chance = effect.value1
      chance *= slash_ratio #added line
      chance *= state_rate(state_id)
      chance *= user.atk_states_rate(state_id)
      chance *= luk_effect_rate(user)
      if rand < chance
        add_state(state_id)
        @result.success = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_add_state_normal (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_add_state_normal item_effect_add_state_normal
  def item_effect_add_state_normal(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_add_state_normal(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    chance = effect.value1
    chance *= slash_ratio #added line
    chance *= state_rate(effect.data_id) if opposite?(user)
    chance *= luk_effect_rate(user)      if opposite?(user)
    if rand < chance
      add_state(effect.data_id)
      @result.success = true
    end
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_remove_state (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_remove_state item_effect_remove_state
  def item_effect_remove_state(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_remove_state(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    chance = effect.value1
    chance *= slash_ratio #added line
    if rand < chance
      remove_state(effect.data_id)
      @result.success = true
    end
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_add_buff  -> do it with probability ratio
  #--------------------------------------------------------------------------
  alias slash_item_effect_add_buff item_effect_add_buff
  def item_effect_add_buff(user, item, effect)
    chance = slash_ratio
    chance = @is_original_tgt ? 1 : 0 if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
    slash_item_effect_add_buff(user,item,effect) if rand < chance
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_add_debuff (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_add_debuff item_effect_add_debuff
  def item_effect_add_debuff(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_add_debuff(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    chance = debuff_rate(effect.data_id) * luk_effect_rate(user)
    chance *= slash_ratio #added line
    if rand < chance
      add_debuff(effect.data_id, effect.value1)
      @result.success = true
    end
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_remove_buff -> do it with probability ratio
  #--------------------------------------------------------------------------
  alias slash_item_effect_remove_buff item_effect_remove_buff
  def item_effect_remove_buff(user, item, effect)
    chance = slash_ratio
    chance = @is_original_tgt ? 1 : 0 if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
    slash_item_effect_remove_buff(user,item,effect) if rand < chance
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_remove_debuff -> do it with probability ratio
  #--------------------------------------------------------------------------
  alias slash_item_effect_remove_debuff item_effect_remove_debuff
  def item_effect_remove_debuff(user, item, effect)
    chance = slash_ratio
    chance = @is_original_tgt ? 1 : 0 if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
    slash_item_effect_remove_debuff(user,item,effect) if rand < chance
  end
  #--------------------------------------------------------------------------
  # alias method: item_effect_grow (overwritten if :ratio!)
  #--------------------------------------------------------------------------
  alias slash_item_effect_grow item_effect_grow
  def item_effect_grow(user, item, effect)
    if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS == :zero
      return slash_item_effect_grow(user,item,effect) if @is_original_tgt
      return #do nothing for others
    end
    #----
    add_param(effect.data_id, (effect.value1 * slash_ratio).to_i) #modified line
    @result.success = true
  end
end #Game_Battler
end #if SlashAbilities::EFFECTS_ON_ADDTIONNAL_TARGETS != :full

#============================================================================
# Game_ActionResult -> deals with the consequences of the action
#============================================================================
class Game_ActionResult
  #--------------------------------------------------------------------------
  # alias method: make_damage -> nerf the value by ratio
  #--------------------------------------------------------------------------
  alias slash_make_damage make_damage
  def make_damage(value, item)
    slash_make_damage((value*@battler.slash_ratio).to_i,item)
  end  
end #Game_ActionResult

#============================================================================
# Game_Unit
#============================================================================
class Game_Unit
  #--------------------------------------------------------------------------
  # new method: left_of -> get the battler left of bat,
  # return nil if no battler on the left or bat is not in unit
  #--------------------------------------------------------------------------
  def left_of(bat)
    mem_id = members.index(bat)
    return nil unless mem_id && mem_id > 0
    return members[mem_id-1]
  end
  
  #--------------------------------------------------------------------------
  # new method: right_of -> get the battler right of bat,
  # return nil if no battler on the right or bat is not in unit
  #--------------------------------------------------------------------------
  def right_of(bat)
    mem_id = members.index(bat)
    return nil unless mem_id && mem_id < members.size-1
    return members[mem_id+1]
  end
end #Game_Unit

#============================================================================
# Scene Battle
#============================================================================
class Scene_Battle
  #--------------------------------------------------------------------------
  # alias method: invoke_item -> extend the effects to other targets
  #--------------------------------------------------------------------------
  alias slash_invoke_item invoke_item
  def invoke_item(target,item)
    return slash_invoke_item(target,item) if item.for_all? || (target.actor? && !SlashAbilities::PARTY_SLASHED)
    invoke_item_ratio(target,item,item.slash_center,true) #center target effect
    unit = target.actor? ? $game_party : $game_troop
    #left side
    next_target = target
    item.slash_left.each do |r|
      next_target = unit.left_of(next_target)
      next_target = unit.left_of(next_target) until next_target.nil? || valid_target?(next_target,item)
      break if next_target.nil? #no available target
      invoke_item_ratio(next_target,item,r)
    end
    #right side
    next_target = target
    item.slash_right.each do |r|
      next_target = unit.right_of(next_target)
      next_target = unit.right_of(next_target) until next_target.nil? || valid_target?(next_target,item)
      break if next_target.nil? #no available target
      invoke_item_ratio(next_target,item,r)
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: invoke_item_ratio -> invoke item with ratio nerfing the effects
  #--------------------------------------------------------------------------
  def invoke_item_ratio(target,item,ratio = 1,is_center = false)
    return if ratio <= 0 #skip 0 case
    target.slash_ratio = ratio
    target.is_original_tgt = is_center
    slash_invoke_item(target,item) #the aliased method
    #restore data
    target.is_original_tgt = true
    target.slash_ratio = 1
  end
  
  #--------------------------------------------------------------------------
  # new method: valid_target? -> return true if target is alive and item 
  # is not for dead or opposite
  #--------------------------------------------------------------------------
  def valid_target?(target,item)
    target.exist? && item.for_dead_friend? == target.dead?
  end
end #Scene_Battle