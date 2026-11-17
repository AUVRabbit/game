class Window_IMMenu < Window_Base
  
  include MM_DataBase
  include MM_System
  
  attr_reader :index
  
  def initialize(menulist)
    super(0, 0, 640, 480)
    @menulist = menulist
    @index = 1
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 40
    @cursor.y = 30
    @cursor.z = 9999
    refresh
  end
  
  def visible=(value)
    super
    @cursor.visible = value
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def reset_cursor
    @index = 1
  end
  
  def refresh
    @menulist.sort! {|a, b| a.size <=> b.size}
    self.width = @menulist.last.split(//).size * 24 + 64
    self.height = @menulist.size * 24 + 32
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    for i in 0...@menulist.size
      self.contents.draw_text(12, i * 24, 240, 32, @menulist[i])
    end
  end
  
  def result
    return @index
  end
  
  def reset_menulist(menulist)
    @menulist = menulist
    refresh
  end
  
  def enter_menu_pro
    loop do
      Graphics.update
      Input.update
      update
      if Input.trigger?(Input::B)
        $game_system.se_play($data_system.cancel_se)
        return IMEMENU_EXIT
      end
      if Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        return @index
      end
    end
  end
  
  def update
    if self.visible && self.active
      
      if Input.trigger?(Input::UP)
        if @index > 1
          @index -= 1
        end
      end
      
      if Input.trigger?(Input::DOWN)
        if @index < @menulist.size
          @index += 1
        end
      end
      
      @cursor.x = self.x
      @cursor.y = self.y + (@index - 1) * 24 + 24
      
    end
  end
end