class Window_StatusActor < Window_Base
  def initialize
    super(24, 10, 560, 200)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    refresh
  end
  
  def refresh
    for i in 0...$game_party.actors.size
      self.contents.draw_text(24, i * 32, 200, 48, $game_party.actors[i].name)
      self.contents.draw_text(230, i * 32, 72, 48, "L:")
      self.contents.draw_text(260, i * 32, 200, 48, $game_party.actors[i].level.to_s)
      self.contents.draw_text(360, i * 32, 200, 48,\
      "H" + $game_party.actors[i].hp.to_s + "/" + $game_party.actors[i].maxhp.to_s)
    end
  end
end