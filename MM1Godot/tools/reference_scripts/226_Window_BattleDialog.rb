class Window_BattleDialog < Window_Base
  include MM_DataBase
  
  def initialize
    super(0, 320, 640, 160)
    self.active = false
    self.back_opacity = 0
    self.opacity = 0
    @back = Sprite.new
    @back.bitmap = RPG::Cache.picture(PICTURE_BATTLE_DIALOG_BACK)
    @back.x = 0
    @back.y = 320
    @back.z = 8003
    @temp_actor_hp = []
    @temp_tank_sp = []
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      @temp_actor_hp.push(actor.hp)
    end
    for i in 0...$game_party.tanks.size
      tank = $game_party.tanks[i]
      @temp_tank_sp.push(tank.hp)
    end
    
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    self.contents = Bitmap.new(width - 32, height - 32)
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      hp = @temp_actor_hp[i]
      x_plus = 10
      y = 44 * i
      self.contents.font.size = 16
      self.contents.draw_text(x_plus + 440, y, 120, 48, "HP")
      self.contents.draw_text(x_plus + 480, y ,120, 48, hp.to_s)
      
      if actor.tank != nil
        self.contents.draw_text(x_plus + 440, y + 18, 120, 48, "SP")
        sp = @temp_tank_sp[$game_party.tanks.index(actor.tank)]
        self.contents.draw_text(x_plus + 480, y + 18, 120, 48, sp.to_i.to_s)
      end
    end
  end
  
  def refresh_actor(member)
    if member.is_a?(Game_Actor)
      @temp_actor_hp[$game_party.actors.index(member)] = member.hp
    elsif member.is_a?(Game_Tank)
      @temp_tank_sp[$game_party.tanks.index(member)] = member.hp
    end
    refresh
  end
  
  def dispose
    super
    @back.bitmap.dispose
    @back.dispose
  end
    
  def visible=(value)
    super
    @back.visible = value
  end
end