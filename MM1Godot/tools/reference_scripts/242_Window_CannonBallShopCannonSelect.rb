class Window_CannonBallShopCannonSelect < Window_Base
  
  include MM_DataBase
  
  def initialize
    super(0, 0, 640, 320)
    self.opacity = 0
    self.back_opacity = 0
    @cursor_index = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 40
    @cursor.y = 30
    @cursor.z = 9999
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_CANNONBALLSHOP_CANNONSELECT)
    @back.x = 0
    @back.y = 0
    @back.z = 8003
    @tank = nil
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
    @back.bitmap.dispose
    @back.dispose
  end
  
  def visible=(value)
    super
    @cursor.visible = value
    @back.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    @cannonballposition = []
    count = 0
    if @tank.main_cannon != nil
      @cannonballposition.push(CANNONBALLPOSITION_MAIN_CANNON)
      self.contents.draw_text(40 + 40, count * 32, 120, 48, "主炮")
      self.contents.draw_text(150 + 40, count * 32, 120, 48, ".." + @tank.main_cannon.name)
      self.contents.draw_text(240 + 100, count * 32, 120, 48, "..")
      self.contents.draw_text(320 + 60, count * 32, 120, 48,\
        @tank.main_cannon.limited_quantity?\
        ? @tank.main_cannon.quantity_reality.to_s + "/" + @tank.main_cannon.quantity.to_s\
        : "……")
      count += 1
    end
    if @tank.sub_cannon != nil
      @cannonballposition.push(CANNONBALLPOSITION_SUB_CANNON)
      self.contents.draw_text(40 + 40, count * 32, 120, 48, "副炮")
      self.contents.draw_text(150 + 40, count * 32, 120, 48, ".." + @tank.sub_cannon.name)
      self.contents.draw_text(240 + 100, count * 32, 120, 48, "..")
      self.contents.draw_text(320 + 60, count * 32, 120, 48,\
        @tank.sub_cannon.limited_quantity?\
        ? @tank.sub_cannon.quantity_reality.to_s + "/" + @tank.sub_cannon.quantity.to_s\
        : "……")
      count += 1
    end
    if @tank.se != nil
      @cannonballposition.push(CANNONBALLPOSITION_SE)
      self.contents.draw_text(40 + 40, count * 32, 120, 48, "SE")
      self.contents.draw_text(150 + 40, count * 32, 120, 48, ".." + @tank.se.name)
      self.contents.draw_text(240 + 100, count * 32, 120, 48, "..")
      self.contents.draw_text(320 + 60, count * 32, 120, 48,\
        @tank.se.limited_quantity?\
        ? @tank.se.quantity_reality.to_s + "/" + @tank.se.quantity.to_s\
        : "……")
      count += 1
    end
  end
  
  def reset
    @cursor_index = 0
  end
  
  def get_part
    return @cannonballposition[@cursor_index]    
  end
  
  def refresh_tank(tank)
    @tank = tank
    refresh
  end
  
  def update
    super
    if self.visible && self.active
      if Input.trigger?(Input::DOWN)
        if @cursor_index < @cannonballposition.size - 1
          @cursor_index += 1
        end
      end
      
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      @cursor.x = 40
      @cursor.y = 30 + @cursor_index * 32
    end    
  end
end