#==============================================================================
# Common event menu VX Ace v1.2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 22/09/2025 
#==============================================================================
# Update history: 
# 21/09/2025: v1.0 - Initial release
# 22/09/2025: v1.1 - Updated description and fixed a disable_confirm bug,
#                    you can now replace $game_system.common_event_menu with
#                    common_event_menu in your script calls for lighter code
# 22/09/2025: v1.2 - Added more compatibility with Yanfly's Common Event Shop
#                    (distinguish internal values for icon and help description)
#==============================================================================
# Description: recreates Yanfly's common event menu for MV in VX Ace
# Here is what you can put in common events comments (following a similar patern 
# to http://www.yanfly.moe/wiki/Common_Event_Menu_(YEP)):
#
#  <Menu Name: x>
#  - This changes the appearance of the common event's text when displayed in
#  the common event menu list. If this tag isn't used, the text displayed
#  will be the common event's name. You can use text codes.
#
#  <Icon: x>
#  - This changes the icon of the common event to x. If this tag isn't used,
#  the icon used will be the one set in the script's parameters.
#
#  <Picture: x>
#  - This sets a picture to be associated with this common event when it is
#  highlighted. If this isn't used, no picture will be displayed and it will
#  be left empty.
#
#  <Help Description>
#   text
#   text
#  </Help Description>
#  - This sets the help description used for the common event when it is
#  selected in the common even menu list. Multiple lines in the comments will be 
#  strung together. Use | for a line break. Text codes may be used inside of the 
#  help description.
#
#  <Subtext>
#   text
#   text
#  </Subtext>
#  - This sets the subtext used for the common event menu's subtext window
#  while this common event is selected in the common event menu list. Multiple 
#  lines in the comments will be strung together. Use | for a line break. Text 
#  codes may be used inside of the help description.
#
#
#
# In your menu you can put the following script calls to setup your menu:
#
# $game_system.common_event_menu.clear
#  - This clears all the listed common events from the Common Event Menu Data
#  pool meaning it has to be filled again. You can do so with the next script call:
#
# ---
#
#  $game_system.common_event_menu.add(1)
#     - or -
#  $game_system.common_event_menu.add(2,3,4,5)
#     - or -
#  - This will add the listed common event numbers into the common event list
#  that will be shown in the common event menu.
#
#  ---
#
#  $game_system.common_event_menu.set_common_event_cancel(20)
#  - This will set the cancel button for the common event menu to run common
#  event 20 when canceled. If it is left at 0, no event will run, but the
#  menu can allow the cancel button to be pressed (and prematurely end it).
#
#  ---
#
#  $game_system.common_event_menu.enable_cancel
#  $game_system.common_event_menu.disable_cancel
#  - This will enable or disable the cancel button for the common event menu from being
#  pressed. Pressing cancel while the common event menu is active will do
#  nothing.
#
#  $game_system.common_event_menu.disable_confirm
#  $game_system.common_event_menu.enable_confirm
#  - This will disable the confirm button for the common event menu from
#  being pressed. This is made for those who wish to use the menu only as a
#  list and not a selectable menu. The Enable version will reenable the
#  confirm function.
#
#  ---
#
#  open_common_event_menu
#  - After you've set everything up, this command will be used to open up the
#  common event menu. All of the common events listed by 
#  $game_system.common_event_menu.add will appear in this list.
#
#  ---
#
#  $game_system.common_event_menu.menu.x = 0
#  $game_system.common_event_menu.menu.y = fitting_height(2)
#  $game_system.common_event_menu.menu.width = Graphics.width/2
#  $game_system.common_event_menu.menu.height = Graphics.height/2 - fitting_height(2)
#  $game_system.common_event_menu.menu.opacity = 255
#  $game_system.common_event_menu.menu.columns = 1
#  - These script calls allow you to adjust the x, y, width, height,
#  opacity, and the number of columns used for the main common event menu
#  list. Make sure all of these settings are done BEFORE the common event
#  menu is opened with the 'open_common_event_menu' script call.
#
#  ---
#
#  $game_system.common_event_menu.menu_help.show
#  $game_system.common_event_menu.menu_help.hide
#  - This will allow you to decide if the help window will be shown or hidden
#  for the next 'open_common_event_menu' plugin command usage.
#
#  $game_system.common_event_menu.menu_help.x = 0
#  $game_system.common_event_menu.menu_help.y = 0
#  $game_system.common_event_menu.menu_help.width = Graphics.width
#  $game_system.common_event_menu.menu_help.height = fitting_height(2)
#  $game_system.common_event_menu.menu_help.opacity = 255
#  - These script calls allow you to adjust the x, y, width, height and
#  opacity of the help window for the common event menu list. Make sure all 
#  of these settings are done BEFORE the common event menu is opened with 
#  the 'open_common_event_menu' script call.
#
#  ---
#
#  $game_system.common_event_menu.menu_picture.show
#  $game_system.common_event_menu.menu_picture.hide
#  - This will allow you to decide if the picture window will be shown or hidden
#  for the next 'open_common_event_menu' plugin command usage.
#
#  $game_system.common_event_menu.menu_picture.x = Graphics.width/2
#  $game_system.common_event_menu.menu_picture.y = fitting_height(2)
#  $game_system.common_event_menu.menu_picture.width = Graphics.width/2
#  $game_system.common_event_menu.menu_picture.height = fitting_height(10)
#  $game_system.common_event_menu.menu_picture.opacity = 255
#  - These script calls allow you to adjust the x, y, width, height and
#  opacity of the picture window for the common event menu list. Make sure all 
#  of these settings are done BEFORE the common event menu is opened with 
#  the 'open_common_event_menu' script call.
#
#  ---
#
#  $game_system.common_event_menu.menu_subtext.show
#  $game_system.common_event_menu.menu_subtext.hide
#  - This will allow you to decide if the subtext window will be shown or hidden
#  for the next 'open_common_event_menu' plugin command usage.
#
#  $game_system.common_event_menu.menu_subtext.x = Graphics.width/2
#  $game_system.common_event_menu.menu_subtext.y = fitting_height(2) + fitting_height(10)
#  $game_system.common_event_menu.menu_subtext.width = Graphics.width/2
#  $game_system.common_event_menu.menu_subtext.height = Graphics.height - fitting_height(2)- fitting_height(10)
#  $game_system.common_event_menu.menu_subtext.opacity = 255
#  - These script calls allow you to adjust the x, y, width, height and
#  opacity of the subtext window for the common event menu list. Make sure all 
#  of these settings are done BEFORE the common event menu is opened with 
#  the 'open_common_event_menu' script call.
#
#  $game_system.common_event_menu.default_setup
#  $game_system.common_event_menu.basic_setup
#  - This allows you to set the common event windows to position themselves
#  to the default setup provided by the script parameters or a basic setup
#  made of just the main list and a help window.
#
#==============================================================================
# Term of use: free for both commercial and non commercial projects, credit is
# required. Please add credit to Yanfly too as this script uses some code from
# common event shop and uses the same interface as his plugin for MV.
#==============================================================================
# Installation: put it above main
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-CommonEventMenu"] = true

module TIM
  module COMMON_EVENT_MENU
    module REGEXP
      MENU_NAME            = /<(?:MENU_NAME|(?:M|m)enu (?:n|N)ame):[ ](.*)>/i
      PICTURE              = /<(?:PICTURE|(?:p|P)icture):[ ](.*)>/i
      ICON_INDEX           = /<(?:ICON|(?:i|I)con):[ ](\d+)>/i
      HELP_DESCRIPTION_ON  = /<(?:HELP_DESCRIPTION|(?:h|H)elp description)>/i
      HELP_DESCRIPTION_OFF = /<\/(?:HELP_DESCRIPTION|(?:h|H)elp description)>/i
      SUBTEXT_ON           = /<(?:SUBTEXT|(?:S|s)ubtext)>/i
      SUBTEXT_OFF          = /<\/(?:SUBTEXT|(?:S|s)ubtext)>/i
    end #REGEXP
    
    DEFAULT_ICON = 0
    HELP_WINDOW_LINES = 2
    PICTURE_WINDOW_LINES = 10
    
    LINE_HEIGHT = 24
    STANDARD_PADDING = 12
    
    def self.fitting_height(line_number)
      line_number * LINE_HEIGHT + STANDARD_PADDING * 2
    end
    
    #==============================================================================
    # Window_Parameters
    #==============================================================================
    class Window_Parameters
      attr_accessor :x, :y, :width, :height, :opacity
      def initialize(x = 0, y = 0, width = 0,height = 0,opacity = 255, show = true)
        @x = x
        @y = y
        @width = width
        @height = height
        @opacity = opacity
        @show = show
      end
      def to_a; [@x,@y,@width,@height]; end
      def show; @show = true; end
      def hide; @show = false; end
      def show?; @show; end
    end #Window_Parameters
    #==============================================================================
    # Window_Select_Parameters
    #==============================================================================
    class Window_Select_Parameters < Window_Parameters
      attr_accessor :columns
      def initialize(x = 0, y = 0, width = 0,height = 0,opacity = 255, columns = 1)
        super(x,y,width,height,opacity)
        @columns = columns
      end
      def to_a; super + [@columns]; end
    end #Window_Select_Parameters
    #==============================================================================
    # CEM_Parameters
    #==============================================================================
    class CEM_Parameters
      attr_reader :list
      attr_reader :menu_cancel_common_event
      attr_reader :menu, :menu_help, :menu_picture, :menu_subtext
      #--------------------------------------------------------------------------
      # method: initialize
      #--------------------------------------------------------------------------
      def initialize
        clear
        set_common_event_cancel(0)
        enable_cancel
        enable_confirm
        default_setup
      end
      
      def clear
        @list = []
      end
      
      def add(*args)
        @list += args
      end
      
      def set_common_event_cancel(id)
        @menu_cancel_common_event = id
      end
      
      def enable_cancel; @cem_cancel = true; end
      def disable_cancel; @cem_cancel = false; end
      def cancel?; @cem_cancel; end
        
      def disable_confirm; @cem_confirm = false; end
      def enable_confirm; @cem_confirm = true; end
      def confirm?; @cem_confirm; end
        
      def fitting_height(line_number)
        TIM::COMMON_EVENT_MENU.fitting_height(line_number)
      end
        
      def default_setup
        h1 = fitting_height(HELP_WINDOW_LINES)
        h2 = fitting_height(PICTURE_WINDOW_LINES)
        @menu = Window_Select_Parameters.new(0, h1, Graphics.width/2, Graphics.height - h1, 255, 1)
        @menu_help = Window_Parameters.new(0, 0, Graphics.width, h1, 255)
        @menu_picture = Window_Parameters.new(Graphics.width / 2, h1, Graphics.width / 2, h2, 255)
        @menu_subtext = Window_Parameters.new(Graphics.width / 2, h1+h2, Graphics.width / 2, Graphics.height - h1-h2, 255)
      end
      
      def basic_setup
        h1 = fitting_height(HELP_WINDOW_LINES)
        @menu = Window_Select_Parameters.new(0, h1, Graphics.width, Graphics.height - h1, 255, 1)
        @menu_help = Window_Parameters.new(0, 0, Graphics.width, h1, 255)
        @menu_picture = Window_Parameters.new
        @menu_subtext = Window_Parameters.new
      end
    end #Game_System
  end #COMMON_EVENT_MENU
end #TIM


#==============================================================================
# Game_System
#==============================================================================
class Game_System
  attr_reader :common_event_menu
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tim_cem_initialize initialize
  def initialize
    @common_event_menu = TIM::COMMON_EVENT_MENU::CEM_Parameters.new
    tim_cem_initialize
  end
end #Game_System

#==============================================================================
# Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # new method: open_common_event_menu
  #--------------------------------------------------------------------------
  def open_common_event_menu
    SceneManager.call(Scene_MenuCommonEvent)
  end
  #--------------------------------------------------------------------------
  # new method: fitting_height
  #--------------------------------------------------------------------------
  def fitting_height(n)
    $game_system.common_event_menu.fitting_height(n)
  end
  #--------------------------------------------------------------------------
  # new method: common_event_menu
  #--------------------------------------------------------------------------
  def common_event_menu
    $game_system.common_event_menu
  end
end #Game_Interpreter

#==============================================================================
# DataManager
#==============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_cem load_database; end
  def self.load_database
    load_database_cem
    load_notetags_cem
  end
  #--------------------------------------------------------------------------
  # new method: load_notetags_cem
  #--------------------------------------------------------------------------
  def self.load_notetags_cem
    groups = [$data_common_events]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_cem
      end
    end
  end
end # DataManager

#==============================================================================
# RPG::CommonEvent
#==============================================================================
class RPG::CommonEvent
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :cem_description
  attr_accessor :cem_icon_index
  attr_accessor :picture
  attr_accessor :menu_name
  attr_accessor :subtext
  #--------------------------------------------------------------------------
  # common cache: load_notetags_cem
  #--------------------------------------------------------------------------
  def load_notetags_cem
    @picture = ""
    @menu_name = name
    @cem_description = ""
    @subtext = ""
    @cem_icon_index = TIM::COMMON_EVENT_MENU::DEFAULT_ICON
    cem_help_description_on = false
    subtext_on = false
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::COMMON_EVENT_MENU::REGEXP::ICON_INDEX
        @cem_icon_index = $1.to_i
      when TIM::COMMON_EVENT_MENU::REGEXP::MENU_NAME
        @menu_name = $1.to_s
      when TIM::COMMON_EVENT_MENU::REGEXP::PICTURE
        @picture = $1.to_s
      #---
      when TIM::COMMON_EVENT_MENU::REGEXP::HELP_DESCRIPTION_ON
        cem_help_description_on = true
      when TIM::COMMON_EVENT_MENU::REGEXP::HELP_DESCRIPTION_OFF
        cem_help_description_on = false
      when TIM::COMMON_EVENT_MENU::REGEXP::SUBTEXT_ON
        subtext_on = true
      when TIM::COMMON_EVENT_MENU::REGEXP::SUBTEXT_OFF
        subtext_on = false
      else
        @cem_description += line.to_s if cem_help_description_on
        @subtext += line.to_s if subtext_on
      #---
      end
    } # self.note.split
    #---
    @cem_description.gsub!(/[|]/i) { "\n" }
    @subtext.gsub!(/[|]/i) { "\n" }
  end
  #--------------------------------------------------------------------------
  # new method: note (copy from Yanfly's common event shop)
  #--------------------------------------------------------------------------
  def note
    @note = ""
    @list.each { |event|
      next if event.nil?
      next unless [108, 408].include?(event.code)
      @note += event.parameters[0] + "\r\n"
    } # Do not remove
    return @note
  end
end # RPG::CommonEvent

#==============================================================================
# Window_CEM
#==============================================================================
class Window_CEM < Window_Base
  attr_accessor :cem_cmd_window
  #--------------------------------------------------------------------------
  # * Object Initialization
  # cem_params is a Window_Parameters object
  #--------------------------------------------------------------------------
  def initialize(cem_params)#x, y, width, height, opacity = 255)
    @event_id = 0
    super(*cem_params)
    self.opacity = cem_params.opacity
    hide unless cem_params.show?
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    refresh if @cem_cmd_window && @cem_cmd_window.current_common_event_id != @event_id
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    @event_id = @cem_cmd_window.current_common_event_id if @cem_cmd_window
    contents.clear
    draw_contents
  end
  #--------------------------------------------------------------------------
  # new method: draw_contents
  #--------------------------------------------------------------------------
  def draw_contents
  end
end #Window_CEM

#==============================================================================
# Window_CEM_Picture
#==============================================================================
class Window_CEM_Picture < Window_CEM
  #--------------------------------------------------------------------------
  # override method: draw_contents
  #--------------------------------------------------------------------------
  def draw_contents
    ce = $data_common_events[@event_id]
    return unless ce
    bitmap = Cache.picture(ce.picture)
    rect = Rect.new(0,0,bitmap.width,bitmap.height)
    contents.blt(0, 0, bitmap, rect)
    bitmap.dispose
  end
end #Window_CEM_Picture

#==============================================================================
# Window_CEM_Subtext
#==============================================================================
class Window_CEM_Subtext < Window_CEM
  #--------------------------------------------------------------------------
  # override method: draw_contents
  #--------------------------------------------------------------------------
  def draw_contents
    ce = $data_common_events[@event_id]
    return unless ce
    draw_text_ex(4, 0, ce.subtext)
  end
end #Window_CEM_Subtext

#==============================================================================
# Window_CEM_Subtext
#==============================================================================
class Window_CEM_Help < Window_Help
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    w_params = $game_system.common_event_menu.menu_help
    super(TIM::COMMON_EVENT_MENU::HELP_WINDOW_LINES)
    self.x = w_params.x
    self.y = w_params.y
    self.width = w_params.width
    self.height = w_params.height
    self.opacity = w_params.opacity
    hide unless w_params.show?
  end
  #--------------------------------------------------------------------------
  # override method: set_item
  #--------------------------------------------------------------------------
  def set_item(item)
    set_text(item ? item.cem_description : "")
  end
end #Window_CEM_Help

#==============================================================================
# Window_CEM_Command -> list of all common events to select
#==============================================================================
class Window_CEM_Command < Window_Command
  attr_reader :common_events
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize
    @w_params = $game_system.common_event_menu.menu
    @common_events = $game_system.common_event_menu.list.dup
    super(@w_params.x,@w_params.y)
    self.opacity = @w_params.opacity
    hide unless @w_params.show?
  end
  #--------------------------------------------------------------------------
  # new method: item
  #--------------------------------------------------------------------------
  def item; current_common_event; end
  #--------------------------------------------------------------------------
  # override method: update_help
  #--------------------------------------------------------------------------
  def update_help; @help_window.set_item(item); end
  #--------------------------------------------------------------------------
  # new method: command_ext
  #--------------------------------------------------------------------------
  def command_ext(index); @list[index][:ext]; end
  #--------------------------------------------------------------------------
  # new method: current_common_event
  #--------------------------------------------------------------------------
  def current_common_event; $data_common_events[current_ext] rescue nil; end
  #--------------------------------------------------------------------------
  # new method: current_common_event_id
  #--------------------------------------------------------------------------
  def current_common_event_id; current_common_event ? current_common_event.id : 0; end
  #--------------------------------------------------------------------------
  # override method: col_max
  #--------------------------------------------------------------------------
  def col_max; @w_params.columns; end
  #--------------------------------------------------------------------------
  # override method: window_width
  #--------------------------------------------------------------------------
  def window_width; @w_params.width; end
  #--------------------------------------------------------------------------
  # override method: window_height
  #--------------------------------------------------------------------------
  def window_height; @w_params.height; end
  #--------------------------------------------------------------------------
  # override method: ok_enabled?
  #--------------------------------------------------------------------------
  def ok_enabled?; handle?(:ok); end
  #--------------------------------------------------------------------------
  # override method: make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    @common_events.each{|id| add_command_common_event(id)}
  end
  #--------------------------------------------------------------------------
  # new method: add_command_common_event
  #--------------------------------------------------------------------------
  def add_command_common_event(id)
    ce = $data_common_events[id]
    add_command(ce.name, :common_event, true, id) if ce
  end
  #--------------------------------------------------------------------------
  # override method: draw_item(index) -> adds an icon if available
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect_for_text(index)
    ce = $data_common_events[command_ext(index)]
    draw_common_event(ce, rect.x, rect.y, command_enabled?(index))#, rect.width)
  end
  #--------------------------------------------------------------------------
  # new method: draw_common_event
  #--------------------------------------------------------------------------
  def draw_common_event(ce, dx, dy, enabled = true)#, dw = 172)
    return if ce.nil?
    draw_icon(ce.cem_icon_index, dx, dy, enabled)
    draw_text_ex(dx+24, dy, ce.menu_name)
    #draw_text(dx+24, dy, dw, line_height, ce.menu_name)
  end
end #Window_CEM_Command

#==============================================================================
# Scene_MenuCommonEvent
#==============================================================================
class Scene_MenuCommonEvent < Scene_MenuBase
  #--------------------------------------------------------------------------
  # override method: start
  #--------------------------------------------------------------------------
  def start
    super
    create_ce_windows
  end
  #--------------------------------------------------------------------------
  # new method: create_cem_command_window
  #--------------------------------------------------------------------------
  def create_cem_command_window
    @ce_window = Window_CEM_Command.new
    @ce_window.viewport = @viewport
    @ce_window.help_window = @help_window
    @ce_window.set_handler(:ok,     method(:on_item_ok)) if $game_system.common_event_menu.confirm?
    @ce_window.set_handler(:cancel, method(:cancel)) if $game_system.common_event_menu.cancel?
  end
  #--------------------------------------------------------------------------
  # new method: create_cem_picture_window
  #--------------------------------------------------------------------------
  def create_cem_picture_window
    @ce_picture_window = Window_CEM_Picture.new($game_system.common_event_menu.menu_picture)
    @ce_picture_window.viewport = @viewport
    @ce_picture_window.cem_cmd_window = @ce_window
  end
  #--------------------------------------------------------------------------
  # new method: create_cem_subtext_window
  #--------------------------------------------------------------------------
  def create_cem_subtext_window
    @ce_subtext_window = Window_CEM_Subtext.new($game_system.common_event_menu.menu_subtext)
    @ce_subtext_window.viewport = @viewport
    @ce_subtext_window.cem_cmd_window = @ce_window
  end
  #--------------------------------------------------------------------------
  # overwrite method: create_help_window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_CEM_Help.new
    @help_window.viewport = @viewport
  end
  #--------------------------------------------------------------------------
  # new method: create_ce_windows
  #--------------------------------------------------------------------------
  def create_ce_windows
    create_help_window
    create_cem_command_window
    create_cem_picture_window
    create_cem_subtext_window
  end
  #--------------------------------------------------------------------------
  # new method: on_item_ok
  #--------------------------------------------------------------------------
  def on_item_ok
    $game_temp.reserve_common_event(@ce_window.current_common_event_id)
    return_scene
  end
  #--------------------------------------------------------------------------
  # new method: cancel
  #--------------------------------------------------------------------------
  def cancel
    $game_temp.reserve_common_event($game_system.common_event_menu.menu_cancel_common_event)
    return_scene
  end
end #Scene_MenuCommonEvent