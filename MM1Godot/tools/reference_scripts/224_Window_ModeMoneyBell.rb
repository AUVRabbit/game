class Window_ModeMoneyBell < Window_Base
  
  include MM_System
  include MM_DataBase
  
  def initialize
    super(228, 300, 420, 180)
    self.back_opacity = 0
    self.opacity = 0
    self.contents = RPG::Cache.picture(PICTURE_MODE_MONEYBELL_BACK)
    @cursor_index = 0
    @number_window = Window_InputNumber.new(8)
    @number_window.number = $game_system.moneybell
    @number_window.x = 300
    @number_window.y = 350
    self.visible = false
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_MODE_MONEYBELL_BACK)
    self.contents.draw_text(100, 80, 120, 48, $game_party.gold.to_s)
  end
  
  def dispose
    super
    @number_window.dispose
  end
  
  def visible=(value)
    super
    @number_window.visible = value
    @number_window.active = value
  end
  
  def number
    return @number_window.number
  end
  
  def update
    super
    if !self.visible
      return
    end
    @number_window.update
  end
end