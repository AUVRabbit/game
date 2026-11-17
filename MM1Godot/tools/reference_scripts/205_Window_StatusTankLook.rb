class Window_StatusTankLook < Window_Base
  
  include MM_DataBase
  include MM_System
  
  attr_reader :tank
  def initialize(tank)
    super(-15, -15, 840, 640)
    self.back_opacity = 0
    self.opacity = 0
    self.contents = RPG::Cache.picture(PICTURE_STATUS_TANK_BACK)
    @sprite_tank_none = Sprite.new
    @sprite_tank_none.z = 9999
    @sprite_tank_main_cannon = Sprite.new
    @sprite_tank_main_cannon.z = 9999
    @sprite_tank_sub_cannon = Sprite.new
    @sprite_tank_sub_cannon.z = 9999
    @sprite_tank_se = Sprite.new
    @sprite_tank_se.z = 9999
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.z = 9999
    @sprite_parament = Sprite.new
    @sprite_parament.x = 385
    @sprite_parament.y = 236
    @sprite_parament.z = 9999
    self.visible = false
    @tank = tank
    refresh
  end
  
  def dispose
    super
    @sprite_tank_none.bitmap.dispose
    @sprite_tank_none.dispose
    @sprite_tank_main_cannon.bitmap.dispose if @sprite_tank_main_cannon.bitmap != nil
    @sprite_tank_main_cannon.dispose
    @sprite_tank_sub_cannon.bitmap.dispose if @sprite_tank_sub_cannon.bitmap != nil
    @sprite_tank_sub_cannon.dispose
    @sprite_tank_se.bitmap.dispose if @sprite_tank_se.bitmap != nil
    @sprite_tank_se.dispose
    @sprite_parament.bitmap.dispose if @sprite_parament.bitmap != nil
    @sprite_parament.dispose
  end
  
  def set_sprite_visible(value)
    @sprite_tank_none.visible = value if @sprite_tank_none.bitmap != nil
    @sprite_tank_main_cannon.visible = value if @sprite_tank_main_cannon.bitmap != nil
    @sprite_tank_sub_cannon.visible = value if @sprite_tank_sub_cannon.bitmap != nil
    @sprite_tank_se.visible = value if @sprite_tank_se.bitmap != nil
    @sprite_cursor.visible = value
  end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_STATUS_TANK_BACK)
    self.contents.draw_text(420, 32, 120, 48, @tank.hp.to_i.to_s + "/" + @tank.maxhp.to_i.to_s)
    self.contents.draw_text(420, 70, 120, 48, @tank.load_reality.roundf(2).to_s + "t")
    self.contents.draw_text(420, 104, 120, 48, @tank.load_max.to_s + "t")
    self.contents.draw_text(420, 140, 120, 48, (@tank.load_max - @tank.load_reality).roundf(2).to_s + "t")
    
    tank_equipments = @tank.equipments.clone
    tank_equipments.delete(@tank.main_cannon) if @tank.main_cannon != nil
    tank_equipments.delete(@tank.sub_cannon) if @tank.sub_cannon != nil
    tank_equipments.delete(@tank.se) if @tank.se != nil
    tank_equipments.delete(@tank.c_unit) if @tank.c_unit != nil
    tank_equipments.delete(@tank.engine) if @tank.engine != nil
    tank_equipments.delete(@tank.underpan) if @tank.underpan != nil
    
    tank_equiped_equipments = []
    tank_equiped_equipments.push(@tank.main_cannon) if @tank.main_cannon != nil
    tank_equiped_equipments.push(@tank.sub_cannon) if @tank.sub_cannon != nil
    tank_equiped_equipments.push(@tank.se) if @tank.se != nil
    tank_equiped_equipments.push(@tank.c_unit) if @tank.c_unit != nil
    tank_equiped_equipments.push(@tank.engine) if @tank.engine != nil
    tank_equiped_equipments.push(@tank.underpan) if @tank.underpan != nil
    
    @tank_equipments_all = []
    
    tank_equipments.each do |equipment|
      @tank_equipments_all.push(equipment)
    end
    tank_equiped_equipments.each do |equipment|
      @tank_equipments_all.push(equipment)
    end
    @cursor_index = 0
    
    for i in 0...tank_equiped_equipments.size
      equipment = tank_equiped_equipments[i]
      case equipment
      when Game_MainCannon
        str = "主炮"
      when Game_SubCannon
        str = "副炮"
      when Game_SE
        str = "SE"
      when Game_C_Unit
        str = "C装置"
      when Game_Engine
        str = "引擎"
      when Game_Underpan
        str = "底盘"
      end
      self.contents.draw_text(80 + 20, 220 + i * 32, 120, 48, str)
      self.contents.draw_text(170 + 20, 220 + i * 32, 120, 48, equipment.name)
      self.contents.draw_text(360 + 20, 220 + i * 32, 120, 48, "OK")
      self.contents.draw_text(450 + 20, 220 + i * 32, 120, 48, equipment.weight.to_s + "t")
    end
    
    for j in 0...tank_equipments.size
      equipment = tank_equipments[j]
      self.contents.draw_text(80 + 20, 220 + (j + i) * 32, 120, 48, str)
      self.contents.draw_text(170 + 20, 220 + (j + i) * 32, 120, 48, equipment.name)
      self.contents.draw_text(360 + 20, 220 + (j + i) * 32, 120, 48, "OK")
      self.contents.draw_text(450 + 20, 220 + (j + i) * 32, 120, 48, equipment.weight.to_s + "t")
    end
    
    #描绘战车形态
    if @sprite_tank_none.bitmap != nil
      @sprite_tank_none.bitmap.dispose
      @sprite_tank_none.bitmap = nil
    end
    if @sprite_tank_main_cannon.bitmap != nil
      @sprite_tank_main_cannon.bitmap.dispose
      @sprite_tank_main_cannon.bitmap = nil
    end
    if @sprite_tank_sub_cannon.bitmap != nil
      @sprite_tank_sub_cannon.bitmap.dispose
      @sprite_tank_sub_cannon.bitmap = nil
    end
    if @sprite_tank_se.bitmap != nil
      @sprite_tank_se.bitmap.dispose
      @sprite_tank_se.bitmap = nil
    end
    
    pictures = PICTURE_TANKS_STATUS[@tank.id]
    @sprite_tank_none.bitmap = RPG::Cache.picture(pictures[0])
    @sprite_tank_none.x = pictures[4][0][0]
    @sprite_tank_none.y = pictures[4][0][1]
    
    if @tank.main_cannon != nil
      @sprite_tank_main_cannon.bitmap = RPG::Cache.picture(pictures[1])
      @sprite_tank_main_cannon.x = pictures[4][1][0]
      @sprite_tank_main_cannon.y = pictures[4][1][1]
    end
    
    if @tank.sub_cannon != nil
      @sprite_tank_sub_cannon.bitmap = RPG::Cache.picture(pictures[2])
      @sprite_tank_sub_cannon.x = pictures[4][2][0]
      @sprite_tank_sub_cannon.y = pictures[4][2][1]
    end
    
    if @tank.se != nil
      @sprite_tank_se.bitmap = RPG::Cache.picture(pictures[3])
      @sprite_tank_se.x = pictures[4][3][0]
      @sprite_tank_se.y = pictures[4][3][1]
    end
  end
  
=begin
  #調試用
  def update
    super
    if self.visible
      @sprite_tank_none.x += 1 if Input.press?(Input::RIGHT) && Input.press?(Input::F5)
      @sprite_tank_none.x -= 1 if Input.press?(Input::LEFT) && Input.press?(Input::F5)
      @sprite_tank_none.y -= 1 if Input.press?(Input::UP) && Input.press?(Input::F5)
      @sprite_tank_none.y += 1 if Input.press?(Input::DOWN) && Input.press?(Input::F5)
      
      @sprite_tank_main_cannon.x += 1 if Input.press?(Input::RIGHT) && Input.press?(Input::F6)
      @sprite_tank_main_cannon.x -= 1 if Input.press?(Input::LEFT) && Input.press?(Input::F6)
      @sprite_tank_main_cannon.y -= 1 if Input.press?(Input::UP) && Input.press?(Input::F6)
      @sprite_tank_main_cannon.y += 1 if Input.press?(Input::DOWN) && Input.press?(Input::F6)
      
      
      @sprite_tank_sub_cannon.x += 1 if Input.press?(Input::RIGHT) && Input.press?(Input::F7)
      @sprite_tank_sub_cannon.x -= 1 if Input.press?(Input::LEFT) && Input.press?(Input::F7)
      @sprite_tank_sub_cannon.y -= 1 if Input.press?(Input::UP) && Input.press?(Input::F7)
      @sprite_tank_sub_cannon.y += 1 if Input.press?(Input::DOWN) && Input.press?(Input::F7)
      
      @sprite_tank_se.x += 1 if Input.press?(Input::RIGHT) && Input.press?(Input::F8)
      @sprite_tank_se.x -= 1 if Input.press?(Input::LEFT) && Input.press?(Input::F8)
      @sprite_tank_se.y -= 1 if Input.press?(Input::UP) && Input.press?(Input::F8)
      @sprite_tank_se.y += 1 if Input.press?(Input::DOWN) && Input.press?(Input::F8)

      if Input.trigger?(Input::C)
        p ("Tank = " + @sprite_tank_none.x.to_s + "," +  @sprite_tank_none.y.to_s,\
           "Main = " + @sprite_tank_main_cannon.x.to_s + "," +  @sprite_tank_main_cannon.y.to_s,\
           "Sub = " + @sprite_tank_sub_cannon.x.to_s + "," +  @sprite_tank_sub_cannon.y.to_s,\
           "SE = " + @sprite_tank_se.x.to_s + "," +  @sprite_tank_se.y.to_s)
      end
    end
  end
=end

  def update
    super
    if self.visible
      if Input.trigger?(Input::DOWN) && @sprite_parament.bitmap == nil
        $game_system.se_play($data_system.cursor_se)
        @cursor_index += 1 if @cursor_index < @tank_equipments_all.size - 1
      end
      
      if Input.trigger?(Input::UP) && @sprite_parament.bitmap == nil
        $game_system.se_play($data_system.cursor_se)
        @cursor_index -= 1 if @cursor_index > 0
      end
      @sprite_cursor.x = 50
      @sprite_cursor.y = 225 + @cursor_index * 32
      
      if Input.press?(Input::C)
        if @sprite_parament.bitmap != nil
          @sprite_parament.bitmap.dispose
        end
        equipment = @tank_equipments_all[@cursor_index]
        @sprite_parament.bitmap = RPG::Cache.picture(PICTURE_STATUS_TANK_PARAMENT)
        @sprite_parament.bitmap.draw_text(98, 64, 120, 48, equipment.weight.to_s + "t")
        x = 156
        y = 108
        case equipment
        when Game_MainCannon, Game_SE
          @sprite_parament.bitmap.draw_text(x, y, 120, 48, equipment.atk.to_s)
          @sprite_parament.bitmap.draw_text(x, y + 32, 120, 48, equipment.pdef.to_s)
          @sprite_parament.bitmap.draw_text(x, y + 32 * 2, 120, 48, equipment.quantity.to_s)
        when Game_SubCannon
          @sprite_parament.bitmap.draw_text(x, y, 120, 48, equipment.atk.to_s)
          @sprite_parament.bitmap.draw_text(x, y + 32, 120, 48, equipment.pdef.to_s)
          if equipment.quantity == LIMITED
            @sprite_parament.bitmap.draw_text(x, y + 32 * 2, 120, 48, "∞")
          else
            @sprite_parament.bitmap.draw_text(x, y + 32 * 2, 120, 48, equipment.quantity.to_s)
          end
        when Game_Engine, Game_C_Unit
          @sprite_parament.bitmap.draw_text(x, y + 24, 120, 48, equipment.pdef.to_s)
        when Game_Underpan
          @sprite_parament.bitmap.draw_text(x, y + 32, 120, 48, equipment.pdef.to_s)
          @sprite_parament.bitmap.draw_text(x, y + 32 * 2, 120, 48,\
                          equipment.special_cannonball.to_s)
        end
      else
        if @sprite_parament.bitmap != nil
          @sprite_parament.bitmap.dispose
          @sprite_parament.bitmap = nil
        end
      end
    end
  end
  
  def refresh_tank(tank)
    @tank = tank
    refresh
  end
end