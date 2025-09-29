#==============================================================================
# Slash Abilities v2 & Damage Popup patch
#==============================================================================

if $imported["TIM-Slash-Abilities"] && $imported["YES-BattlePopup"]

module BattleLuna
  module Addon
    BATTLE_POPUP[:basic_setting][:no_delay] += [:adjacent]
    BATTLE_POPUP[:word_setting][:adjacent] = "ADJACENT HIT"
                                          #[Red, Green, Blue, Size, Bold, Italic, Font],
    BATTLE_POPUP[:style_setting][:adjacent] = [255, 255, 255, 32, true, false, Font.default_name]
    BATTLE_POPUP[:effect_setting][:adjacent] = [:affect, :up, :wait]
  end # Addon
end # BattleLuna

#============================================================================
# Game_BattlerBase
#============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # alias method: make_damage_popups
  #--------------------------------------------------------------------------
  alias slash_make_damage_popups make_damage_popups
  def make_damage_popups(user)
    create_popup(["", nil], :adjacent) unless @is_original_tgt
    slash_make_damage_popups(user)
  end
end #Game_BattlerBase

end # $imported["TIM-Slash-Abilties"] && $imported["YES-BattlePopup"]