class Window_StatusTargetSelect < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_accessor :cursor
  attr_reader   :now
  attr_reader   :actor_index
  attr_reader   :tank_index
  
  def initialize
    super(228, 300, 420, 180)
    self.back_opacity = 0
    self.opacity = 0
    self.active = false
    self.visible = false
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.visible = false
    @cursor.x = 255
    @cursor.y = 320
    @cursor.z = 9999
    @actor_index = 0
    @tank_index = 0
    @now = TARGET_LEFT
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
    
    self.contents = RPG::Cache.picture(PICTURE_BACKUP)
    #self.contents = Bitmap.new(width - 32, height - 32)
    
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      self.contents.draw_text(50, 30 * i, 120, 48, actor.name)
    end
    for i in 0...$game_party.tanks.size
      tank = $game_party.tanks[i]
      self.contents.draw_text(164, 30 * i, 120, 48, tank.name)
    end
  end
  
  def update
    super
    if !self.visible
      return
    end
    if Input.trigger?(Input::DOWN) && self.visible
      case @now
      when TARGET_LEFT
        if @actor_index < $game_party.actors.size - 1
          @actor_index += 1
        end
      when TARGET_RIGHT
        if @tank_index < $game_party.tanks.size - 1
          @tank_index += 1
        end
      end
    end
    
    if Input.trigger?(Input::UP) && self.visible
      case @now
      when TARGET_LEFT
        if @actor_index > 0
          @actor_index -= 1
        end
      when TARGET_RIGHT
        if @tank_index > 0
          @tank_index -= 1
        end
      end
    end
    
    if Input.trigger?(Input::LEFT) && self.visible
      if @now == TARGET_RIGHT
        if @tank_index <= $game_party.actors.size - 1
          @now = TARGET_LEFT
          @actor_index = @tank_index
        end
      end
    end
    
    if Input.trigger?(Input::RIGHT) && self.visible
      if @now == TARGET_LEFT
        if @actor_index <= $game_party.tanks.size - 1
          @now = TARGET_RIGHT
          @tank_index = @actor_index
        end
      end
    end
    
    if @now == TARGET_LEFT
      @cursor.x = 255
      @cursor.y = 320 + @actor_index * 30
    elsif @now == TARGET_RIGHT
      @cursor.x = 380
      @cursor.y = 320 + @tank_index * 30
    end
  end
end