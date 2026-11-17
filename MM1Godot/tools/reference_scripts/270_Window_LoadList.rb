class Window_LoadList < Window_Base
  
  include MM_DataBase
  
  def initialize(param_ary)
    super(105, 100, 500, 300)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 120
    @cursor.y = self.y + 25
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
    for i in 0...@param_ary.size
      next if @param_ary[i] == nil
      self.contents.draw_text(120, 52 * i + 5, 120, 48, @param_ary[i][0])
      self.contents.draw_text(320, 52 * i + 5, 120, 48, @param_ary[i][1].to_s)
    end
  end
  
  def visible=(value)
    super
    @cursor.visible = value if @cursor != nil
  end
  
  def refresh_param(param_ary)
    @param_ary = param_ary
    refresh
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
      
      @cursor.x = 120
      @cursor.y = self.y + @cursor_index * 64 + 25
    end
  end
  
end