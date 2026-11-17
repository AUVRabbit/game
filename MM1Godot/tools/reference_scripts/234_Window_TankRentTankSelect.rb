class Window_TankRentTankSelect < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize(rent_tanks_list)
    super(0, 0, 640, 200)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 35
    @cursor.y = 40
    @cursor.z = 9999
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_TANKRENT_TANKSELECT)
    @back.x = 0
    @back.y = 0
    @back.z = 8001
    @cursor_index = 0
    @rent_tanks_list = rent_tanks_list
    refresh
  end
  
  def visible=(value)
    super
    @cursor.visible = value
    @back.visible = value
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
    @back.bitmap.dispose
    @back.dispose
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    @rent_tank_ary = DATA_RENT_TANK_LIST[@rent_tanks_list]
    for i in 0...@rent_tank_ary.size
      tank_ary = DATA_RENT_TANK[@rent_tank_ary[i]]
      self.contents.draw_text(64, 12 + i * 32, 120, 48, "TAX")
      self.contents.draw_text(64 + 84, 12 + i * 32, 120, 48, tank_ary[0].to_s + "#")
      self.contents.draw_text(64 + 156, 12 + i * 32, 120, 48, tank_ary[1])
      self.contents.draw_text(64 + 380, 12 + i * 32, 120, 48, "SP")
      self.contents.draw_text(64 + 440, 12 + i * 32, 120, 48, "0")
    end
  end
  
  def get_tank_data
    return DATA_RENT_TANK[@rent_tank_ary[@cursor_index]]
  end
  
  def update
    super
    if self.visible && self.active
      if Input.trigger?(Input::DOWN)
        if @cursor_index < @rent_tank_ary.size - 1
          @cursor_index += 1
        end
      end
      
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      if Input.press?(Input::F5) && Input.press?(Input::LEFT)
        @cursor.x -= 1
      end
      
      if Input.press?(Input::F5) && Input.press?(Input::RIGHT)
        @cursor.x += 1
      end
      
      if Input.press?(Input::F5) && Input.press?(Input::UP)
        @cursor.y -= 1
      end
      
      if Input.press?(Input::F5) && Input.press?(Input::DOWN)
        @cursor.y += 1
      end
            
      if Input.press?(Input::F5) && Input.press?(Input::C)
        print @cursor.x.to_s + ", " + @cursor.y.to_s
      end
      
      @cursor.x = 35
      @cursor.y = 40 + @cursor_index * 32
    end
  end
end