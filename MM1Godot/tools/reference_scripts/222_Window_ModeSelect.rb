class Window_ModeSelect < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(228, 300, 420, 180)
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.visible = false
    @cursor.x = 255 - 12
    @cursor.y = 320
    @cursor.z = 9999
    self.back_opacity = 0
    self.opacity = 0
    self.visible = false
    @cursor_index = 0
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_MODE_BACK)
    self.contents.draw_text(120, 35 - 5, 120, 48, $game_system.information.to_s)
    self.contents.draw_text(120, 35 * 2 - 5, 120, 48,\
        $game_system.animation == true ? "ON" : "OFF")
    self.contents.draw_text(120, 35 * 3 - 5, 120, 48,\
        $game_system.sound == true ? "ON" : "OFF")
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
  
  def update
    super
    if !self.visible
      return
    end
    if Input.trigger?(Input::DOWN) && self.visible
      if @cursor_index < 3
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP) && self.visible
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
    
    if Input.trigger?(Input::C)
      case @cursor_index
      when MODE_INFORMATION
        $game_system.information == 5 ? $game_system.information = 1 : $game_system.information += 1
      when MODE_ANIMATION
        $game_system.animation == true ? $game_system.animation = false : $game_system.animation = true
      when MODE_SOUND
        $game_system.sound == true ? $game_system.sound = false : $game_system.sound = true
      end
      refresh
    end
    
    @cursor.x = 255 - 12
    @cursor.y = 320 + @cursor_index * 35
  end
end