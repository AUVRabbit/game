class Game_Map
  
  include MM_DataBase
  
  attr_accessor :tanks_position
  attr_accessor :wanted_persons
  
  alias :old_initialize :initialize
  def initialize
    old_initialize
    @tanks_position = DATA_INITIALIZE_TANKPOSITION
    @wanted_persons = {}
    keys = DATA_ENEMY_BOSS.keys.sort
    for i in keys
      #                                            擊破   領賞  等級
      @wanted_persons[i] = [DATA_ENEMY_BOSS[i], false, false, 1]
    end
  end
  
  def wanted_person_strike(wanted_id, level)
    @wanted_persons[wanted_id][1] = true
    @wanted_persons[wanted_id][3] = level
  end
  
  def wanted_person_award(wanted_id)
    @wanted_persons[wanted_id][2] = true
  end
  
  def wanted_person_striked?(wanted_id)
    return @wanted_persons[wanted_id][1] == true
  end
  
  def wanted_person_awarded?(wanted_id)
    return @wanted_persons[wanted_id][2] == true
  end
  
  #--------------------------------------------------------------------------
  # ● 设置
  #     map_id : 地图 ID
  #--------------------------------------------------------------------------
  def setup(map_id)
    # 地图 ID 记录到 @map_id 
    @map_id = map_id
    # 地图文件装载后、设置到 @map 
    #@map = load_data(sprintf("Data/Map%03d.rxdata", @map_id))
    @map = $game_maps[map_id]
    # 定义实例变量设置地图元件信息
    tileset = $data_tilesets[@map.tileset_id]
    @tileset_name = tileset.tileset_name
    @autotile_names = tileset.autotile_names
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @fog_name = tileset.fog_name
    @fog_hue = tileset.fog_hue
    @fog_opacity = tileset.fog_opacity
    @fog_blend_type = tileset.fog_blend_type
    @fog_zoom = tileset.fog_zoom
    @fog_sx = tileset.fog_sx
    @fog_sy = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    # 初始化显示坐标
    @display_x = 0
    @display_y = 0
    # 清除刷新要求标志
    @need_refresh = false
    # 设置地图事件数据
    @events = {}
    for i in @map.events.keys
      @events[i] = Game_Event.new(@map_id, @map.events[i])
    end
    # 设置公共事件数据
    @common_events = {}
    for i in 1...$data_common_events.size
      @common_events[i] = Game_CommonEvent.new(i)
    end
    # 初始化雾的各种信息
    @fog_ox = 0
    @fog_oy = 0
    @fog_tone = Tone.new(0, 0, 0, 0)
    @fog_tone_target = Tone.new(0, 0, 0, 0)
    @fog_tone_duration = 0
    @fog_opacity_duration = 0
    @fog_opacity_target = 0
    # 初始化滚动信息
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
  end
  
  #--------------------------------------------------------------------------
  # ● 添加事件
  #--------------------------------------------------------------------------
  def add_event(x,y,name,character_name,tank_event_id, direction, through = false)
    id = tank_event_id
    @events[id] = Game_Event.new(@map_id,set_event(x,y,name.to_s,character_name,id,through)) 
    @events[id].direction = direction
    @map.events[id] = set_event(x,y,name,character_name,id,through)
    event = $game_maps[@map_id]
    event.events[id] = set_event(x,y,name,character_name,id,through)
    $game_maps.save(@map_id,event)
    $scene.reload_spriteset
  end

  #--------------------------------------------------------------------------
  # ● 删除事件
  #--------------------------------------------------------------------------
  def delete_event(id)
    @map.events.delete(id)
    @events.delete(id)
    map = $game_maps[@map_id]
    map.events.delete(id)
    $game_maps.save(@map_id, map)
    $scene.reload_spriteset
  end  
  
  #--------------------------------------------------------------------------
  # ● 设置事件(RPG::Event对象)
  #--------------------------------------------------------------------------
  def set_event(x,y,name,character_name,event_id,through = false)
     e = RPG::Event.new(x,y)
     e.id = event_id
     e.name = name
     e.pages = [RPG::Event::Page.new]   
     e.pages[0].graphic = RPG::Event::Page::Graphic.new
     e.pages[0].graphic.character_name = character_name
     e.pages[0].through = through
     return e
  end
end