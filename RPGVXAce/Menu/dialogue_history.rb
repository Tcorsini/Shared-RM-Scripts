#==============================================================================
# Dialogue History v1.3
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 02/10/2025
#==============================================================================
# Version History
#------------------------------------------------------------------------------
# 30/09/2025: Original release
# 30/09/2025: v1.1 smoother sliding, no longer selecting windows
# 01/10/2025: v1.2 fixing dispose order, added more general support for window
#                  positionning, messages are no longer displayed in history
#                  when they are still on the map
# 02/10/2025: v1.3 added text scroll saving and fixed crash at the end of text
#                  scroll when dialogue history 1.2 stores messages.
#==============================================================================
# Description: Records the last messages, scroll text, choices, numbers entered, 
# names given to actors and items selected displays them if necessary or when 
# loading a save.
#
# Available script calls:
#
# To start recording:
#   dialogue_recorder.start
#
# To pause the recording:
#   dialogue_recorder.stop
#
# To erase all history:
#   dialogue_recorder.clear
#
# To set or remove the loading of the history when loading the save:
#   dialogue_recorder.enable_load_on_save
#   dialogue_recorder.disable_load_on_save
#
# To display the history:
#   dialogue_recorder.display
#
# You can access the history on the map by pressing a key set in the module.
# To enable or disable the feature, do:
#   dialogue_recorder.access = true 
#   dialogue_recorder.access = false 
#
# (note for scripters: the recorder is set in $game_system.dialogue_recorder,
# the display method is the same as doing SceneManager.call(Scene_DialogueHistory))
#==============================================================================
# Term of use: Free to use in free or commercial games as long as you give credit
#==============================================================================
# Installation & Compatibility: put the script above main, includes 
# compatibility with Yanfly's Message System and Yanfly's Save Engine as long 
# as you put my script below them.
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-DialogueHistory"] = true

#============================================================================
# DialogueHistory -> Configure the default values here
#============================================================================
module DialogueHistory
  #start recoding at the start of the game?
  INIT_RECORD = true
  #allows to access the history when pressing a key on Scene_Map
  INIT_ACCESS = true
  #activate the display of history when loading a save by default?
  INIT_RECALL = true
  #when loading a save, if history must be displayed but empty, display anyway?
  RECALL_IF_EMPTY = false
  
  #the key to press to get into the history menu when on the map (works too 
  #during messages)
  ACCESS_KEY = :F8
  
  #what type of things are recorded?
  RECORD_MESSAGES = true
  RECORD_CHOICES = true
  RECORD_NUMBERS = true
  RECORD_NAMES = true
  RECORD_ITEMS = true
  RECORD_SCROLLTEXT = true
  
  #change the default texts here (message characters supported):
  module Vocab
    HELP_MENU_TEXT = "Dialogue History"
    
    CHOICE_STR = "\\C[1]>>\\C[0] %s" #%s is the name of the choice
    NUMBER_STR = "\\C[1]Entered:\\C[0] %d" #%d is the number chosen
    NAME_STR = "\\C[1]Entered:\\C[0] %s" #%s is the name chosen
    ITEM_STR = "\\C[1]Selected:\\C[0] \\i[%d] %s" #%d icon index, %s item name
  end #Vocab
  #put a positive value above 0 if you want the dialogue history to have limited 
  #entries without having to control them, each message, choice, actor's name
  #change, item selected and number entered is a single entry
  MAX_HISTORY = 0
  
  #pixels per frame for sliding in dialogue history
  SCROLL_SPEED = 5 #when up/down
  SCROLL_SPEED_UP = 20 #when left/right or shift is pressed
end #DialogueHistory

#============================================================================
# Don't edit anything past this point unless you know what you are doing!
#============================================================================

#============================================================================
# Dialogue_Entry -> parent class for objects in the Dialogue_Recorder list
#============================================================================
class Dialogue_Entry
  #--------------------------------------------------------------------------
  # method: rows -> counts the lines of the history window
  #--------------------------------------------------------------------------
  def rows; 1; end
  #--------------------------------------------------------------------------
  # method: width -> the width of the default history window
  #--------------------------------------------------------------------------
  def width; Graphics.width/2; end
  #--------------------------------------------------------------------------
  # method: text -> gives a string to display on a window, handles special
  # characters
  #--------------------------------------------------------------------------
  def text; ""; end
  #--------------------------------------------------------------------------
  # method: is_message? -> tests if Message_Entry object
  #--------------------------------------------------------------------------
  def is_message?; false; end
  #--------------------------------------------------------------------------
  # method: is_scrolltext? -> tests if ScrollText_Entry object
  #--------------------------------------------------------------------------
  def is_scrolltext?; false; end
  #--------------------------------------------------------------------------
  # method: valid? -> tests if Dialogue_Entry can be displayed
  #--------------------------------------------------------------------------
  def valid?; true; end
end #Dialogue_Entry

#============================================================================
# Message_PostData -> stores positionning among other things that can only be
# calculated after the new page was drawn from the previous message, only
# useful for patches like with ATS: Face Options
#============================================================================
class Message_PostData
  attr_accessor :y
  def initialize(msg_window)
    @y = msg_window.y
  end
end #Message_Entry

#============================================================================
# ScrollText_Entry -> stores a message data
#============================================================================
class ScrollText_Entry < Dialogue_Entry
  attr_reader :data, :post_data
  def initialize
    #puts "recording scrolltext..."
    @data = $game_message.dup
    @data.choice_proc = nil #to allow saving the data
    @data.background = 2 #no background
    @rows = Window_Base.count_lines(text)#rows
  end
  #--------------------------------------------------------------------------
  # new method: add_message_post_data
  #--------------------------------------------------------------------------
  def add_message_post_data
    @valid = true
  end
  #--------------------------------------------------------------------------
  # override methods: width, rows, text, is_scrolltext?, valid?
  #--------------------------------------------------------------------------
  def width; Graphics.width; end
  def rows; @rows; end
  def text; @data.all_text; end
  def is_scrolltext?; true; end
  def valid?; @valid; end
end #ScrollText_Entry

#============================================================================
# Message_Entry -> stores a message data
#============================================================================
class Message_Entry < Dialogue_Entry
  attr_reader :data, :post_data
  def initialize
    #puts "recording msg..."
    @data = $game_message.dup
    @data.choice_proc = nil #to allow saving the data
    @rows = 4
    @width = Graphics.width
    if $imported["YEA-MessageSystem"]
      @rows = Variable.message_rows
      @width = Variable.message_width
    end
  end
  #--------------------------------------------------------------------------
  # new method: add_message_post_data
  #--------------------------------------------------------------------------
  def add_message_post_data
    @post_data = $game_temp.message_post_data.dup
    @valid = true
  end
  #--------------------------------------------------------------------------
  # override methods: width, rows, text, is_message?, valid?
  #--------------------------------------------------------------------------
  def width; @width; end
  def rows; @rows; end
  def text; @data.all_text; end
  def is_message?; true; end
  def valid?; @valid; end
end #Message_Entry

#============================================================================
# Choice_Entry -> stores a dialogue choice made
#============================================================================
class Choice_Entry < Dialogue_Entry
  def initialize(choices, picked_choice)
    #puts "recording choice..."
    @choices = choices
    @n = picked_choice
  end
  #--------------------------------------------------------------------------
  # override method: text
  #--------------------------------------------------------------------------
  def text
    sprintf(DialogueHistory::Vocab::CHOICE_STR, @choices[@n])
  end
end #Choice_Entry

#============================================================================
# Name_Entry -> stores a name entered
#============================================================================
class Name_Entry < Dialogue_Entry
  def initialize(actor, name)
    #puts "recording name..."
    @actor = actor
    @value = name
  end
  #--------------------------------------------------------------------------
  # override method: text
  #--------------------------------------------------------------------------
  def text
    sprintf(DialogueHistory::Vocab::NAME_STR, @value)
  end
end #Name_Entry

#============================================================================
# Item_Entry -> stores an item selected
#============================================================================
class Item_Entry < Dialogue_Entry
  def initialize(item_id)
    #puts "recording item..."
    @value = item_id
  end
  #--------------------------------------------------------------------------
  # new method: item
  #--------------------------------------------------------------------------
  def item
    $data_items[@value]
  end
  #--------------------------------------------------------------------------
  # override method: text
  #--------------------------------------------------------------------------
  def text
    return sprintf(DialogueHistory::Vocab::ITEM_STR,0,"") if item.nil?
    sprintf(DialogueHistory::Vocab::ITEM_STR, item.icon_index, item.name)
  end
end #Text_Entry

#============================================================================
# Value_Entry -> stores a number entered 
#============================================================================
class Value_Entry < Dialogue_Entry
  def initialize(value)
    #puts "recording number..."
    @value = value
  end
  #--------------------------------------------------------------------------
  # override method: text
  #--------------------------------------------------------------------------
  def text
    sprintf(DialogueHistory::Vocab::NUMBER_STR, @value)
  end
end #Value_Entry

#============================================================================
# Dialogue_Recorder -> the history of dialogues and other inputs
#============================================================================
class Dialogue_Recorder
  attr_accessor :record_messages, :record_choices, :record_numbers, :record_items, :record_names, :record_scrolltext
  attr_accessor :max_history, :access
  #--------------------------------------------------------------------------
  # method: initialize
  #--------------------------------------------------------------------------
  def initialize
    @list = []
    @max_history = DialogueHistory::MAX_HISTORY
    @max_history = nil if @max_history <= 0
    @record = DialogueHistory::INIT_RECORD
    @recall = DialogueHistory::INIT_RECALL
    @access = DialogueHistory::INIT_ACCESS
    #booleans for specific entries:
    @record_messages = DialogueHistory::RECORD_MESSAGES
    @record_choices = DialogueHistory::RECORD_CHOICES
    @record_numbers = DialogueHistory::RECORD_NUMBERS
    @record_items = DialogueHistory::RECORD_ITEMS
    @record_names = DialogueHistory::RECORD_NAMES
    @record_scrolltext = DialogueHistory::RECORD_SCROLLTEXT
  end
  #--------------------------------------------------------------------------
  # methods: start/stop -> to start or stop the saving of the dialogues
  #--------------------------------------------------------------------------
  def start; @record = true; end
  def stop; @record = false; end
  def recording?; @record; end
  #--------------------------------------------------------------------------
  # methods: enable/disable_load_on_save -> to start or stop the trigger 
  # of the history scene when loading a save
  #--------------------------------------------------------------------------
  def enable_load_on_save; @recall = true; end
  def disable_load_on_save; @recall = false; end
  def load_on_save? 
    @recall && (DialogueHistory::RECALL_IF_EMPTY || !@list.empty?)
  end
  #--------------------------------------------------------------------------
  # method: clear
  #--------------------------------------------------------------------------
  def clear; @list.clear; end
  #--------------------------------------------------------------------------
  # method: add_entry -> stores a Dialogue_Entry object
  #--------------------------------------------------------------------------
  def add_entry(entry)
    @list.push(entry)
    @list.shift(@list.size - @max_history) if @max_history && @list.size > @max_history
  end
  #--------------------------------------------------------------------------
  # method: list -> gets the valid entries
  #--------------------------------------------------------------------------
  def list
    @list.select{|e| e.valid?}
  end
  #--------------------------------------------------------------------------
  # method: display -> calls the history menu
  #--------------------------------------------------------------------------
  def display
    SceneManager.call(Scene_DialogueHistory)
  end
end #Dialogue_Recorder

#============================================================================
# Game_System
#============================================================================
class Game_System
  attr_reader :dialogue_recorder
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tim_dialogue_history_initialize initialize
  def initialize
    @dialogue_recorder = Dialogue_Recorder.new
    tim_dialogue_history_initialize
  end
end #Game_System

#============================================================================
# Game_Temp
#============================================================================
class Game_Temp
  attr_accessor :message_post_data
end #Game_Temp

#============================================================================
# Game_Interpreter
#============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # new method: dialogue_recorder
  #--------------------------------------------------------------------------
  def dialogue_recorder
    $game_system.dialogue_recorder
  end
  #--------------------------------------------------------------------------
  # alias method: wait_for_message -> catches messages and scrolltext
  #--------------------------------------------------------------------------
  alias record_wait_for_message wait_for_message
  def wait_for_message
    return record_wait_for_message unless dialogue_recorder.recording? && $game_message.has_text?
    bscroll = $game_message.scroll_mode && dialogue_recorder.record_scrolltext
    bmsg = !$game_message.scroll_mode && dialogue_recorder.record_messages
    return record_wait_for_message unless bscroll || bmsg
    entry = nil
    entry = Message_Entry.new if bmsg
    entry = ScrollText_Entry.new if bscroll
    dialogue_recorder.add_entry(entry)
    record_wait_for_message
    entry.add_message_post_data
  end
  #--------------------------------------------------------------------------
  # alias method: setup_choices -> alters the Proc to add the entry
  # that stores the result
  #--------------------------------------------------------------------------
  alias record_setup_choices setup_choices
  def setup_choices(params)
    record_setup_choices(params)
    old_proc = $game_message.choice_proc
    $game_message.choice_proc = Proc.new {|n|
      dialogue_recorder.add_entry(Choice_Entry.new(params[0],n)) if dialogue_recorder.record_choices && dialogue_recorder.recording?;
      old_proc.call(n)
    }
  end
end #Game_Interpreter

#============================================================================
# Window_Base
#============================================================================
class Window_Base < Window
  #--------------------------------------------------------------------------
  # new class method: count_lines
  #--------------------------------------------------------------------------
  def self.count_lines(text)
    w = Window_Base.new(0,0,0,0)
    c = w.convert_escape_characters(text).lines.count
    w.dispose
    return c
  end
end #Window_NumberInput

#============================================================================
# Window_NumberInput
#============================================================================
class Window_NumberInput < Window_Base
  #--------------------------------------------------------------------------
  # alias method: process_ok for input number
  #--------------------------------------------------------------------------
  alias record_process_ok process_ok
  def process_ok
    n = @number
    record_process_ok
    if $game_system.dialogue_recorder.record_numbers && $game_system.dialogue_recorder.recording?
      $game_system.dialogue_recorder.add_entry(Value_Entry.new(n)) 
    end
  end
end #Window_NumberInput

#============================================================================
# Window_KeyItem
#============================================================================
class Window_KeyItem < Window_ItemList
  #--------------------------------------------------------------------------
  # alias method: on_input_ok for input items
  #--------------------------------------------------------------------------
  alias record_on_ok on_ok
  def on_ok
    record_on_ok
    item_id = $game_variables[$game_message.item_choice_variable_id]
    if $game_system.dialogue_recorder.record_items && $game_system.dialogue_recorder.recording?
      $game_system.dialogue_recorder.add_entry(Item_Entry.new(item_id))
    end
  end
  #--------------------------------------------------------------------------
  # alias method: on_input_ok for input items
  #--------------------------------------------------------------------------
  alias record_on_cancel on_cancel
  def on_cancel
    record_on_cancel
    item_id = $game_variables[$game_message.item_choice_variable_id]
    if $game_system.dialogue_recorder.record_items && $game_system.dialogue_recorder.recording?
      $game_system.dialogue_recorder.add_entry(Item_Entry.new(item_id))
    end
  end
end #Window_KeyItem

#============================================================================
# Window_Message
#============================================================================
class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # alias method: new_page -> saves the post-data in a temporary object
  #--------------------------------------------------------------------------
  alias record_new_page new_page
  def new_page(text, pos)
    record_new_page(text,pos)
    $game_temp.message_post_data = Message_PostData.new(self)
  end
end #Window_Message

#============================================================================
# Scene_Name
#============================================================================
class Scene_Name < Scene_MenuBase
  #--------------------------------------------------------------------------
  # alias method: on_input_ok for input name
  #--------------------------------------------------------------------------
  alias record_on_input_ok on_input_ok
  def on_input_ok
    if $game_system.dialogue_recorder.record_names && $game_system.dialogue_recorder.recording?
      $game_system.dialogue_recorder.add_entry(Name_Entry.new(@actor, @edit_window.name))
    end
    record_on_input_ok
  end
end #Scene_Name

#============================================================================
# Scene_Map
#============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias record_update update
  def update
    record_update
    update_message_history unless scene_changing?
  end
  #--------------------------------------------------------------------------
  # new method: update_message_history
  #--------------------------------------------------------------------------
  def update_message_history
    $game_system.dialogue_recorder.display if $game_system.dialogue_recorder.access && Input.press?(DialogueHistory::ACCESS_KEY)
  end
end #Scene_Map

#============================================================================
# Scene_File & Scene_Load
#============================================================================
if $imported["YEA-SaveEngine"]
  class Scene_File < Scene_MenuBase
    #--------------------------------------------------------------------------
    # alias method: on_load_success
    #--------------------------------------------------------------------------
    alias record_on_load_success on_load_success
    def on_load_success
      record_on_load_success
      $game_system.dialogue_recorder.display if $game_system.dialogue_recorder.load_on_save?
    end
  end #Scene_File
else #no save engine
  class Scene_Load < Scene_File
    #--------------------------------------------------------------------------
    # alias method: on_load_success
    #--------------------------------------------------------------------------
    alias record_on_load_success on_load_success
    def on_load_success
      record_on_load_success
      $game_system.dialogue_recorder.display if $game_system.dialogue_recorder.load_on_save?
    end
  end #Scene_Load
end #$imported["YEA-SaveEngine"]

#============================================================================
# Window_NameMessage
#============================================================================
if $imported["YEA-MessageSystem"]
class Window_NameMessage < Window_Base
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias record_winname_initialize initialize
  def initialize(message_window)
    @entry = message_window.entry if message_window.is_a?(Window_DialogueEntry)
    record_winname_initialize(message_window)
  end
  #--------------------------------------------------------------------------
  # alias method: set_y_position
  #--------------------------------------------------------------------------
  alias record_set_y_position set_y_position
  def set_y_position
    return  record_set_y_position unless @entry && @entry.is_message?
    self.y = @message_window.y - self.height
    self.y += YEA::MESSAGE::NAME_WINDOW_Y_BUFFER
  end
end #Window_NameMessage
end #$imported["YEA-MessageSystem"]

#============================================================================
# Window_DialogueEntry
#============================================================================
class Window_DialogueEntry < Window_Message
  attr_reader   :entry
  #--------------------------------------------------------------------------
  # override method: initialize
  # entry is a Dialogue_Entry object
  # index the position of the message in the history
  #--------------------------------------------------------------------------
  def initialize(entry, index)
    @entry = entry
    @index = index
    super()
    self.x = (Graphics.width - self.width)/2
    process_all_text
  end
  #--------------------------------------------------------------------------
  # override method: window_height (restoring behavior if overwritten by
  # Yanfly's message system)
  #--------------------------------------------------------------------------
  def window_height
    return fitting_height(visible_line_number)
  end
  #--------------------------------------------------------------------------
  # override method: window_width
  #--------------------------------------------------------------------------
  def window_width
    @entry.width
  end
  #--------------------------------------------------------------------------
  # new method: total_height (counts additional windows like name window if
  # Yanfly's message system is used)
  #--------------------------------------------------------------------------
  def total_height
    top_h + height + bottom_h
  end
  #--------------------------------------------------------------------------
  # new method: offset_y -> for the parent to know where to put this window 
  # after the last one
  #--------------------------------------------------------------------------
  def offset_y
    top_h
  end
  #--------------------------------------------------------------------------
  # new method: active_window_list (takes care of additional windows)
  #--------------------------------------------------------------------------
  def active_window_list
    wl = [self]
    wl.push(@name_window) if $imported["YEA-MessageSystem"] && !@name_text.empty?
    return wl
  end
  #--------------------------------------------------------------------------
  # new method: top_h -> height above the message window
  #--------------------------------------------------------------------------
  def top_h
    active_window_list.collect{|w| self.y - w.y}.max
  end
  #--------------------------------------------------------------------------
  # new method: bottom_h -> height below the message window
  #--------------------------------------------------------------------------
  def bottom_h
    active_window_list.collect{|w| (w.y+w.height) - (self.y+height)}.max
  end
  #--------------------------------------------------------------------------
  # override method: visible_line_number -> dynamic line numbers, compatible
  # with Yanfly's message system
  #--------------------------------------------------------------------------
  def visible_line_number
    return @entry.rows
  end
  #--------------------------------------------------------------------------
  # override methods: wait, wait_for_one_character, update_fiber, input_pause
  # -> removes any notion of time or user input
  #--------------------------------------------------------------------------
  def wait(duration); end
  def wait_for_one_character; end
  def update_fiber; end
  def input_pause; end
  #--------------------------------------------------------------------------
  # override method: process_all_text -> text is now set by @entry
  #--------------------------------------------------------------------------
  def process_all_text
    clear_name_window if $imported["YEA-MessageSystem"]
    open
    text = convert_escape_characters(@entry.text)
    pos = {}
    new_page(text, pos)
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # new method: face_offset_x -> define the offset made by the face
  #--------------------------------------------------------------------------
  def face_offset_x
    $imported["YEA-MessageSystem"] ? YEA::MESSAGE::FACE_INDENT_X : 112
  end
  #--------------------------------------------------------------------------
  # override method: new_line_x -> face presence defined by @entry
  #--------------------------------------------------------------------------
  def new_line_x
    !@entry.is_message? || @entry.data.face_name.empty? ? 0 : face_offset_x
  end
  #--------------------------------------------------------------------------
  # override method: update_background -> background is defined by @entry
  #--------------------------------------------------------------------------
  def update_background
    @background = @entry.data.background if @entry.is_message? || @entry.is_scrolltext?
    self.opacity = @background == 0 ? 255 : 0
  end
  #--------------------------------------------------------------------------
  # override method: viewport= -> sets the viewport of the background too
  #--------------------------------------------------------------------------
  def viewport=(v)
    super
    @back_sprite.viewport = v
    @name_window.viewport = v if $imported["YEA-MessageSystem"]
  end
  #--------------------------------------------------------------------------
  # override method: y=
  #--------------------------------------------------------------------------
  def y=(new_y)
    super
    @name_window.set_y_position if $imported["YEA-MessageSystem"]
  end
  #--------------------------------------------------------------------------
  # override method: new_page -> refers to @entry instead of $game_message
  #--------------------------------------------------------------------------
  def new_page(text, pos)
    update_background
    adjust_message_window_size if $imported["YEA-MessageSystem"]
    contents.clear
    draw_face(@entry.data.face_name, @entry.data.face_index, 0, 0) if @entry.is_message?
    reset_font_settings
    pos[:x] = new_line_x
    pos[:y] = 0
    pos[:new_x] = new_line_x
    pos[:height] = calc_line_height(text)
    clear_flags
  end
  #--------------------------------------------------------------------------
  # override method: process_escape_character
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    case code.upcase
    when '$'
      #do nothing
    else
      super
    end
  end
end #Window_DialogueEntry

#============================================================================
# Scene_DialogueHistory
#============================================================================
class Scene_DialogueHistory < Scene_MenuBase
  #--------------------------------------------------------------------------
  # override method: start
  #--------------------------------------------------------------------------
  def start
    super
    create_help_window
    create_history_viewport
    create_history_windows
  end
  #--------------------------------------------------------------------------
  # override method: terminate
  #--------------------------------------------------------------------------
  def terminate
    super
    @history_windows.each {|window| window.dispose }
    @history_viewport.dispose
  end
  #--------------------------------------------------------------------------
  # override method: create_help_window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new(1)
    @help_window.viewport = @viewport
    @help_window.set_text(help_window_text)
  end
  #--------------------------------------------------------------------------
  # new method: help_window_text
  #--------------------------------------------------------------------------
  def help_window_text
    DialogueHistory::Vocab::HELP_MENU_TEXT
  end
  #--------------------------------------------------------------------------
  # new method: create_history_viewport
  #--------------------------------------------------------------------------
  def create_history_viewport
    @history_viewport = Viewport.new
    @history_viewport.rect.y = @help_window.height
    @history_viewport.rect.height -= @help_window.height
  end
  #--------------------------------------------------------------------------
  # new method: create_history_windows
  #--------------------------------------------------------------------------
  def create_history_windows
    l = $game_system.dialogue_recorder.list
    @history_windows = Array.new(l.size) do |i|
      Window_DialogueEntry.new(l[i],i)
    end
    y = 0
    @history_windows.each do |w| 
      w.viewport = @history_viewport
      w.y = y + w.offset_y
      y += w.total_height
    end
    @total_height = y
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    super
    @history_windows.each {|window| window.update }
    update_window_selection
  end
  #--------------------------------------------------------------------------
  # new method: item_max
  #--------------------------------------------------------------------------
  def item_max
    $game_system.dialogue_recorder.list.size
  end
  #--------------------------------------------------------------------------
  # new method: move_viewport
  #--------------------------------------------------------------------------
  def move_viewport(diff)
    y = @history_viewport.oy + diff
    max_oy = @total_height-@history_viewport.rect.height
    @history_viewport.oy = [0,[y, max_oy].min].max
  end
  #--------------------------------------------------------------------------
  # new method: update_window_selection
  #--------------------------------------------------------------------------
  def update_window_selection
    return on_ok     if Input.trigger?(:C)
    return on_cancel if Input.trigger?(:B)
    update_cursor
  end
  #--------------------------------------------------------------------------
  # new method: on_ok
  #--------------------------------------------------------------------------
  def on_ok
    Sound.play_cancel
    return_scene
  end
  #--------------------------------------------------------------------------
  # new method: on_cancel
  #--------------------------------------------------------------------------
  def on_cancel
    Sound.play_cancel
    return_scene
  end
  #--------------------------------------------------------------------------
  # new method: update_cursor
  #--------------------------------------------------------------------------
  def update_cursor
    return if @history_windows.empty?
    #last_index = @index
    cursor_down if Input.press?(:DOWN)
    cursor_up if Input.press?(:UP)
    cursor_left if Input.press?(:LEFT)
    cursor_right if Input.press?(:RIGHT)
  end
  #--------------------------------------------------------------------------
  # new method: cursor_down
  #--------------------------------------------------------------------------
  def cursor_down
    speed = DialogueHistory::SCROLL_SPEED
    speed = DialogueHistory::SCROLL_SPEED_UP if Input.press?(:SHIFT)
    move_viewport(speed)
  end
  #--------------------------------------------------------------------------
  # new method: cursor_up
  #--------------------------------------------------------------------------
  def cursor_up
    speed = DialogueHistory::SCROLL_SPEED
    speed = DialogueHistory::SCROLL_SPEED_UP if Input.press?(:SHIFT)
    move_viewport(-speed)
  end
  #--------------------------------------------------------------------------
  # new method: cursor_right
  #--------------------------------------------------------------------------
  def cursor_right
    move_viewport(DialogueHistory::SCROLL_SPEED_UP)
  end
  #--------------------------------------------------------------------------
  # new method: cursor_left
  #--------------------------------------------------------------------------
  def cursor_left
    move_viewport(-DialogueHistory::SCROLL_SPEED_UP)
  end
end #Scene_DialogueHistory