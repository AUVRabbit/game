class Window_MenuStatus < Window_Base
  
  include MM_DataBase
  
  attr_accessor :cursor
  def initialize
    super(240, 300, 440, 180)
    self.active = false
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.visible = false
    @cursor.x = 255
    @cursor.y = 320
    self.back_opacity = 0
    self.opacity = 0
    @index = 0
    refresh
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def visible=(value)
    super
    @cursor.visible = value if @cursor != nil
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    self.contents = Bitmap.new(width - 32, height - 32)
    
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      x_plus = 10
      y = 44 * i
      self.contents.font.size = 16
      self.contents.draw_text(x_plus + 40, y, 120, 48, actor.name)
      self.contents.draw_text(x_plus + 220, y, 120, 48, "HP")
      self.contents.draw_text(x_plus + 280, y ,120, 48, actor.hp.to_s)
      
      if actor.tank != nil
        self.contents.draw_text(x_plus + 220, y + 18, 120, 48, "SP")
        self.contents.draw_text(x_plus + 280, y + 18, 120, 48, actor.tank.hp.to_i.to_s)
      end
    end
  end
  
  def update
    super
    if self.active
      @cursor.visible = true
      if Input.trigger?(Input::DOWN)
        if @index < $game_party.actors.size - 2
          @index += 1
          $game_system.se_play($data_system.cursor_se)
        end
      end
      if Input.trigger?(Input::UP)
        if @index >= 0
          @index -= 1
          $game_system.se_play($data_system.cursor_se)
        end
      end
      @cursor.x = 250
      @cursor.y = 320 + (@index + 1) * 45
    else
      @cursor.visible = false
    end
  end
end