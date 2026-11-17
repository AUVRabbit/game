class Window_CannonBallShopStatus < Window_Base
  
  include MM_System
  
  def initialize
    super(0, 10, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @tank = nil
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(40, -8, 120, 48, @tank.name)
    str_ary = []
    if @tank.main_cannon != nil
      str_ary.push([@tank.main_cannon.name, @tank.main_cannon.quantity_reality, @tank.main_cannon.quantity])
    end
    if @tank.sub_cannon != nil
      str_ary.push([@tank.sub_cannon.name, @tank.sub_cannon.quantity_reality, @tank.sub_cannon.quantity])
    end
    if @tank.se != nil
      str_ary.push([@tank.se.name, @tank.se.quantity_reality, @tank.se.quantity])
    end
    for i in 0...str_ary.size
      self.contents.draw_text(200, -8 + 24 * i, 120, 48, str_ary[i][0])
      if str_ary[i][2] == LIMITED
        self.contents.draw_text(340, -8 + 24 * i, 120, 48, "……")
      else
        self.contents.draw_text(340, -8 + 24 * i, 120, 48,\
                                str_ary[i][1].to_s + "/" + str_ary[i][2].to_s)
      end
    end
  end
  
  def refresh_tank(tank)
    @tank = tank
    refresh
  end
end