class Window_BattleStatus < Window_Base
  
  include MM_DataBase
  
  def initialize
    super(240, 315, 440, 180)
    self.active = false
    self.back_opacity = 0
    self.opacity = 0
    @index = 0
    refresh
  end
    
  def visible=(value)
    super
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
  end
end