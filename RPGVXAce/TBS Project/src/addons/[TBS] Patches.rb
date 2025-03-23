#==============================================================================
#
# �� TBS PatchHub by Timtrack
# -- Last Updated: 02/03/2025
# -- Requires: [TBS] by Timtrack
#
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-PatchHub"] = true
raise "TBS PatchHub requires TBS by Timtrack" unless $imported["TIM-TBS"] if $imported["TIM-TBS-PatchHub"]

#==============================================================================
# �� Updates
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 18/02/2025 - Started Script.
#
#==============================================================================
# �� Description
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# A patch hub that supports scripts I enjoy or recommend along with TBS
# Most of the patches reuse huge chunks of code from the original scripts and
# I pasted these chunks in a brainless way, if you encounter any issue with the
# patches, please tell me!
#
# List of supported scripts by TBS.
# Without any patch:
# --to fill with relevant scripts--
# With this patch:
# - YEA Victory Aftermath v1.04
# - Zeus Lights & Shadows v1.3
# - YEA Core Engine v1.09
# - YEA Battle Core v1.22
# - YEA Enemy HP Bars v1.10
# TODO: check if the patch works with:
# - YEA Lunatic States v1.02
# - YEA Skill Restrictions v1.02
# - YEA System Options v1.00
# Unsupported:
# - YEA Instant Cast: TBS actions are already instants
# - GTBS and other battle systems overhauls are not compatible
#
# If an unsupported script is used that modify the following classes then:
# -Scene_Battle should work properly if tbs is disabled but no modification
#  to it will affect a tbs battle, see Scene_TBS_Battle if you want to add new features
# -BattleManager or skill targetting changes are unlikely to work with TBS
# -Changes to Sprite_Battler must be exported to Sprite_Character_TBS in order to work in TBS
# -Changes to Spriteset_Battle must be exported to Spriteset_Map in order to work in TBS
# -Changes to Spriteset_Map or Game_Map might impact TBS battles but may not work properly
# -Adding new stats to battlers or changing the results of skills should still work in TBS
# -Changing Window_BattleSkill, Window_BattleItem or Window_ActorCommand will affect windows in TBS
#==============================================================================
# �� Recommended Load Order
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# [RPG Maker Scripts]
# Victor Core Engine (required for TBS)
# Yanfly Core Engine (optional)
# Yanfly Battle Core (optional)
# Sprite_Tile        (required for TBS)
# [TBS Core]
# [TBS addons]
# Supported scripts (in their relative order, all are optional)
# This patch
# Main
#==============================================================================


#==============================================================================
# YEA - Ace Core Engine patch
#==============================================================================
# Copy the changes to Sprite_Battler to Sprite_Character_TBS (as it is a copy of it)
# Bugfixes made to Scene_Battle are exported to Scene_TBS_Battle
# Exception is for dual weapons animations already integrated in TBS
#==============================================================================
if $imported["YEA-CoreEngine"]

  class Sprite_Character_TBS < Sprite_Character
    #--------------------------------------------------------------------------
    # alias method: setup_new_animation
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_setup_new_animation_ace setup_new_animation
    def setup_new_animation
      sprite_character_tbs_setup_new_animation_ace
      return if @battler.nil?
      return if @battler.pseudo_ani_id.nil?
      return if @battler.pseudo_ani_id <= 0
      animation = $data_animations[@battler.pseudo_ani_id]
      mirror = @battler.animation_mirror
      start_pseudo_animation(animation, mirror)
      @battler.pseudo_ani_id = 0
    end
  end # Sprite_Character_TBS

  class Scene_TBS_Battle < Scene_Base

    #--------------------------------------------------------------------------
    # alias method: check_substitute
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_check_substitute_ace check_substitute
    def check_substitute(target, item)
      return false if @subject.actor? == target.actor?
      return scene_tbs_battle_check_substitute_ace(target, item)
    end

    #--------------------------------------------------------------------------
    # overwrite method: process_forced_action
    #--------------------------------------------------------------------------
    def process_forced_action
      while BattleManager.action_forced?
        last_subject = @subject
        @subject = BattleManager.action_forced_battler
        process_action
        @subject = last_subject
        BattleManager.clear_action_force
      end
    end

    #--------------------------------------------------------------------------
    # overwrite method: show_normal_animation
    #--------------------------------------------------------------------------
    def show_normal_animation(targets, animation_id, mirror = false)
      animation = $data_animations[animation_id]
      return if animation.nil?
      ani_check = false
      targets.each do |target|
        if ani_check && target.animation_id <= 0
          target.pseudo_ani_id = animation_id
        else
          target.animation_id = animation_id
        end
        target.animation_mirror = mirror
        abs_wait_short unless animation.to_screen?
        ani_check = true if animation.to_screen?
      end
      abs_wait_short if animation.to_screen?
    end

  end
end #YEA-CoreEngine

#==============================================================================
# YEA - Battle Engine patch
#==============================================================================
# Integrates tbs as part of the battle_systems for Game_System and Game_Interpreter (needs checking)
# overwrite methods changed in BattleManager: battle_start
# Copy the changes to Sprite_Battler to Sprite_Character_TBS (as it is a copy of it)
# Copy the changes to Sprite_Battler to Sprite_Character_TBS (as it is a copy of it)
# Copy the changes to Scene_Battle to Scene_TBS_Battle (damage and state popups, discard anything related to Windows)
# Copy the changes to Spriteset_Battle to Spriteset_TBS_Map and adapt them
# References to Scene_Battle also include Scene_TBS_Battle
# Some of the methods introduced to fetch sprites or locate the battler position are already integrated into TBS Core files
# Removed the previous/next commands for Windows_TBS_ActorCommand to avoid issues
#==============================================================================
if $imported["YEA-BattleEngine"]
  class Window_TBS_ActorCommand < Window_ActorCommand
    #--------------------------------------------------------------------------
    # override methods: process_dir4, process_dir6
    #--------------------------------------------------------------------------
    def process_dir4; end
    def process_dir6; end
  end # Window_TBS_ActorCommand

  class Game_System
    #--------------------------------------------------------------------------
    # alias method: set_battle_system
    #--------------------------------------------------------------------------
    alias set_battle_system_tbs set_battle_system
    def set_battle_system(type) #TODO: this doe not actually disable TBS battles
      type == :tbs ? @battle_system = :tbs : set_battle_system_tbs(type)
    end
    #--------------------------------------------------------------------------
    # alias method: battle_system_corrected
    #--------------------------------------------------------------------------
    alias battle_system_corrected_tbs battle_system_corrected
    def battle_system_corrected(type)
      type == :tbs ? :tbs : battle_system_corrected_tbs(type)
    end
  end # Game_System

  class Game_Interpreter
    #--------------------------------------------------------------------------
    # alias method: disable_tbs
    #--------------------------------------------------------------------------
    alias disable_tbs_ybe disable_tbs
    def disable_tbs
      disable_tbs_ybe
      $game_system.set_battle_system(:dtb)
    end
    #--------------------------------------------------------------------------
    # alias method: enable_tbs
    #--------------------------------------------------------------------------
    alias enable_tbs_ybe enable_tbs
    def enable_tbs
      enable_tbs_ybe
      $game_system.set_battle_system(:tbs)
    end
  end


  module BattleManager
    #--------------------------------------------------------------------------
    # overwrite method: self.battle_start
    #--------------------------------------------------------------------------
    def self.battle_start
      return tbs_bm_battle_start unless SceneManager.scene_is?(Scene_TBS_Battle)
      $game_system.battle_count += 1
      #modified
      $game_party.on_tbs_battle_start
      $game_troop.on_tbs_battle_start
      for b in SceneManager.scene.obstacles
        b.on_battle_end
      end
      return unless YEA::BATTLE::MSG_ENEMY_APPEARS
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
  end # BattleManager


  #class Window_BattleHelp
  #  def update_battler_name
  #end

  class Sprite_Character_TBS < Sprite_Character
    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :effect_type
    attr_accessor :battler_visible
    attr_accessor :popups

    #--------------------------------------------------------------------------
    # alias method: initialize
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_initialize_abe initialize
    def initialize(viewport, battler = nil)
      @popups = []
      @popup_flags = []
      sprite_character_tbs_initialize_abe(viewport, battler)
    end

    #--------------------------------------------------------------------------
    # alias method: setup_new_animation
    #--------------------------------------------------------------------------
    unless $imported["YEA-CoreEngine"]
    alias sprite_character_tbs_setup_new_animation_abe setup_new_animation
    def setup_new_animation
      sprite_character_tbs_setup_new_animation_abe
      return if @battler.pseudo_ani_id <= 0
      animation = $data_animations[@battler.pseudo_ani_id]
      mirror = @battler.animation_mirror
      start_pseudo_animation(animation, mirror)
      @battler.pseudo_ani_id = 0
    end
    end # $imported["YEA-CoreEngine"]

    #--------------------------------------------------------------------------
    # alias method: setup_new_effect
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_setup_new_effect_abe setup_new_effect
    def setup_new_effect
      sprite_character_tbs_setup_new_effect_abe
      setup_popups
    end

    #--------------------------------------------------------------------------
    # new method: setup_popups
    #--------------------------------------------------------------------------
    def setup_popups
      return unless @battler.use_sprite?
      @battler.popups = [] if @battler.popups.nil?
      return if @battler.popups == []
      array = @battler.popups.shift
      create_new_popup(array[0], array[1], array[2])
    end

    #--------------------------------------------------------------------------
    # new method: create_new_popup
    #--------------------------------------------------------------------------
    def create_new_popup(value, rules, flags)
      return if @battler == nil
      return if flags & @popup_flags != []
      array = YEA::BATTLE::POPUP_RULES[rules]
      for popup in @popups
        popup.y -= 24
      end
      return unless SceneManager.scene.is_a?(Scene_TBS_Battle)
      return if SceneManager.scene.spriteset.nil?
      view = SceneManager.scene.spriteset.viewportPopups
      new_popup = Sprite_Popup.new(view, @battler, value, rules, flags)
      @popups.push(new_popup)
      @popup_flags.push("weakness") if flags.include?("weakness")
      @popup_flags.push("resistant") if flags.include?("resistant")
      @popup_flags.push("immune") if flags.include?("immune")
      @popup_flags.push("absorbed") if flags.include?("absorbed")
    end

    #--------------------------------------------------------------------------
    # alias method: update_effect
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_update_effect_abe update_effect
    def update_effect
      sprite_character_tbs_update_effect_abe
      update_popups
    end

    #--------------------------------------------------------------------------
    # new method: update_popups
    #--------------------------------------------------------------------------
    def update_popups
      puts "nil" if @popups.nil?
      for popup in @popups
        popup.update
        next unless popup.opacity <= 0
        popup.bitmap.dispose
        popup.dispose
        @popups.delete(popup)
        popup = nil
      end
      @popup_flags = [] if @popups == [] && @popup_flags != []
      return unless SceneManager.scene_is?(Scene_TBS_Battle)
      if @current_active_battler != SceneManager.scene.subject
        @current_active_battler = SceneManager.scene.subject
        @popup_flags = []
      end
    end

  end # Sprite_Character_TBS


  class Spriteset_TBS_Map < Spriteset_Map

    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :battler_sprites
    attr_accessor :viewport1
    attr_accessor :viewportPopups

    #--------------------------------------------------------------------------
    # alias method: create_viewports
    #--------------------------------------------------------------------------
    alias spriteset_tbs_map_create_viewports_abe create_viewports
    def create_viewports
      spriteset_tbs_map_create_viewports_abe
      @viewportPopups = Viewport.new
      @viewportPopups.z = 200
    end

    #--------------------------------------------------------------------------
    # alias method: dispose_viewports
    #--------------------------------------------------------------------------
    alias spriteset_tbs_map_dispose_viewports_abe dispose_viewports
    def dispose_viewports
      spriteset_tbs_map_dispose_viewports_abe
      @viewportPopups.dispose
    end

    #--------------------------------------------------------------------------
    # alias method: update_viewports
    #--------------------------------------------------------------------------
    alias spriteset_tbs_map_update_viewports_abe update_viewports
    def update_viewports
      spriteset_tbs_map_update_viewports_abe
      @viewportPopups.update
    end

  end # Spriteset_TBS_Map


  class Game_Battler
    #--------------------------------------------------------------------------
    # overwrite method: can_collapse?
    #--------------------------------------------------------------------------
    alias tbs_patch_can_collapse? can_collapse?
    def can_collapse?
      return false unless dead?
      return true if actor? and not SceneManager.scene_is?(Scene_TBS_Battle)
      return false unless sprite and sprite.battler_visible
      array = [:collapse, :boss_collapse, :instant_collapse]
      return false if array.include?(sprite.effect_type)
      return true
    end
  end

  class Game_BattlerBase
    #--------------------------------------------------------------------------
    # alias method: create_popup
    #--------------------------------------------------------------------------
    alias create_popup_tbs create_popup
    def create_popup(value, rules = "DEFAULT", flags = [])
      return create_popup_tbs(value, rules, flags) unless SceneManager.scene_is?(Scene_TBS_Battle)
      return unless YEA::BATTLE::ENABLE_POPUPS
      return if Switch.hide_popups
      @popups = [] if @popups.nil?
      @popups.push([value, rules, flags])
    end

    #--------------------------------------------------------------------------
    # alias method: make_buff_popup
    #--------------------------------------------------------------------------
    alias make_buff_popup_tbs make_buff_popup
    def make_buff_popup(param_id, positive = true)
      return make_buff_popup_tbs(param_id, positive) unless SceneManager.scene_is?(Scene_TBS_Battle)
      return unless alive?
      name = Vocab::param(param_id)
      if positive
        text = sprintf(YEA::BATTLE::POPUP_SETTINGS[:add_buff], name)
        rules = "BUFF"
        buff_level = 1
      else
        text = sprintf(YEA::BATTLE::POPUP_SETTINGS[:add_debuff], name)
        rules = "DEBUFF"
        buff_level = -1
      end
      icon = buff_icon_index(buff_level, param_id)
      flags = ["buff", icon]
      return if @popups.include?([text, rules, flags])
      create_popup(text, rules, flags)
    end
  end

  class Scene_TBS_Battle < Scene_Base

    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :info_viewport
    attr_accessor :spriteset
    attr_accessor :status_aid_window
    attr_accessor :subject

    #--------------------------------------------------------------------------
    # alias method: create_spriteset
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_create_spriteset_abe create_spriteset
    def create_spriteset
      BattleManager.init_battle_type
      scene_tbs_battle_create_spriteset_abe
    end

    #--------------------------------------------------------------------------
    # alias method: update_basic
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_update_basic_abe update_basic
    def update_basic
      scene_tbs_battle_update_basic_abe
      update_debug
    end

    #--------------------------------------------------------------------------
    # new method: update_debug
    #--------------------------------------------------------------------------
    def update_debug
      return unless $TEST || $BTEST
      debug_heal_party if Input.trigger?(:F5)
      debug_damage_party if Input.trigger?(:F6)
      debug_fill_tp if Input.trigger?(:F7)
      debug_kill_all if Input.trigger?(:F8)
    end

    #--------------------------------------------------------------------------
    # new method: debug_heal_party
    #--------------------------------------------------------------------------
    def debug_heal_party
      Sound.play_recovery
      for member in $game_party.battle_members
        member.recover_all
      end
      #@status_window.refresh
    end

    #--------------------------------------------------------------------------
    # new method: debug_damage_party
    #--------------------------------------------------------------------------
    def debug_damage_party
      Sound.play_actor_damage
      for member in $game_party.alive_members
        member.hp = 1
        member.mp = 0
        member.tp = 0
      end
      #@status_window.refresh
    end

    #--------------------------------------------------------------------------
    # new method: debug_fill_tp
    #--------------------------------------------------------------------------
    def debug_fill_tp
      Sound.play_recovery
      for member in $game_party.alive_members
        member.tp = member.max_tp
      end
      #@status_window.refresh
    end

    #--------------------------------------------------------------------------
    # new method: debug_kill_all
    #--------------------------------------------------------------------------
    def debug_kill_all
      for enemy in $game_troop.alive_members
        enemy.hp = 0
        enemy.perform_collapse_effect
      end
      BattleManager.judge_win_loss
      #@log_window.wait
      #@log_window.wait_for_effect
    end

    #--------------------------------------------------------------------------
    # alias method: show_fast?
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_show_fast_abe show_fast?
    def show_fast?
      return true if YEA::BATTLE::AUTO_FAST
      return scene_tbs_battle_show_fast_abe
    end

    #--------------------------------------------------------------------------
    # new method: end_battle_conditions?
    #--------------------------------------------------------------------------
    def end_battle_conditions?
      return BattleManager.end_battle_cond?
    end

    #--------------------------------------------------------------------------
    # overwrite method: execute_action
    #--------------------------------------------------------------------------
    def execute_action(tbs = false)
      @subject.sprite_effect_type = :whiten if YEA::BATTLE::FLASH_WHITE_EFFECT
      use_item(tbs)
      @log_window.wait_and_clear
    end

    #--------------------------------------------------------------------------
    # overwrite method: apply_item_effects
    #--------------------------------------------------------------------------
    def apply_item_effects(target, item)
      if $imported["YEA-LunaticObjects"]
        lunatic_object_effect(:prepare, item, @subject, target)
      end
      target.item_apply(@subject, item)
      @log_window.display_action_results(target, item)
      if $imported["YEA-LunaticObjects"]
        lunatic_object_effect(:during, item, @subject, target)
      end
      perform_collapse_check(target)
    end

    #--------------------------------------------------------------------------
    # alias method: invoke_counter_attack
    #--------------------------------------------------------------------------
    alias tbs_invoke_counter_attack invoke_counter_attack
    def invoke_counter_attack(target, item)
      tbs_invoke_counter_attack(target,item)
      perform_collapse_check(target)
      perform_collapse_check(@subject)
    end
    #--------------------------------------------------------------------------
    # new method: perform_collapse_check
    #--------------------------------------------------------------------------
    def perform_collapse_check(target)
      return if YEA::BATTLE::MSG_ADDED_STATES
      target.perform_collapse_effect if target.can_collapse?
      @log_window.wait
      @log_window.wait_for_effect
    end

    #--------------------------------------------------------------------------
    # overwrite method: show_attack_animation
    #--------------------------------------------------------------------------
    def show_attack_animation(targets)
      show_normal_animation(targets, @subject.atk_animation_id1, false)
      wait_for_animation
      show_normal_animation(targets, @subject.atk_animation_id2, true)
    end
    #--------------------------------------------------------------------------
    # overwrite method: show_normal_animation
    #--------------------------------------------------------------------------
    def show_normal_animation(targets, animation_id, mirror = false)
      animation = $data_animations[animation_id]
      return if animation.nil?
      ani_check = false
      targets.each do |target|
        if ani_check && target.animation_id <= 0
          target.pseudo_ani_id = animation_id
        else
          target.animation_id = animation_id
        end
        target.animation_mirror = mirror
        ani_check = true if animation.to_screen?
      end
    end
    #--------------------------------------------------------------------------
    # overwrite method: use_item
    #--------------------------------------------------------------------------
    def use_item(tbs)
      item = @subject.current_action.item
      @log_window.display_use_item(@subject, item)
      @subject.use_item(item)

      if $imported["YEA-LunaticObjects"]
        lunatic_object_effect(:before, item, @subject, @subject)
      end
      process_casting_animation if $imported["YEA-CastAnimations"]
      targets = tbs ? @subject.current_action.tbs_make_targets : @subject.current_action.make_targets.compact
      (tbs ? show_tbs_animation(targets, item.animation_id, @subject.current_action) : show_animation(targets, item.animation_id)) if show_all_animation?(item)
      targets.each {|target|
        if $imported["YEA-TargetManager"]
          target = alive_random_target(target, item) if item.for_random?
        end
        item.repeats.times { invoke_item(target, item) } }
      if $imported["YEA-LunaticObjects"]
        lunatic_object_effect(:after, item, @subject, @subject)
      end
    end

    #--------------------------------------------------------------------------
    # alias method: invoke_item
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_invoke_item_abe invoke_item
    def invoke_item(target, item)
      show_animation([target], item.animation_id) if separate_ani?(target, item)
      if target.dead? != item.for_dead_friend?
        @subject.last_target_index = target.index
        return
      end
      scene_tbs_battle_invoke_item_abe(target, item)
    end

    #--------------------------------------------------------------------------
    # new method: show_all_animation?
    #--------------------------------------------------------------------------
    def show_all_animation?(item)
      return true if item.one_animation
      return false if $data_animations[item.animation_id].nil?
      return false unless $data_animations[item.animation_id].to_screen?
      return true
    end

    #--------------------------------------------------------------------------
    # new method: separate_ani?
    #--------------------------------------------------------------------------
    def separate_ani?(target, item)
      return false if item.one_animation
      return false if $data_animations[item.animation_id].nil?
      return false if $data_animations[item.animation_id].to_screen?
      return target.dead? == item.for_dead_friend?
    end

    #--------------------------------------------------------------------------
    # alias method: turn_end
    #--------------------------------------------------------------------------
    alias turn_end_tbs_patch_ybc turn_end
    def turn_end
      update_party_cooldowns if $imported["YEA-CommandParty"]
      turn_end_tbs_patch_ybc
      #BattleManager.turn_end
      #process_event
      #turn_start
      return if end_battle_conditions?
  end

    #--------------------------------------------------------------------------
    # new method: hide_extra_gauges
    #--------------------------------------------------------------------------
    def hide_extra_gauges
      # Made for compatibility
    end

    #--------------------------------------------------------------------------
    # new method: show_extra_gauges
    #--------------------------------------------------------------------------
    def show_extra_gauges
      # Made for compatibility
    end

  end # Scene_Battle

end #YEA-BattleEngine

#==============================================================================
# YEA Victory Aftermath patch
#==============================================================================
# Links the result menu to Scene_TBS_Battle
#==============================================================================
if $imported["YEA-VictoryAftermath"]
  class Game_Actor < Game_Battler
    #--------------------------------------------------------------------------
    # overwrite method: gain_exp
    #--------------------------------------------------------------------------
    def gain_exp(exp)
      enabled = !(SceneManager.scene_is?(Scene_TBS_Battle) or SceneManager.scene_is?(Scene_Battle))
      change_exp(self.exp + (exp * final_exp_rate).to_i, enabled)
    end
  end

  class Scene_TBS_Battle < Scene_Base
    #--------------------------------------------------------------------------
    # alias method: create_all_windows
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_create_all_windows_va create_all_windows
    def create_all_windows
      scene_tbs_battle_create_all_windows_va
      create_victory_aftermath_windows
    end
    #--------------------------------------------------------------------------
    # new method: create_victory_aftermath_windows
    #--------------------------------------------------------------------------
    def create_victory_aftermath_windows
      @victory_title_window = Window_VictoryTitle.new
      @victory_exp_window_back = Window_VictoryEXP_Back.new
      @victory_exp_window_front = Window_VictoryEXP_Front.new
      @victory_level_window = Window_VictoryLevelUp.new
      @victory_level_skills = Window_VictorySkills.new
      @victory_spoils_window = Window_VictorySpoils.new
    end
    #--------------------------------------------------------------------------
    # new method: show_victory_display_exp
    #--------------------------------------------------------------------------
    def show_victory_display_exp
      @victory_title_window.open
      name = $game_party.battle_members[0].name
      fmt = YEA::VICTORY_AFTERMATH::TOP_TEAM
      name = sprintf(fmt, name) if $game_party.battle_members.size > 1
      fmt = YEA::VICTORY_AFTERMATH::TOP_VICTORY_TEXT
      text = sprintf(fmt, name)
      @victory_title_window.refresh(text)
      #---
      @victory_exp_window_back.open
      @victory_exp_window_back.refresh
      @victory_exp_window_front.open
      @victory_exp_window_front.refresh
    end
    #--------------------------------------------------------------------------
    # new method: show_victory_level_up
    #--------------------------------------------------------------------------
    def show_victory_level_up(actor, temp_actor)
      @victory_exp_window_back.hide
      @victory_exp_window_front.hide
      #---
      fmt = YEA::VICTORY_AFTERMATH::TOP_LEVEL_UP
      text = sprintf(fmt, actor.name)
      @victory_title_window.refresh(text)
      #---
      @victory_level_window.show
      @victory_level_window.refresh(actor, temp_actor)
      @victory_level_skills.show
      @victory_level_skills.refresh(actor, temp_actor)
    end
    #--------------------------------------------------------------------------
    # new method: show_victory_spoils
    #--------------------------------------------------------------------------
    def show_victory_spoils(gold, drops)
      @victory_exp_window_back.hide
      @victory_exp_window_front.hide
      @victory_level_window.hide
      @victory_level_skills.hide
      #---
      text = YEA::VICTORY_AFTERMATH::TOP_SPOILS
      @victory_title_window.refresh(text)
      #---
      @victory_spoils_window.show
      @victory_spoils_window.make(gold, drops)
    end
    #--------------------------------------------------------------------------
    # new method: close_victory_windows
    #--------------------------------------------------------------------------
    def close_victory_windows
      @victory_title_window.close
      @victory_exp_window_back.close
      @victory_exp_window_front.close
      @victory_level_window.close
      @victory_level_skills.close
      @victory_spoils_window.close
      wait(16)
    end
  end # Scene_TBS_Battle
end #YEA-VictoryAftermath

#==============================================================================
# Zeus Lights & Shadows patch
#==============================================================================
# Allows to reload the lights when exiting the battle while reloading saved map data
#==============================================================================
if $imported[:Zeus_Event_Auto_Setup]
  class Game_Map
    #--------------------------------------------------------------------------
    # alias method: setup_old_events
    #--------------------------------------------------------------------------
    alias zl_patch_setup_old_events setup_old_events
    def setup_old_events
      zl_patch_setup_old_events
      @events.each_value {|event| event.reload_lights}
    end
  end #Game_Map
  class Game_Event
    #--------------------------------------------------------------------------
    # new method: reload_lights
    #--------------------------------------------------------------------------
    def reload_lights
      if @auto_setup[@list]
        interpreter = Game_Interpreter.new
        interpreter.setup(@auto_setup[@list], @id)
        interpreter.update while interpreter.running?
      end
    end
  end #Game_Event
end #Zeus_Event_Auto_Setup

#==============================================================================
# YEA - Lunatic States patch
#==============================================================================
# Turn states effects are relative to battler's turn during TBS
#==============================================================================
if $imported["YEA-LunaticStates"]
  class Game_Battler < Game_BattlerBase
    #--------------------------------------------------------------------------
    # alias method: on_turn_start
    #--------------------------------------------------------------------------
    alias game_battler_on_turn_start_lsta on_turn_start
    def on_turn_start
      game_battler_on_turn_start_lsta
      run_lunatic_states(:begin) if SceneManager.scene_is?(Scene_TBS_Battle)
    end
    #--------------------------------------------------------------------------
    # alias method: on_turn_end
    #--------------------------------------------------------------------------
    alias game_battler_on_turn_end_lsta on_turn_end
    def on_turn_end
      game_battler_on_turn_end_lsta
      run_lunatic_states(:close) if SceneManager.scene_is?(Scene_TBS_Battle)
    end
  end

  class Scene_TBS_Battle < Scene_Base
    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :log_window
    attr_accessor :subject
    #--------------------------------------------------------------------------
    # alias method: execute_action
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_execute_action_lsta execute_action
    def execute_action(tbs = false)
      scene_tbs_battle_execute_action_lsta(tbs)
      @subject.run_lunatic_states(:while)
    end
  end # Scene_TBS_Battle
end #YEA-LunaticStates

#==============================================================================
# YEA - Skill Restrictions patch
#==============================================================================
# Cooldowns are updated at the end of battler's turn in TBS
#==============================================================================
if $imported["YEA-SkillRestrictions"]
  class Game_Battler < Game_BattlerBase
    #--------------------------------------------------------------------------
    # alias method: on_turn_end
    #--------------------------------------------------------------------------
    alias game_battler_on_turn_end_sr on_turn_end
    def on_turn_end
      game_battler_on_turn_end_sr
      update_cooldowns if SceneManager.scene_is?(Scene_TBS_Battle)
    end
  end
end #YEA-SkillRestrictions

#==============================================================================
# YEA - System Options patch
#==============================================================================
# Animations displayed during TBS Battle are now hidden if the option is chosen
#==============================================================================
if $imported["YEA-SystemOptions"]
  class Scene_TBS_Battle < Scene_Base
    #--------------------------------------------------------------------------
    # alias method: show_fast?
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_show_fast_so show_fast?
    def show_fast?
      return true unless $game_system.animations?
      return scene_tbs_battle_show_fast_so
    end
    #--------------------------------------------------------------------------
    # alias method: show_normal_animation
    #--------------------------------------------------------------------------
    alias scene_tbs_battle_show_normal_animation_so show_normal_animation
    def show_normal_animation(targets, animation_id, mirror = false)
      return unless $game_system.animations?
      scene_tbs_battle_show_normal_animation_so(targets, animation_id, mirror)
    end
  end # Scene_TBS_Battle

  class Spriteset_TBS_Map < Spriteset_Map
    #--------------------------------------------------------------------------
    # alias method: anim_tgt_sprite
    #--------------------------------------------------------------------------
    alias tbs_map_anim_tgt_sprite_so anim_tgt_sprite
    def anim_tgt_sprite(anim_id, mirror = false)
      return unless $game_system.animations?
      tbs_map_anim_tgt_sprite_so(anim_id, mirror)
    end
  end #Spriteset_TBS_Map
end #YEA-System Options

#==============================================================================
# YEA - Battle Engine Add-On: Enemy HP Bars patch
#==============================================================================
# HP bars will display in TBS battle for both actors and enemies
#==============================================================================
if $imported["YEA-EnemyHPBars"] and $imported["YEA-BattleEngine"]
  class Sprite_Character_TBS < Sprite_Character
    #--------------------------------------------------------------------------
    # alias method: initialize
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_initialize_ehpb initialize
    def initialize(viewport, battler = nil)
      sprite_character_tbs_initialize_ehpb(viewport, battler)
      create_enemy_gauges
    end

    #--------------------------------------------------------------------------
    # alias method: dispose
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_dispose_ehpb dispose
    def dispose
      sprite_character_tbs_dispose_ehpb
      dispose_enemy_gauges
    end

    #--------------------------------------------------------------------------
    # alias method: update
    #--------------------------------------------------------------------------
    alias sprite_character_tbs_update_ehpb update
    def update
      sprite_character_tbs_update_ehpb
      update_enemy_gauges
    end

    #--------------------------------------------------------------------------
    # new method: create_enemy_gauges
    #--------------------------------------------------------------------------
    def create_enemy_gauges
      return if @battler.nil?
      #return if @battler.actor?
      return if @battler.enemy? and not @battler.enemy.show_gauge
      @back_gauge_viewport = Enemy_HP_Gauge_Viewport.new(@battler, self, :back)
      @hp_gauge_viewport = Enemy_HP_Gauge_Viewport.new(@battler, self, :hp)
    end

    #--------------------------------------------------------------------------
    # new method: dispose_enemy_gauges
    #--------------------------------------------------------------------------
    def dispose_enemy_gauges
      @back_gauge_viewport.dispose unless @back_gauge_viewport.nil?
      @hp_gauge_viewport.dispose unless @hp_gauge_viewport.nil?
    end

    #--------------------------------------------------------------------------
    # new method: update_enemy_gauges
    #--------------------------------------------------------------------------
    def update_enemy_gauges
      @back_gauge_viewport.update unless @back_gauge_viewport.nil?
      @hp_gauge_viewport.update unless @hp_gauge_viewport.nil?
    end

    #--------------------------------------------------------------------------
    # new method: update_enemy_gauge_value
    #--------------------------------------------------------------------------
    def update_enemy_gauge_value
      @back_gauge_viewport.new_hp_updates unless @back_gauge_viewport.nil?
      @hp_gauge_viewport.new_hp_updates unless @hp_gauge_viewport.nil?
    end
  end # Sprite_Character_TBS

  class Game_BattlerBase
    #--------------------------------------------------------------------------
    # alias method: refresh
    #--------------------------------------------------------------------------
    alias game_battlerbase_refresh_tbs_ehpb refresh
    def refresh
      game_battlerbase_refresh_tbs_ehpb
      sprite.update_enemy_gauge_value if SceneManager.scene_is?(Scene_TBS_Battle) and sprite
    end
  end # Game_BattlerBase


  class Game_Battler < Game_BattlerBase
    #--------------------------------------------------------------------------
    # alias method: hp=
    #--------------------------------------------------------------------------
    alias game_battlerbase_hpequals_tbs_ehpb hp=
    def hp=(value)
      game_battlerbase_hpequals_tbs_ehpb(value)
      return unless SceneManager.scene_is?(Scene_TBS_Battle)
      return if value == 0
      sprite.update_enemy_gauge_value if sprite
    end
  end # Game_Battler

  class Enemy_HP_Gauge_Viewport < Viewport
    #--------------------------------------------------------------------------
    # alias method: setup_original_hide_gauge
    #--------------------------------------------------------------------------
    alias setup_original_hide_gauge_tbs setup_original_hide_gauge
    def setup_original_hide_gauge
      return @original_hide = false unless @battler.enemy?
      setup_original_hide_gauge_tbs
    end

    #--------------------------------------------------------------------------
    # alias method: create_gauge_sprites
    #--------------------------------------------------------------------------
    alias create_gauge_sprites_tbs create_gauge_sprites
    def create_gauge_sprites
      return create_gauge_sprites_tbs if @battler.enemy?
      @sprite = Plane.new(self)
      dw = self.rect.width * 2
      @sprite.bitmap = Bitmap.new(dw, self.rect.height)
      case @type
      when :back
        colour1 = Colour.text_colour(YEA::BATTLE::ENEMY_BACKGAUGE_COLOUR)
        colour2 = Colour.text_colour(YEA::BATTLE::ENEMY_BACKGAUGE_COLOUR)
      when :hp
        colour1 = Colour.text_colour(YEA::BATTLE::ENEMY_HP_GAUGE_COLOUR1)
        colour2 = Colour.text_colour(YEA::BATTLE::ENEMY_HP_GAUGE_COLOUR2)
      end
      dx = 0
      dy = 0
      dw = self.rect.width
      dh = self.rect.height
      @gauge_width = target_gauge_width
      @sprite.bitmap.gradient_fill_rect(dx, dy, dw, dh, colour1, colour2)
      @sprite.bitmap.gradient_fill_rect(dw, dy, dw, dh, colour2, colour1)
      @visible_counter = 0
    end

    #--------------------------------------------------------------------------
    # alias method: gauge_visible?
    #--------------------------------------------------------------------------
    alias tbs_gauge_visible? gauge_visible?
    def gauge_visible?
      return true if tbs_gauge_visible? #unless SceneManager.scene_is?(Scene_TBS_Battle)
      if SceneManager.scene_is?(Scene_TBS_Battle)
        return false if @battler.dead?
        return SceneManager.scene.battlers_in_area.include?(@battler)
      end
      #update_original_hide
      #return false if @original_hide
      #return false if case_original_hide?
      #return true if @visible_counter > 0
      #return true if @gauge_width != @target_gauge_width
      #if SceneManager.scene_is?(Scene_Battle)
      #return false if SceneManager.scene.enemy_window.nil?
      #unless @battler.dead?
        #if SceneManager.scene.enemy_window.active
          #return false if @battler.enemy? && @battler.hidden #add
          #return true if SceneManager.scene.enemy_window.enemy == @battler
          #return true if SceneManager.scene.enemy_window.select_all?
          #return true if highlight_aoe?
        #end
      #end
      #end
      return false
    end

    #--------------------------------------------------------------------------
    # alias method: case_original_hide?
    #--------------------------------------------------------------------------
    alias tbs_case_original_hide? case_original_hide?
    def case_original_hide?
      return false unless @battler.enemy?
      tbs_case_original_hide?
    end

    #--------------------------------------------------------------------------
    # alias method: update_original_hide
    #--------------------------------------------------------------------------
    alias update_original_hide_tbs update_original_hide
    def update_original_hide
      return @original_hide = false unless @battler.enemy?
      update_original_hide_tbs
    end
  end #Enemy_HP_Gauge_Viewport

end #YEA-EnemyHPBars
