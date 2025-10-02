#==============================================================================
# Dialogue History + ATS: Face Options Patch
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 01/10/2025
# Requires: Dialogue History v1.2 and modern algebra's ATS: Face Options v1.0.3
#==============================================================================
# Description: fixes the face displays from ATS script in the history
#==============================================================================
# Term of use: Free to use in free or commercial games as long as you give credit
#==============================================================================
# Installation & Compatibility: put Dialogue history below ATS:Face Options and
# this compatibiity patch below both scripts
#==============================================================================
# Known issues: face_overlap_allowed won't be represented properly in history,
# I don't know how to fix this so it will be considered true all the time in 
# dialogue history
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-DialogueHistory-MA-ATS-FaceOptions-patch"] = true

module DialogueHistory_ATS_FaceOptions_Patch
  #what to do with faces with constant y positionning that are outside the window?
  #:stick     -> stick them to the window above or below the message window
  #:hide      -> don't show the faces outside the window
  #nil        -> keep the same relative position to the window
  CST_POS_FACES = :hide
end #DialogueHistory_ATS_FaceOptions_Patch

#============================================================================
# Message_Entry
#============================================================================
class Message_Entry < Dialogue_Entry
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_initialize initialize
  def initialize
    tim_dh_atsfo_initialize
    @data.face_scroll_x = false
    @data.face_scroll_y = false
    if @data.face_match_screen_tone
      @data.face_match_screen_tone = false
      @data.face_tone = $game_map.screen.tone.dup
    end
    @data.face_overlap_allowed = true #could not reproduce this feature, so better keep it false
  end
end #Message_Entry

#============================================================================
# Window_DialogueEntry
#============================================================================
class Window_DialogueEntry < Window_Message
  #--------------------------------------------------------------------------
  # alias method: initialize -> game_message is replace temporrly by entry's
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_initialize initialize
  def initialize(entry, index)
    gm = $game_message
    $game_message = entry.data if entry.is_message?
    tim_dh_atsfo_initialize(entry,index)
    @atsfo_face.update_placement #fix the position now before setting y
    $game_message = gm
  end
  #--------------------------------------------------------------------------
  # alias method: update -> game_message is replace temporrly by entry's
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_update update
  def update
    gm = $game_message
    $game_message = @entry.data if @entry.is_message?
    tim_dh_atsfo_update
    $game_message = gm
  end
  #--------------------------------------------------------------------------
  # alias method: viewport= -> sets the viewport of the background too
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_viewport_set viewport=
  def viewport=(v)
    tim_dh_atsfo_viewport_set(v)
    @atsfo_face.face_sprite.viewport = v
    @atsfo_face.face_window.viewport = v
  end
  #--------------------------------------------------------------------------
  # alias method: y=
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_y_set y=
  def y=(new_y)
    old_y = self.y
    tim_dh_atsfo_y_set(new_y)
    @atsfo_face.y += (new_y-old_y)
  end
  #--------------------------------------------------------------------------
  # alias method: active_window_list
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_active_window_list active_window_list
  def active_window_list
    wl = tim_dh_atsfo_active_window_list
    wl.push(@atsfo_face.face_window) if @entry.is_message?
    return wl
  end
  #--------------------------------------------------------------------------
  # alias method: new_line_x -> access the parent method for offset
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_new_line_x new_line_x
  def new_line_x; super; end
  alias tim_dh_atsfo_new_line_x_super new_line_x
  #--------------------------------------------------------------------------
  # overwrite method: face_offset_x -> offset is now defined by parent class
  #--------------------------------------------------------------------------
  def face_offset_x; tim_dh_atsfo_new_line_x_super; end
  def new_line_x; tim_dh_atsfo_new_line_x; end #restore previous behavior
  #--------------------------------------------------------------------------
  # alias method: new_page -> adds the face code handling
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_newpage new_page
  def new_page(text, pos, *args)
    process_face_setting_codes(text)
    while text[/\A\e[AM]?FB?(\[\d+\]|{\s*['"]?.*?['"]?[\s,;:]*\d*\s*})/i] != nil
      text.slice!(/\A\e([AM]?FB?)/i)
      process_face_code($1, text)
    end
    tim_dh_atsfo_newpage(text, pos, *args)
  end
  #--------------------------------------------------------------------------
  # alias method: process_face_setting_code -> removes animations
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_process_face_setting_code process_face_setting_code
  def process_face_setting_code(code, text)
    return tim_dh_atsfo_process_face_setting_code(code, text) if code.nil? || code.empty?
    case code.upcase
    when 'FF', 'FSX', 'FSY' 
      #do nothing
    else 
      return tim_dh_atsfo_process_face_setting_code(code, text)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # alias method: process_escape_character
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_process_escape_character process_escape_character
  def process_escape_character(code, text, *args, &block)
    case code.upcase
    when /FA(M?)/ 
      #ignore animations
    else
      tim_dh_atsfo_process_escape_character(code, text, *args, &block)
    end
  end
end #Window_DialogueEntry

#============================================================================
# Spriteset_ATS_Face
#============================================================================
class Spriteset_ATS_Face
  #--------------------------------------------------------------------------
  # alias method: set_y_placement -> changes what happens for automatic
  # window positionning
  #--------------------------------------------------------------------------
  alias tim_dh_atsfo_set_y_placement set_y_placement
  def set_y_placement
    return tim_dh_atsfo_set_y_placement unless @message_window.is_a?(Window_DialogueEntry) && @message_window.entry.is_message?
    # Update Y
    fy = $game_message.face_y
    fy = fy.to_s.upcase.to_sym if fy.is_a?(Symbol)
    # Automatic Set
    original_y = @message_window.entry.post_data.y
    if fy == :A
      if @face_window.height <= @message_window.height
        fy = :C # Centre if face smaller than message window
      elsif original_y < (Graphics.height - @message_window.height) / 2 
        fy = :T # Align with Top if message window above mid-screen
      else
        fy = :B # Align with Bottom otherwise
      end
    end
    fy = recorder_convert_y_int(fy) if fy.is_a?(Integer)
    w_pad = ($game_message.face_window ? 0 : $game_message.face_padding)
    @dest_y = case fy
    when Integer then fy - w_pad
    when :U, :AT then @message_window.y - @face_window.height + 
      $game_message.face_y_offset + w_pad
    when :T, :BT then @message_window.y + $game_message.face_y_offset - w_pad
    when :C then @message_window.y + ((@message_window.height - 
      @face_window.height) / 2) + $game_message.face_y_offset
    when :B, :AB then @message_window.y + @message_window.height - 
      @face_window.height - $game_message.face_y_offset + w_pad
    when :D, :BB then @message_window.y + @message_window.height - 
      $game_message.face_y_offset - w_pad
    end
    self.y = @dest_y unless $game_message.face_scroll_y
  end
  #--------------------------------------------------------------------------
  # new method: recorder_convert_y_int -> turns an absolute position from the
  # screen into something else for dialogue history
  #--------------------------------------------------------------------------
  def recorder_convert_y_int(fy)
    original_y = @message_window.entry.post_data.y
    face_gap = fy - original_y #< 0 means above, > 0 means below
    action = DialogueHistory_ATS_FaceOptions_Patch::CST_POS_FACES
    action = :relative if (face_gap >= 0 && face_gap <= @message_window.height) || (face_gap < 0 && face_gap+@face_window.height >= original_y) #(if overlapping)
    #delta.abs <= -@message_window.height || delta > -@message_window.height
    case action
    when :stick
      return face_gap < 0 ? :U : :D
    when :hide
      @face_name = ""
      $game_message.face_name = ""
      return fy
    else
      delta = @message_window.y - original_y
      return fy + delta
    end#return :U
  end
end #Spriteset_ATS_Face