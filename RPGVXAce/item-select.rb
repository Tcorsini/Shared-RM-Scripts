#==============================================================================
# Item Selection
# Aims to extends the basic item selection which is very limited in VX Ace
# Allows to set menu for other items rather than only key item
#------------------------------------------------------------------------------
# Author : Timtrack
# date : 16/11/2019
# modified in 29/04/2025 for code clean
#------------------------------------------------------------------------------
#begin
#Frenglish :
#  Usage :
#    Before calling the item selection command (basic command)
#    the variable ITEM_CLASS_VARIABLE (default 100) can be chaged to choose
#    other items types such as basic items, weapons, armor (list below)
#
#    If using different item types (equipments or all, value 5 or 6) the type of
#    the item should be stored in ITEM_SELECTED_CLASS_VARIABLE (default 99)
#    only if ITEM_SELECTED_RETURN_CLASS is set to true
#    The type is 0 if item, 1 if weapon, 2 if armor
#
#    By default, only usable items can be selected, it is possible here to select
#    any item, this feature is stored in switch ITEM_SELECTION_SWITCH (default 100).
#    If the switch is set to true, any displayed item can be selected, else, the
#    default comportment is called.
#
#Français :
#  Utilisation :
#    Avant d'appeler la fenêtre de selection des objets, on modifie
#    la variable ITEM_CLASS_VARIABLE (par défaut 100) pour afficher
#    d'autres types d'objets comme les items de base, les armes ou les armures
#    (possibilités dans la liste ITEM_SELECTION_CLASS)
#
#    Il est possible d'afficher plusieurs types d'objets à la fois
#    (armes et armures ou n'importe quoi), le type de l'objet selectionné devrait
#    être stocké dans la variable ITEM_SELECTED_CLASS_VARIABLE (par défaut 99), cette
#    propriété est activé si ITEM_SELECTED_RETURN_CLASS est mis à "true"
#    La valeur du type stocké est :
#      0 si item,
#      1 si arme,
#      2 si armure
#
#    De base, on ne peut choisir que les objets utilisables, il est maintenant
#    possible de selectionner n'importe quel objet dans la liste, cette fonctionnalité
#    est définie par l'interrupteur ITEM_SELECTION_SWITCH (par défaut 100).
#    Si l'interrupteur est vrai, alors n'importe quel objet peut être choisi, sinon
#    le comportement par défaut est effectué.
#
#==============================================================================
module Item_Selection

  #types concerned and the variable value corresponding
  ITEM_SELECTION_CLASS = {
    0 => :item,
    1 => :weapon,
    2 => :armor,
    3 => :key_item,
    4 => :key_and_items, #all items
    #hard to use : should stores the type of item selected
    5 => :equipments, #weapons and armors
    6 => :all, #any object
  }

  #var where the type of the objects displayed is stored
  ITEM_CLASS_VARIABLE = 100
  #if switch true, then default (only selectable items) else any item is selectable
  ITEM_SELECTION_SWITCH = 100


  #is the type (weapon, item, armor) of the object stored ?
  ITEM_SELECTED_RETURN_CLASS = false
  #var where the type of the selected object is stored
  #stores 0 if item, 1 if weapon, 2 if armor
  ITEM_SELECTED_CLASS_VARIABLE = 99
end #Item_Selection

#============================================================================
# Window_KeyItem
#============================================================================
class Window_KeyItem < Window_ItemList
  include Item_Selection
  #--------------------------------------------------------------------------
  # alias method: update_placement -> when opening the window,
  # choose beforehand which items selecting
  #--------------------------------------------------------------------------
  alias update_placement_item_selection update_placement
  def update_placement
    self.category = ITEM_SELECTION_CLASS[$game_variables[ITEM_CLASS_VARIABLE]]
    update_placement_item_selection
  end

  #--------------------------------------------------------------------------
  # alias method: enable? -> when selecting an item,
  # set if any item can be chosen or only the usable
  #--------------------------------------------------------------------------
  alias enable_item_selection enable?
  def enable?(item)
    $game_switches[ITEM_SELECTION_SWITCH] || enable_item_selection(item)
  end

  #--------------------------------------------------------------------------
  # alias method: include? -> when opening the windows, sets which items are visible
  #--------------------------------------------------------------------------
  alias include_item_selection include?
  def include?(item)
    case @category
    when :key_and_items
      item.is_a?(RPG::Item)
    when :equipments
      item.is_a?(RPG::Weapon) || item.is_a?(RPG::Armor)
    when :all
      return true
    else
      include_item_selection(item)
    end
  end

  #--------------------------------------------------------------------------
  # alias method: on_ok -> when the item is selected, stores if chosen,
  # the type of the item
  #--------------------------------------------------------------------------
  alias on_ok_item_selection on_ok
  def on_ok
    if ITEM_SELECTED_RETURN_CLASS
      result = item ? item_class_value(item) : 0
      $game_variables[ITEM_SELECTED_CLASS_VARIABLE] = result
    end
    on_ok_item_selection
  end

  #--------------------------------------------------------------------------
  # new method: item_class_value -> determines a value for the type of the item
  #--------------------------------------------------------------------------
  def item_class_value(item)
    return 0 if item.is_a?(RPG::Item)
    return 1 if item.is_a?(RPG::Weapon)
    return 2 #armor
  end
end #Window_KeyItem
