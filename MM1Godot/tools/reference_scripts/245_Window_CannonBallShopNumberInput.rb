class Window_CannonBallShopNumberInput < Window_Base
  
  include MM_DataBase
  
  def initialize
    super(260, 300, 440, 200)
    self.opacity = 0
    self.back_opacity = 0
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_CANNONBALLSHOP_NUMBERINPUT)
    @back.x = self.x
    @back.y = self.y + 20
    @back.z = 8003
    @tank = nil
    @equipment = nil
    @cannonball = nil
    @type = nil
  end
  
  def dispose
    super
    @back.bitmap.dispose
    @back.dispose
    @number_window.dispose if @number_window != nil
  end
  
  def visible=(value)
    super
    @back.visible = value
    @number_window.visible = value if @number_window != nil
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(150, 0, 120, 48,\
      (@equipment.quantity - @equipment.quantity_reality).to_s)
    self.contents.draw_text(240, 55, 120, 48,\
      (@equipment.quantity - @equipment.quantity_reality).to_s)
  end
  
  def refresh_tank(equipment, type)
    @tank = nil
    @equipment = equipment
    @type = type
    @cannonball = nil
    refresh
  end
  
  def refresh_tank_special(tank, type)
    @tank = tank
    @cannonball = nil
    @type = type
    @equipment = nil
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(150, 0, 120, 48,\
      (tank.underpan.special_cannonball_capacity - tank.underpan.special_cannonball_relity_capacity).to_s)
    self.contents.draw_text(240, 55, 120, 48,\
      (tank.underpan.special_cannonball_capacity - tank.underpan.special_cannonball_relity_capacity).to_s)
  end
  
  def refresh_sell(tank, cannonball, type)
    @tank = tank
    @cannonball = cannonball
    @equipment = nil
    @type = type
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(150, 0, 120, 48,\
      (tank.underpan.special_cannonball[cannonball]).to_s)
    self.contents.draw_text(240, 55, 120, 48,\
      (tank.underpan.special_cannonball[cannonball]).to_s)
  end
  
  def number
    return @number_window == nil ? 0 : @number_window.number
  end
  
  def set_number_window(num)
    @number_window.dispose if @number_window != nil
    @number_window = Window_InputNumber.new(num)
    @number_window.x = 370
    @number_window.y = 360
  end
  
  def update
    super
    @number_window.update if @number_window != nil
    
    case @type
    when CANNONBALLDRAWTYPE_BUYSPECIAL
      @number_window.number = [@number_window.number, @tank.underpan.special_cannonball_capacity - @tank.underpan.special_cannonball_relity_capacity].min if @number_window != nil
    when CANNONBALLDRAWTYPE_SELL
      @number_window.number = [@number_window.number, @tank.underpan.special_cannonball[@cannonball]].min if @number_window != nil
    when CANNONBALLDRAWTYPE_BUYNORMAL
      @number_window.number = [@number_window.number, @equipment.quantity - @equipment.quantity_reality].min if @number_window != nil
    end
      
  end
end