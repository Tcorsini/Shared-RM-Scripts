#==============================================================================
# TBS Positionning Addon v1
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 06/11/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Positionning"] = true #set to false if to disable this script
if $imported["TIM-TBS-Positionning"]

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Introduce damage system based on direction of the target compared to the user
# when using abilities and a backstab system.
# Abilities can now, without using event calls, teleport to the target or
# exchange place with it
# Abilities can now push or pull the targets
# When the target is pushed towards an obstacle, it can take damage on an
# element. The push damage may depend on the amount of cells that could not be
# crossed.
#
# script calls:
# battler.push(direction,cells)  #direction is a number in 2,4,6,8 following notepad
#                                #cells is the number of cells to cross, returns the
#                                #number of cells remaining after the push
# battler.pull(direction,cells)  #same as push(d,-cells)
# battler.force_push(direction,cells) #ignore obstacles and push the battler regardless
#
#
# Notetags of ablities (skills/item):
#
# <push_damage_element: x> #set the push damage element inflicted by ability
#                          x is element id 0,1,...
# <push: x>               ability will inflict a push from x cells, x can be
#                          negative (pull effect), in the case the base attack,
#                          the push value is added with the actor, class, states,
#                          equipment or enemy's values.
# <tbs_source: caster>    source of ability (for push/pull or directionnal
#                          damage) is considered the caster's position
# <tbs_source: target>    source of ability (for push/pull or directionnal
#                          damage) is considered the targeted cell
# <tbs_dir_damage bool>   bool is either true or false, will emable/disable
#                          directionnal damage ratio based on the direction to
#                          the target, if disabled the ratio is 1. The default
#                          value is set by DIRECTIONNAL_DAMAGE
# <tbs_teleport>          ability will teleport user to targeted cell
# <tbs_exchange>          ability will exchange user and target's positions
#
# In actors, class, enemies, states, armors and weapons notetags;
# <immovable x>          x is a number (default 0), will set the resistance
#                         lvl to moving effects like swapping or pushing to x
#                         A battler always takes the highest immovable level
#                         they wear. If the level is greater or equal to
#                         PUSH_MOVE_LEVEL or SWAP_MOVE_LEVEL, then the target
#                         ignores the skill effects respectively.
#==============================================================================
# Installation: put it below TBS core
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

#==============================================================================
# TBS
#==============================================================================
module TBS
  module Positionning
    PUSH_DMG_ELEM = 0     #default element of push damage
    PUSH_EFFECT_ELEM = -1 #change this to a value >= 0 if you want the number of
                          #cells to be linked to some element resistance
                          #(not recommened)
    PUSH_SPEED = 5        #move speed of units when pushed
    DIRECTIONNAL_DAMAGE = true #default activation of

    #direcitonnal ratio when ability damages front
    FRONT_DMG_RATE = 0.8
    #direcitonnal ratio when ability damages back (except backstab)
    BACK_DMG_RATE = 1.2
    #(the actual ratio will be a value between front and back depending on the
    #angle between the user and the target's direction, see normal_dir_dmg_rate)

    #direcitonnal ratio when ability backstabs (only for base attack on the back
    #when user is next to target)
    #see backstab_ability? and backstab? methods to change the backstabbing
    #conditions
    BACKSTAB_DMG_RATE = 2 #set this to BACK_DMG_RATE if you wish to disable it

    #push damage formula with parameters:
    # a the caster,
    # b the target,
    # n the remaining push cells,
    # v the game variables
    PUSH_DMG_FORMULA = "100*n"
    #if the battler collides with another one, damage the other one too?
    PUSH_DMG_OTHERS = true

    #required immovable level to resist push
    PUSH_MOVE_LEVEL = 1
    #required immovable level to resist swap/tp
    SWAP_MOVE_LEVEL = 1

    #the push damage method, don't modify unless you know what your are doing!
    def self.push_dmg_eval(a, b, n, v)
      [Kernel.eval(PUSH_DMG_FORMULA), 0].max rescue 0
    end
  end #Positionning

  #text displayed in the battle log
  module Vocab
    PushDamage     = "%s a reçu %s dégâts de poussée !" #battler_name, push damage recieved
    BackstabToEnemy = "Backstabed!" #you can put "" if you don't want any text
    BackstabToActor = "Backstabed!" #you can put "" if you don't want any text
  end #Vocab

  module REGEXP
    PUSH = /^<push:\s*(\-*\d+)\s*>/i
    PUSH_DMG_ELEM = /^<push_damage_element:\s* (\d+)\s*>/i
    ABILITY_SRC = /^<tbs_source:\s*(caster|target)\s*>/i
    IGNORE_DIR_DMG = /^<tbs_dir_damage:\s*(true|false)\s*>/i
    TELEPORT = /^<(tbs_teleport)>/i
    EXCHANGE = /^<(tbs_exchange)>/i
    IMMOVABLE = /^<immovable (\d+)>/i
  end #REGEXP

#============================================================================
# Don't edit anything past this point unless you know what you are doing!
#============================================================================

  #============================================================================
  # MATH
  #============================================================================
  module MATH
    #--------------------------------------------------------------------------
    # new method: atk_angle -> given src, tgt two POS objects and tgt_dir a
    # direction (2,4,6,8) of the target.
    # return tbe angle in degree (0-360) relative to the target of the attack:
    #   0 is front attack
    #   90 is attack from the left
    #   180 is back attack
    #   270 is attack from the right
    #--------------------------------------------------------------------------
    def self.atk_angle(src,tgt,tgt_dir)
      diff = src-tgt #direction toward the source
      attack_angle = angle_from(*diff)
      tgt_angle = angle_from(*TBS.direction_to_delta(tgt_dir))
      #0 same ie front attack, 180 is opposite, 90 is on the left of target
      return (tgt_angle - attack_angle)%360
    end

    #--------------------------------------------------------------------------
    # new method: binomial_leq -> return probability of having at most k success
    # on a binomial distribution B(n,p)
    #--------------------------------------------------------------------------
    def self.binomial_leq(n,p,k)
      return 1.0 if k >= n
      return 0.0 if p >= 1
      x = (1-p)**n
      s = x
      #0...(k-1) ie from 1 to k when using i+1
      k.times do |i|
        x *= (n-i).to_f / (i+1) #pascal's triangle update
        x *= p / (1-p) #success update
        s += x
      end
      return s
    end

    #--------------------------------------------------------------------------
    # new method: binomial_ex_leq -> return expectancy when having at most k
    # success in binomial distribution B(n,p)
    #--------------------------------------------------------------------------
    def self.binomial_ex_leq(n,p,k)
      return n*p if k >= n
      return n if p >= 1
      x = (1-p)**n
      s = 0
      #0...(k-1) ie from 1 to k when using i+1
      k.times do |i|
        x *= (n-i).to_f / (i+1) #pascal's triangle update
        x *= p / (1-p) #success update
        s += (i+1)*x
      end
      return s
    end
  end #MATH
end #TBS

#============================================================================
# SNC from Simple Notetag Config
#============================================================================
module SNC
  #--------------------------------------------------------------------------
  # alias method: prepare_metadata
  #--------------------------------------------------------------------------
  class <<self; alias prepare_metadata_tbs_position prepare_metadata; end
  def self.prepare_metadata
    prepare_metadata_tbs_position
    Notetag_Data.new(:push, 0,  TBS::REGEXP::PUSH).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ARMORS,DATA_STATES,DATA_ENEMIES,DATA_ACTORS,DATA_CLASSES)
    Notetag_Data.new(:directionnal_dmg, TBS::Positionning::DIRECTIONNAL_DAMAGE, TBS::REGEXP::IGNORE_DIR_DMG).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:push_dmg_elem,nil,TBS::REGEXP::PUSH_DMG_ELEM).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:tbs_source,  "caster",  TBS::REGEXP::ABILITY_SRC, 1).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:tbs_swap,  false,  TBS::REGEXP::EXCHANGE, 2).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:tbs_tp,  false,  TBS::REGEXP::TELEPORT, 2).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:immovable_lvl,  0,  TBS::REGEXP::IMMOVABLE).add_to(DATA_STATES,DATA_WEAPONS,DATA_ARMORS,DATA_ENEMIES,DATA_ACTORS,DATA_CLASSES)
  end
end #SNC

#============================================================================
# RPG::UsableItem -> parent class of skills and items
#============================================================================
class RPG::UsableItem
  #--------------------------------------------------------------------------
  # alias method: post_metadata_notetags_reading
  #--------------------------------------------------------------------------
  alias post_metadata_notetags_reading_tbs_usableitem_pos post_metadata_notetags_reading
  def post_metadata_notetags_reading
    post_metadata_notetags_reading_tbs_usableitem_pos
    @tbs_source = @tbs_source.to_sym
  end
end #RPG::UsableItem

#============================================================================
# Game_Character_TBS
#============================================================================
class Game_Character_TBS < Game_Character
  attr_accessor :push_result #Game_PushResult
  #--------------------------------------------------------------------------
  # new method: tbs_play_hurt
  #--------------------------------------------------------------------------
  def tbs_push_hurt
    return unless @push_result && SceneManager.scene_is?(Scene_TBS_Battle)
    @push_result.list.each do |b,dmg|
      b.apply_push_damage(dmg)
    end
    @push_result = nil
  end
  #--------------------------------------------------------------------------
  # new method: push -> push from n tiles towards direction d, n >= 0
  #--------------------------------------------------------------------------
  def push(d,n)
    @push_result = nil
    move_route = RPG::MoveRoute.new
    move_route.repeat = false
    l = []
    l.push(RPG::MoveCommand.new(ROUTE_DIR_FIX_ON))
    l.push(RPG::MoveCommand.new(ROUTE_CHANGE_SPEED,[TBS::Positionning::PUSH_SPEED]))
    move_cmd_id = d/2
    n.times{|i| l.push(RPG::MoveCommand.new(move_cmd_id))}
    l.push(RPG::MoveCommand.new(ROUTE_CHANGE_SPEED,[@move_speed]))
    l.push(RPG::MoveCommand.new(ROUTE_DIR_FIX_OFF)) unless @direction_fix
    cmd = "tbs_push_hurt"
    l.push(RPG::MoveCommand.new(ROUTE_SCRIPT,[cmd]))
    l.push(RPG::MoveCommand.new) #end of move route
    move_route.list = l
    force_move_route(move_route)
  end
end #Game_Character_TBS

#============================================================================
# Game_Battler
#============================================================================
class Game_Battler
  #--------------------------------------------------------------------------
  # new method: move_level -> defines the level of move the ability uses
  # tbs_effect_sym is the nature of the move as a symbol in [:swap, :tp, :push]
  #--------------------------------------------------------------------------
  #return the move level
  def move_level(user,item,tbs_effect_sym)
    case tbs_effect_sym
    when :swap, :tp
      return TBS::Positionning::SWAP_MOVE_LEVEL
    when :push
      return TBS::Positionning::PUSH_MOVE_LEVEL
    end
    return 0
  end

  #--------------------------------------------------------------------------
  # new method: immovable_lvl -> defines my level of resistance to move effects
  # (move effects include swapping and pushing of abilities)
  # the level is the max among statesm, wore equipments, class, actor or enemy
  #--------------------------------------------------------------------------
  def immovable_lvl
    0
  end

  #--------------------------------------------------------------------------
  # new method: immovable? -> returns whether the battler is affected by move
  # effects of a specific level
  #--------------------------------------------------------------------------
  def immovable?(level = 0)
    immovable_lvl >= level
  end

  #--------------------------------------------------------------------------
  # new method: ability_source -> given an ability, its user and thr target of
  # the ability, returns the source of the ability, which is either the target
  # of the ability (for area effects for instance) or the position of the caster.
  # method is used for push direction and directionnal damage
  # return source as a POS object
  #--------------------------------------------------------------------------
  def ability_source(user,item,target)
    src = user.pos
    src = target if item.tbs_source == :target
    return src
  end

  #--------------------------------------------------------------------------
  # new method: directionnal_dmg? -> asks if the ability used by self does
  # damage depending on direction of targets
  #--------------------------------------------------------------------------
  def directionnal_dmg?(item)
    item.directionnal_dmg
  end

  #--------------------------------------------------------------------------
  # overwrite method: item_preview_tgt_dependant?
  #--------------------------------------------------------------------------
  def item_preview_tgt_dependant?(item)
    directionnal_dmg?(item) && item.tbs_source == :target
  end

  #===========================================================================
  # directional damage rates and backstab
  #===========================================================================

  #--------------------------------------------------------------------------
  # alias method: item_element_rate -> includes directionnal damage factor
  #--------------------------------------------------------------------------
  alias tbs_pos_item_element_rate item_element_rate
  def item_element_rate(user, item)
    r = tbs_pos_item_element_rate(user,item)
    r *= dir_damage_rate(user,item,SceneManager.scene.last_target) if SceneManager.scene_is?(Scene_TBS_Battle)
    return r
  end

  #--------------------------------------------------------------------------
  # new method: dir_damage_rate -> return factor of damage taken based on
  # direction, used to implement backstab features
  #--------------------------------------------------------------------------
  def dir_damage_rate(user,item,tgt)
    return 1.0 unless user.directionnal_dmg?(item) && user != self
    src = ability_source(user,item,tgt)
    tgt = pos
    angle = TBS::MATH.atk_angle(src,tgt,@char.direction)
    @result.backstab = backstab?(user,item,src,tgt,angle)
    return backstab_dmg_rate(user) if @result.backstab
    return normal_dir_dmg_rate(user,angle)
  end

  #--------------------------------------------------------------------------
  # new methods: right_angle?, left_angle?, front_angle?, back_angle?
  # check the relative angle of attack toward self, utility methods
  #--------------------------------------------------------------------------
  def right_angle?(rel_angle)
    (270 - rel_angle).abs < 45
  end

  def left_angle?(rel_angle)
    (90 - rel_angle).abs < 45
  end

  def front_angle?(rel_angle)
    (180 - rel_angle).abs >= 135
  end

  def back_angle?(rel_angle)
    (rel_angle - 180).abs <= 45
  end
  #--------------------------------------------------------------------------
  # new method: item_effect_backstabbed -> called during item effects if
  # backstabbed, may be used to perform additional effects
  #--------------------------------------------------------------------------
  def item_effect_backstabbed(user,item)
  end
  #--------------------------------------------------------------------------
  # new method: backstab? -> are conditions fullfilled to backstab self?
  # user (Game_Battler) is using ability (RPG::UsableItem) item from src (POS)
  # to self at tgt (POS) with relative angle (0-360)
  #--------------------------------------------------------------------------
  def backstab?(user,item,src,tgt,rel_angle)
    (src-tgt).manathan_norm <= 1 && back_angle?(rel_angle) && user.backstab_ability?(item)
  end
  #--------------------------------------------------------------------------
  # new method: backstab_ability? -> can the ability be used to backstab?
  #--------------------------------------------------------------------------
  def backstab_ability?(item)
    item == $data_skills[attack_skill_id]
  end
  #--------------------------------------------------------------------------
  # new method: normal_dir_dmg_rate -> dir damage rate applied to self by user
  # when no backstab is applied but directionnal damage is allowed
  #--------------------------------------------------------------------------
  def normal_dir_dmg_rate(user,angle)
    r = (180 - angle).abs / 180.0 #value between 0 and 1, 0 being back, 1 being front
    return (1-r)*TBS::Positionning::BACK_DMG_RATE + r*TBS::Positionning::FRONT_DMG_RATE
  end
  #--------------------------------------------------------------------------
  # new method: backstab_dmg_rate -> damage rate when user backstabs self
  #--------------------------------------------------------------------------
  def backstab_dmg_rate(user)
    TBS::Positionning::BACKSTAB_DMG_RATE
  end

  #===========================================================================
  # push effects
  #===========================================================================

  #--------------------------------------------------------------------------
  # new method: push_value -> return the push distance of the ability
  #--------------------------------------------------------------------------
  def push_value(item)
    return attack_push(item) if item == $data_skills[attack_skill_id]
    item.push
  end
  #--------------------------------------------------------------------------
  # new method: attack_push -> return the push distance of the attack skill
  # the skill is given as a parameter
  #--------------------------------------------------------------------------
  def attack_push(item)
    item.push
  end
  #--------------------------------------------------------------------------
  # new method: push_rate -> return the push factor (multiplies the push value)
  #--------------------------------------------------------------------------
  def push_rate
    elem_id = TBS::Positionning::PUSH_EFFECT_ELEM
    return 1 if elem_id < 0
    element_rate(elem_id)
  end
  #--------------------------------------------------------------------------
  # new method: push_dmg_element -> return the push element of the ability
  # used by self
  #--------------------------------------------------------------------------
  def push_dmg_element(item)
    return item.push_dmg_elem if item.push_dmg_elem
    TBS::Positionning::PUSH_DMG_ELEM
  end
  #--------------------------------------------------------------------------
  # new method: push_rate -> return the push damage
  #--------------------------------------------------------------------------
  def push_dmg_rate(user,item)
    return 0 if dead? #dead battlers are immune to push damage
    element_rate(user.push_dmg_element(item))
  end
  #--------------------------------------------------------------------------
  # new method: push -> push the battler of n tiles towards direction d
  # if n is < 0: will push in the opposite direction
  # d is a direction (2,4,6,8)
  # if there are obstacles, the push will stop at the tile right before and
  # returns the remaining tiles (0 if no obstacles met)
  #--------------------------------------------------------------------------
  def push(d,n)
    return push(TBS.reverse_dir(d),-n) if n < 0
    return 0 if n == 0
    i = furthest_push(d,n)
    force_push(d,i)
    return n-i
  end
  #--------------------------------------------------------------------------
  # new method: pull -> same as push(d,-n)
  #--------------------------------------------------------------------------
  def pull(d,n)
    push(TBS.reverse_dir(d),n)
  end
  #--------------------------------------------------------------------------
  # new method: furthest_push -> return the max number of tiles
  # from start_pos that can be pushed in direction d with max push distance n
  #--------------------------------------------------------------------------
  def furthest_push(d,n,start_pos = pos)
    prev_pos = start_pos
    mrule = MoveRule.new(move_rule_id)
    delta_pos = TBS.direction_to_delta(d)
    best_push = 0
    n.times do |i|
      nu_pos = prev_pos + delta_pos
      return best_push unless can_cross?(mrule,d,prev_pos,nu_pos)
      best_push = i+1 if can_occupy?(nu_pos)
      prev_pos = nu_pos
    end
    return best_push
  end
  #--------------------------------------------------------------------------
  # new method: force_push -> push the battler of n tiles towards direction d
  # ignores obstacles, process used by push method after calling furthest_push
  #--------------------------------------------------------------------------
  def force_push(d,n)
    return force_push(TBS.reverse_dir(d),-n) if n < 0
    @char.push(d,n)
  end
  #--------------------------------------------------------------------------
  # new method: push_damage -> given the ability user and the distance n,
  # returns the brute damage dealt by push effect to self
  #--------------------------------------------------------------------------
  def push_damage(user,n)
    TBS::Positionning.push_dmg_eval(user, self, n, $game_variables)
  end
  #--------------------------------------------------------------------------
  # new method: set_push_damage -> apply to self value damage as push damage
  # result is the Game_ActionResult storing the push data (usually original
  # target's object)
  # damage will actually be performed by apply_push_damage called when the
  # battler is done being pushed.
  #--------------------------------------------------------------------------
  def set_push_damage(value, result = @result)
    result.push.add_pushed_bat(self,value) if value > 0
  end
  #--------------------------------------------------------------------------
  # new method: apply_push_damage -> apply to self value damage as push damage
  # called by Game_Character_TBS when push effect ends
  #--------------------------------------------------------------------------
  def apply_push_damage(value)
    perform_damage_effect
    self.hp -= value
  end
  #--------------------------------------------------------------------------
  # new method: item_effect_push -> apply push effect of the ability if available
  #--------------------------------------------------------------------------
  def item_effect_push(user,item)
    return if immovable?(move_level(user,item,:push))
    dist = user.push_value(item)
    return if dist == 0 #return if no push or pull effects
    src = ability_source(user,item,SceneManager.scene.last_target)
    tgt = pos
    dir = TBS.dir_towards(src,tgt)
    dir = @char.direction if dir == 0 #only if same place as caster, ie ability on myself
    push_dist = (dist * push_rate).round
    if push_dist < 0
      dir = TBS.reverse_dir(dir)
      push_dist *= -1
    end
    @result.push.dir = dir
    @result.push.dist = push_dist
    n = push(dir, push_dist)
    return unless n > 0 #return unless collide with obstacles
    dmg = push_damage(user,n) * push_dmg_rate(user,item)
    set_push_damage(dmg.to_i)
    #damage obstacles if they are battler and module option is set
    if TBS::Positionning::PUSH_DMG_OTHERS
      collision_pos = tgt + TBS.direction_to_delta(dir)*(1+push_dist-n) #cell one step further
      batlist = $game_map.battlers_at(*collision_pos)
      batlist.each do |b|
        dmg = b.push_damage(user,n) * b.push_dmg_rate(user,item)
        b.set_push_damage(dmg.to_i, @result)
      end
    end
    @char.push_result = @result.push.dup
  end

  #===========================================================================
  # tp/swap effects
  #===========================================================================

  #--------------------------------------------------------------------------
  # new method: can_swap? -> brute check if self and other can exchange position
  #--------------------------------------------------------------------------
  def can_swap?(other)
    p1 = pos
    p2 = other.pos
    #forcemove other to my position to free their position
    other.moveto(*p1)
    r = can_occupy?(p2)
    #forcemove both of us to free my position
    moveto(*p2)
    other.moveto(*p2)
    r &&= other.can_occupy?(p1)
    moveto(*p1) #restore my position
    return r
  end

  #--------------------------------------------------------------------------
  # new method: swap -> swaps self and other, return boolean depending on
  # success, if force is false, then will check that each battler have the right
  # to be moved to the other's position (checking events and tiles...)
  #--------------------------------------------------------------------------
  def swap(other,force = false)
    p = pos
    return false unless force || can_swap?(other)
    self.moveto(*other.pos)
    other.moveto(*p)
    return true
  end
  #--------------------------------------------------------------------------
  # new method: teleport -> teleport method, a fancier moveto with checking
  #--------------------------------------------------------------------------
  def teleport(tgt,force = false)
    return false unless force || can_occupy?(tgt)
    moveto(*tgt)
    return true
  end

  #--------------------------------------------------------------------------
  # new method: item_effect_exchange -> swap user and target if available
  # only recommanded for single target abilities!
  #--------------------------------------------------------------------------
  def item_effect_exchange(user,item)
    return unless item.tbs_swap
    return if immovable?(move_level(user,item,:swap))
    user.swap(self) #same as swap(user) but I prefer the caster to initiate it
  end

  #--------------------------------------------------------------------------
  # new method: item_effect_tp -> teleports self to the target of ability
  #--------------------------------------------------------------------------
  def item_effect_tp(item)
    return unless item.tbs_tp
    return if immovable?(move_level(self,item,:tp))
    teleport(current_action.tgt_pos)
  end

  #--------------------------------------------------------------------------
  # alias method: item_apply -> adds abilities effects if in tbs and self was hit
  #--------------------------------------------------------------------------
  alias tbs_pos_item_apply item_apply
  def item_apply(user, item)
    tbs_pos_item_apply(user,item)
    return unless SceneManager.scene_is?(Scene_TBS_Battle) && @result.hit?
    item_effect_backstabbed(user,item) if @result.backstab
    item_effect_push(user,item)
    item_effect_exchange(user,item)
  end

  #--------------------------------------------------------------------------
  # alias method: tbs_post_item_effects
  #--------------------------------------------------------------------------
  alias tbs_pos_post_item_effects tbs_post_item_effects
  def tbs_post_item_effects(item,targets)
    tbs_pos_post_item_effects(item,targets)
    item_effect_tp(item)
  end
end # Game_Battler

#============================================================================
# Game_Actor
#============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # override method: attack_push
  #--------------------------------------------------------------------------
  def attack_push(item)
    p = item.push
    p = weapons.inject(p) {|r,w| r + w.push}
    p = armors.inject(p)  {|r,a| r + a.push}
    p += actor.push
    p += self.class.push
    return p
  end
  #--------------------------------------------------------------------------
  # override method: immovable_lvl
  #--------------------------------------------------------------------------
  def immovable_lvl
    l = [ actor.immovable_lvl,
          self.class.immovable_lvl,
          states.collect{|s| s.immovable_lvl}.max,
          armors.collect{|a| a.immovable_lvl}.max,
          weapons.collect{|w| w.immovable_lvl}.max].compact
    return l.max
  end
end # Game_Actor

#============================================================================
# Game_Enemy
#============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # override method: attack_push
  #--------------------------------------------------------------------------
  def attack_push(item)
    p = item.push
    p += enemy.push
    return p
  end
  #--------------------------------------------------------------------------
  # override method: immovable_lvl
  #--------------------------------------------------------------------------
  def immovable_lvl
    r = enemy.immovable_lvl
    r = [r, states.collect{|s| s.immovable_lvl}.max].max unless states.empty?
    return r
  end
end # Game_Enemy

#============================================================================
# Game_PushResult -> stores push dmg data
#============================================================================
class Game_PushResult
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :list
  attr_accessor :dist, :dir #dist a number of tiles, dir a dir4 in (2,4,6,8)
  #--------------------------------------------------------------------------
  # method: initialize
  #--------------------------------------------------------------------------
  def initialize
    clear
  end
  #--------------------------------------------------------------------------
  # method: clear
  #--------------------------------------------------------------------------
  def clear
    @dist = 0
    @dir = 0
    @list = []
  end
  #--------------------------------------------------------------------------
  # method: add_pushed_bat
  #--------------------------------------------------------------------------
  def add_pushed_bat(bat,dmg)
    @list.push([bat,dmg])
  end
  #--------------------------------------------------------------------------
  # method: damaged_bats -> returns a list of damaged battlers, not the
  # original list!
  #--------------------------------------------------------------------------
  def damaged_bats
    @list.collect{|d| d[0]}
  end
  #--------------------------------------------------------------------------
  # method: dmg_of -> easy accessor (unused)
  #--------------------------------------------------------------------------
  def dmg_of(bat)
    r = @list.find{|data| data[0] == bat}
    r = r ? r[1] : 0
    return r
  end
end #Game_PushResult

#============================================================================
# Game_ActionResult -> adds positionnal effects data
#============================================================================
class Game_ActionResult
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :push #Game_PushResult
  attr_accessor :backstab #backstab flag
  #--------------------------------------------------------------------------
  # alias method: clear_damage_values -> clear positionnal data
  #--------------------------------------------------------------------------
  alias tbs_pos_clear_damage_values clear_damage_values
  def clear_damage_values
    @push = Game_PushResult.new
    @backstab = false
    tbs_pos_clear_damage_values
  end
  #--------------------------------------------------------------------------
  # new method: push_damage_texts -> returns a list of text
  #--------------------------------------------------------------------------
  def push_damage_texts
    return @push.list.collect do |data|
      fmt = TBS::Vocab::PushDamage
      sprintf(fmt, data[0].name, data[1])
    end
  end
end # Game_ActionResult

#============================================================================
# Window_BattleLog -> adds positionnal text display
#============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: display_critical -> add backstab text if effective
  #--------------------------------------------------------------------------
  alias tbs_pos_display_critical display_critical
  def display_critical(target, item)
    if target.result.backstab
      text = target.actor? ? TBS::Vocab::BackstabToActor : TBS::Vocab::BackstabToEnemy
      unless text.empty?
        add_text(text)
        wait
      end
    end
    tbs_pos_display_critical(target,item)
  end
  #--------------------------------------------------------------------------
  # new method: display_push_damage
  #--------------------------------------------------------------------------
  def display_push_damage(target, item)
    target.result.push_damage_texts.each do |text|
      add_text(text)
      wait
    end
  end
  #--------------------------------------------------------------------------
  # alias method: display_action_results
  #--------------------------------------------------------------------------
  alias tbs_pos_display_action_results display_action_results
  def display_action_results(target, item)
    tbs_pos_display_action_results(target,item)
    display_action_push(target,item)
  end
  #--------------------------------------------------------------------------
  # new method: display_action_push
  #--------------------------------------------------------------------------
  def display_action_push(target, item)
    last_line_number = line_number
    display_push_damage(target,item)
    wait if line_number > last_line_number
    back_to(last_line_number)
  end
end #Window_BattleLog

#============================================================================
# AI_BattlerBase
#============================================================================
class AI_BattlerBase
  #--------------------------------------------------------------------------
  # new method: skill_positionnal?
  #--------------------------------------------------------------------------
  def skill_positionnal?(skill)
    @bat.directionnal_dmg?(skill) || @bat.push_value(skill) != 0
  end

  #--------------------------------------------------------------------------
  # alias method: skill_src_dependant? -> takes into account if push/pull or
  # directionnal damage effect
  #--------------------------------------------------------------------------
  alias tbs_pos_skill_src_dependant? skill_src_dependant?
  def skill_src_dependant?(skill,area)
    tbs_pos_skill_src_dependant?(skill,area) || skill_positionnal?(skill)
  end

  #--------------------------------------------------------------------------
  # new method: push_damage_expectancy
  # skill: the skill used
  # b: affected battler
  # dist: the distance of a push
  # r: the first small push the collides (0 if no such push)
  # k: the number of pushes which don't collide
  # p2: the probability of doing at most k pushes
  # expectancy: the expected push when considering only at most k pushes
  #--------------------------------------------------------------------------
  def push_damage_expectancy(skill,b,dist,r,k,p2,expectancy)
    dmg1 = b.push_damage(@bat,r) * b.push_dmg_rate(@bat,skill)
    dmg = b.push_damage(@bat,dist) * b.push_dmg_rate(@bat,skill)
    dmg1 = dmg if r == 0
    dmg_1_expectancy = (1-p2) * dmg1
    dmg_expectancy = expectancy * dmg + dmg_1_expectancy
    return dmg_expectancy
  end

  #--------------------------------------------------------------------------
  # new method: push_damage_score
  # skill: the skill used
  # b: affected battler
  # dist: the distance of a push
  # r: the first small push the collides (0 if no such push)
  # k: the number of pushes which don't collide
  # p2: the probability of doing at most k pushes
  # expectancy: the expected push when considering only at most k pushes
  #--------------------------------------------------------------------------
  def push_damage_score(skill,b,dist,r,k,p2,expectancy)
    score = push_damage_expectancy(skill,b,dist,r,k,p2,expectancy)
    score = - [score, b.hp].min.to_f / b.mhp #negative because damage
    score *= @tactic.hp #willingness to inflict damage
    score *= bat_rate_importance(b)
    score *= bat_rate_relationship(b)
    return score
  end

  #--------------------------------------------------------------------------
  # new method: result_rate_bat_push -> added to damage rating to check the
  # repositionning of the battler
  #--------------------------------------------------------------------------
  def result_rate_bat_push(skill,tgt_bat)
    return 0 if tgt_bat.immovable?(tgt_bat.move_level(@bat,skill,:push))
    dist = @bat.push_value(skill)
    return 0 unless dist != 0
    n = skill.repeats * (1 + (attack?(skill) ? @bat.atk_times_add.to_i : 0))
    p = @skill_preview[tgt_bat].touch_rate
    src = tgt_bat.ability_source(@bat,skill,@@scene.last_target)
    dir = TBS.dir_towards(src,tgt_bat.pos)
    dist = (dist * tgt_bat.push_rate).round
    if dist < 0
      dir = TBS.reverse_dir(dir)
      dist *= -1
    end
    max_dist = tgt_bat.furthest_push(dir,n*dist)
    x = n*dist - max_dist #the total push value on an opponent
    return 0 if x <= 0 #no collision
    k = max_dist / dist #how many pushes without reaching an obstacle
    r = max_dist % dist #an eventual partial push
    p2 = TBS::MATH.binomial_leq(n,p,k) #probability of not reaching an obstacle
    ex = TBS::MATH.binomial_ex_leq(n,p,k)
    expectancy = n*p - ex
    expectancy -= (1-p2)*(k+1) #remove from >k guesses the k+1 values
    score = push_damage_score(skill,tgt_bat,dist,r,k,p2,expectancy)
    #if touching another battler
    if TBS::Positionning::PUSH_DMG_OTHERS
      collision_pos = tgt_bat.pos + TBS.direction_to_delta(dir)*(1+r) #cell one step further
      batlist = $game_map.battlers_at(*collision_pos)
      batlist.each do |b|
        score += push_damage_score(skill,b,dist,r,k,p2,expectancy)
      end
    end
    return score
  end

  #--------------------------------------------------------------------------
  # alias method: result_rate_bat -> don't memories for skills with push or
  # directionnal damage effects
  #--------------------------------------------------------------------------
  alias tbs_pos_result_rate_bat result_rate_bat
  def result_rate_bat(skill,tgt_bat)
    #redo to get the right directionnal damage factor
    @rate_preview.delete(tgt_bat) if @bat.directionnal_dmg?(skill)
    r = tbs_pos_result_rate_bat(skill,tgt_bat)
    return r + result_rate_bat_push(skill,tgt_bat)
  end

  #--------------------------------------------------------------------------
  # alias method: result_rate_effects -> redo the preview for directionnal skills
  #--------------------------------------------------------------------------
  alias tbs_pos_result_rate_effects result_rate_effects
  def result_rate_effects(skill,tgt_bat)
    @skill_preview.delete(tgt_bat) if @bat.directionnal_dmg?(skill)
    return tbs_pos_result_rate_effects(skill,tgt_bat)
  end
  #TODO: add positionnal prediction for push/pull, swap and teleport
end # AI_BattlerBase

end #$imported["TIM-TBS-Positionning"]
