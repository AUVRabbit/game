class Window_CannonBallShopSellCannonBallSelect < Window_Base
  
  attr_reader   :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize
    super(24, 140, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 50
    @cursor.y = 175
    @cursor.z = 9999
    @cursor_index = 0
    @tank = nil
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
    temp_ary.sort! {|ball1, ball2| ball1.id <=> ball2.id}
    for i in 0...temp_ary.size
      x = i % 2 * 280 + 60
      y = i / 2 * 24 + 10
      self.contents.draw_text(x, y, 120, 48, $data_specialcannonballs[temp_ary[i]].name)
      self.contents.draw_text(x + 84, y, 120, 48,\
                              @tank.underpan.special_cannonball[temp_ary[i]].to_s)
    end
  end
  
  def get_cannonball
    temp_ary = @tank.underpan.special_cannonball.keys
    temp_ary.sort! {|ball1, ball2| ball1 <=> ball2}
    return temp_ary[@cursor_index]
  end
  
  def refresh_tank(tank)
    @cursor_index = 0
    @tank = tank
    refresh
  end
  
  def reset
    @cursor_index = 0
  end
  
  def update
    if self.visible
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < @tank.underpan.special_cannonball.size - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < @tank.underpan.special_cannonball.size
      end
      
      @cursor.x = 50 + @cursor_index % 2 * 280
      @cursor.y = 175 + @cursor_index / 2 * 24
    end
  end
end