#==============================================================================
# Yanfly Lunatic States Punishment addon
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 12/08/2025
# Requires: YEA - Lunatic States Package - Punishment v1.01 and 
# its required scripts
#==============================================================================
# Description: allows damage (slip damage) to be dealt based on the target
# stats by using MYSTAT instead of STAT (with STAT being MAXHP, MAXMP, ATK, DEF, 
# MAT, MDF, AGI, or LUK).
#==============================================================================
# Installation: put it below the required scripts
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YEA-LSP-Punishment-addon"] = true

if $imported["YEA-LunaticStates"]
#==============================================================================
# Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # alias method: lunatic_state_extension
  #--------------------------------------------------------------------------
  alias tim_lunatic_state_extension_lspa lunatic_state_extension
  def lunatic_state_extension(effect, state, user, state_origin, log_window)
    case effect.upcase
    #----------------------------------------------------------------------
    # Punish Effect: Target Stat Slip Damage
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Best used with close effect. At the end of the turn, the affected
    # battler will take HP slip damage based on its stats. Battler cannot die 
    # from this effect.
    # 
    # Recommended notetag:
    #   <close effect: stat slip damage x%>
    # 
    # Replace "stat" with MYMAXHP, MYMAXMP, MYATK, MYDEF, MYMAT, MYMDF, MYAGI, or MYLUK.
    # Replace x with the stat multiplier to affect damage dealt.
    #
    # This is an addition to the already known SLIP DAMAGE from the punishment addon
    # that worked only with caster's stats, here the damage will be done with the targets's
    # stats as long as you put MYSTAT instead of STAT
    #----------------------------------------------------------------------
    when /(.*)[ ]SLIP DAMAGE[ ](\d+)([%％])/i
      case $1.upcase
      when "MYMAXHP"; dmg = user.mhp
      when "MYMAXMP"; dmg = user.mmp
      when "MYATK";   dmg = user.atk
      when "MYDEF";   dmg = user.def
      when "MYMAT";   dmg = user.mat
      when "MYMDF";   dmg = user.mdf
      when "MYAGI";   dmg = user.agi
      when "MYLUK";   dmg = user.luk
      #when another stat is used like MAXHP etc., will call Yanfly's original script
      else; return tim_lunatic_state_extension_lspa(effect, state, user, state_origin, log_window)
      end
      dmg = (dmg * $2.to_i * 0.01).to_i
      if $imported["YEA-BattleEngine"] && dmg > 0
        text = sprintf(YEA::BATTLE::POPUP_SETTINGS[:hp_dmg], dmg.group)
        user.create_popup(text, "HP_DMG")
      end
      user.perform_damage_effect
      user.hp = [user.hp - dmg, 1].max
    #----------------------------------------------------------------------
    # Stop editting past this point.
    #----------------------------------------------------------------------
    else
      so = state_origin
      lw = log_window
      tim_lunatic_state_extension_lspa(effect, state, user, so, lw)
    end
  end
end # Game_BattlerBase
end # $imported["YEA-LunaticStates"]