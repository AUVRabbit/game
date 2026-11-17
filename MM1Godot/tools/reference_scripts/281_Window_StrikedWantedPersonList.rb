class Window_StrikedWantedPersonList < Window_Base
  include MM_DataBase
  
  def initialize
    super(60, 48, 540, 320)
    self.back_opacity = 0
    self.opacity = 0
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_STRIKEDWANTEDPERSONLIST_BACK)
    @sprite_back.z = 8002
    refresh
  end
  
  def visible=(value)
    super
    @sprite_back.visible = value if @sprite_back != nil
  end
  
  def dispose
    super
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.cotnents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    keys = DATA_ENEMY_BOSS.keys
    keys.sort!
    self.contents.font.size = 25
    for i in 0...keys.size
      if $game_map.wanted_persons[keys[i]][1] == true
        y = i * 48
        self.contents.draw_text(18, y, 240, 48, i.to_s)
        self.contents.draw_text(48, y, 240, 48, $data_enemies[keys[i]].name)
        self.contents.draw_text(308, y, 240, 48, $game_map.wanted_persons[keys[i]][3].to_s)
        if $game_map.wanted_persons[keys[i]][2] == true
          self.contents.draw_text(394, y, 240, 48, $game_map.wanted_persons[keys[i]][0].to_s + "G")
        end
      end
    end
  end
  
end