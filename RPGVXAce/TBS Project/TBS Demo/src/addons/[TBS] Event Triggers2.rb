#==============================================================================
# TBS Event Triggers v2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 24/09/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-EventTriggers"] = true #set to false if you wish to disable the modifications

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 29/03/2025: v1.0 - first version
# 03/04/2025: v1.1 - events are now linked to battlers when calling on_battle_start
#             instead of tbs_entrance, turn_start events trigger after count update
# 09/04/2025: v1.2 -  now supports help_window from core v0.7
# 24/09/2025: v2.0 - event triggers are now labels for better use, added more
#                    global triggers related to state addition and deletion
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
# <tbs_give_skill x>
#
# You may link a team or a move_type to an event for crossing rules:
# <tbs_team x>
# <tbs_move_type x>
# ex:
# <tbs_team 2>
# <tbs_move_type :ground>
#
# Event pages can now be called and jump to specific labels under some
# conditions on the labels names:
#
# Global triggers (like troop events):
# On global turn start (exactly like troop triggers on turn starts)
# <tbs_on_turn_start>
# On battler turn start (each time a battler starts its local turn)
# <tbs_on_bat_start>
# On battler turn end (each time a battler ends its local turn)
# <tbs_on_bat_end>
# On a battler getting any state
# <tbs_on_add_state>
# On a battler getting state x
# <tbs_on_astate x>
# On a battler losing any state
# <tbs_on_rm_state>
# On a battler losing state x
# <tbs_on_rstate x>
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
# <tbs_on_skill x>
# On item (each time a specific item's area touches this event)
# <tbs_on_item x>
#
# Your event's pages may look like this:
#
# ...
# exit event
# label: <tbs_trigger>
# Instructions
# exit event
# ...
# label: <tbs_trigger2>
# Instructions
# exit event
# ...
# label: <tbs_trigger3>
# label: <tbs_trigger4>
# Instructions
# exit event
# ...
#
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
#   class TBS::Trigger_Data
#      stores triggers type for automatisation of label checking
#==============================================================================

if $imported["TIM-TBS-EventTriggers"]

module TBS
  #The text color used to display added skills
  ADDED_SKILL_COLOR = 3
  #If set to true, will display the skill as if it was from the Skill Menu with
  #icon and cost, else, will only display its name.
  DRAW_SKILL_ICONS = false

  module EVENT_TRIGGERS
    DEFAULT_MOVE_TYPE = :wall
    DEFAULT_TEAM = TEAMS::TEAM_NEUTRALS
    #set to false if you don't want a following event to react to its battler
    #moving, else, it will trigger each cell the battler moves to
    FOLLOW_TRIGGERS_REACH_LEAVE_SELF = false
  end #EVENT_TRIGGERS

  module REGEXP
    #These are the regexp found inside events comments, they are linked to their
    #page, changing page mid-battle will change its properties
    module EVENT_COMMENTS
      #will follow the battler that starts the battle on this event
      FOLLOW_BATTLER = /^<tbs_follow_bat>/i
      #will give skill x to the battlers in the range of the skill,
      #the skill will appear as a custom command
      #if the battlers leave the range the skill is removed from them.
      GIVE_SKILL = /^<tbs_give_skill (\d+)>/i
      #team: set the team of the event, useful for passability and obstacles, does
      #not affect the battler on it!
      TEAM = /^<tbs_team (\d+)>/i
      #move_type: set the move_type of the event, useful for passability and obstacles
      MOVE_TYPE = /^<tbs_move_type (:.+)>/i
    end #EVENT_LABELS

    module EVENT_LABELS
      #Triggers are commands run under specific conditions in tbs battles
      #when the map is loaded or the events are refreshed, the system will check
      #any event with special labels recognized as triggers and call the events
      #by jumping to the right label whenever the trigger is activated
      #
      #You have to understand how labels and jump to labels work in order to use
      #triggers. You may have multiple triggers in the same event page but try
      #to keep a low numbers of global triggers! The more you have, the slower
      #the battle will run!
      #
      #Due to editor's limit, labels names cannot be longer than 20 characters,
      #for labels with integers as parameters, count at least 3 characters out
      #(to deal with hundreds indices from the database)
      module GLOBAL
        #when a global turn starts
        ON_GLOBAL_TURN_START = /^<tbs_on_turn_start>/i
        #when any battler starts its turn
        ON_BATTLER_TURN_START = /^<tbs_on_bat_start>/i#"<tbs_on_bat_turn_start>" #data: bat
        #when any battler ends its turn
        ON_BATTLER_TURN_END = /^<tbs_on_bat_end>/i #data: bat
        #when any battler gets a state
        ON_BATTLER_ADD_STATE = /^<tbs_on_add_state>/i #data: bat, state
        #when any battler gets state number x
        ON_BATTLER_ADD_STATE_X = /^<tbs_on_astate (\d+)>/i #data: bat, state
        #when any battler gets a state
        ON_BATTLER_RM_STATE = /^<tbs_on_rm_state>/i #data: bat, state
        #when any battler gets state number x
        ON_BATTLER_RM_STATE_X = /^<tbs_on_rstate (\d+)>/i #data: bat, state
      end #GLOBAL

      module LOCAL
        #if the cursor in select/place mode clicks on this event,
        #triggers before the battler selection if any
        ON_CURSOR_OK = /^<tbs_on_cursor_ok>/i
        #when any battler reaches this event
        ON_BATTLER_REACH = /^<tbs_on_bat_reach>/i #data: bat
        #when any battler leaves this event
        ON_BATTLER_LEAVE = /^<tbs_on_bat_leave>/i #data: bat
        #when skill x is cast upon this cell (among others)
        ON_SKILL = /^<tbs_on_skill (\d+)>/i # sid
        #when item x is cast upon this cell
        ON_ITEM = /^<tbs_on_item (\d+)>/i # iid
      end #LOCAL
    end #EVENT_LABELS
  end #REGEXP

#==========================================================================
# Don't edit things past here!
#==========================================================================

  #==========================================================================
  # Trigger_Data -> stores a key (for hash tables), a regexp to find in labels
  # a boolean whether the trigger is 'global', another whether the trigger needs
  # more data to activate (like under specific skills ids or items)
  #==========================================================================
  All_Trigger_Data = []
  class Trigger_Data
    attr_accessor :key, :regexp, :label_name
    def initialize(key, label_regexp, bglobal, bparam = false)
      @key = key
      @regexp = label_regexp
      @bglobal = bglobal
      @bparam = bparam
      All_Trigger_Data.push(self)
    end
    def param?; @bparam; end
    def global?; @bglobal; end
  end #Trigger_Data

  #global triggers
  Trigger_Data.new(:gts, REGEXP::EVENT_LABELS::GLOBAL::ON_GLOBAL_TURN_START, true)
  Trigger_Data.new(:bts, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_TURN_START, true)
  Trigger_Data.new(:bte, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_TURN_END, true)
  Trigger_Data.new(:bas, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_ADD_STATE, true)
  #new additions
  Trigger_Data.new(:bas2, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_ADD_STATE_X, true, true)
  Trigger_Data.new(:brs, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_RM_STATE, true)
  Trigger_Data.new(:brs2, REGEXP::EVENT_LABELS::GLOBAL::ON_BATTLER_RM_STATE_X, true, true)

  #local triggers
  Trigger_Data.new(:cok, REGEXP::EVENT_LABELS::LOCAL::ON_CURSOR_OK, false)
  Trigger_Data.new(:reach, REGEXP::EVENT_LABELS::LOCAL::ON_BATTLER_REACH, false)
  Trigger_Data.new(:leave, REGEXP::EVENT_LABELS::LOCAL::ON_BATTLER_LEAVE, false)
  Trigger_Data.new(:skill, REGEXP::EVENT_LABELS::LOCAL::ON_SKILL, false, true)
  Trigger_Data.new(:item, REGEXP::EVENT_LABELS::LOCAL::ON_ITEM, false, true)
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
        data = $data_skills[skill_id].range
        r2 = data.each_slice(4).to_a
        spellRg = SpellRange.new(r2[0],r2[1])
        range = TBS.get_targets(self,POS.new(ev.x,ev.y),spellRg)
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
    if SceneManager.scene_is?(Scene_TBS_Battle)
      $game_map.call_triggers(:bas,[self,state_id])
      $game_map.call_triggers_x(:bas2,state_id,[self,state_id])
    end
    tbs_te_add_new_state(state_id)
  end
  #--------------------------------------------------------------------------
  # alias method: add_new_state -> triggers the proper events
  #--------------------------------------------------------------------------
  alias tbs_te_remove_state remove_state
  def remove_state(state_id)
    if state?(state_id) && SceneManager.scene_is?(Scene_TBS_Battle)
      $game_map.call_triggers(:brs,[self,state_id])
      $game_map.call_triggers_x(:brs2,state_id,[self,state_id])
    end
    tbs_te_remove_state(state_id)
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
module BattleManager
  class <<self; alias tbs_trigger_bm_turn_start turn_start; end
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
    l = bat.gen_targets(bat.get_range(skill_id,:skill))
    type2 = $data_skills[skill_id].for_friend? ? :help_skill : :skill
    @spriteset.draw_range(l,TBS.sprite_type(type2))
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
    TBS::All_Trigger_Data.each do |td|
      @global_triggers[td.key] = {} if td.global?
    end
  end
  #--------------------------------------------------------------------------
  # new method: call_tbs_event
  #--------------------------------------------------------------------------
  def call_tbs_event(list,event_id=0, params = [])
    return unless list #if some local triggers were removed
    @waiting_events.push([list,event_id,params])
  end
  #--------------------------------------------------------------------------
  # new method: call_triggers
  #--------------------------------------------------------------------------
  def call_triggers(trigger_key,params = [])
    return unless @global_triggers[trigger_key] #if some triggers were removed
    @global_triggers[trigger_key].each_pair do |key, value|
      call_tbs_event(value, key, params) #key is event id, value is a list of event commands
    end
  end
  #--------------------------------------------------------------------------
  # new method: call_triggers_x -> when the trigger has a second key being a
  # parameter like a state_id
  #--------------------------------------------------------------------------
  def call_triggers_x(trigger_key, id, params = [])
    return unless @global_triggers[trigger_key][id] #if some triggers were removed
    @global_triggers[trigger_key][id].each_pair do |key, value|
      call_tbs_event(value, key, params) #key is event id, value is a list of event commands
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
    @move_type = TBS::EVENT_TRIGGERS::DEFAULT_MOVE_TYPE
    @team = TBS::EVENT_TRIGGERS::DEFAULT_TEAM
    @follow_bat = false
    @give_skill_list = []
    @triggers = {}
    TBS::All_Trigger_Data.each do |td|
      @triggers[td.key] = {} if td.param?
    end
  end
  #--------------------------------------------------------------------------
  # set_global_trigger
  #--------------------------------------------------------------------------
  def set_global_trigger
    TBS::All_Trigger_Data.each do |td|
      next unless td.global? && @triggers[td.key]
      k = td.key
      if td.param?
        #for global triggers with parameters, the data will store
        #trigger_key -> parameter -> event_id
        @triggers[k].each_pair do |id,list|
          $game_map.global_triggers[k][id] ||= {}
          $game_map.global_triggers[k][id][@id] = list
        end
      else
        $game_map.global_triggers[k][@id] = @triggers[k]
      end
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
    return if $imported["TIM-TBS-Animation-plus"] && tbs_offset_moving?
    on_reach if !moving? && @last_moving
    trigger_update_tbs_move
    on_leave(@prev_pos) if moving? && !@last_moving
  end

  #--------------------------------------------------------------------------
  # new method: on_leave -> when the unit leaves a cell
  #--------------------------------------------------------------------------
  def on_leave(prev_pos)
    evList = $game_map.battle_events_at(prev_pos[0],prev_pos[1]).select{|ev| ev.triggers[:leave]}
    evList.select!{|ev| ev.battler != @battler} unless TBS::EVENT_TRIGGERS::FOLLOW_TRIGGERS_REACH_LEAVE_SELF
    evList.each{|ev| $game_map.call_tbs_event(ev.triggers[:leave],ev.id)}
    SceneManager.scene.process_event if SceneManager.scene_is?(Scene_TBS_Battle)
  end

  #--------------------------------------------------------------------------
  # new method: on_reach -> when the unit reaches a cell
  #--------------------------------------------------------------------------
  def on_reach
    evList = $game_map.battle_events_at(@x,@y).select{|ev| ev.triggers[:reach]}
    evList.select!{|ev| ev.battler != @battler} unless TBS::EVENT_TRIGGERS::FOLLOW_TRIGGERS_REACH_LEAVE_SELF
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
    puts sprintf("linked %d to %s", self.id, bat.name)
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
  # new method: read_tbs_trigger_comments (tbs_pagedata is a TBS_PageData obj)
  #--------------------------------------------------------------------------
  def read_tbs_trigger_comments(tbs_pagedata)
    note.split(/[\r\n]+/).each { |line|
    case line
    when TBS::REGEXP::EVENT_COMMENTS::FOLLOW_BATTLER
      tbs_pagedata.follow_bat = true
    when TBS::REGEXP::EVENT_COMMENTS::GIVE_SKILL
      tbs_pagedata.give_skill_list.push($1.to_i)
    when TBS::REGEXP::EVENT_COMMENTS::TEAM
      tbs_pagedata.team =  $1.to_i
    when TBS::REGEXP::EVENT_COMMENTS::MOVE_TYPE
      tbs_pagedata.move_type =  eval($1)
    end
    } # event.note.split
    tbs_pagedata
  end
  #--------------------------------------------------------------------------
  # new method: read_tbs_trigger_labels (tbs_pagedata is a TBS_PageData obj)
  # will store in each reaction key the list of commands to execute, here the
  # list is the original event commands + at the begining a jump to the
  # triggered label
  #--------------------------------------------------------------------------
  def read_tbs_trigger_labels(tbs_pagedata)
    return tbs_pagedata unless @list
    @list.select{|cmd| cmd.code == 118}.each do |cmd|
      TBS::All_Trigger_Data.each do |td|
        cmd.parameters[0].scan(td.regexp) do |m|
          cmdl = [RPG::EventCommand.new(119,0,cmd.parameters.dup)] + @list
          td.param? ? tbs_pagedata.triggers[td.key][$1.to_i] = cmdl : tbs_pagedata.triggers[td.key] = cmdl
        end
      end
    end
    tbs_pagedata
  end
  #--------------------------------------------------------------------------
  # new method: read_triggers -> reads the labels and comments of the current
  # page and determines the current event properties as well as its triggers
  #--------------------------------------------------------------------------
  def read_triggers
    @triggers = {} unless @triggers
    unless @triggers.has_key?(@list) #skip if already read this page
      tbs_pagedata = TBS_PageData.new(@id)
      tbs_pagedata = read_tbs_trigger_comments(tbs_pagedata)
      tbs_pagedata = read_tbs_trigger_labels(tbs_pagedata)
      @triggers[@list] = tbs_pagedata
    end
    tbs_pagedata = @triggers[@list]
    @tbs_move_type = tbs_pagedata.move_type
    @team = tbs_pagedata.team
    tbs_pagedata.set_global_trigger
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
  # alias method: set_target -> store the events affected
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
  def call_additional_tbs_effects(targets)
    call_events_triggers
    trigger_call_additional_tbs_effects(targets)
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
