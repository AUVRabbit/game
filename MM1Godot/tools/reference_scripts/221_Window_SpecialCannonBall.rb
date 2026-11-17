class Window_SpecialCannonBall < Window_Base
  
  attr_accessor :cursor
  attr_reader   :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize(tank)
    super(24, 140, 560, 200)
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
    special_cannonball_capacity_relity = 0
    for key in @tank.underpan.special_cannonball.keys
      special_cannonball_capacity_relity += @tank.underpan.special_cannonball[key]
    end
    self.contents.draw_text(300, -18, 120, 48,
                             special_cannonball_capacity_relity.to_s + "/" +\
                             @tank.underpan.special_cannonball_capacity.to_s)
    temp_ary = @tank.underpan.special_cannonball.keys
    #p temp_ary
    temp_ary.sort! {|ball1, ball2| ball1 <=> ball2}
    for i in 0...temp_ary.size
      x = i % 2 * 280 + 60
      y = i / 2 * 24 + 10
      self.contents.draw_text(x, y, 120, 48, $data_specialcannonballs[temp_ary[i]].name)
      self.contents.draw_text(x + 84, y, 120, 48,\
                              @tank.underpan.special_cannonball[temp_ary[i]].to_s)
    end
  end
    
  def refresh_tank(tank)
    @cursor_index = 0
    @tank = tank
    refresh
  end
end