#==============================================================================
# Change Shop Prices
# allows to multiply the price of items by a variable,
# change also their sell price
#------------------------------------------------------------------------------
# Author : Timtrack
# date : 16/11/2019
#------------------------------------------------------------------------------

module Shop_Prices
  SELL_DIV = 3 #the original price division when selling (when var is at 0)
  SELL_BEST_DIV = 2 #the lowest price division when selling
  VAR_PRICE = 4 #the variable that stores the price modification
  VAR_MAX_VALUE = 400.0
  
  #usually between 0 and 1, can be less than 0, 
  #the more the better for the player (less buy price, more sell gain)
  def SpGetVar() 
    [ $game_variables[VAR_PRICE], VAR_MAX_VALUE ].min / VAR_MAX_VALUE
  end
  
  def SpSell(p)
    [p / SELL_DIV,
    [p * (1.0 / SELL_DIV + (SELL_DIV - SELL_BEST_DIV) * SpGetVar() / (SELL_DIV * SELL_BEST_DIV)),                        
    p / SELL_BEST_DIV].min
    ].max
  end
end

class Window_ShopBuy < Window_Selectable
  include Shop_Prices
  def price(item)
    [ SpSell(@price[item]), #the item cannot be cheaper than its selling price
     @price[item] * (1.0 - SpGetVar() / 2.0)].max.to_i
  end
end

class Scene_Shop < Scene_MenuBase
  include Shop_Prices
  def selling_price
    SpSell(@item.price).to_i
  end
end
