#==============================================================================
#
# TBS v0.8.1 by Timtrack
# -- Last Updated: 10/05/2025
# -- Requires:
#       -Victor Core Engine v 1.35
#       -Timtrack's Sprite_Tile v 1.1
#
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS"] = true

#==============================================================================
# Term of use
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Credit and Thanks
# - Timtrack (author)
# Special thanks
# - GubiD for GTBS this script takes inspiration from
# - Clarabel for the notetag system from GTBS
# Free to use in free or commercial games, you must give credit.
#==============================================================================
# Description
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# A set of scripts that introduces a Tactical Battle System taking inspiration
# from BG3, Dofus, Wildermyth and Fire Emblem.
# [TBS] Core is a single file that might be splitted into subones, it requires
# both Victor Core Engine and Sprite_Tile. It Comes along with many optional
# files to add features but they are not required for the battles to run properly.
#
# This set of scripts is standalone, it is not compatible with GTBS and is
# unlikely to work with any other overhaul of the battle system.
# This is intended to work only with RPG Maker VX ace, it will not work with
# any other version of RPG Maker.
#==============================================================================
# Update History
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 11/05/2024:        start of project
# 13/03/2025: v0.1   first single-file version
# 18/03/2025: v0.2   single file version commented and tested
# 20/03/2025: v0.3   bug fixes, added full status and win conditions menus
# 23/03/2025: v0.4   added sprites to show team alliegeance and active units
# 24/03/2025: v0.4.1 bug fixes (vanilla range, guard confirm and small status window display), calls uniformisation
# 26/03/2025: v0.4.2 supports interpreter calls for map/events effects in TBS
# 28/03/2025: v0.5   supports movements event calls and addon [TBS] Event Triggers
# 03/04/2025: v0.6   add place battler phase with music and menu, allows battle
#                    reinforcement with new interpreter methods and stores skill
#                    data when casting them for common events uses. Allows parent
#                    and children interaction for summons. Expanded properties possibilities
# 03/04/2025: v0.6.1 bug fix when spawning new actors, changed when the battle music is called
# 10/04/2025: v0.7   added option menu as addon, $game_system now has more display attributes,
#                    added damage preview and turn ids, units are now highlighted when affected by abilties
#                    added a turnwheel menu to navigate in the turn wheel
#                    code fixing, hopefully less bugs
# 09/05/2025: v0.8   Improved AIs with preview damage
#                    Battler's tactics are defined by class, actor/enemy id or states
#                    Allows Scene_Shop/Scene_Name calls during TBS Battle with event commands
#                    Added save/load in mid-battle addon, supports Yanfly Save Engine and my Neo-Save-like
#                    States may now forbid actors from being placed in battle
#                    States can now display balloons continuously
#                    Added advanced height system (requires tests)
#                    Fix bug regarding random targeting and other targeting calculation.
#                    Fixed autobattle units in vanilla battle crash
#                    Abilities now only affect dead units if they are specificaly for dead (This will fix ai behavior)
#                    Forced tbs actions are now properly forced, regardless of the tgt_property conditions
#                    Fixed ai pathfinding to consider other paths when blocked by other units
#                    Battlers removed on death will now still display an animation and sound
#                    (their circle and team number will be cleaned after all effects though)
# 10/05/2025: v0.8.1 Fix crash when ais had no available cells to move to
#                    Fix tgt_empty? to check blocking events too
#==============================================================================
# Features
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
# TBS allows turn-based battles taking place on the map.
# Battlers (being actors or enemies) are divided into teams (identified by numbers)
# each team has a relationship with the other teams (friends, neutral, enemies).
# By default the members of the party are in the TEAM_ACTORS and the members of
# the troop are in the TEAM_ENEMIES.
# The battle ends if either TEAM_ACTORS is defeated or if TEAM_ENEMIES is defeated.
#
# A new turn system is introduced : a TurnWheel decides which battlers may act,
# the turn system is either team-based (like Wildermyth, FE), Free For All (like DnD/BG3)
# or is team-based evenly distributed (like Dofus/Wakfu).
#
# Battlers have a character that has a position and that may move during their turn.
# Battlers have a number of moving points that represent how many cells they can cross in a turn.
# By default, as long as they have moving points, the battlers may move mutliple times during their turn.
# A battler may have constraints when moving, some tiles may cost more to cross or even being impossible
# to cross for specific battlers.
#
# The targeting for abilities (being skills, items or attacks) has been changed,
# now an ability must pick a cell to be cast on it. The ability may have a specific range
# (a distance, a shape, a sight that may be blocked by obstacles) and an area of effect.
# Even if the ability states that it has no target or only the user,
# the target will be a cell under this system.
# -Abilties may affect allies and enemies alike, this can be parametrized to
# avoid friendly fire and allow it for specific abilities.
# -Abilities that target all will now work under an area, a single animation is displayed.
# -Abilities that target only one unit will also work on every target under an
# area, an animation for each target is displayed.
# -Abilities that targets k random targets will be applied to k random targets
# inside the area targeted.
# -Abilities used outside of a tbs battle will have the vanilla targeting behavior.
#
# The map can be used to read what are the starting locations for battlers and may
# add more battlers in combat along with obstacles that can be damaged/destroyed by battlers.
#
# This work is aimed to be the most compatible with outside scripts like
# cooldown systems, skill resources etc.
# While inspired by GTBS, some features where dropped:
# -recruitment of actors in battle -> use events instead
# -summon system with doom effect -> use skills/events instead
# -isometric view -> too specific
# -sideview battles (like FE) -> too 'animation' constraining, also conflicts with future plans like reactions skills
# -cooldowns -> use external scripts like Yanfly's
# -custom winning conditions -> either use external scripts or battle events
# -exp rewarded to the killers -> exp is distributed to the battle members of
# the party in a vanilla way. Exp, gold and loot are based on units from enemy
# teams that are dead by the end of the battle.
#
# Other features will be added compared to GTBS:
# -reaction skills (like counterspells etc.)
# -traps/passive area of effect
# -push/pull effects
#==============================================================================
# Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#   Requires
#     -Victor Core Engine (deals with NoteTags reading and skills for battlers)
#     -Sprite_Tile (deals with autotile ranges mostly)
#
#   Modified classes:
#   class RPG::Troop
#     new attributes (private): extra_troops, notes
#     new methods: members, add_new_members, note
#   module SceneManager
#     alias methods: first_scene_class, call
#   class Scene_Map < Scene_Base
#     alias method: pre_terminate
#   class Game_Interpreter
#     alias methods: screen, get_character, command_204, command_236, command_302, command_303
#     new methods: disable_tbs, enable_tbs, spawn_new_obstacle(enemy_id,posList,force_place = false),
#                  spawn_new_enemy(enemy_id,posList,team = 2,parent = nil,force_place = false)
#                  spawn_new_actor(actor_id,posList,team = 0,parent = nil,force_place = false),
#                  spawn_actor(actor_id,posList,team = 0,setup=false,parent = nil,force_place = false),
#                  tbs_add_battler(bat,posList,force_place = false),
#                  tbs_rm_battler(bat), force_tbs_action(bat,skill_id,tgt,check_range = false)
#   class Game_System
#     new attributes: move_color, help_skill_color, attack_skill_color,
#                     attack_color, tbs_enabled, turn_mode, place_music,
#                     help_window, team_sprite, highlight_units, pre_place,
#                     turn_id, preview_damage, anim_range, confirm_hash, area_blink,
#                     area_blink_color
#     alias method: initialize
#     new methods: tbs_enabled?, reset_default_tbs_config, reset_victory_text,
#                  set_victory_text(textLines), set_place_music(bgm_name,volume,pitch),
#                  reset_place_music
#   class Game_BattlerBase
#     new attribute: initiative
#     new method: roll_initiative, threat_from(bat)
#   class Game_Battler < Game_BattlerBase
#     new attributes (private): tbs_active, has_played
#     new attributes: mmov, spent_mov, char, character_name, character_index, face_name,
#                     face_index, team, parent, tbs_battler, ai, turn_id, dmg_preview
#     alias methods: initialize, on_battle_start, on_action_end, on_turn_end, on_battle_end, hide, add_new_state(state_id), remove_current_action
#     override method: sprite
#     overwrite method: opposite?
#     new methods: pos, moveto(x,y), nickname, level, skip_turn(new_dir),
#                  on_turn_start, is_active?, update_char, update, tbs_entrance, can_battle?,
#                  set_obstacle, obstacle?, mmov, available_mov, can_move?, move_rule_id,
#                  force_move_through_path(route,cost), cut_route(route,cost,move_points),
#                  move_through_path(route, cost), can_occupy?(pos), can_cross_bat?(moveRule,other_battler),
#                  calc_pos_move(move_distance = available_mov, forbidden_list = []),
#                  reverse_calc_pos_move(target_pos = pos, move_distance = available_mov, forbidden_list = []),
#                  astar_heuristic(cost,p,tgt,min_cost), astar(tgt,move_distance = available_mov, forbidden_list = []),
#                  true_friend_status(other), friend_status(other), getRange(id,type), getRangeWeapon, genTgt(spellRg),
#                  genArea(tgt,spellRg), always_hide_view?, hide_view?(other), remove_on_death?,
#                  screen_x, screen_y, screen_z, init_ai, player_controllable?, skill_rating(skill_id),
#                  attack_range?(id,type), has_played?, can_cross?, can_cross_ev?(moveRule,dir,event)
#                  tbs_leave, force_tbs_action(skill_id, tgt, check_range = false),
#                  prepare_preview_damage(user,item), preview_damage(user,item),
#                  preview_effects(user,item), displayed_area_affected?, children,
#                  get_ai_tactic, skill_cost_eval(formula,s,t), get_state_balloon
#   class Game_Actor < Game_Battler
#     alias methods: initialize, set_graphic, make_actions
#     override methods: move_rule_id, mmov, getRangeWeapon, screen_x, screen_y, screen_z, can_battle?, get_ai_tactic
#     new method: ai_usable_skills
#   class Game_Enemy < Game_Battler
#     new attributes: class_name, last_skill
#     alias methods: initialize, transform, sprite (if YEA-BattleEngine), make_actions
#     override methods: move_rule_id, mmov, always_hide_view?, getRangeWeapon, remove_on_death?, skill_rating(skill_id), get_ai_tactic
#     overwrite methods: screen_x, screen_y, screen_z
#     new methods: load_tbs_enemy_data(enemy_id), clear_actions, input, next_command, prior_command
#                  ai_usable_skills, usable_skills, description
#   class Game_Unit
#     new methods: tbs_members, tbs_dead_members, on_tbs_battle_start, on_tbs_battle_end
#   class Game_Party < Game_Unit
#     new attribute: neutrals
#     alias methods: initialize, battle_members
#     new method: all_candidate_battlers, tbs_add_actor(actor_id, team, setup), tbs_remove_actor(actor_id)
#   class Game_Troop < Game_Unit
#     new attributes: neutrals, obstacles
#     alias methods: clear, exp_total, gold_total, make_drop_items
#     new methods: all_candidate_battlers, tbs_dead_enemies, add_obstacle(bat), add_extra_battler(bat)
#   module BattleManager
#     alias methods: battle_start, battle_end, actor, judge_win_loss
#     new methods: teams_routed?(scene, team_list), end_battle_cond?
#   class Game_Map
#     new attributes: retrieve_map
#     alias methods: setup_events, setup, update_events
#     new methods: setup_old_events, save_map_data, tbs_setup, update_tbs, update_battlers
#                  setup_tbs_events, tbs_events, battle_event_at?(x,y), in_range?(posList, x1,y1)
#                  targeted_battlers(posList), occupied_by?(x, y), cost_move(move_rule, x,y,d)
#                  obstacle_dir?(prev_pos,pos,d), can_see?(bat,source,target),
#                  battle_events_at(x,y), battle_events_in(posList)
#   class Game_BaseItem
#     reveal attribute: item_id
#   class Game_Action
#     new attributes: tgt_pos
#     new attributes (private): tgt_area, tgt_property
#     alias methods: set_item, set_skill, clear
#     new methods: set_target(pos), get_targeted_rel, tbs_make_target_pos,
#                  tbs_make_targets(area), tbs_make_final_targets(area),
#                  property_valid?(property), get_tgt_property, item_for_none?, item_for_all?,
#                  tbs_tgt_valid?, random_target, call_additional_tbs_effects, tgt_empty?,
#                  tgt_filled?,tgt_blocking_event?,tgt_ground?,tgt_water?
#   class Bitmap
#     new method: draw_circle(radius,x0,y0,c)
#   class Window_Base < Window
#     alias method: draw_actor_class
#     new method: relocate(dir)
#   class Sprite_AutoTile_Handler
#     new method: refresh
#
#
#   New classes/modules:
#   module TBS
#      contains many functions and storage objects dealing with TBS
#      contains modules Vocab, FILENAME, Confirm, FORMULA, TEAMS, REGEXP,
#                              EVENT_NAMES, EVENT_COMMENTS, Characters, PREVIEW
#   class POS
#      stores x,y for math operations
#   class MoveRule
#      stores move cost data and restrictions, used in calc_pos_move
#   class CastRange
#      used to generate range of spells and area of effects
#   class SpellRange
#      stores 2 CastRange, one for the range of the spell, the other for the area of effect.
#   class TBS_Path
#      updates the path when adding directions during move command
#   class Game_TBS_Step_Character < Game_Character
#      handles the path displayed when the player tries to build a path
#   class TBS_Cursor
#      deals with cursor position during TBS
#   class Direction_Cursor < Sprite_Base
#      the WAIT DIRECTION image that appears over battlers at the end of their turn
#   class TurnWheel
#      a new class handling turn order
#   class Game_Character_TBS < Game_Character
#      used inside all tbs battlers to position them and apply effects
#   class Scene_TBS_Battle < Scene_Base
#      meant as a replacement of Scene_Battle, any modification to the latter does not impact the former
#   class Sprite_Character_TBS < Sprite_Character
#      replaces Sprite_Battler for TBS
#   class Sprite_Team < Sprite_Base
#     displays a sprite under the battler's sprite to show its team alliegeance.
#   class Sprite_Active < Sprite_Base
#     displays an icon over the battler's sprite to show if the battler can be played
#   class Sprite_Turn_Number < Sprite_Base
#     displays a number representing the position in the turnwheel of the battler
#   class Sprite_DamagePreview < Sprite_Base
#     displays a text above the affected battlers representing how much damage they might take
#   class Sprite_Range < Sprite_Tile
#      displays all ranges/areas during battle
#   class Sprite_TBS_Cursor < Sprite_Tile
#      handles the display of the cursor
#   class Spriteset_TBS_Map < Spriteset_Map
#      stores and handles every display features
#   class Window_TBS_ActorCommand < Window_ActorCommand
#      deals with the list of commands when selecting a playable battler
#   class Window_TBS_GlobalCommand < Window_Command
#      deals with the list of commands when pressing ESC during TBS battle
#   class Window_TBS_PlaceGlobalCommand < Window_TBS_GlobalCommand
#      lists the commands specific to the place phase
#   class Window_Confirm < Window_HorzCommand
#      displays a Yes/No command with text above
#   class Window_TBS_Confirm < Window_Confirm
#      confirms tbs actions or cancel them
#   class Window_Small_TBS_Status < Window_Base
#      displays a small amount of data on the battlers
#   class Window_Full_Status < Window_Status
#      displays a status window like vanilla but for enemies too (called by Status cmd from Window_TBS_ActorCommand)
#   class Window_WinConditions < Window_Selectable
#      display the victory condition text when called from Window_TBS_GlobalCommand
#   class Window_TurnOrder < Window_Command
#      displays unit in order in the turn wheel, called from Window_TBS_GlobalCommand
#   class Preview_DamageData
#      Parse the potential results of an action, called by AIs and displayed by Sprite_DamagePreview
#   class AI_HandlerBase
#      choose the order of action of each ai battler
#   class AI_BattlerBase
#      decides the action of a battler
#==============================================================================
# �� Load Order
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# [RPG Maker Scripts]
# Victor Core Engine
# Sprite_Tile
# [TBS] Core
# [TBS addons] (optional)
# Main
#==============================================================================
# �� Known Issues/Missing content
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Known issues:
# -branching after saved battle is loaded is not working properly
# -test the advanced height calculation [see addon TBS Height]
# -vanilla ranges obstacles are not great when using flying units (or units at some obstacles)
# -there were in previous tests random crashes/freezes of the game, I did fix them (at least partially)
#  and haven't encountered them again, if you still encounter them, please tell me!
#  It will probably mean that there are still issues in my code
#
# Planned content:
# -more tiny sprite effects (like unit selection)
# -basic animation addon is considered
#
# Planned addons:
# -push/pull effects [addon]
# -dammage based on direction [addon]
# -reaction skills [addon]
# -traps/passive area of effect [addon] (can be partially simulated with event triggers)
#
# Very low priority addons (assume that I will not work on them but you can design them!):
# -side-view battles like FE (graphic knowledge plus conflict with reaction skills etc., not something I want to code)
# -battle animations (cast, moving, projectiles etc.) (graphic knowledge, huge)
# -exp/rewards mid-battle (not something I want to code)
# -self inventory and trade system (probably already exists somewhere, would be nice to check this)
# -script-controlled custom victory conditions (would have to define a list or something, I prefer using events instead)
# -isometric view support (graphic and external script knowledge, not something I want to code)
#==============================================================================

#==============================================================================
# TBS Part 1: Configuration
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# You should edit things below to fit your TBS perspective
#==============================================================================
module TBS

#==============================================================================
# Display configuration
#==============================================================================

  #============================================================================
  # Vocab: Text language is handled here
  #============================================================================
  module Vocab
    #Information when placing batlers
    module PreBattle
      Empty_place_status = "No available unit"
      Place_Message = "Place your units"
    end #PreBattle
    module Commands
      #Actor Commands
      Menu_Move = "Move"
      Menu_Wait = "Wait"
      #Global menu Commands
      Battle_Option_Start_Battle = "Start the battle"
      Battle_Option_End_Turn = "Skip turn"
      Battle_Option_Conditions =  "Victory Conditions"
      Battle_Option_Config = "Options"
      Battle_Option_TurnWheel = "Turn Order"
      Battle_Option_Cancel = "Cancel"
    end #Commands
    #Confirmation window
    module Confirm
      Save_Options = "Save the settings?"
      Place_Here = "Start battle?"
      Skip_turn = "Skip your turn?"
      Wait_Here = "End this battler's turn?"
      Skill_Here = "Use skill here?"
      Item_Here="Use item here?"
      Attack_Here = "Attack here?"
      Move_Here='Move here?'
      Yes, No = "Yes", "No"
    end #Confirm
    #Help Window
    module Help
      #Help in actor menu
      Move='Move to another cell for move points'
      Attack='Attack a target'
      Skill_Class='Use a skill'
      Item='Use an item'
      Status='Get more info about the unit'
      Guard='Use Guard skill'
      Wait='Skip this unit\'s turn'
    end #Help
    #an array with a value per line to display in the VictoryCond window
    #you may use message commands here
    Default_Victory_Cond_Texts = ["Rout all \\C[1]opponents\\C[0]! At least one",
                                 "of your character must survive!"]

  end #Vocab

  #============================================================================
  # Colors: define the default colors handled by TBS
  #============================================================================
  RED = Color.new(255,0,0,255)
  BLUE = Color.new(0,0,255,255)
  GREEN = Color.new(0,255,0,255)
  YELLOW = Color.new(255,255,0,255)
  PURPLE = Color.new(128,0,255,255)
  ORANGE = Color.new(255,128,0,255)
  BROWN = Color.new(128,64,0,255)
  BLACK = Color.new(0,0,0,255)
  WHITE = Color.new(255,255,255,255)
  PINK = Color.new(255,128,255,255)
  TAN = Color.new(200,200,110,255)

  #will be used in the settings menu to define ranges and team colors
  Colors = [RED,BLUE,GREEN,YELLOW,PURPLE,ORANGE,BROWN,BLACK,WHITE,PINK,TAN]
  #The following are the colors used by ranges when no file is loaded
  DEFAULT_ATK_COLOR = RED
  DEFAULT_MOVE_COLOR = BLUE
  DEFAULT_ATK_SKILL_COLOR = YELLOW
  DEFAULT_HELP_SKILL_COLOR = GREEN
  DEFAULT_PLACE_COLOR = DEFAULT_MOVE_COLOR
  #The following are the opacity of the ranges when no file is loaded
  RANGE_OPACITY = 100 #also changes the move opacity
  AREA_OPACITY = 255
  #Will change the transparency of the range sprites when no file is used
  ANIM_TILES = true
  #number of frames per image when using autotiles for ranges,
  #low value implies fast change of image for animated autotiles
  AUTO_RANGE_FPI = 10

  #============================================================================
  # Files
  #============================================================================

  module FILENAME
    #from the root, autotiles pictures to replace ranges
    ATTACK_RANGE = "Graphics/Pictures/TBS/attack_range"
    ATTACK_AREA = "Graphics/Pictures/TBS/attack_area"
    SKILL_RANGE = ""
    SKILL_AREA = ""
    HELP_RANGE = ""
    HELP_AREA = ""
    MOVE_RANGE = ""#"Graphics/Pictures/TBS/water_dungeon_a1"
    PLACE_RANGE = ""

    #In Characters folder
    PATH_CHAR_NAME = "!$path.png" #the path displayed when selecting a cell to move
    #In Pictures folder
    CURSOR_PICTURE = "TBS/cursor" #the cursor on the battle map
    DIRECTION_PICTURES = "TBS/wait%d" #%d is a direction in [2,4,6,8]
  end

  #============================================================================
  # Confirm Window
  #============================================================================

  #You may change the values as true or false to allow or remove the confirmation
  #window when an action is done
  module Confirm
    MODES = [:start_battle,:skip_turn,:wait,:item,:skill,:attack,:move,:settings]
    BOOL_CONFIRM = {
      :start_battle => true,
      :skip_turn => true, #when selecting the global skip turn
      :item => true, #when the item target is selected
      :skill => true, #when the skill target is selected
      :attack => true, #when the attack target is selected
      :move => true, #when the position to move is selected
      :wait => true, #when selecting the 'wait' action (skips self turn)
      :settings => true, #when quitting the setting menu
    }
    #this method reads the hash table
    def self.ask_confirm?(type)
      return $game_system.confirm_hash[type]
    end
  end

  #============================================================================
  # Battler character display
  #============================================================================
  module Characters
    TBS_CHAR_STATES = {
    #state_id => [default_char,default_index,suffix]
    #
    #
    #suffix is the name added to the char_name to find the proper charset
    #if no such file exists, loads default_char with default_index unless default_char is nil
      :default => [nil,nil,""],
      :dead => ["!Flame",5,"_down"],
      #:moving => [nil,nil,"_moving"],
    }

    #--------------------------------------------------------------------------
    # bat_state -> defines what is the state of the battler to display
    # the returned value must be a key in TBS_CHAR_STATES
    #--------------------------------------------------------------------------
    def self.bat_state(bat)
      bat.dead? && !bat.remove_on_death? ? :dead : :default
    end

    #You may change the icons ids associated to battlers, put 0 if you don't want to show an icon
    Active_icons = {
      :active => 359,#189,                  #displayed on freshly activated battlers
      :active_used => 359,#190,             #displayed on active battlers that haved move or use an action at least once this turn
      :active_non_controllable => 0,#191, #displayed on non-inputable (states or ai-controlled) battlers
      :inactive => 0,#186,                #displayed on battlers from your teams that are inactive (for instance finished playing)
      :non_player_teams => 0,          #displayed on battlers that can never be played
      :obstacle => 0,                  #for obstacles, should be 0
    }
    #--------------------------------------------------------------------------
    # get_active_state -> gets the active state, should be a key from Active_icons
    #--------------------------------------------------------------------------
    def self.get_active_state(bat)
      return :obstacle if bat.obstacle?
      return :non_player_teams unless TBS::TEAMS::PLAYABLE_TEAMS.include?(bat.team)
      return :inactive unless bat.is_active?
      return :active_non_controllable unless bat.player_controllable?
      return :active_used if bat.has_played?
      return :active
    end
    #--------------------------------------------------------------------------
    # get_active_icon -> gets the icon to be displyed on the battler
    #--------------------------------------------------------------------------
    def self.get_active_icon(bat)
      return Active_icons[get_active_state(bat)]
    end
  end

  #============================================================================
  # Place phase settings
  #============================================================================
  DISPLAY_EMPTY_PARTY = true #display an empty window when no battler is availvable, set to false to hide it
  PLACE_ACTORS = true #place the actors or they will be randomly put
  PLACE_MUSIC_SWICTH = 0 #if set above 0, you may control whether there is a place phase music or not based on the swicth
  PLACE_MUSIC = RPG::BGM.new("Scene2", 100, 100) #default place music

  #============================================================================
  # Battle settings: default values and all the rest of the battle settings are handled here
  #============================================================================
  BTEST_MAPID = 4 #id of the map to setup battle tests, put 0 if you don't want to test a tbs battle
  WINDOW_OPACITY = 120 #the opacity of windows during TBS battle, between 0 and 255
  TRANSPARENT_Z = 200 #added to all trasnparent battlers to be above tileset
  TRANSPARENT_OPACITY = 0.75 #in 0...1, will be multiplied by the battler's opacity in transparent mode
  #skip the direction choice of the battler at the end of its turn
  SKIP_DIRECTION_CHOICE = false
  HIDE_PERFORMED_ACTIONS = true

  #----------------------------------------------------------------------------
  # Turn Wheel
  #----------------------------------------------------------------------------
  #teams is a turn system like fire emblem, the same team plays together
  #ffa is like dnd : your turn is decided based on a personal stat
  #ffaeven is like dofus : the turn order is decided in each team based on
  #personal stat but is balanced, the order will be t1p1,t2p1,t1p2,t2p2...
  TURN_SYSTEMS = [:teams,:ffa,:ffaeven]
  DEFAULT_TURN_SYSTEM = :ffa
  #mostly relevant for team and ffa, allows to play in any order the units
  #that share the same team id
  GROUPED_TURNS = true

  module FORMULA
    # the formula for intiative calculation of a Game_BattlerBase, the higher
    # the value, the earlier the battler takes its turn during tbs battles
    # Initiative for a battler is calculated once at the begining of the battle
    # states or events affecting the parameters mid-battle will not change the initiative
    INITIATIVE = "agi"
  end

  #----------------------------------------------------------------------------
  # Teams
  #----------------------------------------------------------------------------
  # Battlers (Actors/Enemies) are linked to a team (with a team id), a team
  # have a relationship with other teams that may affect spell targeting,
  # move rules and more importantly, win conditions
  #
  #there are 4 types of relationships (do not change them or their values!):
  SELF = 2     #special case of the battler itself, it is always its ally, useful for skill targeting
  FRIENDLY = 1 #basically allies, units will avoid harming the others and even help them
  NEUTRAL = 0  #neutrals (like obstacles) will not matter much, may be helped or harmed
  ENEMY = -1   #opponents, will try to kill the others

  module TEAMS
    #By default there are 3 main teams, you may add more but do not change the base 3!
    TEAM_ACTORS = 0 #the default team for your party and any actor
    TEAM_NEUTRALS = 1 #the default team for obstacles or neutral units you want to add
    TEAM_ENEMIES = 2 #the default team for the troop and any enemy

    #units in the following teams are player controllable, you may control neutrals or enemies! Obstacles are not controllable though
    PLAYABLE_TEAMS = [TEAM_ACTORS]
    #by default, battles are lost if all units in the following teams are dead
    TEAMS_TO_SURVIVE = [TEAM_ACTORS]
    #by default, battles are won if all units in the following teams are dead
    TEAMS_TO_ROUT = [TEAM_ENEMIES]
    #by default, exp,gold and loot is only rewarded from dead enemies in the following teams:
    TEAMS_TO_LOOT = TEAMS_TO_ROUT

    #TEAM_TABLE defines the relationship between teams, each row is for a team id
    #each column is for the other team id
    #the more teams, the bigger the table must be
    TEAM_TABLE = [
      [TBS::FRIENDLY,TBS::NEUTRAL,TBS::ENEMY], #actors
      [TBS::NEUTRAL,TBS::NEUTRAL,TBS::NEUTRAL],#obstacles
      [TBS::ENEMY,TBS::NEUTRAL,TBS::FRIENDLY], #enemies
    ]

    #this method is used to read the table
    def self.friend_status(team1,team2)
      return TEAM_TABLE[team1][team2]
    end
    #this method determines the total number of teams implemented,
    #here, the number of rows in TEAM_TABLE.
    def self.nb_teams
      return TEAM_TABLE.size
    end

    #set a color per team_id to draw their circle
    TEAM_COLOR = [BLUE,BLACK,RED]

    CIRCLE_FOR_OBSTACLES = false
    #this method is used to read the table
    def self.team_color(team)
      return TEAM_COLOR[team]
    end
  end #module TEAMS

  #----------------------------------------------------------------------------
  # Ability Ranges
  #----------------------------------------------------------------------------
  # Abilities (Skills/Items) are now linked to a range to choose a target
  # A range is an array [min_range, max_range, line_of_sight, range_type]
  # Where min_range (between 0 and max_range) is the minimum distance between the caster and the target
  # max_range is the maximum distance between caster and target
  # line_of_sight (either true or false) decides if the ability may be obstructed by obstacles/other battlers
  # range_type is the shape of the range (see RANGE_TYPES table for all possibilities)
  # A range may be defined as the array above or an array twice the same size:
  # [min_range, max_range, line_of_sight, range_type, area_range, area_range, area_line_of_sight, area_type]
  # Where the area properties will define the shape of the area of effect from the target of the ability
  #
  # Range types:
  # RANGE_TYPES = [:default, :square, :cross, :diagonal, :perpendicular, :line]
  # :default is diamond shape, the distance is based on the sum of x/y distance
  # :square is... square shaped, the distance is based on the max between x and y distance
  # :cross will only consider cells that have the same x or y as the source, (like rook)
  # :diagonal will only consider cells diagonal with source (like bishops)
  # :line and :perpendicular will act like cross if set for the range type
  # :line for area will perform a straight line from the target to the cells behind
  # :perpendicular will perform a straight line that is perpendicular to the source--target line
  # It is advised but not restricted to use :line and :perpendicular areas only with :cross or :diagonal ranges
  #
  # To set the range of an ability, put
  # <range = [m,M,los,type]> in their notetags or
  # <range = [m,M,los,type,am,aM,alos,atype]> to deal with areas
  # Putting a range in weapon notetags allow to change the range of the base attack
  # Only the range of the first weapon is taken into account!
  # Putting a range in enemies notetags allow to change the range of the base attack of enemies
  #
  # Now the parameters:
  # the default range will only affect the source, avoid changing this to
  # something else than [0,0,false,:default] unless you know what you are doing!
  DEFAULT_RANGE = [0,0,false,:default]
  # Default Item range, takes into account the area, it must be an array of size 8!
  DEFAULT_ITEM_RANGE = DEFAULT_RANGE + DEFAULT_RANGE
  # Default skill range is the same as default item range
  DEFAULT_SKILL_RANGE = DEFAULT_ITEM_RANGE
  # Default weapon range: you can target your neighbors but not yourself
  # This will also be used if no weapons are used
  DEFAULT_WEAPON_RANGE = [1,1,false,:default] + DEFAULT_RANGE
  # Default enemy range
  DEFAULT_ENEMY_RANGE = DEFAULT_WEAPON_RANGE

  # Abilities may harm/help units that do not have the intended relationship
  # from the database, you may change this by setting (in your skill/item/weapon notetags):
  # <target_rel = array>
  # With array an array [a,b,...] where a,b are relationships id (-1,0,1,2) (see SELF, FRIENDLY, NEUTRAL or ENEMY values)

  # do you want default help abilities (for user, allies, dead allies...) to affect enemies?
  ENEMY_SUPPORT = false
  # do you want default offensive abilities (for opponents or none) to affect allies?
  FRIENDLY_FIRE = true

  # It is adviced to not change the following 3 values unless you know what you are doing:
  ALL_RELATIONS = [SELF, FRIENDLY, NEUTRAL, ENEMY]
  # The default relationships affected by abilities towards enemies
  DEFAULT_ENEMY_TARGETTING = FRIENDLY_FIRE ? ALL_RELATIONS : [NEUTRAL, ENEMY]
  # The default relationships affected by abilities towards allies
  DEFAULT_ALLY_TARGETTING = ENEMY_SUPPORT ? ALL_RELATIONS : [SELF, FRIENDLY, NEUTRAL]

  # Line of sight (LOS) rules:
  # What is considered an obstacle for abilities with LOS and what is not?
  #
  # The default behavior is that X tiles block view, the rest does not
  # if you want the X tiles not to block view, set the following variable to false:
  DEFAULT_OBSTACLES_HIDE = true
  # the following two lists are exceptions and will take over the rule of DEFAULT_OBSTACLES_HIDE
  REVEAL_TERRAIN_TAG = [1] #any tile with such terrain_tag id won't hide anything
  HIDE_TERRAIN_TAG = [] #any tile with such terrain_tag id will hide everything
  #NOTE: if you are using TBS Height addon, then the previous 3 settings are not
  #      used anymore, trading the use of terrain tag for zone area to handle obstacles

  #Can units block the view?
  #by setting this to true, battlers may also block view
  BATTLER_HIDE = true
  #by setting this to false, neutral units (regarding the caster) are not blocking view
  NEUTRAL_HIDE = false
  #do you want battler in the same team to block the view of others ?
  FRIENDLY_HIDE = false

  #dead battlers won't obstruct the view of abilities if this is set to true
  #else the obstruction will be the same as when the battler is alive
  DEAD_REVEAL_VIEW = true

  # You may force a unit to hide the view of every other units, overriding
  # the relationship hide property, to do so, put in an enemy notetag this:
  # <view_obstacle>

  #----------------------------------------------------------------------------
  # Moves
  #----------------------------------------------------------------------------
  # Units may move during battle in 4 directions, by default, a unit may move
  # any number of times before ending their turn, as long as they have enough
  # move points.
  # The default number of move points for battlers is:
  DEFAULT_MOVE = 3
  # You may set the number of move_points to x in enemies or classes
  # <move = x>
  # Additionally, actors, states and equipments may affect the number of moves:
  # <move = +y>
  # <move = -y>
  # y is added to the number of moves.
  #
  # Units may have different move restrictions, ships may only travel on water
  # airships may travel almost anywhere, but even foot units may have some restrictions
  # for instance, a horse is slower in swamps, thieves may cross enemy units etc.
  # Units are linked to a MoveRule object that will determine their move restrictions:
  #
  # You may set the move rule of a unit in notetags (of actors, class, enemies, states or equipments)
  # <move_rule = name>
  # Here is a list of move_rule names and their corresponding ids
  MOVE_NAMES_TO_ID = {
    "default" => 0,
    "sneak" => 1,
    "horse" => 2,
    "boat" => 3,
    "ship" => 4,
    "fly" => 5,
  }
  #units with no move_rule specified will have move id 0
  DEFAULT_MOVE_RULE = 0
  # note: higher id will always take priority over lower ids for move rules,
  # so if a state adds the fly type (nb 5) to your unit with sneak,
  # its move rule will be replaced,
  # advanced users may change this behaviour in self.move_rule_priority

  # By default, can units cross allied cells?
  DEFAULT_CAN_CROSS_ALLIES = true
  # By default, can non-flying units cross cells with flying units? (both allies and enemies)
  DEFAULT_CAN_GROUND_GO_UNDER_FLIGHT = true

  #----------------------------------------------------------------------------
  # Advanced move settings, edit only if you know what you are doing!
  #----------------------------------------------------------------------------
  # the default cost in move points when crossing a cell (this is overriden by terrain tags)
  DEFAULT_MOVE_COST = 1
  # move types are categories of move rules, they represent what a move rule can
  # cross while the move rule will specify how much it costs
  # you can add custom move types like ghost types or anything if you then add new move rules
  # note that self.tbs_passable? is the way to decide if a tile is passable or not
  # by editing MOVE_NAMES_TO_ID, MOVE_COSTS_TT and MOVE_DATA
  MOVE_TYPES = [:ground,:boat,:ship,:flight]
  #wall is like ground but cannot be crossed by specific units, tall_wall even blocks flying units
  #do not edit them unless you know what you are doing!
  ALL_MOVE_TYPES = MOVE_TYPES + [:wall,:tall_wall]

  #these are constants that should not be changed unless you know what you are doing:
  CROSS_NONE = []
  CROSS_ALL = MOVE_TYPES
  CROSS_GROUND = DEFAULT_CAN_GROUND_GO_UNDER_FLIGHT ? [:flight] : CROSS_NONE
  CROSS_ALLIES_DEFAULT = DEFAULT_CAN_CROSS_ALLIES ? CROSS_ALL : CROSS_GROUND
  CROSS_ALLIES_FLIGHT = DEFAULT_CAN_CROSS_ALLIES ? CROSS_ALL+[:wall] : [:ground,:boat,:ship,:wall]

  #For each move_rule id, set the cost in move points to cross a terrain tag
  MOVE_COSTS_TT = {
    0 => [1,2,3,1,1,1,1,1000], #default
    1 => [1,2,3,1,1,1,1,1000], #sneak
    2 => [0.5,2,100,2,1,1,1,1000], #horse
    3 => [1,1,1,1,1,1,1,1000], #boat
    4 => [1,1,1,1,1,1,1,1000], #ship
    5 => [1,1,1,1,1,1,1,1000], #fly
  }

  #moveType, crossAlliesRel, crossNeutralRel, crossEnemyRel
  MOVE_DATA = [
    [:ground,CROSS_ALLIES_DEFAULT,CROSS_GROUND,CROSS_GROUND],
    [:ground,CROSS_ALL,CROSS_ALL,CROSS_ALL],
    [:ground,CROSS_ALLIES_DEFAULT,CROSS_GROUND,CROSS_GROUND],
    [:boat,CROSS_ALLIES_DEFAULT,CROSS_GROUND,CROSS_GROUND],
    [:ship,CROSS_ALLIES_DEFAULT,CROSS_GROUND,CROSS_GROUND],
    [:flight,CROSS_ALLIES_FLIGHT,[:ground,:boat,:ship,:wall],[:ground,:boat,:ship,:wall]]
  ]

  #given an array of move_rules_ids that a battler carries (states, equipments etc.)
  #picks the id of the move_rules of the battler
  def self.move_rule_priority(move_rule_ids)
    return move_rule_ids.max
  end

  #----------------------------------------------------------------------------
  # Ais
  #----------------------------------------------------------------------------
  #default ai choose their skills and effects based on what you tell them
  #a state might be interresting for an ai to get or bad for them
  #set in the state notetags
  # <ai_rating = v>
  #with v a positive or negative value:
  #negative is something bad to get (so good to inflict on opponents)
  #positive is something good to get (so bad to inflict on opponents)
  #v should be between -10 and +10 to rate how great or bad the state is
  DEFAULT_AI_STATE_RATING = 0 #if nothing is speicied

  #AIs cannot use items but can use skills, by default the skill is taken
  #randomly with weighted values (like default enemies), but in the case
  #of ai-controlled actors or added skills, you may set:
  # <ai_rating = v>
  #with v positive value, usually between 1 and 10
  #this valus is overriden by the enemy skill rate in their database
  DEFAULT_AI_SKILL_RATING = 5 #if nothing is specified

  #The maximum distance the battlers explore to find targets for pathfinding
  AI_VIEW_RANGE = 30

  #============================================================================
  # REGEXP
  #============================================================================
  #REGEXP are used to read the values in the database and set some properties
  #for actors, classes, skills, items, states, equipments and even troops and maps
  #In the case of troops, the notetags are actually comments in the event pages of the troop
  module REGEXP
    BASE_MOVE = /^<move\s*=\s*(\d+)\s*>/i
    MOVE_MODIFIER = /^<move\s*=\s*(\-*\d+)\s*>/i
    MOVEMODE = /^<move_rule\s*=\s*(.+)\s*>/i
    #for weapons, skills and items
    TARGET_REL = /^<target_rel\s*=\s*(\[(\s*\-*\d+\s*(,\s*\-*\d+\s*)*)?\])\s*>/i
    #for abilities (skills/items)
    RANGE = /^<range\s*=\s*(\[\s*\d+\s*,\s*\d+\s*,\s*(true|false)\s*,\s*:[a-z]+\s*(,\s*\d+\s*,\s*\d+\s*,\s*(true|false)\s*,\s*:[a-z]+\s*)?\])\s*>/i
    TARGET_PROPERTY = /^<target_property\s*=\s*(.+)\s*>/i
    RANGE_LIKE_WEAPON = /^<(attack_range)>/i
    #for skills and states (for skills is the chance of picking it, for states its value)
    AI_RATING = /^<ai_rating\s*=\s*(\-*\d+)\s*>/i
    #for enemies, actors, classes and states:
    AI_TACTIC = /^<ai_tactic\s*=\s*(.+)\s*>/i
    #for skills (custom evaluation instead of skill cost)
    #evaluation in Game_Battler (caster) with s the RPG::Skill and t the ai_tactic object
    AI_COST_RATING = /^<ai_cost_rating=\s*(.+)\s*>/i
    #not implemented:
    #TARGET_REL_WEAPON = /^<(attack_target_rel)>/i
    #for states balloons:
    BALLOON = /^<balloon_id\s*=\s*(\d)\s*>/

    #for enemies only
    #display
    FACE_NAME = /^<face_name\s*=\s*(.+)\s*>/i
    FACE_INDEX = /^<face_index\s*=\s*(\d)\s*>/i
    CHARSET = /^<charset\s*=\s*(.+)\s*>/i
    CHAR_INDEX = /^<char_index\s*=\s*(\d)\s*>/i
    CLASS_NAME = /^<class\s*=\s*(.+)\s*>/i
    DESCRIPTION = /^<description\s*=\s*(.+)>/i
    #other
    ALWAYS_BLOCK_VIEW = /(^<view_obstacle\s*>)/i
    REMOVE_ON_DEATH = /(^<remove_on_death\s*>)/i

    #for actors and states, preventing actors from joining battles
    NO_BATTLE = /(^<no_battle\s*>)/i
    #for maps calling another battle map:
    BATTLE_MAP = /^<battle_on\s*=\s*(\d+)\s*>/i
    #for more enemies in troops:
    EXTRA_TROOPS = /^extra_enemies\s*=\s*(\[((\s*\d+\s*),?)+\])/i
    #when the state is added:
    REMOVE_CHILDREN = /(^<remove_children\s*>)/i
  end

  #============================================================================
  # Map Setup
  #============================================================================

  #If event names contains the following substrings:
  module EVENT_NAMES
    #tbs_extra (makes the event visible and may run but cannot be interacted with)
    #tbs_event (makes the event part of the active events on the map)
    EXTRA = 'tbs_extra'
    TBS_EVENT = 'tbs_event'

    #the following list is read by Game_Map, do not edit it or its order!
    LIST = [EXTRA, TBS_EVENT]
  end

  #If a comment in the event active page contains a specific string:
  module EVENT_COMMENTS
    #obstacle i -> puts obstacle corresponding to enemy id i
    #actor i -> puts actor number i from the party/neutrals here if available
    #enemy i -> puts enemy number i from the troop here if available
    #spawn_actor i t -> spawns a new actor i for team t
    #spawn_enemy i t -> spawns a new enemy i for team t
    OBSTACLE = 'obstacle'
    ACTOR = 'actor'
    ENEMY = 'enemy'
    SPAWN_ACTOR = 'spawn_actor'
    SPAWN_ENEMY = 'spawn_enemy'

    #enemy_place -> a random place to put an enemy (from team enemy)
    #party_place -> a selected place to put a party member (from team actor)
    #team_place t -> a random place for team nb t
    PLACE_ENEMY = 'enemy_place'
    PLACE_PARTY = 'party_place'
    PLACE_TEAM = 'team_place'

    #the following two lists are read by Game_Map, do not edit them or their order!
    LIST_FIX = [OBSTACLE,ACTOR,ENEMY,SPAWN_ACTOR,SPAWN_ENEMY]
    LIST_PLACE = [PLACE_ENEMY,PLACE_PARTY,PLACE_TEAM]
  end

  #============================================================================
  # PREVIEW: to handle ability damage previewing
  #============================================================================
  # Are damage estimation displayed over battlers?
  # Can be changed in Option Menu
  PREVIEW_DAMAGE = true
  module PREVIEW
    module STR
      # The arguments are dmg, variation, touch_rate
      # variation and touche_rate are integers representing percents.

      # The following two strings are created by Preview_DamageData
      # and displayed by Sprite_DamagePreview when the battler is in area
      # of ability.
      #method is sprintf(str,dmg,variation,touch_rate)
      DMG_VAR = "%3$d%%\n%1$d" #when variation (%2$d) is not 0
      DMG_NO_VAR = "%3$d%%\n%1$d" #when variation is 0
    end #STR

    #The colors used for damage preview display:
    COLOR_HP_HEAL = GREEN
    COLOR_HP_DAMAGE = RED
    COLOR_MP_HEAL = BLUE
    COLOR_MP_DAMAGE = PURPLE

    #Arrays of color data (RVBA) linked to the hit rate, if hit rate reaches 100
    #then the color at 100 will be used, else, picks a color between the closest
    #two colors of this array baed on the hit rate in %.
    COLOR_TOUCH = {
      0 => [255,0,0,255], #red #don't remove this!
      50 => [255,255,0,255], #yellow
      100 => [0,255,0,255], #green #don't remove this!
    } #do not remove this ~
    #The following keeps the values used in COLOR_TOUCH for
    #faster reading
    COLOR_TOUCH_KEYS = COLOR_TOUCH.keys.sort
    #--------------------------------------------------------------------------
    # get_min_max_colors: returns two index of color data being the closest
    # to the rate used (rate is a value between 0 and 1 representing the hit rate)
    #--------------------------------------------------------------------------
    def self.get_min_max_colors(rate)
      #rate = [rate*100,100].min #just in case
      rate *= 100
      keys = COLOR_TOUCH_KEYS
      maxdex = keys.index {|v| v >= rate}
      mindex = [maxdex-1,0].max#keys.rindex {|v| v <= rate}
      maxdex = keys[maxdex]
      mindex = keys[mindex]
      return mindex,maxdex#COLOR_TOUCH[mindex],COLOR_TOUCH[maxdex]
    end

    #--------------------------------------------------------------------------
    # hit_rate_color: returns a color between two colors data A,B,
    # hit_rate is the chance (between 0 and 1) for the ability to touch
    # the target (and them not to dodge it)
    #--------------------------------------------------------------------------
    def self.hit_rate_color(hit_rate)
      mindex,maxdex = get_min_max_colors(hit_rate)
      c1,c2 = COLOR_TOUCH[mindex],COLOR_TOUCH[maxdex]
      delta = (maxdex - mindex) * 0.01
      rate = delta > 0 ? (hit_rate - mindex * 0.01)/delta : 1
      args = []
      for i in 0...3
        args.push((1-rate)*c1[i] + rate*c2[i])
      end
      return Color.new(*args)
    end
  end #PREVIEW

  #============================================================================
  # Highlighted units colors 0 -> used to change unit color based on caster's
  # friendliness when selected by an ability
  #============================================================================
  #Colors used when units are in area of an ability
  HIGHLIGHT_COLOR = {
    SELF => BLUE,
    FRIENDLY => GREEN,
    NEUTRAL => YELLOW,
    ENEMY => RED,
  }
  UNSELECTED_COLOR = Color.new(0,0,0,128) #when outside of area or unaffected by ability
  #set to false to deactivate highlighting units
  IN_AREA_HIGHLIGHT = true #true means
  #if false, then HIGHLIGHT_COLOR color will not be used but UNSELECTED_COLOR
  #will still be used (if IN_AREA_HIGHLIGHT is true)
  HIGHLIGHT_WITH_COLOR = true

  #============================================================================
  # AI: to design unit's behavior for ais
  #============================================================================
  module AI
    #the name of the default tactic used by ais, if no nam eis specified in
    #<ai_tactic> in actors/classes/enemies or states notetags, this will be used
    #(see default values of Tactic class)
    DEFAULT_TACTIC_NAME = "default"
    #if set to true, ais will test all skills instead of random ones and compare them
    #use this only if your skills heuristics are great and if no skill have unpredictable effetcs
    #like call common events, fleeing combat etc.
    #if set to false, skills will be picked in a random weighted way, which might
    ALL_POSSIBILITIES = false
    #a global multiplier of the ratings of states defined in database
    #(they are integers usually between -100 and 100)
    #putting a 0.01 multiplier allows the states to weight between -1 and 1
    STATE_RATING_NORM = 0.01

    #============================================================================
    # Tactic: stores weight values used in ai calculations (their heuristics)
    # can help designing more aggressive or supporting units
    #============================================================================
    All_AI_Tactics = {} #don't touch this, it will store ai tactics
    class Tactic
      attr_accessor :harm,
                    :summoner_concern, :summon_mul, :obstacle_mul,
                    :hp, :mp, :states, :kill_aim,
                    :mp_save, :tp_save, :move_save,
                    :move_range, :view_range, :safe_distance, :unsafe_distance_rate
                    :name
      #Initialize a tactic with the parameters of the default tactic (agressive one here)
      def initialize(name = DEFAULT_TACTIC_NAME)   #name is used to set monster's ai_level
        #multiplier based on team to consider when affecting
        @harm = {
          ENEMY => 1,     #keep at positive
          NEUTRAL => 0,   #if 0, will ignore neutrals, positive will harm them, negative will help them, < 1 makes it less interesting than opponents, >= 1 makes it as inetresting, if not more than opponents
          FRIENDLY => -1, #keep at negative
          SELF => -1,     #keep at negative, multiply each effect valuation applied to self, very low value means very high concern for your safety
        }
        #multiplier based on tbs status (used both for damage and positionning ratings)
        @summoner_concern = 0.1 #additional multiplier to summoners (sums the threat of each summons times this value and add it the threat level)
        @summon_mul = 0.2       #multiply threat level if unit is a summon, 0 < x < 1 means it will be considered less dangerous than non-summons units
        @obstacle_mul = 0.001   #multiply threat level if unit is an obstacle
        #effect inflcting
        @hp = 1        #multiplier to any hp percent change on the target, keep >= 0 !
        @mp = 0.2      #multiplier to any mp percent change on the target, keep >= 0 !
        @states = 1    #multiplier to each states added or removed (times the state ai_rating), keep >= 0 !
        @kill_aim = 1  #bonus multiplier for killing units, keep >= 0 !
        #resources handling
        @mp_save = 1 #multiplier to any mmp% used, see this as how much 1% of my mmp is worth in mhp% loss of an oppponent?
        @tp_save = 0.1  #multiplier to any mtp% used, see this as how much 1% of my mtp is worth in mhp% loss of an oppponent?
        @move_save = 10 #economic move usage (only if can move later on), just keep it positive or at 0
        #positionning, positive likeness means trying to minimize distance to other units
        #negative means fleeing other units
        @move_range = TBS::AI_VIEW_RANGE #the distance (in move points) from which calculating pathfinding is done when no more action is available, allows planning paths over multiple turns (can change mind)
        @view_range = TBS::AI_VIEW_RANGE #the distance (in cells, regardless of obstacles) from which other units are considered for safe/unsafe position (will ignore any unit beyond this distance in cells)
        @safe_distance = { #will score 0 if inside such range from considered units, value is [min,max], please ensure that min >= max
          ENEMY => [1,1],    #stay close if @unsafe_distance_rate[:enemy] != 0
          NEUTRAL => [1,1],  #stay close if @unsafe_distance_rate[:neutral] != 0
          FRIENDLY => [1,1],     #stay close if @unsafe_distance_rate[:ally] != 0
        }
        @unsafe_distance_rate = { #will add this to the score for each 'unsafe' units based on their distance
          ENEMY => -1,  #try to avoid having enemies out of safe_distance
          NEUTRAL => 0, #do not care about neutral units
          FRIENDLY => 0,    #do not care about ally units
        }
        @name = name

        All_AI_Tactics[name] = self
      end
    end #Tactic
    Default = Tactic.new
    #Berserk will try to reach opponents with no regards for other units or itself
    Berserk = Tactic.new("berserk")
    Berserk.harm[ENEMY] = 2
    Berserk.harm[NEUTRAL] = 0.1 #will try to harm neutral units as consolation price
    Berserk.harm[FRIENDLY] = 0 #has few regards to allies
    Berserk.harm[SELF] = 0 #has few regards to itself
    Berserk.kill_aim = 3  #tries to go for the kill
    Berserk.mp_save = 0   #does not concern itself with its remaining mps
    Berserk.tp_save = 0   #does not concern itself with its remaining tps
    #Support will try to help as much as possible their friends with little regards to opponents
    Support = Tactic.new("support")
    Support.harm[ENEMY] = 0.1
    Support.harm[FRIENDLY] = -10
    Support.unsafe_distance_rate[ENEMY] = 0.2 #a bit fearful of enemies
    Support.unsafe_distance_rate[FRIENDLY] = -1 #keep close to allies
    Support.safe_distance[FRIENDLY] = [1,3]     #this is the safe place to be around friends
    #Ranged will keep a close distance to enemies
    Ranged = Tactic.new("ranged")
    Ranged.safe_distance[ENEMY] = [3,7]
    Ranged.unsafe_distance_rate[ENEMY] = -5 #really dislikes too close enemies
    Ranged.view_range = 9 #won't calculate units that are really too far from self
    #Tank will keep a close eye on most opponents
    Tank = Tactic.new("tank")
    Tank.safe_distance[ENEMY] = [1,3]
    #Crazy will harm its friends, why? for testing purpose
    Crazy = Tactic.new("crazy")
    Crazy.harm[FRIENDLY] = 1
    Crazy.harm[ENEMY] = -1
  end #AI
#==============================================================================
# End of Configuration
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# You may look at the storage objects to check notetags examples but you should
# not edit things below this point
#==============================================================================

  #============================================================================
  # Storage objects: are used by TBS to store battlers properties from TBS Core
  # Do not edit unless you know what you are doing
  #============================================================================
  #Hash tables ({}) contain id => property
  #with id the id of the BaseItem in the database and property what was read in the notetags
  #Arrays ([]) contain ids of the BaseItem with property,
  #if the id is not in the array, then the BaseItem do not have the property
  #Both the Hash tables and the Arrays are set by the notetags from the database

  #Base ranges property = [min_range,max_range,line_of_sight,type]
  #property may be of double size to contain the area
  #to set it, put in the notetags:
  #<range = [m,M,los,type]>
  #<range = [m,M,los,type,am,aM,alos,atype]>
  #ex:
  #<range = [0,5,true,:default]>
  #<range = [2,3,true,:default,0,2,false,:square]>
  SKILL_RANGE = {} #for skills
  ITEM_RANGE = {} #for item
  WEAPON_RANGE = {} #for user attack
  ENEMY_RANGE = {} #for enemy attack

  #for skills/items where you want their range to be defined by their weapon
  #in other words, their range is the same as the base attack:
  #<attack_range>
  SKILL_RANGE_LIKE_WEAPON = []
  ITEM_RANGE_LIKE_WEAPON = []

  #allow enemies (battlers) to obstruct the view of spells/items regardless of the team
  #used mainly for obstacles
  #to set it, put:
  #<view_obstacle>
  ENEMY_VIEW_OBSTACLE = []

  #TARGET_REL tables have property [friend_status1,friend_status2...]
  #where friend_status may be SELF/FRIENDLY/NEUTRAL/ENEMY
  #<target_rel = [a,b]>
  #ex (to target only neutrals):
  #<target_rel = [0]>
  #(to target anyone except yourself):
  #<target_rel = [-1,0,1]>
  SKILL_TARGET_REL = {}
  ITEM_TARGET_REL = {}
  WEAPON_TARGET_REL = {}

  #not implemented:
  #for skills/items where you want their target relationship to be defined by their weapon
  #in other words, their rel is the same as the base attack:
  #<attack_target_rel>
  #SKILL_TARGET_REL_LIKE_WEAPON = []
  #ITEM_TARGET_REL_LIKE_WEAPON = []

  #Property restriciton on the targeted cell by an ability, the
  #TARGET_PROPERTY contains a string that is evaluated as part of Game_Action class
  #<target_property = properties>
  #ex:
  #<target_property = tgt_empty? && tgt_ground?>
  SKILL_TARGET_PROPERTY = {}
  ITEM_TARGET_PROPERTY = {}

  #ratings for ais
  #put (where x is rating)
  #<ai_rating = x>
  #State rating: from -100 to +100, default 0, -100 means
  #that it's similar to loosing 100% hps, in other words:
  #I don't want to have this but want to inflict this!
  #ex:
  #<ai_rating = -3>
  STATE_RATING = {}
  #Skill rating: from 1 to 10, probability of using a skill
  #ex:
  #<ai_rating = 4>
  SKILL_RATING = {}

  #Skill cost rating: override the cost returned by ai heuristic
  #evaluated in Game_Battler environment with parameters s (the skill)
  #and t the tactic
  #ex:
  #<ai_cost_rating = - t.mp_save * s.mp_cost>
  SKILL_COST_RATING = {}

  #The move modification or default move set by the obj
  #<move = m>
  #ex:
  #<move = 3>
  #will add 3 move points when wearing the BaseItem
  #<move = -2>
  #will remove 2 move points when wearing the BaseItem
  ACTOR_MOVE = {}
  STATE_MOVE = {}
  WEAPON_MOVE = {}
  EQUIP_MOVE = {}
  #<move = 3>
  #will set the base move to 3 move points when having class_id or the enemy_id
  CLASS_MOVE = {}
  ENEMY_MOVE = {}

  #The move_rule set by the obj
  #<move_rule = name>
  #ex:
  #<move_rule = sneak>
  STATE_MOVEMODE = {}
  WEAPON_MOVEMODE = {}
  EQUIP_MOVEMODE = {}
  ACTOR_MOVEMODE = {}
  CLASS_MOVEMODE = {}
  ENEMY_MOVEMODE = {}

  #The battlers added automatically to the troop at the begining of combat
  #in comments of troops pages:
  #extra_enemies = [a,b,c]
  #ex:
  #extra_enemies = [1,1,4,1]
  Extra_Troops = {}

  #The enemy display properties
  #<face_name = name>
  #ex:
  #<face_name = Actor1>
  ENEMY_FACE = {}
  #id between 0 and 7
  #<face_index = id>
  #ex:
  #<face_index = 3>
  ENEMY_FACE_INDEX = {}
  #<charset = name>
  #ex:
  #<charset = Monster1>
  ENEMY_CHARSET = {}
  #id between 0 and 7
  #<char_index = id>
  #ex:
  #<char_index = id>
  ENEMY_CHAR_INDEX = {}
  #<class = name>
  #ex:
  #<class = evilkind>
  ENEMY_CLASS = {}
  #<description = text>
  #ex:
  #<description = I'm a slime!>
  ENEMY_DESCRIPTION = {}

  #list the actors and the states such that actor with id or under the state
  #cannot be added in battle through the place phase
  #<no_battle>
  ACTOR_NO_BATTLE = []
  STATE_NO_BATTLE = []
  #stores the enemies that will be removed upon death avoiding resurection or obstruction,
  #note that they will still be counted on exp and gold rewards
  #<remove_on_death>
  ENEMY_DISAPPEAR = []

  #the battle map that wil be called from the current map, by default the current map is used
  #<battle_on = map_id>
  #ex:
  #<battle_on = 4>
  CALL_ALTERNATE_MAP = {}

  #all children/summons linked to the battler will be removed if the battler if
  #the battler is removed from battle or the following state is added:
  #<remove_children>
  STATE_REMOVE_CHILDREN = []

  #displays balloon with id x continuously when uner this state as priority:
  #<balloon_id = x>
  STATE_BALLOON = {}

##########################################
# Enemy Display
##########################################
  def self.enemy_face(enemy_id)
    return ENEMY_FACE[enemy_id] ? ENEMY_FACE[enemy_id] : ""
  end
  def self.enemy_face_index(enemy_id)
    return ENEMY_FACE_INDEX[enemy_id] ? ENEMY_FACE_INDEX[enemy_id] : 0
  end
  def self.enemy_charset(enemy_id)
    return ENEMY_CHARSET[enemy_id] ? ENEMY_CHARSET[enemy_id] : ""
  end
  def self.enemy_char_index(enemy_id)
    return ENEMY_CHAR_INDEX[enemy_id] ? ENEMY_CHAR_INDEX[enemy_id] : 0
  end
  def self.enemy_class(enemy_id)
    return ENEMY_CLASS[enemy_id] ? ENEMY_CLASS[enemy_id] : ""
  end
  def self.enemy_description(enemy_id)
    return ENEMY_DESCRIPTION[enemy_id] ? ENEMY_DESCRIPTION[enemy_id] : ""
  end
##########################################
# Move
##########################################

  def self.class_move(class_id)
    return CLASS_MOVE[class_id] ? CLASS_MOVE[class_id] : DEFAULT_MOVE
  end

  def self.enemy_move(enemy_id)
    return ENEMY_MOVE[enemy_id] ? ENEMY_MOVE[enemy_id] : DEFAULT_MOVE
  end

#move modifiers

  def self.weapon_move(w_id)
    return WEAPON_MOVE[w_id] ? WEAPON_MOVE[w_id] : 0
  end

  def self.equip_move(equip_id)
    return EQUIP_MOVE[equip_id] ? EQUIP_MOVE[equip_id] : 0
  end

  def self.state_move(state_id)
    return STATE_MOVE[state_id] ? STATE_MOVE[state_id] : 0
  end

  def self.actor_move(actor_id)
    return ACTOR_MOVE[actor_id] ? ACTOR_MOVE[actor_id] : 0
  end

##########################################
# MoveMode move_rule
##########################################
  def self.meta_moveMode(id,moveMode_table)
    name = moveMode_table[id]
    return name ? (MOVE_NAMES_TO_ID[name] ? MOVE_NAMES_TO_ID[name] : DEFAULT_MOVE_RULE) : DEFAULT_MOVE_RULE
  end

  def self.state_moveMode(id)
    return TBS.meta_moveMode(id,STATE_MOVEMODE)
  end
  def self.weapon_moveMode(id)
    return TBS.meta_moveMode(id,WEAPON_MOVEMODE)
  end
  def self.equip_moveMode(id)
    return TBS.meta_moveMode(id,EQUIP_MOVEMODE)
  end
  def self.actor_moveMode(id)
    return TBS.meta_moveMode(id,ACTOR_MOVEMODE)
  end
  def self.class_moveMode(id)
    return TBS.meta_moveMode(id,CLASS_MOVEMODE)
  end
  def self.enemy_moveMode(id)
    return TBS.meta_moveMode(id,ENEMY_MOVEMODE)
  end


##########################################
# Range
##########################################

  def self.meta_range(id,default_range,range_table)
    range = range_table[id] ? range_table[id] : default_range
    (range.size...default_range.size).each {|i|
        range << default_range[i]
    }
    return range
  end

  def self.item_range(item_id)
    return TBS.meta_range(item_id,DEFAULT_ITEM_RANGE,ITEM_RANGE)
  end

  def self.skill_range(skill_id)
    return TBS.meta_range(skill_id,DEFAULT_SKILL_RANGE,SKILL_RANGE)
  end

  def self.weapon_range(weapon_id)
    return TBS.meta_range(weapon_id,DEFAULT_WEAPON_RANGE,WEAPON_RANGE)
  end

  def self.enemy_range(enemy_id)
    return TBS.meta_range(enemy_id,DEFAULT_ENEMY_RANGE,ENEMY_RANGE)
  end

  def self.always_hide_view(enemy_id)
    return ENEMY_VIEW_OBSTACLE.include?(enemy_id)
  end

  #to copy the range of the base attack:
  def self.skill_range_like_weapon?(skill_id)
    return SKILL_RANGE_LIKE_WEAPON.include?(skill_id)
  end

  def self.item_range_like_weapon?(item_id)
    return ITEM_RANGE_LIKE_WEAPON.include?(item_id)
  end

##########################################
# Targeting restrictions (allies,neutrals,enemies)
##########################################

  def self.meta_targeting_rel(id,for_ally,target_table)
    l = target_table[id]
    l = (for_ally ? DEFAULT_ALLY_TARGETTING : DEFAULT_ENEMY_TARGETTING) if l.nil?
    return l
  end

  def self.item_targeting_rel(item_id)
    return TBS.meta_targeting_rel(item_id,$data_items[item_id].for_friend?,ITEM_TARGET_REL)
  end

  def self.skill_targeting_rel(skill_id)
    return TBS.meta_targeting_rel(skill_id,$data_skills[skill_id].for_friend?,SKILL_TARGET_REL)
  end

  #not implemented!
  #def self.enemy_targeting_rel(enemy_id)
  #  return TBS.meta_targeting_rel(enemy_id,false,ENEMY_TARGET_REL)
  #end

  #def self.weapon_targeting_rel(skill_id, weapon_id)
  #  return TBS.meta_targeting_rel(weapon_id,false,WEAPON_TARGET_REL)
  #end

  #to copy the targeting restrictions of the base attack:
  #def self.skill_target_rel_attack?(skill_id)
  #  return SKILL_TARGET_REL_LIKE_WEAPON.include?(skill_id)
  #end

  #def self.item_target_rel_attack?(item_id)
  #  return ITEM_TARGET_REL_LIKE_WEAPON.include?(item_id)
  #end

##########################################
# Property on the targeted cell
##########################################
  def self.item_targeting_property(item_id)
    p = ITEM_TARGET_PROPERTY[item_id]
    return p ? p : "true"
  end

  def self.skill_targeting_property(skill_id)
    p = SKILL_TARGET_PROPERTY[skill_id]
    return p ? p : "true"
  end

##########################################
# AI rating on effects
##########################################

  def self.state_ai_rating(state_id)
    p = STATE_RATING[state_id]
    return p.nil? ? DEFAULT_AI_STATE_RATING : p*AI::STATE_RATING_NORM
  end

  def self.skill_ai_rating(skill_id)
    p = SKILL_RATING[skill_id]
    return p.nil? ? DEFAULT_AI_SKILL_RATING : p
  end

  def self.skill_cost_rating(skill_id)
    return SKILL_COST_RATING[skill_id]
  end

##########################################
# Prevent actor_battle
##########################################

  def self.actor_no_battle(actor_id)
    return ACTOR_NO_BATTLE.include?(actor_id)
  end

  def self.state_no_battle(state_id)
    return STATE_NO_BATTLE.include?(state_id)
  end

##########################################
# BALLOON display of states
##########################################
  def self.state_balloon(state_id)
    return STATE_BALLOON[state_id]
  end

##########################################
# Enemy Disappear on death
##########################################

  def self.enemy_disappear(enemy_id)
    return ENEMY_DISAPPEAR.include?(enemy_id)
  end

##########################################
# Remove children on state infliction
##########################################

  def self.state_remove_children?(state_id)
    return STATE_REMOVE_CHILDREN.include?(state_id)
  end

##########################################
# AI tactics
##########################################
  ENEMY_TACTIC = {} #base priority
  CLASS_TACTIC = {} #base priority
  ACTOR_TACTIC = {} #higher priority than class
  STATE_TACTIC = {} #higher priority than the rest, the state position defines which state to pick

  def self.enemy_tactic(enemy_id)
    name = ENEMY_TACTIC[enemy_id]
    name = AI::DEFAULT_TACTIC_NAME unless name
    return AI::All_AI_Tactics[name]
  end

  def self.class_tactic(class_id)
    name = CLASS_TACTIC[class_id]
    name = AI::DEFAULT_TACTIC_NAME unless name
    return AI::All_AI_Tactics[name]
  end

  def self.actor_tactic(actor_id)
    name = ACTOR_TACTIC[actor_id]
    #return nil unless name
    return AI::All_AI_Tactics[name]
  end

  def self.state_tactic(state_id)
    name = STATE_TACTIC[state_id]
    #return nil unless name
    return AI::All_AI_Tactics[name]
  end
end #TBS

#==============================================================================
#
# TBS Note Config
#
#==============================================================================

class RPG::Troop
  def members
    if @extra_troops.nil?
      add_new_members
    end
    return @members
  end
  def add_new_members
    data = TBS::Extra_Troops[@id]
    if data != nil
      for memID in data
        mem = RPG::Troop::Member.new
        mem.enemy_id = memID
        @members << mem
      end
    end
    #Set this flag so that we only add the extra's 1 time
    @extra_troops = true
  end
  #--------------------------------------------------------------------------
  # * New method: note
  #--------------------------------------------------------------------------
  # Reads all "pages" for comments and returns as 'notes'
  #--------------------------------------------------------------------------
  def note
    comment_list = []
    return @notes if !@notes.nil?
    for page in @pages
      next if !page || !page.list || page.list.size <= 0
      note_page = page.list.dup

      note_page.each do |item|
        next unless item && (item.code == 108 || item.code == 408)
        comment_list.push(item.parameters[0])
      end
    end
    @notes = comment_list.join("\r\n")
    return @notes
  end
end

module TBS
#==============================================================
# Easy Config by Clarabel
# Load the settings done in the note place in the editor
# All note entries must be on separate line
#==============================================================
# case ConfigType
# when nil
#   eval data
# when 0
#   set true
# when 1
#   save string
# when 2
#   add id to array
# when 5
#   add string to hash using mapid and subkey region id
# when 6
#   add int to hash using mapid and subkey region id
# when 7
#   Add string to array within hash.
# when 8
#   Add int to array within hash.
#
# REQUIRES VICTOR CORE ENGINE !!
#==============================================================
  # a parameter is set wirh an array [ Hash_To_Store, reg_exp, ConfigType]
  #DATA_SKILLS Config
  SKILLS_EASY_CONFIG = [
    [SKILL_RANGE, REGEXP::RANGE],
    [SKILL_TARGET_REL, REGEXP::TARGET_REL],
    [SKILL_TARGET_PROPERTY,REGEXP::TARGET_PROPERTY,1],
    [SKILL_RANGE_LIKE_WEAPON,REGEXP::RANGE_LIKE_WEAPON,2],
    #[SKILL_TARGET_REL_LIKE_WEAPON,REGEXP::TARGET_REL_WEAPON,2],
    [SKILL_RATING,REGEXP::AI_RATING],
    [SKILL_COST_RATING,REGEXP::AI_COST_RATING,1],
  ]

  #DATA_ITEMS Config
  ITEMS_EASY_CONFIG=[
    [ITEM_RANGE, REGEXP::RANGE],
    [ITEM_TARGET_REL, REGEXP::TARGET_REL],
    [ITEM_TARGET_PROPERTY,REGEXP::TARGET_PROPERTY,1],
    [ITEM_RANGE_LIKE_WEAPON,REGEXP::RANGE_LIKE_WEAPON,2],
    #[ITEM_TARGET_REL_LIKE_WEAPON,REGEXP::TARGET_REL_WEAPON,2],
  ]

  #DATA_WEAPONS Cconfig
  WEAPONS_EASY_CONFIG = [
    [WEAPON_RANGE, REGEXP::RANGE],
    [WEAPON_MOVE, REGEXP::MOVE_MODIFIER],
    [WEAPON_MOVEMODE,REGEXP::MOVEMODE,1],
    [WEAPON_TARGET_REL, REGEXP::TARGET_REL],
  ]

  #DATA_ARMORS Config
  ARMORS_EASY_CONFIG =[
    [EQUIP_MOVE, REGEXP::MOVE_MODIFIER],
    [EQUIP_MOVEMODE,REGEXP::MOVEMODE,1],
  ]

  #DATA_ENEMIES Config
   ENEMIES_EASY_CONFIG =[
     [ENEMY_MOVE, REGEXP::BASE_MOVE],
     [ENEMY_MOVEMODE,REGEXP::MOVEMODE,1],
     [ENEMY_RANGE, REGEXP::RANGE],
     [ENEMY_FACE, REGEXP::FACE_NAME, 1],
     [ENEMY_FACE_INDEX, REGEXP::FACE_INDEX],
     [ENEMY_CHARSET,  REGEXP::CHARSET, 1],
     [ENEMY_CHAR_INDEX, REGEXP::CHAR_INDEX],
     [ENEMY_CLASS,  REGEXP::CLASS_NAME, 1],
     [ENEMY_VIEW_OBSTACLE,REGEXP::ALWAYS_BLOCK_VIEW,2],
     [ENEMY_DISAPPEAR,REGEXP::REMOVE_ON_DEATH,2],
     [ENEMY_DESCRIPTION, REGEXP::DESCRIPTION,1],
     [ENEMY_TACTIC, REGEXP::AI_TACTIC, 1],
   ]

 #DATA_STATES Config
  STATES_EASY_CONFIG = [
    [STATE_MOVE, REGEXP::MOVE_MODIFIER],
    [STATE_MOVEMODE,REGEXP::MOVEMODE,1],
    [STATE_RATING,REGEXP::AI_RATING],
    [STATE_REMOVE_CHILDREN,REGEXP::REMOVE_CHILDREN,2],
    [STATE_NO_BATTLE,REGEXP::NO_BATTLE,2],
    [STATE_TACTIC,REGEXP::AI_TACTIC,1],
    [STATE_BALLOON,REGEXP::BALLOON],
  ]

  ACTOR_EASY_CONFIG = [
    [ACTOR_MOVE, REGEXP::MOVE_MODIFIER],
    [ACTOR_MOVEMODE,REGEXP::MOVEMODE,1],
    [ACTOR_NO_BATTLE,REGEXP::NO_BATTLE,2],
    [ACTOR_TACTIC,REGEXP::AI_TACTIC,1],
  ]

  CLASS_EASY_CONFIG = [
    [CLASS_MOVE, REGEXP::BASE_MOVE],
    [CLASS_MOVEMODE,REGEXP::MOVEMODE,1],
    [CLASS_TACTIC,REGEXP::AI_TACTIC,1],
  ]

  MAP_EASY_CONFIG = [
    [CALL_ALTERNATE_MAP, REGEXP::BATTLE_MAP],
  ]

  TROOP_EASY_CONFIG = [
    [Extra_Troops, REGEXP::EXTRA_TROOPS]
  ]

#============================================================================
#  You don't have to modify this
#============================================================================
#  End of Easy Config script
#  This will effectively load the settings for the game
#============================================================================
# the database parser
# type = name of the file
# all_config = one of the array define above
  def self.easy_config(type, all_config)
    data = load_data('Data/'+type+'.rvdata2')
    max = data.size
    if type == 'MapInfos'
      max += 1
    end
    for i in 1...max
      if type == 'MapInfos'
        filename = sprintf("Data/Map%03d.rvdata2", i)
        if (File.exist?(filename) == false)
          next
        end
        note = load_data(filename).note
      else
        note = data[i].note
      end
      note.gsub!(/[\t\r\f]/,"")
      for line in note.split("\n")
        for config in all_config
          line_note = line.clone
          #unless config[3]
          #
          #end
          line_note.scan(config[1])
          if $1
            case config[2]
            when 8 # hash int array push
              #config[0][i] = [] if (config[0][i]).nil?
              config[0][i] = eval("[" + $1 + "]") #push eval data
            when 7 # hash string array push (as array)
              #Start new array at hash key
              config[0][i] = [] if (config[0][i]).nil?
              config[0][i] << $1
            when 6 # Custom for Map battle transfers based off area
              temp = eval($1)
              config[0][i] ||= {}
              config[0][i][temp] = eval($2)
            when 5 # Custom for battlebacks
              temp = eval($1)
              config[0][i] ||= {}
              config[0][i][temp] = $2
            when 2 # add to array
              if !config[0].include?(i)
                config[0] << i
                config[0].sort!
              end
            when 1 # is a string
              config[0][i] = $1
            when 0 #is a switch parameters
              config[0][i] =  true
            else#value parameter
              config[0][i] =  eval($1)
            end
            break
          end
        end
      end
    end
  end

  def self.on_game_start
    self.easy_config('Skills', SKILLS_EASY_CONFIG)
    self.easy_config('Items', ITEMS_EASY_CONFIG)
    self.easy_config('Weapons', WEAPONS_EASY_CONFIG)
    self.easy_config('Armors', ARMORS_EASY_CONFIG)
    self.easy_config('Enemies', ENEMIES_EASY_CONFIG)
    self.easy_config('States', STATES_EASY_CONFIG)
    self.easy_config('Actors', ACTOR_EASY_CONFIG)
    self.easy_config('Classes', CLASS_EASY_CONFIG)
    self.easy_config('MapInfos', MAP_EASY_CONFIG)
    self.easy_config('Troops', TROOP_EASY_CONFIG)
  end
  self.on_game_start
end #TBS

#==============================================================================
# TBS Part 2: Game Logic
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Deals with everything that is not related to display and ais
#==============================================================================

#============================================================================
# SceneManager
#============================================================================
class << SceneManager
  alias sceneManager_call_tbs call
  alias first_scene_class_tbs first_scene_class
end
module SceneManager
  #--------------------------------------------------------------------------
  # alias method: first_scene_class -> loads tbs battle in test battle mode
  #--------------------------------------------------------------------------
  def self.first_scene_class
    result = first_scene_class_tbs
    result = Scene_TBS_Battle if result == Scene_Battle && TBS::BTEST_MAPID > 0
    return result
  end

  #--------------------------------------------------------------------------
  # alias method: call -> loads Scene_TBS_Battle instead of Scene_Battle if tbs is enabled
  #--------------------------------------------------------------------------
  def self.call(scene_class)
    scene_class = Scene_TBS_Battle if scene_class == Scene_Battle && $game_system.tbs_enabled?
    sceneManager_call_tbs(scene_class)
  end
end


#============================================================================
# Scene_Map
#============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: pre_terminate -> do the same effects as battle when laoding tbs battles
  #--------------------------------------------------------------------------
  alias pre_term_scn_map_tbs pre_terminate
  def pre_terminate
    pre_term_scn_map_tbs
    pre_battle_scene if SceneManager.scene_is?(Scene_TBS_Battle)
  end

  #--------------------------------------------------------------------------
  # overwrite method: pre_battle_scene -> starts the music only when tbs starts
  #--------------------------------------------------------------------------
  def pre_battle_scene
    Graphics.update
    Graphics.freeze
    @spriteset.dispose_characters
    BattleManager.save_bgm_and_bgs
    BattleManager.play_battle_bgm unless SceneManager.scene_is?(Scene_TBS_Battle)
    Sound.play_battle_start
  end
end

#============================================================================
# Game_Interpreter -> adds method for tbs activation, allows map interaction
# during TBS like scrolling, moving events etc.
#============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # new methods: disable_tbs, enable_tbs to switch between tbs call and default battle
  #--------------------------------------------------------------------------
  def disable_tbs
    $game_system.tbs_enabled = false
  end
  def enable_tbs
    $game_system.tbs_enabled = true
  end

  #--------------------------------------------------------------------------
  # alias method: screen -> effects will be seen on the map during tbs battle
  #--------------------------------------------------------------------------
  alias tbs_screen screen
  def screen
    $game_party.in_battle && $game_system.tbs_enabled? ? $game_map.screen : tbs_screen
  end
  #--------------------------------------------------------------------------
  # alias method: get_character -> catch events during battle
  #--------------------------------------------------------------------------
  alias tbs_get_character get_character
  def get_character(param)
    return tbs_get_character(param) unless SceneManager.scene_is?(Scene_TBS_Battle)
    return $game_player if param < 0
    events = same_map? ? $game_map.events : {}
    events[param > 0 ? param : @event_id]
  end
  #--------------------------------------------------------------------------
  # alias method: command_204 -> scroll map
  #--------------------------------------------------------------------------
  alias tbs_command_204 command_204
  def command_204
    return tbs_command_204 unless SceneManager.scene_is?(Scene_TBS_Battle)
    Fiber.yield while $game_map.scrolling?
    $game_map.start_scroll(@params[0], @params[1], @params[2])
  end
  #--------------------------------------------------------------------------
  # alias method: command_236 -> change_weather
  #--------------------------------------------------------------------------
  alias tbs_command_236 command_236
  def command_236
    return tbs_command_236 unless SceneManager.scene_is?(Scene_TBS_Battle)
    screen.change_weather(@params[0], @params[1], @params[2])
    wait(@params[2]) if @params[3]
  end

  #--------------------------------------------------------------------------
  # alias method: command_302 -> shop calls in tbs battle are allowed
  #--------------------------------------------------------------------------
  alias tbs_command_302 command_302
  def command_302
    return tbs_command_302 unless SceneManager.scene_is?(Scene_TBS_Battle)
    goods = [@params]
    while next_event_code == 605
      @index += 1
      goods.push(@list[@index].parameters)
    end
    SceneManager.snapshot_for_background
    SceneManager.call(Scene_Shop)
    SceneManager.scene.prepare(goods, @params[4])
    SceneManager.scene.main #will loop until we leave Scene_Shop
    SceneManager.scene.perform_transition #updates the graphics back
  end
  #--------------------------------------------------------------------------
  # alias method: command_303 -> name input calls in tbs battle are allowed
  #--------------------------------------------------------------------------
  alias tbs_command_303 command_303
  def command_303
    return tbs_command_303 unless SceneManager.scene_is?(Scene_TBS_Battle)
    if $data_actors[@params[0]]
      SceneManager.snapshot_for_background
      SceneManager.call(Scene_Name)
      SceneManager.scene.prepare(@params[0], @params[1])
      SceneManager.scene.main #will loop until we leave Scene_Name
      SceneManager.scene.perform_transition #updates the graphics back
    end
  end

  #--------------------------------------------------------------------------
  # new method: spawn_new_obstacle -> creates a temporary obstacle to be added
  # for the battle in a specific team.
  # Returns the new battler if it was successfully added to the battle, nil otherwise
  #--------------------------------------------------------------------------
  def spawn_new_obstacle(enemy_id,posList,force_place = false)
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    bat = Game_Enemy.new(0,enemy_id)
    $game_troop.add_obstacle(bat)
    res = tbs_add_battler(bat,posList,force_place)
    $game_troop.obstacles.delete(bat) unless res
    return res ? bat : nil
  end

  #--------------------------------------------------------------------------
  # new method: spawn_new_enemy -> creates a temporary enemy to be added
  # for the battle in a specific team.
  # Returns the new battler if it was successfully added to the battle, nil otherwise
  #--------------------------------------------------------------------------
  def spawn_new_enemy(enemy_id,posList,team = TBS::TEAMS::TEAM_ENEMIES,parent = nil, force_place = false)
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    bat = Game_Enemy.new(0,enemy_id)
    bat.team = team
    bat.parent = parent
    res = tbs_add_battler(bat,posList,force_place)
    $game_troop.add_extra_battler(bat) if res
    return res ? bat : nil
  end

  #--------------------------------------------------------------------------
  # new method: spawn_new_actor -> creates a temporary actor to be added
  # for the battle in a specific team, the actor is not part of $game_actors!
  # Returns the new battler if it was successfully added to the battle, nil otherwise
  #--------------------------------------------------------------------------
  def spawn_new_actor(actor_id,posList,team = TBS::TEAMS::TEAM_ACTORS,parent = nil, force_place = false)
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    bat = Game_Actor.new(actor_id)
    bat.team = team
    bat.parent = parent
    res = tbs_add_battler(bat,posList,force_place)
    $game_troop.add_extra_battler(bat) if res
    return res ? bat : nil
  end

  #--------------------------------------------------------------------------
  # new method: spawn_actor -> adds an actor (may reset it) to the party, sets its
  # team and tries to place it with tbs_add_battler. Might reset the actor if the option is chosen
  # If it fails, the actor will still be in the party (or neutrals)
  # If the actor was already in battle, it will only change their team
  # Returns true iff the actor was successfully added to the battle
  #--------------------------------------------------------------------------
  def spawn_actor(actor_id,posList,team = TBS::TEAMS::TEAM_ACTORS, setup = false, parent = nil, force_place = false)
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    return false if $game_actors[actor_id].tbs_battler #can't add an actor that is already there
    $game_party.tbs_add_actor(actor_id,team,setup)
    bat = $game_actors[actor_id]
    bat.parent = parent
    return tbs_add_battler(bat,posList,force_place)
  end

  #--------------------------------------------------------------------------
  # new method: tbs_rm_battler -> adds a battler to the first available place
  # in posList (a list of positions [x,y]), if force_place is true, ignores
  # the move restrictions of the battler
  # Can be called before the place phase ended or mid battle
  # Returns true iff the battler was successfully added to the battle
  #--------------------------------------------------------------------------
  def tbs_add_battler(bat,posList,parent = nil,force_place = false)
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.add_battler(bat,posList,force_place)
  end

  #--------------------------------------------------------------------------
  # new method: tbs_rm_battler -> remove a battler from tbs if it exists, does not remove it from party/troop
  #--------------------------------------------------------------------------
  def tbs_rm_battler(battler)
    return unless SceneManager.scene_is?(Scene_TBS_Battle)
    SceneManager.scene.remove_battler(battler)
  end
  #--------------------------------------------------------------------------
  # new method: force_tbs_action
  # Casts skill_id on target position, does not check any range property
  # If check_range, the action will be used only if tgt is in range from
  # battler's position
  # tgt is an array [x,y]
  #--------------------------------------------------------------------------
  def force_tbs_action(bat, skill_id, tgt, check_range = false)
    bat.force_tbs_action(skill_id, tgt, check_range)
  end
end #Game_Interpreter

#==============================================================================
#
# TBS Game_System
#
#==============================================================================

#============================================================================
# Game_System
#============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  #attr_reader   :battle_events
  attr_accessor :move_color
  attr_accessor :help_skill_color
  attr_accessor :attack_skill_color
  attr_accessor :attack_color
  attr_accessor :place_color
  attr_accessor :tbs_enabled
  attr_accessor :turn_mode
  attr_reader   :victory_cond_texts
  attr_accessor :place_music

  #for options menu
  attr_accessor :help_window, :team_sprite, :highlight_units, :pre_place,
  :turn_id, :preview_damage, :anim_range,:area_blink, :area_blink_color
  attr_reader :confirm_hash

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tbs_gs_init initialize
  def initialize
    reset_victory_text
    reset_default_tbs_config
    reset_place_music
    #@battle_events       = {}
    @turn_mode = TBS::DEFAULT_TURN_SYSTEM
    @tbs_enabled         = true
    tbs_gs_init
  end

  #--------------------------------------------------------------------------
  # new method: tbs_enabled?
  #--------------------------------------------------------------------------
  def tbs_enabled?
    return @tbs_enabled
  end

  #--------------------------------------------------------------------------
  # new method: reset_default_tbs_config -> at the intialization or by config window
  #--------------------------------------------------------------------------
  def reset_default_tbs_config
    @move_color          = TBS::DEFAULT_MOVE_COLOR
    @help_skill_color    = TBS::DEFAULT_HELP_SKILL_COLOR
    @attack_skill_color  = TBS::DEFAULT_ATK_SKILL_COLOR
    @attack_color        = TBS::DEFAULT_ATK_COLOR
    @place_color         = TBS::DEFAULT_PLACE_COLOR

    @help_window         = false #displays the help window in actor commands menu
    @team_sprite         = true  #displays the circle representing the team sprite
    @highlight_units     = false #displays the unit in semi-transparency (like dofus) and above any tiles
    @pre_place           = false #auto place the first available party members in random cells
    @turn_id             = false #displays the id the turn position of the battler
    @preview_damage      = TBS::PREVIEW_DAMAGE  #displays an estimation of the damage performed by the spell on the target
    @anim_range          = TBS::ANIM_TILES #for transparency change of the ranges
    @area_blink          = TBS::IN_AREA_HIGHLIGHT #will change
    @area_blink_color    = TBS::HIGHLIGHT_WITH_COLOR #will choose if units in area are colored based on friendship

    @confirm_hash        = TBS::Confirm::BOOL_CONFIRM.dup
  end

  #--------------------------------------------------------------------------
  # new method: reset_victory_text
  #--------------------------------------------------------------------------
  def reset_victory_text
    set_victory_text(TBS::Vocab::Default_Victory_Cond_Texts)
  end

  #--------------------------------------------------------------------------
  # new method: set_victory_text -> set the text displayed when opening Window_WinConditions
  # textLines is an array of strings, one per lines displayed
  #--------------------------------------------------------------------------
  def set_victory_text(textLines)
    @victory_cond_texts = textLines
  end

  #--------------------------------------------------------------------------
  # new method: reset_place_music -> sets the place phase music to the parameters
  #--------------------------------------------------------------------------
  def set_place_music(bgm_name,volume,pitch)
    @place_music = RPG::BGM.new(bgm_name,volume,pitch)
  end
  #--------------------------------------------------------------------------
  # new method: reset_place_music -> sets the place phase music to the default one
  #--------------------------------------------------------------------------
  def reset_place_music
    @place_music = TBS::PLACE_MUSIC
  end
end

#==============================================================================
#
# TBS Game_Character_TBS
#
#==============================================================================

#============================================================================
# Game_Character_TBS: used inside all tbs battlers to position them and apply effects
#============================================================================
class Game_Character_TBS < Game_Character
  #--------------------------------------------------------------------------
  # overload method: initialize
  #--------------------------------------------------------------------------
  def initialize(battler)
    @battler = battler
    super()
  end
  #--------------------------------------------------------------------------
  # override method: init_public_members
  #--------------------------------------------------------------------------
  def init_public_members
    super
    #@id = 0
    #@x = 0
    #@y = 0
    #@real_x = 0
    #@real_y = 0
    #@tile_id = 0
    #@character_name = ""
    #@character_index = 0
    #@move_speed = 4
    #@move_frequency = 6
    #@walk_anime = true
    @step_anime = true
    @tbs_route = []
    #@direction_fix = false
    #@opacity = 255
    #@blend_type = 0
    #@direction = 2
    #@pattern = 1
    #@priority_type = 1
    @through = true
    #@bush_depth = 0
    #@animation_id = 0
    #@balloon_id = 0
    #@transparent = false
    #@original_character_name = @bat_char_index = nil
    #@current_state = :default
  end

  #--------------------------------------------------------------------------
  # override method: update -> walk along the path set when moving
  #--------------------------------------------------------------------------
  def update
    super
    update_tbs_move
  end

  #--------------------------------------------------------------------------
  # new method: update_tbs_move
  #--------------------------------------------------------------------------
  def update_tbs_move
    if @tbs_route.size > 0 && !moving? && !$game_troop.interpreter.running?
      dir = @tbs_route.shift
      instance_eval("move_straight(#{dir})")
    end
  end

  #--------------------------------------------------------------------------
  # new method: set_obstacle -> set the properties of obstacle chars
  #--------------------------------------------------------------------------
  def set_obstacle
    @walk_anime = @step_anime = false
    @direction_fix = true
  end

  #--------------------------------------------------------------------------
  # new method: set_tbs_route -> set the path that the char will follow when moving the battler
  #--------------------------------------------------------------------------
  def set_tbs_route(route)
    @tbs_route = route
  end
  #--------------------------------------------------------------------------
  # new method: reset_tbs_route
  #--------------------------------------------------------------------------
  def reset_tbs_route
    @tbs_route = []
  end
  #--------------------------------------------------------------------------
  # override method: screen_z -> takes into account the transparency option
  #--------------------------------------------------------------------------
  def screen_z
    super + ($game_system.highlight_units ? TBS::TRANSPARENT_Z : 0)
  end
end

#==============================================================================
#
# TBS Game_Battler
#
#==============================================================================

#============================================================================
# Game_BattlerBase
#============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :initiative #priority on the turnWheel, the higher, the sooner it plays

  #--------------------------------------------------------------------------
  # new method: roll_initiative -> called once per battle when the battler is added to the turnwheel
  #--------------------------------------------------------------------------
  def roll_initiative
    return @initiative = eval(TBS::FORMULA::INITIATIVE)
  end

  #--------------------------------------------------------------------------
  # new method: threat_from -> return a value representing how much the other battler
  # is considered important/dangerous to this battler
  # higher threat means more likely to be targeted by ais (not random attacks)
  # both friendly and opponents
  #--------------------------------------------------------------------------
  def threat_from(bat); bat.tgr; end
end #Game_BattlerBase

#============================================================================
# Game_Battler
#============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :mmov                     # max movements
  attr_reader :spent_mov                # movements spent this turn
  attr_reader :char                     # current game_character
  attr_reader :character_name           # character graphic filename
  attr_reader :character_index          # character graphic index
  attr_reader :face_name                # face graphic filename
  attr_reader :face_index               # face graphic index
  attr_accessor :team                   # id of your team
  attr_accessor :parent                 # ref of your parent if you are a summon
  attr_accessor :tbs_battler            # bool indicating if you are in battle
  attr_accessor :turn_id                # int representing the position in the turnwheel
  attr_reader :ai                       # ai object to take decisions for autobattle and opponents
  attr_accessor :dmg_preview            # [str, colors_array] str is a string with \n for new lines, colors_array lists one color per line.
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tbs_battler_initialize initialize
  def initialize
    tbs_battler_initialize
    #@mmov = 0
    @spent_mov = 0
    @char = Game_Character_TBS.new(self)
    @team = TBS::TEAMS::TEAM_NEUTRALS
    @tbs_active = false #check if unit is "playable"
    @tbs_battler = false
    #@my_turn = 0 #used to check that no multiple turns are performed by the battler
    @parent = nil
    @obstacle = false #assert oif battler is obstacle
    @turn_id = nil
    #move data
    #@old_pos = POS.new(0,0)
    #@old_dir = 2
    init_ai
  end

  #--------------------------------------------------------------------------
  # new method: pos -> the position on the map of the battler
  #--------------------------------------------------------------------------
  def pos
    POS.new(@char.x,@char.y)
  end

  #--------------------------------------------------------------------------
  # new method: moveto -> teleports the battler
  #--------------------------------------------------------------------------
  def moveto(x,y)
    @char.moveto(x,y)
  end

  #--------------------------------------------------------------------------
  # new methods: nickname, level
  #--------------------------------------------------------------------------
  def nickname; ""; end
  def level; 0; end

  #--------------------------------------------------------------------------
  # alias method: on_battle_start -> called at the begining of battle
  #--------------------------------------------------------------------------
  alias tbs_on_battle_start on_battle_start
  def on_battle_start
    #@char.reinitialize
    tbs_on_battle_start
    @spent_mov = 0
    @my_turn = 0
    update_char
    #init_tp unless preserve_tp?
  end
  #--------------------------------------------------------------------------
  # alias method: on_action_end -> Processing at End of Action
  #--------------------------------------------------------------------------
  alias tbs_on_action_end on_action_end
  def on_action_end
    #@result.clear
    #remove_states_auto(1)
    #remove_buffs_auto
    tbs_on_action_end
  end
  #--------------------------------------------------------------------------
  # alias method: on_action_end -> Processing at End of battler's turn
  #--------------------------------------------------------------------------
  alias tbs_on_turn_end on_turn_end
  def on_turn_end
    #@result.clear
    #regenerate_all
    #update_state_turns
    #update_buff_turns
    #remove_states_auto(2)
    @tbs_active = false
    @spent_mov = 0 #reset the spent mov, if it is modfiied before my turn, then it will affect my next turn
    tbs_on_turn_end
  end
  #--------------------------------------------------------------------------
  # alias method: on_battle_end -> Processing at End of battle
  #--------------------------------------------------------------------------
  alias tbs_on_battle_end on_battle_end
  def on_battle_end
    tbs_on_battle_end
    @char.reset_tbs_route
    @tbs_active = false
    #tbs_leave
    #clear_actions
    #@result.clear
  end

  #--------------------------------------------------------------------------
  # alias method: remove_current_action -> now stores the info that the action was played
  #--------------------------------------------------------------------------
  alias tbs_remove_current_action remove_current_action
  def remove_current_action
    @has_played = true
    tbs_remove_current_action
  end

  #--------------------------------------------------------------------------
  # new method: skip_turn -> forbids the battler to take further actions, called before on_turn_end
  #--------------------------------------------------------------------------
  def skip_turn(new_dir = @char.direction)
    @tbs_active = false
    @char.set_direction(new_dir)
  end

  #--------------------------------------------------------------------------
  # new method: on_turn_start -> Processing at Begining of battler's turn
  #--------------------------------------------------------------------------
  def on_turn_start
    #t = $game_troop.turn_count
    @has_played = false
    @tbs_active = true #unless @my_turn >= t #skip turn repetition
    #@my_turn = t
    #@spent_mov = 0#mmov
  end
  #--------------------------------------------------------------------------
  # new method: is_active? -> determine if the battler may take actions at the moment
  #--------------------------------------------------------------------------
  def is_active?; return @tbs_active; end

  #--------------------------------------------------------------------------
  # new method: has_played? -> determine if the battler took at least one action during its turn
  #--------------------------------------------------------------------------
  def has_played?; return @has_played; end

  #--------------------------------------------------------------------------
  # new method: update_char -> update the display of the battler if needed
  #--------------------------------------------------------------------------
  def update_char
    @char.set_graphic(@character_name,@character_index)
  end

  #--------------------------------------------------------------------------
  # new method: update -> called during Scene_TBS_Battle updates
  #--------------------------------------------------------------------------
  def update
    @char.update
    @char.balloon_id = get_state_balloon
  end

  #--------------------------------------------------------------------------
  # new method: get_state_balloon
  #--------------------------------------------------------------------------
  def get_state_balloon
    s = @states.find{|s| TBS.state_balloon(s)}
    return s ? TBS.state_balloon(s) : 0
  end

  #--------------------------------------------------------------------------
  # alias method: hide -> completly remove the battler from the battlers list, please use it once!
  #--------------------------------------------------------------------------
  alias tbs_gb_hide hide
  def hide
    tbs_gb_hide
    SceneManager.scene.remove_battler(self) if SceneManager.scene_is?(Scene_TBS_Battle)
  end

  #--------------------------------------------------------------------------
  # new method: tbs_entrance -> called by the scene to initialize the battler
  #--------------------------------------------------------------------------
  def tbs_entrance(x,y,team=nil)
    @char.reset_tbs_route
    moveto(x,y)
    appear
    @tbs_battler = true
    @team = team unless team.nil?
  end

  #--------------------------------------------------------------------------
  # new method: tbs_leave -> called by the scene to cancel the addition of the battler
  #--------------------------------------------------------------------------
  def tbs_leave
    @char.reset_tbs_route
    @tbs_active = @tbs_battler = false
  end

  #--------------------------------------------------------------------------
  # new method: can_battle -> check if the battler can be included in a tbs battle, relevant when you want party members not to be included in battles
  #--------------------------------------------------------------------------
  def can_battle?
    return true
  end

  #--------------------------------------------------------------------------
  # new method: set_obstacle -> turn the battler into an obstacle, a bat that does not do anything
  #--------------------------------------------------------------------------
  def set_obstacle
    @obstacle = true
    @char.set_obstacle
  end

  #--------------------------------------------------------------------------
  # new method: obstacle?
  #--------------------------------------------------------------------------
  def obstacle?; @obstacle; end

  #--------------------------------------------------------------------------
  # new method: mmov -> maximal amount of move points per turn
  #--------------------------------------------------------------------------
  def mmov
    return 0
  end

  #--------------------------------------------------------------------------
  # new method: available_mov -> the number of remaining move points this turn
  #--------------------------------------------------------------------------
  def available_mov
    return mmov - @spent_mov
  end

  #--------------------------------------------------------------------------
  # new method: can_move?
  #--------------------------------------------------------------------------
  def can_move?
    return available_mov > 0 && !obstacle?
  end

  #--------------------------------------------------------------------------
  # new method: move_rule_id
  #--------------------------------------------------------------------------
  def move_rule_id
    return TBS.DEFAULT_MOVE_RULE
  end

  #--------------------------------------------------------------------------
  # new method: force_move_through_path
  #--------------------------------------------------------------------------
  #route is a list of directions, cost is the total cost of route
  #the battler takes the route regardless of its feasability
  def force_move_through_path(route,cost)
    #@old_pos = pos
    #@old_dir = @char.direction
    @char.set_tbs_route(route) #force_move_route(route)
    @spent_mov += cost
  end

  #--------------------------------------------------------------------------
  # new method: cut_route
  #--------------------------------------------------------------------------
  #cut the input route if it costs too much for the battler move points
  def cut_route(route,cost,move_points = available_mov)
    return route,cost if cost <= move_points
    path = TBS_Path.new
    path.set_route(self,[],0) #from the source
    #get the subroute that can be crossed in a single turn
    for d in route
      path.push_dir(d)
      if path.cost > move_points
        path.pop_dir
        break
      end
    end
    #remove any last tile that is aready occupied
    tgt = path.dest
    while !(can_occupy?(tgt) || path.route.empty?)
      path.pop_dir
      tgt = path.dest
    end
    return path.route, path.cost
  end

  #--------------------------------------------------------------------------
  # new method: move_through_path
  #--------------------------------------------------------------------------
  #if the route is feasable, do it, else, cut it until it is feasable and then do it
  def move_through_path(route,cost)
    @has_played = true
    r2,c2 = cut_route(route,cost)
    return force_move_through_path(r2,c2)
  end

  #Array of [dir, dx, dy] to test the 4 directions
  TEST_DIR = [ [2, 0, 1], [4, -1, 0], [6, 1, 0], [8, 0, -1] ]

  #--------------------------------------------------------------------------
  # new method: can_occupy? -> can the battler stay in this cell? return true iff no other battle occupies the cell
  #--------------------------------------------------------------------------
  def can_occupy?(pos)
    return $game_map.occupied_by?(pos[0],pos[1]).nil?
  end

  #--------------------------------------------------------------------------
  # new method: can_cross? -> can the battler with the moveRule cross the position
  # nu_pos from prev_pos through direction dir?
  #--------------------------------------------------------------------------
  def can_cross?(moveRule,dir,prev_pos,nu_pos)
    return false unless TBS.tbs_passable?(prev_pos[0],prev_pos[1],dir,moveRule.travel_mode)
    return false unless TBS.tbs_passable?(nu_pos[0],nu_pos[1],TBS.reverse_dir(dir),moveRule.travel_mode)
    battler2 = $game_map.occupied_by?(nu_pos[0],nu_pos[1])
    return false unless battler2.nil? || can_cross_bat?(moveRule,battler2)
    evList = $game_map.battle_events_at(nu_pos[0],nu_pos[1])
    return false if evList.any? {|event| !can_cross_ev?(moveRule,dir,event)}
    return true
  end

  #--------------------------------------------------------------------------
  # new method: can_cross_ev? -> can the battler with the moveRule cross the
  # battle event? (only called for tbs_events)
  #--------------------------------------------------------------------------
  def can_cross_ev?(moveRule,dir,event)
    return !event.normal_priority?
  end

  #--------------------------------------------------------------------------
  # new method: can_cross_bat? -> can the battler with the moveRule cross the other_battler?
  #--------------------------------------------------------------------------
  def can_cross_bat?(moveRule,other_battler)
    return true if other_battler.dead? #dead units are crossable
    other_move_type = TBS::MOVE_DATA[other_battler.move_rule_id][0]
    case true_friend_status(other_battler)
    when TBS::ENEMY
      return moveRule.cross_enemies.include?(other_move_type)
    when TBS::NEUTRAL
      return moveRule.cross_neutrals.include?(other_move_type)
    when TBS::FRIENDLY
      return moveRule.cross_allies.include?(other_move_type)
    when TBS::SELF
      return true
    end
    return false #this should not happen unless other relationships types are defined
  end

  #--------------------------------------------------------------------------------------------------------------
  # new method: calc_pos_move -> given a number of move_points, returns 2 hash tables route, cost with keys positions [x,y] that are reachable
  # for any reachable position p, route[p] is an array of directions (2,4,6,8) to go from bat.pos to p and cost is the total cost in move points
  # ie: calc_pos_move generates optimal paths from the battler to all other reachable positions in range
  # optional parameter:
  # - forbidden_list containing specific positions excluded from paths
  #-------------------------------------------------------------------------------------------------------------
  def calc_pos_move(move_distance = available_mov, forbidden_list = [])
    #return {},{} unless can_move?
    moveRule = MoveRule.new(move_rule_id)
    #start position initialization
    start_pos = pos.x, pos.y    #push starting position
    route = {start_pos => []}                                  #initialize route #Push empty route for starting postion
    cost = {start_pos => 0}                                       #start position cost = 0
    return route,cost unless can_move?
    more_step = [start_pos]                                  #initialize array
    for _pos in more_step                              #each step in position
      x, y = _pos                          #set x, y for index
      c = cost[_pos]                                  #set cost for current postion index
      for dir,dx,dy in TEST_DIR   # loop for the four directions
        nu_pos = (nu_x, nu_y = x + dx, y + dy)#pos + posDelta
        next if forbidden_list.include?(nu_pos)
        next unless can_cross?(moveRule,dir,_pos,nu_pos)
        nu_cost = c + $game_map.cost_move(moveRule,nu_x,nu_y,dir)
        next if nu_cost > move_distance          # Abort tests if current route cost is bigger than move_range
        old_cost = cost[nu_pos]
        # if not reached yet or old_cost is bigger
        if !old_cost || old_cost > nu_cost
          route[nu_pos] = route[_pos] + [dir]
          cost[nu_pos] = nu_cost
          more_step.push(nu_pos) if nu_cost < move_distance
        end
      end#4dir loop for
    end

    for _pos in cost.keys #check all positions and remove the ones you can't stay at
      battler2 = $game_map.occupied_by?(_pos[0], _pos[1])
      route.delete(_pos) unless battler2.nil? || can_cross_bat?(moveRule,battler2)
      #route.delete(pos) unless can_occupy?(pos)
    end
    return route, cost
  end

  #--------------------------------------------------------------------------------------------------------------
  # new method: reverse_calc_pos_move -> returns how much it cost for each cell to reach the target_pos
  # will return two hash tables route,cost with:
  #  route: position -> array of directions [2,4,6,8] as a path from position to target_pos
  #  cost:  position -> float being the cost of the above path
  # This performs a similar process as calc_pos_move but instead is intended to reach a specific
  # cell from different positions.
  #-------------------------------------------------------------------------------------------------------------
  def reverse_calc_pos_move(target_pos = pos, move_distance = available_mov, forbidden_list = [])
    prev_x, prev_y = pos.x, pos.y
    moveto(target_pos[0],target_pos[1])
    r,c = calc_pos_move(move_distance, forbidden_list)
    moveto(prev_x, prev_y)

    moveRule = MoveRule.new(move_rule_id)
    cost = $game_map.cost_move(moveRule,target_pos[0],target_pos[1],0)
    r.each_pair do |p,route|
      next if route.empty?
      route.reverse!.map!{|d| TBS.reverse_dir(d)}
      c[p] += cost - $game_map.cost_move(moveRule,p[0],p[1],0)
    end
    return r,c
  end


  #--------------------------------------------------------------------------------------------------------------
  # new method: astar_heuristic -> used by A* algorithm below
  #-------------------------------------------------------------------------------------------------------------
  def astar_heuristic(cost,p,target,min_travel)
    cost + min_travel * ((p[0]-target[0]).abs + (p[1]-target[1]).abs)
  end

  #--------------------------------------------------------------------------------------------------------------
  # new method: astar -> performs A* algorithm to compute a path from current position to target position
  # should be a bit faster than calc_pos_move but is unused as of right now
  #-------------------------------------------------------------------------------------------------------------
  def astar(target, move_distance = available_mov, forbidden_list = [])
    moveRule = MoveRule.new(move_rule_id)
    min_travel = moveRule.move_cost_tt.min
    #start position initialization
    start_pos = pos.x, pos.y    #push starting position
    route = {start_pos => []}                                  #initialize route #Push empty route for starting postion
    cost = {start_pos => 0}                                       #start position cost = 0
    return route,cost unless can_move?
    more_step = [start_pos]                                  #initialize array
    until more_steps.empty?
      _pos = more_steps.pop
      x,y = _pos
      c = cost[_pos]
      for dir,dx,dy in TEST_DIR   # loop for the four directions
        nu_pos = (nu_x, nu_y = x + dx, y + dy)
        next if forbidden_list.include?(nu_pos)
        next unless can_cross?(moveRule,dir,_pos,nu_pos)
        nu_cost = c + $game_map.cost_move(moveRule,nu_x,nu_y,dir)
        next if nu_cost > move_distance          # Abort tests if current route cost is bigger than move_range
        old_cost = cost[nu_pos]
        # if not reached yet or old_cost is bigger
        if !old_cost || old_cost > nu_cost
          route[nu_pos] = route[_pos] + [dir]
          cost[nu_pos] = nu_cost
          if nu_cost < move_distance
            my_h = astar_heuristic(nu_cost,nu_pos,target,min_travel)
            i = more_step.rindex{|p| astar_heuristic(cost[p],p,target,min_travel) >= my_h}
            i = -1 unless i
            more_step.insert(i+1,nu_pos)
          end
          #more_step.push(nu_pos) if nu_cost < move_distance
        end
        return route[target], cost[target] if target == nu_pos #end when target is found
      end
    end
    return route[target], cost[target]
  end

  #def cancel_move_path(cost)
  #  @char.set_move_route([])
  #  @spent_mov -= cost
  #  moveto(@old_pos.x,@old_pos.y)
  #  @char.set_direction(@old_dir)
  #end

  #--------------------------------------------------------------------------
  # overwrite method: opposite? -> now the team matters instead of the battler's class
  #--------------------------------------------------------------------------
  def opposite?(battler)
    true_friend_status(battler) == TBS::ENEMY || battler.magic_reflection
  end

  #--------------------------------------------------------------------------
  # new method: true_friend_status -> checks the relationship with another battler
  #--------------------------------------------------------------------------
  def true_friend_status(other)
    return TBS::SELF if self.equal?(other)
    return TBS::TEAMS.friend_status(@team, other.team)
  end

  #--------------------------------------------------------------------------
  # new method: friend_status -> checks the relationship with another battler
  # but judgement may be affected by confusion states
  #--------------------------------------------------------------------------
  def friend_status(other)
    return true_friend_status(other) unless (confusion? && confusion_level > 1)
    return TBS::NEUTRAL if confusion_level == 2
    r = true_friend_status(other)
    return r == TBS::SELF ? TBS::ENEMY : -r
  end

  #--------------------------------------------------------------------------
  # new method: getRange -> returns a SpellRange associated to an ability
  #--------------------------------------------------------------------------
  #id is id of the ability in the database
  #type is the ability type, either :skill or :item
  def getRange(id,type)
    range =  nil
    case type
    when :item
      range = attack_range?(id,type) ? getRangeWeapon() : TBS.item_range(id)
    when :skill
      range = attack_range?(id,type) ? getRangeWeapon() : TBS.skill_range(id)
    end
    r2 = range.each_slice(4).to_a
    return spellRg = SpellRange.new(r2[0],r2[1])
  end

  #--------------------------------------------------------------------------
  # new method: attack_range? -> returns true if the skill/item uses an attack range
  #--------------------------------------------------------------------------
  def attack_range?(id,type)
    (type == :skill && (id == attack_skill_id || TBS.skill_range_like_weapon?(id))) || (type == :item && TBS.item_range_like_weapon?(id))
  end

  #--------------------------------------------------------------------------
  # new method: getRangeWeapon -> returns an array to initialize the SpellRange of the attack skill
  #--------------------------------------------------------------------------
  def getRangeWeapon
    TBS.DEFAULT_WEAPON_RANGE
  end

  #--------------------------------------------------------------------------
  # new method: genTgt -> returns an array of [x,y] cells that the spell may target from the current position
  #--------------------------------------------------------------------------
  def genTgt(spellRg)
    TBS.getTargetsList(self,pos,spellRg)
  end

  #--------------------------------------------------------------------------
  # new method: genArea -> returns an array of [x,y] cells that are covered by the area of the spell on tgt
  #--------------------------------------------------------------------------
  def genArea(tgt,spellRg)
    TBS.getArea(self,pos,tgt,spellRg)
  end

  #--------------------------------------------------------------------------
  # new method: always_hide_view?
  #--------------------------------------------------------------------------
  def always_hide_view?; false; end

  #--------------------------------------------------------------------------
  # new method: hide_view? -> return if this battler hides the view from other (when other tries to cast an ability)
  #--------------------------------------------------------------------------
  def hide_view?(other)
    return false if dead? && TBS::DEAD_REVEAL_VIEW
    return true if always_hide_view?
    rel = true_friend_status(other)
    return false if rel == TBS::SELF
    return TBS::NEUTRAL_HIDE if rel == TBS::NEUTRAL
    return TBS::FRIENDLY_HIDE if rel == TBS::FRIENDLY
    return TBS::BATTLER_HIDE
  end

  #--------------------------------------------------------------------------
  # new method: remove_on_death? -> by default, obstacles are removed forever from battles when dying
  #--------------------------------------------------------------------------
  def remove_on_death?; obstacle?; end

  #--------------------------------------------------------------------------
  # alias method: add_new_state -> remove the battler from the map when dead if conditions are met
  # remove the children too if the state deletes them
  #--------------------------------------------------------------------------
  alias tbs_add_new_state add_new_state
  def add_new_state(state_id)
    tbs_add_new_state(state_id)
    if SceneManager.scene_is?(Scene_TBS_Battle) && SceneManager.scene.phase
      SceneManager.scene.remove_children(self) if TBS.state_remove_children?(state_id)
      SceneManager.scene.prepare_remove_battler(self) if state_id == death_state_id && remove_on_death?
    end
  end

  #--------------------------------------------------------------------------
  # override method: sprite -> used to refer to the sprite of the battler (here a Sprite_Character_TBS)
  #--------------------------------------------------------------------------
  #(see Victor Core Engine for parent call)
  def sprite
    return super unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.spriteset.get_sprite(self) if SceneManager.scene.spriteset
    return nil
  end

  #--------------------------------------------------------------------------
  # new methods: screen_x, screen_y, screen_z
  #--------------------------------------------------------------------------
  def screen_x
    return SceneManager.scene_is?(Scene_TBS_Battle) ? @char.screen_x : @screen_x
  end

  def screen_y
    return SceneManager.scene_is?(Scene_TBS_Battle) ? @char.screen_y : @screen_y
  end

  def screen_z
    return SceneManager.scene_is?(Scene_TBS_Battle) ? @char.screen_z : 100
  end

  #--------------------------------------------------------------------------
  # new method: init_ai
  #--------------------------------------------------------------------------
  def init_ai
    @ai = AI_BattlerBase.new(self)
  end

  #--------------------------------------------------------------------------
  # new method: player_controllable? -> returns if the player may input the battler or not
  #--------------------------------------------------------------------------
  #a battler is controllable by the player if it is part of specific teams and
  #may play normally (not confused, no autobattle etc.)
  def player_controllable?
    TBS::TEAMS::PLAYABLE_TEAMS.include?(@team) && inputable?
  end

  #--------------------------------------------------------------------------
  # new method: skill_rating -> a value > 0 that represents how likely the skill is to be used
  #--------------------------------------------------------------------------
  def skill_rating(skill_id)
    return TBS.skill_ai_rating(skill_id)
  end

  #--------------------------------------------------------------------------
  # new method: use_sprite?
  #--------------------------------------------------------------------------
  def use_sprite?; SceneManager.scene_is?(Scene_TBS_Battle) && sprite; end

  #--------------------------------------------------------------------------
  # new method: force_tbs_action
  # Casts skill_id on target position, does not check any range property
  # If check_range, the action will be used only if tgt is in range from
  # battler's position
  # If check_movability, the battler may act only if movable (not dead, paralyzed etc.)
  # tgt is an array [x,y]
  #--------------------------------------------------------------------------
  def force_tbs_action(skill_id, tgt, check_range = false, check_movability = true)
    return unless SceneManager.scene_is?(Scene_TBS_Battle)
    return if check_movability && !movable?
    return if check_range && !TBS.getTargetsList(self,pos,getRange(skill_id,:skill)).include?[tgt]
    action = Game_Action.new(self, true)
    action.set_skill(skill_id)
    action.set_target(tgt)
    @actions.insert(0,action)
    SceneManager.scene.process_tbs_action(self)
    #SceneManager.scene.wait_for_effect
  end

  #--------------------------------------------------------------------------
  # new method: prepare_preview_damage -> links the ability stats to an attribute
  # @dmg_preview being an array [string,colorArray], will be set to nil when
  # Sprite_DamagePreview reads it
  #--------------------------------------------------------------------------
  def prepare_preview_damage(user,item)
    p = Preview_DamageData.new(self,user,item)
    colorArray = [TBS::PREVIEW.hit_rate_color(p.touch_rate), p.color_dmg]
    @dmg_preview = [p.to_str, colorArray]
  end

  #--------------------------------------------------------------------------
  # new method: preview_damage -> returns an array that will be read by Preview_DamageData
  # to display damage preview and help ai rate results
  # Any change to make_damage_value method should be imported here or in preview_effects
  #--------------------------------------------------------------------------
  def preview_damage(user,item)
    value = item.damage.eval(user, self, $game_variables)
    value *= item_element_rate(user, item)
    value *= pdr if item.physical?
    value *= mdr if item.magical?
    value *= rec if item.damage.recover?
    hit_chance = item_hit(user, item)# * 100).to_i
    hit_chance = [[hit_chance,1].min,0].max
    eva_chance = item_eva(user,item)# * 100).to_i
    eva_chance = [[eva_chance,1].min,0].max
    cri_chance = item_cri(user,item)
    cri_chance = [[cri_chance,1].min,0].max
    return [value, hit_chance, eva_chance, cri_chance, preview_effects(user,item)]
  end

  #--------------------------------------------------------------------------
  # new method: preview_effects -> internal method that reads the effects of the
  # item and store them in hash table result used by class Preview_DamageData
  #--------------------------------------------------------------------------
  def preview_effects(user,item)
    result = {}
    result[:hp] = 0 #hp gained
    result[:mp] = 0 #mp gained
    result[:tp] = 0 #tp gained
    result[:added_states] = {} #store a hash table of state_id => chance
    result[:removed_states] = {} #store a hash table of state_id => chance
    #result[:added_buffs] = {} #store a hash table of buff_state => [turn]
    #result[:removed_buffs] = {}
    #result[:added_debuffs] = {}
    #result[:removed_debuffs] = {}
    result[:grow] = {} #store a hash table of stat => increment
    discarded_verif = [EFFECT_RECOVER_HP, EFFECT_RECOVER_MP, EFFECT_GAIN_TP]
    usable_effects = item.effects.select{|effect| discarded_verif.include?(effect.code) || item_effect_test(user,item,effect)}
    usable_effects.each do |effect|
      case effect.code
      when EFFECT_RECOVER_HP
        value = (mhp * effect.value1 + effect.value2) * rec
        value *= user.pha if item.is_a?(RPG::Item)
        value = value.to_i
        result[:hp] += value
      when EFFECT_RECOVER_MP
        value = (mmp * effect.value1 + effect.value2) * rec
        value *= user.pha if item.is_a?(RPG::Item)
        value = value.to_i
        result[:mp] += value
      when EFFECT_GAIN_TP
        result[:tp] += effect.value1.to_i
      when EFFECT_ADD_STATE #:item_effect_add_state
        if effect.data_id == 0 #attack
          user.atk_states.each do |state_id|
            c = result[:added_states][state_id]
            c = result[:added_states][state_id] = 0 if c.nil?
            chance = effect.value1
            chance *= state_rate(state_id)
            chance *= user.atk_states_rate(state_id)
            chance *= luk_effect_rate(user)
            result[:added_states][state_id] += (1-c)*chance
          end
        else
          state_id = effect.data_id
          c = result[:added_states][state_id]
          c = result[:added_states][state_id] = 0 if c.nil?
          chance = effect.value1
          chance *= state_rate(state_id)  if opposite?(user)
          chance *= luk_effect_rate(user) if opposite?(user)
          result[:added_states][state_id] += (1-c)*chance
        end
      when EFFECT_REMOVE_STATE #:item_effect_remove_state
        chance = effect.value1
        c = result[:removed_states][state_id]
        c = 0 if c.nil?
        result[:removed_states][state_id] = c + (1-c)*chance
      when EFFECT_GROW
        v = result[:grow][effect.data_id]
        v = 0 if v.nil?
        result[:grow][effect.data_id] = v + effect.value1.to_i
      end
    end
    return result
    #EFFECT_RECOVER_HP    => :item_effect_recover_hp,
    #EFFECT_RECOVER_MP    => :item_effect_recover_mp,
    #EFFECT_GAIN_TP       => :item_effect_gain_tp,
    #EFFECT_ADD_STATE     => :item_effect_add_state,
    #EFFECT_REMOVE_STATE  => :item_effect_remove_state,
    #EFFECT_ADD_BUFF      => :item_effect_add_buff,
    #EFFECT_ADD_DEBUFF    => :item_effect_add_debuff,
    #EFFECT_REMOVE_BUFF   => :item_effect_remove_buff,
    #EFFECT_REMOVE_DEBUFF => :item_effect_remove_debuff,
    #EFFECT_SPECIAL       => :item_effect_special,
    #EFFECT_GROW          => :item_effect_grow,
    #EFFECT_LEARN_SKILL   => :item_effect_learn_skill,
    #EFFECT_COMMON_EVENT  => :item_effect_common_event,
  end

  #--------------------------------------------------------------------------
  # new method: displayed_area_affected? -> returns true if the battler is in area of
  # ability for display features
  # TODO: change this to attribute for faster reading
  #--------------------------------------------------------------------------
  def displayed_area_affected?
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.battlers_in_area.include?(self)
  end

  #--------------------------------------------------------------------------
  # new method: children -> returns all battlers with this one as parent
  # TODO: change this to attribute for faster reading
  #--------------------------------------------------------------------------
  def children
    return [] unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.tactics_battlers.select{|b| b.parent == self}
  end
end

#==============================================================================
#
# TBS Game_Actor
#
#==============================================================================

#============================================================================
# Game_Actor
#============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias game_actor_tbs_init initialize
  def initialize(actor_id)
    game_actor_tbs_init(actor_id)
    @team = TBS::TEAMS::TEAM_ACTORS #the defualt team
    update_char
  end

  #--------------------------------------------------------------------------
  # alias method: set_graphic -> the Game_Character_TBS is also updated when the actor char is changed by event calls
  #--------------------------------------------------------------------------
  alias game_actor_tbs_set_graphic set_graphic
  def set_graphic(character_name, character_index, face_name, face_index)
    game_actor_tbs_set_graphic(character_name, character_index, face_name, face_index)
    update_char
  end

  #--------------------------------------------------------------------------
  # alias method: make_actions -> the action chosen will be handled by the ai, so ai actors load their actions like actors by default
  #--------------------------------------------------------------------------
  alias tbs_game_actor_make_actions make_actions
  def make_actions
    return tbs_game_actor_make_actions unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end

  #--------------------------------------------------------------------------
  # override method: move_rule_id -> search in the associated baseitems the move_rule_id
  #--------------------------------------------------------------------------
  def move_rule_id
    modeModeL = [TBS.actor_moveMode(@actor_id),TBS.class_moveMode(@class_id)]
    for a in armors
      modeModeL += [TBS.equip_moveMode(a.id)]
    end
    for w in weapons
      modeModeL += [TBS.weapon_moveMode(w.id)]
    end
    for s_id in @states
      modeModeL += [TBS.state_moveMode(s_id)]
    end
    return TBS.move_rule_priority(modeModeL)
  end

  #--------------------------------------------------------------------------
  # override method: mmov -> search in the associated baseitems the total mmov
  #--------------------------------------------------------------------------
  def mmov
    move = TBS.class_move(@class_id)
    move += TBS.actor_move(@actor_id)
    for a in armors
      move += TBS.equip_move(a.id)
    end
    for w in weapons
      move += TBS.weapon_move(w.id)
    end
    for s_id in @states
      move += TBS.state_move(s_id)
    end
    return [move,0].max
  end

  #--------------------------------------------------------------------------
  # override method: getRangeWeapon -> take the range of the first weapon
  #--------------------------------------------------------------------------
  def getRangeWeapon
    weapon =  weapons[0]
    range = weapon.nil? ?  TBS.weapon_range(0) :  TBS.weapon_range(weapon.id)
    return range
  end

  #--------------------------------------------------------------------------
  # override methods: screen_x, screen_y, screen_z -> compatibility with YEA-BattleEngine
  #--------------------------------------------------------------------------
  if $imported["YEA-BattleEngine"]
    alias tbs_act_screen_x screen_x
    def screen_x
       SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_act_screen_x
     end
     alias tbs_act_screen_y screen_y
    def screen_y
      SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_act_screen_y
    end
    alias tbs_act_screen_z screen_z
    def screen_z
      SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_act_screen_z
    end

    alias tbs_act_sprite sprite
    def sprite
      SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_act_sprite
    end
  else
    def screen_x; super; end
    def screen_y; super; end
    def screen_z; super; end
  end

  #--------------------------------------------------------------------------
  # override method: can_battle? -> some actors may not battle
  #--------------------------------------------------------------------------
  def can_battle?
    return !(TBS.actor_no_battle(@actor_id) || @states.any? {|s| TBS.state_no_battle(s)})
  end

  #--------------------------------------------------------------------------
  # new method: ai_usable_skills -> returns a pair [id,rating] for each usable skill
  #--------------------------------------------------------------------------
  #ai related
  def ai_usable_skills
    sList = usable_skills
    sList.collect!{|s| [s,TBS.skill_ai_rating(s.id)]}
    l1 = [] #add the attack and guard skills
    for id in [attack_skill_id,guard_skill_id]
      l1.push([$data_skills[id],TBS.skill_ai_rating(id)])
    end
    return l1 + sList
  end

  #--------------------------------------------------------------------------
  # alias method: use_sprite?
  #--------------------------------------------------------------------------
  alias tbs_actor_use_sprite? use_sprite?
  def use_sprite?
    return SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_actor_use_sprite?
  end
end #Game_Actor

#==============================================================================
#
# TBS Game_Enemy
#
#==============================================================================

#============================================================================
# Game_Enemy
#============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :class_name #to display in Window_Small_TBS_Status
  attr_reader :last_skill #for enemy controls

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias game_enemy_tbs_init initialize
  def initialize(index, enemy_id)
    game_enemy_tbs_init(index, enemy_id)
    @team = TBS::TEAMS::TEAM_ENEMIES
    load_tbs_enemy_data(enemy_id)
    @last_skill = Game_BaseItem.new
  end

  #--------------------------------------------------------------------------
  # new method: load_tbs_enemy_data
  #--------------------------------------------------------------------------
  def load_tbs_enemy_data(enemy_id)
    @character_name = TBS.enemy_charset(enemy_id)
    @character_index = TBS.enemy_char_index(enemy_id)
    @face_name = TBS.enemy_face(enemy_id)
    @face_index = TBS.enemy_face_index(enemy_id)
    @class_name = TBS.enemy_class(enemy_id)
    update_char
  end

  #--------------------------------------------------------------------------
  # alias method: transform
  #--------------------------------------------------------------------------
  alias tbs_transform transform
  def transform(enemy_id)
    tbs_transform(enemy_id)
    load_tbs_enemy_data(enemy_id)
  end

  #--------------------------------------------------------------------------
  # override method: mmov
  #--------------------------------------------------------------------------
  def mmov
    move = TBS.enemy_move(@enemy_id)
    for s_id in @states
      move += TBS.state_move(s_id)
    end
    return [move,0].max
  end

  #--------------------------------------------------------------------------
  # override method: move_rule_id
  #--------------------------------------------------------------------------
  def move_rule_id
    modeModeL = [TBS.enemy_moveMode(@enemy_id)]
    for s_id in @states
      modeModeL += [TBS.state_moveMode(s_id)]
    end
    return TBS.move_rule_priority(modeModeL)
  end

  #--------------------------------------------------------------------------
  # overwrite methods: screen_x, screen_y, screen_z -> the attributes are no longer directly used
  #--------------------------------------------------------------------------
  def screen_x; super; end
  def screen_y; super; end
  def screen_z; super; end

  #--------------------------------------------------------------------------
  # override method: sprite if YEA-BattleEngine is used
  #--------------------------------------------------------------------------
  if $imported["YEA-BattleEngine"]
    alias tbs_en_sprite sprite
    def sprite
      SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_en_sprite
    end
  end

  #--------------------------------------------------------------------------
  # override method: always_hide_view?
  #--------------------------------------------------------------------------
  def always_hide_view?
    return TBS.always_hide_view(@enemy_id)
  end

  #--------------------------------------------------------------------------
  # override method: getRangeWeapon? -> enemies have a weapon range defined in notetags
  #--------------------------------------------------------------------------
  def getRangeWeapon()
    return TBS.enemy_range(@enemy_id)
  end

  #--------------------------------------------------------------------------
  # alias method: make_actions -> the action chosen will be handled by the ai, so the enemies load their actions like actors by default
  #--------------------------------------------------------------------------
  alias tbs_game_enemy_make_actions make_actions
  def make_actions
    return tbs_game_enemy_make_actions unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end

  #--------------------------------------------------------------------------
  # new methods: clear_actions, input, next_command, prior_command -> same as Game_actor for controllable enemies
  #--------------------------------------------------------------------------
  def clear_actions
    super
    @action_input_index = 0
  end

  def input
    @actions[@action_input_index]
  end

  def next_command
    return false if @action_input_index >= @actions.size - 1
    @action_input_index += 1
    return true
  end

  def prior_command
    return false if @action_input_index <= 0
    @action_input_index -= 1
    return true
  end

  #--------------------------------------------------------------------------
  # override method: remove_on_death?
  #--------------------------------------------------------------------------
  def remove_on_death?
    return (super || TBS.enemy_disappear(@enemy_id))
  end

  #--------------------------------------------------------------------------
  # new method: ai_usable_skills -> returns a pair [id,rating] for each usable skill
  #--------------------------------------------------------------------------
  def ai_usable_skills
    l1 = enemy.actions.select {|a| action_valid?(a) }.collect{|action| [action.skill_id, action.rating]}
    l2 = added_skills.collect {|id| [id,TBS.skill_ai_rating(id)] }
    return (l1+l2).sort.collect{|l| [$data_skills[l[0]],l[1]] }.select{|l| usable?(l[0])}
  end

  #--------------------------------------------------------------------------
  # new method: usable_skills -> returns a list of skills that can be used
  #--------------------------------------------------------------------------
  def usable_skills
    l1 = enemy.actions.select {|a| action_valid?(a) }.collect{|action| action.skill_id }
    l2 = (l1 | added_skills).sort.collect {|id| $data_skills[id] }
    l2.select {|skill| usable?(skill) }
  end

  #--------------------------------------------------------------------------
  # override method: skill_rating -> if the skill is part of the conditional skills, puts the rating of the skill from the database
  #--------------------------------------------------------------------------
  def skill_rating(skill_id)
    for a in enemy.actions
      return a.rating if a.skill_id == skill_id && action_valid?(a)
    end
    return super
  end

  #--------------------------------------------------------------------------
  # new method: description -> returns a description for the database
  #--------------------------------------------------------------------------
  def description
    return TBS.enemy_description(@enemy_id)
  end

  #--------------------------------------------------------------------------
  # alias method: use_sprite?
  #--------------------------------------------------------------------------
  alias tbs_enemy_use_sprite? use_sprite?
  def use_sprite?
    return SceneManager.scene_is?(Scene_TBS_Battle) ? super : tbs_enemy_use_sprite?
  end
end #Game_Enemy

#==============================================================================
#
# TBS Game_Unit
#
#==============================================================================

#============================================================================
# Game_Unit
#============================================================================
class Game_Unit
  #--------------------------------------------------------------------------
  # new method: tbs_members
  #--------------------------------------------------------------------------
  def tbs_members
    return all_candidate_battlers.select {|mem| mem.tbs_battler}
  end

  #def existing_members
  #  return (tbs_members.select {|mem| mem.exist? } )
  #end

  #--------------------------------------------------------------------------
  # new method: tbs_dead_members
  #--------------------------------------------------------------------------
  def tbs_dead_members
    return tbs_members.select {|mem| mem.death_state?}
    #return dead #return (dead.select{|mem| mem.tbs_battler})
  end

  #--------------------------------------------------------------------------
  # new method: on_tbs_battle_start -> called by BattleManager for TBS battles
  #--------------------------------------------------------------------------
  def on_tbs_battle_start
    @in_battle = true
    tbs_members.each{|member| member.on_battle_start }
  end

  #--------------------------------------------------------------------------
  # new method: on_tbs_battle_end -> called by BattleManager for TBS battles
  #--------------------------------------------------------------------------
  def on_tbs_battle_end
    @in_battle = false
    tbs_members.each{|member| member.on_battle_end }
  end
end #Game_Unit

#============================================================================
# Game_Party -> stores all Game_Actors from Game_Actors list regardless of their team
#============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  #ids of actors not in party but that might take part in battle!
  #they are part of $game_actors
  attr_reader :neutrals

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias party_tbs_initialize initialize
  def initialize
    @neutrals = []
    party_tbs_initialize
  end

  #--------------------------------------------------------------------------
  # new method: tbs_add_actor -> call before/after a battle to add actors with specific team
  #--------------------------------------------------------------------------
  def tbs_add_actor(actor_id,team = TBS::TEAMS::TEAM_ACTORS, setup = false)
    $game_actors[actor_id].setup(actor_id) if setup
    $game_actors[actor_id].team = team
    if team == TBS::TEAMS::TEAM_ACTORS
      @neutrals.delete(actor_id)
      add_actor(actor_id)
    else
      remove_actor(actor_id)
      @neutrals.push(actor_id) unless @neutrals.include?(actor_id)
    end
  end

  #--------------------------------------------------------------------------
  # new method: tbs_remove_actor -> call before/after a battle to remove actors, regardless of their team
  #--------------------------------------------------------------------------
  def tbs_remove_actor(actor_id)
    @neutrals.delete(actor_id)
    remove_actor(actor_id)
  end

  #def tbs_clear_non_friends
  #  @neutrals = []
  #end

  #--------------------------------------------------------------------------
  # new method: all_candidate_battlers -> battlers that may be part of a tbs battle
  #--------------------------------------------------------------------------
  def all_candidate_battlers
    return all_members + neutrals.collect{|id| $game_actors[id] }
  end

  #--------------------------------------------------------------------------
  # alias method: battle_members -> during battle, the "battle_members" is not only the first 4 members
  #--------------------------------------------------------------------------
  alias tbs_battle_members battle_members
  def battle_members
    SceneManager.scene_is?(Scene_TBS_Battle) ? all_members.select{|actor| actor.tbs_battler && actor.exist?} : tbs_battle_members
  end
end #Game_Party

#============================================================================
# Game_Party -> stores all Game_Enemy as well as freshly instanciated Game_Actor (not from the Game_Actors array)
#============================================================================
class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader   :neutrals               # any battler not part of the main enemy team but also not from $game_actors array, can be from any team including TEAM_ACTORS !
  attr_reader   :obstacles              # battlers that do not take turns
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias troop_tbs_clear clear
  def clear
    @neutrals = []
    @obstacles = []
    troop_tbs_clear
  end

  #--------------------------------------------------------------------------
  # new method: all_candidate_battlers
  #--------------------------------------------------------------------------
  def all_candidate_battlers
    return members + neutrals
  end

  #--------------------------------------------------------------------------
  # new method: tbs_dead_enemies -> useful for loot/exp/gold calculation
  #--------------------------------------------------------------------------
  def tbs_dead_enemies
    tbs_dead_members.select{|mem| mem.enemy? && TBS::TEAMS::TEAMS_TO_LOOT.include?(mem.team)}
  end
  #--------------------------------------------------------------------------
  # alias methods: exp_total, gold_total, make_drop_items
  #--------------------------------------------------------------------------
  alias tbs_exp_total exp_total
  def exp_total
    return tbs_exp_total unless SceneManager.scene_is?(Scene_TBS_Battle)
    tbs_dead_enemies.inject(0) {|r, enemy| r += enemy.exp}
  end
  alias tbs_gold_total gold_total
  def gold_total
    return tbs_gold_total unless SceneManager.scene_is?(Scene_TBS_Battle)
    tbs_dead_enemies.inject(0) {|r, enemy| r += enemy.gold} * gold_rate
  end
  alias tbs_make_drop_items make_drop_items
  def make_drop_items
    return tbs_make_drop_items unless SceneManager.scene_is?(Scene_TBS_Battle)
    tbs_dead_enemies.inject([]) {|r, enemy| r += enemy.make_drop_items }
  end

  #posList is a list of pos ([x,y]) set by priority, if no valid pos is vailable, the unit is not added to the game
  #def addEnemy(enemy_id, pos_list, team = TBS::TEAMS::TEAM_ENEMIES)
  #  bat = Game_Enemy.new(0,enemy_id)
  #  addBattler(bat,pos_list,team)
  #end

  #def addActor(actor_id, pos_list, team = TBS::TEAMS::TEAM_ACTORS)
  #  bat = Game_Actor.new(actor_id)
  #  addBattler(bat,pos_list,team)
  #end

  #def addBattler(bat, pos_list, team)
  #  bat.team = team
  #  @neutrals += [bat]
  #end
  #def addObstacle(enemy_id,pos)
  #  bat = Game_Enemy.new(0,enemy_id)
  #  bat.team = TBS::TEAMS::TEAM_NEUTRALS
  #  bat.moveto(pos[0],pos[1])
  #  bat.set_obstacle
  #  @obstacles += [bat]
  #end

  #--------------------------------------------------------------------------
  # new method: add_obstacle -> set the battler as an obstacle
  #--------------------------------------------------------------------------
  def add_obstacle(bat)
    bat.team = TBS::TEAMS::TEAM_NEUTRALS
    bat.set_obstacle
    @obstacles += [bat]
  end

  #--------------------------------------------------------------------------
  # new method: add_extra_battler -> adds a battler to the list (may be of any team!)
  #--------------------------------------------------------------------------
  def add_extra_battler(bat)
    @neutrals += [bat]
  end
end #Game_Troop

#==============================================================================
#
# TBS Turn Order
#
#==============================================================================

#BEHAVIOR OF THE TURNWHEEL
#ON NEXT POINTER: TAKE THE K CONTINGEOUS UNITS THAT SHARE A TURN
#If someone dies during its turn: disactivate it
#If someone dies outside its turn: disactivate it, regarless of whether there is a unit right after
#If the unit should be removed (because dead or anything): remove it but keep
#If someone is added before its turn: add it then activate it on its turn
#If someone is added after its turn: add it but activate it only on the next turn

#============================================================================
# TurnWheel -> a new class handling turn order
#============================================================================
class TurnWheel
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :battlerList #the list of battlers that can take a turn (ie any tbs battler except obstacles and removed battlers)

  #--------------------------------------------------------------------------
  # new method: initialize
  #--------------------------------------------------------------------------
  #mode is a turnSystem (see TURN_SYSTEMS for a list of possibilities)
  def initialize(mode)
    @mode = mode
    @next_pointer = 0 #the first index of the next battler to play when the current ones have finished their turns
    @battlerList = [] #the complete list of battlers taking a turn, ordered by initiative
    @activeBattlers = [] #a list that will evolve, usually @battlerList[@pointer,@next_pointer], unless some battlers are added/removed, regardless, this list will NEVER be updated before an end of local turn
  end

  #--------------------------------------------------------------------------
  # new method: size -> the number of battlers in the turnWheel
  #--------------------------------------------------------------------------
  def size
    return @battlerList.size
  end

  #--------------------------------------------------------------------------
  # new method: computeOrder -> called once at the begining of battle (after the actors are placed)
  #--------------------------------------------------------------------------
  #should be called after putting every battler inside the list, should be called only at the begining of the battle
  #teams is an array of arrays of battlers sorted by teams, you must assume that the teams are non empty
  def computeOrder(teams)
    @battlerList = []
    for t in teams
      for b in t
        b.roll_initiative
      end
    end
    case @mode
    when :ffa
      #will shuffle the battlers (ensuring any order in case of tie, then order them
      for t in teams
        @battlerList += t
      end
      @battlerList.shuffle!
      @battlerList.sort_by!{|b| b.initiative}
      @battlerList.reverse! #the order was increasing, we want it decreasing based on initiative
    when :teams
      #order the teams in teams2 based on their maximum initiative
      teams2 = teams.sort_by{|t| t.map{|bat| bat.initiative}.max}
      teams2.reverse!
      for t in teams2
        @battlerList += t
      end
    when :ffaeven
      teams2 = []
      #order each team
      for t in teams
        t2 = t.shuffle.sort_by!{|b| b.initiative}.reverse!
        teams2.push(t2)
      end
      #teams are now ordered based on their max initiative
      teams2.sort_by!{|t| t.map{|bat| bat.initiative}.max}
      teams2.reverse!
      i = 0
      loop do
        hasChanged = false
        for t in teams2
          b = t[i]
          unless b.nil?
            @battlerList.push(b)
            hasChanged = true
          end
        end
        break unless hasChanged
        i += 1
      end
    end
    updateBattlersTurnID
    #@battlerList = @battlerList #neutrals are dealt with by the battle system
  end

  #--------------------------------------------------------------------------
  # new method: getBattler
  #--------------------------------------------------------------------------
  def getBattler(i)
    @battlerList[i]
  end

  #--------------------------------------------------------------------------
  # new method: getTurnIndex
  #--------------------------------------------------------------------------
  def getTurnIndex(b)
    @battlerList.index(b)
  end

  #--------------------------------------------------------------------------
  # new method: battlerShareTurnWith -> asks if b2 can play alongside b1
  #--------------------------------------------------------------------------
  def battlerShareTurnWith?(b2,b1)
    TBS::GROUPED_TURNS && b2.team == b1.team
  end

  #--------------------------------------------------------------------------
  # new method: nextPointerPos -> given a position p in the turnwheel,
  # returns the next position on the turnwheel that represents the first battler
  # that does not share a turn with the battler in posiiton p
  #--------------------------------------------------------------------------
  def nextPointerPos(p)
    b1 = getBattler(p)#@battlerList[@pointer]
    #p = @pointer
    loop do
      p += 1
      b2 = getBattler(p)
      break if (b2.nil? || !battlerShareTurnWith?(b2,b1))
    end
    return p #the first "invalid" pos
  end

  #--------------------------------------------------------------------------
  # new method: getActiveBattlers -> the array of battlers that may act according to the turnwheel
  #--------------------------------------------------------------------------
  def getActiveBattlers
    @activeBattlers#@battlerList[@pointer,@next_pointer]
  end

  #--------------------------------------------------------------------------
  # new method: forward -> updates the list of active battlers
  #--------------------------------------------------------------------------
  #will advance the wheel
  #return true iff the wheel advanced, return false otherwise (end of the wheel)
  def forward
    if (@next_pointer < @battlerList.size)
      prev_pointer = @next_pointer
      @next_pointer = nextPointerPos(@next_pointer)#nextPointerPos
      #puts sprintf("Array is [%d,%d[",prev_pointer,@next_pointer)
      @activeBattlers = @battlerList[prev_pointer,@next_pointer-prev_pointer]
      return true
    end
    #puts sprintf("New turn for the wheel %d vs %d", @next_pointer, @battlerList.size)
    @next_pointer = 0
    @activeBattlers = []
    return false
  end

  #--------------------------------------------------------------------------
  # new method: addBattler
  #--------------------------------------------------------------------------
  #process when adding reinforcement, parent is relevant for ffaeven when a summon might be added right after its parent
  def addBattler(b,parent = nil)
    b.roll_initiative
    id = parent.nil? ? nil : @battlerList.index(parent)
    i = 0 #position to insert
    if id.nil?
      case @mode
      when :ffa
        i = @battlerList.index{|b2| b2.initiative < b.initiative}
        i = @battlerList.size if i.nil?
      when :ffaeven
        #could be improved but don't know which behaviour to adopt
        i = @battlerList.size
      when :teams
        #push the battler at the end of its team
        i = @battlerList.rindex{|b2| b2.team == teamID}
        i = @battlerList.size if i.nil?
      end
    else
      i = id + 1
    end
    @battlerList.insert(i,b)
    updateBattlersTurnID
    onAddBat(i)
  end

  #--------------------------------------------------------------------------
  # new method: removeBattler
  #--------------------------------------------------------------------------
  #process when a battler is removed during combat
  def removeBattler(b)
    id = @battlerList.index(b)
    return if id.nil?
    @battlerList.delete_at(id)
    b.turn_id = nil
    updateBattlersTurnID
    onRmBat(id)
  end

  #--------------------------------------------------------------------------
  # new method: onAddBat
  #--------------------------------------------------------------------------
  #if the batler added is before me, then I am pushed later
  #if the battler is added where I am, it is fine, I will give it a turn!
  def onAddBat(pos)
    @next_pointer += 1 if @next_pointer > pos
  end

  #--------------------------------------------------------------------------
  # new method: onRmBat
  #--------------------------------------------------------------------------
  #if the battler removed was before me, then I am pulled, if it was my next one or after, then it is not matter
  def onRmBat(pos)
    @next_pointer  -= 1 if @next_pointer  > pos
  end

  #--------------------------------------------------------------------------
  # new method: battlerShareTurnWith -> asks if b2 can play alongside b1
  #--------------------------------------------------------------------------
  def updateBattlersTurnID
    @battlerList.each_with_index{|bat,i| bat.turn_id = i}
  end
end #TurnWheel

#==============================================================================
#
# TBS Scene_TBS_Battle
#
#==============================================================================

#==============================================================================
# ** Scene_TBS_Battle
#------------------------------------------------------------------------------
#  This class performs battle screen processing.
#  SHould replace the original Scene_Battle in script calls
#==============================================================================

#============================================================================
# Scene_TBS_Battle -> a new class replacing Scene_Battle during TBS
#============================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # * Public instance variables used to find what where the last abilities used,
  # where and by whom?
  #--------------------------------------------------------------------------
  attr_reader :last_user, :last_item, :last_target, :phase, :turnWheel
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    @phase = nil #means that nothing is ready yet
    @tbs_battlers = []
    @active_battlers = []
    @remove_list = []
    super
    map_data = setup_map
    create_battlers(map_data)
    create_cursor
    create_spriteset
    create_all_windows
    #create_message_window
    BattleManager.method_wait_for_message = method(:wait_for_message)
  end
  #--------------------------------------------------------------------------
  # * Post-Start Processing
  #--------------------------------------------------------------------------
  def post_start
    super
    pre_battle_start
  end
  #--------------------------------------------------------------------------
  # * Pre-Termination Processing
  #--------------------------------------------------------------------------
  def pre_terminate
    super
    if SceneManager.scene_is?(Scene_Map)
      return_to_map
      Graphics.fadeout(30)
    end
    Graphics.fadeout(60) if SceneManager.scene_is?(Scene_Title)
  end
  #--------------------------------------------------------------------------
  # * Termination Processing
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_spriteset
    @info_viewport.dispose
    RPG::ME.stop
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    return if scene_changing?
    process_event if BattleManager.in_turn?
    BattleManager.judge_win_loss if @phase == :battle
  end
  #--------------------------------------------------------------------------
  # * Update Frame (Basic)
  #--------------------------------------------------------------------------
  def update_basic
    super
    update_cursor unless $game_troop.interpreter.running?
    update_direction_cursor unless $game_troop.interpreter.running?
    $game_timer.update
    $game_troop.update
    $game_map.update(false) #update of the map and its events
    $game_map.update_tbs(false) unless scene_changing? #update of the battlers on the map
    @spriteset.update unless scene_changing?
    update_message_open
  end
  #--------------------------------------------------------------------------
  # * Update Frame (for Wait)
  #--------------------------------------------------------------------------
  def update_for_wait
    update_basic
  end
  #--------------------------------------------------------------------------
  # * Wait
  #--------------------------------------------------------------------------
  def wait(duration)
    duration.times {|i| update_for_wait if i < duration / 2 || !show_fast? }
  end
  #--------------------------------------------------------------------------
  # * Determine if Fast Forward
  #--------------------------------------------------------------------------
  def show_fast?
    Input.press?(:A) || Input.press?(:C)
  end
  #--------------------------------------------------------------------------
  # * Wait (No Fast Forward)
  #--------------------------------------------------------------------------
  def abs_wait(duration)
    duration.times {|i| update_for_wait }
  end
  #--------------------------------------------------------------------------
  # * Short Wait (No Fast Forward)
  #--------------------------------------------------------------------------
  def abs_wait_short
    abs_wait(15)
  end
  #--------------------------------------------------------------------------
  # * Wait Until Message Display has Finished
  #--------------------------------------------------------------------------
  def wait_for_message
    @message_window.update
    update_for_wait while $game_message.visible
  end
  #--------------------------------------------------------------------------
  # * Wait Until Animation Display has Finished
  #--------------------------------------------------------------------------
  def wait_for_animation
    update_for_wait
    update_for_wait while @spriteset.animation?
  end
  #--------------------------------------------------------------------------
  # * Wait Until Effect Execution Ends
  #--------------------------------------------------------------------------
  def wait_for_effect
    update_for_wait
    update_for_wait while @spriteset.effect?
  end
  #--------------------------------------------------------------------------
  # * Update Processing for Opening Message Window
  #    Set openness to 0 until the status window and so on are finished closing.
  #--------------------------------------------------------------------------
  def update_message_open
    if $game_message.busy? && false #!@status_window.close?
      @message_window.openness = 0
      #@status_window.close
      @party_command_window.close
      @actor_command_window.close
    end
  end

  #--------------------------------------------------------------------------
  # * Create Sprite Set
  #--------------------------------------------------------------------------
  def create_spriteset
    @spriteset = Spriteset_TBS_Map.new
  end
  #--------------------------------------------------------------------------
  # * Free Sprite Set
  #--------------------------------------------------------------------------
  def dispose_spriteset
    @spriteset.dispose
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  def create_all_windows
    @window_list = []
    create_message_window
    create_scroll_text_window
    create_log_window
    create_info_viewport
    create_help_window

    create_global_command_window
    create_place_command_window
    create_tbs_actor_command_window
    create_small_status_window
    create_place_status_window
    create_full_status_window
    create_skill_window
    create_item_window
    create_windcond_window
    create_turnorder_window
    create_option_window if $imported["TIM-TBS-Settings"]
    create_confirm_window

    for w in @window_list
      w.back_opacity = TBS::WINDOW_OPACITY
    end
  end

  #--------------------------------------------------------------------------
  # * Create Confirm Window
  #--------------------------------------------------------------------------
  def create_confirm_window
    @confirm_window = Window_TBS_Confirm.new(:start_battle)
    @confirm_window.set_handler(:ok,   method(:on_confirm_ok))
    @confirm_window.set_handler(:no,   method(:on_confirm_no))
    @confirm_window.set_handler(:cancel, method(:on_confirm_cancel))
    @window_list.push(@confirm_window)
  end

  #--------------------------------------------------------------------------
  # * Create Small Status Window
  #--------------------------------------------------------------------------
  def create_small_status_window
    @small_status_window = Window_Small_TBS_Status.new
    @window_list.push(@small_status_window)
  end

  #--------------------------------------------------------------------------
  # * Create Place Status Window
  #--------------------------------------------------------------------------
  def create_place_status_window
    @place_status_window = Window_Small_TBS_Status.new
    @place_status_window.relocate(7)
    @window_list.push(@place_status_window)
  end

  #--------------------------------------------------------------------------
  # * Create Full Status Window
  #--------------------------------------------------------------------------
  def create_full_status_window
    @full_status_window = Window_Full_Status.new(nil)
    @full_status_window.deactivate
    @full_status_window.openness = 0
    @full_status_window.set_handler(:cancel, method(:open_actor_command_window))
    @full_status_window.set_handler(:ok,   method(:open_actor_command_window))
    @window_list.push(@full_status_window)
  end

  #--------------------------------------------------------------------------
  # * Create Message Window
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_Message.new
  end
  #--------------------------------------------------------------------------
  # * Create Scrolling Text Window
  #--------------------------------------------------------------------------
  def create_scroll_text_window
    @scroll_text_window = Window_ScrollText.new
  end
  #--------------------------------------------------------------------------
  # * Create Log Window
  #--------------------------------------------------------------------------
  def create_log_window
    @log_window = Window_BattleLog.new
    @log_window.method_wait = method(:wait)
    @log_window.method_wait_for_effect = method(:wait_for_effect)
  end
  #--------------------------------------------------------------------------
  # * Create Information Display Viewport
  #--------------------------------------------------------------------------
  def create_info_viewport
    w = Window_BattleStatus.new
    status_height = w.height
    w.dispose #this is ugly, but I don't need Window_BattleStatus
    @info_viewport = Viewport.new
    @info_viewport.rect.y = Graphics.height - status_height
    @info_viewport.rect.height = status_height
    @info_viewport.z = 100
    @info_viewport.ox = 64
  end
  #--------------------------------------------------------------------------
  # * Create Global Commands Window
  #--------------------------------------------------------------------------
  def create_global_command_window
    win = Window_TBS_GlobalCommand.new
    win.relocate(5) #center the window
    @party_command_window = win
    @party_command_window.set_handler(:escape, method(:command_escape))
    @party_command_window.set_handler(:victory_conditions, method(:open_winconditions))
    @party_command_window.set_handler(:options, method(:open_options_window)) if $imported["TIM-TBS-Settings"]
    @party_command_window.set_handler(:turn_order, method(:open_turnorder))
    @party_command_window.set_handler(:end_team_turn, method(:command_ask_end_team_turn))
    @party_command_window.set_handler(:cancel, method(:command_cursor_select))
    @party_command_window.unselect
    @window_list.push(@party_command_window)
  end
  #--------------------------------------------------------------------------
  # * Create Place Global Commands Window
  #--------------------------------------------------------------------------
  def create_place_command_window
    win = Window_TBS_PlaceGlobalCommand.new
    win.relocate(5) #center the window
    @place_command_window = win
    @place_command_window.set_handler(:start_battle, method(:command_start_battle))
    @place_command_window.set_handler(:victory_conditions, method(:open_winconditions))
    @place_command_window.set_handler(:options, method(:open_options_window)) if $imported["TIM-TBS-Settings"]
    @place_command_window.set_handler(:cancel, method(:command_cursor_place))
    @place_command_window.unselect
    @window_list.push(@place_command_window)
  end
  #--------------------------------------------------------------------------
  # * Create Actor Commands Window
  #--------------------------------------------------------------------------
  def create_tbs_actor_command_window
    @actor_command_window = Window_TBS_ActorCommand.new
    @actor_command_window.set_handler(:move,   method(:command_move))
    @actor_command_window.set_handler(:attack, method(:command_attack))
    @actor_command_window.set_handler(:skill,  method(:command_skill))
    @actor_command_window.set_handler(:wait,  method(:command_choose_dir))
    @actor_command_window.set_handler(:guard,  method(:command_guard))
    @actor_command_window.set_handler(:item,   method(:command_item))
    @actor_command_window.set_handler(:status,   method(:command_full_status))
    @actor_command_window.set_handler(:cancel, method(:command_cursor_select))
    @actor_command_window.help_window = @help_window
    @window_list.push(@actor_command_window)
  end

  #--------------------------------------------------------------------------
  # * Create WinConditions Window
  #--------------------------------------------------------------------------
  def create_windcond_window
    @wincond_window = Window_WinConditions.new
    @wincond_window.set_handler(:cancel, method(:open_global_commands))
    @wincond_window.set_handler(:ok, method(:open_global_commands))
    @window_list.push(@wincond_window)
  end

  #--------------------------------------------------------------------------
  # * Create TurnOrder Window
  #--------------------------------------------------------------------------
  def create_turnorder_window
    @turnorder_window = Window_TurnOrder.new
    @turnorder_window.set_handler(:cancel, method(:open_global_commands))
    @turnorder_window.set_handler(:ok, method(:command_cursor_select))
    @window_list.push(@turnorder_window)
  end

  #--------------------------------------------------------------------------
  # * Create Help Window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new#Window_TBS_Help.new#Window_Help.new
    @help_window.hide
    @window_list.push(@help_window)
  end
  #--------------------------------------------------------------------------
  # * Create Skill Window
  #--------------------------------------------------------------------------
  def create_skill_window
    @skill_window = Window_BattleSkill.new(@help_window, @info_viewport)
    @skill_window.set_handler(:ok,     method(:on_skill_ok))
    @skill_window.set_handler(:cancel, method(:on_skill_cancel))
    @window_list.push(@skill_window)
  end
  #--------------------------------------------------------------------------
  # * Create Item Window
  #--------------------------------------------------------------------------
  def create_item_window
    @item_window = Window_BattleItem.new(@help_window, @info_viewport)
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @window_list.push(@item_window)
  end
  #--------------------------------------------------------------------------
  # * [Escape] Command
  #--------------------------------------------------------------------------
  def command_escape
    next_group_turn unless BattleManager.process_escape
  end

  #--------------------------------------------------------------------------
  # * [End Team Turn] Command
  #--------------------------------------------------------------------------
  def command_ask_end_team_turn
    @party_command_window.deactivate
    setup_confirm_window(:skip_turn)
  end
  #--------------------------------------------------------------------------
  # * [Attack] Command
  #--------------------------------------------------------------------------
  def command_attack
    @actor_command_window.close
    bat = BattleManager.actor
    bat.input.set_attack
    l = bat.genTgt(bat.getRange(bat.attack_skill_id,:skill))
    @spriteset.draw_range(l,TBS.spriteType(:attack))
    @cursor.set_skill_data(bat, l)
    @cursor.moveto(bat.pos.x,bat.pos.y)
    activate_cursor(:attack)
    @cursor.moveto(bat.pos.x,bat.pos.y)
    @spriteset.update_tile_sprites
  end
  #--------------------------------------------------------------------------
  # * [Skill] Command
  #--------------------------------------------------------------------------
  def command_skill
    @actor_command_window.close
    @skill_window.actor = BattleManager.actor
    @skill_window.stype_id = @actor_command_window.current_ext
    @skill_window.refresh
    @skill_window.show.activate
  end
  #--------------------------------------------------------------------------
  # * [Guard] Command
  #--------------------------------------------------------------------------
  def command_guard
    @actor_command_window.close
    bat = BattleManager.actor
    bat.input.set_guard
    l = bat.genTgt(bat.getRange(bat.guard_skill_id,:skill))
    @spriteset.draw_range(l,TBS.spriteType(:help_skill))
    @cursor.set_skill_data(bat, l)
    @cursor.menu_skill = true #to return to menu when cancelling
    activate_cursor(:skill)
    @cursor.moveto_bat(bat)
  end

  #--------------------------------------------------------------------------
  # * [Move] Command
  #--------------------------------------------------------------------------
  def command_move
    @actor_command_window.close
    route, cost = BattleManager.actor.calc_pos_move
    l = route.keys
    @spriteset.draw_range(l,TBS.spriteType(:move))
    @cursor.set_move_data(BattleManager.actor, l, route, cost)
    @cursor.moveto(BattleManager.actor.pos.x,BattleManager.actor.pos.y)
    activate_cursor(:move)
  end

  #--------------------------------------------------------------------------
  # * [Wait] Command
  #--------------------------------------------------------------------------
  def command_choose_dir
    @actor_command_window.close
    return if BattleManager.actor.nil? #only happens during some combats ending?
    @wait_pic = Direction_Cursor.new(@spriteset.viewport1,BattleManager.actor)
    @wait_pic.moveto(BattleManager.actor.char.x, BattleManager.actor.char.y-1)
    if TBS::SKIP_DIRECTION_CHOICE
      setup_confirm_window(:wait)
      return on_confirm_ok
    end
    #@wait_pic.update_bitmap
  end

  #--------------------------------------------------------------------------
  # * [Start Battle] Command during place phase
  #--------------------------------------------------------------------------
  def command_start_battle
    @place_status_window.hide
    setup_confirm_window(:start_battle)
  end

  #--------------------------------------------------------------------------
  # * [Cancel of menu] Command during place phase
  #--------------------------------------------------------------------------
  def command_cursor_place
    @place_command_window.close
    activate_cursor(:place)
  end

  #--------------------------------------------------------------------------
  # * [Cancel/End of Action] Command
  #--------------------------------------------------------------------------
  def command_cursor_select
    @turnorder_window.close
    @party_command_window.close
    @actor_command_window.close
    #@cursor.moveto(@cursor.x,@cursor.y)
    #@cursor.battler.nil? ? @small_status_window.hide : @small_status_window.show #update the window when the battler is removed
    #@small_status_window.battler = @cursor.battler
    remaining_playable_battlers? ? activate_cursor(:select) : player_group_input_end
  end

  #--------------------------------------------------------------------------
  # * [Status] Command
  #--------------------------------------------------------------------------
  def command_full_status
    @actor_command_window.close
    @full_status_window.actor = @cursor.battler
    @full_status_window.open
    @full_status_window.activate
  end

  #--------------------------------------------------------------------------
  # * [Item] Command
  #--------------------------------------------------------------------------
  def command_item
    @actor_command_window.close
    @item_window.refresh
    @item_window.show.activate
  end

  #--------------------------------------------------------------------------
  # * Ability (Skill/Item) [OK]
  #--------------------------------------------------------------------------
  #item is an item or skill object, type is :item or :skill
  def on_tbs_item_ok(item, type)
    bat = BattleManager.actor
    case type
    when :skill
      bat.input.set_skill(item.id)
    when :item
      bat.input.set_item(item.id)
    end
    l = bat.genTgt(bat.getRange(item.id,type))
    type2 = item.for_friend? ? :help_skill : :skill
    @spriteset.draw_range(l,TBS.spriteType(type2))
    @cursor.set_skill_data(bat, l)
    #@cursor.moveto(bat.pos.x,bat.pos.y)
    activate_cursor(type)
    @cursor.moveto_bat(bat)
    @spriteset.update_tile_sprites
  end
  #--------------------------------------------------------------------------
  # * Skill [OK]
  #--------------------------------------------------------------------------
  def on_skill_ok
    @skill = @skill_window.item
    on_tbs_item_ok(@skill,:skill)
    @skill_window.hide
  end
  #--------------------------------------------------------------------------
  # * Skill [Cancel]
  #--------------------------------------------------------------------------
  def on_skill_cancel
    @skill_window.hide
    open_actor_command_window
    #@actor_command_window.open
    #@actor_command_window.activate
  end
  #--------------------------------------------------------------------------
  # * Item [OK]
  #--------------------------------------------------------------------------
  def on_item_ok
    @item = @item_window.item
    on_tbs_item_ok(@item,:item)
    @item_window.hide
  end
  #--------------------------------------------------------------------------
  # * Item [Cancel]
  #--------------------------------------------------------------------------
  def on_item_cancel
    @item_window.hide
    open_actor_command_window
    #@actor_command_window.open
    #@actor_command_window.activate
  end
  #--------------------------------------------------------------------------
  # * Event Processing
  #--------------------------------------------------------------------------
  def process_event
    while !scene_changing?
      $game_troop.interpreter.update
      $game_troop.setup_battle_event
      wait_for_message
      wait_for_effect if $game_troop.all_dead?
      process_forced_action
      BattleManager.judge_win_loss
      break unless $game_troop.interpreter.running?
      update_for_wait
    end
  end
  #--------------------------------------------------------------------------
  # * Forced Action Processing
  #--------------------------------------------------------------------------
  def process_forced_action
    if BattleManager.action_forced?
      last_subject = @subject
      @subject = BattleManager.action_forced_battler
      BattleManager.clear_action_force
      process_action
      @subject = last_subject
    end
  end
  #--------------------------------------------------------------------------
  # * Battle Action Processing for any TBS actions
  #--------------------------------------------------------------------------
  def process_tbs_action(subject)
    return if scene_changing?
    @subject = subject
    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action.valid? && @subject.current_action.tbs_tgt_valid?
        #@status_window.open
        execute_action(true)
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
    process_event
  end

  #--------------------------------------------------------------------------
  # * Battle Action Processing (for forced actions)
  #--------------------------------------------------------------------------
  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      @subject = BattleManager.next_subject
    end
    return turn_end unless @subject
    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action.valid?
        #@status_window.open
        execute_action
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end
  #--------------------------------------------------------------------------
  # * Processing at End of Action
  #--------------------------------------------------------------------------
  def process_action_end
    @subject.on_action_end
    @remove_list.each{|b| remove_battler(b)}
    @remove_list = []
    #refresh_status
    @log_window.display_auto_affected_status(@subject)
    @log_window.wait_and_clear
    @log_window.display_current_state(@subject)
    @log_window.wait_and_clear
    BattleManager.judge_win_loss
  end
  #--------------------------------------------------------------------------
  # * Execute Battle Actions
  #--------------------------------------------------------------------------
  def execute_action(tbs = false)
    @subject.sprite_effect_type = :whiten
    @subject.char.set_direction(TBS.dir_towards(@subject.pos,@subject.current_action.tgt_pos)) if tbs
    use_item(tbs)
    @log_window.wait_and_clear
  end
  #--------------------------------------------------------------------------
  # * Store Battle Action data
  #--------------------------------------------------------------------------
  def store_action_data(user,action)
    @last_user = user
    @last_item = action.item
    @last_target = action.tgt_pos
  end
  #--------------------------------------------------------------------------
  # * Use Skill/Item
  #--------------------------------------------------------------------------
  def use_item(tbs = false)
    store_action_data(@subject,@subject.current_action)
    item = @subject.current_action.item
    @log_window.display_use_item(@subject, item)
    @subject.use_item(item)
    #refresh_status
    targets = tbs ? @subject.current_action.tbs_make_final_targets : @subject.current_action.make_targets.compact
    @subject.current_action.call_additional_tbs_effects if tbs
    tbs ? show_tbs_animation(targets, item.animation_id, @subject.current_action) : show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  end
  #--------------------------------------------------------------------------
  # * Invoke Skill/Item
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    if rand < target.item_cnt(@subject, item)
      invoke_counter_attack(target, item)
    elsif rand < target.item_mrf(@subject, item)
      invoke_magic_reflection(target, item)
    else
      apply_item_effects(apply_substitute(target, item), item)
    end
    @subject.last_target_index = target.index
  end
  #--------------------------------------------------------------------------
  # * Apply Skill/Item Effect
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    target.item_apply(@subject, item)
    #refresh_status
    @log_window.display_action_results(target, item)
  end
  #--------------------------------------------------------------------------
  # * Invoke Counterattack
  #--------------------------------------------------------------------------
  def invoke_counter_attack(target, item)
    @log_window.display_counter(target, item)
    attack_skill = $data_skills[target.attack_skill_id]
    @subject.item_apply(target, attack_skill)
    #refresh_status
    @log_window.display_action_results(@subject, attack_skill)
  end
  #--------------------------------------------------------------------------
  # * Invoke Magic Reflection
  #--------------------------------------------------------------------------
  def invoke_magic_reflection(target, item)
    @subject.magic_reflection = true
    @log_window.display_reflection(target, item)
    apply_item_effects(@subject, item)
    @subject.magic_reflection = false
  end
  #--------------------------------------------------------------------------
  # * Apply Substitute
  #--------------------------------------------------------------------------
  def apply_substitute(target, item)
    if check_substitute(target, item)
      substitute = target.friends_unit.substitute_battler
      if substitute && target != substitute
        @log_window.display_substitute(substitute, target)
        return substitute
      end
    end
    target
  end
  #--------------------------------------------------------------------------
  # * Check Substitute Condition
  #--------------------------------------------------------------------------
  def check_substitute(target, item)
    target.hp < target.mhp / 4 && (!item || !item.certain?)
  end
  #--------------------------------------------------------------------------
  # * Show Animation
  #     targets      : Target array
  #     animation_id : Animation ID (-1:  Same as normal attack)
  #--------------------------------------------------------------------------
  def show_animation(targets, animation_id)
    if animation_id < 0
      show_attack_animation(targets)
    else
      show_normal_animation(targets, animation_id)
    end
    @log_window.wait
    wait_for_animation
  end

  def show_tbs_animation(targets, animation_id,action)
    return show_animation(targets, animation_id) unless action.item_for_none? || action.item_for_all?
    animation_id = (@subject.actor? ? @subject.atk_animation_id1 : 1) if animation_id < 0
    @spriteset.move_tgt_sprite(action.tgt_pos[0],action.tgt_pos[1])
    @spriteset.anim_tgt_sprite(animation_id)
    @log_window.wait
    wait_for_animation
  end

  #--------------------------------------------------------------------------
  # * Show Attack Animation
  #     targets : Target array
  #    Account for dual wield in the case of an actor (flip left hand weapon
  #    display). If enemy, play the [Enemy Attack] SE and wait briefly.
  #--------------------------------------------------------------------------
  def show_attack_animation(targets)
    if @subject.actor?
      show_normal_animation(targets, @subject.atk_animation_id1, false)
      wait_for_animation #added
      show_normal_animation(targets, @subject.atk_animation_id2, true)
    else
      show_normal_animation(targets, 1, false) #added
      Sound.play_enemy_attack
      abs_wait_short
    end
  end
  #--------------------------------------------------------------------------
  # * Show Normal Animation
  #     targets      : Target array
  #     animation_id : Animation ID
  #     mirror       : Flip horizontal
  #--------------------------------------------------------------------------
  def show_normal_animation(targets, animation_id, mirror = false)
    animation = $data_animations[animation_id]
    if animation
      targets.each do |target|
        target.animation_id = animation_id
        target.animation_mirror = mirror
        abs_wait_short unless animation.to_screen?
      end
      abs_wait_short if animation.to_screen?
    end
  end

  #--------------------------------------------------------------------------
  # Map
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # setup_map -> sets the battle map amd return data read frpm the map tp setup events and positions
  #--------------------------------------------------------------------------
  def setup_map
    if TBS::BTEST_MAPID > 0 && $BTEST
      @map_id = TBS::BTEST_ID
    else
      $game_map.save_map_data
      @map_id = $game_map.map_id
    end
    battle_map_id = determine_battle_map(@map_id)
    return $game_map.tbs_setup(battle_map_id) #[places_loc, extra_battlers, obstacles, enemy_loc, actor_loc]
  end

  #--------------------------------------------------------------------------
  # determine_battle_map -> find the battle map to load given the starting map
  #--------------------------------------------------------------------------
  def determine_battle_map(map_id)
    return map_id if $BTEST
    map_id = TBS::CALL_ALTERNATE_MAP[map_id] if TBS::CALL_ALTERNATE_MAP[map_id]
    return map_id
  end

  #--------------------------------------------------------------------------
  # return_to_map -> go back to the original map
  #--------------------------------------------------------------------------
  def return_to_map
    $game_map.retrieve_map = true #will load the data of the map, if the exit map is not the same as the map that called the battle, this should be set to false
    $game_map.setup(@map_id)
    $game_player.refresh
    $game_player.center($game_player.x, $game_player.y)
  end

  #--------------------------------------------------------------------------
  # Cursors
  #--------------------------------------------------------------------------
  def create_cursor
    #create cursor
    @cursor = TBS_Cursor.new
  end

  #--------------------------------------------------------------------------
  # Get cursor
  #--------------------------------------------------------------------------
  def tbs_cursor
    @cursor
  end

  #--------------------------------------------------------------------------
  # activate_cursor -> the cursor becomes controllable, mode is either :place, :select, :move, :item, :skill or :attack
  #--------------------------------------------------------------------------
  def activate_cursor(mode)
    set_preview_dmg if [:attack,:skill,:item].include?(mode)
    @cursor.moveto(@cursor.x,@cursor.y)
    @cursor.battler.nil? ? @small_status_window.hide : @small_status_window.show
    @small_status_window.battler = @cursor.battler
    @cursor.active = true
    @cursor.mode = mode
    @cursor.controllable = mode != :observe
  end

  #--------------------------------------------------------------------------
  # disactivate_cursor -> the cursor cannot be moved
  #--------------------------------------------------------------------------
  def disactivate_cursor
    @spriteset.get_battler_sprites.each{|s| s.stop_team_blink} if $game_system.area_blink
    @cursor.active = false
    #@cursor.menu_skill = false
    @cursor.mode = nil
    @small_status_window.hide
    @small_status_window.battler = nil
  end

  #--------------------------------------------------------------------------
  # update_cursor -> the main update of the cursor
  #--------------------------------------------------------------------------
  def update_cursor
    return unless @cursor.active
    @cursor.update #moves the cursor and updates its internal data
    @interaction = false #compatibility, a sound will play depending of interaction status
    if @cursor.controllable
      if Input.trigger?(Input::B) #cancel
        on_cursor_cancel
      elsif Input.trigger?(Input::C) #confirm
        on_cursor_ok
      elsif Input.repeat?(Input::R) #right
        on_cursor_next
      elsif Input.repeat?(Input::L) #left
        on_cursor_previous
      elsif Input.repeat?(Input::A)
        on_cursor_next
      elsif Input.repeat?(Input::Z)
        on_cursor_previous
      end
    end
    return unless @cursor.active
    if @cursor.has_moved #cursor might have been disactivated
      @spriteset.dispose_range(TBS.spriteType(:move)) if @cursor.mode == :select #when selecting battlers
      @cursor.battler.nil? ? @small_status_window.hide : @small_status_window.show
      @small_status_window.battler = @cursor.battler
      cursor_sprite = @spriteset.get_cursor_sprite
      @small_status_window.check_relocate(cursor_sprite.x,cursor_sprite.y) unless cursor_sprite.nil?
    end
    update_cursor_place if @cursor.mode == :place
  end

  #--------------------------------------------------------------------------
  # update_cursor_place -> used for place phase updates
  #--------------------------------------------------------------------------
  def update_cursor_place
    cursor_sprite = @spriteset.get_cursor_sprite
    @place_status_window.check_relocate_place(cursor_sprite.x,cursor_sprite.y) unless cursor_sprite.nil?
    if @place_pointer.nil?
      return @place_status_window.hide unless TBS::DISPLAY_EMPTY_PARTY
      @place_status_window.battler = nil
      @place_status_window.show
    else
      @place_status_window.battler = @place_candidates[@place_pointer]
      @place_status_window.show
    end
  end

  #--------------------------------------------------------------------------
  # update_direction_cursor -> the main update of the direction cursor (used at and of actions)
  #--------------------------------------------------------------------------
  def update_direction_cursor
    return if @wait_pic.nil? || !@wait_pic.active
    @wait_pic.update
    if Input.trigger?(Input::B)
      @wait_pic.on_cancel
      @wait_pic.dispose
      @wait_pic = nil
      open_actor_command_window
    elsif Input.trigger?(Input::C)
      @wait_pic.active = false
      setup_confirm_window(:wait)
    end
  end

  #--------------------------------------------------------------------------
  # on_cursor_next -> when :R is pressed like page_up
  #--------------------------------------------------------------------------
  def on_cursor_next
    return place_pointer_next if @cursor.mode == :place
    return if @cursor.locked_in_range?
    b = nil
    if @cursor.battler
      i = @turnWheel.getTurnIndex(@cursor.battler)
      b = @turnWheel.getBattler((i+1) % @turnWheel.size) unless i.nil?
    else
      b = @turnWheel.getBattler(0)
    end
    return if b.nil? #should not happen
    Sound.play_cursor
    @cursor.moveto(b.pos.x,b.pos.y)
  end
  #--------------------------------------------------------------------------
  # on_cursor_previous -> when :L is pressed like page_down
  #--------------------------------------------------------------------------
  def on_cursor_previous
    return place_pointer_previous if @cursor.mode == :place
    return if @cursor.locked_in_range?
    b = nil
    if @cursor.battler
      i = @turnWheel.getTurnIndex(@cursor.battler)
      b = @turnWheel.getBattler(i-1) unless i.nil?
    else
      b = @turnWheel.getBattler(-1)
    end
    return if b.nil? #should not happen
    Sound.play_cursor
    @cursor.moveto(b.pos.x,b.pos.y)
  end

  #--------------------------------------------------------------------------
  # on_cursor_ok -> when :C is pressed
  #--------------------------------------------------------------------------
  def on_cursor_ok
    case @cursor.mode
    when :place #placment phase
      unless @places.include?([@cursor.x,@cursor.y])
        Sound.play_buzzer unless @interaction
        return
      end
      #return Sound.play_buzzer unless @places.include?([@cursor.x,@cursor.y])
      bat = @place_candidates.find{|a| a.tbs_battler && a.pos.x == @cursor.x && a.pos.y == @cursor.y}
      #bat = i ? @place_candidates[i] : nil
      rm_place_phase_bat(bat) if bat
      init_battler_list
      add_place_phase_bat(@place_candidates[@place_pointer],@cursor.x,@cursor.y) if @place_pointer
      init_battler_list
      if place_pointer_next.nil? || @remaining_places <= 0
        disactivate_cursor
        command_start_battle
      end
      return
    when :select
      bat = @cursor.battler
      return Sound.play_buzzer if bat.nil? && !@interaction
      return if bat.nil?
      if bat.player_controllable? && bat.is_active?
        Sound.play_ok
        @cursor.select_bat(bat)
        @actor_command_window.setup(bat)
        disactivate_cursor
      else #bat exists and stuff
        @spriteset.dispose_range(TBS.spriteType(:move))
        route, cost = bat.calc_pos_move
        @spriteset.draw_range(route.keys,TBS.spriteType(:move))
        Sound.play_buzzer
        #call status menu!
      end
      #get battler under cursor
      #if no battler
      #  call config_menu
      #if battler is controllable (must be its turn!)
      #  call command menu
      #if battler is not controllable
      #  call status menu
      return
    when :move
      return Sound.play_buzzer if @cursor.battler
      disactivate_cursor
      setup_confirm_window(:move)
      return
    when :attack, :skill, :item
      return Sound.play_buzzer unless @cursor.cursor_in_range? && @cursor.origin_bat.input.tbs_tgt_valid?
      mode = @cursor.mode
      disactivate_cursor
      setup_confirm_window(mode)
      return
    end
    disactivate_cursor
    @spriteset.dispose_tile_sprites
  end

  #--------------------------------------------------------------------------
  # on_cursor_cancel -> when :B is pressed
  #--------------------------------------------------------------------------
  def on_cursor_cancel
    case @cursor.mode
    when :place #placment phase
      bat = @place_candidates.find{|a| a.tbs_battler && a.pos.x == @cursor.x && a.pos.y == @cursor.y}
      #bat = i ? @place_candidates[i] : nil
      if @places.include?([@cursor.x,@cursor.y]) && bat
        rm_place_phase_bat(bat)
        init_battler_list
        place_pointer_next unless @place_pointer
      else
        #disactivate_cursor
        @place_status_window.hide
        @place_command_window.refresh
        open_global_commands
      end
      return
    when :select
      open_global_commands
    when :move
      open_actor_command_window
    when :attack
      open_actor_command_window
    when :skill
      if @cursor.menu_skill
        open_actor_command_window
      else
        @cursor.moveto_bat(@cursor.origin_bat)
        @skill_window.show
        @skill_window.activate
      end
    when :item
      if @cursor.menu_skill
        open_actor_command_window
      else
        @cursor.moveto_bat(@cursor.origin_bat)
        @item_window.show
        @item_window.activate
      end
    end
    disactivate_cursor
    @spriteset.dispose_tile_sprites
  end

  #--------------------------------------------------------------------------
  # Confirm Window
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # setup_confirm_window -> if the window is not needed, go directly to YES
  #--------------------------------------------------------------------------
  def setup_confirm_window(type)
    if TBS::Confirm.ask_confirm?(type)
      @confirm_window.setup(type)
    else
      @confirm_window.set_mode(type)
      on_confirm_ok
    end
  end

  #--------------------------------------------------------------------------
  # on_confirm_ok -> when YES is chosen in the confirm window
  #--------------------------------------------------------------------------
  def on_confirm_ok
    case @confirm_window.mode
    when :attack, :skill, :item
      @confirm_window.close
      @spriteset.dispose_tile_sprites
      process_tbs_action(@cursor.origin_bat)
      #wait_for_effect #wait for the action of the battler
      open_actor_command_window
      return
    when :move
      @cursor.origin_bat.move_through_path(@cursor.path.route,@cursor.path.cost)
      @confirm_window.close
      @spriteset.dispose_tile_sprites
      wait_for_effect #wait for the move of the battler
      open_actor_command_window
      return
    when :wait
      @confirm_window.close
      @wait_pic.battler.skip_turn
      @wait_pic.dispose
      @wait_pic = nil
      command_cursor_select
      return
    when :skip_turn
      @confirm_window.close
      @party_command_window.close
      player_group_input_end
    when :start_battle
      @spriteset.dispose_range(TBS.spriteType(:place))
      BattleManager.play_battle_bgm
      @place_status_window.hide
      @confirm_window.close
      @place_command_window.close
      return battle_start
    when :settings
      @options_window.save_changes
      open_global_commands
    end
    @confirm_window.close
  end

  #--------------------------------------------------------------------------
  # on_confirm_cancel -> when NO is chosen in the confirm window
  #--------------------------------------------------------------------------
  def on_confirm_no
    return on_confirm_cancel unless @confirm_window.mode == :settings
    case @confirm_window.mode
    when :settings
      @options_window.discard_changes
      open_global_commands
    end
    @confirm_window.close
  end

  #--------------------------------------------------------------------------
  # on_confirm_cancel -> when CANCEL is chosen in the confirm window
  #--------------------------------------------------------------------------
  def on_confirm_cancel
    case @confirm_window.mode
    when :skill, :item, :attack, :move
      activate_cursor(@confirm_window.mode)
    when :wait
      @wait_pic.active = true
    when :skip_turn
      @party_command_window.activate
    when :start_battle
      @place_command_window.close? ? command_cursor_place : @place_command_window.activate
    when :settings
      @options_window.activate
    end
    @confirm_window.close
  end

  #--------------------------------------------------------------------------
  # open_actor_command_window -> when an action was done, go back to the actor list, or ask for end of turn
  #--------------------------------------------------------------------------
  def open_actor_command_window
    @cursor.menu_skill = false
    @cursor.moveto_bat(@cursor.origin_bat)
    @small_status_window.hide
    @full_status_window.close
    @actor_command_window.refresh
    return command_cursor_select unless @cursor.origin_bat.player_controllable?
    return command_choose_dir unless @actor_command_window.remaining_commands?
    @actor_command_window.open
    @actor_command_window.activate
  end

  #--------------------------------------------------------------------------
  # open_winconditions
  #--------------------------------------------------------------------------
  def open_winconditions
    @place_command_window.close
    @party_command_window.close
    @wincond_window.refresh
    @wincond_window.open
    @wincond_window.activate
  end

  #--------------------------------------------------------------------------
  # open_turnorder
  #--------------------------------------------------------------------------
  def open_turnorder
    @party_command_window.close
    @turnorder_window.refresh
    activate_cursor(:observe)
    @turnorder_window.open
    @turnorder_window.activate
  end

  #--------------------------------------------------------------------------
  # on_win_window_cancel
  #--------------------------------------------------------------------------
  def open_global_commands
    disactivate_cursor
    @turnorder_window.close
    @wincond_window.close
    global_win = @phase == :setup ? @place_command_window : @party_command_window
    global_win.setup
    #global_win.refresh
    #global_win.open
    #global_win.activate
  end

  #--------------------------------------------------------------------------
  # Getters
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # init_battler_list -> Called after the party members and the enemies are placed
  #--------------------------------------------------------------------------
  def init_battler_list
    @tbs_battlers = $game_party.tbs_members + $game_troop.tbs_members
  end

  #--------------------------------------------------------------------------
  # tactics_battlers -> all battlers that can take decision during a battle
  #--------------------------------------------------------------------------
  def tactics_battlers
    @tbs_battlers
  end
  #--------------------------------------------------------------------------
  # obstacles -> all battlers that do not take any decision
  #--------------------------------------------------------------------------
  def obstacles
    $game_troop.obstacles
  end

  #--------------------------------------------------------------------------
  # tactics_all -> all battlers
  #--------------------------------------------------------------------------
  def tactics_all
    tactics_battlers + obstacles
  end
  #--------------------------------------------------------------------------
  # tactics_team -> all battlers of a team
  #--------------------------------------------------------------------------
  def tactics_team(team)
    tactics_battlers.select {|mem| mem.team == team}
  end
  #--------------------------------------------------------------------------
  # team_alive? -> is the team alive?
  #--------------------------------------------------------------------------
  def team_alive?(team)
    tactics_battlers.any?{|b| b.alive? && b.team == team}
  end

  #def tactics_alive
  #  tactics_all.select {|mem| mem.alive?}#!mem.death_state?}
  #end
  #ef tactics_dead
  #  return tactics_all.select{|b| b.dead?}
  #end

  #used to check if any actor from the main team is in battle, abort battle if empty
  def tactics_party
    $game_party.all_members.select {|mem| mem.tbs_battler && mem.team == TBS::TEAMS::TEAM_ACTORS}
  end


  #--------------------------------------------------------------------------
  # battlers_in_area -> return the list of battlers that are in the area of the cursor
  #--------------------------------------------------------------------------
  def battlers_in_area
    return [] unless @cursor.requires_area?
    return BattleManager.actor.input.tbs_make_targets(@cursor.area)
    #return []
  end

  #--------------------------------------------------------------------------
  # add_place_phase_bat
  #--------------------------------------------------------------------------
  def add_place_phase_bat(bat,x,y)
    return unless bat
    @remaining_places -= 1 if add_battler(bat,[[x,y]])
  end
  #--------------------------------------------------------------------------
  # rm_place_phase_bat
  #--------------------------------------------------------------------------
  def rm_place_phase_bat(bat)
    return unless bat
    remove_battler(bat)
    @remaining_places += 1
  end
  #--------------------------------------------------------------------------
  # place_pointer_previous
  #--------------------------------------------------------------------------
  def place_pointer_previous
    @place_pointer = 0 if @place_pointer.nil?
    @place_pointer -= 1
    while @place_pointer >= 0 && @place_candidates[@place_pointer].tbs_battler
      @place_pointer -= 1
    end
    @place_pointer = @place_candidates.rindex{|a| !a.tbs_battler} if @place_pointer < 0
    return @place_pointer
  end
  #--------------------------------------------------------------------------
  # place_pointer_next
  #--------------------------------------------------------------------------
  def place_pointer_next
    @place_pointer = 0 if @place_pointer.nil?
    @place_pointer += 1
    while @place_pointer < @place_candidates.size && @place_candidates[@place_pointer].tbs_battler
      @place_pointer += 1
    end
    @place_pointer = @place_candidates.index{|a| !a.tbs_battler} if @place_pointer >= @place_candidates.size
    return @place_pointer
  end
  #--------------------------------------------------------------------------
  # Main Loop
  #--------------------------------------------------------------------------
  #init
    #placement_phase
    #for_each_global_turn:
    # turn(team) : select action, apply them -> can lead to defeat
    # check_victory_cond (team is alive etc.) -> break
    # team = next_team #list of battlers
    # if team.first? : next_turn (increase count, trigger events, start_turn etc.)
    # ? check_victory_cond2 (turn count) -> break
    #exit_battle(result)
    #delete

  #--------------------------------------------------------------------------
  # add_battler -> add a battler midgame or during place phase (will not add the bat to the troop/party!)
  #--------------------------------------------------------------------------
  #tries to put a battler in game, return false if no such battler may be put, return true otherwise
  #force_place if you want to place the battler regardless
  def add_battler(bat,posList,force_place = false)
    i = force_place ? 0 : posList.index{|p| bat.can_occupy?(p)}
    return false if i.nil?
    pos = posList[i]
    bat.tbs_entrance(pos[0],pos[1])
    @spriteset.create_battler_sprite(bat) if @spriteset
    if @phase == :battle && !bat.obstacle?
      @tbs_battlers.push(bat)
      @turnWheel.addBattler(bat,bat.parent)
      bat.on_battle_start
    end
    return true
  end

  #--------------------------------------------------------------------------
  # remove_battler -> remove all children of a battler (battlers with bat as parent)
  #--------------------------------------------------------------------------
  def remove_children(bat)
    tactics_battlers.select{|b| b.parent == bat}.each{|b| b.die; remove_battler(b)}
  end

  #--------------------------------------------------------------------------
  # prepare_remove_battler -> list the battler to be removed (temporary data)
  #--------------------------------------------------------------------------
  def prepare_remove_battler(bat)
    @remove_list.push(bat)
  end

  #--------------------------------------------------------------------------
  # remove_battler -> remove a battler midgame or during place phase (except for obstacles, will not delete the bat from the troop/party!)
  #--------------------------------------------------------------------------
  def remove_battler(bat)
    remove_children(bat) #children are removed too when the battler is removed
    if bat.obstacle?
      obstacles.delete(bat)
    elsif @phase == :battle
      @turnWheel.removeBattler(bat)
      @tbs_battlers.delete(bat)
      @active_battlers.delete(bat)
      #if battler was somehow active
    end
    @spriteset.dispose_battler_sprite(bat) if @spriteset
    @phase == :battle ? bat.on_battle_end : bat.tbs_leave
    #@turnWheel.removeBattler(bat) unless bat.obstacle?
  end

  #--------------------------------------------------------------------------
  # create_battlers -> setup all the battler (except the actors to place) according to the data of the map
  #--------------------------------------------------------------------------
  def create_battlers(map_tbs_data)
    #@map_tbs_data = [places_loc, extra_battlers, obstacles, enemy_loc, actor_loc]
    @places_loc, extra_battlers, obstacles_list, enemy_loc, actor_loc = map_tbs_data
    for actor in $game_party.all_candidate_battlers
      #actor.hide
      actor.tbs_battler = false #disactivate the actor from the battle members unless it is added afterwards
      actor_pos = actor_loc[actor.id]
      actor.tbs_entrance(actor_pos.x, actor_pos.y) unless actor_pos.nil?
    end
    for battler in $game_troop.members
      #battler.hide
      en_pos = enemy_loc[battler.index+1]
      battler.tbs_entrance(en_pos.x, en_pos.y) unless en_pos.nil?
      battler.letter = ""
    end
    for battler in obstacles_list
      $game_troop.add_obstacle(battler)
      battler.tbs_entrance(battler.char.x, battler.char.y)
    end
    for battler in extra_battlers
      $game_troop.add_extra_battler(battler)
      battler.tbs_entrance(battler.char.x, battler.char.y)
    end
    remaining_battlers = ($game_party.all_candidate_battlers + $game_troop.all_candidate_battlers).select{|mem| mem.tbs_battler == false}
    @place_candidates = $game_party.all_members.select{|actor| actor.can_battle? && !actor.tbs_battler}
    for team in 0...@places_loc.size
      next if TBS::PLACE_ACTORS && team == TBS::TEAMS::TEAM_ACTORS && !$game_system.pre_place #skip the pos list of actors, this should be done elsewhere
      pList = @places_loc[team].shuffle
      next unless pList.size > 0
      batList = remaining_battlers.select{|mem| mem.team == team && mem.can_battle?}
      for i in 0...pList.size
        break if i >= batList.size
        pos = pList[i]
        bat = batList[i]
        bat.tbs_entrance(pos[0],pos[1])
      end
    end
    init_battler_list
    #Abort battle to title if map has no actors placed on it.
    if $game_party.tbs_members.size == 0 && @places_loc[TBS::TEAMS::TEAM_ACTORS].size == 0
      raise "NO SPACE FOR ACTORS :'("
      SceneManager.clear
      SceneManager.goto(SceneManager.first_scene_class)
    #Abort battle to title if map has no enemies placed on it.
    elsif $game_troop.tbs_members.size == 0
      raise "NO SPACE FOR ENEMIES >:("
      SceneManager.clear
      SceneManager.goto(SceneManager.first_scene_class)
    end
  end

  #--------------------------------------------------------------------------
  # pre_battle_start -> starts place scene or skip it if no places available
  # or feature disabled
  #--------------------------------------------------------------------------
  def pre_battle_start
    @phase = :setup
    #@place_candidates = $game_party.all_members.select{|actor| actor.can_battle? && !actor.tbs_battler}
    @places = @places_loc[TBS::TEAMS::TEAM_ACTORS]
    if !TBS::PLACE_ACTORS || @place_candidates.empty? || @places.empty?
      @confirm_window.set_mode(:start_battle)
      return on_confirm_ok #unless (TBS::PLACE_ACTORS and not @places.empty?)
    end
    actors_placed = @place_candidates.select{|actor| actor.tbs_battler}.size
    @remaining_places = @places.size - actors_placed
    @spriteset.draw_range(@places,TBS.spriteType(:place))
    if TBS::PLACE_MUSIC_SWICTH > 0 && !$game_switches[TBS::PLACE_MUSIC_SWICTH]
      BattleManager.play_battle_bgm
    else
      $game_system.place_music.play
    end
    @place_pointer = @place_candidates.index{|a| !a.tbs_battler}
    @place_pointer = 0 unless @place_pointer
    @cursor.moveto(@places[0][0],@places[0][1])
    if @remaining_places <= 0 || @place_candidates.size - actors_placed <= 0
      @place_pointer = nil if @place_candidates.size - actors_placed <= 0
      return setup_confirm_window(:start_battle)
    end
    command_cursor_place
  end

  #--------------------------------------------------------------------------
  # battle_start -> once every battler is place, initiate the turnwheel and starts
  #--------------------------------------------------------------------------
  def battle_start
    init_battler_list #catch the remaining battlers added before starting combat
    @phase = :battle
    @turnWheel = TurnWheel.new($game_system.turn_mode)
    bats = []#[$game_party.members,$game_troop.members]
    for team in 0...TBS::TEAMS.nb_teams
      l = tactics_team(team)
      bats += [l] unless l.size == 0
    end
    @turnWheel.computeOrder(bats)
    puts @turnWheel.battlerList.map{|b| b.name}
    BattleManager.battle_start
    process_event
    turn_start
    #next_group_turn
    #start_party_command_selection
  end

  #--------------------------------------------------------------------------
  # remaining_playable_battlers -> can the player still use battlers or should we just skip the turn ?
  #--------------------------------------------------------------------------
  def remaining_playable_battlers?
    @active_battlers.any?{|b| b.player_controllable? && b.is_active?}
  end

  #--------------------------------------------------------------------------
  # player_group_input_end -> called to end player input phase and deal with the remaining ais or skip to the next local turn
  #--------------------------------------------------------------------------
  def player_group_input_end
    @active_battlers.each{|b| on_turn_end(b) if b.player_controllable? || !b.is_active?}
    @active_battlers.select!{|b| b.is_active?}
    @active_battlers.empty? ? next_group_turn : ai_handle_turn
  end

  #--------------------------------------------------------------------------
  # ai_handle_turn -> lets the ai finish the turn for the remaining active battlers
  #--------------------------------------------------------------------------
  def ai_handle_turn
    next_group_turn #this will be ovewritten when introducing ais
  end

  #--------------------------------------------------------------------------
  # next_group_turn -> ends the local turn and starts the next
  #--------------------------------------------------------------------------
  def next_group_turn
    return if scene_changing? #avoid infinite loop and go to end of battle
    for b in @active_battlers
      on_turn_end(b)
    end
    if @turnWheel.forward
      @active_battlers = @turnWheel.getActiveBattlers
      puts sprintf("Turn of %d battlers:",@active_battlers.size)
      puts @active_battlers.map{|bat| bat.name}
      for b in @active_battlers
        b.make_actions
        on_turn_start(b)
      end
      @cursor.moveto_bat(@active_battlers[0]) if @active_battlers.size > 0
      command_cursor_select #will activate cursor iff there are active battlers, else will call ai
    else
      turn_end #global turn end
    end
  end

  #--------------------------------------------------------------------------
  # on_turn_start
  #--------------------------------------------------------------------------
  def on_turn_start(bat)
    bat.on_turn_start
  end
  #--------------------------------------------------------------------------
  # on_turn_end
  #--------------------------------------------------------------------------
  def on_turn_end(bat)
    bat.on_turn_end
  end

  #--------------------------------------------------------------------------
  # turn_start -> call the battle events, make the turn for obstacles then starts the next local turn
  #--------------------------------------------------------------------------
  def turn_start
    @subject =  nil
    BattleManager.turn_start
    @log_window.wait
    @log_window.clear
    process_event
    #update_obstacles
    for b in obstacles
      b.make_actions #just in case, but it should not be used
      on_turn_start(b) #activate all obstacles
    end
    for b in obstacles
      on_turn_end(b) #disactivate them, simulate parrallel turns just in case
    end
    #@party_command_window.close
    #@actor_command_window.close
    #@status_window.unselect
    next_group_turn
  end
  #--------------------------------------------------------------------------
  # turn_end -> call the battle events, then initiate next global turn
  #--------------------------------------------------------------------------
  def turn_end
    BattleManager.turn_end
    process_event
    turn_start
  end

  #--------------------------------------------------------------------------
  # new method: set_preview_dmg -> calls all battlers and calculate their
  # damage preview in case they are selected
  #--------------------------------------------------------------------------
  def set_preview_dmg
    @spriteset.get_battler_sprites.each{|s| s.start_team_blink} if $game_system.area_blink
    user = BattleManager.actor
    item = user.input.item
    tactics_all.each {|bat| bat.prepare_preview_damage(user,item)}
  end
end #Scene_TBS_Battle

#==============================================================================
#
# TBS BattleManager
#
#==============================================================================
#
# TBS BattleManager
#
#==============================================================================

#============================================================================
# BattleManager -> changes to start and end of battles and change to the win conditions
#============================================================================
class << BattleManager
  alias tbs_judge judge_win_loss
  alias tbs_battlemanager_actor actor
  alias tbs_bm_battle_start battle_start
  alias tbs_bm_battle_end battle_end
  #alias tbs_bm_make_action_order make_action_order
end
module BattleManager
  #--------------------------------------------------------------------------
  # alias method: battle_start -> battle start for all tbs battlers
  #--------------------------------------------------------------------------
  def self.battle_start
    return tbs_bm_battle_start unless SceneManager.scene_is?(Scene_TBS_Battle)
    $game_system.battle_count += 1
    #modified
    $game_party.on_tbs_battle_start
    $game_troop.on_tbs_battle_start
    for b in SceneManager.scene.obstacles
      b.on_battle_start
    end
    #/modified
    $game_troop.enemy_names.each do |name|
      $game_message.add(sprintf(Vocab::Emerge, name))
    end
    if @preemptive
      $game_message.add(sprintf(Vocab::Preemptive, $game_party.name))
    elsif @surprise
      $game_message.add(sprintf(Vocab::Surprise, $game_party.name))
    end
    wait_for_message
  end

  #--------------------------------------------------------------------------
  # alias method: battle_end -> battle end for all tbs battlers
  #--------------------------------------------------------------------------
  def self.battle_end(result)
    return tbs_bm_battle_end(result) unless $game_system.tbs_enabled?
    @phase = nil
    @event_proc.call(result) if @event_proc
    $game_party.on_tbs_battle_end
    $game_troop.on_tbs_battle_end
    $game_troop.obstacles.each {|b| b.on_battle_end}
    SceneManager.exit if $BTEST
  end

  #def self.turn_start
  #  @phase = :turn
  #  clear_actor
  #  $game_troop.increase_turn
  #  make_action_orders unless SceneManager.scene_is?(Scene_TBS_Battle)
  #end

  #--------------------------------------------------------------------------
  # alias method: actor -> actor will refer to the selected battler by cursor, may be an enemy
  #--------------------------------------------------------------------------
  def self.actor
    return tbs_battlemanager_actor unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.tbs_cursor.origin_bat
  end

  #--------------------------------------------------------------------------
  # new method: teams_routed? -> useful for win/lose conditions
  #--------------------------------------------------------------------------
  def self.teams_routed?(scene, team_list)
    for t in team_list
      return false if scene.team_alive?(t)
    end
    return true
  end

  #--------------------------------------------------------------------------
  # new method: end_battle_cond? -> useful for patches with Yanfly Battle Engine
  #--------------------------------------------------------------------------
  def self.end_battle_cond?
    return false unless SceneManager.scene_is?(Scene_TBS_Battle)
    scene = SceneManager.scene
    if @phase
      return true   if scene.tactics_party.empty?
      return true   if teams_routed?(scene,TBS::TEAMS::TEAMS_TO_SURVIVE)
      return true   if teams_routed?(scene,TBS::TEAMS::TEAMS_TO_ROUT)
      return true   if aborting?
    end
    return false
  end

  #--------------------------------------------------------------------------
  # alias method: judge_win_loss -> now ends the battle when the selected teams are routed one way or another
  #--------------------------------------------------------------------------
  def self.judge_win_loss
    return tbs_judge unless SceneManager.scene_is?(Scene_TBS_Battle)
    scene = SceneManager.scene
    if @phase
      return process_abort   if scene.tactics_party.empty?
      return process_defeat  if teams_routed?(scene,TBS::TEAMS::TEAMS_TO_SURVIVE) #$game_party.all_dead?
      return process_victory if teams_routed?(scene,TBS::TEAMS::TEAMS_TO_ROUT)
      return process_abort   if aborting?
    end
    return false
  end
end #BattleManager

#==============================================================================
#
# TBS Position
#
#==============================================================================

#============================================================================
# Position class
#----------------------------------------------------------------------------
# This class simply stores x,y info for faster reading than from arrays
#============================================================================

#============================================================================
# POS -> stores x,y for math operations
#============================================================================
class POS
  attr_accessor :x
  attr_accessor :y
  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end
  def +(obj)
    return POS.new(@x + obj[0], @y + obj[1])
  end
  def -(obj)
    return POS.new(@x - obj[0], @y - obj[1])
  end
  def ==(obj)
    return (@x == obj[0] && @y == obj[1])
  end
  #--------------------------------------------------------------------------
  # eql? and hash methods are for Hash tables, POS is considered as an [x,y] array
  #--------------------------------------------------------------------------
  alias eql? ==
  def hash
    [@x,@y].hash
  end
  #--------------------------------------------------------------------------
  # manathan_norm -> sum of x and y axis
  #--------------------------------------------------------------------------
  def manathan_norm
    return @x.abs + @y.abs
  end
  #--------------------------------------------------------------------------
  # a 2-dimension distance in absolute value in each axis
  #--------------------------------------------------------------------------
  def local_dist(other)
    return POS.new(abs(@x - other.x), abs(@y - other.y))
  end
  #--------------------------------------------------------------------------
  # a 2-dimension distance in each axis with respect to the map
  #--------------------------------------------------------------------------
  def map_dist(other)
    dx = @x - other[0]
    dy = @y - other[1]
    dx += (dx < 0 ? $game_map.width : -$game_map.width) if $game_map.loop_horizontal? && dx.abs > $game_map.width / 2
    dx += (dy < 0 ? $game_map.height : -$game_map.height) if $game_map.loop_vertical? && dy.abs > $game_map.height / 2
    return dx,dy
  end
  #--------------------------------------------------------------------------
  # euclidian_norm -> the distance of the vector as sqrt(x^2 + y^2)
  #--------------------------------------------------------------------------
  def euclidian_norm
    return Math.sqrt(@x*@x + @y*@y)
  end

  def moveto(x,y)
    @x = x
    @y = y
  end

  def [](key)
    return @x if key == 0
    return @y
  end

  #def coordinates
  #  return x,y
  #end

  #--------------------------------------------------------------------------
  # signs -> returns a [sx,sy] array with sx the sign of x and sy the sign of y, 0 if x/y is 0
  #--------------------------------------------------------------------------
  def signs
    a = @x > 0 ? 1 : -1
    a = 0 if @x == 0
    b = @y > 0 ? 1 : -1
    b = 0 if @y == 0
    return a,b
  end
end

#==============================================================================
#
# TBS Move Rules
#
#==============================================================================

#deals with the move cost of tiles and enemy move_restrictions

module TBS
  #--------------------------------------------------------------------------
  # new method: tbs_passable? -> return true iff the battler with move_type type
  # can cross the cell x,y from direction d?
  #--------------------------------------------------------------------------
  def self.tbs_passable?(x,y,d,type)
    case type
    when :ground
      return $game_map.passable?(x,y,d)
    when :boat
      return $game_map.boat_passable?(x,y)
    when :ship
      return $game_map.ship_passable?(x,y)
    when :flight
      return true
    else #walls
      return false
    end
  end
end #TBS

#============================================================================
# MoveRule -> stores move cost data and restrictions, used in calc_pos_move
#============================================================================
class MoveRule
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :id #the move_rule_id
  attr_reader :cross_allies #array of move_types the moverule may cross when friends
  attr_reader :cross_neutrals #array of move_types the moverule may cross when neutral
  attr_reader :cross_enemies #array of move_types the moverule may cross when enemies
  attr_reader :travel_mode #move_type, see MOVE_TYPES
  attr_reader :move_cost_tt #array of costs per terrain_tags
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(id)#,travel_mode,cross_allies,cross_neutrals,cross_enemies,move_cost_tt)
    @id = id
    l = TBS::MOVE_DATA[id]
    @travel_mode = l[0]#travel_mode #this will refer to game_map move mode
    @cross_allies = l[1]#cross_allies #table of move_types that can be crossed
    @cross_neutrals = l[2]#cross_neutrals #table of move modes that can be crossed
    @cross_enemies = l[3]#cross_enemies #table of move modes that can be crossed
    #move cost by terrain tags, I suggest using integers only but it is not mandatory, all values must be above 0!
    @move_cost_tt = TBS::MOVE_COSTS_TT[id]#move_cost_tt
  end
  #--------------------------------------------------------------------------
  # get_cost_move -> returns the cost in move points when attempting to cross the terrain tag
  #--------------------------------------------------------------------------
  def get_cost_move(terain_tag)
    cost = @move_cost_tt[terain_tag]
    return cost.nil? ? TBS::DEFAULT_MOVE_COST : cost
  end
end #MoveRule

#==============================================================================
#
# TBS SpellRange
#
#==============================================================================

#============================================================================
# CastRange and SpellRange
#----------------------------------------------------------------------------
# These classes represent the range of spells/items/weapons,
#
# CastRange is a small object similar to a table [min,max,sight,type]
# where min is the minimum distance between the source and the target, max is the maximum range
# sight (true or false value) represents whether the spell is blocked by obstacles
# type is the range type : it can be based on distance, a square shape, a straight line or diagonals
#
# SpellRange is the actual object dealt with for casting actions :
# it is made of two CastRange objects: the range and the area of effect
#
# Note for self: might need to update SpellRange to contain an array of areas (for multiple effects)
#===========================================================================

module TBS
  #cross is the same as line but for area of effect it differs
  RANGE_TYPES = [:default, :square, :line, :cross, :diagonal,:perpendicular]
  #used by ais to determine if the position of the src matters for the shape of the area
  DIRECTIONAL_RANGE_TYPES = [:line,:perpendicular]
  #DEFAULT_RANGE = [0,0,true,:default]

  #--------------------------------------------------------------------------
  # new method: range_order -> returns the biggest range_type between the two compared, useful for ais
  #--------------------------------------------------------------------------
  def self.range_order(range_type1,range_type2)
    return rannge_type1 if range_type1 == range_type2
    return :square if [range_type1,range_type2].include?(:square)
    return :square if [range_type1,range_type2].include?(:diagonal)
    return :default if [range_type1,range_type2].include?(:default)
    return :cross
  end

  #--------------------------------------------------------------------------
  # new method: directional_range_type? -> returns true if the area will change based on the source--target vector
  #--------------------------------------------------------------------------
  def self.directional_range_type?(type)
    return DIRECTIONAL_RANGE_TYPES.include?(type)
  end


  #--------------------------------------------------------------------------
  # new method: getTargetsList -> returns an array of targetable postitions by a spellRng when casting it from src
  #--------------------------------------------------------------------------
  #given a bat, a spellRng it aims to cast, its src postition,
  #returns a list of position that may be targeted by bat
  #this method is used by players and ais
  def self.getTargetsList(bat,src,spellRng)
    l = spellRng.range.genTargets(src)
    return l.select{|pos| tgt_valid?(bat,src,pos,spellRng.range)}
    #return l2.map{|pos| pos.coordinates}
  end

  #--------------------------------------------------------------------------
  # new method: getSourcesList -> returns an array of sources postitions that may target the tgt with the given spellRng
  #--------------------------------------------------------------------------
  #given a bat, a spellRng it aims to cast, and a tgt it aims to target,
  #returns a list of position that may be sources for bat
  #this method is used by ais
  def self.getSourcesList(bat,tgt,spellRng)
    l = spellRng.range.genTargets(tgt)
    return l.select{|pos| $game_map.valid?(pos.x,pos.y) && tgt_valid?(bat,pos,tgt,spellRng.range)}
    #return l2.map{|pos| pos.coordinates}
  end

  #--------------------------------------------------------------------------
  # new method: getArea -> returns an array of cells in the area of a spell cast on tgt from src
  #--------------------------------------------------------------------------
  def self.getArea(bat,src,tgt,spellRng)
    l = spellRng.area.genArea(src,tgt)
    return l.select{|pos| tgt_valid?(bat,tgt,pos,spellRng.area)}
  end

  #--------------------------------------------------------------------------
  # new method: tgt_valid? -> returns true if target in the map and not obstructed by obstacles when the spellrange requires it
  #--------------------------------------------------------------------------
  def self.tgt_valid?(bat,src,tgt,castRng)
    $game_map.valid?(tgt.x,tgt.y) && (!castRng.los? || $game_map.can_see?(bat, src, tgt))
  end

  #--------------------------------------------------------------------------
  # new method: crossed_range -> returns a list of crossed lines in one dimension
  # from s to t (s,t being integers as centers of cells in a single dimension)
  #--------------------------------------------------------------------------
  #s,t being in one dimension coordinate, returns the grid inbetween :
  #ex [1,10] returns 1.5,2.5...9.5
  #[5,2] returns 4.5,3.5,2.5
  def self.crossed_range(s,t)
    zrange = []
    if s != t
      sg = s < t ? 1 : -1
      while s != t
        zrange.push(s + sg*0.501) #should be 0.5, but I need round to work
        s += sg
      end
    end
    return zrange
  end

  #--------------------------------------------------------------------------
  # new method: delta_to_direction -> turn a dx,dy vector into a direction d in [1...9]
  # dx,dy in [-1,0,1]
  #--------------------------------------------------------------------------
  def self.delta_to_direction(dx,dy)
    return 1 + (1 + dx) + (1 - dy) * 3
  end

  #--------------------------------------------------------------------------
  # new method: direction_to_delta -> turn a direction (between 1 and 9) into a vector dx,dy
  #--------------------------------------------------------------------------
  #d is a value between 1 and 9 corresponding to the numpad
  #return a POS object (x,y) of (-1|0|1) values corresponding to the direction
  def self.direction_to_delta(d)
    d -= 1
    dx = (d % 3) - 1
    dy = 1 - (d / 3)
    return POS.new(dx,dy)
  end

  #--------------------------------------------------------------------------
  # new method: is_diagonal? -> asks if a direction d is a diagonal one
  #--------------------------------------------------------------------------
  #d is a value between 1 and 9 corresponding to the numpad
  #asks if d is diagonal (and assumes it's not the center)
  def self.is_diagonal?(d)
    return d % 2 == 1
  end

  #--------------------------------------------------------------------------
  # new method: diagonal_to_pair -> turn a diagonal direction d into two directions d1,d2
  #--------------------------------------------------------------------------
  def self.diagonal_to_pair(d)
    pos = TBS.direction_to_delta(d)
    d1 = TBS.delta_to_direction(pos.x,0)
    d2 = TBS.delta_to_direction(0,pos.y)
    return d1,d2
  end

  #--------------------------------------------------------------------------
  # new method: reverse_dir -> return the opposite direction
  #--------------------------------------------------------------------------
  def self.reverse_dir(d)
    return 10-d
  end

  #--------------------------------------------------------------------------
  # new method: dir_towards -> return a direction to look at from pos1 towards pos2
  #--------------------------------------------------------------------------
  def self.dir_towards(pos1,pos2)
    sx,sy = pos1.map_dist(pos2)
    return (sx > 0 ? 4 : 6) if sx.abs > sy.abs
    return (sy > 0 ? 8 : 2) if sy != 0
    return 0 #no change to the dir
  end

  #--------------------------------------------------------------------------
  # new method: crossed_positions -> return an array of crossed cells between a source and a target positions with a straight line
  #--------------------------------------------------------------------------
  #return a list of position crossed from source to target (will not contain the source pos but will contain the target)
  def self.crossed_positions(source,target)
    return crossed_positions_dir(source,target)[0]
  end

  #--------------------------------------------------------------------------
  # new method: crossed_positions_dir -> return an array of crossed cells between a source and a target positions with a straight line
  # Additionally returns a list of directions that are from where the cells are crossed by such line
  #--------------------------------------------------------------------------
  #return a pairs of list l,dirs
  #l = list of position crossed from source to target (will not contain the source pos but will contain the target)
  #d = direction (in rpgmaker way) showing by which angle the position is reached
  def self.crossed_positions_dir(source,target)
    l, dirs = [], []
    sx,sy = source.x, source.y
    tx,ty = target.x, target.y
    dx,dy = (tx - sx), (ty - sy)
    #value of the function y = f(x) = ax + b
    #then what matters is for x barrier in [sx,tx] there are ys that changes as integers
    #same for y
    return l, dirs if dx == 0 && dy == 0
    #intialize main directions for x and y axis
    lx = dx < 0 ? -1 : 1
    ly = dy < 0 ? -1 : 1
    #diagonal case
    if dx.abs() == dy.abs()
      d = TBS.delta_to_direction(lx,ly)
      while sx != tx
        sx += lx
        sy += ly
        l.push(POS.new(sx,sy))
        dirs.push(d)
      end
      return l, dirs
    end
    a = b = 0
    if dx == 0
      a = 100000000 #a big enough integer such that y never changes
      b = 0 #the value does not matter
    else
      a = dy.to_f()/dx.to_f()
      b = sy - a*sx
    end
    xrange = crossed_range(sx,tx)
    yrange = crossed_range(sy,ty)
    d = 5  #center direction
    ix = iy = 0 #index in xrange amd yrange
    x,y = sx,sy #previous positions
    while ix < xrange.size || iy < yrange.size
      x1, y1 = sx, sy #considered position
      if ix < xrange.size
        x1 = xrange[ix]
        y1 = a*x1 + b
        if iy < yrange.size #x and y must be compared
          y2 = yrange[iy]
          x2 = (y2 - b)/a
          #checks if x2 is closer to x than x1
          if (sx-x1).abs() > (sx-x2).abs()
            x1, y1 = x2, y2
            iy += 1
            d = TBS.delta_to_direction(0,ly)
            #d = dx > 0 ? 6 : 4
          else
            ix += 1
            d = TBS.delta_to_direction(lx,0)
          end

        else #only x matters
          ix += 1
          d = TBS.delta_to_direction(lx,0)
        end
      else #only y matters
        y1 = yrange[iy]
        x1 = (y1 - b)/a
        x1 = sx if dx == 0 #patch to deal with single axis
        iy += 1
        d = TBS.delta_to_direction(0,ly)
      end

      x1 = x1.round()
      y1 = y1.round()
      if x != x1 || y != y1
        pos = POS.new(x1,y1) #only an integer matters
        x,y = x1,y1
        l.push(pos)
        dirs.push(d)
      end
    end #while
    return l, dirs
  end #crossed_positions
end #TBS


#============================================================================
# CastRange -> stores 4 values min_range, max_range, line_of_sight, range_type
# CastRange is used to generate range of spells and area of effects
#============================================================================
#spell area is the same as spell range
#minrg/maxrg : the distance from src, the second one is always higher than the first one
#sight : true/false, asks whether seeing the target is required to cast the spell
#rg_type : the type of area of effect
class CastRange
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :min_range
  attr_reader :max_range
  attr_reader :line_of_sight
  attr_reader :range_type
  def initialize(minrg = 0, maxrg = 0, sight = true, rg_type = :default)
    @min_range = minrg#[minrg,0].max
    @max_range = maxrg#[maxrg,@min_range].max #shouldn't have a lower max_range
    @line_of_sight = sight
    if TBS::RANGE_TYPES.include? rg_type
      @range_type = rg_type
    else
      @range_type = :default
    end
  end
  #--------------------------------------------------------------------------
  # add_range and add_min_range are used to updated the values of min_range and max_range
  #--------------------------------------------------------------------------
  def add_range(maxrg)
    @max_range += maxrg #= [@max_range + maxrg,@min_range].max
  end
  def add_min_range(minrg)
    @min_range += minrg #= [@min_range + minrg,0].max
  end
  #--------------------------------------------------------------------------
  # _maxRange and _minRange the actual values used in range/area calculations
  # there must be at least one possible target, so 0 <= _minRange <= _maxRange
  #--------------------------------------------------------------------------
  def _maxRange
    return [@max_range, _minRange].max
  end
  def _minRange
    return [@min_range,0].max
  end
  #--------------------------------------------------------------------------
  # set_sight and set_type may be used to change the last two attributes
  #--------------------------------------------------------------------------
  def set_sight(newsight)
    @line_of_sight = newsight
  end
  def set_type(new_type)
    return unless RANGE_TYPES.include? new_type
    @range_type = new_type
  end
  #--------------------------------------------------------------------------
  # los? asks if the CastRange requires a Line Of Sight
  #--------------------------------------------------------------------------
  def los?
    return @line_of_sight
  end

  #--------------------------------------------------------------------------
  # genTargets -> returns an array of cells that are inside the range of a spell cast from src
  #--------------------------------------------------------------------------
  #given src as POS, return a list of reachable position
  def genTargets(src)
    l = [] #the list to return
    minRange, maxRange = _minRange, _maxRange
    l += [src] if minRange == 0
    x = src.x
    y = src.y
    #i >= 1
    m_range = [minRange,1].max
    case @range_type
    when :square
      for i in m_range...maxRange+1
        for j in -i...(i-1)+1
          l += [POS.new(x+j,y-i),POS.new(x+i,y+j),POS.new(x-j,y+i),POS.new(x-i,y-j)]
        end
      end
    when  :cross, :line, :perpendicular
      for i in m_range...maxRange+1
        l += [POS.new(x,y+i),POS.new(x,y-i),POS.new(x-i,y),POS.new(x+i,y)]
      end
    when :diagonal
      for i in m_range...maxRange+1
        l += [POS.new(x+i,y+i),POS.new(x+i,y-i),POS.new(x-i,y+i),POS.new(x-i,y-i)]
      end
    else #default
      for i in m_range...maxRange+1
        for j in 0...i-1+1
          l += [POS.new(x-i+j,y+j),POS.new(x+j,y+i-j),POS.new(x+i-j,y-j),POS.new(x-j,y-i+j)]
        end
      end
    end
    return l
  end

  #--------------------------------------------------------------------------
  # genArea -> returns an array of cells that are inside the area of a spell cast on tgt from src
  #--------------------------------------------------------------------------
  #given an src (caster) and tgt POS, return a list of cells that are touched by an area
  def genArea(src,tgt)
    return genTargets(tgt) unless [:perpendicular,:line].include?(@range_type)
    minRange, maxRange = _minRange, _maxRange
    l = []
    vec = tgt -src
    x,y = vec.signs
    case @range_type
    when :line
      for i in minRange...maxRange+1
        l.push(tgt + POS.new(i*x,i*y))
      end
    when :perpendicular
      l.push(tgt) if minRange == 0
      m_range = [minRange,1].max
      for i in m_range...maxRange+1
        l += [tgt + POS.new(-i*y,i*x), tgt + POS.new(i*y,-i*x)]
      end
    end
    return l
    #use then l.select to filter the pos of interest
  end

  #--------------------------------------------------------------------------
  # pos_in_range? -> returns true if tgt is in range when the spell is cast from src
  #--------------------------------------------------------------------------
  #src, tgt are POS objects
  #asks if tgt is in range from src
  def pos_in_range?(src,tgt)
    minRange, maxRange = _minRange, _maxRange
    dist = src.local_dist(tgt) #return POS(DELTA_X,DELTA_Y) in absolute values
    return false if [dist.x,dist.y].min > maxRange
    case @range_type
    when :square
      return [dist.x,dist.y].max >= minRange
    when  :line, :perpendicular, :cross
      return ([dist.x,dist.y].max >= minRange && [dist.x,dist.y].min == 0)
    when :diagonal
      return ([dist.x,dist.y].max >= minRange && dist.x == dist.y)
    else #default
      return (dist.x + dist.y >= minRange && dist.x + dist.y <= maxRange)
    end
    return false
  end

  #--------------------------------------------------------------------------
  # pos_in_area? -> returns true if tgt is in area when the spell is cast from origin to src
  #--------------------------------------------------------------------------
  #origin, src, tgt are POS objects
  #origin is the position of the caster
  #src is the position of the spell (target of the range)
  #asks if tgt is in arange of the area on src
  def pos_in_area?(origin,src,tgt)
    return pos_in_range?(src,tgt) unless [:perpendicular,:line].include?(@range_type)
    minRange, maxRange = _minRange, _maxRange
    dist = src.local_dist(tgt) #return POS(DELTA_X,DELTA_Y) in absolute values
    return false if [dist.x,dist.y].min > maxRange
    #return false if [dist.x,dist.y].max < @min_range #none is close enough
    vec1 = src - origin
    x,y = vec1.signs
    return false if x == 0 && y == 0 #cannot deal with no direction
    case @range_type
    when :line
      vec2 = tgt - src
      return false if x != 0 && (vec2.x * x < minRange || dist.x > maxRange)
      return false if x == 0 && vec2.y != 0
      return false if y != 0 && (vec2.y * y < minRange || dist.y > maxRange)
      return false if y == 0 && vec2.x != 0
      return true
    when :perpendicular
      return false if y != 0 && (dist.x < minRange || dist.x > maxRange)
      return false if x != 0 && (dist.y < minRange  || dist.y > maxRange)
      return true
    end
    return false
  end

  #--------------------------------------------------------------------------
  # largest_range -> returns a castRange containing both input castRange
  #--------------------------------------------------------------------------
  #for ai computation
  def largest_range(other)
    return CastRange.new([@min_range,other.min_range].min,[@max_range,other.max_range].max, (@sight && other.sight), TBS.range_order(@range_type, other.range_type))
  end
end #CastRange


#============================================================================
# SpellRange -> stores 2 CastRange, one for the range of the spell, the other
# for the area of effect.
#============================================================================
#each spell/item contains a spellrange, it represents the range of the spell and its area of effect
class SpellRange
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :range
  attr_accessor :area
  #--------------------------------------------------------------------------
  # initialize -> takes two arrays of length 4 containing the data of the range and the area
  #--------------------------------------------------------------------------
  def initialize(range_table=TBS::DEFAULT_RANGE, area_table=TBS::DEFAULT_RANGE)
    @range = CastRange.new(range_table[0],range_table[1],range_table[2],range_table[3])
    @area = CastRange.new(area_table[0],area_table[1],area_table[2],area_table[3])
  end

  #--------------------------------------------------------------------------
  # new method: pos_in_range? return true if the position is in the range of the spellRng when casting it from src
  #--------------------------------------------------------------------------
  def pos_in_range?(src,tgt)
    return @range.pos_in_range?(src,tgt)
  end

  #--------------------------------------------------------------------------
  # new method: pos_in_area? return true if the position is in the area of the spellRng when casting it on tgt from src
  #--------------------------------------------------------------------------
  def pos_in_area?(origin,src,tgt)
    return @area.pos_in_area?(origin,src,tgt)
  end
end #SpellRange

#==============================================================================
#
# TBS TBS_Path
#
#==============================================================================

#============================================================================
# ** TBS_Path
#------------------------------------------------------------------------------
#  This class update the path when adding directions,
#  it does not handle whether tiles are passable but only their cost, it is used
#  to then display the path when using the move command
#============================================================================
class TBS_Path
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :route
  attr_reader :cost
  #--------------------------------------------------------------------------
  # initialize -> empty route
  #--------------------------------------------------------------------------
  def initialize
    @bat = nil
    @m_r = nil
    @first_dir = 2
    @route = []
    @cost = 0
  end
  #--------------------------------------------------------------------------
  # set_route -> given a route (array of directions) and its cost for a battler,
  # computes a TBS_Path from it, does not check the cost!
  #--------------------------------------------------------------------------
  def set_route(bat,r,c)
    @bat = bat
    @m_r = MoveRule.new(bat.move_rule_id)
    @first_dir = bat.char.direction
    #@src = Pos.new(bat.char.x,bat.char.y)
    @route = []
    for d in r
      @route.push(d)
    end
    @cost = c
  end

  #--------------------------------------------------------------------------
  # dest -> returns the dest reached by the route from bat.pos
  #--------------------------------------------------------------------------
  def dest(index = @route.size)
    pos = @bat.pos
    for i in 0...index
      d = @route[i]
      pos += TBS.direction_to_delta(d) #unless i == 0 #avoid shifting with the first dir
    end
    return pos
  end

  #--------------------------------------------------------------------------
  # pop_dir -> removes the last direction and updates the cost
  #--------------------------------------------------------------------------
  def pop_dir
    p = dest
    dir = @route.pop
    @cost -= $game_map.cost_move(@m_r,p.x,p.y,dir)
  end

  #--------------------------------------------------------------------------
  # push_dir -> push the given direction and updates the cost
  #--------------------------------------------------------------------------
  def push_dir(dir)
    @route.push(dir)
    p = dest
    @cost += $game_map.cost_move(@m_r,p.x,p.y,dir)
  end

  #--------------------------------------------------------------------------
  # add_dir -> extends the path following the direction d, if a cycle is created,
  # the path is shortened until no cycle remains but the destination stays the same as the addition of i
  #--------------------------------------------------------------------------
  #d a direction in [2,4,6,8]
  def add_dir(d)
    p = TBS.direction_to_delta(d)
    i = 0
    b_cycle = false
    #find if there is a cycle
    j = @route.size-1
    while j >= 0 && !b_cycle
      d2 = @route[j]
      i += 1
      j -= 1
      p += TBS.direction_to_delta(d2)
      b_cycle = (p.x == 0 && p.y == 0) #loop ends when a cycle is met
    end
    if b_cycle
      for _ in 0...i
        pop_dir
      end
    else
      push_dir(d)
    end
  end

  #--------------------------------------------------------------------------
  # char_list -> generates a list of Game_TBS_Step_Character for display purpose
  #--------------------------------------------------------------------------
  def char_list
    pos = @bat.pos#Pos.new(bat.char.x,bat.char.y)
    l = []
    road = [@first_dir] + @route
    for i in 0...road.size#-1
      d1 = road[i]
      d2 = i < road.size-1 ? road[i+1] : nil
      c = Game_TBS_Step_Character.new(d1,d2)
      pos += TBS.direction_to_delta(d1) unless i == 0 #avoid shifting with the first dir
      c.moveto(pos.x,pos.y)
      l.push(c)
    end
    return l
  end
end #TBS_Path

#==============================================================================
# ** Game_TBS_Step_Character
#------------------------------------------------------------------------------
#  This class handles the path displayed when the player tries to build a path
#==============================================================================

class Game_TBS_Step_Character < Game_Character
  #--------------------------------------------------------------------------
  # override method: initialize -> calculates which part of the character file take
  #--------------------------------------------------------------------------
  def initialize(dir,nextdir)
    super()
    set_graphic(TBS::FILENAME::PATH_CHAR_NAME,0)
    @direction = dir
    @original_pattern = 0
    @priority_type = 0
    if nextdir#not nextdir.nil?
      #straight line
      if ([2,8].include?(dir) && [2,8].include?(nextdir)) || ([4,6].include?(dir) && [4,6].include?(nextdir))
        @original_pattern = 1
      else
        @original_pattern = 2
        angles = [[[6,8],[2,4]],[[4,8],[2,6]],[[6,2],[8,4]],[[4,2],[8,6]]]
        i = 2
        for a in angles
          vec = [dir, nextdir]
          if a[0] == vec || a[1] == vec
            @direction = i
            break
          end
          i += 2
        end
      end
    end
    @pattern = @original_pattern #pattern is a constant
  end

  #--------------------------------------------------------------------------
  # override method: straighten -> do not change the pattern
  #--------------------------------------------------------------------------
  def straighten
    super
    @pattern = @original_pattern
  end
end

#==============================================================================
#
# TBS Game_Map
#
#==============================================================================

#============================================================================
# Game_Map
#============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :retrieve_map #controls whether the saved events should be loaded

  #-------------------------------------------------------------------------
  # alias method: setup_events -> will replace the events if @retrieve_map
  #-------------------------------------------------------------------------
  alias :tbs_game_map_setup_events :setup_events
  def setup_events
    @retrieve_map ? setup_old_events : tbs_game_map_setup_events
  end

  #-------------------------------------------------------------------------
  # new method: setup_old_events -> replace the events by the saved ones
  #-------------------------------------------------------------------------
  def setup_old_events
    @events = @old_events.dup
    @common_events = @old_common_events.dup
    @old_events = @old_common_events = @retrieve_map = nil
    refresh_tile_events
  end

  #-------------------------------------------------------------------------
  # new method: save_map_data -> saves the events from the previous map before loading a battle map
  #-------------------------------------------------------------------------
  def save_map_data
    @old_events = @events.dup
    @old_common_events = @common_events.dup
  end

  #-------------------------------------------------------------------------
  # alias method: initialize -> refresh the @extras and @battle_evemts
  #-------------------------------------------------------------------------
  #alias tbs_map_init initialize
  #def initialize()
  #  @extras = {}
  #  @battle_events = {}
  #  tbs_map_init
  #end

  #-------------------------------------------------------------------------
  # alias method: setup -> refresh the @extras and @battle_events
  #-------------------------------------------------------------------------
  alias tbs_map_setup setup
  def setup(map_id)
    @extras = {}
    @battle_events = {}
    tbs_map_setup(map_id)
  end

  #-------------------------------------------------------------------------
  # new method: tbs_setup -> setup the map, reads it events and return an array of data
  # [places_loc, extra_battlers, obstacles, enemy_loc, actor_loc]
  #-------------------------------------------------------------------------
  def tbs_setup(map_id)
    setup(map_id)
    return setup_tbs_events
  end

  #-------------------------------------------------------------------------
  # new method: update_tbs -> updates only the battlers
  #-------------------------------------------------------------------------
  def update_tbs(main = false)
    update_battlers
  end

  #-------------------------------------------------------------------------
  # new method: update_battlers -> updates only the battlers
  #-------------------------------------------------------------------------
  def update_battlers
    battlers = SceneManager.scene.tactics_all
    battlers.each {|battler| battler.update}
  end

  #-------------------------------------------------------------------------
  # alias method: update_events -> only updates visible events (events part of tbs and extra)
  #-------------------------------------------------------------------------
  alias tbs_update_events update_events
  def update_events
    return tbs_update_events unless SceneManager.scene_is?(Scene_TBS_Battle)
    tbs_events.each {|event| event.update }
    @common_events.each {|event| event.update }
  end

  #-------------------------------------------------------------------------
  # new method: setup_tbs_events -> reads all events and store them if they are relevant for TBS, the rest will be hidden
  #-------------------------------------------------------------------------
  TBS_event_names = TBS::EVENT_NAMES::LIST
  TBS_comments_names = TBS::EVENT_COMMENTS::LIST_FIX + TBS::EVENT_COMMENTS::LIST_PLACE
  def setup_tbs_events
    obstacles = []
    enemy_loc = {}
    actor_loc = {}
    #neu_loc = {}
    extra_battlers = []
    places_loc = []
    for i in 0...TBS::TEAMS.nb_teams
      places_loc.push([])
    end
    for j in @events.keys
      event = @events[j]
      if event.name #!event.name.nil? #read the event name
        for i in 0...TBS_event_names.size
          type = TBS_event_names[i]
          if event.name.downcase.include?(type)
            case i
            when 0 #extra
              @extras[j] = event
            when 1 #battle_events
              #$game_system.battle_events
              @battle_events[j] = event
            end
          end
        end
      end
      #now, check the comments
      next if event.list == nil
      for i in 0...event.list.size
        if event.list[i].code == 108 #comment
          txt = event.list[i].parameters[0] #"LIGHT 1" & co
          res = txt.split
          comment_id = TBS_comments_names.index(res[0])
          next if comment_id.nil?
          id = team_id = nil
          id = res[1].to_i unless res[1].nil?
          team_id = res[2].to_i unless res[2].nil?
          case comment_id
          when 0 #obstacle
            bat = Game_Enemy.new(0,id)
            bat.moveto(event.x, event.y)
            obstacles.push(bat)
          when 1 #actor
            actor_loc[id] = event
          when 2 #enemy
            enemy_loc[id] = event
          when 3 #spawn_actor
            bat = Game_Actor.new(id)
            bat.team = team_id
            bat.moveto(event.x, event.y)
            extra_battlers.push(bat)
          when 4 #spawn_enemy
            bat = Game_Enemy.new(0,id)
            bat.team = team_id
            bat.moveto(event.x, event.y)
            extra_battlers.push(bat)
          when 5 #enemy_place
            places_loc[TBS::TEAMS::TEAM_ENEMIES].push([event.x, event.y])
          when 6 #party_place
            places_loc[TBS::TEAMS::TEAM_ACTORS].push([event.x, event.y])
          when 7 #team_place
            places_loc[id].push([event.x, event.y])
          end
          #a comment was used for tbs, no need to check further comments,
          #this guarantees the unicity of position of each element of the tables,
          #so this also avoid computation checking :3
          break
        end
      end
    end
    #list of lists of pos for each team,
    #list of battlers already placed, need to check them and add them at the right place
    #list of obstacles already placed, need to check them too
    #list of positions for specific enemies and actors
    return [places_loc, extra_battlers, obstacles, enemy_loc, actor_loc]
  end

  #-------------------------------------------------------------------------
  # new method: tbs_events -> return all the tbs events and extra to create sprite_event
  #-------------------------------------------------------------------------
  def tbs_events
    #$game_system.battle_events.values
    return @battle_events.values + @extras.values
  end

  #-------------------------------------------------------------------------
  # new method: battle_event_at? -> is there a battle_event at x,y?
  #-------------------------------------------------------------------------
  def battle_event_at?(x,y)
    for event in @battle_events.values
      return event if event.x == x && event.y == y
    end
    return nil
  end

  #-------------------------------------------------------------------------
  # new method: battle_events_at -> return an array of battle_events at x,y
  #-------------------------------------------------------------------------
  def battle_events_at(x,y)
    @battle_events.values.select{|e| e.x == x && e.y == y}
  end

  #-------------------------------------------------------------------------
  # new method: battle_events_in -> return an array of battle_events in the range posList
  #-------------------------------------------------------------------------
  def battle_events_in(posList)
    @battle_events.values.select{|e| in_range?(posList,e.x,e.y)}
  end

  #-------------------------------------------------------------------------
  # new method: in_range? -> is x,y inside the posList?
  #-------------------------------------------------------------------------
  def in_range?(posList, x1 = x,y1 = y)
    return posList.include?([x1, y1])
  end

  #--------------------------------------------------------------------------
  # new method: targeted_battlers ->  returns all battlers inside the posList
  #--------------------------------------------------------------------------
  def targeted_battlers(posList)
    return SceneManager.scene.tactics_all.select{|bat| in_range?(posList,bat.pos.x,bat.pos.y)}
  end

  #--------------------------------------------------------------------------
  # new method: occupied_by? ->  return a battler that occupies the x,y position, nil otherwise
  #--------------------------------------------------------------------------
  def occupied_by?(x, y)
    return nil unless SceneManager.scene_is?(Scene_TBS_Battle)
    return SceneManager.scene.tactics_all.find{|battler| battler.pos.x == x && battler.pos.y == y}
    #for battler in SceneManager.scene.tactics_all
    #  return battler if battler.pos.x == x && battler.pos.y == y
    #end
    #return nil #not occupied?
  end

  #--------------------------------------------------------------------------
  # new method: cost_move ->  get cost of the move to x,y given a MoveRule object
  #--------------------------------------------------------------------------
  def cost_move(move_rule, x,y,d)
    return move_rule.get_cost_move(terrain_tag(x, y))
  end

  #--------------------------------------------------------------------------
  # new method: obstacle_dir? return true if the cell pos blocks the view from prev_pos and direction d
  #--------------------------------------------------------------------------
  #define if the current position is an obstacle for spells and ranged attacks
  def obstacle_dir?(prev_pos,pos,d)
    tag = terrain_tag(pos.x,pos.y)
    tag2 = terrain_tag(prev_pos.x,prev_pos.y)
    ignore_prev_pos = TBS::REVEAL_TERRAIN_TAG.include?(tag2)
    ignore_pos = TBS::REVEAL_TERRAIN_TAG.include?(tag)
    return false if ignore_pos #TBS::REVEAL_TERRAIN_TAG.include?(tag)
    return true if TBS::HIDE_TERRAIN_TAG.include?(tag)
    return false unless TBS::DEFAULT_OBSTACLES_HIDE
    if TBS.is_diagonal?(d)
      d1,d2 = TBS.diagonal_to_pair(d)
      return true unless ignore_prev_pos || (passable?(prev_pos.x, prev_pos.y, d1) && passable?(prev_pos.x, prev_pos.y, d2))
      d1,d2 = TBS.diagonal_to_pair(TBS.reverse_dir(d))
      return true unless ignore_pos || (passable?(pos.x, pos.y, d1) && passable?(pos.x, pos.y, d2))
    else
      return true unless (ignore_prev_pos || passable?(prev_pos.x, prev_pos.y, d)) && (ignore_pos || passable?(pos.x, pos.y, TBS.reverse_dir(d)))
    end
    return false
  end

  #--------------------------------------------------------------------------
  # new method: can_see? return true if bat from source can see target
  #--------------------------------------------------------------------------
  #asks if source can see target (ie if I can launch something at it with enough range)
  def can_see?(bat,source,target)
    l,dirs = TBS.crossed_positions_dir(source,target)
    if l.size > 0
      l.pop #do not test the target element : so remove it
      l = [source] + l
    end
    #for pos in l
    for i in 1...l.size
      return false if obstacle_dir?(l[i-1],l[i],dirs[i-1])
      if TBS::BATTLER_HIDE
        bat2 = occupied_by?(l[i].x,l[i].y)
        return false unless (bat2.nil? || !bat2.hide_view?(bat))
      end
    end
    return true
  end
end #Game_Map

#==============================================================================
#
# TBS TBS_Cusor
#
#==============================================================================

#============================================================================
# TBS_Cursor -> Deals with cursor position during TBS
#============================================================================
class TBS_Cursor
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  #active determines if the cursor can me controlled
  #mode is a value in [:place,:select,:move,:attack,:skill,:item], it defines the cursor purpose
  attr_accessor :active, :mode, :controllable
  attr_accessor :menu_skill #boolean controlled by scene that will return to the actor menu when cancelling the cursor action, relevant for guard skill and future single menu skills
  #has_moved is used for informing the rest to update themselves
  #origin_bat is the selected battler by the cursor (except in :select mode)
  #battler is the current battler under the cursor, nil if the cell is empty
  #path is a TBS_Path for :move mode and :area an array of [x,y] for :item, :attack and :skill modes
  attr_reader :has_moved, :origin_bat, :battler, :path, :area
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    @active = false
    @pos = POS.new(0,0)
    @range = [] #list of x,y where the cursor may go, relevant for move situations
    @mode = nil                      #a value in [:place, :select, :move, :item, :skill, :attack]
    @battler = nil                   #battler under the cursor, nil if no such battler
    @has_moved = false               #update cursor data only if its position has changed during this update cycle
    @menu_skill = false              #boolean, set to true if the skill is an action from the menu, that way, when the cursor is canceled, it goes back to the menu
    @origin_bat = nil                #the battler that was selected (caster etc.)
    @path = TBS_Path.new             #path to track the route when selecting moving
    @route_data = {}
    @cost_data = {}
    @area = [] #skill, help_skill, used to display area
  end

  #--------------------------------------------------------------------------
  # locked_in_range? -> restricts the cursor movements to its range? useful for :move mode
  #--------------------------------------------------------------------------
  def locked_in_range?
    return @mode == :move
  end

  #--------------------------------------------------------------------------
  # x,y to get the cursor position
  #--------------------------------------------------------------------------
  def x; @pos.x; end
  def y; @pos.y; end

  #--------------------------------------------------------------------------
  # update -> when the cursor is active, it will respond to the keyboard arrows to move
  #--------------------------------------------------------------------------
  def update
    return false unless @active && @controllable #|| $game_troop.interpreter.running? #|| $game_map.interpreter.running?
    @has_moved = false
    nu_x, nu_y = x, y
    if Input.repeat?(Input::RIGHT)
        nu_x += 1
    elsif Input.repeat?(Input::LEFT)
        nu_x -= 1
    elsif Input.repeat?(Input::DOWN)
        nu_y += 1
    elsif Input.repeat?(Input::UP)
        nu_y -= 1
    end
    #check if moved and not moved outside the map
    if (nu_x != x || nu_y != y) && $game_map.valid?(nu_x, nu_y) && (!locked_in_range? || in_range?(@range,nu_x,nu_y))
      moveto( nu_x, nu_y)
      Sound.play_cursor
      return true
    end
    return false
  end

  #--------------------------------------------------------------------------
  # moveto -> moves the cursor to x,y
  #--------------------------------------------------------------------------
  def moveto(x,y)
    @has_moved = true
    dx,dy = x-@pos.x,y-@pos.y
    @pos.moveto(x,y)
    @battler = $game_map.occupied_by?(x,y)
    if @mode == :move
      if dx.abs + dy.abs == 1
        d = TBS.delta_to_direction(dx,dy)
        @path.add_dir(d)
        d_pos = [x,y]
        @path.set_route(@origin_bat,@route_data[d_pos],@cost_data[d_pos]) unless path_is_good
      else
        d_pos = [x,y]
        @path.set_route(@origin_bat,@route_data[d_pos],@cost_data[d_pos])
      end
    elsif requires_area?
      @area = cursor_in_range? ? @origin_bat.input.set_target(@pos) : []
    end
  end

  #-------------------------------------------------------------------------
  # in_range? - is the position inside the range posList?
  #-------------------------------------------------------------------------
  def in_range?(posList, x1 = x,y1 = y)
    return $game_map.in_range?(posList,x1,y1)
  end

  #--------------------------------------------------------------------------
  # cursor_in_range? -> is the cursor inside its own range?
  #--------------------------------------------------------------------------
  def cursor_in_range?
    return in_range?(@range,x,y)
  end

  #--------------------------------------------------------------------------
  # requires_area? -> does moving the cursor implies generating an area?
  #--------------------------------------------------------------------------
  def requires_area?
    return [:attack,:item,:skill].include?(@mode)
  end

  #--------------------------------------------------------------------------
  # at? -> is the cursor at pos2?
  #--------------------------------------------------------------------------
  #def at?(pos2)
  #  return @pos == pos2
  #end

  #--------------------------------------------------------------------------
  # set_move_data -> when setting the :move mode, storing the route and cost
  # values from bat.calc_pos_move will be used for computing a TBS_Path
  # range is the list of keys from route and cost (ie the cells that can be crossed)
  #--------------------------------------------------------------------------
  def set_move_data(bat, range, route, cost)
    select_bat(bat)
    @range = range
    @route_data = route
    @cost_data = cost
    bat_pos = [bat.char.x,bat.char.y]
    #begin
    @path.set_route(bat,route[bat_pos],cost[bat_pos])
    #rescue => e
    #  puts bat.name
    #  puts route
    #  puts bat_pos
    #  raise e
    #end
  end

  #--------------------------------------------------------------------------
  # range_mode -> for diaply purpose, returns either :attack, :help_skill or :skill
  # it will affect how the ranges and area are displayed
  #--------------------------------------------------------------------------
  def range_mode
    return nil unless requires_area?
    return @mode if @mode == :attack
    return @origin_bat.input.item.for_friend? ? :help_skill : :skill
  end

  #--------------------------------------------------------------------------
  # set_skill_data -> will load the battler and its range to the cursor
  #--------------------------------------------------------------------------
  #will refer to the bat with input...
  def set_skill_data(bat, range)
    select_bat(bat)
    @range = range
  end

  #--------------------------------------------------------------------------
  # path_is_good -> return true iff the path does not cost too much move points
  #--------------------------------------------------------------------------
  def path_is_good
    return @origin_bat.available_mov >= @path.cost
  end

  #--------------------------------------------------------------------------
  # select_bat -> sets the cursor's battlers to bat
  #--------------------------------------------------------------------------
  def select_bat(bat)
    @origin_bat = bat
  end

  #--------------------------------------------------------------------------
  # moveto_bat -> reaches the battler bat
  #--------------------------------------------------------------------------
  def moveto_bat(bat)
    moveto(bat.char.x,bat.char.y)
  end
end #TBS_Cusor

#==============================================================================
#
# TBS Direction_Cursor
#
#==============================================================================

#============================================================================
# Direction_Cursor -> This is the  WAIT DIRECTION image that appears over
# battlers at the end of their turn
#============================================================================
class Direction_Cursor < Sprite_Base
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :battler
  attr_reader :initial_dir
  attr_accessor :active

  #----------------------------------------------------------------------------
  # override method: initialize
  #----------------------------------------------------------------------------
  def initialize(viewport, battler)
    super(viewport)
    @battler = battler
    @initial_dir = battler.char.direction
    @current_dir = @initial_dir
    @active = true
    create_bitmap
    self.ox = self.bitmap.width / 2
    self.oy = self.bitmap.height
    #update_bitmap
  end

  #----------------------------------------------------------------------------
  # new method: moveto
  #----------------------------------------------------------------------------
  def moveto(x, y)
    @map_x = x % $game_map.width
    @map_y = y % $game_map.height
    @real_x = @map_x
    @real_y = @map_y
  end

  #----------------------------------------------------------------------------
  # override method: update
  #----------------------------------------------------------------------------
  def update
    super
    return unless active
    newDir = 0
    if Input.trigger?(Input::DOWN)
      newDir = 2
    elsif Input.trigger?(Input::LEFT)
      newDir = 4
    elsif Input.trigger?(Input::RIGHT)
      newDir = 6
    elsif Input.trigger?(Input::UP)
      newDir = 8
    else
      newDir = @current_dir
    end
    if @current_dir != newDir
      @current_dir = newDir
      Sound.play_cursor
      @battler.char.set_direction(@current_dir)
    end
    moveto(@battler.char.x, @battler.char.y)
    update_bitmap
    self.x = @battler.screen_x
    self.y = @battler.screen_y - 40 + 16* (1-1)#unit_size -1
    self.z = @battler.screen_z + 1
  end

  #----------------------------------------------------------------------------
  # new method: on_cancel -> the battler goes back to its original direction
  #----------------------------------------------------------------------------
  def on_cancel
    @battler.char.set_direction(@initial_dir)
  end

  #----------------------------------------------------------------------------
  # override method: dispose
  #----------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #----------------------------------------------------------------------------
  # new method: create_bitmap
  #----------------------------------------------------------------------------
  def create_bitmap
    @direction = 0
    update_bitmap
  end
  #----------------------------------------------------------------------------
  # new method: update_bitmap
  #----------------------------------------------------------------------------
  def update_bitmap
    if @direction != @battler.char.direction
      @direction = @battler.char.direction
      self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
      self.bitmap = Cache.picture(sprintf(TBS::FILENAME::DIRECTION_PICTURES, @direction))
    end
  end
end #Direction_Cursor

#==============================================================================
#
# TBS Game_Action
#
#==============================================================================

#Target mode:
#No one : can have no battler targeted, will run the skill with the targeted position in mind
#may also have targeted battlers
#1-all allies, 1-all enemies -> same behaviour no matter 1 or all | for ai will help to chose the right target
#k-random enemies -> take k-random targets in area
#1-all dead allies -> same behaviour as non-dead but restricted to dead units
#user -> same as 1-all allies, you should run with range (0,0) instead

#targeting

#============================================================================
# Game_BaseItem
#============================================================================
class Game_BaseItem
  attr_reader :item_id #public access to item_id
end #Game_BaseItem

#============================================================================
# Game_Action -> will now have methods specific to tbs
#============================================================================
class Game_Action
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :tgt_pos #an x,y cell refering to the target of the action

  #--------------------------------------------------------------------------
  # alias method: set_skill -> now loads some tgt restriction properties for tbs
  #--------------------------------------------------------------------------
  alias tbs_ga_set_skill set_skill
  def set_skill(skill_id)
    ret = tbs_ga_set_skill(skill_id)
    @tgt_property = get_tgt_property #refers to : is the cell empty etc. or other cosntraints
    ret
  end

  #--------------------------------------------------------------------------
  # alias method: set_item -> now loads some tgt restriction properties for tbs
  #--------------------------------------------------------------------------
  alias tbs_ga_set_item set_item
  def set_item(item_id)
    ret = tbs_ga_set_item(item_id)
    @tgt_property = get_tgt_property #refers to : is the cell empty etc. or other cosntraints
    ret
  end

  #--------------------------------------------------------------------------
  # alias method: clear -> resets the new attributes
  #--------------------------------------------------------------------------
  alias tbs_ga_clear clear
  def clear
    tbs_ga_clear
    @tgt_pos = [0,0]
    @tgt_area = [] #the cells selected
    @tgt_property = nil
  end


  #--------------------------------------------------------------------------
  # new method: set_target -> pos becomes the target of the action,
  # returns the area of effect when pos is the target
  #--------------------------------------------------------------------------
  def set_target(pos)
    @tgt_pos = [pos[0],pos[1]]
    type = @item.is_item? ? :item : :skill
    spellRng = subject.getRange(@item.item_id,type)
    @tgt_area = subject.genArea(POS.new(pos[0],pos[1]),spellRng)
    return @tgt_area
  end

  #--------------------------------------------------------------------------
  # new method: get_targeted_rel -> return the list of relationships (TBS::FRIENDLY, TBS::NEUTRAL, TBS::ENEMY)
  # that will be affected by the action
  #--------------------------------------------------------------------------
  def get_targeted_rel
    return [] if @item.nil?
    if @item.is_item?
      return TBS.item_targeting_rel(@item.item_id)
    end
    return TBS.skill_targeting_rel(@item.item_id)
  end

  #--------------------------------------------------------------------------
  # new method: tbs_make_target_pos -> return the list of positions that can be targets
  #--------------------------------------------------------------------------
  def tbs_make_target_pos
    type = @item.is_item? ? :item : :skill
    spellRng = subject.getRange(@item.item_id,type)
    posList = subject.genTgt(spellRng)
    targets = {}
    for p in posList
      tgt = POS.new(p[0],p[1])
      targets[p] = tbs_make_targets(subject.genArea(tgt,spellRng))
    end
    return targets
  end

  #--------------------------------------------------------------------------
  # new method: tbs_make_targets -> return the list of battlers affected by the area (with unicity)
  #--------------------------------------------------------------------------
  def tbs_make_targets(area = @tgt_area)
    targets = $game_map.targeted_battlers(area)
    rel = get_targeted_rel
    targets = targets.select  {|target| rel.include?(subject.friend_status(target))}
    targets = targets.select  {|target| target.dead? == item.for_dead_friend?}
    return targets.compact
  end

  #--------------------------------------------------------------------------
  # new method: tbs_make_final_targets -> return the final list of battlers
  # affected by the area, like make_targets, will take into account randomness
  # and attack times, use it to g
  #--------------------------------------------------------------------------
  def tbs_make_final_targets(area = @tgt_area)
    targets = tbs_make_targets(area)
    targets = Array.new(item.number_of_targets) { random_target(targets) } if item.for_random?
    num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
    targets *= num
    return targets
  end

  #--------------------------------------------------------------------------
  # new method: property_valid? -> return true iff the cell follows specific tbs properties
  # if false, then the target is not valid for tbs casting
  #--------------------------------------------------------------------------
  def property_valid?(property_str)
    eval(property_str)
  end

  #--------------------------------------------------------------------------
  # new method: tgt_empty? -> checks if the targeted cell does not contain a battler or a blocking event
  #--------------------------------------------------------------------------
  def tgt_empty?
    return !tgt_filled?
  end

  #--------------------------------------------------------------------------
  # new method: tgt_filled? -> checks if the targeted cell contains a battler or a blocking event
  #--------------------------------------------------------------------------
  def tgt_filled?
    return $game_map.occupied_by?(@tgt_pos[0], @tgt_pos[1]) || tgt_blocking_event?
  end

  #--------------------------------------------------------------------------
  # new method: tgt_blocking_event? -> is a blocking event
  #--------------------------------------------------------------------------
  def tgt_blocking_event?
    mr = MoveRule.new(@subject.move_rule_id)
    return $game_map.battle_events_at(@tgt_pos[0], @tgt_pos[1]).any?{|ev| !@subject.can_cross_ev?(mr,5,ev)}
  end

  #--------------------------------------------------------------------------
  # new method: tgt_ground? -> checks if the targeted cell is ground passable
  #--------------------------------------------------------------------------
  def tgt_ground?
    return [2,4,6,8].any?{|d| $game_map.passable?(@tgt_pos[0], @tgt_pos[1],d)}
  end

  #--------------------------------------------------------------------------
  # new method: tgt_water? -> checks if the targeted cell is water tile (or ship passable)
  #--------------------------------------------------------------------------
  def tgt_water?
    return $game_map.ship_passable?(@tgt_pos[0], @tgt_pos[1])
  end

  #--------------------------------------------------------------------------
  # new method: event? -> to be overwritten by TBS Event Triggers for property checking
  #--------------------------------------------------------------------------
  def event?; false; end

  #--------------------------------------------------------------------------
  # new method: get_tgt_property -> fetch the tgt_property from the database (notetags)
  #--------------------------------------------------------------------------
  def get_tgt_property
    return nil if @item.nil?
    return TBS.item_targeting_property(@item.item_id) if @item.is_item?
    return TBS.skill_targeting_property(@item.item_id)
  end

  #--------------------------------------------------------------------------
  # new method: item_for_none? -> return true if the item is meant for none
  #--------------------------------------------------------------------------
  def item_for_none?
    !(item.for_friend? || item.for_opponent?)
  end

  #--------------------------------------------------------------------------
  # new method: item_for_all? -> return true if the item is meant for all battlers
  #--------------------------------------------------------------------------
  def item_for_all?
    return item.for_all?
  end

  #--------------------------------------------------------------------------
  # new method: tbs_tgt_valid? -> checks that the curent action is valid in regard to TBS
  #--------------------------------------------------------------------------
  #does not check that the target is in range! this shouuld be done outside,
  #it leaves freedom for forced actions.
  def tbs_tgt_valid?
    @forcing || (property_valid?(@tgt_property) && (item_for_none? || tbs_make_targets.size > 0))
  end

  #--------------------------------------------------------------------------
  # new method: random_target -> given an already refined set of targets, pick a random one based on tgr
  #--------------------------------------------------------------------------
  def random_target(targets)
    tgr_sum = targets.inject(0) {|r, member| r + member.tgr }
    tgr_rand = rand * tgr_sum
    targets.each do |member|
      tgr_rand -= member.tgr
      return member if tgr_rand < 0
    end
    targets[0]
  end

  #--------------------------------------------------------------------------
  # new method: call_additional_tbs_effects -> call other effects for fututre compaitiblity
  #--------------------------------------------------------------------------
  def call_additional_tbs_effects; end
end #Game_Action

#==============================================================================
# TBS Part 3: Sprites
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Deals with sprite objects
#==============================================================================

#==============================================================================
#
# TBS Sprite_Character_TBS
#
#==============================================================================

#============================================================================
# Bitmap -> adds draw_circle for Sprite_Team
#============================================================================
class Bitmap
  #--------------------------------------------------------------------------
  # new method: draw_circle -> midpoint circle algorithm to draw a circle of color c
  #--------------------------------------------------------------------------
  def draw_circle(radius, x0, y0, c)
    x = radius
    y = 0
    radiusError = 1 - x
    while x >= y
      set_pixel( x + x0,  y + y0, c)
      set_pixel( y + x0,  x + y0, c)
      set_pixel(-x + x0,  y + y0, c)
      set_pixel(-y + x0,  x + y0, c)
      set_pixel(-x + x0, -y + y0, c)
      set_pixel(-y + x0, -x + y0, c)
      set_pixel( x + x0, -y + y0, c)
      set_pixel( y + x0, -x + y0, c)
      y += 1
      if radiusError < 0
        radiusError += 2 * y + 1
      else
        x -= 1
        radiusError += 2 *(y-x) + 1
      end
    end
  end
end #Bitmap

#==============================================================================
# Sprite_Character_TBS -> Replaces Sprite_Battler for TBS, it directly copies
# everything from Sprite_Battler while inheriting the rest from Sprite_Character
#==============================================================================
class Sprite_Character_TBS < Sprite_Character
  #--------------------------------------------------------------------------
  # class variables
  #--------------------------------------------------------------------------
  #available_characters is used to Cache which characters exist or not for state display
  @@available_characters = Hash.new { |h, k|
    begin
      Cache.character(k)
      h[k] = true
    rescue Errno::ENOENT
      h[k] = false
    end
  }
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :battler
  attr_accessor :to_dispose
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(viewport, battler = nil)
    @battler = battler
    @battler_visible = false
    @to_dispose = false

    @bat_state = @new_bat_state = :default
    @fixed_index = nil

    @effect_type = nil
    @effect_duration = 0
    @sprite_team = Sprite_Team.new(viewport, battler) unless battler.obstacle? && !TBS::TEAMS::CIRCLE_FOR_OBSTACLES
    super(viewport,battler.char)
    #@displayed_name = @character_name
    @sprite_active = Sprite_Active.new(viewport,battler) #must be after the char sprite
    @sprite_turn = Sprite_Turn_Number.new(viewport,battler) unless battler.obstacle?
    @sprite_dmg_preview = Sprite_DamagePreview.new(viewport,battler,self)
    #revert_to_normal
  end
  #--------------------------------------------------------------------------
  # * Free
  #--------------------------------------------------------------------------
  def dispose
    @sprite_active.dispose if @sprite_active
    @sprite_team.dispose if @sprite_team
    @sprite_turn.dispose if @sprite_turn
    @sprite_dmg_preview.dispose if @sprite_dmg_preview
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    @sprite_active.update if @sprite_active
    @sprite_team.update if @sprite_team
    @sprite_turn.update if @sprite_turn
    @sprite_dmg_preview.update if @sprite_dmg_preview
    super
    if @battler
      @use_sprite = true #everyone uses sprite #@battler.use_sprite?
      if @use_sprite
        update_bitmap
        #update_origin
        #update_position
      end
      setup_new_effect
      setup_new_animation
      update_effect
      if @effect_type.nil?
        set_bat_state(TBS::Characters.bat_state(@battler))
        revert_to_normal unless @bat_state == :dead && @battler.remove_on_death?
      end
      update_team_blink if @blink_mode
    else
      self.bitmap = nil
      @effect_type = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Update Transfer Origin Bitmap
  #--------------------------------------------------------------------------
  def update_bitmap
    super
    init_visibility #if @battler
  end
  #--------------------------------------------------------------------------
  # * Initialize Visibility
  #--------------------------------------------------------------------------
  def init_visibility
    #return if @battler.dead? && @battler.remove_on_death?
    @battler_visible = true #@battler.alive?
    self.opacity = 0 unless @battler_visible
  end
  #--------------------------------------------------------------------------
  # * Set New Effect
  #--------------------------------------------------------------------------
  def setup_new_effect
    super
    if !@battler_visible && @battler.alive?
      start_effect(:appear)
    elsif @battler_visible && @battler.hidden?
      start_effect(:disappear)
    end
    if @battler_visible && @battler.sprite_effect_type
      start_effect(@battler.sprite_effect_type)
      @battler.sprite_effect_type = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Start Effect
  #--------------------------------------------------------------------------
  def start_effect(effect_type)
    @effect_type = effect_type
    case @effect_type
    when :appear
      @effect_duration = 16
      @battler_visible = true
    when :disappear
      @effect_duration = 32
      @battler_visible = false
    when :whiten
      @effect_duration = 16
      @battler_visible = true
    when :blink
      @effect_duration = 20
      @battler_visible = true
    when :collapse
      @effect_duration = 48
      @battler_visible = false
    when :boss_collapse
      @effect_duration = bitmap.height
      @battler_visible = false
    when :instant_collapse
      @effect_duration = 16
      @battler_visible = false
    end
    revert_to_normal
  end
  #--------------------------------------------------------------------------
  # * Revert to Normal Settings
  #--------------------------------------------------------------------------
  def revert_to_normal
    if @battler.dead? && @battler.remove_on_death?
      self.opacity = 0
      return
    end
    #@new_bat_state = @pending_bat_state
    self.blend_type = 0
    self.color.set(0, 0, 0, 0)
    self.opacity = base_opacity
    #self.ox = bitmap.width / 2 if bitmap
    self.ox = @cw / 2
    self.oy = @ch
    #self.src_rect.y = 0
  end
  #--------------------------------------------------------------------------
  # * Set New Animation
  #--------------------------------------------------------------------------
  def setup_new_animation
    if @battler.animation_id > 0
      animation = $data_animations[@battler.animation_id]
      mirror = @battler.animation_mirror
      start_animation(animation, mirror)
      @battler.animation_id = 0
    end
  end
  #--------------------------------------------------------------------------
  # * Determine if Effect Is Executing
  #--------------------------------------------------------------------------
  def effect?
    @effect_type != nil || @character.moving?
  end

  #--------------------------------------------------------------------------
  # * Determine if there are still things displayed (wait for them before removing the sprite battler)
  #--------------------------------------------------------------------------
  def can_rm_sprite?
    !effect?
  end

  #--------------------------------------------------------------------------
  # * Update Effect
  #--------------------------------------------------------------------------
  def update_effect
    if @effect_duration > 0
      @effect_duration -= 1
      case @effect_type
      when :whiten
        update_whiten
      when :blink
        update_blink
      when :appear
        update_appear
      when :disappear
        update_disappear
      when :collapse
        update_collapse
      when :boss_collapse
        update_boss_collapse
      when :instant_collapse
        update_instant_collapse
      end
      on_effect_end if @effect_duration == 0
    end
  end
  #--------------------------------------------------------------------------
  # * Update White Flash Effect
  #--------------------------------------------------------------------------
  def update_whiten
    self.color.set(255, 255, 255, 0)
    self.color.alpha = 128 - (16 - @effect_duration) * 10
  end
  #--------------------------------------------------------------------------
  # * Update Blink Effect
  #--------------------------------------------------------------------------
  def update_blink
    #255
    self.opacity = (@effect_duration % 10 < 5) ? base_opacity : 0
  end
  #--------------------------------------------------------------------------
  # * Update Appearance Effect
  #--------------------------------------------------------------------------
  def update_appear
    self.opacity = (16 - @effect_duration) * 16
  end
  #--------------------------------------------------------------------------
  # * Updated Disappear Effect
  #--------------------------------------------------------------------------
  def update_disappear
    self.opacity = 256 - (32 - @effect_duration) * 10
  end
  #--------------------------------------------------------------------------
  # * Update Collapse Effect
  #--------------------------------------------------------------------------
  def update_collapse
    self.blend_type = 1
    self.color.set(255, 128, 128, 128)
    #self.opacity = 256 - (48 - @effect_duration) * 6
    self.opacity = base_opacity - opacity_ratio*(48 - @effect_duration) * 6
  end
  #--------------------------------------------------------------------------
  # * opacity_ratio
  #--------------------------------------------------------------------------
  def opacity_ratio
    return (base_opacity/256)
  end

  def base_opacity
    @character.opacity * ($game_system.highlight_units ? TBS::TRANSPARENT_OPACITY : 1)
  end
  #--------------------------------------------------------------------------
  # * Update Boss Collapse Effect
  #--------------------------------------------------------------------------
  def update_boss_collapse
    alpha = @effect_duration * 120 / bitmap.height
    self.ox = @cw / 2 + @effect_duration % 2 * 4 - 2
    self.blend_type = 1
    self.color.set(255, 255, 255, 255 - alpha)
    self.opacity = alpha*opacity_ratio
    self.src_rect.y -= 1
    Sound.play_boss_collapse2 if @effect_duration % 20 == 19
  end
  #--------------------------------------------------------------------------
  # * Update Instant Collapse Effect
  #--------------------------------------------------------------------------
  def update_instant_collapse
    self.opacity = 0
  end

  #--------------------------------------------------------------------------
  # new method: update_team_blink -> called only when a skill is selected
  #--------------------------------------------------------------------------
  def update_team_blink
    if @battler.displayed_area_affected?
      if $game_system.area_blink_color
        count = (Graphics.frame_count % 60) / 10
        self.color.set(@blink_color)
        self.color.alpha = 128 - (16 * count)
        self.opacity = base_opacity
      else
        self.color.alpha = 0
        self.opacity = base_opacity
      end
    else
      self.color.set(TBS::UNSELECTED_COLOR)
      self.opacity = base_opacity * 0.8 #lower the opaicity of unselected units
    end
  end
  #--------------------------------------------------------------------------
  # new method: stop_team_blink
  #--------------------------------------------------------------------------
  def stop_team_blink
    self.color.set(0,0,0,0)
    self.opacity = base_opacity
    @blink_mode = false
  end

  #--------------------------------------------------------------------------
  # new method: start_team_blink
  #--------------------------------------------------------------------------
  def start_team_blink
    caster = BattleManager.actor
    @blink_color = TBS::HIGHLIGHT_COLOR[caster.true_friend_status(@battler)]
    @blink_mode = true
  end

  #--------------------------------------------------------------------------
  # new method: on_effect_end
  #--------------------------------------------------------------------------
  def on_effect_end
    #case @effect_type
    #set_bat_state(TBS::Characters.bat_state(@battler))
    #when :collapse, :boss_collapse, :instant_collapse
    #  set_bat_state(TBS::Characters.bat_state(@battler))
    #end
    @effect_type = nil #if @effect_duration == 0
  end

  #--------------------------------------------------------------------------
  # new method: char_available? -> true iff the char exists in the graphics
  #--------------------------------------------------------------------------
  def char_available?(name)
    return @@available_characters[name]
  end

  #--------------------------------------------------------------------------
  # override method: update_src_rect
  #--------------------------------------------------------------------------
  def update_src_rect
    if @tile_id == 0
      index = char_index #modified this part
      pattern = @character.pattern < 3 ? @character.pattern : 1
      sx = (index % 4 * 3 + pattern) * @cw
      sy = (index / 4 * 4 + (@character.direction - 2) / 2) * @ch
      self.src_rect.set(sx, sy, @cw, @ch)
    end
  end
  #--------------------------------------------------------------------------
  # override method: set_bitmap
  #--------------------------------------------------------------------------
  def set_bitmap
    @bat_state = @new_bat_state#TBS::Characters.bat_state(@battler)
    @fixed_index = nil
    @displayed_name = @character_name
    return super unless TBS::Characters::TBS_CHAR_STATES[@bat_state] #should not happen
    def_char, def_index, suffix = TBS::Characters::TBS_CHAR_STATES[@bat_state]
    #try the suffix
    @displayed_name = @character_name + suffix
    return self.bitmap = Cache.character(@displayed_name, hue) if char_available?(@displayed_name)
    #try the def char
    if def_char && char_available?(def_char)
      @fixed_index = def_index
      @displayed_name = def_char
      return self.bitmap = Cache.character(def_char, hue)
    end
    #take the set char
    @displayed_name = @character_name
    super
  end
  #--------------------------------------------------------------------------
  # override method: set_bitmap_name (from Victor Core Engine)
  #--------------------------------------------------------------------------
  def set_bitmap_name
    @displayed_name
  end

  #--------------------------------------------------------------------------
  # override method: get_sign (from Victor Core Engine)
  #--------------------------------------------------------------------------
  def get_sign
    @displayed_name[/^[\!\$]./]
  end

  #--------------------------------------------------------------------------
  # new method: char_index
  #--------------------------------------------------------------------------
  def char_index
    @fixed_index ? @fixed_index : @character.character_index
  end

  #--------------------------------------------------------------------------
  # new method: state_changed?
  #--------------------------------------------------------------------------
  def state_changed?
    @bat_state != @new_bat_state
  end

  #--------------------------------------------------------------------------
  # new method: set_bat_state
  #--------------------------------------------------------------------------
  def set_bat_state(new_state)
    @new_bat_state = new_state
    #@pending_bat_state = new_state
  end

  #def lock_graphic_change?
  #  return [:collapse,:boss_collapse,:instant_collapse].include?(@effect_type) || @battler.sprite_effect_type
  #end

  #--------------------------------------------------------------------------
  # override method: graphic_changed?
  #--------------------------------------------------------------------------
  def graphic_changed?
    return super || state_changed?
  end
end #Sprite_Character_TBS

#============================================================================
# ** Sprite_Team
#------------------------------------------------------------------------------
# This class displays a sprite under the battler's sprite to show its team
# alliegeance. By default the sprite will be a circle of the team's color
#============================================================================
class Sprite_Team < Sprite_Base
  #--------------------------------------------------------------------------
  # Constants and class variable
  #--------------------------------------------------------------------------
  @@cache_bitmap = {}
  CIRCLE_MAX_RAD = 14
  CIRCLE_WIDTH = 3
  CIRCLE_OPACITY = 140

  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, battler)
    @bat = battler
    @character = battler.char
    @team = @bat.team
    super(viewport)
    self.ox = 16
    self.oy = 26
    refresh
    update
  end

  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    refresh if @team != @bat.team
    self.visible = $game_system.team_sprite
    update_pos
    super
  end

  #--------------------------------------------------------------------------
  # new method: update_pos
  #--------------------------------------------------------------------------
  def update_pos
    self.x = @character.screen_x
    self.y = @character.screen_y
    self.z = $game_system.highlight_units ? TBS::TRANSPARENT_Z : 0#@character.screen_z
  end

  #--------------------------------------------------------------------------
  # new method: refresh
  #--------------------------------------------------------------------------
  def refresh
    @team = @bat.team
    tbs_color = TBS::TEAMS.team_color(@team)
    bmp = @@cache_bitmap[tbs_color]
    unless bmp
      bmp = draw_bitmap(tbs_color)
      @@cache_bitmap[tbs_color] = bmp
    end
    self.bitmap = bmp
    self.opacity = CIRCLE_OPACITY
  end

  #--------------------------------------------------------------------------
  # new method: draw_bitmap
  #--------------------------------------------------------------------------
  def draw_bitmap(tbs_color)
    bmp = Bitmap.new(32, 32)
    for r in CIRCLE_MAX_RAD-CIRCLE_WIDTH...CIRCLE_MAX_RAD
      bmp.draw_circle(r, 16, 16 ,tbs_color)
    end
    return bmp
  end
end #Sprite_Team


#============================================================================
# ** Sprite_Active
#------------------------------------------------------------------------------
# This class displays an icon over the battler's sprite to show whether the
# battler is playable or something, see Active_icons in module TBS
#============================================================================
class Sprite_Active < Sprite_Base
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, battler)
    @bat = battler
    @character = battler.char
    @my_index = nil
    super(viewport)
    self.bitmap = Cache.system("Iconset")
    self.ox = 20
    self.oy = 10
    update
  end

  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    draw_icon
    update_pos
    super
  end

  #--------------------------------------------------------------------------
  # new method: update_pos
  #--------------------------------------------------------------------------
  def update_pos
    self.x = @character.screen_x
    self.y = @character.screen_y
    self.z = @character.screen_z
  end

  #--------------------------------------------------------------------------
  # new method: draw_icon
  #--------------------------------------------------------------------------
  def draw_icon
    icon_index = TBS::Characters.get_active_icon(@bat)
    return if @my_index == icon_index
    @my_index = icon_index
    self.src_rect.set(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    self.opacity = 200
  end
end #Sprite_Active

#============================================================================
# ** Sprite_Turn_Number
#------------------------------------------------------------------------------
# This class displays a number representing the position in the turn wheel of
# the battler
#============================================================================
class Sprite_Turn_Number < Sprite_Base
  W = 30
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, battler)
    @bat = battler
    @turn_id == @bat.turn_id
    @character = battler.char
    super(viewport)
    self.ox = W/2#-W
    self.oy = 32
    refresh
  end
  #--------------------------------------------------------------------------
  # new method: refresh
  #--------------------------------------------------------------------------
  def refresh
    bw = W
    bh = Font.default_size * 3
    bitmap = Bitmap.new(bw, bh)
    size = 14
    bitmap.font.size = size
    bitmap.font.out_color.set(0, 0, 0, 255)
    self.bitmap = bitmap
    update
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    self.visible = $game_system.turn_id
    draw_turn unless @turn_id == @bat.turn_id
    update_pos
    super
  end
  #--------------------------------------------------------------------------
  # new method: update_pos
  #--------------------------------------------------------------------------
  def update_pos
    self.x = @character.screen_x
    self.y = @character.screen_y
    self.z = @character.screen_z
  end

  #--------------------------------------------------------------------------
  # new method: draw_turn
  #--------------------------------------------------------------------------
  def draw_turn
    @turn_id = @bat.turn_id
    self.bitmap.clear
    text = @turn_id ? (@turn_id+1).to_s : ""
    bw = self.bitmap.width
    bh = Font.default_size * 3
    self.bitmap.draw_text(0, 0, bw, bh, text, 2)
  end
end # Sprite_Turn_Number

#============================================================================
# ** Sprite_DamagePreview
#------------------------------------------------------------------------------
# Displays a text above the affected battlers representing how much damage
# they might take
#============================================================================
class Sprite_DamagePreview < Sprite_Base
  DMG_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, battler, sprite_tbs_char)
    @bat = battler
    @character = battler.char
    @parent_sprite = sprite_tbs_char
    super(viewport)
    refresh
  end
  #--------------------------------------------------------------------------
  # new method: refresh -> sets the bitmap to draw the text when ready
  #--------------------------------------------------------------------------
  def refresh
    bw = 32 #size of a tile
    bh = DMG_FONT_SIZE*3
    bitmap = Bitmap.new(bw, bh)
    bitmap.font.size = DMG_FONT_SIZE
    bitmap.font.out_color.set(0, 0, 0, 255)
    self.bitmap = bitmap
    self.ox = bw/2
    update
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    self.visible = $game_system.preview_damage && dmg_preview?
    update_text
    update_pos
    super
  end
  #--------------------------------------------------------------------------
  # new method: update_pos
  #--------------------------------------------------------------------------
  def update_pos
    self.oy = @parent_sprite.height+self.bitmap.height
    self.x = @character.screen_x
    self.y = @character.screen_y
    self.z = @character.screen_z + 200
  end
  #--------------------------------------------------------------------------
  # new method: update_text -> changes the text if a new one is available
  #--------------------------------------------------------------------------
  def update_text
    data = @bat.dmg_preview
    draw_text(data) if data
    @bat.dmg_preview = nil
  end
  #--------------------------------------------------------------------------
  # new method: draw_text
  # data is [string, [colors]]
  #--------------------------------------------------------------------------
  def draw_text(data)
    self.bitmap.clear
    return if data[0] == ""
    textL = data[0].split(/\r?\n/)
    bw = self.bitmap.width
    bh = self.bitmap.height
    textL.each_with_index do |text,i|
      self.bitmap.font.color.set(data[1][i]) if data[1][i]
      self.bitmap.draw_text(0, i*DMG_FONT_SIZE, bw, bh, text, 1)
    end
  end
  #--------------------------------------------------------------------------
  # new method: dmg_preview?
  #--------------------------------------------------------------------------
  def dmg_preview?
    return @bat.displayed_area_affected?
  end
end # Sprite_DamagePreview

#==============================================================================
#
# TBS Sprite_Range
#
#==============================================================================

module TBS
  #type in [:move, :attack, :skill, :help_skill]
  TBS_RANGE_TYPES = [:attack, :skill, :help_skill, :move, :place]
  def self.spriteType(type, bIsArea = false)
    x = bIsArea ? TBS_RANGE_TYPES.size : 0
    i = TBS_RANGE_TYPES.index(type)
    return i ? x + i : 0
  end

  #given a sprite type, return the name of a file storing the range
  RANGE_FILES = [FILENAME::ATTACK_RANGE, FILENAME::SKILL_RANGE, FILENAME::HELP_RANGE,  FILENAME::MOVE_RANGE, FILENAME::PLACE_RANGE,
                 FILENAME::ATTACK_AREA, FILENAME::SKILL_AREA, FILENAME::HELP_AREA]
  def self.rangePicture(type)
    return RANGE_FILES[type]
  end
end #TBS

#==============================================================================
# Sprite_Range -> displays all ranges/areas during battle,
# see Sprite_AutoTile_Handler if the range is animated
#==============================================================================
class Sprite_Range < Sprite_Tile
  #--------------------------------------------------------------------------
  # Constants
  #--------------------------------------------------------------------------
  ANIM_FRAMES = 240
  @@cache_bitmap = {}
  #----------------------------------------------------------------------------
  # Object initialization
  #----------------------------------------------------------------------------
  #   type = 0-6, passed by 'def draw_range' from Spriteset_TBS_Map
  #----------------------------------------------------------------------------
  def initialize(viewport, type, x, y)
    @type = type
    super(viewport,x,y)
    @anim = $game_system.anim_range
    @original_opacity = 0
    @anim_step = 0
    refresh
  end

  #----------------------------------------------------------------------------
  # new method: get_color -> returns the color from $game_system
  #----------------------------------------------------------------------------
  def get_color(type)
    case type
    when 0; return $game_system.attack_color #attack
    when 1; return $game_system.attack_skill_color #attack_skill
    when 2; return $game_system.help_skill_color #heal skill
    when 3; return $game_system.move_color #move
    when 4; return $game_system.place_color #place
    #areas
    when 5; return $game_system.attack_color #attack
    when 6; return $game_system.attack_skill_color #attack_skill
    when 7; return $game_system.help_skill_color #heal skill
    end
    raise sprintf("undefined type %d",type) #should not happen
  end
  #----------------------------------------------------------------------------
  # new method: refresh
  #----------------------------------------------------------------------------
  def refresh
    tbs_color = get_color(@type)
    bmp = @@cache_bitmap[tbs_color]
    unless bmp
      bmp = draw_bitmap(tbs_color)
      @@cache_bitmap[tbs_color] = bmp
    end
    self.bitmap = bmp
    #if area, the opacity is denser, else it is more transparent
    @original_opacity = @type >= TBS::TBS_RANGE_TYPES.size ? TBS::AREA_OPACITY : TBS::RANGE_OPACITY
    self.opacity = @original_opacity
    update
  end

  #----------------------------------------------------------------------------
  # new method: draw_bitmap -> creates a new bitmap
  #----------------------------------------------------------------------------
  def draw_bitmap(tbs_color)
    rect = Rect.new(1, 1, 30, 30)
    bmp = Bitmap.new(32, 32)
    bmp.fill_rect(rect, tbs_color)
    return bmp
  end

  #----------------------------------------------------------------------------
  # override method: update -> change the transparency over time if TBS::ANIM_TILES
  #----------------------------------------------------------------------------
  def update
    @anim = $game_system.anim_range
    if @anim
      @anim_step = (@anim_step+1)%ANIM_FRAMES
      ratio = @anim_step < ANIM_FRAMES/2 ? @anim_step.to_f / (ANIM_FRAMES/2) : (ANIM_FRAMES-@anim_step.to_f) / (ANIM_FRAMES/2)
      self.opacity = @original_opacity/2 + (@original_opacity/2 * ratio)
    else
      self.opacity = @original_opacity
    end
    super
  end
end #Sprite_Range

#==============================================================================
# Sprite_AutoTile_Handler -> adds refresh to avoid case in Spriteset with Sprite_Range
#==============================================================================
class Sprite_AutoTile_Handler
  #----------------------------------------------------------------------------
  # new method: refresh -> does nothing
  #----------------------------------------------------------------------------
  def refresh; end
end #Sprite_AutoTile_Handler

#==============================================================================
#
# TBS Sprite_TBS_Cursor
#
#==============================================================================

#----------------------------------------------------------------------------
# Sprite_TBS_Cursor -> handles the display of the cursor
#----------------------------------------------------------------------------
class Sprite_TBS_Cursor < Sprite_Tile
  #----------------------------------------------------------------------------
  # Object initialization
  #----------------------------------------------------------------------------
  def initialize(viewport, x = $game_player.x, y = $game_player.y)
    super(viewport,x,y)
    set_bitmap
    @cursor = SceneManager.scene.tbs_cursor
    moveto(@cursor.x, @cursor.y)
    update
  end
  #----------------------------------------------------------------------------
  # Sets the bitmap to the cursor image, or draws it for you.
  #----------------------------------------------------------------------------
  def set_bitmap
    self.bitmap = Cache.picture(TBS::FILENAME::CURSOR_PICTURE)
  end
  #----------------------------------------------------------------------------
  # MoveTo - Sets the X,Y position of the cursor
  #----------------------------------------------------------------------------
  def moveto(x, y)
    return if @map_x == x && @map_y == y
    @map_x = x % $game_map.width
    @map_y = y % $game_map.height
    center(x,y)
  end
  #--------------------------------------------------------------------------
  # * Set Map Display Position to Center of Screen
  #     x : x-coordinate
  #     y : y-coordinate
  #--------------------------------------------------------------------------
  def center(x, y)
    $game_player.center(x,y)
  end
  #----------------------------------------------------------------------------
  # Dispose method
  #----------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end

  #--------------------------------------------------------------------------
  # override method: screen_z
  #--------------------------------------------------------------------------
  def screen_z; 101+($game_system.highlight_units ? TBS::TRANSPARENT_Z : 0); end
  #----------------------------------------------------------------------------
  # Update Process
  #----------------------------------------------------------------------------
  def update
    moveto(@cursor.x, @cursor.y)
    self.visible = @cursor.active
    super
  end
end #Sprite_TBS_Cursor

#==============================================================================
#
# TBS Spriteset_TBS_Map
#
#==============================================================================

#==============================================================================
# Spriteset_TBS_Map -> stores and handles every display features
#==============================================================================
class Spriteset_TBS_Map < Spriteset_Map
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader   :tile_sprites
  attr_reader   :tgt_sprite #the sprite use to display animations when single target mod
  attr_reader   :viewport1, :viewport2
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(*args)
    init_tile_sprites
    super(*args)
  end

  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    super
    update_battler_sprites
    update_tile_sprites
    update_cursor
    @tgt_sprite.update
  end

  #--------------------------------------------------------------------------
  # override method: dispose
  #--------------------------------------------------------------------------
  def dispose
    dispose_tile_sprites
    super
  end

  #--------------------------------------------------------------------------
  # new method: move_tgt_sprite -> set the position of the target sprite to
  # the selected target for animation display (for single animation)
  #--------------------------------------------------------------------------
  def move_tgt_sprite(x,y)
    @tgt_sprite.character.moveto(x,y)
  end

  #--------------------------------------------------------------------------
  # new method: anim_tgt_sprite -> sets an animation to the tgt_sprite
  #--------------------------------------------------------------------------
  def anim_tgt_sprite(anim_id, mirror = false)
    @tgt_sprite.character.animation_id = anim_id
  end

  #--------------------------------------------------------------------------
  # Characters sprites
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # override method: create_characters (does not call the original)
  #--------------------------------------------------------------------------
  def create_characters
    @character_sprites = []
    for event in $game_map.tbs_events #display all tbs events
      @character_sprites.push(Sprite_Character.new(@viewport1, event))
    end
    @map_id = $game_map.map_id
    create_battler_sprites
    create_cursor
    @tgt_sprite = Sprite_Character.new(@viewport1, Game_Character.new())
  end

  #--------------------------------------------------------------------------
  # override method: dispose_characters
  #--------------------------------------------------------------------------
  def dispose_characters
    super
    dispose_battler_sprites
    dispose_cursor
    @tgt_sprite.dispose
  end

  #--------------------------------------------------------------------------
  # Cursor sprite
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # new method: create_cursor
  #--------------------------------------------------------------------------
  def create_cursor
    @cursor = Sprite_TBS_Cursor.new(@viewport1)
    @cursor.visible = false
  end

  #--------------------------------------------------------------------------
  # new method: get_cursor_sprite (to track its screen position outside of spriteset)
  #--------------------------------------------------------------------------
  def get_cursor_sprite
    return @cursor
  end

  #--------------------------------------------------------------------------
  # new method: update_cursor
  #--------------------------------------------------------------------------
  def update_cursor
    @cursor.update unless @cursor.nil?
  end

  #--------------------------------------------------------------------------
  # new method: dispose_cursor
  #--------------------------------------------------------------------------
  def dispose_cursor
    @cursor.dispose unless @cursor.nil?
  end

  #--------------------------------------------------------------------------
  # Battlers sprites
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # new method: create_battler_sprites
  #--------------------------------------------------------------------------
  def create_battler_sprites
    @battler_sprites = []
    for bat in SceneManager.scene.tactics_all #display all battlers handled by Scene_TBS_Battle
      @battler_sprites.push(Sprite_Character_TBS.new(@viewport1, bat))
    end
  end

  #--------------------------------------------------------------------------
  # new method: create_battler_sprite -> to add a specific sprite
  #--------------------------------------------------------------------------
  def create_battler_sprite(bat)
    @battler_sprites.push(Sprite_Character_TBS.new(@viewport1, bat))
  end

  #--------------------------------------------------------------------------
  # new method: update_battler_sprites
  #--------------------------------------------------------------------------
  def update_battler_sprites
    @battler_sprites.each do |sprite|
      sprite.update
      sprite.dispose if sprite.to_dispose && sprite.can_rm_sprite?
    end
    @battler_sprites.select! {|sprite| !sprite.disposed?}
  end

  #--------------------------------------------------------------------------
  # new method: dispose_battler_sprites
  #--------------------------------------------------------------------------
  def dispose_battler_sprites
    @battler_sprites.each {|sprite| sprite.dispose }
    @battler_sprites = []
  end

  #--------------------------------------------------------------------------
  # new method: get_battler_sprites
  #--------------------------------------------------------------------------
  def get_battler_sprites
    @battler_sprites
  end

  #--------------------------------------------------------------------------
  # new method: dispose_battler_sprite -> to remove a specific sprite from display
  #--------------------------------------------------------------------------
  def dispose_battler_sprite(bat)
    s = get_sprite(bat)
    s.to_dispose = true if s
    return
    #id = @battler_sprites.index{|sprite| sprite.battler == bat}
    #return if id.nil?
    #@battler_sprites.delete_at(id)
  end

  #--------------------------------------------------------------------------
  # new method: get_sprite -> to get a specific sprite from a battler
  #--------------------------------------------------------------------------
  def get_sprite(bat)
    return @battler_sprites.find{|sprite| sprite.battler == bat}
    #if id.nil?
      #puts sprintf("weird call " + bat.name)
    #  l = @battler_sprites.select{|sprite| sprite.battler.name == bat.name}
    #  puts l.size
    #  puts @battler_sprites.size
    #  puts ($game_party.tbs_members + $game_troop.tbs_members + $game_troop.obstacles).size
    #  @battler_sprites.each {|s| puts s.battler.name}
    #end
    #return id ? @battler_sprites[id] : nil
  end
  #--------------------------------------------------------------------------
  # * Determine if Animation is Being Displayed
  #--------------------------------------------------------------------------
  def animation?
    @tgt_sprite.animation? || @battler_sprites.any? {|sprite| sprite.animation? }
  end
  #--------------------------------------------------------------------------
  # * Determine if Effect Is Executing
  #--------------------------------------------------------------------------
  def effect?
    @battler_sprites.any? {|sprite| sprite.effect? }
  end

  #--------------------------------------------------------------------------
  # Tile sprites
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # new method: init_tile_sprites
  #--------------------------------------------------------------------------
  def init_tile_sprites
    @tile_sprites = []
    @move_sprites = []
    @range_sprites = []
    @area_sprites = []
    @path_sprites = []
  end

  #--------------------------------------------------------------------------
  # new method: all_tile_sprites
  #--------------------------------------------------------------------------
  def all_tile_sprites
    return @tile_sprites + @move_sprites + @range_sprites + @area_sprites + @path_sprites
  end

  #--------------------------------------------------------------------------
  # new method: update_tile_sprites
  #--------------------------------------------------------------------------
  def update_tile_sprites
    if SceneManager.scene.tbs_cursor.has_moved
      dispose_path
      draw_path
      dispose_area
      draw_area
    end
    all_tile_sprites.each {|s| s.update}
  end
  #--------------------------------------------------------------------------
  # new method: refresh_tile_sprites
  #--------------------------------------------------------------------------
  def refresh_tile_sprites
    (@tile_sprites + @move_sprites + @range_sprites + @area_sprites).each {|s| s.refresh}
  end
  #--------------------------------------------------------------------------
  # new method: dispose_tile_sprites
  #--------------------------------------------------------------------------
  def dispose_tile_sprites
    all_tile_sprites.each {|s| s.dispose}
    @tile_sprites.clear
    @move_sprites.clear
    @range_sprites.clear
    @area_sprites.clear
    @path_sprites.clear
  end

  #--------------------------------------------------------------------------
  # new method: range_sprite_list -> returns the array corresponding to type (in 0-6)
  #--------------------------------------------------------------------------
  def range_sprite_list(type)
    sprites = @tile_sprites
    x = TBS::TBS_RANGE_TYPES.size
    sprites = @move_sprites if type == x-1
    sprites = @range_sprites if type < x-1
    sprites = @area_sprites if type >= x
    return sprites
  end

  #--------------------------------------------------------------------------
  # new method: dispose_range
  #--------------------------------------------------------------------------
  def dispose_range(type)
    sprites = range_sprite_list(type)
    sprites.each {|s| s.dispose}
    sprites.clear
  end

  #--------------------------------------------------------------------------
  # new method: draw_range -> range is a list of [x,y], type is in 0-6
  #--------------------------------------------------------------------------
  def draw_range(range, type)
    sprites = range_sprite_list(type)
    filename = TBS.rangePicture(type)
    if filename && filename != ""
      sprites.push(Sprite_AutoTile_Handler.new(@viewport1,filename,range,TBS::AUTO_RANGE_FPI))
    else
      for p in range
        sprites.push(Sprite_Range.new(@viewport1, type, p[0], p[1]))
      end
    end
  end

  #--------------------------------------------------------------------------
  # new method: dispose_path
  #--------------------------------------------------------------------------
  def dispose_path
    @path_sprites.each {|s| s.dispose}
    @path_sprites.clear
  end

  #--------------------------------------------------------------------------
  # new method: draw_path
  #--------------------------------------------------------------------------
  def draw_path
    return unless SceneManager.scene_is?(Scene_TBS_Battle)
    cursor = SceneManager.scene.tbs_cursor
    return unless cursor.active && cursor.mode == :move
    for p in cursor.path.char_list
      @path_sprites.push(Sprite_Character.new(@viewport1, p))
    end
  end

  #--------------------------------------------------------------------------
  # new method: dispose_area
  #--------------------------------------------------------------------------
  def dispose_area
    @area_sprites.each {|s| s.dispose}
    @area_sprites.clear
  end

  #--------------------------------------------------------------------------
  # new method: draw_area
  #--------------------------------------------------------------------------
  def draw_area
    return unless SceneManager.scene_is?(Scene_TBS_Battle)
    cursor = SceneManager.scene.tbs_cursor
    return unless cursor.active && cursor.requires_area?
    type = TBS.spriteType(cursor.range_mode,true)
    draw_range(cursor.area,type)
  end
end #Spriteset_TBS_Map

#==============================================================================
# TBS Part 4: Windows
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Deals with Window classes
#==============================================================================

#==============================================================================
#
# TBS Commands
#
#==============================================================================

#============================================================================
# Window_Base
#============================================================================
class Window_Base < Window
  #--------------------------------------------------------------------------
  # new method: relocate -> place the window based on a direction/numpad number
  #--------------------------------------------------------------------------
  def relocate(dir)
    p = TBS.direction_to_delta(dir)
    self.x = (p.x + 1) * (Graphics.width - width)/2
    self.y = (p.y + 1) * (Graphics.height - height)/2
  end

  #--------------------------------------------------------------------------
  # alias method: draw_actor_class -> supports enemies
  #--------------------------------------------------------------------------
  alias tbs_draw_actor_class draw_actor_class
  def draw_actor_class(actor, x, y, width = 112)
    return tbs_draw_actor_class(actor, x, y, width) if actor.actor?
    change_color(normal_color)
    draw_text(x, y, width, line_height, actor.class_name)
  end
end

#============================================================================
# Window_TBS_ActorCommand
#------------------------------------------------------------------------------
# Deals with the list of commands when selecting a playable battler
# battler can be an actor or an enemy
# Command list is:
# Move
# Attack
# Guard
# Skills
# Item (if battler is an actor)
# Custom
# Status
# Wait (end of battler's turn)
#============================================================================
class Window_TBS_ActorCommand < Window_ActorCommand
  #--------------------------------------------------------------------------
  # override method: make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    return unless @actor
    add_move_command
    add_attack_command
    add_guard_command
    add_skill_commands
    add_item_command
    add_custom_commands
    add_status_command
    add_wait_command
  end

  #--------------------------------------------------------------------------
  # override method: window_height
  #--------------------------------------------------------------------------
  def window_height
    [item_max * item_height + standard_padding * 2, Graphics.height].min
  end

  #--------------------------------------------------------------------------
  # new method: add_tbs_command -> adds the command unless command conditions
  # are not met and the tbs option states to hide the command
  #--------------------------------------------------------------------------
  def add_command_tbs(name, symbol, enabled = true, ext = nil)
    add_command(name, symbol, enabled, ext) unless (TBS::HIDE_PERFORMED_ACTIONS && !enabled)
  end

  #--------------------------------------------------------------------------
  # override method: add_attack_command
  #--------------------------------------------------------------------------
  def add_attack_command
    add_command_tbs(Vocab::attack, :attack, (@actor.attack_usable? && @actor.current_action))
  end
  #--------------------------------------------------------------------------
  # override method: add_guard_command
  #--------------------------------------------------------------------------
  def add_guard_command
    add_command_tbs(Vocab::guard, :guard, (@actor.guard_usable? && @actor.current_action))
  end
  #--------------------------------------------------------------------------
  # override method: add_skill_commands
  #--------------------------------------------------------------------------
  def add_skill_commands
    @actor.added_skill_types.sort.each do |stype_id|
      name = $data_system.skill_types[stype_id]
      add_command_tbs(name, :skill, @actor.current_action, stype_id)
    end
  end
  #--------------------------------------------------------------------------
  # override method: add_item_command
  #--------------------------------------------------------------------------
  def add_item_command
    add_command_tbs(Vocab::item, :item, @actor.current_action) unless @actor.enemy?
  end

  #--------------------------------------------------------------------------
  # new method: add_move_command
  #--------------------------------------------------------------------------
  def add_move_command
    add_command_tbs(TBS::Vocab::Commands::Menu_Move, :move, @actor.can_move?)
  end

  #--------------------------------------------------------------------------
  # new method: add_status_command
  #--------------------------------------------------------------------------
  def add_status_command
    add_command_tbs(Vocab.status, :status)
  end

  #--------------------------------------------------------------------------
  # new method: add_wait_command
  #--------------------------------------------------------------------------
  def add_wait_command
    add_command_tbs(TBS::Vocab::Commands::Menu_Wait, :wait)
  end

  #--------------------------------------------------------------------------
  # new method: add_custom_commands
  #--------------------------------------------------------------------------
  def add_custom_commands
    #add_command_tbs("Interact", :interact) if false
  end

  #--------------------------------------------------------------------------
  # override method: visible_line_number
  #--------------------------------------------------------------------------
  def visible_line_number
    return [item_max,15].min
  end

  #--------------------------------------------------------------------------
  # override method: refresh
  #--------------------------------------------------------------------------
  def refresh
    super
    select(0) if @index >= item_max
    self.height = fitting_height(visible_line_number)
  end

  #--------------------------------------------------------------------------
  # new method: remaining_commands? -> asks if commands are remaining, else, do the wait/end of turn action
  #--------------------------------------------------------------------------
  def remaining_commands?
    @actor.can_move? || @actor.current_action
  end
  #--------------------------------------------------------------------------
  # override method: update_help
  #--------------------------------------------------------------------------
  def update_help
    txt = ""
    case current_symbol
    when :attack
      txt = TBS::Vocab::Help::Attack
    when :move
      txt = TBS::Vocab::Help::Move
    when :guard
      txt = TBS::Vocab::Help::Guard
    when :status
      txt = TBS::Vocab::Help::Status
    when :wait
      txt = TBS::Vocab::Help::Wait
    when :skill
      txt = TBS::Vocab::Help::Skill_Class
    when :item
      txt = TBS::Vocab::Help::Item
    end
    @help_window.set_text(txt)
  end
  #--------------------------------------------------------------------------
  # override method: activate
  #--------------------------------------------------------------------------
  def activate
    super
    if $game_system.help_window && @help_window
      @help_window.show
      @help_window.relocate(2)
    end
  end
  #--------------------------------------------------------------------------
  # override method: deactivate
  #--------------------------------------------------------------------------
  def deactivate
    super
    if $game_system.help_window && @help_window
      @help_window.hide
      @help_window.relocate(8)
    end
  end
end #Window_TBS_ActorCommand



#============================================================================
# Window_TBS_GlobalCommand
#------------------------------------------------------------------------------
# Deals with the list of commands when pressing ESC
# Command list is:
# End of Turn -> Confirm -> skip the turn of the active battlers
# Escape (if available)
# Victory Conditions -> Victory text Menu
# Turn Order
# Options -> Option Menu
# Cancel (ESC)
#============================================================================
class Window_TBS_GlobalCommand < Window_Command
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    self.openness = 0
    deactivate
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    return 192
  end
  #--------------------------------------------------------------------------
  # * Get Number of Lines to Show
  #--------------------------------------------------------------------------
  def visible_line_number
    item_max
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(TBS::Vocab::Commands::Battle_Option_End_Turn, :end_team_turn)
    add_command(Vocab::escape, :escape, BattleManager.can_escape?)
    add_command(TBS::Vocab::Commands::Battle_Option_Conditions, :victory_conditions)
    add_command(TBS::Vocab::Commands::Battle_Option_TurnWheel, :turn_order)
    add_original_commands
    add_command(TBS::Vocab::Commands::Battle_Option_Config, :options) if $imported["TIM-TBS-Settings"]
    add_command(Vocab::save, :save, save_enabled) if $imported["TIM-TBS-Save"] && $game_system.save_mid_tbs
    add_command(TBS::Vocab::Commands::Battle_Option_Cancel, :cancel)
  end

  #--------------------------------------------------------------------------
  # * Additional commands (method to change with addons)
  #--------------------------------------------------------------------------
  def add_original_commands
  end

  #--------------------------------------------------------------------------
  # * Get Activation State of Save
  #--------------------------------------------------------------------------
  def save_enabled
    !$game_system.save_disabled
  end
  #--------------------------------------------------------------------------
  # * Setup
  #--------------------------------------------------------------------------
  def setup
    clear_command_list
    make_command_list
    refresh
    #select(0)
    activate
    open
  end
end #Window_TBS_GlobalCommand

#============================================================================
# Window_TBS_PlaceGlobalCommand
#------------------------------------------------------------------------------
# Lists the commands available in place phase
#============================================================================
class Window_TBS_PlaceGlobalCommand < Window_TBS_GlobalCommand
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(TBS::Vocab::Commands::Battle_Option_Start_Battle, :start_battle, $game_party.tbs_members.size > 0)
    add_command(TBS::Vocab::Commands::Battle_Option_Conditions, :victory_conditions)
    add_original_commands
    add_command(TBS::Vocab::Commands::Battle_Option_Config, :options) if $imported["TIM-TBS-Settings"]
    add_command(Vocab::save, :save, save_enabled) if $imported["TIM-TBS-Save"] && $game_system.save_pre_tbs
    add_command(TBS::Vocab::Commands::Battle_Option_Cancel, :cancel)
  end

  #--------------------------------------------------------------------------
  # * Additional commands (method to change with addons)
  #--------------------------------------------------------------------------
  def add_original_commands
  end
end #Window_TBS_GlobalCommand

#==============================================================================
#
# TBS Window_Confirm
#
#==============================================================================

#==============================================================================
# Window_Confirm -> displays a Yes/No command with text above
# Parent class for Window_TBS_Confirm
#==============================================================================
class Window_Confirm < Window_HorzCommand
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor   :text_list #array of strings, one per line
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(x, y,textLines = 1)
    @textLines = textLines #amount of text lines
    @text_list = []
    super(x, y)
  end
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width / 2
  end
  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height
    fitting_height(@textLines+1)
  end
  #--------------------------------------------------------------------------
  # refresh
  #--------------------------------------------------------------------------
  def refresh
    super
    draw_head_text(0,0)
  end

  #--------------------------------------------------------------------------
  # override method: item_rect
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = super
    rect.y += @textLines*line_height
    rect
  end

  #--------------------------------------------------------------------------
  # override method: contents_height
  #--------------------------------------------------------------------------
  def contents_height
    window_height
  end

  #--------------------------------------------------------------------------
  # new method: draw_head_text -. displays the text on each line
  #--------------------------------------------------------------------------
  def draw_head_text(x,y)
    for h in 0...@textLines
      #rect = Rect.new(x, y + h*line_height, contents.width - 4 - x, line_height)
      rect = Rect.new(x, y + h*line_height, contents.width, line_height)
      txt = @text_list[h].nil? ? "" : @text_list[h]
      draw_text(rect, txt, 1)
    end
  end

  #--------------------------------------------------------------------------
  # override method: col_max -> for YES/NO
  #--------------------------------------------------------------------------
  def col_max
    return 2
  end

  #--------------------------------------------------------------------------
  # override method: make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(TBS::Vocab::Confirm::Yes, :ok)
    add_command(TBS::Vocab::Confirm::No, :no)
  end
end #Window_Confirm

#==============================================================================
# Window_TBS_Confirm -> confirms tbs actions or cancel them
#==============================================================================
class Window_TBS_Confirm < Window_Confirm
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :mode

  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(mode)
    super(0,0,1)
    set_mode(mode)
    relocate(5) #put the window in the center
    deactivate
    self.openness = 0
  end

  #--------------------------------------------------------------------------
  # new method: set_mode -> mode in [:start_battle, :skip_turn, :skill, :item, :attack, :move, :wait]
  #--------------------------------------------------------------------------
  def set_mode(mode)
    @mode = mode
    txt = ""
    case mode
    when :start_battle
      txt = TBS::Vocab::Confirm::Place_Here
    when :skip_turn
      txt = TBS::Vocab::Confirm::Skip_turn
    when :skill
      txt = TBS::Vocab::Confirm::Skill_Here
    when :item
      txt = TBS::Vocab::Confirm::Item_Here
    when :attack
      txt = TBS::Vocab::Confirm::Attack_Here
    when :move
      txt = TBS::Vocab::Confirm::Move_Here
    when :wait
      txt = TBS::Vocab::Confirm::Wait_Here
    when :settings
      txt = TBS::Vocab::Confirm::Save_Options
    end
    @text_list = [txt]
  end

  #--------------------------------------------------------------------------
  # new method: setup -> called by Scene_TBS_Battle
  #--------------------------------------------------------------------------
  def setup(mode)
    set_mode(mode)
    refresh
    select(0)
    activate
    open
  end
end #Window_TBS_Confirm

#==============================================================================
#
# TBS Window_TBS_Status
#
#==============================================================================

#==============================================================================
# Window_Small_TBS_Status -> displays a small amount of data on the battlers
#==============================================================================
class Window_Small_TBS_Status < Window_Base
  #--------------------------------------------------------------------------
  # Comstants
  #--------------------------------------------------------------------------
  STD_W = 4 #safe distance from other objects of the widnow, in pixel
  FACE_W = 96 #size of a face in pixel
  GAUGE_W = FACE_W+4 #size of the gauge in pixel

  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(battler = nil)
    xwidth = 10*STD_W + FACE_W + GAUGE_W #224
    super(0, 0, xwidth, line_height*7+STD_W)
    hide
    @battler = battler
    relocate(9)
    refresh
  end
  #--------------------------------------------------------------------------
  # * Set Actor
  #--------------------------------------------------------------------------
  def battler=(battler)
    return if @battler == battler
    @battler = battler
    refresh
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    return draw_empty if @battler.nil?
    draw_block1   (line_height * 0)
    draw_block2   (line_height * 1)
    text_w = draw_battler_move(@battler, STD_W + line_height * 5)
    icon_w = contents_width - text_w
    draw_actor_icons(@battler, 2*STD_W, STD_W + line_height * 5, icon_w)
  end
  #--------------------------------------------------------------------------
  # * draw_empty -> when no battler is available
  #--------------------------------------------------------------------------
  def draw_empty
    text = TBS::Vocab::PreBattle::Empty_place_status
    #(height-line_height)/2
    draw_text(0, 0, contents.width, contents.height, text, 1)
  end
  #--------------------------------------------------------------------------
  # * Draw Block 1 -> battler name and class name
  #--------------------------------------------------------------------------
  def draw_block1(y)
    draw_actor_name(@battler, STD_W, y)
    draw_actor_class(@battler, 4*STD_W+FACE_W, y)
  end
  #--------------------------------------------------------------------------
  # * Draw Block 2 -> battler face, lvl and gauges
  #--------------------------------------------------------------------------
  def draw_block2(y)
    draw_actor_face(@battler, 2*STD_W, y)
    draw_basic_info(4*STD_W + FACE_W, y)
  end
  #--------------------------------------------------------------------------
  # * Draw Basic Information -> level and hp/mp/tp
  #--------------------------------------------------------------------------
  def draw_basic_info(x, y)
    draw_actor_level(@battler, x, y + line_height * 0) unless @battler.obstacle?
    draw_gauge_area(@battler,x,y+ line_height)
  end

  #--------------------------------------------------------------------------
  # * draw_gauge_area -> hp, mp and tp (the last two or displayed only if they can be greater than 0)
  #--------------------------------------------------------------------------
  def draw_gauge_area(battler,x,y,w=GAUGE_W)
    draw_actor_hp(battler, x , y, w)
    y += line_height
    if battler.mmp > 0
      draw_actor_mp(battler, x , y, w)
      y += line_height
    end
    return if battler.obstacle?
    draw_actor_tp(battler, x, y,w) if ($data_system.opt_display_tp && battler.max_tp > 0)
  end

  #--------------------------------------------------------------------------
  # * draw_battler_move -> display on the right the move points as remaining_move_points / max_move_points
  #--------------------------------------------------------------------------
  def draw_battler_move(bat,y)
    return 0 if bat.obstacle?
    txt = bat.available_mov.to_s + " / " + bat.mmov.to_s
    text_x = contents_width - text_size(txt).width
    draw_text(text_x, y, text_size(txt).width, line_height, txt)
    return text_size(txt).width
  end

  #--------------------------------------------------------------------------
  # * check_relocate -> tracks the x/y position of the cursor to move this window if it is too close
  #--------------------------------------------------------------------------
  def check_relocate(cursor_sprite_x,cursor_sprite_y)
    if cursor_sprite_x - 32 >= x
      if cursor_sprite_y <= height
        relocate(3)
      else
        relocate(9) if cursor_sprite_y - 32 >= y
      end
    end
  end

   #--------------------------------------------------------------------------
  # * check_relocate -> tracks the x/y position of the cursor to move this window if it is too close
  #--------------------------------------------------------------------------
  def check_relocate_place(cursor_sprite_x,cursor_sprite_y)
    if cursor_sprite_x - 32 <= width
      if cursor_sprite_y <= height
        relocate(1)
      else
        relocate(7) if cursor_sprite_y - 32 >= y
      end
    end
  end
end #Window_Small_TBS_Status

#============================================================================
# Window_Full_Status -> display full data of the battler, supports non-actors battlers
#============================================================================
class Window_Full_Status < Window_Status
  #----------------------------------------------------------------------------
  # override method: refresh -> supports nil battlers
  #----------------------------------------------------------------------------
  def refresh
    super if @actor
  end
  #----------------------------------------------------------------------------
  # override method: draw_equipments -> only for actors
  #----------------------------------------------------------------------------
  def draw_equipments(x, y)
    super if @actor.actor?
  end
  #----------------------------------------------------------------------------
  # override method: draw_exp_info -> only for actors
  #----------------------------------------------------------------------------
  def draw_exp_info(x, y)
    super if @actor.actor?
  end
end #Window_Full_Status

#==============================================================================
# Window_WinConditions -> displays the victory condition text
#==============================================================================
class Window_WinConditions < Window_Selectable
  #--------------------------------------------------------------------------
  # Constants
  #--------------------------------------------------------------------------
  COND_WIDTH = 350 #Graphic.width / 2
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, window_width, window_height)
    relocate(5)
    deactivate
    self.openness = 0
    refresh
  end

  #--------------------------------------------------------------------------
  # new method: textList -> fetch it directly from $game_system.victory_cond_texts
  #--------------------------------------------------------------------------
  def textList
    return $game_system.victory_cond_texts
  end

  #--------------------------------------------------------------------------
  # new method: window_height
  #--------------------------------------------------------------------------
  def window_height
    return fitting_height(textList.size)
  end

  #--------------------------------------------------------------------------
  # new method: window_width
  #--------------------------------------------------------------------------
  def window_width
    return COND_WIDTH
  end

  #--------------------------------------------------------------------------
  # override method: refresh -> draws the text line per line,
  # can read message commands like colors
  #--------------------------------------------------------------------------
  def refresh
    self.height = window_height
    contents.clear
    x = 8
    y = 0
    for text in textList
      draw_text_ex(x, y, text)
      y += line_height
    end
  end
end #Window_WinConditions

#==============================================================================
# Window_TurnOrder -> displays unit in order in the turn wheel
#==============================================================================
class Window_TurnOrder < Window_Command
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    @turnWheel = nil
    super(0,0)
    deactivate
    self.openness = 0
    refresh
  end

  #--------------------------------------------------------------------------
  # set_turn_wheel
  #--------------------------------------------------------------------------
  def set_turn_wheel
    @turnWheel = SceneManager.scene.turnWheel if SceneManager.scene_is?(Scene_TBS_Battle)
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    set_turn_wheel unless @turnWheel
    return unless @turnWheel
    @turnWheel.battlerList.each {|bat| add_command(bat.name,:ok,true,bat)}
    #self.height = window_height
  end

  def refresh
    super
    self.height = window_height
  end

  #--------------------------------------------------------------------------
  # command_ext
  #--------------------------------------------------------------------------
  def command_ext(index)
    @list[index][:ext]
  end

  #--------------------------------------------------------------------------
  # override method: item_height
  #--------------------------------------------------------------------------
  def item_height; 30; end

  #--------------------------------------------------------------------------
  # override method: window_height
  #--------------------------------------------------------------------------
  def window_height
    [item_max * item_height + standard_padding * 2, Graphics.height].min
  end

  #--------------------------------------------------------------------------
  # override method: draw_face -> now takes into account the size of the item
  # to draw in
  #--------------------------------------------------------------------------
  def draw_face(face_name, face_index, x, y, enabled = true)
    bitmap = Cache.face(face_name)
    face_size = 96
    w = [item_width,face_size].min
    h = [item_height,face_size].min
    _x = (face_size - w) / 2 #face_size/2 -
    _y = (face_size - h) / 2
    rect = Rect.new(face_index % 4 * 96 + _x, face_index / 4 * 96 + _y, w, h)
    contents.blt(x, y, bitmap, rect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end

  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    bat = command_ext(index)
    rect = item_rect(index)
    enabled = bat.is_active?

    draw_back(index,TBS::TEAMS.team_color(bat.team).dup)
    draw_face(bat.face_name,bat.face_index,rect.x, rect.y,enabled)
    change_color(normal_color, enabled)
    draw_text(item_rect_for_text(index), command_name(index), alignment) #draw bat name
    draw_text(item_rect_for_text(index), index+1, 2) #draw turn id
  end

  #--------------------------------------------------------------------------
  # * Draw Background for team affiliation
  #--------------------------------------------------------------------------
  def draw_back(index,color)
    rect = item_rect(index)
    color.alpha = 80#translucent_alpha*0.8
    contents.fill_rect(rect, color)
    return
    bitmap = Bitmap.new(rect.width, rect.height)
    bitmap.fill_rect(rect,color)
    contents.blt(rect.x, rect.y, bitmap, rect, translucent_alpha)
    bitmap.dispose
  end

  #--------------------------------------------------------------------------
  # override method: update_cursor -> moves the battle cursor too
  #--------------------------------------------------------------------------
  def update_cursor
    super
    SceneManager.scene.tbs_cursor.moveto_bat(current_ext) if SceneManager.scene_is?(Scene_TBS_Battle) && current_symbol == :ok
  end
end #Window_TurnOrder

#==============================================================================
# TBS Part 5: AI
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Deals with non-player-controlled units, takes decisions
#==============================================================================

#==============================================================================
# ** AI
#------------------------------------------------------------------------------
#   What can an ai do?
#   -Move
#   -Use action (attack, skill, item?)
#   -Interract with environment?
#==============================================================================
# levels of AIs :
# -dumb/classic (easiest to deal with): given a set of available actions,
# pick a random one (based on probabilities like vanilla) and play it,
# try to stay at some distance (default 1) from the player
# -gtbs-like: strategy based on probabilities like looking for kill etc. X
# -smartish: FSM with transition, each state represent a strategy (like gtbs)
# -oversmartish: tries to predict next few turns
# -custom
###############################################
#Tant que je peux faire une action :
#  L = la liste d actions que je peux faire #(coût en ressources, cooldown etc.)
#  M = la liste des cases où je peux me rendre en me déplaçant
#  Ordonne L selon mes préférences d actions #(donc probabilité + éventuellement un état interne qui me ferait privilégier certaines actions par rapport aux autres)
#  Pour chaque capacité c de L (ordonnée) :
#    Je calcule la liste des cases que c peut toucher depuis ma position ou une position où je me serai déplacé #voir pb A
#    Si cette liste contient des cibles pertinentes :
#      Je prends la meilleure cible #(calcul propre à l ia, une meilleure cible dépendra du nombre de cibles, et d'à quel point ça avantage mon équipe, genre tuer les cibles, les affaiblir ou soigner mes alliés etc.)
#      Je regarde où je peux atteindre cette cible #voir pb B
#      Je me déplace vers la meilleure position qui peut atteindre ma cible #(calcul propre à l'ia, dépend de si elle veut se rapprocher ou s'éloigner, de ses déplacements restants etc.)
#      Je lance la capacité sur la cible
#      Je reviens au tant que
#    Sinon:
#      Je passe à la capacité suivante
#  Si aucune action ne peut être faite, je regarde la meilleure position où je peux aller, j'y vais et je termine mon tour
################################################

#============================================================================
# ** Preview_DamageData
#------------------------------------------------------------------------------
# Parse the potential results of an action, called by AIs to rate the result
# Sprite_DamagePreview displays this to_str method output
# This preview is independant from TBS.
#============================================================================
class Preview_DamageData
  #--------------------------------------------------------------------------
  # Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :touch_rate, :crit_rate, :variance, :mean_v
  #--------------------------------------------------------------------------
  # Initialize: user is the caster, item the ability, tgt the battler targeted
  # by the ability.
  #--------------------------------------------------------------------------
  def initialize(tgt,user,item)
    data = tgt.preview_damage(user,item)
    @tgt = tgt
    @user = user
    @item = item #the item used (for additional info)
    @mean_v = data[0] #value of eval damage, > 0 for damage, < 0 for healings
    @touch_rate = [[data[1]*(1-data[2]),1].min,0].max #float
    @crit_rate = [[data[3],1].min,0].max #float
    @variance = item.damage.variance #integer in %
    @effects_res = data[4] #hash table
  end
  #--------------------------------------------------------------------------
  # method: dmg_value -> returns the value with or without crit rate applied
  # mode between 0,1,2 returns:
  # -min value for 0
  # -average value for 1
  # -max value for 2
  #--------------------------------------------------------------------------
  def dmg_value(crit = false, mode = 1)
    v = @mean_v #>0 means that it will deal damage, <0 means that it will heal
    case mode
    when 0
      v -= v*@variance*0.01
      v = [v,0].max if @mean_v > 0
      v = [v,0].min if @mean_v < 0
    when 2
      v += v*@variance*0.01
    end
    return crit ? @tgt.apply_critical(v) : v
  end

  #--------------------------------------------------------------------------
  # method: hp_change -> returns the hp difference (positive -> gain hp, negative -> lose hp)
  #--------------------------------------------------------------------------
  def hp_change(crit = false, mode = 1)
    v = @effects_res[:hp]
    v -= dmg_value(crit,mode) if @item.damage.to_hp?
    return v
  end

  #--------------------------------------------------------------------------
  # method: mp_change -> returns the mp difference (positive -> gain mp, negative -> lose mp)
  #--------------------------------------------------------------------------
  def mp_change(crit = false,mode=1)
    v = @effects_res[:mp]
    v -= dmg_value(crit,mode) if @item.damage.to_mp?
    return v
  end

  #--------------------------------------------------------------------------
  # method: returns 'main dmaage' amount and type. amount is the stat gain (or loss if < 0)
  # type (0 for hp, 1 for mp, nil for none of them) is the type of the item formula type
  # if item has no formula, then type is the highest absolute between hp and mp change, or nil both are 0
  #--------------------------------------------------------------------------
  def dmg_data
    hp = hp_change
    mp = mp_change
    return hp,0 if @item.damage.to_hp?
    return mp,1 if @item.damage.to_mp?
    return 0,nil if hp == mp && hp == 0
    return hp,0 if hp.abs >= mp.abs
    return mp,1
  end

  #--------------------------------------------------------------------------
  # method: color_dmg -> choose the color displayed on the dmg line based
  # on the 'main' affected stat and gain/or loss conditions.
  # Represents the color used by Sprite_DamagePreview
  #--------------------------------------------------------------------------
  def color_dmg
    v,t = dmg_data
    return Color.new unless t
    color = t == 0 ? [TBS::PREVIEW::COLOR_HP_HEAL,TBS::PREVIEW::COLOR_HP_DAMAGE] : [TBS::PREVIEW::COLOR_MP_HEAL,TBS::PREVIEW::COLOR_MP_DAMAGE]
    color = v > 0 ? color[0] : color[1]
    return color
  end

  #to display during preview_damage
  #--------------------------------------------------------------------------
  # method: to_str -> returns the string that will be displayed by Sprite_DamagePreview
  #--------------------------------------------------------------------------
  def to_str
    v,t = dmg_data
    return "" if v == 0
    args = [v.abs,@variance,(@touch_rate*100).to_i]
    return sprintf(TBS::PREVIEW::STR::DMG_NO_VAR,*args) unless @variance > 0
    return sprintf(TBS::PREVIEW::STR::DMG_VAR,*args)
  end

  #var is an integer % between -variance and +variance
  #the rule is (for 0 <= k <= n) P(X = k) = (n+1-k)/(n+1)^2
  #for k < 0, P(X = k) = P(X = -k)
  #P(X = n) = 1/(n+1)^2, P(X = 0) = 1/(n+1)
  def var_chance(var)
    return 0 if var.abs > @variance
    n = @variance
    ratio = 1.0 / (n+1)
    ratio *= ratio
    return (1 + n - var.abs) * ratio
  end

  def at_least_var_chance(var)
    n = @variance
    return 0 if var > n
    return 1 if var <= -n
    if var >= 0
      ratio = 1.0 / (n+1)
      ratio *= ratio
      k = n - var
      return 0.5 * (k+1) * (k+2) * ratio
    end
    #we search p(X >= k) for k < 0
    #by symmetry we have p(X = k) = p(X = -k)
    #we then deduce that P(X >= k) for k < 0
    #is the same as 1 - P(X > -k) which is 1-P(X >= -k +1)
    #not really convinced but pretty sure
    return 1 - at_least_var_chance(var.abs+1)
  end

  #return the probability (between 0 and 1) of killing the target in hp)
  def damage_kill_chance
    r = sub_damage_kill_chance(false)
    return r + (1-r) * @crit_rate * sub_damage_kill_chance(true)
  end


  def sub_damage_kill_chance(crit = false)
    dmg = -hp_change(crit).to_f
    return 0 if dmg <= 0 #heal or no damage case
    ratio = @tgt.hp/dmg * 100
    return 0 if ratio > 100+@variance #beyond the probability
    return at_least_var_chance(ratio.to_i - 100)
  end

  #--------------------------------------------------------------------------
  # method: added_states -> returns an array of states ids that can be added
  #--------------------------------------------------------------------------
  def added_states
    @effects_res[:removed_states].keys
  end

  #--------------------------------------------------------------------------
  # method: removed_states -> returns an array of states ids that can be removed
  #--------------------------------------------------------------------------
  def removed_states
    @effects_res[:removed_states].keys
  end

  #--------------------------------------------------------------------------
  # method: state_add_chance? -> return a value between 0 and 1 for the state to be added
  #--------------------------------------------------------------------------
  def state_add_chance?(state_id)
    return 0 if @tgt.state_resist?(state_id)
    rate = @effects_res[:added_states][state_id]
    rate = 0 unless rate
    return rate unless state_id == @tgt.death_state_id
    kill_rate = damage_kill_chance #when dealing damage
    return kill_rate + (1-kill_rate)*rate
  end
  #--------------------------------------------------------------------------
  # method: state_rm_chance? -> return a value between 0 and 1 for the state to be removed
  #--------------------------------------------------------------------------
  def state_rm_chance?(state_id)
    rate = @effects_res[:removed_states][state_id]
    rate = 0 unless rate
    return rate
  end

end #Preview_DamageData

#==============================================================================
# Scene_TBS_Battle
#==============================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # overwrite method: ai_handle_turn
  #--------------------------------------------------------------------------
  def ai_handle_turn
    ai = AI_HandlerBase.new(self)
    ai.decide_actions(@active_battlers)
    next_group_turn
  end
end #Scene_TBS_Battle

#==============================================================================
# Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # new method: get_ai_tactic (will be overriden below)
  #--------------------------------------------------------------------------
  def get_ai_tactic; TBS::AI::Default; end
  #--------------------------------------------------------------------------
  # new method: skill_cost_eval -> returns a numeric value from evaluating formula
  # with arguments s the skill and t the tactic object
  #--------------------------------------------------------------------------
  def skill_cost_eval(formula,s,t)
    eval(formula)
  end
end #Game_Battler

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # override method: get_ai_tactic
  #--------------------------------------------------------------------------
  def get_ai_tactic
    s = @states.find{|s| TBS.state_tactic(s)}
    return TBS.state_tactic(s) if s #priority to the states tactics
    t = TBS.actor_tactic(@actor_id)
    return t if t #then the actor's tactic
    return TBS.class_tactic(@class_id) #else the class
  end
end #Game_Actor

#==============================================================================
# Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # override method: get_ai_tactic
  #--------------------------------------------------------------------------
  def get_ai_tactic
    s = @states.find{|s| TBS.state_tactic(s)}
    return TBS.state_tactic(s) if s #priority to the states tactics
    return TBS.enemy_tactic(@enemy_id) #else the enemy
  end
end #Game_Enemy


#==============================================================================
# AI_HandlerBase
#==============================================================================
#AI_Handler choose the order of action of each battler
#The basic one is individualist : each battler plays with its own idea of best action
class AI_HandlerBase
  #--------------------------------------------------------------------------
  # initialize -> uses scene_tbs_battle to fetch it directly
  #--------------------------------------------------------------------------
  def initialize(scene_tbs_battle)
    @scene = scene_tbs_battle #usefull when wanting to fetch information
    @battlers = []
  end

  #--------------------------------------------------------------------------
  # decide_actions -> will choose and apply action for each battlers
  #--------------------------------------------------------------------------
  def decide_actions(bat_list)
    AI_BattlerBase.scene = @scene
    @battlers = bat_list
    for b in @battlers
      break if @scene.scene_changing?
      b.ai.decide_actions
    end
    AI_BattlerBase.scene = nil
  end
end

#==============================================================================
# AI_BattlerBase -> takes decisions for computer-controlled units
# their main method is decide_actions
#==============================================================================
class AI_BattlerBase
  #--------------------------------------------------------------------------
  # initialize -> stores the battler and loads its decision data for heuristics calculations
  #--------------------------------------------------------------------------
  def initialize(battler)
    @bat = battler
  end

  #--------------------------------------------------------------------------
  # scene -> to asks Scene_TBS_Battle directly
  #--------------------------------------------------------------------------
  def self.scene=(scene)
    @@scene = scene
  end

  #--------------------------------------------------------------------------
  # genTargetList
  #--------------------------------------------------------------------------
  # return a hash table {pos => [srcs]} such that skill may be cast on pos from any srcs
  #--------------------------------------------------------------------------
  def genTargetList(skill)
    targets = {}
    for src in @route.keys
      l = TBS.getTargetsList(@bat,POS.new(src[0],src[1]),@spellRg)
      for p in l
        targets[p] = [] unless targets[p]
        targets[p].push(src)
      end
    end
    return targets
  end

  #--------------------------------------------------------------------------
  # area_src_dependant?
  #--------------------------------------------------------------------------
  # asks if the area will change its shape depending on the src-target vector,
  # false values allows quickier computation
  #--------------------------------------------------------------------------
  def area_src_dependant?(area)
    return (TBS.directional_range_type?(area.range_type) && area.max_range > 0)
  end

  #--------------------------------------------------------------------------
  # skill_src_dependant?
  #--------------------------------------------------------------------------
  # for future compatibility like push/pull effects
  # asks if the position from where the spell is cast matters for the result
  #--------------------------------------------------------------------------
  def skill_src_dependant?(skill,area)
    return area_src_dependant?(area)
  end

  #--------------------------------------------------------------------------
  # ai_move
  #--------------------------------------------------------------------------
  # Moves the battler through route (array of directions) with cost cost
  # Wait for the end of effects
  #--------------------------------------------------------------------------
  def ai_move(route, cost, bat = @bat, scene = @@scene)
    bat.move_through_path(route,cost)
    scene.wait_for_effect
  end

  #--------------------------------------------------------------------------
  # ai_cast
  #--------------------------------------------------------------------------
  # bat (Game_Battler) cast the skill (RPG::Skill) to tgt ([x,y]), scene should be Scene_TBS_Battle
  #--------------------------------------------------------------------------
  def ai_cast(skill, tgt, bat = @bat, scene = @@scene)
    bat.input.set_skill(skill.id)
    bat.input.set_target(tgt)
    scene.process_tbs_action(bat)
    scene.wait_for_effect
  end

  #--------------------------------------------------------------------------
  # ai_move_cast
  #--------------------------------------------------------------------------
  # move throught the route then cast the skill
  #--------------------------------------------------------------------------
  def ai_move_cast(skill, tgt, route, cost, bat = @bat, scene = @@scene)
    ai_move(route,cost,bat,scene)
    ai_cast(skill,tgt,bat,scene)
  end

  #--------------------------------------------------------------------------
  # decide_actions
  #--------------------------------------------------------------------------
  # The main algorithm of AI_BattlerBase:
  # While the battler can play an action, will try to play to play one
  # (in take_action) until no skill is playable or no action is available
  # Then the battler will move to the best position it can reach and end
  # its turn.
  #--------------------------------------------------------------------------
  def decide_actions
    return unless @bat.movable?
    @tactic = @bat.get_ai_tactic
    #as long as I can do smthing I should check it
    while @bat.current_action
      return unless @bat.movable? #skip battlers turn that can't play
      break unless take_action #if nothing was played, then break loop
    end
    #find the best position to move before the end of your turn
    reach_best_position
  end
  #--------------------------------------------------------------------------
  # take_action
  #--------------------------------------------------------------------------
  # Generates all positions it can move to, then choose a skill to cast
  # through pick_action, go to the best position to cast the skill (usually
  # the closest in move points) and cast the skill. Returns true if an action
  # was made, false otherwise.
  #--------------------------------------------------------------------------
  def take_action
    #generates the move route:
    @route, @cost = @bat.calc_pos_move #get the move range
    @route.keep_if{|key, value| (key[0] == @bat.pos.x && key[1] == @bat.pos.y) || @bat.can_occupy?(key)}
    #pick a skill, its pos_target and the positions where the skill can be cast:
    skill, tgt, srcs = pick_action
    return false unless skill #break if no skill was picked
    best_src = pick_cast_position(srcs)
    return false unless best_src
    #cast the skill
    ai_move_cast(skill, tgt, @route[best_src],@cost[best_src], @bat, @@scene)
    return true
  end

  #--------------------------------------------------------------------------
  # pick_cast_position
  #--------------------------------------------------------------------------
  # Chooses the best position to go to cast the ability given an array of
  # valid positions to reach and cast it. Returns the position or nil if no
  # position was good (unlikely)
  #--------------------------------------------------------------------------
  def pick_cast_position(pos_list)
    best_src = nil
    src_rate = -1000000
    for src in pos_list
      r = rate_pos(src)
      if r > src_rate
        best_src = src
        src_rate = r
      end
    end
    return best_src #break if no source could be picked
  end

  #--------------------------------------------------------------------------
  # reach_best_position
  #--------------------------------------------------------------------------
  # Chooses the best position to reach this turn and move to it
  #--------------------------------------------------------------------------
  def reach_best_position
    #find a good position to end your turn
    @route, @cost = @bat.calc_pos_move(@tactic.move_range)
    @route.keep_if{|key, value| (key[0] == @bat.pos.x && key[1] == @bat.pos.y) || @bat.can_occupy?(key)}
    best_pos = nil
    pos_rate = -1000000
    for pos in @route.keys
      r = rate_pos(pos,true)
      if r > pos_rate
        best_pos = pos
        pos_rate = r
      end
    end
    return unless best_pos
    ai_move_best(best_pos,@bat, @@scene)
  end


  #--------------------------------------------------------------------------
  # ai_move_best
  #--------------------------------------------------------------------------
  # Move towards the target, takes alternative paths if the current one is
  # cut by units
  #--------------------------------------------------------------------------
  def ai_move_best(target,bat,scene)
    route, cost = @route[target],@cost[target]

    path = TBS_Path.new
    path.set_route(bat,[],0) #from the source
    #get the subroute that can be crossed in a single turn
    for d in route
      path.push_dir(d)
      if path.cost > bat.available_mov
        path.pop_dir
        break
      end
    end
    #checks if last cell is occupied
    tgt = path.dest
    return ai_move(route, cost, bat, scene) if bat.can_occupy?(tgt)
    #if last cell is occupied, look for a better cell and path by performing a reverse dijkstra:
    #a better cell is closer to the target position (so minimum distance by pathfinding)
    route_data2, cost_data2 = bat.reverse_calc_pos_move(target, cost) #bound the research by the shortest path)
    #remove occupied cells:
    cost_data2.keep_if{|p,c| (bat.can_occupy?(p) || (p[0] == bat.pos.x && p[1] == bat.pos.y)) && @cost[p] && @cost[p] <= bat.available_mov}
    return if cost_data2.empty?
    #pick the closest one to the target:
    tmp_target = cost_data2.min_by{|p,c| c}[0]
    route, cost = @route[tmp_target],@cost[tmp_target]
    ai_move(route, cost, bat, scene) if route
  end
  #--------------------------------------------------------------------------
  # pick_action
  #--------------------------------------------------------------------------
  # Choose a skill to cast and where, returns a triplet
  # skill, target, [srcs]
  # with:
  # -skill the skill chosen (RPG::Skill)
  # -target an [x,y] position to cast the skill to
  # -[srcs] an array of positions to move to before casting the skill
  # If no skill was chosen (none is available or good to cast), returns
  # nil, nil, []
  #--------------------------------------------------------------------------
  def pick_action
    TBS::AI::ALL_POSSIBILITIES ? pick_action_all : pick_action_weight
  end

  #--------------------------------------------------------------------------
  # pick_action_weight
  #--------------------------------------------------------------------------
  # Tries skills in a random way (based on weighted probabilities through
  # <ai_rating> or enemy's rating of skills) until one of them can be cast
  # in a good way (positive rating). returns a triplet:
  # skill, target, [srcs]
  #--------------------------------------------------------------------------
  def pick_action_weight
    skills_data = @bat.ai_usable_skills #get usable skills
    total_weight = skills_data.inject(0){|res, item| res += item[1]}
    while skills_data.size > 0
      #pick a random weighted skill and tries to play it
      v = rand(total_weight)
      selected_item = nil
      for item in skills_data
        selected_item = item
        v -= item[1]
        break if v < 0
      end
      skills_data.delete(selected_item)
      total_weight -= selected_item[1]
      rate, tgt, srcs = calc_skill(selected_item[0])
      return selected_item[0], tgt, srcs if rate > 0
    end
    return nil, nil, []
  end

  #--------------------------------------------------------------------------
  # pick_action_all
  #--------------------------------------------------------------------------
  # Same as pick_action_weight but instead will try all usable skills before
  # chosing the best skill and target based on rating, returns a triplet
  # skill, target, [srcs]
  #--------------------------------------------------------------------------
  def pick_action_all
    skills_data = @bat.ai_usable_skills #get usable skills
    best = skills_data.map {|s,r| calc_skill(s)+[s]}.max_by{|r,t,l,s| r}
    return best[3], best[1], best[2] if best[0] > 0
    return nil,nil,[] #no good choice
  end

  #--------------------------------------------------------------------------
  # calc_skill
  #--------------------------------------------------------------------------
  # Rates all possibilities when trying to cast the skill, returns a triplet
  # rate, target, [srcs]
  # With:
  # -rate the rating of the skill to cast to target
  # -target a position [x,y] to cast the skill to
  # -[srcs] an array if all possible positions to move before casting the skill
  # If no target is valid or 'interesting' (positive rate), returns
  # 0, nil, nil
  #--------------------------------------------------------------------------
  def calc_skill(skill)
    #puts sprintf("decide for %d", skill.id)
    @rate_preview = {}  #a hash table with Game_Battler => float (tgt => how great is taregting the battler)
    @skill_preview = {} #a hash table with Game_Battler => PreviewDamage_Data (tgt => effect to target)
    @bat.input.set_skill(skill.id)
    return 0, nil, nil unless @bat.current_action.valid?
    @spellRg = @bat.getRange(skill.id,:skill)
    targets = genTargetList(skill) #gets all uniq cells that can be targeted this turn
    #choose the best target if any
    best_tgt = nil
    best_rating = 0
    for tgt in targets.keys
      @bat.input.set_target(tgt)
      next unless @bat.current_action.tbs_tgt_valid?
      r = result_rate(skill,tgt,targets,best_rating)
      if r > best_rating
        best_tgt = tgt
        best_rating = r
      end
    end
    return best_rating, best_tgt, targets[best_tgt]
  end

  #============================================================================
  # The following methods are heuristics:
  # empiric ratings of choices for easier calculations, they will define what
  # the ais judge as good or bad choices, feel free to change them
  #============================================================================

  #--------------------------------------------------------------------------
  # result_rate_bat
  #--------------------------------------------------------------------------
  # first heuristic: rate for each affected battler how great (for the caster)
  # it is to affect them. The score returned will be added to the score of the
  # other affected battlers.
  # If score > 0 -> it is good to apply the ability to the battler
  # If score < 0 -> it is bad to apply the ability to the battler
  # If score == 0 -> it is equally good to not affect the battler as to affect it
  # The greater/lower the score, the more the battler will matter in the question of targeting it
  #--------------------------------------------------------------------------
  def result_rate_bat(skill,tgt_bat)
    return @rate_preview[tgt_bat] if @rate_preview[tgt_bat] #skip calculations if already performed
    res = result_rate_effects(skill,tgt_bat)
    res *= bat_rate_importance(tgt_bat)
    res *= bat_rate_relationship(tgt_bat)
    res *= skill.repeats
    return @rate_preview[tgt_bat] = res
  end


  #--------------------------------------------------------------------------
  # result_rate_effects
  #--------------------------------------------------------------------------
  # sub heuristic: rates for the targeted battler if the use of the skill will
  # help or harm it and how much.
  # If score > 0 -> it will help the target
  # If score < 0 -> it will harm the target
  # If score == 0 -> it won't affect the target significatively
  #--------------------------------------------------------------------------
  def result_rate_effects(skill,tgt_bat)
    @skill_preview[tgt_bat] = Preview_DamageData.new(tgt_bat,@bat,skill) unless @skill_preview[tgt_bat]
    prev = @skill_preview[tgt_bat]
    #damage
    crit = prev.crit_rate
    current_hp_r = tgt_bat.hp.to_f / tgt_bat.mhp
    hp_score = [[(prev.hp_change*(1-crit)+prev.hp_change(true)*crit) / tgt_bat.mhp, 1-current_hp_r].min,-current_hp_r].max #negative: hp_loss, ie harmful, expected value, in mhp%
    mp_score = 0
    if tgt_bat.mmp > 0
      current_mp_r = tgt_bat.mp.to_f / tgt_bat.mmp
      mp_score = [[(prev.mp_change*(1-crit)+prev.mp_change(true)*crit) / tgt_bat.mmp, 1-current_mp_r].min,-current_mp_r].max #negative: mp_loss, ie harmful, expected value, in mmp%
    end
    #states
    death_s = tgt_bat.death_state_id
    added_states = prev.added_states.select{|s| s != death_s} #exclude the kill case -> done separatly
    state_score = added_states.inject(0){|r,s| r + TBS.state_ai_rating(s) * prev.state_add_chance?(s)} #negative: bad states, ie harmful
    state_score -= prev.removed_states.inject(0){|r,s| r + TBS.state_ai_rating(s) * prev.state_rm_chance?(s)} #negative: good states, ie harmful
    state_score += prev.state_add_chance?(death_s) * @tactic.kill_aim * TBS.state_ai_rating(death_s) #kill should be negative as it is harmful ~
    #result
    res = hp_score * @tactic.hp + mp_score * @tactic.mp + state_score * @tactic.states
    #touch multiplier -> lower the score if the touch rate is low, see this as expectancy
    res *= prev.touch_rate
    return res
  end

  #--------------------------------------------------------------------------
  # bat_rate_importance
  #--------------------------------------------------------------------------
  # sub heuristic: rates how important is the battler, >= 0 value
  # the higher, the more it will matter (in a good or bad way) to affect the battler
  # depends from tgr (see threat), summon status or obstacle status
  #--------------------------------------------------------------------------
  def bat_rate_importance(tgt_bat)
    #threat multiplier
    threat_mul = @bat.threat_from(tgt_bat)
    threat_mul += @tactic.summoner_concern * tgt_bat.children.inject(0){|r,c| r + @bat.threat_from(c)}
    threat_mul *= @tactic.summon_mul if tgt_bat.parent #is summon
    threat_mul *= @tactic.obstacle_mul if tgt_bat.obstacle? #if obstacle
    return threat_mul
  end

  #--------------------------------------------------------------------------
  # bat_rate_relationship
  #--------------------------------------------------------------------------
  # sub heuristic: rates how the relationship matters:
  # > 0 means that the battler should be helped
  # < 0 means that the battler should be harmed
  # = 0 means that the battler can be ignored
  #--------------------------------------------------------------------------
  def bat_rate_relationship(tgt_bat)
    team_rel = @bat.friend_status(tgt_bat) #friendship is biased by confusion states
    return -@tactic.harm[team_rel]
  end

  #--------------------------------------------------------------------------
  # result_rate_src
  #--------------------------------------------------------------------------
  # second heuristic: rate the use of the skill applied to the target tgt from the source src
  # It is the sum of result_rate_bat on each affected battlers + other constraints like saving mana
  #--------------------------------------------------------------------------
  def result_rate_src(skill,tgt,src)
    @area = TBS.getArea(@bat,POS.new(src[0],src[1]),POS.new(tgt[0],tgt[1]),@spellRg) unless @area
    old_pos = @bat.pos
    @bat.moveto(src[0],src[1]) #go to the src for the sake of the simulation
    affected_bats = @bat.input.tbs_make_targets(@area)

    #if skill_rate_cost (usually < 0) outweight the sum of result_rate_bat, then
    #it is likely the skill won't be cast as the final result must be > 0 to be
    #considered in parent function
    #for safety measures, first call result_rate_bat before skill_rate_cost
    dmg = affected_bats.inject(0){|r,b| r+result_rate_bat(skill,b)}
    dmg *= skill.number_of_targets.to_f / affected_bats.size if skill.for_random? && !affected_bats.empty?
    score = skill_rate_cost(skill,tgt,src,affected_bats) + dmg

    @bat.moveto(old_pos[0],old_pos[1]) #restore my original position
    return score
  end

  #--------------------------------------------------------------------------
  # skill_rate_cost
  #--------------------------------------------------------------------------
  # sub heuristic: rates how the cost of the skill affects its casting (among
  # additional effects)
  # > 0 means that using the skill in term of cost is worth it (usually gain resources)
  # < 0 means that using the skill will cost resources
  # = 0 means that the skill is basically free (except the action price)
  #--------------------------------------------------------------------------
  def skill_rate_cost(skill,tgt,src,affected_bats)
    special_case = TBS.skill_cost_rating(skill.id)
    return @bat.skill_cost_eval(special_case,skill,@tactic) if special_case
    return 1 unless skill.for_friend? || skill.for_opponent? || !affected_bats.empty? #will consider the special case non-target skills as 'good choice'
    #get mp cost in mmp% (0 if mmp == 0)
    mp_per_cost = @bat.mmp > 0 ? @bat.skill_mp_cost(skill).to_f/@bat.mmp : 0
    score = -mp_per_cost * @tactic.mp_save
    #get tp cost and tp gained by skill in mtp% (0 if mtp == 0)
    if @bat.max_tp > 0
      tp_gain = affected_bats.inject(0) {|r,b| r + @skill_preview[b].touch_rate * skill.tp_gain * @bat.tcr}
      tp_gain *= skill.number_of_targets.to_f / affected_bats.size if skill.for_random? && !affected_bats.empty?
      tp_gain *= skill.repeats
      tp_gain -= @bat.skill_tp_cost(skill)
      tp_gain = [[tp_gain,@bat.max_tp-@bat.tp].min,-@bat.tp].max
      tp_per = tp_gain.to_f / @bat.max_tp
      score += tp_per * @tactic.tp_save
    end
    return score
  end

  #--------------------------------------------------------------------------
  # result_rate
  #--------------------------------------------------------------------------
  # third heuristic: rate the use of the skill applied to tgt
  # will consider each src from srcList and order them based on result_rate_src
  # Returns the best rating and filters the best positions to move to in order to cast it
  #--------------------------------------------------------------------------
  def result_rate(skill,tgt,targets_src_hash,current_best_rating = 0)
    best_srcs = []
    best_rate = current_best_rating
    @area = nil
    srcList = targets_src_hash[tgt]
    if !skill_src_dependant?(skill,@spellRg.area)
      src = srcList[0]
      @area = TBS.getArea(@bat,POS.new(src[0],src[1]),POS.new(tgt[0],tgt[1]),@spellRg)
      #case 0: in area, case 1: out of area
      srcCases = [[],[]]
      srcList.each{|s| @area.include?(s) ? srcCases[0].push(s) : srcCases[1].push(s)}
      #choose if it is better to be inside the range or out of it
      for l in srcCases
        next if l.empty?
        r = result_rate_src(skill,tgt,l[0])
        if r >= best_rate
          best_srcs = [] if r > best_rate
          best_srcs += l
          best_rate = r
        end
      end
    else #skill is src dependant
      for src in srcList
        @area = nil #recalculate
        r = result_rate_src(skill,tgt,src)
        if r >= best_rate
          best_srcs = [] if r > best_rate
          best_srcs.push(src)
          best_rate = r
        end
      end
    end
    targets_src_hash[tgt] = best_srcs unless best_srcs.empty? #filter the sources
    return best_rate
  end

  #--------------------------------------------------------------------------
  # rate_pos
  #--------------------------------------------------------------------------
  # fourth and last heuristic: rate how great reaching/being at pos is
  # This rate will be affected by the remaining move_points
  # (keeping move points is good if the battler may still move afterwards)
  # If last_move is true, then the remaning move points do not matter as this
  # will be the last time this turn the battler moves
  #--------------------------------------------------------------------------
  def rate_pos(pos,last_move = false)
    threat_eval = @@scene.tactics_all.inject(0) do |r,b|
      next r unless b.alive? && b != @bat
      rel = @bat.friend_status(b)
      dist = (b.pos - POS.new(pos[0],pos[1])).manathan_norm
      #next r+@tactic.view_range* if dist > @tactic.view_range #exclude out of range battlers
      min_d, max_d = @tactic.safe_distance[rel]
      next r if dist >= min_d && dist <= max_d #battlers in safe distance are counted as 0
      th = @bat.threat_from(b) * @tactic.unsafe_distance_rate[rel]
      delta = dist < min_d ? min_d-dist : dist-max_d
      delta = dist-@tactic.view_range if dist > @tactic.view_range
      r + delta*th #add threat_level + distance
    end
    c = @cost[pos]
    return threat_eval if last_move || c.nil?
    return threat_eval + (@bat.available_mov - c)*@tactic.move_save
  end
  #============================================================================
  # AI design discussion
  #--------------------------------------------------------------------------
  # The default ai first picks the ability before selecting the 'best' target,
  # this is closer to rpg maker vanilla and therefore easier to play with as a maker
  #
  # However, this might lead to dumb ais that may play bad spells (because of probabilities)
  # There are other solutions:
  # -ais that first pick a target, then choose the best skill to affect the target
  # => this makes ais more consistent but you lose the rpg maker randomness,
  # meaning that the smartness of an ai is only defined by the heuristics,
  # risky unless the heuristics are well designed
  # -ais that tests for all skills the result of the skill and each possible target:
  # => This might be performance heavy, but with the right heuristics this one
  # could make great ais, however this requires special heuristics for unique
  # skills (like common-event calling skills)
  # -ais with planification over multiple turns
  # => even better as they might not do heavy calculations every turn, but you have to define a notion of goal and to define if a goal should be changed by battle situations
  #============================================================================
end #AI_BattlerBase
