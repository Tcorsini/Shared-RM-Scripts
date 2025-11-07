#==============================================================================
# TBS Animated Poses v1.0
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 07/11/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-AnimatedPoses"] = true
if $imported["TIM-TBS-AnimatedPoses"]

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 07/11/2025: v1.0 - first version
#==============================================================================
# Description
#------------------------------------------------------------------------------
# Provides basic features regarding sprite poses during TBS.
# You can use bigger spritesheets to have multiple poses (idle, moving, attack,
# dodge, cast, defeated,...)
# The poses will be called by the battle effects or abilities.
#
# How to use:
# During TBS, given a charset with name charset_name, the system will first
# look for it in Graphics/Battlers/TBS_BAT_FOLDER.
# If the charset exists here, it will use it and consider it to have multiple
# poses. Otherwise, it will use the charset with the same name in
# Graphics/Charracters and will act as the default system (no poses, and look
# for "charset_name_down" when defeated).
#
# Your spritesheet will follow the same naming rule as rpg maker:
# $ for a single character on the sprite
# ! to not gice any vertical offset to the sprite
# The spritesheet is divided into columns and rows, each cell defining a column
# of 4 sprites (one in each direction like in rpg maker) that will then be
# divided by the system based on the direction of the battler.
#
# You can define in constants ROWS (y dimension) and COLUMNS (x dimension),
# the dimensions of each spritesheet. For instance, if your spritesheet is a
# default rpg maker spritesheet, then you should use  ROWS = 1, COLUMNS = 3.
#
# You can define dimensions exceptions for a given filename by setting it in
# POSE_DIMENSIONS_EXCEPTIONS
# For instance POSE_DIMENSIONS_EXCEPTIONS["zombie"] = [5,2]
# Will set 5 rows and 2 columns to the zombie sprite instead of the constants
# above.
#
# Once your dimensions are set, you should try to harmonize as much as possible
# your spritesheets and set the poses in poses:
# POSES[:pose_symb] = [[row,column,frames],[row2,column2,frames2],...]
# This set the pose with reference :pose_symb as a sequence of sprites from
# the spritesheet with frames the time staying as such sprite before going to
# the next one.
#
# You can also define exceptions given filenames in POSES_EXCEPTIONS, for
# instance:
# POSES_EXCEPTIONS["zombie"] = {:idle => [[0,0,10],[0,1,20],[0,2,10]],
#                               :miss => [[1,1,10],[1,2,15]],
# }
# Will change the poses :idle and :miss for the spritesheet named "zombie".
#
# List of default poses:
# Idle poses (looping and depends on the battler or charset states):
# - :idle (alive, doing nothing) [MANDATORY]
# - :walk (the character is moving)
# - :jump (the character is jumping)
# - :dying (the battler is alive with less than DYING_HP_PER% hps)
# - :dead (the battler is dead)
#
# Other handled poses:
# - :cast (the default pose when using an ability)
# - :hurt (when damaged)
# - :death (when killed)
# - :miss (when opponent's ability missed)
# - :dodge (when opponent's ability is evaded)
# - :magic_dodge (when opponent's ability is magically evaded)
#
# You can create as many poses as you want and set them to be the poses for
# abilities like this in their notetags:
# <cast_pose = :symb>
# <end_pose = :symb>
#
# You may define pose aliases to handle specific poses based on the context,
# for instance if pose :attack is aliased to :spear, whenever the :attack pose
# is called on the battler, it will call the :spear pose instead.
# You can set an alias in actors, classes, enemies, states, or equipment
# notetags like this:
# <pose_alias :attack = :spear>
#
# The pose alias priority will be:
# for actors:
# state (by priority) > weapon (by weapon order) > armor > actor > class
# for enemies:
# state (by priority) > enemy
#
# Whenever a pose is played (except idle poses), a sound or an animation may
# be played on the battler (currently no timing offset is supported), you can
# link a sound to a pose like this:
# <pose_sound :pose = ["filename", volume, pitch]>
# (works in actors, enemies, class, weapons, armor and states notetags)
#
# And an animation_id (from the database) to a pose like this:
# <pose_anim_id :pose = id>
#
# The pose_anim_id is nil if none is provided and won't do anything
# The pose_sound is silent for most :pose except for
# - :hurt which will use the default damage sound from the database
# - :death which will use the default collapse sound from the database
# (see method play_tbs_sound)
#
# You may also use script calls to set the pose_sound or pose_anim_id of a
# battler bat, they will overtake any automatic value like this:
# (volume and pitch are optionnal)
#  bat.set_tbs_anim_sound(:pose_symb, filename, volume, pitch)
#  bat.set_tbs_anim_id(:pose_symb, anim_id)
#
# You may also remove the values like this:
#  bat.clear_tbs_anim_sound(:pose_symb)
#  bat.clear_tbs_anim_id(:pose_symb)
#
# Or reset every set sound and anim_ids with:
#  bat.clear_tbs_anim_sounds
#  bat.clear_tbs_anim_ids
#==============================================================================
# Installation: put it below TBS core
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

module TBS
  #% of hp remaining to replace the idle pose of battlers by :dying
  DYING_HP_PER = 25

  module ANIM
    #name of the folder inside Graphics/Battlers that contains the full battler
    #poses (leave empty string if no subfolder)
    TBS_BAT_FOLDER = "TBS/"
    #Your animation files must follow the same format:
    COLUMNS = 13 #number of columns in your battler spritesheet
    ROWS = 15    #number of rows in your battler spritesheet (note: each row is
                 # 4 directions so it has 4 sub rows)

    #activate this if you cosndier that the directions of the pose file are
    #in LPC order (up,left,down,right)
    #set this to false to follow the default rpg maker directions
    #(down,left,right,up)
    LPC_DIRECTIONS = true

    #each pose is an array of [row,column,frames]
    #if a symbol is not found, it will take the default_pose_symb(symb),
    #the very default pose is :idle, don't remove it!
    POSES = {
      #:pose => [[row, column, frames], ... ],
      #idle (looping) poses:
      :idle => [ [7,0,10] , [7,1,10]],# , [0,2,10] ], #DO NOT REMOVE THE :idle LINE!
      :walk  => [ [2,0,10] , [2,1,10] , [2,2,10], [2,3,10], [2,4,10], [2,5,10], [2,6,10], [2,7,10], [2,8,10] ],
      :jump => [[8,2,1]],
      :dead => [ [5,5,10] ],
      #:dying => [ [0,0,10] , [0,1,10] , [0,2,10] ],

      #system poses:
      :cast => [ [0,0,10] , [0,1,10] , [0,2,10], [0,3,10], [0,4,10], [0,5,10], [0,6,10] ],
      #:dodge => [ [0,1,10] ],
      #:magic_dodge => [ [0,1,10] ],
      #:miss => [ [0,1,10] ],
      #:hurt => [ [0,0,10] , [0,1,10] , [0,2,10] ],
      :death => [ [5,0,10] , [5,1,5], [5,2,20], [5,3,5], [5,4,5], [5,5,5]],

      #custom poses;
      :attack => [ [3,0,5], [3,1,5], [3,2,5], [3,3,10], [3,4,5], [3,5,5],],
      :bow => [[4,0,5], [4,1,5], [4,2,5], [4,3,10], [4,4,5], [4,5,5],
               [4,6,5], [4,7,5], [4,8,20], [4,9,5], [4,10,5], [4,11,5],
               [4,12,15],],
    } #POSES

    #if you want some battler pose files to follow different number of columns and rows
    #from [ROWS,COLUMNS]: (filename excludes folder prefix)
    POSE_DIMENSIONS_EXCEPTIONS = {
      #filename => [rows, columns]
    } #POSE_DIMENSIONS_EXCEPTIONS

    #if you want some battler pose files to follow different pose arrays
    #from POSES (note that if a pose does not exist here, it
    #will take the pose array from POSES)
    #(filename excludes folder prefix)
    POSES_EXCEPTIONS = {
      #filename => {
      #   symb => array,
      #   ....
      #   symb => array,
      #},
    } #POSES_EXCEPTIONS

#============================================================================
# Don't edit anything past this, unless you know what you are doing!
#============================================================================
    #--------------------------------------------------------------------------
    # method: idle_symb -> automatic pose symbol of the battler when it is not
    # doing a specific pose
    #--------------------------------------------------------------------------
    def self.idle_symb(bat)
      return :dead if bat.dead?
      return :jump if bat.char.jumping?
      return :walk if bat.char.moving?
      return :dying if bat.dying?
      :idle
    end
    #--------------------------------------------------------------------------
    # method: pose_dimensions -> returns the [rows,column] dimensions of the
    # spritesheet
    #--------------------------------------------------------------------------
    def self.pose_dimensions(filename)
      r = POSE_DIMENSIONS_EXCEPTIONS[filename]
      r ? r : [ROWS,COLUMNS]
    end
    #--------------------------------------------------------------------------
    # method: default_pose_symb -> replace a symbol by another if no pose with
    # the original symbol was found
    #--------------------------------------------------------------------------
    #may be called mutliple times in a row, make sure it does not loop!
    #only used to find a proper pose array, does not overtake sounds or
    #animations displayed
    def self.default_pose_symb(symb)
      case symb
      when :magic_dodge
        return :dodge
      when :dodge
        return :miss
      end
      :idle
    end
    #--------------------------------------------------------------------------
    # method: pose_array -> get the sequence of sprites given a filename and
    # a pose symbol
    #--------------------------------------------------------------------------
    def self.pose_array(filename,symb)
      r = POSES_EXCEPTIONS[filename]
      return r[symb] if r && r[symb]
      return POSES[symb] if symb == default_pose_symb(symb)
      POSES[symb] ? POSES[symb] : pose_array(filename,default_pose_symb(symb))
    end
    #--------------------------------------------------------------------------
    # method: dir_to_lpc -> called if LPC_DIRECTIONS is true
    #--------------------------------------------------------------------------
    #2,4,6,8 -> 6,4,8,2
    def self.dir_to_lpc(dir)
      l = [6,4,8,2]
      l[(dir-2)/2]
    end
  end #ANIM

  module REGEXP
    CAST_POSE = /^<cast_pose\s*=\s*(:.+)\s*>/i
    POST_ANIM_POSE = /^<end_pose\s*=\s*(:.+)\s*>/i
    #AFFECTED_POSE = /^<affected_anim\s*=\s*(:.+)\s*>/i

    POSE_SOUNDS = /^<pose_sound\s+(:\w+)\s*=\s*(\[.+\s*,\s*\d+\s*,\s*\d+\s*\])\s*>/i
    POSE_ANIM_IDS = /^<pose_anim_id\s+(:\w+)\s*=\s*(\d+)\s*>/i
    POSE_ALIAS = /^<pose_alias\s+(:\w+)\s*=\s*(:\w+)\s*>/i
  end #REGEXP
end #TBS

#============================================================================
# SNC from Simple Notetag Config
#============================================================================
module SNC
  #--------------------------------------------------------------------------
  # alias method: prepare_metadata
  #--------------------------------------------------------------------------
  class <<self; alias prepare_metadata_tbs_anim prepare_metadata; end
  def self.prepare_metadata
    prepare_metadata_tbs_anim
    Notetag_Data.new(:cast_anim,     :cast,  TBS::REGEXP::CAST_POSE,     ).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ENEMIES)
    Notetag_Data.new(:post_anim,       nil,  TBS::REGEXP::POST_ANIM_POSE,).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ENEMIES)
    #Notetag_Data.new(:affected_anim,   nil,  TBS::REGEXP::AFFECTED_POSE, 1).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ENEMIES)
    Notetag_Data.new(:anim_sounds,      {},  TBS::REGEXP::POSE_SOUNDS,   3).add_to(DATA_ACTORS,DATA_CLASSES,DATA_SKILLS,DATA_ITEMS,DATA_STATES,DATA_ENEMIES)
    Notetag_Data.new(:anim_ids,         {},  TBS::REGEXP::POSE_ANIM_IDS, 3).add_to(DATA_ACTORS,DATA_CLASSES,DATA_SKILLS,DATA_ITEMS,DATA_STATES,DATA_ENEMIES)
    Notetag_Data.new(:pose_alias,       {},  TBS::REGEXP::POSE_ALIAS,    3).add_to(DATA_ACTORS,DATA_CLASSES,DATA_WEAPONS,DATA_ARMORS,DATA_STATES,DATA_ENEMIES)
  end #prepare_metadata
end #SNC

#==============================================================================
# Game_Battler
#==============================================================================
class Game_Battler
  #--------------------------------------------------------------------------
  # alias method: initialize -> now stores animation sounds and ids exception
  # (set by event calls)
  #--------------------------------------------------------------------------
  alias tbs_anim_bat_initialize initialize
  def initialize
    @anim_sounds = {}
    @anim_ids = {}
    tbs_anim_bat_initialize
  end
  #--------------------------------------------------------------------------
  # new method: set_tbs_anim_id
  #--------------------------------------------------------------------------
  def set_tbs_anim_id(symb, anim_id)
    @anim_ids ||= {}
    return @anim_ids.delete(symb) if anim_id.nil?
    @anim_ids[symb] = anim_id
  end
  #--------------------------------------------------------------------------
  # new method: clear_tbs_anim_sound
  #--------------------------------------------------------------------------
  def clear_tbs_anim_id(symb)
    set_tbs_anim_id(symb,nil)
  end
  #--------------------------------------------------------------------------
  # new method: clear_tbs_anim_ids
  #--------------------------------------------------------------------------
  def clear_tbs_anim_ids
    @anim_ids = {}
  end
  #--------------------------------------------------------------------------
  # new method: set_tbs_anim_sound
  #--------------------------------------------------------------------------
  def set_tbs_anim_sound(symb, sound, volume = 100, pitch = 100)
    @anim_sounds ||= {}
    return @anim_sounds.delete(symb) if sound.nil?
    @anim_sounds[symb] = [sound, volume, pitch]
  end
  #--------------------------------------------------------------------------
  # new method: clear_tbs_anim_sound
  #--------------------------------------------------------------------------
  def clear_tbs_anim_sound(symb)
    set_tbs_anim_sound(symb,nil)
  end
  #--------------------------------------------------------------------------
  # new method: clear_tbs_anim_ids
  #--------------------------------------------------------------------------
  def clear_tbs_anim_sounds
    @anim_sounds = {}
  end
  #--------------------------------------------------------------------------
  # new method: tbs_anim_id -> return an animatio id to play, nil otherwise
  #--------------------------------------------------------------------------
  def tbs_anim_id(symb)
    @anim_ids[symb]
  end
  #--------------------------------------------------------------------------
  # new method: make_sound_of -> turns an array (if it exists) into a SE object
  #--------------------------------------------------------------------------
  def make_sound_of(l)
    return l ? RPG::SE.new(*l) : nil
  end
  #--------------------------------------------------------------------------
  # new method: tbs_anim_sound -> return a sound file (SE) to play, nil
  # otherwise
  #--------------------------------------------------------------------------
  def tbs_anim_sound(symb)
    return make_sound_of(@anim_sounds[symb])
  end
  #--------------------------------------------------------------------------
  # new method: play_tbs_sound -> play a sound linked to the symbol, otherwise
  # the default system sounds (if elligeble)
  #--------------------------------------------------------------------------
  def play_tbs_sound(symb)
    s = tbs_anim_sound(symb)
    return s.play if s
    case symb
    when :hurt
      actor? ? Sound.play_actor_damage : Sound.play_enemy_damage
    when :death
      if actor?
        Sound.play_actor_collapse
      else
        case collapse_type
        when 0
          Sound.play_enemy_collapse
        when 1
          Sound.play_boss_collapse1
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # new method: dying? -> if the battler is damaged enough, it will be under
  # the dying 'state', only for display purpose
  #--------------------------------------------------------------------------
  def dying?
    alive? && 100*(hp.to_f / mhp) <= TBS::DYING_HP_PER
  end
  #--------------------------------------------------------------------------
  # new method: set_pose -> creates a new pose handled by char and return it
  #--------------------------------------------------------------------------
  def set_pose(pose_symb,loop_pose=false)
    loop_pose ? @char.loop_pose(pose_symb) : @char.set_pose(pose_symb)
  end
  #--------------------------------------------------------------------------
  # new method: play_pose -> called to do set pose and other things
  #--------------------------------------------------------------------------
  def play_pose(pose_symb,loop_pose=false)
    return unless pose_symb
    pose_symb = pose_alias(pose_symb)
    play_tbs_sound(pose_symb)
    anim_id = tbs_anim_id(pose_symb)
    @animation_id = anim_id if anim_id
    set_pose(pose_symb,loop_pose)
  end
  #--------------------------------------------------------------------------
  # new method: pose_alias -> given a pose_symb (usually given by an
  # ability), return a pose_symb that actually represents what pose is used
  # (useful essentially for weapons)
  #--------------------------------------------------------------------------
  def pose_alias(pose_symb)
    pose_symb
  end
  #--------------------------------------------------------------------------
  # new method: perform_damage_effect (will replace actor/enemy damage effects)
  #--------------------------------------------------------------------------
  def perform_damage_effect
    play_pose(:hurt) #sound will be handled by play_pose
    @sprite_effect_type = :blink unless $imported["YEA-BattleEngine"] && !YEA::BATTLE::BLINK_EFFECTS
    if enemy? && !($imported["YEA-BattleEngine"] && !YEA::BATTLE::SCREEN_SHAKE)
      $game_troop.screen.start_shake(5, 5, 10)
    end
  end
  #--------------------------------------------------------------------------
  # new method: perform_collapse_effect (will replace actor/enemy collapse
  # effects)
  #--------------------------------------------------------------------------
  def perform_collapse_effect
    return unless $game_party.in_battle
    play_pose(:death)
    case collapse_type
    when 0
      @sprite_effect_type = :collapse
    when 1
      @sprite_effect_type = :boss_collapse
    when 2
      @sprite_effect_type = :instant_collapse
    end
  end
end #Game_Battler

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # override method: tbs_anim_sound
  #--------------------------------------------------------------------------
  def tbs_anim_sound(symb)
    r = super
    return r if r
    l = states.collect{|s|  make_sound_of(s.anim_sounds[symb])}.compact
    return l.first unless l.empty?
    r = make_sound_of(actor.anim_sounds[symb])
    return r if r
    return make_sound_of(self.class.anim_sounds[symb])
  end
  #--------------------------------------------------------------------------
  # override method: tbs_anim_id
  #--------------------------------------------------------------------------
  def tbs_anim_id(symb)
    r = super
    return r if r
    l = states.collect{|s| s.anim_ids[symb]}.compact
    return l.first unless l.empty?
    return actor.anim_ids[symb] if actor.anim_ids[symb]
    return self.class.anim_ids[symb]
  end
  #--------------------------------------------------------------------------
  # alias method: perform_damage_effect (call parent)
  #--------------------------------------------------------------------------
  alias tbs_anim_actor_perform_damage_effect perform_damage_effect
  def perform_damage_effect
    return tbs_anim_actor_perform_damage_effect unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end
  #--------------------------------------------------------------------------
  # alias method: perform_collapse_effect (call parent)
  #--------------------------------------------------------------------------
  alias tbs_anim_actor_perform_collapse_effect perform_collapse_effect
  def perform_collapse_effect
    return tbs_anim_actor_perform_collapse_effect unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end
  #--------------------------------------------------------------------------
  # override method: pose_alias
  #--------------------------------------------------------------------------
  def pose_alias(pose_symb)
    l = states.collect{|s| s.pose_alias[pose_symb]}.compact
    return l.first unless l.empty?
    l = weapons.collect{|w| w.pose_alias[pose_symb]}.compact
    return l.first unless l.empty?
    l = armors.collect{|a| a.pose_alias[pose_symb]}.compact
    return l.first unless l.empty?
    r = actor.pose_alias[pose_symb]
    return r if r
    r = self.class.pose_alias[pose_symb]
    return r if r
    pose_symb
  end
end #Game_Actor

#==============================================================================
# Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # override method: tbs_anim_sound
  #--------------------------------------------------------------------------
  def tbs_anim_sound(symb)
    r = super
    return r if r
    l = states.collect{|s|  make_sound_of(s.anim_sounds[symb])}.compact
    return l.first unless l.empty?
    return make_sound_of(enemy.anim_sounds[symb])
  end
  #--------------------------------------------------------------------------
  # override method: tbs_anim_id
  #--------------------------------------------------------------------------
  def tbs_anim_id(symb)
    r = super
    return r if r
    l = states.collect{|s| s.anim_ids[symb]}.compact
    return l.first unless l.empty?
    return enemy.anim_ids[symb]
  end
  #--------------------------------------------------------------------------
  # alias method: perform_damage_effect (call parent)
  #--------------------------------------------------------------------------
  alias tbs_anim_enemy_perform_damage_effect perform_damage_effect
  def perform_damage_effect
    return tbs_anim_enemy_perform_damage_effect unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end
  #--------------------------------------------------------------------------
  # alias method: perform_collapse_effect (call parent)
  #--------------------------------------------------------------------------
  alias tbs_anim_enemy_perform_collapse_effect perform_collapse_effect
  def perform_collapse_effect
    return tbs_anim_enemy_erform_collapse_effect unless SceneManager.scene_is?(Scene_TBS_Battle)
    super
  end
  #--------------------------------------------------------------------------
  # override method: pose_alias
  #--------------------------------------------------------------------------
  def pose_alias(pose_symb)
    l = states.collect{|s| s.pose_alias[pose_symb]}.compact
    return l.first unless l.empty?
    r = enemy.pose_alias[pose_symb]
    return r if r
    pose_symb
  end
end #Game_Enemy

#==============================================================================
# TBS_AnimationBase -> superclass of animations of tbs battlers
#==============================================================================
class TBS_AnimationBase
  #array is a list of commands to use
  def initialize(array = [])
    @array = array
    @frame_count = 0
    @pointer = -1
  end
  #called once per frames (except for main animations)
  def update
    @frame_count += 1
  end
  #is the animation over?
  def done?
    @pointer >= @array.size
  end
  def running?; !done?; end
  def current_step; @array[@pointer]; end
  #for compatibility:
  def dispose; @pointer = @array.size; end
  def disposed?; done?; end
end #TBS_AnimationBase

#==============================================================================
# TBS_PoseHandler -> handle non-looping pose of a battler sprite
#==============================================================================
class TBS_PoseHandler < TBS_AnimationBase
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(char,battler,animation_symb)
    @char = char
    @bat = battler
    super()
    set_animsymb(animation_symb)
  end
  #--------------------------------------------------------------------------
  # new method: set_animsymb -> set the pose to animation_symb
  #--------------------------------------------------------------------------
  def set_animsymb(animation_symb)
    @anim_symb = animation_symb
    @array = pose_list(@anim_symb)
  end
  #--------------------------------------------------------------------------
  # new method: get the pose list of the current character
  #--------------------------------------------------------------------------
  def pose_list(symb)
    TBS::ANIM.pose_array(@char.character_name,symb)
  end
  #--------------------------------------------------------------------------
  # new method: reset -> restart the pose
  #--------------------------------------------------------------------------
  def reset
    on_new_pose(0)
  end
  #--------------------------------------------------------------------------
  # new method: update_graphic_data -> called if the sprite file changes
  #--------------------------------------------------------------------------
  def update_graphic_data
    poses = pose_list(@anim_symb)
    if poses != @array
      @array = poses
      reset
    end
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    return if done?
    on_new_pose(0) if @pointer < 0 #activate it a first time here
    super #update frame count
    on_new_pose(@pointer+1) if @frame_count >= wait_time
  end
  #--------------------------------------------------------------------------
  # new method: on_new_pose -> proceeds to a new pose frame
  #--------------------------------------------------------------------------
  def on_new_pose(p)
    @pointer = p
    @frame_count = 0
    #@bat.set_pose(@anim_symb, *sprite_coords)
  end
  #--------------------------------------------------------------------------
  # new method: current_pose -> current pose frame (coordinates in file +
  # frame count)
  #--------------------------------------------------------------------------
  def current_pose; @array[@pointer]; end
  #--------------------------------------------------------------------------
  # new method: sprite_coords -> coordinates for the sprite to use
  #--------------------------------------------------------------------------
  def sprite_coords
    [current_pose[0], current_pose[1]]
  end
  #--------------------------------------------------------------------------
  # new method: wait_time -> number of frames to wait before changing pose
  # frame
  #--------------------------------------------------------------------------
  def wait_time; current_pose[2]; end
end #TBS_PoseHandler

#==============================================================================
# TBS_IdlePoseHandler -> handles looping poses of a battler sprite
#==============================================================================
class TBS_IdlePoseHandler < TBS_PoseHandler
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(char,battler)
    anim_s = :idle
    super(char,battler,anim_s)
  end
  #--------------------------------------------------------------------------
  # new method: force_pose -> fix the pose to pose_symb
  #--------------------------------------------------------------------------
  def force_pose(pose_symb)
    @forced_pose = pose_symb
  end
  #--------------------------------------------------------------------------
  # new method: forced_pose?
  #--------------------------------------------------------------------------
  def forced_pose?
    @forced_pose
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    idle_symb = @forced_pose
    idle_symb = TBS::ANIM.idle_symb(@bat) unless @forced_pose
    if idle_symb != @anim_symb
      set_animsymb(idle_symb)
      reset
    end
    super
    reset if done? #loop the animation
  end
end #TBS_IdlePoseHandler

#==============================================================================
# Game_Character_TBS -> handles poses
#==============================================================================
class Game_Character_TBS < Game_Character
  attr_reader :posehandler
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tbs_animpose_initialize initialize
  def initialize(bat)
    tbs_animpose_initialize(bat)
    @idle_posehandler = TBS_IdlePoseHandler.new(self,@battler)
    @posehandler = nil
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias anim_update update
  def update
    anim_update
    update_posehandler if SceneManager.scene_is?(Scene_TBS_Battle)
  end
  #--------------------------------------------------------------------------
  # new method: set_pose -> creates a new pose handled by char and return it
  #--------------------------------------------------------------------------
  def set_pose(pose_symb)
    @posehandler.dispose if @posehandler
    return @posehandler = TBS_PoseHandler.new(self,@battler,pose_symb)
  end
  #--------------------------------------------------------------------------
  # new method: loop_pose -> force the idle pose to use this pose, return the
  # idle pose handler
  #--------------------------------------------------------------------------
  def loop_pose(pose_symb)
    @idle_posehandler.force_pose(pose_symb)
    @idle_posehandler
  end
  #--------------------------------------------------------------------------
  # new method: forced_pose?
  #--------------------------------------------------------------------------
  def forced_pose?
    @idle_posehandler.forced_pose?
  end
  #--------------------------------------------------------------------------
  # new method: unloop_pose
  #--------------------------------------------------------------------------
  def unloop_pose
    @idle_posehandler.force_pose(nil)
  end
  #--------------------------------------------------------------------------
  # new method: current_posehandler
  #--------------------------------------------------------------------------
  def current_posehandler
    @posehandler ? @posehandler : @idle_posehandler
  end
  #--------------------------------------------------------------------------
  # new method: update_pos_handler
  #--------------------------------------------------------------------------
  def update_posehandler
    current_posehandler.update
    if @posehandler && @posehandler.done?
      @posehandler = nil
      @idle_posehandler.reset
    end
  end
  #--------------------------------------------------------------------------
  # new method: pose_coords -> return [x,y] to get as a char
  #--------------------------------------------------------------------------
  def pose_coords
    current_posehandler.sprite_coords
  end
  #--------------------------------------------------------------------------
  # override method: set_graphic
  #--------------------------------------------------------------------------
  def set_graphic(character_name, character_index)
    super(character_name, character_index)
    @idle_posehandler.update_graphic_data
    @posehandler.update_graphic_data(character_name) if @posehandler
  end
end #Game_Character_TBS

#==============================================================================
# Sprite_Character_TBS -> supports poses (logic is left to the battler)
# also handles the offset positions from Game_Character
#==============================================================================
class Sprite_Character_TBS < Sprite_Character
  attr_reader :use_pose_bat #checks if battler allows poses
  #--------------------------------------------------------------------------
  # class variables
  #--------------------------------------------------------------------------
  #available_battlers is used to Cache which battlers exist or not for multi-format availability
  @@available_battlers = Hash.new { |h, k|
    begin
      Cache.battler(k,0)
      h[k] = true
    rescue Errno::ENOENT
      h[k] = false
    end
  }
  #--------------------------------------------------------------------------
  # new method: tbs_battler_available? to read the hash table
  #--------------------------------------------------------------------------
  def tbs_battler_available?(name)
    @@available_battlers[name]
  end
  #--------------------------------------------------------------------------
  # new method: bat_char_name -> adds the folder
  #--------------------------------------------------------------------------
  def bat_char_name
    TBS::ANIM::TBS_BAT_FOLDER + @character_name
  end
  #--------------------------------------------------------------------------
  # alias method: set_bitmap -> load pose file if any, else use the original char
  #--------------------------------------------------------------------------
  alias anim_set_bitmap set_bitmap
  def set_bitmap
    @use_pose_bat = tbs_battler_available?(bat_char_name)
    return anim_set_bitmap unless @use_pose_bat
    @fixed_index = nil
    @displayed_name = @character_name #for compatibility
    self.bitmap = Cache.battler(bat_char_name, hue)
    @pose_dim = TBS::ANIM.pose_dimensions(@character_name)
    @pose_dim = [@pose_dim[1],@pose_dim[0]]
  end

  #--------------------------------------------------------------------------
  # alias method: set_bitmap_name
  #--------------------------------------------------------------------------
  alias anim_set_bitmap_name set_bitmap_name
  def set_bitmap_name
    @use_pose_bat ? @character_name : anim_set_bitmap_name
  end
  #--------------------------------------------------------------------------
  # override method: set_bitmap_position -> deals with own dimensions when in
  # pose mode
  #--------------------------------------------------------------------------
  def set_bitmap_position
    return super unless @use_pose_bat
    @dim_w = @pose_dim[0]
    @dim_h = @pose_dim[1]*4
    sign = get_sign
    if sign && sign.include?('$')
      @cw = bitmap.width / @dim_w
      @ch = bitmap.height / @dim_h
    else
      @cw = bitmap.width / (@dim_w * 4)
      @ch = bitmap.height / (2*@dim_h)
    end
    self.ox = @cw / 2
    self.oy = @ch
  end
  #--------------------------------------------------------------------------
  # alias method: update_src_rect
  #--------------------------------------------------------------------------
  alias anim_update_src_rect update_src_rect
  def update_src_rect
    return anim_update_src_rect unless @use_pose_bat
    index = @character.character_index
    pose_h, pose_w = @character.pose_coords
    #pose_w = pattern = @character.pattern < 3 ? @character.pattern : 1
    #pose_h = 0
    d = @character.direction
    d = TBS::ANIM.dir_to_lpc(d) if TBS::ANIM::LPC_DIRECTIONS

    sx = (index % 4 * @dim_w + pose_w) * @cw
    sy = (index / 4 * @dim_h + pose_h*4 + (d - 2) / 2) * @ch
    self.src_rect.set(sx, sy, @cw, @ch)
  end
end #Sprite_Character_TBS

#==============================================================================
# Window_BattleLog
#==============================================================================
class Window_BattleLog
  #--------------------------------------------------------------------------
  # alias method: display_miss -> play miss pose
  #--------------------------------------------------------------------------
  alias tbs_anim_display_miss display_miss
  def display_miss(target, item)
    target.play_pose(:miss)
    tbs_anim_display_miss(target,item)
  end
  #--------------------------------------------------------------------------
  # alias method: display_evasion -> play dodge/magic_dodge pose
  #--------------------------------------------------------------------------
  alias tbs_anim_display_evasion display_evasion
  def display_evasion(target, item)
    b = !item || item.physical?
    target.play_pose(b ? :dodge : :magic_dodge)
    tbs_anim_display_evasion(target,item)
  end
end #Window_BattleLog

#==============================================================================
# Scene_TBS_Battle
#==============================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # new method: wait_for_pose
  #--------------------------------------------------------------------------
  def wait_for_pose(pose)
    update_for_wait
    update_for_wait while pose && pose.running?
  end
  #--------------------------------------------------------------------------
  # alias method: tbs_pre_effects -> play the item casting pose
  #--------------------------------------------------------------------------
  alias anim_tbs_pre_effects tbs_pre_effects
  def tbs_pre_effects(user, item, targets, btbs)
    p = user.play_pose(item.cast_anim)
    wait_for_pose(p) if user.sprite.use_pose_bat
    anim_tbs_pre_effects(user, item, targets, btbs)
  end
  #--------------------------------------------------------------------------
  # alias method: tbs_post_effects -> play the item post anim pose
  #--------------------------------------------------------------------------
  alias anim_tbs_post_effects tbs_post_effects
  def tbs_post_effects(user, item, targets, btbs)
    anim_tbs_post_effects(user, item, targets, btbs)
    p = user.play_pose(item.post_anim)
    wait_for_pose(p) if user.sprite.use_pose_bat
  end
end #Scene_TBS_Battle

end #$imported["TIM-TBS-AnimatedPoses"]
