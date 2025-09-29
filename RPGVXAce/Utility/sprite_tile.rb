#==============================================================================
# Sprite_Tile v1.2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 09/04/2025
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-SpriteTiles"] = true

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Utilitary script, won't do anything on its own.
# You may create Sprite_Tile that will follow the update on the map display
# You may create Autotiles with Sprite_AutoTile_Handler
# To do so, in your Spriteset (or equivalent) do the following to create the autotiles:
#
# Sprite_AutoTile_Handler.new(viewport,filename,posList)
# with filename the autotile file (you may have as many animation steps as you want)
# and posList a list of [x,y] coordinates on the map
#
# The AutoTile_Handler can be updated with update method to change the animation
# It must be disposed with the dispose method when unused
#
# If you wish to change the autotiles positions, you should dispose and create a new Sprite_AutoTile_Handler
# with an updated posList.
#==============================================================================
# Version History
#------------------------------------------------------------------------------
# 11/03/2025 - first version
# 18/03/2025 - anim speed is no more a constant (except default one)
# 09/04/2025 - code cleaning
#==============================================================================
# Installation: put it above Main and any other script using it
#==============================================================================
# Terms of use: free for commercial and non-commercial project if you give credit
#==============================================================================

module TIM_TILE
  TILE_DIM = 32 #the size of the tiles in pixels, should not be changed
  ANIM_SPEED = 6 #the number of frames before changing the pattern of the autotile
end

#==============================================================================
# Sprite_Tile: class of sprites that will stay on their cells even when the screen moves
#==============================================================================
class Sprite_Tile < Sprite_Base
  include TIM_TILE
  attr_accessor :map_x, :map_y
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  def initialize(viewport,x,y)
    super(viewport)
    @map_x = x #position x of the tile on the map
    @map_y = y #position y of the tile on the map
  end

  #--------------------------------------------------------------------------
  # override method: update
  #--------------------------------------------------------------------------
  def update
    update_pos
    super
  end

  #--------------------------------------------------------------------------
  # new method: update_pos -> will follow the map
  #--------------------------------------------------------------------------
  def update_pos
    self.x = screen_x
    self.y = screen_y
    self.z = screen_z
  end

  #--------------------------------------------------------------------------
  # new methods: screen_x, screen_y, screen_z
  #--------------------------------------------------------------------------
  def screen_x; $game_map.adjust_x(@map_x) * TILE_DIM; end
  def screen_y; $game_map.adjust_y(@map_y) * TILE_DIM; end
  def screen_z; 0; end
end #Sprite_Tile

#==============================================================================
# Sprite_SmallAutoTile: deals with 16*16 corners of autotiles
#==============================================================================
class Sprite_SmallAutoTile < Sprite_Tile
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  #neighbors is an array of 0/1 [0,1,2
  #                              3,4,5
  #                              6,7,8]
  #0 is the absence of a friendly autotil, 1 is the presence of a friendly auotile
  #index is a value between 0 and 3
  #A 32*32 tile is 4 autotiles with indices  0 1
  #                                          2 3
  def initialize(viewport,x,y,index,neighbors)
    super(viewport,x+0.5*(index%2),y+0.5*(index/2))
    @tx,@ty = get_tile_index(index,neighbors)
  end

  #--------------------------------------------------------------------------
  # override method: update -> pattern is calculated by handler class, represents the animation step
  #--------------------------------------------------------------------------
  def update(pattern = 0)
    update_src_rect(pattern)
    super()
  end

  #--------------------------------------------------------------------------
  # new method: get_tile_index -> a x,y position of a 16*16 pixel square in the autotile bitmap
  #--------------------------------------------------------------------------
  Relevant_neighbors = [[3,0,1],[1,2,5],[7,6,3],[5,8,7]]
  def get_tile_index(index,neighbors)
    l = Relevant_neighbors[index].map{|i| neighbors[i]}
    return 2 + index%2, index/2 if l[0] == 1 && l[1] == 0 && l[2] == 1
    mx = index%2 + (index%2 == 0 ? 2*neighbors[3] : 2*(1-neighbors[5]))
    my = 2+index/2 + (index/2 == 0 ? 2*neighbors[1] : 2*(1-neighbors[7]))
    return mx,my
  end

  #--------------------------------------------------------------------------
  # new method:  set_bitmap -> bitmap is loaded by the handler class
  #--------------------------------------------------------------------------
  def set_bitmap(bitmap)
    self.bitmap = bitmap
  end

  #--------------------------------------------------------------------------
  # new method:  update_src_rect -> chooses the 16*16 square in the bitmap to display
  #--------------------------------------------------------------------------
  def update_src_rect(pattern)
    sx = (@tx + 4*pattern) * TILE_DIM/2
    sy = @ty * TILE_DIM/2
    self.src_rect.set(sx, sy, TILE_DIM/2, TILE_DIM/2)
  end
end #Sprite_SmallAutoTile

#==============================================================================
# Sprite_AutoTile_Handler: loads the bitmap, decides the number of animation steps
# creates all Sprite_SmallAutoTile and handles them
#==============================================================================
class Sprite_AutoTile_Handler
  #--------------------------------------------------------------------------
  # override method: initialize
  #--------------------------------------------------------------------------
  #posList is a list of positions [x,y]
  def initialize(viewport,filename,posList, anim_speed = TIM_TILE::ANIM_SPEED)
    @bitmap = Cache.load_bitmap("",filename)
    @frame_step = 0 #the frame step
    @pattern = 0 #the pattern id, in [0,@anim_steps[
    @anim_speed = anim_speed #number of frames before changing animation
    @anim_steps = @bitmap.width/(2*TIM_TILE::TILE_DIM) #the number of anim frames, 1 for non-animated autotiles, 3 for RPG Maker animated autotiles, can be anything depending on the width of the bitmap
    @sprite_list = [] #stores all the Sprite_SmallAutoTile of the same autotile
    init_sprite_list(viewport,posList)
  end

  #--------------------------------------------------------------------------
  # new method: init_sprite_list -> called on initialize
  #--------------------------------------------------------------------------
  def init_sprite_list(viewport,posList)
    #generates a grid of 0 and 1 for tile presence
    my_map = [0]*($game_map.width*$game_map.height)
    for p in posList
      my_map[p[0] + p[1]*$game_map.width] = 1
    end
    for p in posList
      #generates the neighorhood in 8 directions of the position studied
      neigh = []
      for y in [p[1]-1,p[1],p[1]+1]
        for x in [p[0]-1,p[0],p[0]+1]
          #note: does not deal with torus maps
          $game_map.valid?(x,y) ? neigh.push(my_map[x+y*$game_map.width]) : neigh.push(0)
        end
      end
      #create a Sprite_SmallAutoTile for each 16*16 squarre of a 32*32 tile
      [0,1,2,3].each{|i| @sprite_list.push(Sprite_SmallAutoTile.new(viewport,p[0],p[1],i,neigh))}
    end
    @sprite_list.each{|s| s.set_bitmap(@bitmap)} #links the bitmap to each sprites
  end

  #--------------------------------------------------------------------------
  # new method: update -> must be called by a spriteset
  #--------------------------------------------------------------------------
  def update
    update_anim
    @sprite_list.each{|s| s.update(@pattern)}
  end

  #--------------------------------------------------------------------------
  # new method: update_anim -> updates the pattern
  #--------------------------------------------------------------------------
  def update_anim
    @frame_step = (@frame_step+1) % @anim_speed
    @pattern = (@pattern+1) % @anim_steps if @frame_step == 0
  end

  #--------------------------------------------------------------------------
  # new method: dispose -> must be called by a spriteset
  #--------------------------------------------------------------------------
  def dispose
    @sprite_list.each{|s| s.dispose}
    @sprite_list = []
    #@bitmap.dispose #bitmap is in the cache so I guess there is no need to do this especially if the same bitmap is used somewhere else
  end
end #Sprite_AutoTile_Handler
