class Window_EquipmentTypeTank < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_accessor :sprite_cursor
  
  def initialize(tank, equipment)
    super(240, 300, 440, 180)
    @tank = tank
    @equipment = equipment
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.x = self.x + 20
    @sprite_cursor.y = self.y + 20
    @sprite_cursor.z = 9999
    @cursor_index = 0
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    refresh
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def visible=(value)
    super
    @sprite_cursor.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    @select_ary = []
    case @equipment
    when Game_MainCannon
      @select_ary.push("主炮")
    when Game_SubCannon
      if @equipment.equip_position[HOLE_MAIN_CANNON]
        @select_ary.push("主炮")
      end
      @select_ary.push("副炮")
    when Game_SE
      if @equipment.equip_position[HOLE_MAIN_CANNON]
        @select_ary.push("主炮")
      end
      if @equipment.equip_position[HOLE_SUB_CANNON]
        @select_ary.push("副炮")
      end
      @select_ary.push("SE")
    end
    
    @max_index = @select_ary.size
    for i in 0...@max_index
      self.contents.draw_text(56, i * 28, 64, 64, @select_ary[i])
      self.contents.draw_text(128, i * 28, 64, 64, "……")
      case @select_ary[i]
      when "主炮"
        self.contents.draw_text(196, i * 28, 128, 64, @tank.main_cannon.name) if @tank.main_cannon != nil
      when "副炮"
        self.contents.draw_text(196, i * 28, 128, 64, @tank.sub_cannon.name) if @tank.sub_cannon != nil
      when "SE"
        self.contents.draw_text(196, i * 28, 128, 64, @tank.se.name) if @tank.se != nil
      end
    end
    
  end
  
  def position
    case @select_ary[@cursor_index]
    when "主炮"
      return EQUIPTYPE_MAIN_CANNON
    when "副炮"
      return EQUIPTYPE_SUB_CANNON
    when "SE"
      return EQUIPTYPE_SE
    end
  end
  
  def update
    if self.active
      if Input.trigger?(Input::UP)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 1 if @cursor_index < @max_index - 1
      end
      
      @sprite_cursor.y = self.y + 20 + 10 if @cursor_index == 0
      @sprite_cursor.y = self.y + 48 + 10 if @cursor_index == 1
      @sprite_cursor.y = self.y + 76 + 10 if @cursor_index == 2
    end
  end
end