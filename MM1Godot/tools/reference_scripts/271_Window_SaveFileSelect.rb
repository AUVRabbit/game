class Window_SaveFileSelect < Window_Base
  include MM_DataBase
  
  def initialize(param_ary)
    super(265, 340, 500, 300)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 235
    @cursor.y = self.y + 15
    @cursor.z = 9999
    @cursor_index = 0
    @param_ary = param_ary
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    for i in 0..1
      self.contents.draw_text(24, 24 * i, 120, 48, i.to_s + ".")
      next if @param_ary[i] == nil
      self.contents.draw_text(50, 24 * i, 120, 48, @param_ary[i])
    end
  end
  
  def visible=(value)
    super
    @cursor.visible = value if @cursor != nil
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def result
    return @cursor_index
  end
  
  def reset
    @cursor_index = 0
  end
  
  def update
    super
    if self.active && self.visible
      if Input.trigger?(Input::DOWN)
        if @cursor_index < 1
          @cursor_index += 1
        end
      end
    
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      @cursor.x = 225 + 10
      @cursor.y = self.y + @cursor_index * 32 + 18
    end
  end
  
end