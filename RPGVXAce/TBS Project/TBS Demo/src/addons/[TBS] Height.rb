#==============================================================================
# TBS Height
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 09/04/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Height"] = false #set to false if you wish to disable the modifications
raise "TBS Height requires TBS by Timtrack" unless $imported["TIM-TBS"] if $imported["TIM-TBS-Height"]

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 24/02/2025: first version
# 09/04/2025: code fix
#==============================================================================
# Description
#------------------------------------------------------------------------------
# Replaces the default obstacle system of ability targeting for TBS,
# introduces a height to each battlers (defined by notetags) it can be modified
# by states (defined by notetags too). Each tile also have a height (defined by
# battle zones).
# Terrain tags defined by tileset are no longer used for any targeting.
#
# When casting an ability, the battler will cast it from its height.
#==============================================================================
# Installation: put it after TBS core files and before TBS PatchHub
#
# You should modify the constants from TBS_HEIGHT to settle the default height
# for battlers, choose which targeting system for TBS is used (a simple height
# or a more complicated but realistic one).
#
# ZONE_HEIGHT stores the height of each zone_ids, the first value is for no zone,
# then zone 1, zone 2...
#
# In actors, enemies and states notetags, you may select a height value:
# <height: h>
# Where h is a float/real number
# States may increase or decrease the height by adding h defined in the notetags.
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

module TBS_HEIGHT
  DEFAULT_ACTOR_HEIGHT = 1
  DEFAULT_ENEMY_HEIGHT = 1

  module REGEXP
    HEIGHT       = /<height:\s*\-*((\d*\.)?\d+)>/i
  end

  #DEFAULT SYSTEM: follows a min/max operation, higher units can target things below
  #them (or at the same level) while higher tiles are obstacles to lower tiles
  #If there is a tile even higher behind, it will be seen by the caster.
  #ADVCANCED SYSTEM: similar to railcasting when checking which tiles cann be obstacles
  #Draw a line from caster to target in 3d and checks if the crossed tiles/units are obstacles
  ADVANCED_HEIGHT_SYSTEM = false #keep it false, the avanced system is not yet implemented
  DEFAULT_ZONE_HEIGHT = 0 #if no zone is specified or ZONE_HEIGHT[zone_id] is not specified

  MIN_BAT_HEIGHT = 0.1 #must be a stricly positive value

  FLY_HEIGHT = 1 #this will be added to the height of the battler when flying, leaving space between its legs and the ground too
  MAX_HEIGHT = 100 #if zone_height > MAX_HEIGHT, then the tile cannot be crossed by the battler, this puts a limit to flying unit with virtual obstacles

  #indices are zone_ids, values or the height associated to each zone
  #height can be real number
  ZONE_HEIGHT = [DEFAULT_ZONE_HEIGHT,1,2,3,4,5,6,7,8,9,
                1000,-1,-2,-3,-4,-5,-6,-7,-8,-9]

#==============================================================================
# Changing things below is at your own risk!
#==============================================================================

  def self.zone_height(zone_id)
    h = ZONE_HEIGHT[zone_id]
    return h.nil? ? DEFAULT_ZONE_HEIGHT : h
  end

  #move type is ground, fly etc.
  def self.height_addition(move_type)
    return move_type == :fly ? FLY_HEIGHT : 0
  end
end #module TBS_HEIGHT

if $imported["TIM-TBS-Height"]
  #============================================================================
  # TBS
  #============================================================================
  module TBS
    #--------------------------------------------------------------------------
    # alias method: tbs_passable? (for move rules -> takes into account a maximum altitude)
    #--------------------------------------------------------------------------
    class <<self; alias tbs_height_passable? tbs_passable?; end
    def self.tbs_passable?(x,y,d,type)
      return (tbs_height_passable?(x,y,d,type) && $game_map.tbs_height([x,y]) <= TBS_HEIGHT::MAX_HEIGHT)
    end
  end


  #============================================================================
  # DataManager
  #============================================================================
  module DataManager
    #--------------------------------------------------------------------------
    # alias method: load_database
    #--------------------------------------------------------------------------
    class <<self; alias load_database_height load_database; end
    def self.load_database
      load_database_height
      load_notetags_height
    end

    #--------------------------------------------------------------------------
    # new method: load_notetags_height
    #--------------------------------------------------------------------------
    def self.load_notetags_height
      groups = [$data_actors,$data_enemies,$data_states]
      for group in groups
        for obj in group
          next if obj.nil?
          obj.load_notetags_height
        end
      end
    end
  end # DataManager

  #============================================================================
  # RPG::BaseItem
  #============================================================================
  class RPG::BaseItem
    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :height
    #--------------------------------------------------------------------------
    # common cache: load_notetags_height
    #--------------------------------------------------------------------------
    def load_notetags_height
      @height = nil
      #---
      self.note.split(/[\r\n]+/).each { |line|
        case line
        #---
        when TBS_HEIGHT::REGEXP::HEIGHT
          @height = $1.to_f
        end
        #---
      } # self.note.split
      #---
    end
  end # RPG::BaseItem

  #============================================================================
  # Game_Battler
  #============================================================================
  class Game_Battler < Game_BattlerBase
    #--------------------------------------------------------------------------
    # new method: unit_height -> the base height of the unit
    #--------------------------------------------------------------------------
    def unit_height
      actor? ? TBS_HEIGHT::DEFAULT_ACTOR_HEIGHT : TBS_HEIGHT::DEFAULT_ENEMY_HEIGHT
    end
    #--------------------------------------------------------------------------
    # new method: tbs_height
    #--------------------------------------------------------------------------
    #height object is a tuple [min_height, max_height]
    #for a unit on a tile, there are 3 data [ground_level,min_height,max_height]
    def tbs_height
      base_height = TBS_HEIGHT.height_addition(TBS::MOVE_DATA[move_rule_id][0])
      height = unit_height
      for s_id in @states
        h = $data_states[s_id].height
        height += h if h
      end
      height = [height, TBS_HEIGHT::MIN_BAT_HEIGHT].max
      return base_height, base_height+height
    end
  end

  #============================================================================
  # Game_Actor
  #============================================================================
  class Game_Actor < Game_Battler
    #--------------------------------------------------------------------------
    # override method: unit_height
    #--------------------------------------------------------------------------
    def unit_height
      h = $data_actors[@actor_id].height
      return h ? h : TBS_HEIGHT::DEFAULT_ACTOR_HEIGHT
    end
  end

  #============================================================================
  # Game_Enemy
  #============================================================================
  class Game_Enemy < Game_Battler
    #--------------------------------------------------------------------------
    # override method: unit_height
    #--------------------------------------------------------------------------
    def unit_height
      h = $data_enemies[@enemy_id].height
      return h ? h : TBS_HEIGHT::DEFAULT_ENEMY_HEIGHT
    end
  end

  #============================================================================
  # Game_Map
  #============================================================================
  class Game_Map
    #--------------------------------------------------------------------------
    # new method: tbs_height
    #--------------------------------------------------------------------------
    def tbs_height(pos)
      return TBS_HEIGHT.zone_height(region_id(pos[0],pos[1]))
    end

    #--------------------------------------------------------------------------
    # new method: height_property
    #--------------------------------------------------------------------------
    #return a triplet [zone_height, bat_foot, bat_height]
    def height_property(pos,bat = nil)
      min_h, max_h = bat.nil? ? [0,0] : bat.tbs_height
      zone_h = tbs_height(pos)
      return [zone_h, min_h+zone_h, max_h + zone_h]
    end
    #--------------------------------------------------------------------------
    # new method: simple_height_target
    #--------------------------------------------------------------------------
    def simple_height_target(bat,source,target)
      posList,dirs = TBS.crossed_positions_dir(source,target)
      max_h = height_property(source,bat)[2]
      tgt_prop = height_property(target,occupied_by?(target.x,target.y))

      obstacle_h = 0
      for i in 0...posList.size-1
        p = posList[i]
        if TBS::BATTLER_HIDE #this feature is still used
          bat2 = occupied_by?(p.x,p.y)
          if (bat2 && bat2.hide_view?(bat))
            prop = height_property(p,bat2)
            delta = prop[2] - max_h
            if delta > obstacle_h && (prop[1] - max_h <= obstacle_h)
              obstacle_h = delta
              return false if prop[2] >= tgt_prop[2]
            end
            next #this is enough
          end
        end
        h = tbs_height(p)
        delta = h - max_h
        if delta > obstacle_h
          obstacle_h = delta
          return false if h >= tgt_prop[2]
        end
      end
      return true
    end

    #--------------------------------------------------------------------------
    # new method: advanced_height_target
    #--------------------------------------------------------------------------
    def advanced_height_target(bat,source,target)
      return true #code not yet working!
      posList, dirs, aList = TBS_HEIGHT.crossedPositionsAxis(source,target)
      cast_h = height_property(source,bat)[2]
      b2 = occupied_by?(target.x,target.y)
      tgt_prop = height_property(target,b2)
      segList = []
      if b2
        segList.push([TBS_HEIGHT.get_a(cast_h,tgt_prop[1],aList[-1]),TBS_HEIGHT.get_a(cast_h,tgt_prop[2],aList[-1])])
      else
        segList.push([TBS_HEIGHT.get_a(cast_h,tgt_prop[0],aList[-2]),TBS_HEIGHT.get_a(cast_h,tgt_prop[0],aList[-1])])
      end
      return true
      region_id(x,y)
    end

    #--------------------------------------------------------------------------
    # overwrite method: can_see?
    #--------------------------------------------------------------------------
    def can_see?(bat,source,target)
      return true if source == target
      return TBS_HEIGHT::ADVANCED_HEIGHT_SYSTEM ? advanced_height_target(bat,source,target) : simple_height_target(bat,source,target)
    end
  end

  #============================================================================
  # module TBS_HEIGHT (for advamced calculation, not yet working!)
  #============================================================================
  module TBS_HEIGHT

    #get the a value for f(x) = ax +b such that h1 = f(0) and h2 = f(x)
    #-> h2-h1 = ax ...
    def self.get_a(h1,h2,x)
      return (h2-h1) / x
    end

    #return a triplet of lists l,dirs,dist
    #l = list of position crossed from source to target (will not contain the source pos but will contain the target)
    #d = direction (in rpgmaker way) showing by which angle the position is reached
    #dist = the distance between the source and the element from l
    def self.crossedPositionsAxis(source,target)
      l = []
      dirs = []
      dist = []
      sx = source.x
      sy = source.y
      tx = target.x
      ty = target.y
      dx = (tx - sx)
      dy = (ty - sy)
      #value of the function y = f(x) = ax + b
      #then what matters is for x barrier in [sx,tx] there are ys that changes as integers
      #same for y
      return l, dirs, dist if dx == 0 && dy == 0
      #diagonal case
      lx = dx < 0 ? -1 : 1
      ly = dy < 0 ? -1 : 1
      if dx.abs() == dy.abs()
        d = TBS.delta_to_direction(lx,ly)
        sqr2 = Math.sqrt(2)
        abscisse = sqr2/2
        while sx != tx
          sx += lx
          sy += ly
          l.push(POS.new(sx,sy))
          dirs.push(d)
          dist.push(abscisse)
          abscisse += sqr2
        end
        dits.push(abscisse) #adds one more value to check when leaving the last square
        return l, dirs, dist
      end
      a = 0
      b = 0
      if dx == 0
        a = 100000000 #a big enough integer such that y never changes
        b = 0 #the value does not matter
      else
        a = dy.to_f()/dx.to_f()
        b = sy - a*sx
      end
      xrange = crossedRange(sx,tx)
      yrange = crossedRange(sy,ty)
      d = 5
      ix = 0 #index in xrange
      iy = 0
      x = sx #previous
      y = sy
      while ix < xrange.size || iy < yrange.size
        x1 = sx #considered position
        y1 = sy
        if ix < xrange.size
          x1 = xrange[ix]
          y1 = a*x1 + b
          if iy < yrange.size #x and y must be compared
            y2 = yrange[iy]
            x2 = (y2 - b)/a
            #checks if x2 is closer to x than x1
            if (sx-x1).abs() > (sx-x2).abs()
              x1 = x2
              y1 = y2
              iy += 1
              d = TBS.delta_to_direction(0,ly)
              #d = dx > 0 ? 6 : 4
            else
              ix += 1
              d = TBS.delta_to_direction(lx,0)
            end

          else #only x matters
            ix += 1
            d = TBS.delta_to_direction(lx,0)
          end
        else #only y matters
          y1 = yrange[iy]
          x1 = (y1 - b)/a
          x1 = sx if dx == 0 #patch to deal with single axis
          iy += 1
          d = TBS.delta_to_direction(0,ly)
        end

        abscisse = (source - POS.new(x1,y1)).math_norm
        x1 = x1.round()
        y1 = y1.round()
        if x != x1 || y != y1
          pos = POS.new(x1,y1) #only an integer matters
          x = x1
          y = y1
          l.push(pos)
          dirs.push(d)
          dist.push(abscisse)
        end
      end #while
      return l, dirs, dist
    end #crossed_Positions
  end
end #$imported["TIM-TBS-Height"]
