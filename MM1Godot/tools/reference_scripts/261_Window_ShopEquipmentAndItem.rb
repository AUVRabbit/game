class Window_ShopEquipmentAndItem < Window_Base
  include MM_DataBase
  
  attr_reader :corsor_index
  
  def initialize
    super(0, 0, 440, 380)
    self.opacity = 0
    self.back_opacity = 0
    @wanted_list = $game_temp.wanted_list
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 24
    @cursor.y = self.y + 54
    @cursor.z = 9999
    self.contents = RPG::Cache.picture(PICTURE_SHOP_EQUIPMENTANDITEM)
    @cursor_index = 0
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
      
      @cursor.x = 24
      @cursor.y = self.y + @cursor_index * 32 + 54
    end
  end
end