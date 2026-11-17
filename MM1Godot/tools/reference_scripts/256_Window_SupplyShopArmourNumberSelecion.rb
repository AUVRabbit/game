class Window_SupplyShopArmourNumberSelecion < Window_Base
  include MM_DataBase
  
  def initialize
    super(260, 300, 440, 200)
    self.opacity = 0
    self.back_opacity = 0
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_SUPPLYSHOP_ARMOURNUMBERSELECT)
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
  
  #def refresh
  #  if self.contents != nil
  #    self.contents.dispose
  #    self.contents = nil
  #  end
    #self.contents = Bitmap.new(width - 32, height - 32)
    #self.contents.draw_text(150, 0, 120, 48, (@tank.maxhp - @tank.hp).to_s)
  #end
  
  def refresh_tank(tank)
    @tank = tank
    #refresh
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
    return unless self.active && self.visible
    @number_window.update if @number_window != nil
    @number_window.number = [@number_window.number, @tank.maxhp - @tank.hp].min
  end
end