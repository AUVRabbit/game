class Window_CannonBallShopCommand < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(225, 10, 500, 300)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 225 + 10
    @cursor.y = 20 + 10
    @cursor.z = 9999
    self.contents = RPG::Cache.picture(PICTURE_CANNONBALLSHOP_COMMAND)
    @cursor_index = 0
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
  
  def result
    return @cursor_index
  end
  
  def reset
    @cursor_index = 0
  end
  
  def update
    super
    if self.visible && self.active
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
      
      @cursor.x = 225 + 10
      @cursor.y = 20 + @cursor_index * 32 + 10
    end
  end
end