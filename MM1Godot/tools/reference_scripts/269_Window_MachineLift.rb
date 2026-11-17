class Window_MachineLift < Window_Base
  
  include MM_DataBase
  
  def initialize(floor_count)
    @floor_count = floor_count
    super(20, 100, 120, 60 * @floor_count)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 24
    @cursor.y = self.y + 27
    @cursor.z = 9999
    @cursor_index = 0
    refresh
  end
  
  def result
    return @cursor_index + 1
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    blt = RPG::Cache.picture(PICTURE_MACHINE_LIFTTABLE)
    width = 99
    height = 50 * @floor_count + @floor_count + 1
    x = 0
    y = 308 - height
    rect = Rect.new(x, y, width, height)
    self.contents.blt(0, 0, blt, rect)
  end
  
  def update
    if Input.trigger?(Input::DOWN)
      if @cursor_index < @floor_count - 1
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP)
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
    @cursor. y = self.y + 27 + 50 * @cursor_index
  end
end