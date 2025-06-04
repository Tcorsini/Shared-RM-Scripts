#==============================================================================
# TBS Height
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 09/05/2025
# Requires: [TBS] by Timtrack
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-Height"] = true #set to false if you wish to disable the modifications
raise "TBS Height requires TBS by Timtrack" unless $imported["TIM-TBS"] if $imported["TIM-TBS-Height"]

#==============================================================================
# Updates
#------------------------------------------------------------------------------
# 24/02/2025: first version
# 09/04/2025: code fix
# 09/05/2025: adapted to Core v0.8, first iteration of ADVANCED_HEIGHT_SYSTEM
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
# You should modify the constants from TBS::HEIGHT to settle the default height
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

if $imported["TIM-TBS-Height"]
  #============================================================================
  # TBS
  #============================================================================
  module TBS
    #==========================================================================
    # HEIGHT
    #==========================================================================
    module HEIGHT
      DEFAULT_ACTOR_HEIGHT = 1
      DEFAULT_ENEMY_HEIGHT = 1

      module REGEXP
        HEIGHT       = /<height:\s*\-*((\d*\.)?\d+)>/i
      end

      #SIMPLE SYSTEM: follows a min/max operation, higher units can target things below
      #them (or at the same level) while higher tiles are obstacles to lower tiles
      #If there is a tile even higher behind, it will be seen by the caster.
      #ADVCANCED SYSTEM: similar to railcasting when checking which tiles cann be obstacles
      #Draw a line from caster to target in 3d and checks if the crossed tiles/units are obstacles
      ADVANCED_HEIGHT_SYSTEM = true
      DEFAULT_ZONE_HEIGHT = 0 #if no zone is specified or ZONE_HEIGHT[zone_id] is not specified

      MIN_BAT_HEIGHT = 0.1 #must be a stricly positive value

      FLY_HEIGHT = 1 #this will be added to the height of the battler when flying, leaving space between its legs and the ground too
      MAX_HEIGHT = 100 #if zone_height > MAX_HEIGHT, then the tile cannot be crossed by the battler, this puts a limit to flying unit with virtual obstacles

      #indices are zone_ids, values or the height associated to each zone
      #height can be real number
      ZONE_HEIGHT = [DEFAULT_ZONE_HEIGHT,1,2,3,4,5,6,7,8,9,
                    1000,-1,-2,-3,-4,-5,-6,-7,-8,-9]

    #==========================================================================
    # Changing things below is at your own risk!
    #==========================================================================

      def self.zone_height(zone_id)
        h = ZONE_HEIGHT[zone_id]
        return h.nil? ? DEFAULT_ZONE_HEIGHT : h
      end

      #move type is ground, fly etc.
      def self.height_addition(move_type)
        return move_type == :fly ? FLY_HEIGHT : 0
      end
    end # HEIGHT

    #--------------------------------------------------------------------------
    # alias method: tbs_passable? (for move rules -> takes into account a maximum altitude)
    #--------------------------------------------------------------------------
    class <<self; alias tbs_height_passable? tbs_passable?; end
    def self.tbs_passable?(x,y,d,type)
      return (tbs_height_passable?(x,y,d,type) && $game_map.tbs_height([x,y]) <= HEIGHT::MAX_HEIGHT)
    end
  end # TBS

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
        when TBS::HEIGHT::REGEXP::HEIGHT
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
      actor? ? TBS::HEIGHT::DEFAULT_ACTOR_HEIGHT : TBS::HEIGHT::DEFAULT_ENEMY_HEIGHT
    end
    #--------------------------------------------------------------------------
    # new method: tbs_height
    #--------------------------------------------------------------------------
    #height object is a tuple [min_height, max_height]
    #for a unit on a tile, there are 3 data [ground_level,min_height,max_height]
    def tbs_height
      base_height = TBS::HEIGHT.height_addition(TBS::MOVE_DATA[move_rule_id][0])
      height = unit_height
      for s_id in @states
        h = $data_states[s_id].height
        height += h if h
      end
      height = [height, TBS::HEIGHT::MIN_BAT_HEIGHT].max
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
      return h ? h : TBS::HEIGHT::DEFAULT_ACTOR_HEIGHT
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
      return h ? h : TBS::HEIGHT::DEFAULT_ENEMY_HEIGHT
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
      return TBS::HEIGHT.zone_height(region_id(pos[0],pos[1]))
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
    # new method: simple_height_target -> return true if source can see target
    # Works like this:
    # I can see anything below my height unless there is an obstacle in the middle
    # If the obstacles met are above the height of my target, then I cannot see it
    #--------------------------------------------------------------------------
    def simple_height_target(bat,source,target)
      posList,dirs = TBS.crossed_positions_dir(source,target)
      max_h = height_property(source,bat)[2] #my height
      tgt_prop = height_property(target,occupied_by?(target.x,target.y))

      obstacle_h = 0 #max height of obstacles met
      for i in 0...posList.size-1
        p = posList[i]
        if TBS::BATTLER_HIDE #this feature is still used
          bat2 = occupied_by?(p.x,p.y)
          if (bat2 && bat2.hide_view?(bat))
            prop = height_property(p,bat2)
            delta = prop[2] - max_h #is the unit above my height?
            if delta > obstacle_h && (prop[1] - max_h <= obstacle_h)
              obstacle_h = delta
              return false if prop[2] >= tgt_prop[2]
            end
            next #this is enough
          end
        end
        #case when no bat2 is met:
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
    # new method: advanced_height_target -> return true if source can see target
    # Works like this: draw a line from source to target (as center)
    # If any cell met (or blocking battlers) have height above my line, then return
    # false
    #--------------------------------------------------------------------------
    def advanced_height_target(bat,source,target)
      #return true #code not yet working!
      posList, dirs, aList = TBS.crossed_positions_axis(source,target)
      cast_h = height_property(source,bat)[2]
      b2 = occupied_by?(target.x,target.y)
      tgt_prop = height_property(target,b2)

      a = TBS.get_a(cast_h,tgt_prop[1],aList[-2])
      b = TBS.get_a(cast_h,tgt_prop[2],aList[-1])
      true_a = [a,b].min
      #puts sprintf("For %s to target %d,%d", bat.name, target.x,target.y)
      seg_list = Interval.new(true_a,[a,b].max) #list of pairs [a,b] that represent available a values, basically an interval structure
      #puts seg_list.to_s
      i = 0
      until seg_list.empty? || i >= posList.size-1
        p = posList[i]
        if TBS::BATTLER_HIDE #this feature is still used
          bat2 = occupied_by?(p.x,p.y)
          if (bat2 && bat2.hide_view?(bat))
            prop = height_property(p,bat2)
            a = TBS.get_a(cast_h,prop[1],aList[i])
            b = TBS.get_a(cast_h,prop[2],aList[i+1])
            seg_list.remove([a,b].min,[a,b].max)
          end
        end
        a = true_a-1
        b = TBS.get_a(cast_h,tbs_height(p),aList[i+1])
        seg_list.remove([a,b].min,[a,b].max)
        i += 1
      end
      #puts seg_list.to_s
      return !seg_list.empty?
    end

    #--------------------------------------------------------------------------
    # overwrite method: can_see?
    #--------------------------------------------------------------------------
    def can_see?(bat,source,target)
      return true if source == target
      return TBS::HEIGHT::ADVANCED_HEIGHT_SYSTEM ? advanced_height_target(bat,source,target) : simple_height_target(bat,source,target)
    end
  end

  #============================================================================
  # module TBS (add advanced calculation, not yet working!)
  #============================================================================
  module TBS
    #--------------------------------------------------------------------------
    # new method: get_a -> get the a value for f(x) = ax +b such that h1 = f(0) and h2 = f(x)
    #--------------------------------------------------------------------------
    #h2-h1 = ax
    def self.get_a(h1,h2,x)
      return (h2-h1).to_f / x
    end

    #--------------------------------------------------------------------------
    # new method: crossed_positions_axis -> return a triplet l,d,dist with:
    # l an array of positions crossed from source to target (will not contain the source pos but will contain the target)
    # d an array of directions (in rpgmaker way) showing by which angle the position is reached
    # dist an array of distances between the source and the position from l
    # the distance of cell l[i] is dist[i] and dist[i+1] (when line meets square and when line leaves square)
    # as such, dist.size = l.size+1 to have the total length of the last cell
    #--------------------------------------------------------------------------
    def self.crossed_positions_axis(source,target)
      l, dirs, dist = [], [], []
      sx,sy = source.x, source.y
      tx,ty = target.x, target.y
      dx,dy = (tx - sx), (ty - sy)
      #value of the function y = f(x) = ax + b
      #then what matters is for x barrier in [sx,tx] there are ys that changes as integers
      #same for y
      return l, dirs, dist if dx == 0 && dy == 0
      #intialize main directions for x and y axis
      lx = dx < 0 ? -1 : 1
      ly = dy < 0 ? -1 : 1
      #diagonal case
      if dx.abs() == dy.abs()
        d = TBS.delta_to_direction(lx,ly)
        #added:
        sqr2 = Math.sqrt(2)
        abscisse = sqr2/2
        #---
        while sx != tx
          sx += lx
          sy += ly
          l.push(POS.new(sx,sy))
          dirs.push(d)
          #added:
          dist.push(abscisse)
          abscisse += sqr2
          #---
        end
        dist.push(abscisse)
        return l, dirs, dist
      end
      a = b = 0
      if dx == 0
        a = 100000000 #a big enough integer such that y never changes
        b = 0 #the value does not matter
      else
        a = dy.to_f()/dx.to_f()
        b = sy - a*sx
      end
      xrange = crossed_range(sx,tx)
      yrange = crossed_range(sy,ty)
      d = 5  #center direction
      ix = iy = 0 #index in xrange amd yrange
      x,y = sx,sy #previous positions
      while ix < xrange.size || iy < yrange.size
        x1, y1 = sx, sy #considered position
        if ix < xrange.size
          x1 = xrange[ix]
          y1 = a*x1 + b
          if iy < yrange.size #x and y must be compared
            y2 = yrange[iy]
            x2 = (y2 - b)/a
            #checks if x2 is closer to x than x1
            if (sx-x1).abs() > (sx-x2).abs()
              x1, y1 = x2, y2
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

        abscisse = (source - POS.new(x1,y1)).euclidian_norm #added
        x1 = x1.round()
        y1 = y1.round()
        if x != x1 || y != y1
          pos = POS.new(x1,y1) #only an integer matters
          x,y = x1,y1
          l.push(pos)
          dirs.push(d)
          dist.push(abscisse) #added
        end
      end #while
      last_abscisse = dist[-1] + 2*(target-l[-1]).euclidian_norm
      dist.push(last_abscisse)
      return l, dirs, dist
    end #crossed_positions_axis
  end #TBS

  #============================================================================
  # Interval -> class dealing with sets/intervals of float values
  #============================================================================
  class Interval
    attr_reader :seg_list
    #--------------------------------------------------------------------------
    # initialize -> min,max are float values (assumes that min <= max) such that
    # the interval corresponds to [min,max]
    #--------------------------------------------------------------------------
    def initialize(a,b)
      #an array of pairs [a,b] such that:
      # a <= b and
      # for i in [0,size-2] @seg_list[i][1] < @seg_list[i+1][0]
      @seg_list = []
      @seg_list.push([a,b]) if a <= b
    end

    #--------------------------------------------------------------------------
    # empty? -> return if the interval contains at least one element
    #--------------------------------------------------------------------------
    def empty?
      @seg_list.empty?
    end

    #--------------------------------------------------------------------------
    # contains? -> return if v (a float) is part of the interval
    #--------------------------------------------------------------------------
    def contains?(v)
      i = index(v)
      return false if i >= @seg_list.size
      return @seg_list[i][0] <= v && @seg_list[i][1] >= v
    end

    #--------------------------------------------------------------------------
    # min,max the min and max values of the segments
    #--------------------------------------------------------------------------
    def min; @seg_list[0][0]; end
    def max; @seg_list[-1][1]; end

    #--------------------------------------------------------------------------
    # index -> return given v (a float) the index i in the interval where v
    # is either in the segment [a,b] of index i or v is above the previous segment but
    # below this one
    # return:
    # i if v is below segement i
    # size if v is above maximum value
    #--------------------------------------------------------------------------
    def index(v)
      i = @seg_list.index{|a,b| b >= v} #improve this into binary search if you intend to use big range
      return i ? i : @seg_list.size
    end

    #--------------------------------------------------------------------------
    # add -> add segment [a,b] to interval, may delete internally sub arrays
    # the changed list will contain at most one more segment
    # (case where [a,b] is not intersecting with any segment)
    #--------------------------------------------------------------------------
    def add(a,b)
      return if a >= b
      ia, ib = index(a), index(b)
      return @seg_list.push([a,b]) if ia >= @seg_list.size #push new interval
      if ia == ib
        return @seg_list[ia][0] = a if @seg_list[ia][0] <= b #fuse intervals
        @seg_list.insert(ia,[a,b]) #distinct intervals -> insert [a,b] here
      else #ia < ib -> will fuse intervals for sure
        @seg_list[ia][0] = a if @seg_list[ia][0] > a #a is not in any interval
        b2 = b
        b2 = @seg_list[ib][1] if ib < @seg_list.size && @seg_list[ib][0] <= b
        @seg_list[ia][1] = b2
        #clean redundant segments
        max_slice = ib #the last id to remove
        max_slice -= 1 if ib < @seg_list.size && @seg_list[ib][0] > b #exclude this interval if b was not in it
        @seg_list.slice!(ia+1, max_slice-ia) #ex: ia = 2, ib = 4, this should be 3,1 or 3,2
      end
    end

    #--------------------------------------------------------------------------
    # remove -> remove segment [a,b] from the interval, may delete internally multiple
    # arrays, the changed list will contain at most one more segment (case where
    # [a,b] was inside another segment)
    #--------------------------------------------------------------------------
    def remove(a,b)
      return if a >= b
      #puts sprintf("Remove %f,%f from %s",a,b, to_s)
      ia, ib = index(a), index(b)
      return if ia >= @seg_list.size #don't remove anything
      if ia == ib
        if @seg_list[ia][0] <= b #reduce current interval
          min_v = @seg_list[ia][0]
          @seg_list[ia][0] = b
          @seg_list.insert(ia,[min_v,a]) if a >= min_v#split interval
        end
        #else: interval does not exists so no need to remove it
      else #ia < ib -> might remove many intervals
        start_slice = ia
        end_slice = ib
        if @seg_list[ia][0] < a #a is inside its interval
          @seg_list[ia][1] = a
          start_slice += 1
        end
        @seg_list[ib][0] = b if ib < @seg_list.size && @seg_list[ib][0] <= b #b is inside its interval
        #clean inbetween segments
        @seg_list.slice!(start_slice, end_slice-start_slice) #ex: ia = 2, ib = 4, this should be 2,2 or 3,1
      end
      #puts sprintf("Got %s",to_s)
    end


    #--------------------------------------------------------------------------
    # and -> intersection operation between two intervals self and other, return a new interval
    #--------------------------------------------------------------------------
    def and(other)
      ret = self.dup
      return ret if ret.empty? || other.empty?
      ret.remove(ret.min-1,other.min) if ret.min < other.min
      ret.remove(other.max,ret.max+1) if ret.max > other.max
      other.seg_list.each_with_index do |seg,i|
        next if i == 0 || i >= other.seg_list.size-1
        prev_b = other.seg_list[i-1][1]
        next_a = seg[0]
        ret.remove(prev_b,next_a)
      end
      return ret
    end

    #--------------------------------------------------------------------------
    # or -> union operation between two intervals self and other, return a new interval
    #--------------------------------------------------------------------------
    def or(other)
      ret = self.dup
      other.seg_list.each{|a,b| ret.add(a,b)}
      return ret
    end

    #--------------------------------------------------------------------------
    # to_s
    #--------------------------------------------------------------------------
    def to_s
      s = "{"
      @seg_list.each{|a,b| s += sprintf("[%f,%f], ",a,b)}
      s += "}"
      return s
    end
  end
end #$imported["TIM-TBS-Height"]
