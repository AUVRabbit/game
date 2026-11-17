class Window_MenuUpDown < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  attr_accessor :cursor
  def initialize
    super(240, 300, 440, 180)
#    self.index = -1
    @cursor_index = 0
    self.visible = false
    self.active = false
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.z = 9999
    @cursor.x = 255
    @cursor.y = 320
    @cursor.visible = false
    self.back_opacity = 0
    self.opacity = 0
    refresh
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.font.size = 20
    
    str_ary = ["全体"]
    for i in 0...$game_party.actors.size
      str = ""
      str += $game_party.actors[i].name
      if $game_party.actors[i].tank != nil
        str += (" … " + $game_party.actors[i].tank.name)
      end
      str_ary.push(str)
    end
    
    for i in 0...str_ary.size
      str = str_ary[i]
      self.contents.draw_text(60, i * 32, 240, 48, str)
    end
  end
  
  def visible=(value)
    super
    @cursor.visible = value if @cursor != nil
  end
  
  def update
    super
    if self.visible
      @cursor.visible = true
      if Input.trigger?(Input::DOWN)
        if @cursor_index < $game_party.actors.size
          @cursor_index += 1
          $game_system.se_play($data_system.cursor_se)
        end
      end
      if Input.trigger?(Input::UP)
        if @cursor_index >= 0
          @cursor_index -= 1
          $game_system.se_play($data_system.cursor_se)
        end
      end    
      @cursor.x = 255
      @cursor.y = 320 + @cursor_index * 32
    else
      @cursor.visible = false
    end
  end
end