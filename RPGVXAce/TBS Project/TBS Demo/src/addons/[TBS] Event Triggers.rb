#==============================================================================
# TBS Event Triggers v1.2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 09/04/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
raise "TBS Event Triggers requires TBS by Timtrack" unless $imported["TIM-TBS"]
$imported["TIM-TBS-EventTriggers"] = true #set to false if you wish to disable the modifications

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 29/03/2025: first version
# 03/04/2025: events are now linked to battlers when calling on_battle_start
#             instead of tbs_entrance, turn_start events trigger after count update
# 09/04/2025: now supports help_window from core v0.7
#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows some events on the map to be called and interacted with on specific
# battler situations, all events must be a tbs_event for the following features
# to work:
#
# You may add the following comments in events:
#
# If a battler starts the battle here, the event will be attached to the battler:
# <tbs_follow_bat>
#
# Any battler around the event skill range will get the skill,
# you may forbid some battler to get the skill by disactivating
# the skill type or the skill itself:
# <tbs_give_skill> x
#
# You may link a team or a move_type to an event for crossing rules:
# <tbs_team> id
# <tbs_move_type> move_type
# ex:
# <tbs_team> 2
# <tbs_move_type> :ground
#
# Event pages can store subparts triggering under some conditions.
# The list of triggers is in two parts:
#
# Global triggers (like troop events):
# On global turn start (exactly like troop triggers on turn starts)
# <tbs_on_turn_start>
# On battler turn start (each time a battler starts its local turn)
# <tbs_on_bat_turn_start>
# On battler turn end (each time a battler ends its local turn)
# <tbs_on_bat_turn_end>
# On battler add a state
# <tbs_on_bat_add_state>
# The data of the triggers (battler, state got) are stored in @trigger_params
# to catch by the interpreter.
#
# Local triggers (relative to the event)
# On cursor ok (each time the user press the ok button on this event during cursor select or place modes)
# <tbs_on_cursor_ok>
# On battler reach  (each time a battler reaches the position of this event, won't work on follow bat)
# <tbs_on_bat_reach>
# On battler leave (each time a battler leaves the position of this event, won't work on follow bat)
# <tbs_on_bat_leave>
# On skill (each time a specific skill's area touches this event)
# <tbs_on_skill_here> x
# On item (each time a specific item's area touches this event)
# <tbs_on_item_here> x
#
# All triggers (Global and Local) must be closed by the following comment:
# </tbs>
# Your event's page should look like this:
#
# Comment: <tbs_trigger>
# Instructions
# Comment: </tbs>
# ...
# Comment: <tbs_trigger2>
# Instructions
# Comment: </tbs>
# ...
#
# Anything between the tbs_trigger and </tbs> will run only if such trigger is
# activated during tbs battle.
# Instructions outside will run only if the event is called in a vanilla way.
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================
# Changes
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#   Requires TBS Core and its dependency
#
#   Modified classes:
#   class Game_Interpreter
#     new attribute: trigger_params
#   class Game_Troop < Game_Unit
#     alias method: setup_battle_event
#   class Game_Battler < Game_BattlerBase
#     overwrite method: can_cross_ev?
#     alias methods: add_new_state, on_battle_start
#     new methods: get_event_skills, event_friend_status(event)
#   class Game_Map
#     new attributes: global_triggers, waiting_events
#     alias methods: setup, refresh
#     new methods: init_global_triggers, call_tbs_event(list,event_id,params),call_triggers(key,params)
#   class Game_Event < Game_Character
#     new attributes: battler, tbs_move_type, team
#     new attribute(private): triggers
#     alias methods: update, refresh
#     new methods: triggers, link_on_start?, link_to_bat(bat), read_triggers
#   class Game_Action
#     new attribute: affected_events
#     alias methods: set_target, property_valid?, call_additional_tbs_effects
#     new method: call_events_triggers
#     overwrite method: event?
#   module BattleManager
#     alias method: turn_start
#   class Scene_TBS_Battler < Scene_Base
#     alias methods: on_turn_end, on_turn_start,
#                    on_cursor_ok, create_tbs_actor_command_window
#     new method: command_event_skill
#   class Game_Character_TBS < Game_Character
#     new attributes (private): @last_moving, @prev_pos
#     alias methods: update, update_tbs_move
#     new methods: on_leave(prev_pos), on_reach
#   class Window_TBS_ActorCommand < Window_ActorCommand
#     alias methods: add_custom_commands, draw_item, update_help
#     new methods: add_event_skill_command(sid), draw_skill(index,sid),
#                  draw_skill_name(item, x, y, enabled, width),
#                  draw_skill_cost(rect,skill,enabled), allow_extra_skill?(skill_id)
#
#   New classes/modules:
#   module TBS
#      introduces submodules EVENTS and TRIGGERS
#   class TBS_PageData
#      stores event's page triggers and other tbs data
#==============================================================================

if $imported["TIM-TBS-EventTriggers"]

module TBS
  #The text color used to display added skills
  ADDED_SKILL_COLOR = 3
  #If set to true, will display the skill as if it was from the Skill Menu with
  #icon and cost, else, will only display its name.
  DRAW_SKILL_ICONS = false

  module EVENTS
    DEFAULT_MOVE_TYPE = :wall
    DEFAULT_TEAM = TEAMS::TEAM_NEUTRALS
    #set to false if you don't want a following event to react to its battler
    #moving, else, it will trigger each cell the battler moves to
    FOLLOW_TRIGGERS_REACH_LEAVE_SELF = false
    #if at the start of battle, the battler is here, then the event WILL follow the battler forever
    FOLLOW_BATTLER = "<tbs_follow_bat>"
    #will give skill x to the battlers in the range of the skill,
    #the skill will appear as a custom command
    #if the battlers leave the range the skill is removed from them.
    GIVE_SKILL = "<tbs_give_skill>" #x
    #team
    TEAM = "<tbs_team>" #x
    #move_type
    MOVE_TYPE = "<tbs_move_type>" #x
  end #EVENTS

  module TRIGGERS
    #Triggers are list of commands run under specific conditions in tbs battles
    #when the map is loaded or the events are refreshed, the system will take
    #every command between <tbs cmd> and </tbs> in event comments, remove them from
    #the event and store them elsewhere when the event is triggered
    #
    #You may have multiple triggers in the same event page but:
    #-try to keep a low number of global triggers, the more, the slower the system will run
    #-DO NOT stack the triggers in the event page, start a trigger, end it, start the next one etc.
    #-don't try to leave the event commands inside a trigger with gotos and labels, this behavior is not supported
    module GLOBAL
      #when a global turn starts
      ON_GLOBAL_TURN_START = "<tbs_on_turn_start>"
      #when any battler starts its turn
      ON_BATTLER_TURN_START = "<tbs_on_bat_turn_start>" #data: bat
      #when any battler ends its turn
      ON_BATTLER_TURN_END = "<tbs_on_bat_turn_end>" #data: bat
      #when any battler gets a state
      ON_BATTLER_ADD_STATE = "<tbs_on_bat_add_state>" #data: bat, state
    end #GLOBAL

    module LOCAL
      #if the cursor in select/place mode clicks on this event,
      #triggers before the battler selection if any
      ON_CURSOR_OK = "<tbs_on_cursor_ok>"
      #when a battler reaches this event
      ON_BATTLER_REACH = "<tbs_on_bat_reach>" #data: bat
      #when a battler leaves this event
      ON_BATTLER_LEAVE = "<tbs_on_bat_leave>" #data: bat
      #when skill %d is cast upon this cell (among others)
      ON_SKILL = "<tbs_on_skill_here>" # sid
      #when item %d is cast upon this cell
      ON_ITEM = "<tbs_on_item_here>" # iid
    end #LOCAL
    #anything past this point will be ignored by the current trigger
    TRIGGER_END = "</tbs>"
  end #TRIGGERS

  #Don't edit anything past this point
  EVENT_KEYS = [:follow,:getskill,:gts,:bts,:bte,:bas,:cok,:reach,:leave,:skill,:item,:end]
  EVENT_COMMENTS_TRIGGERS = {
    :follow   => EVENTS::FOLLOW_BATTLER,
    :getskill => EVENTS::GIVE_SKILL, #param
    :team     => EVENTS::TEAM, #param
    :mtype    => EVENTS::MOVE_TYPE, #param
    :gts      => TRIGGERS::GLOBAL::ON_GLOBAL_TURN_START,
    :bts      => TRIGGERS::GLOBAL::ON_BATTLER_TURN_START,
    :bte      => TRIGGERS::GLOBAL::ON_BATTLER_TURN_END,
    :bas      => TRIGGERS::GLOBAL::ON_BATTLER_ADD_STATE,
    :cok      => TRIGGERS::LOCAL::ON_CURSOR_OK,
    :reach    => TRIGGERS::LOCAL::ON_BATTLER_REACH,
    :leave    => TRIGGERS::LOCAL::ON_BATTLER_LEAVE,
    :skill    => TRIGGERS::LOCAL::ON_SKILL, #param
    :item     => TRIGGERS::LOCAL::ON_ITEM, #param
    :end      => TRIGGERS::TRIGGER_END,
  }
  GLOBAL_TRIGGERS_KEYS = [:gts,:bts,:bte,:bas]
  EVENT_NO_END = [:follow,:getskill,:team,:mtype]
  EVENT_WITH_PARAM = [:skill,:item]
end #TBS

#==========================================================================
# Game_Interpreter -> adds an array of parameters to read by trigger events
#==========================================================================
class Game_Interpreter
  attr_accessor :trigger_params #to access more info from the triggers
end

#==========================================================================
# Game_Troop -> supports a waiting list of events that are triggers
#==========================================================================
class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # alias method: setup_battle_event -> loads triggers before common events
  #--------------------------------------------------------------------------
  alias tbs_trigger_setup_battle_event setup_battle_event
  def setup_battle_event
    return if @interpreter.running?
    v = $game_map.waiting_events.pop
    if v
      interpreter.trigger_params = v[2]
      interpreter.setup(v[0],v[1])
    end
    tbs_trigger_setup_battle_event
  end
end #Game_Troop

#==========================================================================
# Game_Battler -> catch the skills added by events
#==========================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # new method: get_event_skills -> return the skills added by surrounding tbs events
  #--------------------------------------------------------------------------
  def get_event_skills
    added_skills = []
    for ev in $game_map.tbs_events
      for skill_id in ev.give_skill_list
        data = TBS.skill_range(skill_id)
        r2 = data.each_slice(4).to_a
        spellRg = SpellRange.new(r2[0],r2[1])
        range = TBS.getTargetsList(self,POS.new(ev.x,ev.y),spellRg)
        added_skills.push(skill_id) if $game_map.in_range?(range,pos.x,pos.y)
      end
    end
    return added_skills.uniq
  end
  #--------------------------------------------------------------------------
  # new method: true_friend_status -> checks the relationship with another battler
  #--------------------------------------------------------------------------
  def event_friend_status(event)
    return TBS::SELF if event.battler == self
    return TBS::TEAMS.friend_status(@team, event.team)
  end
  #--------------------------------------------------------------------------
  # overwrite method: can_cross_ev? -> now reads the event move type
  #--------------------------------------------------------------------------
  def can_cross_ev?(moveRule,dir,event)
    return true if !event.normal_priority?
    other_move_type = event.tbs_move_type
    case event_friend_status(event)
    when TBS::ENEMY
      return moveRule.cross_enemies.include?(other_move_type)
    when TBS::NEUTRAL
      return moveRule.cross_neutrals.include?(other_move_type)
    when TBS::FRIENDLY
      return moveRule.cross_allies.include?(other_move_type)
    when TBS::SELF
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # alias method: add_new_state -> triggers the proper events
  #--------------------------------------------------------------------------
  alias tbs_te_add_new_state add_new_state
  def add_new_state(state_id)
    $game_map.call_triggers(:bas,[self,state_id]) if SceneManager.scene_is?(Scene_TBS_Battle)
    tbs_te_add_new_state(state_id)
  end
  #--------------------------------------------------------------------------
  # alias method: on_battle_start -> links the event to the battler
  #--------------------------------------------------------------------------
  alias trigger_on_battle_start on_battle_start
  def on_battle_start
    trigger_on_battle_start
    evList = $game_map.battle_events_at(pos.x,pos.y).select{|ev| ev.link_on_start? && ev.battler.nil?}
    evList.each{|ev| ev.link_to_bat(self)}
  end
end #Game_Battler


#==========================================================================
# BattleManager -> calls turn_start triggers
#==========================================================================
class << BattleManager
  alias tbs_trigger_bm_turn_start turn_start
end
module BattleManager
  def self.turn_start
    tbs_trigger_bm_turn_start
    $game_map.call_triggers(:gts)
  end
end

#==========================================================================
# Scene_TBS_Battle -> calls the right triggers at the right time
#==========================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: create_tbs_actor_command_window -> catch the skills added by events
  #--------------------------------------------------------------------------
  alias tbs_trigger_create_tbs_actor_command_window create_tbs_actor_command_window
  def create_tbs_actor_command_window
    tbs_trigger_create_tbs_actor_command_window
    @actor_command_window.set_handler(:event_skill,   method(:command_event_skill))
  end
  #--------------------------------------------------------------------------
  # new method: command_event_skill -> when an event's skill is selected, same behavior as guard
  #--------------------------------------------------------------------------
  def command_event_skill
    @actor_command_window.close
    bat = BattleManager.actor
    skill_id = @actor_command_window.current_ext
    bat.input.set_skill(skill_id)
    l = bat.genTgt(bat.getRange(skill_id,:skill))
    type2 = $data_skills[skill_id].for_friend? ? :help_skill : :skill
    @spriteset.draw_range(l,TBS.spriteType(type2))
    @cursor.set_skill_data(bat, l)
    @cursor.menu_skill = true #to return to menu when cancelling
    activate_cursor(:skill)
    @cursor.moveto_bat(bat)
  end
  #--------------------------------------------------------------------------
  # alias method: on_cursor_ok -> for click triggers
  #--------------------------------------------------------------------------
  alias trigger_on_cursor_ok on_cursor_ok
  def on_cursor_ok
    if @cursor.mode == :select
      evList = $game_map.battle_events_at(@cursor.x,@cursor.y).select{|ev| ev.triggers[:cok]}
      evList.each{|ev| $game_map.call_tbs_event(ev.triggers[:cok],ev.id)}
      @interaction = true unless evList.empty?
    end
    trigger_on_cursor_ok
  end
  #--------------------------------------------------------------------------
  # alias method: on_turn_start -> call local turn start triggers
  #--------------------------------------------------------------------------
  alias trigger_on_turn_start on_turn_start
  def on_turn_start(bat)
    $game_map.call_triggers(:bts,[bat]) unless bat.obstacle?
    process_event
    trigger_on_turn_start(bat)
  end
  #--------------------------------------------------------------------------
  # alias method: on_turn_end -> call local turn end triggers
  #--------------------------------------------------------------------------
  alias trigger_on_turn_end on_turn_end
  def on_turn_end(bat)
    $game_map.call_triggers(:bte,[bat]) unless bat.obstacle?
    process_event
    trigger_on_turn_end(bat)
  end
end #Scene_TBS_Battle

#==========================================================================
# Game_Map -> stores the global triggers and a waiting list of triggers to be run by troop's interpreter
#==========================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :global_triggers
  attr_reader :waiting_events
  #--------------------------------------------------------------------------
  # alias method: setup
  #--------------------------------------------------------------------------
  alias tbs_et_gm_setup setup
  def setup(map_id)
    @waiting_events = []
    init_global_triggers
    tbs_et_gm_setup(map_id)
    @events.each_value {|event|  event.read_triggers} #if SceneManager.scene_is?(Scene_TBS_Battle)
  end
  #--------------------------------------------------------------------------
  # alias method: refresh
  #--------------------------------------------------------------------------
  alias tbs_et_gm_refesh refresh
  def refresh
    init_global_triggers
    tbs_et_gm_refesh
  end
  #--------------------------------------------------------------------------
  # new method: init_global_triggers
  #--------------------------------------------------------------------------
  def init_global_triggers
    @global_triggers = {}
    for key in TBS::GLOBAL_TRIGGERS_KEYS
      @global_triggers[key] = {}
    end
  end
  #--------------------------------------------------------------------------
  # new method: call_tbs_event
  #--------------------------------------------------------------------------
  def call_tbs_event(list,event_id=0, params = [])
    @waiting_events.push([list,event_id,params])
  end
  #--------------------------------------------------------------------------
  # new method: call_trigger
  #--------------------------------------------------------------------------
  def call_triggers(trigger_key,params = [])
    @global_triggers[trigger_key].each_pair do |key, value|
      call_tbs_event(value, key, params) #key is event id, value is a list
    end
  end
end #Game_Map

#==========================================================================
# TBS_PageData -> a new class storing its event's triggers and other things
# page related
#==========================================================================
#stores a list of event commands to run when specific conditions are met
class TBS_PageData
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :follow_bat, :give_skill_list, :triggers, :move_type, :team
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(event_id)
    @id = event_id
    @move_type = TBS::EVENTS::DEFAULT_MOVE_TYPE
    @team = TBS::EVENTS::DEFAULT_TEAM
    @follow_bat = false
    @give_skill_list = []
    @triggers = {}
    for k in TBS::EVENT_WITH_PARAM
      @triggers[k] = {}
    end
  end
  #--------------------------------------------------------------------------
  # set_global_trigger
  #--------------------------------------------------------------------------
  def set_global_trigger
    for k in TBS::GLOBAL_TRIGGERS_KEYS
      $game_map.global_triggers[k][@id] = @triggers[k] if @triggers[k]
    end
  end
end #TBS_PageData


#==========================================================================
# Game_Character_TBS -> catch battle events triggered by moving
#==========================================================================
class Game_Character_TBS < Game_Character
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias trigger_gct_update update
  def update
    @last_moving = moving?
    @prev_pos = [@x,@y]
    trigger_gct_update
  end

  #--------------------------------------------------------------------------
  # alias method: update_tbs_move
  #--------------------------------------------------------------------------
  alias trigger_update_tbs_move update_tbs_move
  def update_tbs_move
    on_reach if !moving? && @last_moving
    trigger_update_tbs_move
    on_leave(@prev_pos) if moving? && !@last_moving
  end

  #--------------------------------------------------------------------------
  # new method: on_leave -> when the unit leaves a cell
  #--------------------------------------------------------------------------
  def on_leave(prev_pos)
    evList = $game_map.battle_events_at(prev_pos[0],prev_pos[1]).select{|ev| ev.triggers[:leave]}
    evList.select!{|ev| ev.battler != @battler} unless TBS::EVENTS::FOLLOW_TRIGGERS_REACH_LEAVE_SELF
    evList.each{|ev| $game_map.call_tbs_event(ev.triggers[:leave],ev.id)}
    SceneManager.scene.process_event if SceneManager.scene_is?(Scene_TBS_Battle)
  end

  #--------------------------------------------------------------------------
  # new method: on_reach -> when the unit reaches a cell
  #--------------------------------------------------------------------------
  def on_reach
    evList = $game_map.battle_events_at(@x,@y).select{|ev| ev.triggers[:reach]}
    evList.select!{|ev| ev.battler != @battler} unless TBS::EVENTS::FOLLOW_TRIGGERS_REACH_LEAVE_SELF
    evList.each{|ev| $game_map.call_tbs_event(ev.triggers[:reach],ev.id)}
    SceneManager.scene.process_event if SceneManager.scene_is?(Scene_TBS_Battle)
  end
end #Game_Character_TBS

#==========================================================================
# Game_Event -> read the comments to check what triggers exist
#==========================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :battler #battler this event is linked to if you use the option
  attr_accessor :tbs_move_type
  attr_accessor :team
  #--------------------------------------------------------------------------
  # new method: give_skill_list
  #--------------------------------------------------------------------------
  def give_skill_list
    @triggers[@list].give_skill_list
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias tbs_trigger_event_update update
  def update
    tbs_trigger_event_update
    if @battler
      pos = @battler.pos
      #puts sprintf("%d follows %s in [%d,%d]", @id, @battler.name, pos.x,pos.y) unless pos == [x,y]
      moveto(pos.x,pos.y) unless pos == [x,y]
    end
  end
  #--------------------------------------------------------------------------
  # new method: triggers
  #--------------------------------------------------------------------------
  def triggers
    @triggers[@list].triggers
  end
  #--------------------------------------------------------------------------
  # new method: link_on_start?
  #--------------------------------------------------------------------------
  def link_on_start?
    return @triggers[@list].follow_bat if @triggers
  end
  #--------------------------------------------------------------------------
  # new method: link_to_bat
  #--------------------------------------------------------------------------
  def link_to_bat(bat)
    @battler = bat
  end
  #--------------------------------------------------------------------------
  # alias method: refresh
  #--------------------------------------------------------------------------
  alias tbs_et_ge_refresh refresh
  def refresh
    tbs_et_ge_refresh
    read_triggers #if SceneManager.scene_is?(Scene_TBS_Battle)
  end
  #--------------------------------------------------------------------------
  # new method: read_triggers -> takes every command between the comments,
  # remove them from the event page and store them in another object until the right moment
  #--------------------------------------------------------------------------
  def read_triggers
    @triggers = {} unless @triggers
    unless @triggers.has_key?(@list)
      tbs_trigger = TBS_PageData.new(@id)
      nread_page = true
      start = 0
      while nread_page && @list
        a,b,k,value = nil,nil,nil,nil
        for i in start...@list.size
          nread_page = false if i >= @list.size-1
          command = @list[i]
          next unless command.code == 108
          res = command.parameters[0].split #cmd x
          key = TBS::EVENT_COMMENTS_TRIGGERS.key(res[0])
          next unless key
          tbs_trigger.follow_bat = true if key == :follow
          tbs_trigger.give_skill_list.push(res[1].to_i) if key == :getskill && res[1]
          tbs_trigger.team = res[1].to_i if key == :team && res[1]
          tbs_trigger.move_type = eval(res[1]) if key == :mtype && res[1]
          #eval("tbs_trigger.move_type =" + res[1]) if (key == :mtype and res[1])
          next if TBS::EVENT_NO_END.include?(key)
          if key == :end && k
            b = i
          elsif key != :end
            k = key
            value = res[1].to_i if TBS::EVENT_WITH_PARAM.include?(key)
            start = a = i
          else
            puts sprintf("Badly written event %d on map %d", @id, $game_map.map_id)
          end
          break if a && b
        end #for
        if TBS::EVENT_WITH_PARAM.include?(k)
          tbs_trigger.triggers[k][value] = a && b && @list.slice!(a, b-a+1).push(@list[-1])
        elsif k
          tbs_trigger.triggers[k] = a && b && @list.slice!(a, b-a+1).push(@list[-1])
        end
      end #while
      @triggers[@list] = tbs_trigger
    end
    tbs_trigger = @triggers[@list]
    @tbs_move_type = tbs_trigger.move_type
    @team = tbs_trigger.team
    tbs_trigger.set_global_trigger
  end
end #Game_Event


#==========================================================================
# Game_Action -> stores the affected events by abilities
#==========================================================================
class Game_Action
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :affected_events
  #--------------------------------------------------------------------------
  # alias method: tbs_make_targets -> store the events affected
  #--------------------------------------------------------------------------
  alias trigger_set_target set_target
  def set_target(pos)
    trigger_set_target(pos)
    type = @item.is_item? ? :item : :skill
    @affected_events = $game_map.battle_events_in(@tgt_area).select{|ev| ev.triggers[type][@item.item_id]}
    return @tgt_area
  end

  #--------------------------------------------------------------------------
  # alias method: property_valid? -> supports abilities made to target events!
  #--------------------------------------------------------------------------
  alias trigger_property_valid? property_valid?
  def property_valid?(property)
    return trigger_property_valid?(property) unless property == "event"
    return @affected_events && !@affected_events.empty?
  end

  #--------------------------------------------------------------------------
  # alias method: call_additional_tbs_effects
  #--------------------------------------------------------------------------
  alias trigger_call_additional_tbs_effects call_additional_tbs_effects
  def call_additional_tbs_effects
    call_events_triggers
    trigger_call_additional_tbs_effects
  end
  #--------------------------------------------------------------------------
  # new method: call_events_triggers
  #--------------------------------------------------------------------------
  def call_events_triggers
    type = @item.is_item? ? :item : :skill
    @affected_events.each{|ev| $game_map.call_tbs_event(ev.triggers[type][@item.item_id],ev.id,[@subject])} if @affected_events
  end
  #--------------------------------------------------------------------------
  # overwrite method: event? -> for properties to check if at least one event is affected
  #--------------------------------------------------------------------------
  def event?
    return @affected_events && !@affected_events.empty?
  end
end #Game_Action

#==========================================================================
# Window_TBS_ActorCommand -> adds the new skills as commands
#==========================================================================
class Window_TBS_ActorCommand < Window_ActorCommand
  #--------------------------------------------------------------------------
  # alias method: add_custom_commands
  #--------------------------------------------------------------------------
  alias tbs_trigger_add_custom_commands add_custom_commands
  def add_custom_commands
    for sid in @actor.get_event_skills.sort
      add_event_skill_command(sid)
    end
    tbs_trigger_add_custom_commands
  end
  #--------------------------------------------------------------------------
  # new method: extra_skill?
  #--------------------------------------------------------------------------
  def allow_extra_skill?(skill)
    !@actor.skill_sealed?(skill.id) && !@actor.skill_type_sealed?(skill.stype_id)
  end

  #--------------------------------------------------------------------------
  # new method: add_event_skill_command
  #--------------------------------------------------------------------------
  def add_event_skill_command(skill_id)
    skill = $data_skills[skill_id]
    add_command_tbs(skill.name, :event_skill, @actor.usable?(skill) && @actor.current_action, skill_id) if allow_extra_skill?(skill)
  end

  #--------------------------------------------------------------------------
  # alias method: draw_item
  #--------------------------------------------------------------------------
  alias trigger_tbs_draw_item draw_item
  def draw_item(index)
    return trigger_tbs_draw_item(index) unless @list[index][:symbol] == :event_skill
    change_color(text_color(TBS::ADDED_SKILL_COLOR), command_enabled?(index))
    return draw_text(item_rect_for_text(index), command_name(index), alignment) unless TBS::DRAW_SKILL_ICONS
    skill_id = @list[index][:ext]
    draw_skill(index,skill_id)
    #draw_text(item_rect_for_text(index), command_name(index), alignment)
  end

  #--------------------------------------------------------------------------
  # new method: draw_skill
  #--------------------------------------------------------------------------
  def draw_skill(index,sid)
    skill = $data_skills[sid]
    return if skill.nil?
    rect = item_rect(index)
    rect.width -= 4
    draw_skill_name(skill, rect.x, rect.y, command_enabled?(index), rect.width - 24)
    draw_skill_cost(rect, skill,command_enabled?(index))
  end

  #--------------------------------------------------------------------------
  # new method: draw_skill_name -> same as draw_item_name but not changing the color
  #--------------------------------------------------------------------------
  def draw_skill_name(item, x, y, enabled = true, width = 172)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    draw_text(x + 24, y, width, line_height, item.name)
  end

  #--------------------------------------------------------------------------
  # new method: draw_skill_cost -> copied from Window_Skill_List
  #--------------------------------------------------------------------------
  def draw_skill_cost(rect, skill, enabled)
    if @actor.skill_tp_cost(skill) > 0
      change_color(tp_cost_color, enabled)
      draw_text(rect, @actor.skill_tp_cost(skill), 2)
    elsif @actor.skill_mp_cost(skill) > 0
      change_color(mp_cost_color, enabled)
      draw_text(rect, @actor.skill_mp_cost(skill), 2)
    end
  end
  #--------------------------------------------------------------------------
  # alias method: update_help -> handles the skills
  #--------------------------------------------------------------------------
  alias tbs_et_update_help update_help
  def update_help
    return tbs_et_update_help unless current_symbol == :event_skill
    skill_id = current_ext
    @help_window.set_item($data_skills[skill_id])
  end
end #Window_TBS_ActorCommand

end #$imported["TIM-TBS-EventTriggers"]
