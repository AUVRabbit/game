class Window_EquipTankLoad < Window_Base
  def initialize
    super(24, 0, 560, 200)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    self.visible = false
    @tank = nil
    @equipment = nil
  end
  
  def refresh
    self.contents.clear
    
    now_load = @tank.load_reality - @equipment.weight
    max_load = @tank.engine.load
    remain_load = max_load - now_load
    
    self.contents.draw_text(60, -10, 120, 64,\
          $game_tanks.index(@tank).to_s + "." + @tank.name)
    
    self.contents.draw_text(350, -10, 120, 64, now_load.roundf(2).to_s + "t")
    self.contents.draw_text(350, 24, 120, 64, max_load.roundf(2).to_s + "t")
    self.contents.draw_text(350, 56, 120, 64, remain_load.roundf(2).to_s + "t")
  end
  
  def refresh_data(tank, equipment)
    @tank = tank
    @equipment = equipment
    refresh
  end
end