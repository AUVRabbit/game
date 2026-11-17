class Window_StatusActorLook < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_reader :actor
  def initialize(actor)
    super(-15, -15, 840, 640)
    self.visible = false
    self.back_opacity = 0
    self.opacity = 0
    self.contents = RPG::Cache.picture(PICTURE_STATUS_PEOPLE_BACK)
    @actor = actor
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = RPG::Cache.picture(PICTURE_STATUS_PEOPLE_BACK)
    self.contents.draw_text(120, 40, 120, 32, @actor.name)
    self.contents.draw_text(150, 80, 120, 32, @actor.level.to_s)
    self.contents.draw_text(60, 110, 120, 32,\
      "HP" + @actor.hp.to_s + "/" + @actor.maxhp.to_s)
    x_plus = 160
    y_plus = 20
    self.contents.draw_text(320 + x_plus, 55 + y_plus, 120, 32, @actor.battle_level.to_s)
    self.contents.draw_text(320 + x_plus, 90 + y_plus, 120, 32, @actor.fix_level.to_s)
    self.contents.draw_text(320 + x_plus, 125 + y_plus, 120, 32, @actor.driver_level.to_s)
    self.contents.draw_text(350 + x_plus, 160 + y_plus, 120, 32, @actor.atk.to_s)
    self.contents.draw_text(350 + x_plus, 195 + y_plus, 120, 32, @actor.pdef.to_s)
    self.contents.draw_text(350 + x_plus, 230 + y_plus, 120, 32, @actor.str.to_s)
    self.contents.draw_text(350 + x_plus, 265 + y_plus, 120, 32, @actor.dex.to_s)
    self.contents.draw_text(350 + x_plus, 300 + y_plus, 120, 32, @actor.agi.to_s)
    self.contents.draw_text(350 + x_plus, 330 + y_plus, 120, 32, @actor.int.to_s)
    self.contents.draw_text(320 + x_plus, 370 + y_plus, 120, 32, @actor.exp.to_s)
    self.contents.draw_text(320 + x_plus, 402 + y_plus, 120, 32, $game_party.gold.to_s)
    
    for i in 0...@actor.equipments.size
      equipment = @actor.equipments[i]
      bitmap = nil
      case equipment
      when RPG::Weapon
        if bitmap != nil
          bitmap.dispose if !bitmap.disposed?
        end
        if @actor.weapon.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_WEAPON)
        else
          bitmap = Bitmap.new(32, 32)
        end
      when RPG::Armor
        case equipment.kind 
        when ARMOR_HEAD
          if bitmap != nil
            bitmap.dispose if !bitmap.disposed?
          end
          if @actor.armor1.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_HEAD)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_BODY
          if bitmap != nil
            bitmap.dispose if !bitmap.disposed?
          end
          if @actor.armor2.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_BODY)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_HAND
          if bitmap != nil
            bitmap.dispose if !bitmap.disposed?
          end
          if @actor.armor3.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_HAND)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_FOOT
          if bitmap != nil
            bitmap.dispose if !bitmap.disposed?
          end
          if @actor.armor4.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_FOOT)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_LEATHER
          if bitmap != nil
            bitmap.dispose if !bitmap.disposed?
          end
          if @actor.armor5.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_LEATHER)
          else
            bitmap = Bitmap.new(32, 32)
          end
        end
      end
      if bitmap != nil
        rect = Rect.new(0, 0, bitmap.width, bitmap.height)
        self.contents.blt(50, 210 + i * 32, bitmap, rect)
        self.contents.draw_text(80, 200 + i * 32, 120, 48, equipment.name)
      end
    end
  end
  
  def refresh_people(actor)
    @actor = actor
    refresh
  end
end