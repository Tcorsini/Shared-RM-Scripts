#==============================================================================
# Enemies status icons
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 29/09/2025
#==============================================================================
# Description: Displays status above or below enemies sprites as a grid of
# icons
#==============================================================================
# Term of use: Free to use in free or commercial games
#==============================================================================
# Installation: put it above main, set the right configurations on the enemies
# sprites
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-EnemiesStatusIcons"] = true

#============================================================================
# StateIcons
#============================================================================
module StateIcons
  #are the icons displayed above the sprite (if true) or below (if false)
  TOP_POSITION = false
  #how many states displayed in a row (number of columns)
  COLUMNS = 5
  #how many rows?
  ROWS = 2
  #the total number of states displayed will be ROWS*COLUMNS
  
  #a distance (in pixels from the battler's sprite)
  SPRITE_OFFSET = 4
end #StateIcons

#============================================================================
# Sprite_Icon
#============================================================================
class Sprite_Icon < Sprite
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, icon_index)
    @icon_index = icon_index
    super(viewport)
    self.bitmap = Cache.system("Iconset")
    update_icon
  end
  #--------------------------------------------------------------------------
  # overload method: update
  #--------------------------------------------------------------------------
  def update(new_icon = 0)
    super()
    if new_icon != @icon_index
      @icon_index = new_icon
      update_icon
    end
  end
  #--------------------------------------------------------------------------
  # new method: draw_icon
  #--------------------------------------------------------------------------
  def update_icon
    self.src_rect.set(@icon_index % 16 * 24, @icon_index / 16 * 24, 24, 24)
  end
end #Sprite_Icon

#============================================================================
# Sprite_States
#============================================================================
class Sprite_States
  #--------------------------------------------------------------------------
  # new method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport, bat_sprite)
    @bat_sprite = bat_sprite
    @total_icons = StateIcons::COLUMNS * StateIcons::ROWS
    @sprite_l = (0...@total_icons).collect {|i| Sprite_Icon.new(viewport,0)}
  end
  #--------------------------------------------------------------------------
  # new method: update
  #--------------------------------------------------------------------------
  def update
    update_position
    update_opacity
    update_icons
  end
  #--------------------------------------------------------------------------
  # new method: dispose
  #--------------------------------------------------------------------------
  def dispose
    @sprite_l.each {|s| s.dispose}
  end
  #--------------------------------------------------------------------------
  # new method: update_position
  #--------------------------------------------------------------------------
  def update_position
    return unless @x != @bat_sprite.x || @y != @bat_sprite.y
    @x = @bat_sprite.x
    @y = @bat_sprite.y
    _x = @x - (StateIcons::COLUMNS)*12
    _y = @y - @bat_sprite.oy
    @sprite_l.each_with_index do |s,i|
      s.x = _x + (i % StateIcons::COLUMNS)*24
      s.z = @bat_sprite.z
      if StateIcons::TOP_POSITION
        s.y = _y - (24 + StateIcons::SPRITE_OFFSET + (i / StateIcons::COLUMNS)*24)
      else
        s.y = _y + @bat_sprite.height + StateIcons::SPRITE_OFFSET + (i / StateIcons::COLUMNS)*24
      end
    end
  end
  #--------------------------------------------------------------------------
  # new method: update_icons
  #--------------------------------------------------------------------------
  def update_icons
    bat = @bat_sprite.battler
    return unless bat
    icon_list = bat.state_icons
    @sprite_l.each_with_index do |s,i|
      icon = i < icon_list.size ? icon_list[i] : 0
      s.update(icon)
    end
  end
  #--------------------------------------------------------------------------
  # new method: update_opacity
  #--------------------------------------------------------------------------
  def update_opacity
    if @opacity != @bat_sprite.opacity
      @opacity =  @bat_sprite.opacity
      @sprite_l.each {|s| s.opacity = @opacity}
    end
  end
end #Sprite_States

#============================================================================
# Sprite_Battler
#============================================================================
class Sprite_Battler < Sprite_Base
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias bat_state_icons_initialize initialize
  def initialize(viewport, battler = nil)
    bat_state_icons_initialize(viewport, battler)
    @state_s = Sprite_States.new(viewport, self)
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias bat_state_icons_update update
  def update
    bat_state_icons_update
    @state_s.update
  end
  #--------------------------------------------------------------------------
  # alias method: dispose
  #--------------------------------------------------------------------------
  alias bat_state_icons_dispose dispose
  def dispose
    @state_s.dispose
    bat_state_icons_dispose
  end
end #Sprite_Battler