class Window_ModeData < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(228, 300, 420, 180)
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.visible = false
    @cursor.x = 255 - 12
    @cursor.y = 320
    @cursor.z = 9999
    self.back_opacity = 0
    self.opacity = 0
    self.visible = false
    self.contents = RPG::Cache.picture(PICTURE_MODE_DATA_BACK)
    @cursor_index = 0
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_MODE_DATA_BACK)
    self.contents.draw_text(210, 68, 120, 48, $game_system.moneybell.to_s)
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
  
  def update
    super
    if !self.visible
      return
    end
    if Input.trigger?(Input::DOWN) && self.visible
      if @cursor_index < 2
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP) && self.visible
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
        
    @cursor.x = 255 - 12
    @cursor.y = 320 + @cursor_index * 35
  end
end