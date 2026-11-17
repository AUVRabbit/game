class Window_BattleTankCommand < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(0, 320, 640, 160)
    self.back_opacity = 0
    self.opacity = 0
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_BATTLE_TANK_BACK)
    @back.z = 8002
    @back.x = 0
    @back.y = 320
    @cursor_index = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = self.x + 8
    @cursor.y = self.y + 48
    @cursor.z = 9999     
    self.contents = Bitmap.new(height - 32, width - 32)
  end
  
  def set_text(text)
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(height - 32, width - 32)
    self.contents.draw_text(30, 0, 128, 32, text)
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
    @back.bitmap.dispose
    @back.dispose
  end
  
  def visible=(value)
    super
    @cursor.visible = value
    @back.visible = value
  end
  
  def update
    if !self.visible
      return
    end
    
    if Input.trigger?(Input::LEFT)
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
    
    if Input.trigger?(Input::RIGHT)
      if @cursor_index < 5
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP)
      if @cursor_index >= 2
        @cursor_index -= 2
      end
    end
    
    if Input.trigger?(Input::DOWN)
      if @cursor_index < 4
        @cursor_index += 2
      end
    end
    
    @cursor.x = (@cursor_index % 2) * 98 + self.x + 8
    @cursor.y = (@cursor_index / 2) * 32 + self.y + 48
  end
end