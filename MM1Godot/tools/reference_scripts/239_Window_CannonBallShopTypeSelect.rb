class Window_CannonBallShopTypeSelect < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(225, 15, 640, 200)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 235
    @cursor.y = 35
    @cursor.z = 9999
    self.contents = RPG::Cache.picture(PICTURE_CANNONBALLSHOP_CANNONBALLTYPESELECT)
    @cursor_index = 0
  end
  
  def visible=(value)
    super
    @cursor.visible = value
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
    if self.visible
      if Input.trigger?(Input::DOWN)
        if @cursor_index < 2
          @cursor_index += 1
        end
      end
      
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      @cursor.x = 235
      @cursor.y = 35 + @cursor_index * 32
    end
  end
end