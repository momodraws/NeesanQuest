#====================================================================
# Map Zoom Ace
# v.1.6
# Auteur : MGC
#
# Ce script pour RMVX Ace permet de jouer avec une carte zoomee.
# Le coefficient de zoom peut aller de 1/8 a 8
#
# Necessite :
# - le script "MGC Tilemap Ace" du meme auteur en V.1.4 minimum, place
#   directement au-dessus de ce script
#
# Utilisation :
# - pour une carte utilisant la tilemap du script "MGC Tilemap Ace" (cf.
#   ce script pour savoir comment obtenir une telle carte), deux
#   commandes en script sont utilisables :
#         - MGC.map_zoom=(nouvelle valeur de zoom)
#         - MGC.to_map_zoom(nouvelle valeur de zoom, duree de la transition)
#
# Configuration :
# - PARALLAX_ZOOM : alimente a true ou false
#         - true : le panorama subi le meme zoom que la carte. Desactive
#                 par defaut car il semble que cela introduit du lag, et
#                 je n'ai pas envie de reecrire la gestion du zoom de la
#                 classe Plane pour remplacer ce que nous a ecrit Enterbrain
#         - false : le panorama est insensible au zoom de la carte
# - DEFAULT_ZOOM : valeur de zoom par defaut qui s'applique a chaque entree
#         dans une carte supportant le zoom. Compris entre 0.125 et 8.0.
#
# Vous pouvez ajouter une commande dans le nom des cartes pour forcer le
# la valeur du zoom a l'entree dans cette carte. Cela est prioritaire par
# rapport a DEFAULT_ZOOM.
# - [Zx], ou x est un decimal entre 0.125 et 8.0 : zoom de la carte
# Exemple : My Worldmap[Z0.5]
#====================================================================
module MGC
  #--------------------------------------------------------------------------
  # * CONFIGURATION
  #--------------------------------------------------------------------------
  PARALLAX_ZOOM = false
  DEFAULT_ZOOM = 2.0 # [1.4]
  #--------------------------------------------------------------------------
  # * Initialisation
  #--------------------------------------------------------------------------
  @zoom = 1.0
  #--------------------------------------------------------------------------
  # * Aliased methods [1.4]
  #--------------------------------------------------------------------------
  class << self
    unless @already_aliased_mgc_zoom
      alias end_new_tilemap_mgc_zoom end_new_tilemap
      alias update_new_tilemap_mgc_zoom update_new_tilemap
      alias new_tilemap_effect_mgc_zoom? new_tilemap_effect?
      @already_aliased_mgc_zoom = true
    end
  end
  #--------------------------------------------------------------------------
  # * Fin de la nouvelle tilemap [1.4]
  #--------------------------------------------------------------------------
  def self.end_new_tilemap
    self.end_new_tilemap_mgc_zoom
    self.to_map_zoom(1.0, 1)
  end
  #--------------------------------------------------------------------------
  # * Initialisation de la valeur de zoom [1.4]-MOD
  #--------------------------------------------------------------------------
  def self.initialize_map_zoom
    @zoom = $game_system.map_zoom ? $game_system.map_zoom :
    $game_map.get_default_zoom
    @map_zoom_incr = Math.log(@zoom) / Math.log(2)
    @map_zoom_duration = 0
  end
  #--------------------------------------------------------------------------
  # * Change Map [1.4]
  #--------------------------------------------------------------------------
  def self.start_change_map_new_zoom
    @zoom = $game_map.get_default_zoom
    @map_zoom_incr = Math.log(@zoom) / Math.log(2)
    @map_zoom_duration = 0
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut zoom
  #--------------------------------------------------------------------------
  def self.map_zoom
    return @zoom
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut zoom
  #--------------------------------------------------------------------------
  def self.map_zoom=(zoom_value)
    unless map_zoom == zoom_value
      if zoom_value < 0.125 || zoom_value > 8.0 then return end
      @zoom = zoom_value
      $game_system.map_zoom = @zoom
      $game_player.center($game_player.x, $game_player.y)
    end
  end
  #--------------------------------------------------------------------------
  # * Incrementation de la valeur du zoom
  #--------------------------------------------------------------------------
  def self.incr_map_zoom(val = 0.02)
    @map_zoom_incr += val
    new_zoom = 2 ** @map_zoom_incr
    self.map_zoom = new_zoom
  end
  #--------------------------------------------------------------------------
  # * Pour aller progressivement vers une nouvelle valeur de zoom
  #--------------------------------------------------------------------------
  def self.to_map_zoom(new_zoom, duration)
    unless map_zoom == new_zoom
      if new_zoom < 0.125 || new_zoom > 8.0 then return end
      @map_zoom_duration = duration
      target_zoom_incr = Math.log(new_zoom) / Math.log(2)
      @map_zoom_step = (target_zoom_incr - @map_zoom_incr) / duration
      @target_map_zoom = new_zoom
    end
  end
  #--------------------------------------------------------------------------
  # * Mise a jour de la nouvelle tilemap [1.4]
  #--------------------------------------------------------------------------
  def self.update_new_tilemap
    if @new_tilemap_active && @map_zoom_duration > 0
      @map_zoom_duration -= 1
      if @map_zoom_duration == 0
        self.map_zoom = @target_map_zoom
      else
        self.incr_map_zoom(@map_zoom_step)
      end
    end
    update_new_tilemap_mgc_zoom
  end
  #--------------------------------------------------------------------------
  # * Verifie si un effet est en cours
  #--------------------------------------------------------------------------
  def self.new_tilemap_effect?
    return new_tilemap_effect_mgc_zoom? ||
    @new_tilemap_active && @map_zoom_duration > 0
  end
end

#==============================================================================
# ** Game_System [1.4]
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # * Attributs
  #--------------------------------------------------------------------------
  attr_accessor :map_zoom
end

#==============================================================================
# ** Viewport
#==============================================================================
class Viewport
  #--------------------------------------------------------------------------
  # * Attributs
  #--------------------------------------------------------------------------
  attr_reader :zoom
  attr_accessor :contains_zoomable_map
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias initialize_mgc_zoom initialize
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Initialisation
  #--------------------------------------------------------------------------
  def initialize(*args)
    initialize_mgc_zoom(*args)
    self.zoom = 1.0
    @contains_zoomable_map = false
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut zoom
  #--------------------------------------------------------------------------
  def zoom=(new_zoom)
    unless zoom == new_zoom
      if new_zoom < 0.125 || new_zoom > 8.0 then return end
      @zoom = new_zoom
    end
  end
  #--------------------------------------------------------------------------
  # * Mise a jour du zoom
  #--------------------------------------------------------------------------
  def update_zoom
    if contains_zoomable_map
      self.zoom = MGC.map_zoom
    end
  end
end

#==============================================================================
# ** MGC::Tilemap
#==============================================================================
module MGC
  class Tilemap
    #--------------------------------------------------------------------------
    # * Aliased methods
    #--------------------------------------------------------------------------
    unless @already_aliased_mgc_zoom
      alias initialize_mgc_zoom initialize
      alias update_mgc_zoom update
      @already_aliased_mgc_zoom = true
    end
    #--------------------------------------------------------------------------
    # * Initialisation
    #--------------------------------------------------------------------------
    def initialize(viewport)
      initialize_mgc_zoom(viewport)
      @sprite_render.no_viewport_zoom = true
      @sprite_render_layer2.no_viewport_zoom = true
      viewport.contains_zoomable_map = true
    end
    #--------------------------------------------------------------------------
    # * Mise a jour, appelee normalement a chaque frame
    #--------------------------------------------------------------------------
    def update
      if @visible
        self.zoom = viewport.zoom
      end
      update_mgc_zoom
    end
  end
end

#==============================================================================
# ** Plane
#==============================================================================
class Plane
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias initialize_mgc_zoom initialize
    alias ox_mgc_zoom= ox=
    alias oy_mgc_zoom= oy=
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Initialisation
  #--------------------------------------------------------------------------
  def initialize(*args)
    initialize_mgc_zoom(*args)
    @phase_viewport_zoom = false
    self.ox = 0
    self.oy = 0
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut ox
  #--------------------------------------------------------------------------
  def ox=(new_ox)
    unless @phase_viewport_zoom
      @base_ox = new_ox
    end
    self.ox_mgc_zoom = new_ox
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut ox
  #--------------------------------------------------------------------------
  def ox
    return @base_ox
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut oy
  #--------------------------------------------------------------------------
  def oy=(new_oy)
    unless @phase_viewport_zoom
      @base_oy = new_oy
    end
    self.oy_mgc_zoom = new_oy
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut oy
  #--------------------------------------------------------------------------
  def oy
    return @base_oy
  end
  #--------------------------------------------------------------------------
  # * Mise a jour du zoom en fonction du zoom du viewport
  #--------------------------------------------------------------------------
  def update_viewport_zoom
    if MGC::PARALLAX_ZOOM
      unless viewport.nil? || !viewport.contains_zoomable_map
        @phase_viewport_zoom = true
        self.zoom_x = viewport.zoom
        self.zoom_y = viewport.zoom
        self.ox = - ((Graphics.width >> 1) +
        (ox - (Graphics.width >> 1)) * viewport.zoom).to_i
        self.oy = - ((Graphics.height >> 1) +
        (oy - (Graphics.height >> 1)) * viewport.zoom).to_i
        @phase_viewport_zoom = false
      end
    end
  end
end

#==============================================================================
# ** Spriteset_Map
#==============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias start_new_tilemap_mgc_zoom start_new_tilemap
    alias update_parallax_mgc_zoom update_parallax
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Active la nouvelle tilemap [1.4]
  #--------------------------------------------------------------------------
  def start_new_tilemap
    unless @tilemap_new
      MGC.initialize_map_zoom
    end
    start_new_tilemap_mgc_zoom
  end
  #--------------------------------------------------------------------------
  # * Update [1.4]-MOD
  #--------------------------------------------------------------------------
  def update
    MGC.update_new_tilemap
    if $game_map.start_new_tilemap
      start_new_tilemap
      $game_map.start_new_tilemap = false
    elsif $game_map.end_new_tilemap
      end_new_tilemap
      $game_map.end_new_tilemap = false
    end
    update_viewports_zoom
    update_mgc_tilemap
  end
  #--------------------------------------------------------------------------
  # * Update Parallax
  #--------------------------------------------------------------------------
  def update_parallax
    update_parallax_mgc_zoom
    @parallax.update_viewport_zoom
  end
  #--------------------------------------------------------------------------
  # * Update Viewports Zoom
  #--------------------------------------------------------------------------
  def update_viewports_zoom
    @viewport1.update_zoom
  end
end

#==============================================================================
# ** Sprite
#==============================================================================
class Sprite
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias initialize_mgc_zoom initialize
    alias x_mgc_zoom= x=
    alias y_mgc_zoom= y=
    alias zoom_x_mgc_zoom= zoom_x=
    alias zoom_y_mgc_zoom= zoom_y=
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Attributs
  #--------------------------------------------------------------------------
  attr_accessor :no_viewport_zoom
  #--------------------------------------------------------------------------
  # * Initialisation
  #--------------------------------------------------------------------------
  def initialize(*args)
    initialize_mgc_zoom(*args)
    @phase_viewport_zoom = false
    self.x = 0
    self.y = 0
    self.zoom_x = 1.0
    self.zoom_y = 1.0
    self.no_viewport_zoom = false
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut x
  #--------------------------------------------------------------------------
  def x=(new_x)
    unless @phase_viewport_zoom
      @base_x = new_x
    end
    self.x_mgc_zoom = new_x
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut y
  #--------------------------------------------------------------------------
  def y=(new_y)
    unless @phase_viewport_zoom
      @base_y = new_y
    end
    self.y_mgc_zoom = new_y
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut x
  #--------------------------------------------------------------------------
  def x
    return @base_x
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut y
  #--------------------------------------------------------------------------
  def y
    return @base_y 
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut zoom_x
  #--------------------------------------------------------------------------
  def zoom_x=(new_zoom_x)
    unless @phase_viewport_zoom
      @base_zoom_x = new_zoom_x
    end
    self.zoom_x_mgc_zoom = new_zoom_x
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut zoom_y
  #--------------------------------------------------------------------------
  def zoom_y=(new_zoom_y)
    unless @phase_viewport_zoom
      @base_zoom_y = new_zoom_y
    end
    self.zoom_y_mgc_zoom = new_zoom_y
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut zoom_x
  #--------------------------------------------------------------------------
  def zoom_x
    return @base_zoom_x
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut zoom_y
  #--------------------------------------------------------------------------
  def zoom_y
    return @base_zoom_y 
  end
  #--------------------------------------------------------------------------
  # * Valeur reelle du zoom_x en prenant en compte le zoom de la carte
  #--------------------------------------------------------------------------
  def zoom_x_global
    return @zoom_x
  end
  #--------------------------------------------------------------------------
  # * Valeur reelle du zoom_y en prenant en compte le zoom de la carte
  #--------------------------------------------------------------------------
  def zoom_y_global
    return @zoom_y 
  end
end

#==============================================================================
# ** Sprite and all its subclasses [1.4]-MOD
#==============================================================================
[:Sprite, :Sprite_Base, :Sprite_Character, :Sprite_Battler, :Sprite_Picture,
:Sprite_Timer].each {|classname|
  parent = eval("#{classname}.superclass")
  eval(
  "class #{classname} < #{parent}
    unless @already_aliased_mgc_zoom_#{classname}
      alias update_mgc_zoom_#{classname} update
      @already_aliased_mgc_zoom_#{classname} = true
    end
    def update
      update_mgc_zoom_#{classname}
      if self.instance_of?(#{classname})
        if MGC.new_tilemap_active && viewport && !no_viewport_zoom &&
          viewport.contains_zoomable_map
          @phase_viewport_zoom = true
          self.zoom_x = @base_zoom_x * viewport.zoom
          self.zoom_y = @base_zoom_y * viewport.zoom
          self.x = ((Graphics.width >> 1) +
          (x - (Graphics.width >> 1)) * viewport.zoom).to_i
          self.y = ((Graphics.height >> 1) +
          (y - (Graphics.height >> 1)) * viewport.zoom).to_i
          @phase_viewport_zoom = false
          @in_new_tilemap_zoom = true
        elsif @in_new_tilemap_zoom
          self.zoom_x = @base_zoom_x
          self.zoom_y = @base_zoom_y
          @in_new_tilemap_zoom = false
        end
      end
    end
  end")
}

#==============================================================================
# ** Sprite_Character
#==============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias update_balloon_mgc_zoom update_balloon
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Update Balloon Icon
  #--------------------------------------------------------------------------
  def update_balloon
    update_balloon_mgc_zoom
    if @balloon_sprite then @balloon_sprite.update end
  end
end

#==============================================================================
# ** Sprite_Base
#==============================================================================
class Sprite_Base < Sprite
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias animation_set_sprites_mgc_zoom animation_set_sprites
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Set Animation Sprite
  #     frame : Frame data (RPG::Animation::Frame)
  #--------------------------------------------------------------------------
  def animation_set_sprites(frame)
    animation_set_sprites_mgc_zoom(frame)
    @ani_sprites.each {|sprite| sprite.update}
  end
end

#==============================================================================
# ** Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_zoom
    alias set_display_pos_mgc_zoom set_display_pos
    alias scroll_down_mgc_zoom scroll_down
    alias scroll_left_mgc_zoom scroll_left
    alias scroll_right_mgc_zoom scroll_right
    alias scroll_up_mgc_zoom scroll_up
    @already_aliased_mgc_zoom = true
  end
  #--------------------------------------------------------------------------
  # * Setup [1.4]
  #--------------------------------------------------------------------------
  def setup(map_id)
    setup_mgc_tilemap(map_id)
    if use_new_tilemap?
      if MGC.new_tilemap_active
        MGC.start_change_map_new_zoom
      end
      self.start_new_tilemap = true
    else
      self.end_new_tilemap = true
    end
  end
  #--------------------------------------------------------------------------
  # * Get default zoom [1.4]
  #--------------------------------------------------------------------------
  def get_default_zoom
    if $data_mapinfos[@map_id].full_name[/\[Z(\d+(?:\.\d+)*)\]/]
      return [[$1.to_f, 0.125].max, 8.0].min
    else
      return MGC::DEFAULT_ZOOM
    end
  end
  #--------------------------------------------------------------------------
  # * Set Display Position
  #--------------------------------------------------------------------------
  def set_display_pos(x, y)
    if MGC.new_tilemap_active && $game_map.use_new_tilemap? # [1.4]
      if loop_horizontal?
        @display_x = (x + width) % width
      else
        if width * MGC.map_zoom < screen_tile_x
          @display_x = (width - screen_tile_x).abs / 2
        else
          x_min = screen_tile_x * (1.0 / MGC.map_zoom - 1.0) / 2
          x_max = width + screen_tile_x * ((1.0 - 1.0 / MGC.map_zoom) / 2 - 1)
          x = [x_min, [x, x_max].min].max
          @display_x = x
        end
      end
      if loop_vertical?
        @display_y = (y + height) % height
      else
        if height * MGC.map_zoom < screen_tile_y
          @display_y = (height - screen_tile_y).abs / 2
        else
          y_min = screen_tile_y * (1.0 / MGC.map_zoom - 1.0) / 2
          y_max = height + screen_tile_y * ((1.0 - 1.0 / MGC.map_zoom) / 2 - 1)
          y = [y_min, [y, y_max].min].max
          @display_y = y
        end
      end
      @parallax_x = x
      @parallax_y = y
    else
      set_display_pos_mgc_zoom(x, y)
    end
  end
  #--------------------------------------------------------------------------
  # * Scroll Down
  #--------------------------------------------------------------------------
  def scroll_down(distance)
    if MGC.new_tilemap_active # [1.4]
      if loop_vertical?
        @display_y += distance
        @display_y %= @map.height
        @parallax_y += distance if @parallax_loop_y
      else
        last_y = @display_y
        if height * MGC.map_zoom < screen_tile_y
          @display_y = (height - screen_tile_y).abs / 2
        else
          max = height + screen_tile_y * ((1.0 - 1.0 / MGC.map_zoom) / 2 - 1)
          @display_y = [@display_y + distance, max].min
        end
        @parallax_y += @display_y - last_y
      end
    else
      scroll_down_mgc_zoom(distance)
    end
  end
  #--------------------------------------------------------------------------
  # * Scroll Left
  #--------------------------------------------------------------------------
  def scroll_left(distance)
    if MGC.new_tilemap_active # [1.4]
      if loop_horizontal?
        @display_x += @map.width - distance
        @display_x %= @map.width 
        @parallax_x -= distance if @parallax_loop_x
      else
        last_x = @display_x
        if width * MGC.map_zoom < screen_tile_x
          @display_x = (width - screen_tile_x).abs / 2
        else
          min = screen_tile_x * (1.0 / MGC.map_zoom - 1.0) / 2
          @display_x = [@display_x - distance, min].max
        end
        @parallax_x += @display_x - last_x
      end
    else
      scroll_left_mgc_zoom(distance)
    end
  end
  #--------------------------------------------------------------------------
  # * Scroll Right
  #--------------------------------------------------------------------------
  def scroll_right(distance)
    if MGC.new_tilemap_active # [1.4]
      if loop_horizontal?
        @display_x += distance
        @display_x %= @map.width
        @parallax_x += distance if @parallax_loop_x
      else
        last_x = @display_x
        if width * MGC.map_zoom < screen_tile_x
          @display_x = (width - screen_tile_x).abs / 2
        else
          max = width + screen_tile_x * ((1.0 - 1.0 / MGC.map_zoom) / 2 - 1)
          @display_x = [@display_x + distance, max].min
        end
        @parallax_x += @display_x - last_x
      end
    else
      scroll_right_mgc_zoom(distance)
    end
  end
  #--------------------------------------------------------------------------
  # * Scroll Up
  #--------------------------------------------------------------------------
  def scroll_up(distance)
    if MGC.new_tilemap_active # [1.4]
      if loop_vertical?
        @display_y += @map.height - distance
        @display_y %= @map.height
        @parallax_y -= distance if @parallax_loop_y
      else
        last_y = @display_y
        if height * MGC.map_zoom < screen_tile_y
          @display_y = (height - screen_tile_y).abs / 2
        else
          min = screen_tile_y * (1.0 / MGC.map_zoom - 1.0) / 2
          @display_y = [@display_y - distance, min].max
        end
        @parallax_y += @display_y - last_y
      end
    else
      scroll_up_mgc_zoom(distance)
    end
  end
end

#============================================================================
# ** RPG::MapInfo
#============================================================================
class RPG::MapInfo
  # defines the map name as the name without anything within brackets,
  # including brackets
  def name
    return @name.gsub(/\[.*\]/) {''}
  end
  #--------------------------------------------------------------------------
  # the original name with the codes
  def full_name
    return @name
  end
end