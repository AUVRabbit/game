class Window_ItemCommands < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(240, 300, 440, 180)
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.x = self.x + 30
    @sprite_cursor.y = self.y + 20
    @sprite_cursor.z = 9999
    @cursor_index = 0
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    refresh
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def active=(value)
    super
    @sprite_cursor.visible = value
  end
  
  def result
    case @cursor_index
    when 0
      return ITEMCOMMAND_USE
    when 1
      return ITEMCOMMAND_PASS
    when 2
      return ITEMCOMMAND_DROP
    end
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    
    self.contents.draw_text(56, 0, 64, 48, "使")
    self.contents.draw_text(56, 28, 64, 48, "给")
    self.contents.draw_text(56, 56, 64, 48, "扔")
  end
  
  def update
    if self.active
      if Input.trigger?(Input::UP)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 1 if @cursor_index < 2
      end
      
      @sprite_cursor.y = self.y + 20 if @cursor_index == 0
      @sprite_cursor.y = self.y + 48 if @cursor_index == 1
      @sprite_cursor.y = self.y + 76 if @cursor_index == 2
    end
  end
end