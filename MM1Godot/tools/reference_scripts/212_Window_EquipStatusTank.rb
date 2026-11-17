class Window_EquipStatusTank < Window_Base
  
  include MM_System
  
  def initialize(tank)
    super(0, 10, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @tank = tank
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(40, -8, 120, 48,\
      $game_tanks.index(@tank).to_s + "." + @tank.name)
  end
  
  def refresh_equipment(item)
    refresh
    case item
    when Game_MainCannon, Game_SubCannon, Game_SE
      self.contents.draw_text(230, 28, 120, 48, item.atk.to_s)
      self.contents.draw_text(430, 28, 120, 48, item.pdef.to_s)
    when Game_Engine, Game_C_Unit, Game_Underpan
      self.contents.draw_text(430, 28, 120, 48, item.pdef.to_s)
    end
  end
  
  def refresh_tank(tank)
    @tank = tank
    refresh
  end
end