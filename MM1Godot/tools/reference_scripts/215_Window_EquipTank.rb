class Window_EquipTank < Window_Base
  
  attr_accessor :cursor
  attr_reader   :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize(tank)
    super(24, 140, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @tank = tank
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 40
    @cursor.y = 160
    @cursor.z = 9999 
    @cursor_index = 0
    refresh
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
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
    self.contents = Bitmap.new(width - 32, height - 32)
    
    for i in 0...@tank.equipments.size
      equipment = @tank.equipments[i]
      bitmap = nil
      x = 80 + i % 2 * 280
      y = -10 + i / 2 * 24
      self.contents.draw_text(x, y, 120, 64, equipment.name)
      case equipment
      when Game_MainCannon, Game_SubCannon, Game_SE
        if @tank.main_cannon.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_MAINCANNON)
        elsif @tank.sub_cannon.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_SUBCANNON)
        elsif @tank.se.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_SE)
        else
          bitmap = Bitmap.new(32, 32)
        end
      when Game_Engine
        if @tank.engine.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_ENGINE)
        else
          bitmap = Bitmap.new(32, 32)
        end
      when Game_C_Unit
        if @tank.c_unit.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_CUNIT)
        else
          bitmap = Bitmap.new(32, 32)
        end
      when Game_Underpan
        if @tank.underpan.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_UNDERPAN)
        else
          bitmap = Bitmap.new(32, 32)
        end
      end
      if bitmap != nil
        rect = Rect.new(0, 0, bitmap.width, bitmap.height)
        self.contents.blt(x - 24, y + 18, bitmap, rect)
      end
    end
  end
    
  def refresh_tank(tank)
    @cursor_index = 0
    @tank = tank
    refresh
  end
  
  def update
    super
    if self.active
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < @tank.equipments.size - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < @tank.equipments.size
      end
            
      @cursor.x = 40 + @cursor_index % 2 * 280
      @cursor.y = 160 + @cursor_index / 2 * 24
      return
    end
  end
end