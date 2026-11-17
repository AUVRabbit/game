class Window_StatusTankDrop < Window_Base
  include MM_DataBase
  def initialize(tank)
    super(240, 300, 440, 180)
    @tank = tank
    @number_input_window = Window_StatusTankDropInputNumber.new(tank.hp)
    @number_input_window.x = self.x + 220
    @number_input_window.y = self.y + 1
    @number_input_window.visible = false
    @number_input_window.active = false
    self.back_opacity = 0
    self.opacity = 0
    self.visible = false
    refresh
  end
  
  def drop_number
    return (@tank.hp - @number_input_window.number.to_i).to_i
  end
  
  def dispose
    super
    @number_input_window.dispose
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    self.contents = RPG::Cache.picture(PICTURE_STATUS_TANK_DROP)
    
    self.contents.draw_text(4, -4, 120, 48, @tank.name)
    self.contents.draw_text(220, 26, 120, 48, @tank.load_reality.to_s + "t")
    self.contents.draw_text(220, 26 + 32, 120, 48, @tank.engine.load.to_s + "t")
    self.contents.draw_text(220, 26 + 32 * 2, 120, 48,\
      (@tank.engine.load - @tank.load_reality).to_f.to_s)
  end
  
  def update
    super
    if self.visible
      if self.contents != nil
        self.contents.dispose
        self.contents = nil
      end
    
      self.contents = RPG::Cache.picture(PICTURE_STATUS_TANK_DROP)
      @number_input_window.visible = true if !@number_input_window.visible
      @number_input_window.update
      
      self.contents.draw_text(4, -4, 120, 48, @tank.name)
      
      now_tank_load_extra = @tank.hp - @number_input_window.number.to_i
      temp_now_load = @tank.load_reality - now_tank_load_extra / 100
      self.contents.draw_text(220, 26, 120, 48,\
          temp_now_load.to_s + "t")
      self.contents.draw_text(220, 26 + 32, 120, 48, @tank.load_max.to_s + "t")
      
      now_tank_load = @tank.load_reality - now_tank_load_extra / 100
      
      now_tank_load_remained = @tank.load_max - now_tank_load.roundf(2)
      self.contents.draw_text(220, 26 + 32 * 2, 120, 48,\
          now_tank_load_remained.to_s + "t")
    else
      @number_input_window.visible = false if @number_input_window.visible
    end
  end
  
  def refresh_tank(tank)
    @tank = tank
    refresh
  end
end