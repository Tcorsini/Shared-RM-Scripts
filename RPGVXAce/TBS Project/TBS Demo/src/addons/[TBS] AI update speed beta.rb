module TBS
  DISPLAY_AI_THINK = true

  TIME_FREQ = 1.0/Graphics.frame_rate#0.015 #0.015
  TIME_REFESH = true

  THINK_WAIT_START = 10 #in frames, time before displaying that the unit is thinking
  THINK_UP_TIME = 6 #in frames

  module Vocab
    THINKING_TEXT  = "Thinking"
  end
end

class Scene_TBS_Battle
  def init_think(bat)
    @thinking = Sprite_Thinking.new(bat)
  end

  def dispose_think
    @thinking.dispose
    @thinking = nil
  end

  def update_thinking
    @thinking.update if @thinking
    update_basic
  end

  def check_frame_refresh
    #Graphics.frame_reset
    @debut = Time.now unless @debut
    if Time.now - @debut > TBS::TIME_FREQ
      update_thinking #does update_basic
      @debut = Time.now
    end
  end
end

if TBS::TIME_REFESH
  class Game_Battler
    alias update_display_can_cross? can_cross?
    def can_cross?(moveRule,dir,prev_pos,nu_pos)
      SceneManager.scene.check_frame_refresh if SceneManager.scene_is?(Scene_TBS_Battle)
      update_display_can_cross?(moveRule,dir,prev_pos,nu_pos)
    end
  end


  #class Game_Map
  #  alias update_display_cost_move cost_move
  #  def cost_move(move_rule, x,y,d)
  #    SceneManager.scene.check_frame_refresh if SceneManager.scene_is?(Scene_TBS_Battle)
  #    update_display_cost_move(move_rule, x,y,d)
  #  end
  #end

  class AI_BattlerBase
    if TBS::DISPLAY_AI_THINK
    alias update_display_decide_actions decide_actions
    def decide_actions
      @@scene.init_think(@bat)
      update_display_decide_actions
      @@scene.dispose_think
    end
    end

    alias update_display_result_rate result_rate
    def result_rate(skill,tgt,targets_src_hash,current_best_rating = 0)
      SceneManager.scene.check_frame_refresh if SceneManager.scene_is?(Scene_TBS_Battle)
      update_display_result_rate(skill,tgt,targets_src_hash,current_best_rating)
    end

    #alias update_display_reach_best_position reach_best_position
    #def reach_best_position
    #  update_display_reach_best_position
    #  #puts @tactic.move_range
    #end

    alias update_display_rate_pos rate_pos
    def rate_pos(pos,last_move = false)
      SceneManager.scene.check_frame_refresh if SceneManager.scene_is?(Scene_TBS_Battle)
      update_display_rate_pos(pos,last_move)
    end
  end
end

#===============================================================================
# Sprite_Thinking -> Draws the Thinking... at start of AI thinking
#===============================================================================
class Sprite_Thinking < Sprite
  #----------------------------------------------------------------
  # initialize: battler parameter is for further add-on/modification
  #----------------------------------------------------------------
  def initialize(battler)
    super()
    @think_time = -TBS::THINK_WAIT_START
    reset_text
    self.bitmap = Bitmap.new(250, 24)
    update
  end
  #----------------------------------------------------------------
  # override method: update -> draws the Thinking... .. . bitmap
  # while AI is running
  #----------------------------------------------------------------
  def update
    @think_time += 1
    if @think_time >= 0 && @think_time % TBS::THINK_UP_TIME == 0
      self.bitmap.clear
      @think_text +="."
      reset_text if self.bitmap.text_size(@think_text).width > self.width
      self.bitmap.draw_text(0, 0, self.width, self.height, @think_text)
    end
    super
  end
  #----------------------------------------------------------------
  # new method: reset_text
  #----------------------------------------------------------------
  def reset_text
    @think_text = TBS::Vocab::THINKING_TEXT
  end
  #----------------------------------------------------------------
  # override method: dispose
  #----------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
end #Sprite_Thinking
