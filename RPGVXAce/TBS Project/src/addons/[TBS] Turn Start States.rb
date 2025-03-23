#==============================================================================
# TBS Turn start states
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 12/03/2025
# Requires: [TBS] by Timtrack or any script that adds on_turn_start method to Game_Battler
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TurnStartStates"] = true #set to false if you wish to disable it

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows some states to be removed at the begining of turns instead of the end
# Useful when you want states like guard to stay up to your next turn.
#
# Put <remove_on_turn_starts> in the notetags of your state to use it
#==============================================================================
# Installation: put it below TBS core or any script that has already defined
# on_turn_start method for Game_Battlers
#==============================================================================
# Terms of use: free for commercial and non-commercial projects, credit for
# this script is not mandatory
#==============================================================================

module TurnStartStates
  module REGEXP
    RM_ON_TURN_STARTS       = /<remove_on_turn_starts>/i
  end

  #the id should be different from 0,1,2 as they are used by None, on_action_end and on_turn_end
  #if other scripts are changing attribute auto_removal_timing from RPG::State, then you should change this value to a free one
  TURN_START_RM_ID = 3
end

if $imported["TIM-TurnStartStates"]
  #============================================================================
  # DataManager
  #============================================================================
  module DataManager
    #--------------------------------------------------------------------------
    # alias method: load_database
    #--------------------------------------------------------------------------
    class <<self; alias load_database_tss load_database; end
    def self.load_database
      load_database_tss
      load_notetags_tss
    end

    #--------------------------------------------------------------------------
    # new method: load_notetags_tss
    #--------------------------------------------------------------------------
    def self.load_notetags_tss
      for s in $data_states
        next if s.nil?
        s.load_notetags_tss
      end
    end
  end # DataManager

  #============================================================================
  # RPG::State
  #============================================================================
  class RPG::State
    #--------------------------------------------------------------------------
    # common cache: load_notetags_height
    #--------------------------------------------------------------------------
    def load_notetags_tss
      #---
      self.note.split(/[\r\n]+/).each { |line|
        case line
        #---
        when TurnStartStates::REGEXP::RM_ON_TURN_STARTS
          @auto_removal_timing = TurnStartStates::TURN_START_RM_ID
        end
        #---
      } # self.note.split
      #---
    end
  end # RPG::States

  #============================================================================
  # Game_Battler
  #============================================================================
  class Game_Battler
    #--------------------------------------------------------------------------
    # alias method: on_turn_start -> assumes that on_turn_start is already defined!
    #--------------------------------------------------------------------------
    alias on_turn_start_tss on_turn_start
    def on_turn_start
      remove_states_auto(TurnStartStates::TURN_START_RM_ID)
      on_turn_start_tss
    end
  end
end #imported TIM-TurnStartStates
