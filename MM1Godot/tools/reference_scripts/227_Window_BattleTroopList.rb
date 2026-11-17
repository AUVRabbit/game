class Window_BattleTroopList < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(240, 300, 440, 180)
    self.back_opacity = 0
    self.opacity = 0
    #self.contents = RPG::Cache.picture(PICTURE_MODE_MONEYBELL_BACK)
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 250
    @cursor.y = 320
    @cursor.z = 9999 
    @cursor_index = 0
    refresh
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.bitmap
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
    for i in 0...$game_troop.enemies.size
      enemies_ary = $game_troop.enemies[i]
      x = (i % 2) * 156 + 32
      y = (i / 2) * 32 + 16
      self.contents.draw_text(x, y, 64, 64, enemies_ary[0].name)
      self.contents.draw_text(x + 60, y, 64, 64, enemies_ary.size.to_s)
    end
  end
  
  def update
    super
    if !self.visible
      return
    end
    if Input.trigger?(Input::LEFT)
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
    
    if Input.trigger?(Input::RIGHT)
      if @cursor_index < $game_troop.enemies.size - 1
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP)
      if @cursor_index >= 2
        @cursor_index -= 2
      end
    end
    
    if Input.trigger?(Input::DOWN)
      if @cursor_index <$game_troop.enemies.size - 2
        @cursor_index += 2
      end
    end
    
    @cursor.x = (@cursor_index % 2) * 156 - 12 + self.x
    @cursor.y = (@cursor_index / 2) * 32 + self.y + 48
  end
end