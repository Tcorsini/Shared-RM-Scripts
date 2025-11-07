#==============================================================================
# TBS Sprite_Projectile
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 07/11/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Projectile"] = true
if $imported["TIM-TBS-Projectile"]

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 07/11/2025: v1.0 - first version
#==============================================================================
# Description
#------------------------------------------------------------------------------
# Adds projectiles to abilities (skills and items)
#
# You can set a projectile in the items, skills, enemies and weapons notetags
# like this:
# <projectile = filename>
# <projectile_animation = [anim_id, bool]>
#
# projectile will look for a sprite named filename in
# Graphics/Pictures/TBS/Projectiles/
# and display it before doing the animation for skills and items
#
# projectile_animation will set an animation that loops around the projectile
# until it reaches its target, the boolean is either true or false, true means
# that the animation will change it's angle based on the projectile's angle,
# false means the animation will keep its original display.
#
# You can set in item or skills the notetag:
# <weapon_projectile>
# if you want the ability to use the same projectile (if any) as the main
# weapon.
#
# Animations and projectiles are thought such that the right side of the sprite
# is the front of the projectile.
#
# You may also invoke a projectile by event calls like this:
# scene = SceneManager.scene    #get the Scene_TBS_Battle
# src = POS.new(x,y)
# tgt = POS.new(x2,y2)
# p = scene.spriteset.create_projectile(src,tgt,filename)
# p.set_loop_anim(anim_id, true) #set a looping animation that rotates with the
#                                 projectile, false to avoid rotation
# #to have an animation and damage at the end of the projectile
# #(not recommended as script calls in events)
# p.set_anim_data(batlist, animation_id, action)
#==============================================================================
# Installation: put it below TBS core
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

#==============================================================================
# TBS
#==============================================================================
module TBS
  module ANIM
    #will camera follow the projectile?
    PROJECTILE_CAM = false
    #what is the projectile trajectory shape? :straight or :arched?
    PROJECTILE_DEFAULT = :arched #put :straight or :arched
  end #ANIM

  module REGEXP
    PROJECTILE = /^<projectile\s*=\s*(.+)\s*>/i #for weapons, enemies, skills and items to define a projectile
    WEAPON_PROJECTILE = /^<(weapon_projectile)>/i #for items and skills to use the weapon projectile
    ANIM_PROJECTILE = /^<projectile_animation\s*=\s*(\[\s*\d+(\s*,\s*(true|false))?\s*\])\s*>/i
  end #REGEXP
end #TBS

#============================================================================
# Don't edit things below this point
#============================================================================

#============================================================================
# SNC from Simple Notetag Config
#============================================================================
module SNC
  #--------------------------------------------------------------------------
  # alias method: prepare_metadata
  #--------------------------------------------------------------------------
  class <<self; alias prepare_metadata_tbs_projectile prepare_metadata; end
  def self.prepare_metadata
    prepare_metadata_tbs_projectile
    Notetag_Data.new(:projectile,       nil,  TBS::REGEXP::PROJECTILE,       1).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ENEMIES)
    Notetag_Data.new(:weapon_projectile,false,TBS::REGEXP::WEAPON_PROJECTILE,2).add_to(DATA_SKILLS,DATA_ITEMS)
    Notetag_Data.new(:anim_projectile,  nil,  TBS::REGEXP::ANIM_PROJECTILE    ).add_to(DATA_SKILLS,DATA_ITEMS,DATA_WEAPONS,DATA_ENEMIES)
  end #prepare_metadata
end #SNC

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # new method: weapon_projectile
  #--------------------------------------------------------------------------
  def weapon_projectile
    weapons[0] ? weapons[0].projectile : nil
  end
  #--------------------------------------------------------------------------
  # new method: weapon_anim_projectile
  #--------------------------------------------------------------------------
  def weapon_anim_projectile
    weapons[0] ? weapons[0].anim_projectile : nil
  end
end #Game_Actor

#==============================================================================
# Game_Enemy
#==============================================================================
class Game_Enemy
  #--------------------------------------------------------------------------
  # new method: weapon_projectile
  #--------------------------------------------------------------------------
  def weapon_projectile
    enemy.projectile
  end
  #--------------------------------------------------------------------------
  # new method: weapon_anim_projectile
  #--------------------------------------------------------------------------
  def weapon_anim_projectile
    enemy.anim_projectile
  end
end #Game_Enemy

#==============================================================================
# Game_Action
#==============================================================================
class Game_Action
  #--------------------------------------------------------------------------
  # new method: projectile -> get the projectile used by stored ability if any
  #--------------------------------------------------------------------------
  def projectile
    item.weapon_projectile ? @subject.weapon_projectile : item.projectile
  end
  #--------------------------------------------------------------------------
  # new method: anim_projectile -> get the animation projectile stored by ability
  #--------------------------------------------------------------------------
  def anim_projectile
    return item.anim_projectile if item.anim_projectile
    return @subject.weapon_anim_projectile if item.weapon_projectile
    nil
  end
end #Game_Action

#==============================================================================
# Scene_TBS_Battle
#==============================================================================
class Scene_TBS_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: tbs_anim_show_tbs_animation -> displays projectiles
  #--------------------------------------------------------------------------
  alias tbs_proj_show_tbs_animation show_tbs_animation
  def show_tbs_animation(targets, animation_id,action)
    #skip projectiles when animations are not used:
    return tbs_proj_show_tbs_animation(targets, animation_id,action) if $imported["YEA-SystemOptions"] && !$game_system.animations?
    projectile = action.projectile
    anim_proj = action.anim_projectile
    return tbs_proj_show_tbs_animation(targets, animation_id,action) unless projectile
    if action.item_for_none? || action.item_for_all? #single animation
      p = @spriteset.create_projectile(@subject.pos,action.tgt_pos,projectile)
      p.set_loop_anim(*anim_proj) if anim_proj
      p.set_anim_data(targets, animation_id,action)
    else
      targets.each do |t|
        p = @spriteset.create_projectile(@subject.pos,t.pos,projectile)
        p.set_loop_anim(*anim_proj) if anim_proj
        p.set_anim_data([t],animation_id,action)
        abs_wait_short
      end
    end
    wait_for_animation
    #return tbs_anim_show_tbs_animation(targets, animation_id,action)
  end
  #--------------------------------------------------------------------------
  # new method: on_projectile_end -> calls the animation on the tatgets when
  # the projectile lands
  #--------------------------------------------------------------------------
  def on_projectile_end(targets, animation_id, action)
    return unless targets && !targets.empty?
    tbs_proj_show_tbs_animation(targets, animation_id, action)
  end
end #Scene_TBS_Battle

#===============================================================================
# Sprite_Projectile -> display projectiles in TBS, this is a modified version
# of GTBS Projectile class
#===============================================================================
class Sprite_Projectile < Sprite_Tile
  #--------------------------------------------------------------------------
  # * Initialize
  #     source = source in map coordinates
  #     target = target in map coordinates
  #     projectile_name   = a filename in "TBS/Projectiles/"
  #     type
  #       *  :straight - for straight path with no camera adjustments
  #       *  :arched - for curved path using camera adjustments (actual path
  #            followed is straight, but camera adjust to "appear" as curved)
  #     _speed = the number of cells per steps
  #     wait_time = the number of steps before launching the projectile
  #--------------------------------------------------------------------------
  # Constants
  #----------------------------------------------------------------------------
  WAIT_MOVE_TIME = 25 #frames before launching projectile
  CELLS_PER_STEP = 0.25 #cells per steps
  def initialize(viewport, source, target, projectile_name,
                 type = TBS::ANIM::PROJECTILE_DEFAULT,
                 _speed = CELLS_PER_STEP,
                 wait_time = WAIT_MOVE_TIME)
    @src = POS.new(*source) + POS.new(0.5,0.5)
    @tgt = POS.new(*target) + POS.new(0.5,0.5)
    super(viewport,*@src)
    return self.dispose if @src == @tgt
    @type = type

    self.bitmap = Cache.picture("TBS/Projectiles/#{projectile_name}")
    self.opacity = 255
    self.visible = true
    self.ox = self.bitmap.width/2
    self.oy = self.bitmap.height/2

    diff = @tgt - @src
    #atan(-y/x) since y axis is inverted
    #angle = Math.atan2(-diff.y,diff.x)
    self.angle = TBS::MATH.angle_from(*diff)#rad_to_degree(angle)

    dist = diff.euclidian_norm #(diff/dist is the normalized vector)
    @speed = (diff / dist) * _speed #2-dimension speed in x and y coordinates
    @slice = dist / _speed #number of steps in frames before projectile is over
    @div = Math::PI / @slice #to set the arc of the object on arched, its angle should go from 0 to pi during runtime
    @high = dist / 4 #How high the object will go on arched

    @index = 0 #init counterà
    #To wait before launch
    @start = wait_time
    @started = false

    update
  end
  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update(camera = false)
    return if disposed?
    super()
    if !@started
      @start -= 1
      self.visible = @started = true if @start <= 0
    else
      update_move #straight or arched projectile
      update_camera if camera
      @index += 1
    end
    self.dispose if @index >= @slice
  end
  #--------------------------------------------------------------------------
  # new method: update_move - Updates "normal" projectiles
  #--------------------------------------------------------------------------
  def update_move
    p = @src + @speed*(@index+1)
    @map_x, @map_y = p[0], p[1]
    update_move_arched if @type == :arched
  end
  #--------------------------------------------------------------------------
  # new method: update_move_arched - Updates arched projectiles
  #--------------------------------------------------------------------------
  def update_move_arched
    @map_y -= (Math::sin(@index*@div.to_f)*@high)
  end
  #--------------------------------------------------------------------------
  # new method: update_camera - Updates the camera based on current "frame" of animation
  #--------------------------------------------------------------------------
  def update_camera
    camera_y = @map_y
    camera_y -= Math::sin(@index*@div.to_f)*@high/2 if @type == :arched
    $game_player.center(@map_x,camera_y)
  end
  #--------------------------------------------------------------------------
  # override method: screen_z
  #--------------------------------------------------------------------------
  def screen_z; 5000; end
  #--------------------------------------------------------------------------
  # set_anim_data -> [batlist, anim_id, action] are stored in @data for
  # the end of the projectile
  #--------------------------------------------------------------------------
  def set_anim_data(*args); @data = args; end
  #--------------------------------------------------------------------------
  # get_anim_data
  #--------------------------------------------------------------------------
  def get_anim_data; @data; end
end #Sprite_Projectile

#===============================================================================
# Sprite_AnimatedProjectile -> display a continuous animation on the projectile
#===============================================================================
class Sprite_AnimatedProjectile < Sprite_Projectile
  #--------------------------------------------------------------------------
  # new method: set_loop_anim
  #--------------------------------------------------------------------------
  def set_loop_anim(anim_id, rotate = true)
    @anim_id = anim_id
    @rotate_anim = rotate
  end

  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update(camera=false)
    return if disposed?
    start_animation($data_animations[@anim_id]) if @anim_id && !animation?
    super(camera)
  end

  #--------------------------------------------------------------------------
  # override method: animation_set_sprites -> rotate the animation baded on
  # the projectile angle
  #--------------------------------------------------------------------------
  def animation_set_sprites(frame)
    super(frame)
    return unless @rotate_anim
    turn_animation(self.angle)
  end

  #--------------------------------------------------------------------------
  # new method: turn_animation by an angle a (in degree and in trigonomical order)
  # (ie counter-clock wise)
  #--------------------------------------------------------------------------
  def turn_animation(a)
    r1 = TBS::MATH.degree_to_rad(a)
    @ani_sprites.each do |s|
      p = POS.new(s.x - @ani_ox, s.y-@ani_oy) #position of the sprite in origin space
      d = p.euclidian_norm
      #angle:
      r2 = TBS::MATH.rad_angle_from(*p)
      cx = Math.cos(r1+r2)
      sy = -Math.sin(r1+r2)
      #result:
      s.x = d*cx + @ani_ox
      s.y = d*sy + @ani_oy
      s.angle += a
    end
  end

  #--------------------------------------------------------------------------
  # new method: move_animation (from Sprite_Character)
  #--------------------------------------------------------------------------
  def move_animation(dx, dy)
    if @animation && @animation.position != 3
      @ani_ox += dx
      @ani_oy += dy
      @ani_sprites.each do |sprite|
        sprite.x += dx
        sprite.y += dy
      end
    end
  end

  #--------------------------------------------------------------------------
  # override method: update_pos
  #--------------------------------------------------------------------------
  def update_pos
    move_animation(screen_x - x, screen_y - y)
    super
  end
end #Sprite_AnimatedProjectile

#==============================================================================
# Spriteset_TBS_Map
#==============================================================================
class Spriteset_TBS_Map < Spriteset_Map
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tbs_anim_spriteset_init initialize
  def initialize(*args)
    @projectiles = []
    tbs_anim_spriteset_init(*args)
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias tbs_anim_spriteset_update update
  def update
    tbs_anim_spriteset_update
    update_projectiles
  end
  #--------------------------------------------------------------------------
  # alias method: dispose
  #--------------------------------------------------------------------------
  alias tbs_anim_spriteset_dispose dispose
  def dispose
    tbs_anim_spriteset_dispose
    dispose_projectiles
  end
  #--------------------------------------------------------------------------
  # alias method: animation?
  #--------------------------------------------------------------------------
  alias tbs_anim_spriteset_animation? animation?
  def animation?
    tbs_anim_spriteset_animation? || !@projectiles.empty?
  end
  #--------------------------------------------------------------------------
  # new method: create_projectile : takes 2 POS objects and a filename of a
  # sprite, shoots a sprite between the two positions
  #--------------------------------------------------------------------------
  def create_projectile(src,tgt,filename="arrow")
    return nil unless filename && filename != ""
    p = Sprite_AnimatedProjectile.new(@viewport1,src,tgt,filename)
    @projectiles.push(p)
    return p
  end
  #--------------------------------------------------------------------------
  # new method: update_projectiles
  #--------------------------------------------------------------------------
  def update_projectiles
    camera = TBS::ANIM::PROJECTILE_CAM && @projectiles.size <= 1
    @projectiles.each do |p|
      if !p.disposed?
        p.update(camera)
        data = p.get_anim_data
        SceneManager.scene.on_projectile_end(*data) if p.disposed? && data && SceneManager.scene_is?(Scene_TBS_Battle)
      end
    end
    @projectiles.select!{|p| !p.disposed?}
  end
  #--------------------------------------------------------------------------
  # new method: dispose_projectiles
  #--------------------------------------------------------------------------
  def dispose_projectiles
    @projectiles.each{|p| p.dispose}
    @projectiles.clear
  end
end #Spriteset_TBS_Map

end #$imported["TIM-TBS-Projectile"]
