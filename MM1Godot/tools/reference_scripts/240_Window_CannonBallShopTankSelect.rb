class Window_CannonBallShopTankSelect < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(0, 320, 200, 200)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 20
    @cursor.y = 350
    @cursor.z = 9999
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_TANKRENT_BACKUP)
    @back.x = 17
    @back.y = 324
    @back.z = 8003
    @cursor_index = 0
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
    for i in 0...$game_party.tanks.size
      tank = $game_party.tanks[i]
      self.contents.draw_text(64, 4 + 32 * i, 120, 48, tank.name)
    end
  end
  
  def reset
    @cursor_index = 0
  end
  
  def update
    super
    if self.visible && self.active
      if Input.trigger?(Input::DOWN)
        if @cursor_index < $game_party.tanks.size - 1
          @cursor_index += 1
        end
      end
      
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      @cursor.x = 20
      @cursor.y = 350 + @cursor_index * 32
    end
  end
end