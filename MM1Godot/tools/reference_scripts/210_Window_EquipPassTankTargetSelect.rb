class Window_EquipPassTankTargetSelect < Window_Selectable
  
  include MM_System
  include MM_DataBase
  
  attr_accessor :cursor
  attr_reader   :tank_index
  
  def initialize
    super(228, 300, 420, 180)
    self.active = false
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.visible = false
    @cursor.x = 255 - 12
    @cursor.y = 320
    @cursor.z = 9999
    self.back_opacity = 0
    self.opacity = 0
    self.visible = false
    @tank_index = 0
    refresh
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def visible=(value)
    super
    @cursor.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    self.contents = RPG::Cache.picture(PICTURE_BACKUP_DROP_SELECT)
    
    for i in 0...$game_party.tanks.size
      tank = $game_party.tanks[i]
      self.contents.draw_text(50, 30 * i, 120, 48, tank.name)
    end
  end
  
  def update
    super
    if !self.visible
      return
    end
    if Input.trigger?(Input::DOWN) && self.visible
      if @tank_index < $game_party.tanks.size - 1
        @tank_index += 1
      end
    end
    
    if Input.trigger?(Input::UP) && self.visible
      if @tank_index > 0
        @tank_index -= 1
      end
    end
    
    @cursor.x = 255 - 12
    @cursor.y = 320 + @tank_index * 30
  end
end