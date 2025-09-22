# ╔═══════════════════════════════════════════════╦════════════════════╗
# ║ Title: Title Command Options                  ║  Version: 1.00a    ║
# ║ Author: Roninator2                            ║                    ║
# ║ Modified by Timtrack                          ║                    ║
# ╠═══════════════════════════════════════════════╬════════════════════╣
# ║ Function:                                     ║   Date Created     ║
# ║    Show additional Commands after winning     ╠════════════════════╣
# ║    on title screen                            ║    16 Aug 2025     ║
# ╚═══════════════════════════════════════════════╩════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Requires: Global Save script to preserve switch data               ║
# ╚════════════════════════════════════════════════════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Brief Description:                                                 ║
# ║   Script allows using additional commands when switch is active    ║
# ╚════════════════════════════════════════════════════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Instructions:                                                      ║
# ║   Configure below and test                                         ║
# ║   This modified version is meant to be used with Hime's Preserve   ║
# ║   Data and Timtrack's Hide Title Menu Commands                     ║
# ║   Put this script below the other two scripts                      ║
# ╚════════════════════════════════════════════════════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Updates:                                                           ║
# ║ 1.00  - 16 Aug 2025 - Script finished                              ║
# ║ 1.00a - 20 Aug 2025 - 'Uniformisation' by Timtrack                 ║
# ╚════════════════════════════════════════════════════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Credits and Thanks:                                                ║
# ║   Roninator2                                                       ║
# ║                                                                    ║
# ╚════════════════════════════════════════════════════════════════════╝
# ╔════════════════════════════════════════════════════════════════════╗
# ║ Terms of use:                                                      ║
# ║  Follow the original Authors terms of use where applicable         ║
# ║    - When not made by me (Roninator2)                              ║
# ║  Free for all uses in RPG Maker except nudity                      ║
# ║  Anyone using this script in their project before these terms      ║
# ║  were changed are allowed to use this script even if it conflicts  ║
# ║  with these new terms. New terms effective 03 Apr 2024             ║
# ║  No part of this code can be used with AI programs or tools        ║
# ║  Credit must be given                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

module Title_Menu_Options_8BG
  TITLE_CMD_LIST = [
    #[symbol, text, switch_id, start_map_id, start_x, start_y],
    [:challenge, "Challenge Mode", 1, 2, 12, 9],
    [:bossrush, "Boss Ruch Mode", 2, 2, 15, 4],
  ]
end

# Edit this to add more options
module DataManager
  include Title_Menu_Options_8BG
  #new
  def self.setup_extra_modes(symb)
    l = TITLE_CMD_LIST.find {|l| l[0] == symb}
    create_game_objects
    $game_party.setup_starting_members
    $game_map.setup(l[3])
    $game_player.moveto(l[4], l[5])
    $game_player.refresh
    Graphics.frame_count = 0
  end
end #DataManager

# only edit the command_window options below to add more
class Scene_Title < Scene_Base
  include Title_Menu_Options_8BG
  #alias
  alias r2_title_options_create_command_window create_command_window
  def create_command_window
    r2_title_options_create_command_window
    TITLE_CMD_LIST.each do |l|
      @command_window.set_handler(l[0], method(:command_extra_mode))
    end
  end
  
  #new
  def command_extra_mode
    DataManager.setup_extra_modes(@command_window.current_symbol) # current selected mode
    common_new_game_setup
  end
  
  #new
  def common_new_game_setup
    close_command_window
    fadeout_all
    $game_map.autoplay
    SceneManager.goto(Scene_Map)
  end
end #Scene_Title

# edit the command list below to add more
class Window_TitleCommand < Window_Command
  include Title_Menu_Options_8BG
  #overwrite
  def make_command_list
    add_command(Vocab::new_game, :new_game)
    add_command(Vocab::continue, :continue, continue_enabled)
    TITLE_CMD_LIST.each do |l|
      add_command(l[1], l[0], $game_switches[l[2]])
    end
    add_command(Vocab::shutdown, :shutdown)
  end
end #Window_TitleCommand