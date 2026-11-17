class Window_BattleEquip < Window_Base
  
  attr_reader :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize(obj)
    super(240, 300, 440, 180)
    self.back_opacity = 0
    self.opacity = 0
    @obj = obj
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 250
    @cursor.y = 320 + 20
    @cursor.z = 9999
    @cursor_index = 0
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
  
  def active=(value)
    super
    @cursor.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    
    for i in 0...@obj.equipments.size
      equipment = @obj.equipments[i]
      x = 40 + i % 2 * 130
      y = -10 + i / 2 * 24 + 20
      self.contents.draw_text(x, y, 120, 64, equipment.name)
    end
  end
    
  def refresh_obj(obj)
    @cursor_index = 0
    @obj = obj
    refresh
  end
  
  def update
    super
    if self.active
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < @obj.equipments.size - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < @obj.equipments.size
      end
            
      @cursor.x = 250 + @cursor_index % 2 * 130
      @cursor.y = 320 + @cursor_index / 2 * 24 + 20
      return
    end
  end
end