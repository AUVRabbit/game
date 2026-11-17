class Window_SupplyShopArmourSelection < Window_Base
  include MM_DataBase
  
  def initialize
    super(225, 10, 500, 300)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 235
    @cursor.y = self.y + 15
    @cursor.z = 9999
    self.contents = RPG::Cache.picture(PICTURE_SUPPLYSHOP_ARMOURSUPPLYBACK)
    @cursor_index = 0
    @tank = nil
  end
  
  def visible=(value)
    super
    @cursor.visible = value if @cursor != nil
  end
  
  def refresh_tank(tank)
    @tank = tank
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_SUPPLYSHOP_ARMOURSUPPLYBACK)
    self.contents.draw_text(280, 0, 120, 48, (@tank.maxhp - @tank.hp).to_i.to_s)
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
      @cursor.y = self.y + (@cursor_index + 1)* 32 + 15
    end
  end
end