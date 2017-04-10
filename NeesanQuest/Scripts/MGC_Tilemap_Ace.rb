#====================================================================
# MGC Tilemap Ace
# v.1.4
# Auteur : MGC
#
# Il s'agit d'une reecriture de la classe Tilemap pour RMVX Ace.
#
# - Ne gere pas le flash_data
# - Ne gere pas le decalage des motifs d'autotiles du tiles du
#   tileset A2 avec l'indicateur "counter"
# - Gere le reste, et meme d'autres proprietes/methodes empruntees
#   a la classe Sprite :
#         - opacity
#         - blend_type
#         - color
#         - tone
#         - wave_amp
#         - wave_length
#         - wave_speed
#         - wave_phase
#         - zoom
#         - flash
# - Ajout d'une methode to_zoom(new_zoom, duration) pour un zoom
#   progressif
#
# Necessite :
# - le fichier MGC_Map_Ace_1_6.dll a la racine du projet
# - les 3 fichiers graphiques suivants, deposes dans Pictures/ :
#         - autotiles_data.png
#         - autotiles_data_small.png
#         - autotiles_data_xsmall.png
#
# Configuration :
# - NEW_TILEMAP_FOR_ALL_MAPS : alimente a true ou false
#         - true : la nouvelle Tilemap sera utilisee pour toutes les cartes
#         - false : la nouvelle Tilemap ne sera utilisee que pour les
#                   cartes dont l'id est dans NEW_TILEMAP_MAPS_IDS
# - NEW_TILEMAP_MAPS_IDS : utilise si NEW_TILEMAP_FOR_ALL_MAPS est a false
#         Contient la liste des id des cartes pour lesquelles la nouvelle
#         tilemap doit etre utilisee
#====================================================================
module MGC
  #--------------------------------------------------------------------------
  # * CONFIGURATION
  #--------------------------------------------------------------------------
  NEW_TILEMAP_FOR_ALL_MAPS = true
  NEW_TILEMAP_MAPS_IDS = [1, 2] # seules les cartes 1 et 2 utilisent cette tilemap
  #--------------------------------------------------------------------------
  # * Initialisation [1.2]
  #--------------------------------------------------------------------------
  @new_tilemap_active = false
  #--------------------------------------------------------------------------
  # * Lancement de la nouvelle tilemap [1.2]
  #--------------------------------------------------------------------------
  def self.start_new_tilemap
    @end_new_tilemap = false
    @spriteset.start_new_tilemap
  end
  #--------------------------------------------------------------------------
  # * Fin de la nouvelle tilemap [1.2]
  #--------------------------------------------------------------------------
  def self.end_new_tilemap
    @end_new_tilemap = true
  end
  #--------------------------------------------------------------------------
  # * Setter pour l'attribut new_tilemap_active [1.2]
  #--------------------------------------------------------------------------
  def self.new_tilemap_active=(flag)
    $game_system.new_tilemap_active = flag
    @new_tilemap_active = flag
  end
  #--------------------------------------------------------------------------
  # * Getter pour l'attribut new_tilemap_active [1.2]
  #--------------------------------------------------------------------------
  def self.new_tilemap_active
    return @new_tilemap_active
  end
  #--------------------------------------------------------------------------
  # * Mise a jour de la nouvelle tilemap [1.2]
  #--------------------------------------------------------------------------
  def self.update_new_tilemap
    if @new_tilemap_active && @end_new_tilemap
      @spriteset.end_new_tilemap
      @end_new_tilemap = false
    end
  end
  #--------------------------------------------------------------------------
  # * Verifie si un effet est en cours [1.2]
  #--------------------------------------------------------------------------
  def self.new_tilemap_effect?
    return @new_tilemap_active && @end_new_tilemap
  end
  #==============================================================================
  # ** MGC::Tilemap
  #==============================================================================
  class Tilemap
    #--------------------------------------------------------------------------
    # * Attributs
    #--------------------------------------------------------------------------
    attr_reader :viewport, :visible, :ox, :oy, :opacity, :blend_type, :color,
    :tone, :wave_amp, :wave_length, :wave_speed, :wave_phase, :zoom, :map_data,
    :flags
    attr_accessor :flash_data
    attr_writer :bitmaps # [1.2]
    #--------------------------------------------------------------------------
    # * Constantes
    #--------------------------------------------------------------------------
    RENDER = Win32API.new("MGC_Map_Ace_1_6", "renderMap", "l", "l")
    #--------------------------------------------------------------------------
    # * Initialisation
    #--------------------------------------------------------------------------
    def initialize(viewport)
      @viewport = viewport
      self.bitmaps = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      @map_data = 0
      @flags = 0
      self.flash_data = nil
      @cx = Graphics.width >> 1
      @cy = Graphics.height >> 1
      @sprite_render = Sprite.new(viewport)
      @render = Bitmap.new(Graphics.width + 64, Graphics.height + 64)
      @sprite_render.bitmap = @render
      @sprite_render.x = -32
      @sprite_render.y = -32
      @sprite_render.z = 0
      @sprite_render_layer2 = Sprite.new(viewport)
      @render_layer2 = Bitmap.new(Graphics.width + 64, Graphics.height + 64)
      @sprite_render_layer2.bitmap = @render_layer2
      @sprite_render_layer2.x = -32
      @sprite_render_layer2.y = -32
      @sprite_render_layer2.z = 200
      @zoom_incr = 0.0
      @zoom_duration = 0
      @parameters = [@render, @render_layer2, map_data, bitmaps,
      Cache.picture('autotiles_data'), Cache.picture('autotiles_data_small'),
      Cache.picture('autotiles_data_xsmall'), flags, 0, 0, 0, 0, 0, 0, 1024,
      100, $game_map.loop_horizontal?, $game_map.loop_vertical?]
      self.visible = true
      self.zoom = 1.0
      self.ox = 0
      self.oy = 0
      self.opacity = 255
      self.blend_type = 0
      self.color = Color.new
      self.tone = Tone.new
      self.wave_amp = 0
      self.wave_length = 180
      self.wave_speed = 360
      self.wave_phase = 0.0
      @refresh_all = true
    end
    #--------------------------------------------------------------------------
    # * Getter pour l'attribut bitmaps # [1.2]
    #--------------------------------------------------------------------------
    def bitmaps
      force_refresh
      return @bitmaps
    end
    #--------------------------------------------------------------------------
    # * Force le rafraichissement de la tilemap # [1.2]
    #--------------------------------------------------------------------------
    def force_refresh
      @need_refresh = true # [1.2]
      @refresh_all = true # [1.2]
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut map_data
    #--------------------------------------------------------------------------
    def map_data=(new_map_data)
      @map_data = new_map_data
      @parameters[2] = @map_data
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut flags
    #--------------------------------------------------------------------------
    def flags=(new_flags)
      @flags = new_flags
      @parameters[7] = @flags
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut zoom
    #--------------------------------------------------------------------------
    def zoom=(new_zoom)
      unless zoom == new_zoom
        if new_zoom < 0.125 || new_zoom > 8.0 then return end
        @zoom = new_zoom
        @parameters[14] = (1024.0 / new_zoom).to_i
        vox = @ox
        @ox = nil
        self.ox = vox
        voy = @oy
        @oy = nil
        self.oy = voy
        @need_refresh = true
        @refresh_all = true
      end
    end
    #--------------------------------------------------------------------------
    # * Incrementation de la valeur du zoom
    #--------------------------------------------------------------------------
    def incr_zoom(val = 0.02)
      @zoom_incr += val
      new_zoom = 2 ** @zoom_incr
      self.zoom = new_zoom
    end
    #--------------------------------------------------------------------------
    # * Pour aller progressivement vers une nouvelle valeur de zoom
    #--------------------------------------------------------------------------
    def to_zoom(new_zoom, duration)
      unless zoom == new_zoom
        if new_zoom < 0.125 || new_zoom > 8.0 then return end
        @zoom_duration = duration
        target_zoom_incr = Math.log(new_zoom) / Math.log(2)
        @zoom_step = (target_zoom_incr - @zoom_incr) / duration
        @target_zoom = new_zoom
      end
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut visible
    #--------------------------------------------------------------------------
    def shadow_opacity=(value)
      @parameters[15] = [[value, 0].max, 255].min
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut visible
    #--------------------------------------------------------------------------
    def visible=(flag)
      @visible = flag
      @sprite_render.visible = flag
      @sprite_render_layer2.visible = flag
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut ox
    #--------------------------------------------------------------------------
    def ox=(new_ox)
      @parameters[12] = 0
      unless new_ox == @ox
        if ox && $game_map.loop_horizontal?
          if (new_ox.to_i - ox >> 5) == $game_map.width - 1 ||
            (ox - new_ox.to_i >> 5) == $game_map.width - 1
          then
            @refresh_all = true
          end
        end
        @ox = new_ox.to_i
        ox_zoom = (@ox << 10) / @parameters[14]
        ox_floor = ox_zoom >> 5 << 5
        unless ox_floor == @parameters[8]
          @parameters[12] = ox_floor - @parameters[8] >> 5
          @need_refresh = true
        end
        @parameters[8] = ox_floor
        @sprite_render.ox = ox_zoom - ox_floor
        @sprite_render_layer2.ox = @sprite_render.ox
      end
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut oy
    #--------------------------------------------------------------------------
    def oy=(new_oy)
      @parameters[13] = 0
      unless new_oy == @oy
        if oy && $game_map.loop_vertical?
          if (new_oy.to_i - oy >> 5) == $game_map.height - 1 ||
            (oy - new_oy.to_i >> 5) == $game_map.height - 1
          then
            @refresh_all = true
          end
        end
        @oy = new_oy.to_i
        oy_zoom = (@oy << 10) / @parameters[14]
        oy_floor = oy_zoom >> 5 << 5
        unless oy_floor == @parameters[9]
          @parameters[13] = oy_floor - @parameters[9] >> 5
          @need_refresh = true
        end
        @parameters[9] = oy_floor
        @sprite_render.oy = oy_zoom - oy_floor
        @sprite_render_layer2.oy = @sprite_render.oy
      end
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut opacity
    #--------------------------------------------------------------------------
    def opacity=(new_opacity)
      @opacity = new_opacity
      @sprite_render.opacity = new_opacity
      @sprite_render_layer2.opacity = new_opacity
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut blend_type
    #--------------------------------------------------------------------------
    def blend_type=(new_blend_type)
      @blend_type = new_blend_type
      @sprite_render.blend_type = new_blend_type
      @sprite_render_layer2.blend_type = new_blend_type
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut color
    #--------------------------------------------------------------------------
    def color=(new_color)
      @color = new_color
      @sprite_render.color = new_color
      @sprite_render_layer2.color = new_color
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut tone
    #--------------------------------------------------------------------------
    def tone=(new_tone)
      @tone = new_tone
      @sprite_render.tone = new_tone
      @sprite_render_layer2.tone = new_tone
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut wave_amp
    #--------------------------------------------------------------------------
    def wave_amp=(new_wave_amp)
      @wave_amp = new_wave_amp
      @sprite_render.wave_amp = new_wave_amp
      @sprite_render_layer2.wave_amp = new_wave_amp
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut wave_length
    #--------------------------------------------------------------------------
    def wave_length=(new_wave_length)
      @wave_length = new_wave_length
      @sprite_render.wave_length = new_wave_length
      @sprite_render_layer2.wave_length = new_wave_length
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut wave_speed
    #--------------------------------------------------------------------------
    def wave_speed=(new_wave_speed)
      @wave_speed = new_wave_speed
      @sprite_render.wave_speed = new_wave_speed
      @sprite_render_layer2.wave_speed = new_wave_speed
    end
    #--------------------------------------------------------------------------
    # * Setter pour l'attribut wave_phase
    #--------------------------------------------------------------------------
    def wave_phase=(new_wave_phase)
      @wave_phase = new_wave_phase
      @sprite_render.wave_phase = new_wave_phase
      @sprite_render_layer2.wave_phase = new_wave_phase
    end
    #--------------------------------------------------------------------------
    # * Liberation de l'instance
    #--------------------------------------------------------------------------
    def dispose
      @render.dispose
      @render_layer2.dispose
      @sprite_render.dispose
      @sprite_render_layer2.dispose
    end
    #--------------------------------------------------------------------------
    # * Retourne true si l'instance a ete liberee
    #--------------------------------------------------------------------------
    def disposed?
      return @render.disposed?
    end
    #--------------------------------------------------------------------------
    # * Mise a jour, appelee normalement a chaque frame
    #--------------------------------------------------------------------------
    def update
      if @visible
        if @zoom_duration > 0
          @zoom_duration -= 1
          if @zoom_duration == 0
            self.zoom = @target_zoom
          else
            incr_zoom(@zoom_step)
          end
        end
        if Graphics.frame_count & 31 == 0
          @parameters[10] += 1
          @parameters[10] %= 3
          unless @need_refresh
            @need_refresh_anim = true
          end
        end
        if @need_refresh
          if @refresh_all
            @render.clear
            @render_layer2.clear
            @parameters[12] = 0
            @parameters[13] = 0
            @refresh_all = false
          end
          @parameters[11] = 0
          RENDER.call(@parameters.__id__)
          @need_refresh = false
        elsif @need_refresh_anim
          @parameters[11] = 1
          @parameters[12] = 0
          @parameters[13] = 0
          RENDER.call(@parameters.__id__)
          @need_refresh_anim = false
        end
        @sprite_render.update
        @sprite_render_layer2.update
      end
    end
    #--------------------------------------------------------------------------
    # * Flash des couches de la tilemap
    #--------------------------------------------------------------------------
    def flash(color, duration)
      @sprite_render.flash(color, duration)
      @sprite_render_layer2.flash(color, duration)
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
  unless @already_aliased_mgc_tilemap
    alias create_tilemap_mgc_tilemap create_tilemap
    alias update_mgc_tilemap update # [1.2]
    @already_aliased_mgc_tilemap = true
  end
  #--------------------------------------------------------------------------
  # * Create Tilemap [1.2]-MOD
  #--------------------------------------------------------------------------
  def create_tilemap
    create_tilemap_mgc_tilemap
    unless $game_system.new_tilemap_active
      MGC.new_tilemap_active = false
    end
    if $game_map.use_new_tilemap? || $game_system.new_tilemap_active
      start_new_tilemap
    end
  end
  #--------------------------------------------------------------------------
  # * Active la nouvelle tilemap [1.2]
  #--------------------------------------------------------------------------
  def start_new_tilemap
    unless @tilemap_new
      @tilemap_classic = @tilemap
      @tilemap_new = MGC::Tilemap.new(@viewport1)
      @tilemap_new.map_data = $game_map.data
      @tilemap_new.force_refresh
      @tilemap = @tilemap_new
      load_tileset
    end
    @tilemap_new.visible = true
    @tilemap_classic.visible = false
    @tilemap = @tilemap_new
    MGC.new_tilemap_active = true
    $game_player.center($game_player.x, $game_player.y)
  end
  #--------------------------------------------------------------------------
  # * Desactive la nouvelle tilemap [1.2]
  #--------------------------------------------------------------------------
  def end_new_tilemap
    if @tilemap_new
      @tilemap_new.visible = false
      @tilemap_classic.visible = true
      @tilemap = @tilemap_classic
      load_tileset
    end
    MGC.new_tilemap_active = false
  end
  #--------------------------------------------------------------------------
  # * Update [1.2]
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
    update_mgc_tilemap
  end
end

#==============================================================================
# ** Game_System [1.2]
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # * Attributs
  #--------------------------------------------------------------------------
  attr_accessor :new_tilemap_active
end

#==============================================================================
# ** Game_Map [1.2]
#==============================================================================
class Game_Map
  attr_accessor :start_new_tilemap, :end_new_tilemap
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_tilemap
    alias setup_mgc_tilemap setup
    @already_aliased_mgc_tilemap = true
  end
  #--------------------------------------------------------------------------
  # * Setup
  #--------------------------------------------------------------------------
  def setup(map_id)
    setup_mgc_tilemap(map_id)
    if use_new_tilemap?
      self.start_new_tilemap = true
    else
      self.end_new_tilemap = true
    end
  end
  #--------------------------------------------------------------------------
  # * Check if the map is configured for the new tilemap
  #--------------------------------------------------------------------------
  def use_new_tilemap?
    return MGC::NEW_TILEMAP_FOR_ALL_MAPS ||
    MGC::NEW_TILEMAP_MAPS_IDS.include?($game_map.map_id)
  end
end

#==============================================================================
# ** Scene_Map [1.2]
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Aliased methods
  #--------------------------------------------------------------------------
  unless @already_aliased_mgc_tilemap
    alias update_call_menu_mgc_tilemap update_call_menu
    @already_aliased_mgc_tilemap = true
  end
  #--------------------------------------------------------------------------
  # * Determine if Menu is Called due to Cancel Button
  #--------------------------------------------------------------------------
  def update_call_menu
    unless MGC.new_tilemap_effect?
      update_call_menu_mgc_tilemap
    end
  end
end