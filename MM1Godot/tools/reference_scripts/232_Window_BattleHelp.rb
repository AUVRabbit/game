class Window_BattleHelp < Window_Base
  
  attr_reader :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize
    super(240, 330, 440, 180)
    self.back_opacity = 0
    self.opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 400
    @cursor.y = 320
    @cursor.z = 9999
    @cursor_index = 0
    refresh
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
  
  def active=(value)
    super
    @cursor.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_BATTLE_HELP_BACK)
    self.contents.draw_text(190, 35 - 5 - 15, 120, 48, $game_system.information.to_s)
    self.contents.draw_text(190, 35 * 2 - 12 - 15, 120, 48,\
        $game_system.animation == true ? "ON" : "OFF")
    self.contents.draw_text(190, 35 * 3 - 20 - 15, 120, 48,\
        $game_system.sound == true ? "ON" : "OFF")
  end
  
  def update
    super
    if self.visible
      if Input.trigger?(Input::C)
        case @cursor_index
        when BATTLEHELP_INFORMATION
          $game_system.information == 5 ? $game_system.information = 1 : $game_system.information += 1
        when BATTLEHELP_ANIMATION
          $game_system.animation == true ? $game_system.animation = false : $game_system.animation = true
        when BATTLEHELP_MUSIC
          $game_system.sound == true ? $game_system.sound = false : $game_system.sound = true
        end
        refresh
      end
      
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < 8 - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < 8
      end
      @cursor.x = 260 + @cursor_index % 2 * 100
      @cursor.y = 340 + @cursor_index / 2 * 26
      return
    end
  end
end