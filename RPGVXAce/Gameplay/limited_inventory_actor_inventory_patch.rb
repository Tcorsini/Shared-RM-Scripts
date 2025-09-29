#==============================================================================
# Actor Inventory, Limited Inventory and Instance Items compatibility patch
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 02/06/2025
# Requires: TheoAllen - Limited Inventory and Hime's Actor Inventory
# Supports Hime's Instance Items
#==============================================================================
# Note: tested with the following script order:
# Limited Inventory
# Instance Items*
# Core - Inventory
# Core - Inventory - Instance Items patch*
# Actor Inventory
# Actor Inventory - Instance Items*
# Actor Inventory Scenes
# This patch
#
# * Use the scripts with the symbol if you use Hime's instance items
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"] = true

module TimPatch
  #set to true for TheoAllen's script to slow paarty members if at least one
  #actor inventory is full, else all inventories must be full to slow the party
  INVENTORY_SLOWED_ANY = false
  
  #set to true for extra items to be given to other actors inventories when
  #current actor inventory is full (item is discarded if no inventory can handle it)
  DISTRIBUTE_EXTRA_ITEMS = true
  
  #if an item is non discardable and non usable in the menu:
  #disable the item from the menu if this option is true
  #if the option is false, you can still select the item with only the option to cancel
  #your action
  DISABLE_NON_USABLE_AND_DISCARDABLE_ITEMS = false
  
  #-----------------------------------------------------------------------------
  # new method: discardable? -> meant to overwrite TheoAllen's discardable 
  # method that was hidden in a window object (code is exactly the same)
  #-----------------------------------------------------------------------------
  def self.discardable?(item)
    return false if item.nil?
    !(item.is_a?(RPG::Item) && item.key_item?)
  end
end #TimPatch

#==============================================================================
# Game_Inventory
#==============================================================================
class Game_Inventory
  attr_accessor :force_gain
end #Game_Inventory

#==============================================================================
# Game_ActorInventory
#==============================================================================
class Game_ActorInventory < Game_Inventory
  #-----------------------------------------------------------------------------
  # alias method: max_item_number -> handles the weight
  #-----------------------------------------------------------------------------
  alias timpatch_liminv_max_item max_item_number
  def max_item_number(item)
    return 9999999 if @force_gain #don't ask for weight in force gain mode
    $BTEST ? timpatch_liminv_max_item(item) : @actor.inv_max_item(item) + item_number(item)
  end
  
  if $imported["TH_InstanceItems"]
  #-----------------------------------------------------------------------------
  # alias method: add_instance_item -> will forbid new insstances to be given if inventory is full
  #-----------------------------------------------------------------------------
  alias timpatch_liminv_add_instance_item add_instance_item
  def add_instance_item(item)
    if actor.inv_max_item(item) <= 0 && !@force_gain
      $game_party.distribute_instance_item(item) if TimPatch::DISTRIBUTE_EXTRA_ITEMS
    else
      timpatch_liminv_add_instance_item(item)
    end
  end
  else #compatibility if no instance item script is used
    def instance_enabled?(item); false; end
  end#$imported["TH_InstanceItems"]
  
  if TimPatch::DISTRIBUTE_EXTRA_ITEMS
  #-----------------------------------------------------------------------------
  # alias method: gain_item
  #-----------------------------------------------------------------------------
  alias timpatch_instance_gain_item gain_item
  def gain_item(item, amount, include_equip = false)
    return timpatch_instance_gain_item(item, amount, include_equip) if @force_gain || instance_enabled?(item) || amount <= 0
    #case where item is not instanciable and amount is > 0
    place = @actor.inv_max_item(item)
    return timpatch_instance_gain_item(item, amount, include_equip) if place >= amount
    #if not enough space for items, we disstribute the rest to the party members:
    r = timpatch_instance_gain_item(item, place, include_equip)
    $game_party.distribute_extra_items(item, amount-place)
    return r #just a failsafe if gain_item had a return value
  end
  end #TimPatch::DISTRIBUTE_EXTRA_ITEMS
end #Game_ActorInventory

#==============================================================================
# Game_Actor -> all new methods here were pasted from Game_Party in Limited Inventory
#==============================================================================
class Game_Actor < Game_Battler
  def inv_maxed?
    inv_max <= total_inv_size
  end
  
  #this one contains the actor inventory AND their equipment
  def total_inv_size
    result = all_items.inject(0) {|total,item| total + (item_number(item) * item.inv_size)}
    result += equip_size
    result
  end
  
  def inv_max_item(item)
    return 9999999 if item.nil? || item.inv_size == 0
    free_slot / item.inv_size
  end
  
  def free_slot
    inv_max - total_inv_size
  end
  
  alias theo_liminv_item_max? item_max?
  def item_max?(item)
    $BTEST ? theo_liminv_item_max?(item) : inv_max_item(item) <= 0
  end
  
  def near_maxed?
    free_slot.to_f / inv_max <= Theo::LimInv::NearMaxed_Percent/100.0
  end
  
  def item_size(item)
    return 0 unless item
    item.inv_size * item_number(item)
  end
  
  #-----------------------------------------------------------------------------
  # alias method: max_item_number
  #-----------------------------------------------------------------------------
  alias timpatch_liminv_max_item max_item_number
  def max_item_number(item)
    return 9999999 if Theo::LimInv::ForceGain
    $BTEST ? timpatch_liminv_max_item(item) : inv_max_item(item) + item_number(item)
  end

  #-----------------------------------------------------------------------------
  # alias method: gain_item
  #-----------------------------------------------------------------------------
  alias timpatch_liminv_gain_item gain_item
  def gain_item(*args)
    if Theo::LimInv::ForceGain
      force_gain_item(*args)
    else
      timpatch_liminv_gain_item(*args)
    end
  end
  
  if $imported["TH_InstanceItems"]
  #-----------------------------------------------------------------------------
  # new method: add_instance_item
  #-----------------------------------------------------------------------------
  def add_instance_item(item)
    @inventory.add_instance_item(item)
  end
  end #$imported["TH_InstanceItems"]
  
  #-----------------------------------------------------------------------------
  # new method: force_gain_item
  #-----------------------------------------------------------------------------
  def force_gain_item(*args)
    @inventory.force_gain = true
    timpatch_liminv_gain_item(*args)
    @inventory.force_gain = false
  end
end #Game_Actor

#==============================================================================
# Game_Party -> inventory is the sum of all inventories, note that inv_max is already defined that way
#==============================================================================
class Game_Party < Game_Unit
  #-----------------------------------------------------------------------------
  # overwrite method: total_inv_size
  #-----------------------------------------------------------------------------
  def total_inv_size
    members.inject(0) {|r,a| r+a.total_inv_size}
  end
  
  #-----------------------------------------------------------------------------
  # overwrite method: force_gain_item (NOTE: inventory size or checking of party is not implemented!)
  #-----------------------------------------------------------------------------
  def force_gain_item(item, amount, include_equip = false)
    return @inventory.gain_item(item, include_equip) if $imported["TIM-AI-addon-SharedItems"] && TIM::ActorInventoryAddon.shared_inventory?(item)
    leader.force_gain_item(item, amount, include_equip)
  end
  
  #-----------------------------------------------------------------------------
  # new method: distribute_extra_items -> called when an invenotry is full and 
  # others are not, only if DISTRIBUTE_EXTRA_ITEMS is true (handles multiple instance items)
  #-----------------------------------------------------------------------------
  def distribute_extra_items(item, amount)
    candidates = members.select{|a| a.inv_max_item(item) >= 1}
    for a in candidates
      to_add = [0,[a.inv_max_item(item), amount].min].max
      a.gain_item(item, to_add)
      amount -= to_add
      return if amount <= 0
    end
  end
  
  
  if $imported["TH_InstanceItems"]
  #-----------------------------------------------------------------------------
  # new method: distribute_instance_item -> called when an invenotry is full and 
  # others are not, only if DISTRIBUTE_EXTRA_ITEMS is true (handles instance items)
  #-----------------------------------------------------------------------------
  def distribute_instance_item(item)
    candidate = members.find{|a| a.inv_max_item(item) >= 1}
    candidate.add_instance_item(item) if candidate #do nothing if no candidate was found
  end
  end #$imported["TH_InstanceItems"]
end #Game_Party

#==============================================================================
# Game_Player -> slow down features from single actors (only if option INVENTORY_SLOWED_ANY is true!)
#==============================================================================
if TimPatch::INVENTORY_SLOWED_ANY
class Game_Player
  #-----------------------------------------------------------------------------
  # alias method: dash?
  #-----------------------------------------------------------------------------
  alias timpatch_liminv_dash? dash?
  def dash?
    return false if Theo::LimInv::Full_DisableDash && $game_party.members.any?{|a| a.inv_maxed?}
    return timpatch_liminv_dash?
  end
  
  #-----------------------------------------------------------------------------
  # overwrite method: move_penalty
  #-----------------------------------------------------------------------------
  def move_penalty
    Theo::LimInv::Full_SlowDown && $game_party.members.any?{|a| a.inv_maxed?} ? 1 : 0
  end
end #Game_Player
end #TimPatch::INVENTORY_SLOWED_ANY

#==============================================================================
# Window_Base
#==============================================================================
class Window_Base < Window
  #-----------------------------------------------------------------------------
  # alias method: draw_inv_slot
  #-----------------------------------------------------------------------------
  alias actor_inv_patch_draw_inv_slot draw_inv_slot 
  def draw_inv_slot(x,y,width = contents.width,align = 2)
    return actor_inv_patch_draw_inv_slot(x,y,width,align) unless SceneManager.scene_is?(Scene_Item) || SceneManager.scene_is?(Scene_Shop) || SceneManager.scene_is?(Scene_Battle)
    #added
    actor = SceneManager.scene_is?(Scene_Battle) ? BattleManager.actor : SceneManager.scene.actor
    #replaced $game_party with actor:
    txt = sprintf("%d/%d", actor.total_inv_size, actor.inv_max)
    color = Theo::LimInv::NearMaxed_Color
    if actor.near_maxed?
      change_color(text_color(color))
    else
      change_color(normal_color)
    end
    draw_text(x,y,width,line_height,txt,align)
    change_color(normal_color)
  end
  
  #-----------------------------------------------------------------------------
  # overwrite method: draw_item_size
  #-----------------------------------------------------------------------------
  def draw_item_size(item,x,y,total = true,width = contents.width)
    rect = Rect.new(x,y,width,line_height)
    change_color(system_color)
    draw_text(rect,Theo::LimInv::InvSizeVocab)
    change_color(normal_color)
    #modified here:
    number = get_item_size(item,total)
    draw_text(rect,number,2)
  end
  
  #-----------------------------------------------------------------------------
  # new method: get_item_size
  #-----------------------------------------------------------------------------
  def get_item_size(item,total = true)
    if Theo::LimInv::DrawTotal_Size && total
      actor = SceneManager.scene_is?(Scene_Battle) ? BattleManager.actor : SceneManager.scene.actor
      actor.item_size(item)
    else
      item.nil? ? 0 : item.inv_size
    end
  end
end #Window_Base

#==============================================================================
# Window_DiscardAmount
#==============================================================================
class Window_DiscardAmount < Window_Base
  #-----------------------------------------------------------------------------
  # overwrite method: refresh
  #-----------------------------------------------------------------------------
  def refresh
    contents.clear
    return unless @item
    draw_item_name(@item,0,0,true,contents.width)
    actor = SceneManager.scene.actor
    txt = sprintf("%d/%d",@amount, actor.item_number(@item))
    draw_text(0,0,contents.width,line_height,txt,2)
  end
  #-----------------------------------------------------------------------------
  # overwrite method: lose_item
  #-----------------------------------------------------------------------------
  def lose_item
    #replaced 
    #$game_party.lose_item(@item,@amount)
    #with:
    actor = SceneManager.scene.actor
    actor.lose_item(@item,@amount)
    #---
    @itemlist.redraw_current_item
    @freeslot.refresh
    if actor.item_number(@item) == 0
      Sound.play_ok
      @itemlist.activate.refresh
      @itemlist.update_help
      @cmn_window.close.deactivate
      close
    else
      close_window
    end
  end
  #-----------------------------------------------------------------------------
  # overwrite method: change_amount
  #-----------------------------------------------------------------------------
  def change_amount(num)
    actor = SceneManager.scene.actor
    @amount = [[@amount+num,0].max,actor.item_number(@item)].min
    Sound.play_cursor
    refresh
  end
end #Window_DiscardAmount

#==============================================================================
# Window_ItemUseCommand
#==============================================================================
class Window_ItemUseCommand < Window_Command
  #-----------------------------------------------------------------------------
  # overwrite method: discardable? -> define the method outside of the window obj
  #-----------------------------------------------------------------------------
  def discardable?(item)
    TimPatch.discardable?(item)
  end
end #Window_ItemUseCommand

#==============================================================================
# Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
  
  if $imported["TH_InstanceItems"]
  #-----------------------------------------------------------------------------
  # alias method: draw_item_number
  #-----------------------------------------------------------------------------
  alias timpatch_ai_li_draw_item_number draw_item_number
  def draw_item_number(rect, item)
    timpatch_ai_li_draw_item_number(rect,item) if item.is_template? 
  end
  end #$imported["TH_InstanceItems"]
  #-----------------------------------------------------------------------------
  # overwrite method: enable? -> restores TheoAllen's Limited Inventory behavior
  #-----------------------------------------------------------------------------
  alias timpatch_ai_li_enable? enable?
  def enable?(item)
    return false unless item
    return true unless TimPatch::DISABLE_NON_USABLE_AND_DISCARDABLE_ITEMS
    item && (timpatch_ai_li_enable?(item) || discardable?(item))
  end
  #-----------------------------------------------------------------------------
  # new method: discardable?
  #-----------------------------------------------------------------------------
  def discardable?(item)
    SceneManager.scene_is?(Scene_Item) && TimPatch.discardable?(item)
  end
end #Window_ItemList

#==============================================================================
# Window_ShopNumber
#==============================================================================
class Window_ShopNumber < Window_Selectable
  #-----------------------------------------------------------------------------
  # overwrite method: draw_itemsize
  #-----------------------------------------------------------------------------
  def draw_itemsize
    actor = SceneManager.scene_is?(Scene_Shop) ? SceneManager.scene.actor : $game_party.leader
    
    item_size = @number * @item.inv_size
    total_size = actor.total_inv_size + 
      (@mode == :buy ? item_size : -item_size)
    txt = sprintf("%d/%d",total_size,actor.inv_max)
    ypos = item_y + line_height * ($imported["YEA-ShopOptions"] ? 5 : 4)
    rect = Rect.new(4,ypos,contents.width-8,line_height)
    change_color(system_color)
    draw_text(rect,Theo::LimInv::InvSlotVocab)
    change_color(normal_color)
    draw_text(rect,txt,2)
  end
end #Window_ShopNumber

#==============================================================================
# Scene_Item
#==============================================================================
class Scene_Item < Scene_ItemBase
  attr_reader :actor
  #-----------------------------------------------------------------------------
  # overwrite method: on_item_ok
  #-----------------------------------------------------------------------------
  def on_item_ok
    #@actor.last_item.object = item
    @use_command.set_item(item)
    @use_command.open
    @use_command.activate
    @use_command.select(0)
  end
  
  #-----------------------------------------------------------------------------
  # alias method: use_command_ok
  #-----------------------------------------------------------------------------
  alias timpatch_ai_li_use_command_ok use_command_ok
  def use_command_ok
    @actor.last_item.object = item
    timpatch_ai_li_use_command_ok
  end
  
  #-----------------------------------------------------------------------------
  # alias method: on_actor_change
  #-----------------------------------------------------------------------------
  alias timpatch_ai_li_on_actor_change on_actor_change
  def on_actor_change
    timpatch_ai_li_on_actor_change
    @freeslot.refresh
  end
end #Scene_Item

#==============================================================================
# Scene_Shop
#==============================================================================
class Scene_Shop < Scene_MenuBase
  attr_reader :actor
  
  if $imported["TH_ActorInventoryScenes"]
  #-----------------------------------------------------------------------------
  # overwrite method: start -> bugfix to Hime's script
  #-----------------------------------------------------------------------------
  def start
    @actor = $game_party.leader
    th_actor_inventory_start
  end
  end
  #-----------------------------------------------------------------------------
  # overwrite method: do_buy
  #-----------------------------------------------------------------------------
  def do_buy(number)
    $game_party.lose_gold(number * buying_price)
    @actor.gain_item(@item, number)
  end
end #Scene_Shop