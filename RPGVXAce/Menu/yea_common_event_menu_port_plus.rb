#==============================================================================
# Common event menu VX Ace alternative patch
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 22/09/2025 
#==============================================================================
# Description: Changes the index and description regexp to be distinct from 
# Yanfly's Common Event Shop, use this only if you don't want the same icon
# and help description for a common event in the shop and the added menu.
#
#  <CEM Icon: x>
#
#  <CEM Help Description>
#   text|text
#  </CEM Help Description>
#==============================================================================
# Term of use: free for both commercial and non commercial games
#==============================================================================
# Installation: put it below Common Event Menu script
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-CommonEventMenu-alt"] = false

if $imported["TIM-CommonEventMenu-alt"]

module TIM
  module COMMON_EVENT_MENU
    module REGEXP
      ICON_INDEX           = /<CEM (?:ICON|(?:i|I)con):[ ](\d+)>/i
      HELP_DESCRIPTION_ON  = /<CEM (?:HELP_DESCRIPTION|(?:h|H)elp description)>/i
      HELP_DESCRIPTION_OFF = /<\/CEM (?:HELP_DESCRIPTION|(?:h|H)elp description)>/i
    end #REGEXP
  end #COMMON_EVENT_MENU
end #TIM

end #$imported["TIM-CommonEventMenu-alt"]