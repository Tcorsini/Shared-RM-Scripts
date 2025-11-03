#-----------------------------------------------------------
# [VX] Terrain Tag
# Par timtrack, Delsin7 et Marrend
# Version 1.1 - RPG Maker VX seulement.
# 14/03/2021
#-----------------------------------------------------------
=begin
Par défaut, RPG Maker VX ne gère pas les terrain, ce qui rend plus difficile
la conception de certains puzzles ou d'effets visuels, obligeant généralement
à utiliser un script par fonctionnalité souhaitée (chouette...).
 
Ce petit script restaure cette fonctionnalité de base pour les tilesets B à E.
 
Utilisation :
Sur une map test, récupérez le numéro id du tile que vous souhaitez utiliser 
dans une variable de votre jeu en appel de script (attention à la position du code
dans l'appel, un code coupé engendre une erreur en jeu) :
$game_variables[id de la variable] = 
$game_map.get_tile_id($game_player.x , 
$game_player.y)
Vous n'avez plus qu'à le montrer via message avec la balise \v[id de la variable] 
ou F9.
 
Et éditez le module du script TERRAIN_TAG. Ajoutez à gauche l'id que vous avez
obtenu, à droite la valeur que vous souhaitez lui attribuer.
 
Ensuite, il ne vous reste plus qu'à l'utiliser en jeu, toujours via la
commande appel de script ou condition > script (3e page).
 
Pour récupérer le tag de la case du joueur :
$game_player.get_terrain_tag
Pour récupérer le tag de la case de l'event id de la map courante :
$game_map.events[id].get_terrain_tag
Pour récupérer le tag de la case x,y sur la map courante
$game_map.terrain_tag(x, y)
 
Vous n'avez plus qu'à l'utiliser pour ce que vous souhaitez faire !
=end
#-----------------------------------------------------------
 
module Terrain_Tag
  #Si le terrain n'est pas répertorié dans TERRAIN_TAG, on renvoie cette valeur :
  DEFAULT_TAG = 0
  
  # On associe à chaque id de terrain un tag ici (saut à la ligne obligatoire) :
  # A gauche le numéro du tile, à droite la valeur que vous souhaitez.
  TERRAIN_TAG = {
    1 => 1, 
    2 => 1, 
    5 => 1, 
    7 => 1, 
    768 => 2 # 1ère case du tile E.
  }
end
 
class Game_Map
  include Terrain_Tag
  
 # Renvoie l'id de terrain de la couche B à E (0 si rien n'est rempli)
  def get_tile_id(x,y)
    # La couche 2 correspond à B-E, 
    # La couche 1 m'est inconnue, 
    # La couche 0 correspond aux tileset A, dont les ids changent pour les tiles dynamiques
    for i in [2] #[1,0]
      tile_id = @map.data[x, y, i]
      return 0 if tile_id == nil # Il semblerait que cela puisse arriver.
      return tile_id
    end
  end
  
  # Renvoie le tag associé à l'id de terrain
  def terrain_tag(x,y)
    ret = TERRAIN_TAG[get_tile_id(x,y)]
    return DEFAULT_TAG if ret == nil
    return ret
  end
end
 
  # A chaque event est associé le tag à récupérer.
class Game_Character
  def get_terrain_tag
    $game_map.terrain_tag(@x, @y)
  end
end