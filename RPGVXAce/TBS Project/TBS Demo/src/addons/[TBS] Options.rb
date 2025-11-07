#==============================================================================
# TBS Option Menu
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 19/10/2025
# Requires: [TBS] by Timtrack
# Special thanks to Yanfly for Yanfly's System Options this script takes
# inspiration from
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Settings"] = true #set to false if you wish to disable the modifications
if $imported["TIM-TBS-Settings"]

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 10/04/2025: first version
# 19/10/2025: changed control with left/right buttons, automatically hides the
# range color options when a range file is used
#==============================================================================
# Description
#------------------------------------------------------------------------------
# Adds a config menu that is heavily inspired by Yanfly System Options
# The configuration menu allows to set multiple values from $game_system:
# help_window     toggle the help_window in actor commands menu
# highlight_units toggle the units in transparency and above any tile to better see them
# turn_id         toggle the position of the battler in the turnwheel
# pre_place       toggle to place the party members at the strat of battle randomly (if places are available, the memebrs may still be moved)
# team_sprite     toggle the team affiliation circle
# preview_damage  toggle to display an estmation of the damage perfored by an ability on the targets
#
# confirm_x       toggle to skip or ask given the action the confirm menu
# x_color         to set the color of the range sprites if no file is used
# anim_range      toggle to chose if the non-file range sprites are animated
#
# (the values modified are already defined in [TBS] Core)
#
# Like Yanfly's settings menu, you may add custom variables and switches by
# modifying CUSTOM_SWITCHES and CUSTOM_VARIABLES
#
# The settings menu can be accessed from the global command windows from place
# and battle phases. COMMANDS is the list of settings used.
#
# If you wish to add your own setting (that is neither a variable nor a switch):
# 1 - create an entry in COMMAND_VOCAB
# :my_setting => [name,options_names,description]
# 2 - add :my_setting to COMMANDS array
# 3 - add :my_setting to BOOLEAN_COMMANDS or COLOR_COMMANDS arrays depending on the type
# 4 - create an attribute in $game_system called @my_setting (must be the same name!)
# You are done! For more specific settings, either use variables/switches or explore the code
#==============================================================================
# Installation: put it below TBS core
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

module TBS
  module Options

    #The commands, in their order, comment or change the order to fit your own view
    COMMANDS = [
      :help_window,
      :highlight_units,
      :turn_id,
      :pre_place,
      :team_sprite,
      :preview_damage,
      :area_blink,
      :area_blink_color,
      :blank, #a white space
      :confirm_attack,
      :confirm_skill,
      :confirm_item,
      :confirm_move,
      :confirm_wait,
      :confirm_skip_turn,
      :blank, #a white space
      :attack_color,
      :attack_skill_color,
      :help_skill_color,
      :move_color,
      :place_color,
      :anim_range,
      :blank, #a white space
      #:variable_1, #to add a variable for instance
      #swicth_1, #to add a game switch
      :save, #saves the settings
      :reset, #reset the settings to their default values (except variables and switches)
      :discard, #discard unsaved changes
    ] # Do not remove this.
    #--------------------------------------------------------------------------
    # - Custom Switches -
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # If you want your game to have system options other than just the ones
    # listed above, you can insert custom switches here to produce such an
    # effect. Adjust the settings here as you see fit.
    #--------------------------------------------------------------------------
    CUSTOM_SWITCHES ={
    # -------------------------------------------------------------------------
    # :switch    => [Switch, Name, Off Text, On Text,
    #                Help Window Description
    #               ], # Do not remove this.
    # -------------------------------------------------------------------------
      :switch_1  => [ 1, "Custom Switch 1", "OFF", "ON",
                     "Help description used for custom switch 1."
                    ],
    # -------------------------------------------------------------------------
      :switch_2  => [ 2, "Custom Switch 2", "OFF", "ON",
                     "Help description used for custom switch 2."
                    ],
    # -------------------------------------------------------------------------
    } # Do not remove this.

    #--------------------------------------------------------------------------
    # - Custom Variables -
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # If you want your game to have system options other than just the ones
    # listed above, you can insert custom variables here to produce such an
    # effect. Adjust the settings here as you see fit.
    #--------------------------------------------------------------------------
    CUSTOM_VARIABLES ={
    # -------------------------------------------------------------------------
    # :variable   => [Variable, Name, Colour1, Colour2, Min, Max,
    #                 Help Window Description
    #                ], # Do not remove this.
    # -------------------------------------------------------------------------
      :variable_1 => [ 1, "Custom Variable 1", 9, 1, -100, 100,
                      "Help description used for custom variable 1.\n" +
                      "Hold SHIFT to change by 10."
                     ],
    # -------------------------------------------------------------------------
      :variable_2 => [ 2, "Custom Variable 2", 10, 2, -10, 10,
                      "Help description used for custom variable 2."
                     ],
    } # Do not remove this.

    COMMAND_VOCAB = {
    # -------------------------------------------------------------------------
    # :command    => [Command Name, [Option1, Option2],
    #                 Help Window Description,
    #                ], # Do not remove this.
    # -------------------------------------------------------------------------
      :blank      => ["", [],
                      ""
                     ], # Do not remove this.
    # -------------------------------------------------------------------------
      :help_window  => ["Help Window", ["Hide", "Show"],
                      "Display a small text to describe selected actions."
                      ], # Do not remove this.
      :highlight_units  => ["Transparent units", ["No", "Yes"],
                      "If set to yes, will display the units above any\n"+
                      "tile with transparency for better detection"
                     ], # Do not remove this.
      :turn_id     => ["Turn numbers", ["Hide", "Show"],
                      "Displays the place in turn below each unit."
                     ], # Do not remove this.
      :team_sprite => ["Team circles", ["Hide", "Show"],
                      "Displays the circle the team affiliation \nbelow each unit."
                     ], # Do not remove this.
      :pre_place  => ["Preplace party members", ["No", "Yes"],
                      "Will automatically put the first members\n" +
                      "of the party in random starting places if available."
                      ], # Do not remove this.
      :preview_damage  => ["Damage preview", ["No", "Yes"],
                      "If set to yes, will display a rough estimation\n" +
                      "of the damage done to units when casting an ability."
                      ], # Do not remove this.
      :anim_range     => ["Animate ranges", ["No", "Yes"],
                      "If set to yes, will dynamically change the\n" +
                      "opacity of the ranges displayed."
                      ], # Do not remove this.
      :area_blink      => ["Highlight units", ["No", "Yes"],
                      "If set to yes, will highlight units affected by\n"+
                      "selected ability and grey units outside."
                      ], # Do not remove this.
      :area_blink_color => ["Colored highlight", ["No", "Yes"],
                      "If set to yes, will blink units affected by\n"+
                      "selected ability based on friendship with caster."
                      ], # Do not remove this.
    # -------------------------------------------------------------------------
      :confirm_attack  => ["Confirm attack", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \nattacking."
                      ], # Do not remove this.
      :confirm_skill  => ["Confirm skill", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \ncasting a spell."
                      ], # Do not remove this.
      :confirm_item  => ["Confirm item use", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \nusing items."
                      ], # Do not remove this.
      :confirm_move  => ["Confirm move", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \nmoving to a cell."
                     ], # Do not remove this.
      :confirm_wait  => ["Confirm wait", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \npicking a direction."
                     ], # Do not remove this.
      :confirm_skip_turn  => ["Confirm skip turn", ["No", "Yes"],
                      "If set to no, will not ask for confirmation when \nskiping a turn."
                     ], # Do not remove this.
    # -------------------------------------------------------------------------
      :attack_color => ["Attack range", [],
                      "Change the color of attack range and area\n" +
                      "Use right or left arrow to change the color"
                     ], # Do not remove this.
      :attack_skill_color => ["Offensive range", [],
                      "Change the color of offensive abilities range and \narea. " +
                      "Use right or left arrow to change the color"
                     ], # Do not remove this.
      :help_skill_color => ["Help range", [],
                      "Change the color of helpful abilities range and \narea. " +
                      "Use right or left arrow to change the color"
                     ], # Do not remove this.
      :move_color => ["Move range", [],
                      "Change the color of move range\n" +
                      "Use right or left arrow to change the color"
                     ], # Do not remove this.
      :place_color => ["Place cells", [],
                      "Change the color of place cells in prebattle phase\n" +
                      "Use right or left arrow to change the color"
                      ], # Do not remove this.
    # -------------------------------------------------------------------------
      :save =>      ["Save changes", [],
                     "Save the changes"
                     ], # Do not remove this.
      :discard =>   ["Discard changes", [],
                     "Discards the modifications to the parameters"
                     ], # Do not remove this.
      :reset =>      ["Reset changes", [],
                      "Set the default value to each parameter"
                     ], # Do not remove this.
    # -------------------------------------------------------------------------
    } # Do not remove this.

#==============================================================================
# Changing things below is at your own risk!
#==============================================================================

    #will suggest a color from TBS::Colors list:
    COLOR_COMMANDS = [:attack_color, :attack_skill_color, :help_skill_color,
                      :move_color, :place_color]
    #will be toggles between true and false values
    BOOLEAN_COMMANDS = [:help_window, :highlight_units, :turn_id, :pre_place,
                        :team_sprite, :preview_damage,:anim_range,:area_blink,
                        :area_blink_color]
    #will be toggles between true and false values and will fetch a specific object instead of a sigle attribute
    CONFIRM_COMMANDS = [:confirm_attack, :confirm_skill, :confirm_item, :confirm_move, :confirm_wait, :confirm_skip_turn]
    #the symbol in the hash table corresponding to the confirm_commands
    CONFIRM_SYMB = {:confirm_attack => :attack, :confirm_skill => :skill,
                    :confirm_item => :item, :confirm_move => :move,
                    :confirm_wait => :wait, :confirm_skip_turn => :skip_turn}
    #allows the okay button, results are handled by Scene
    OK_COMMANDS = [:save, :reset, :discard]
    #won't display anything except their name, are not associated to a value
    NO_VALUE_COMMANDS = [:blank, :save, :reset, :discard]

    #--------------------------------------------------------------------------
    # new method: get_value -> a getter to find which value correspond to the command
    #--------------------------------------------------------------------------
    def self.get_value(symb)
      return nil if NO_VALUE_COMMANDS.include?(symb)
      return $game_variables[CUSTOM_VARIABLES[symb][0]] if CUSTOM_VARIABLES.include?(symb)
      return $game_switches[CUSTOM_SWITCHES[symb][0]] if CUSTOM_SWITCHES.include?(symb)
      return $game_system.confirm_hash[CONFIRM_SYMB[symb]] if CONFIRM_COMMANDS.include?(symb)
      attr_name = "@"+symb.id2name
      v = $game_system.instance_variable_get(attr_name)
      return v unless COLOR_COMMANDS.include?(symb)
      i = TBS::Colors.index(v)
      return i ? i : 0
    end
    #--------------------------------------------------------------------------
    # new method: set_value -> a setter to modify the value corresponding to the
    # command, called when saving changes
    #--------------------------------------------------------------------------
    def self.set_value(symb,v)
      return nil if NO_VALUE_COMMANDS.include?(symb)
      return $game_variables[CUSTOM_VARIABLES[symb][0]] = v if CUSTOM_VARIABLES.include?(symb)
      return $game_switches[CUSTOM_SWITCHES[symb][0]] = v if CUSTOM_SWITCHES.include?(symb)
      return $game_system.confirm_hash[CONFIRM_SYMB[symb]] = v if CONFIRM_COMMANDS.include?(symb)
      v = TBS::Colors[v] if COLOR_COMMANDS.include?(symb)
      attr_name = "@"+symb.id2name
      return $game_system.instance_variable_set(attr_name,v)
    end
  end #Options
end #TBS

#==============================================================================
# Scene_TBS_Battle -> adds the option menu and reference it, the calls of some
# methods is already handled in Core as long as $imported["TIM-TBS-Settings"] is true
#==============================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # new method: create_option_window
  #--------------------------------------------------------------------------
  def create_option_window
    @options_window = Window_TBS_Options.new(@help_window)
    @options_window.set_handler(:cancel, method(:cancel_options_window))
    @options_window.set_handler(:save, method(:options_window_save))
    @options_window.set_handler(:reset, method(:options_window_reset))
    @options_window.set_handler(:discard, method(:options_window_discard))
    @window_list.push(@options_window)
  end
  #--------------------------------------------------------------------------
  # alias method: open_global_commands -> closes the option menu too
  #--------------------------------------------------------------------------
  alias tbs_options_open_global_commands open_global_commands
  def open_global_commands
    @spriteset.refresh_tile_sprites
    @help_window.hide
    @options_window.close
    tbs_options_open_global_commands
  end
  #--------------------------------------------------------------------------
  # new method: open_options_window
  #--------------------------------------------------------------------------
  def open_options_window
    @place_command_window.close
    @party_command_window.close
    @help_window.show
    @options_window.open
    @options_window.activate
  end
  #--------------------------------------------------------------------------
  # new method: options_window_save -> when calling the save command from settings
  #--------------------------------------------------------------------------
  def options_window_save
    @options_window.save_changes
    @options_window.activate
  end
  #--------------------------------------------------------------------------
  # new method: options_window_discard -> when calling the discard command
  # from settings ot when opening the window
  #--------------------------------------------------------------------------
  def options_window_discard
    @options_window.discard_changes
    @options_window.activate
  end
  #--------------------------------------------------------------------------
  # new method: options_window_reset -> when calling the reset command from settings
  #--------------------------------------------------------------------------
  def options_window_reset
    $game_system.reset_default_tbs_config
    @options_window.discard_changes
    @options_window.activate
  end
  #--------------------------------------------------------------------------
  # new method: cancel_options_window -> when closing the settings
  #--------------------------------------------------------------------------
  def cancel_options_window
    return open_global_commands unless @options_window.has_changed?
    setup_confirm_window(:settings)
  end
end #Scene_TBS_Battle

#==============================================================================
# new class: Window_TBS_Options -> lists and changes the values of the settings
# it contains an hash table @my_data that stores the values before saving them
# to $game_system, $game_variables and $game_switches
#==============================================================================
class Window_TBS_Options < Window_Command
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(help_window)
    @help_window = help_window
    super(0, @help_window.height)
    deactivate
    relocate(5)
    self.y = [self.y, @help_window.height].max
    self.openness = 0
    refresh
  end

  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width
    return 320#Graphics.width
  end

  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height
    return 288#Graphics.height - @help_window.height
  end

  #--------------------------------------------------------------------------
  # update_help
  #--------------------------------------------------------------------------
  def update_help
    if current_symbol == :custom_switch || current_symbol == :custom_variable
      text = @help_descriptions[current_ext]
    else
      text = @help_descriptions[current_symbol]
    end
    text = "" if text.nil?
    @help_window.set_text(text)
  end

  #--------------------------------------------------------------------------
  # ok_enabled?
  #--------------------------------------------------------------------------
  def ok_enabled?
    return ok_cmd?(current_symbol) || toggle_cmd?(current_symbol) || current_symbol == :custom_switch
  end

  #--------------------------------------------------------------------------
  # process_ok -> will modify toggle or swicthes when :C is pressed
  #--------------------------------------------------------------------------
  def process_ok
    symbol = current_symbol
    return super unless toggle_cmd?(symbol) || symbol == :custom_switch
    Sound.play_ok
    Input.update
    @my_data[symbol] = !@my_data[symbol]
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    @help_descriptions = {}
    return unless @my_data
    for command in TBS::Options::COMMANDS
      next if auto_ignore_command?(command)
      if TBS::Options::COMMAND_VOCAB.include?(command)
        add_command(TBS::Options::COMMAND_VOCAB[command][0], command)
        @help_descriptions[command] = TBS::Options::COMMAND_VOCAB[command][2]
      else
        process_custom_switch(command)
        process_custom_variable(command)
      end
    end
  end

  #--------------------------------------------------------------------------
  # auto_ignore_command? -> automatically remove the symbol from the command
  # list if system knows it's useless, like colors commands when a sprite
  # is available
  #--------------------------------------------------------------------------
  def auto_ignore_command?(symb)
    return false unless color_cmd?(symb)
    type = TBS::Options::COLOR_COMMANDS.index(symb)
    filename = TBS.range_picture(type)
    return filename && !filename.empty?
  end

  #--------------------------------------------------------------------------
  # process_custom_switch
  #--------------------------------------------------------------------------
  def process_custom_switch(command)
    return unless TBS::Options::CUSTOM_SWITCHES.include?(command)
    name = TBS::Options::CUSTOM_SWITCHES[command][1]
    add_command(name, :custom_switch, true, command)
    @help_descriptions[command] = TBS::Options::CUSTOM_SWITCHES[command][4]
  end

  #--------------------------------------------------------------------------
  # process_custom_variable
  #--------------------------------------------------------------------------
  def process_custom_variable(command)
    return unless TBS::Options::CUSTOM_VARIABLES.include?(command)
    name = TBS::Options::CUSTOM_VARIABLES[command][1]
    add_command(name, :custom_variable, true, command)
    @help_descriptions[command] = TBS::Options::CUSTOM_VARIABLES[command][6]
  end

  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    reset_font_settings
    rect = item_rect(index)
    contents.clear_rect(rect)
    cmd = @list[index][:symbol]
    return draw_color_choice(rect, index, cmd) if color_cmd?(cmd)
    return draw_toggle(rect, index, cmd) if toggle_cmd?(cmd)
    return draw_text(item_rect_for_text(index), command_name(index), 1) if ok_cmd?(cmd)
    case cmd
    when :custom_switch
      draw_custom_switch(rect, index, @list[index][:ext])
    when :custom_variable
      draw_custom_variable(rect, index, @list[index][:ext])
    end
  end

  #--------------------------------------------------------------------------
  # color_cmd?, toggle_cmd?, ok_cmd?
  #--------------------------------------------------------------------------
  def color_cmd?(symbol)
    TBS::Options::COLOR_COMMANDS.include?(symbol)
  end

  def toggle_cmd?(symbol)
    (TBS::Options::BOOLEAN_COMMANDS + TBS::Options::CONFIRM_COMMANDS).include?(symbol)
  end

  def ok_cmd?(symbol)
    TBS::Options::OK_COMMANDS.include?(symbol)
  end

  #--------------------------------------------------------------------------
  # draw_window_tone
  #--------------------------------------------------------------------------
  def draw_color_choice(rect, index, symbol)
    name = @list[index][:name]
    draw_text(0, rect.y, contents.width/2, line_height, name, 1)

    color = TBS::Colors[@my_data[symbol]]
    color_rect = Rect.new(3*contents.width/4 -9, rect.y+3, 18, 18)
    self.contents.fill_rect(color_rect, color)
    return
  end

  #--------------------------------------------------------------------------
  # draw_toggle
  #--------------------------------------------------------------------------
  def draw_toggle(rect, index, symbol)
    name = @list[index][:name]
    draw_text(0, rect.y, contents.width/2, line_height, name, 1)
    #---
    dx = contents.width / 2
    enabled = @my_data[symbol]
    dx = contents.width/2
    #change_color(normal_color, !enabled)
    id = enabled ? 1 : 0
    option = TBS::Options::COMMAND_VOCAB[symbol][1][id]
    draw_text(dx, rect.y, contents.width/2, line_height, option, 1)
    #dx += contents.width/4
    #change_color(normal_color, enabled)
    #option2 = TBS::Options::COMMAND_VOCAB[symbol][2]
    #draw_text(dx, rect.y, contents.width/4, line_height, option2, 1)
  end

  #--------------------------------------------------------------------------
  # cursor_right
  #--------------------------------------------------------------------------
  def draw_custom_switch(rect, index, ext)
    name = @list[index][:name]
    draw_text(0, rect.y, contents.width/2, line_height, name, 1)
    #---
    dx = contents.width / 2
    enabled = @my_data[ext]
    dx = contents.width/2
    id = enabled ? 3 : 2
    option = TBS::Options::CUSTOM_SWITCHES[ext][id]
    draw_text(dx, rect.y, contents.width/2, line_height, option, 1)
  end

  #--------------------------------------------------------------------------
  # draw_custom_variable
  #--------------------------------------------------------------------------
  def draw_custom_variable(rect, index, ext)
    name = @list[index][:name]
    draw_text(0, rect.y, contents.width/2, line_height, name, 1)
    #---
    dx = contents.width / 2
    value = @my_data[ext]
    colour1 = text_color(TBS::Options::CUSTOM_VARIABLES[ext][2])
    colour2 = text_color(TBS::Options::CUSTOM_VARIABLES[ext][3])
    minimum = TBS::Options::CUSTOM_VARIABLES[ext][4]
    maximum = TBS::Options::CUSTOM_VARIABLES[ext][5]
    rate = (value - minimum).to_f / [(maximum - minimum).to_f, 0.01].max
    dx = contents.width/2
    draw_gauge(dx, rect.y, contents.width - dx - 48, rate, colour1, colour2)
    draw_text(dx, rect.y, contents.width - dx - 48, line_height, value, 2)
  end

  #--------------------------------------------------------------------------
  # cursor_right
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    cursor_change(:right)
    super(wrap)
  end

  #--------------------------------------------------------------------------
  # cursor_left
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    cursor_change(:left)
    super(wrap)
  end

  #--------------------------------------------------------------------------
  # cursor_change
  #--------------------------------------------------------------------------
  def cursor_change(direction)
    return change_range_color(direction) if color_cmd?(current_symbol)
    return change_toggle(direction) if toggle_cmd?(current_symbol)
    case current_symbol
    when :custom_switch
      change_custom_switch(direction)
    when :custom_variable
      change_custom_variables(direction)
    end
  end

  #--------------------------------------------------------------------------
  # change_window_tone
  #--------------------------------------------------------------------------
  def change_range_color(direction)
    Sound.play_cursor
    value = direction == :left ? -1 : 1
    v = @my_data[current_symbol]
    v = (v+value) % TBS::Colors.size
    @my_data[current_symbol] = v
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # change_toggle
  #--------------------------------------------------------------------------
  def change_toggle(direction)
    value = direction == :left ? false : true
    current_case = @my_data[current_symbol]
    @my_data[current_symbol] = value
    Sound.play_cursor if value != current_case
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # change_custom_switch
  #--------------------------------------------------------------------------
  def change_custom_switch(direction)
    value = direction == :left ? false : true
    ext = current_ext
    current_case = @my_data[ext]
    @my_data[ext] = value
    Sound.play_cursor if value != current_case
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # change_custom_variables
  #--------------------------------------------------------------------------
  def change_custom_variables(direction)
    Sound.play_cursor
    value = direction == :left ? -1 : 1
    value *= 10 if Input.press?(:A)
    ext = current_ext
    minimum = TBS::Options::CUSTOM_VARIABLES[ext][4]
    maximum = TBS::Options::CUSTOM_VARIABLES[ext][5]
    @my_data[ext] += value
    @my_data[ext] = [[@my_data[ext], minimum].max, maximum].min
    draw_item(index)
  end

  #--------------------------------------------------------------------------
  # save_changes
  #--------------------------------------------------------------------------
  def save_changes
    TBS::Options::COMMANDS.each do |cmd|
      TBS::Options.set_value(cmd,@my_data[cmd])
    end
  end

  #--------------------------------------------------------------------------
  # discard_changes
  #--------------------------------------------------------------------------
  def discard_changes
    @my_data = {}
    TBS::Options::COMMANDS.each do |cmd|
      @my_data[cmd] = TBS::Options.get_value(cmd)
    end
    refresh
  end

  #--------------------------------------------------------------------------
  # has_changed? -> the condition to call the confirm window when closing
  #--------------------------------------------------------------------------
  def has_changed?
    TBS::Options::COMMANDS.any? {|cmd| @my_data[cmd] != TBS::Options.get_value(cmd)}
  end

  #--------------------------------------------------------------------------
  # override method: open -> will set @my_data to the system values when opening
  # this window.
  #--------------------------------------------------------------------------
  def open
    discard_changes
    super
  end
end #Window_TBS_Options

end #$imported["TIM-TBS-Settings"]
