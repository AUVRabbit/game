class Window_StatusTank < Window_Base
  def initialize
    super(24, 140, 560, 200)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    refresh
  end
  
  def refresh
    self.contents.clear
    
    for i in 0...$game_party.tanks.size
      self.contents.draw_text(24, i * 24, 200, 48, $game_party.tanks[i].name)
      self.contents.draw_text(360, i * 24, 200, 48,\
        "SP" + $game_party.tanks[i].hp.to_i.to_s + "/" + $game_party.tanks[i].maxhp.to_i.to_s)
    end
  end
end