class Window_YesOrNo < Window_Base
  
  include MM_System
  include MM_DataBase
  
  def initialize
    super(260, 380, 440, 100)
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.x = self.x + 30
    @sprite_cursor.y = self.y + 20
    @sprite_cursor.z = 9999
    @cursor_index = 0
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    self.z = 9999
    refresh
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def result
    return @cursor_index == RESULT_YES ? RESULT_YES : RESULT_NO
  end
  
  def visible=(value)
    super
    @sprite_cursor.visible = value
  end
  
  def refresh
    self.contents.draw_text(50, 0, 64, 48, "是")
    self.contents.draw_text(200, 0, 64, 48, "否")
  end
  
  def update
    if self.visible
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index == 1
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index == 0
      end
      
      @sprite_cursor.x = self.x + 30 if @cursor_index == 0
      @sprite_cursor.x = self.x + 180 if @cursor_index == 1
    end
  end
end