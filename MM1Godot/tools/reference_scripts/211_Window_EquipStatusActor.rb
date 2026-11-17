class Window_EquipStatusActor < Window_Base
  
  include MM_System
  
  def initialize(actor)
    super(0, 10, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @actor = actor
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    
    self.contents.draw_text(40, -8, 120, 48, @actor.name)
    self.contents.draw_text(230, -8, 120, 48, @actor.level.to_s)
    self.contents.draw_text(230, 28, 120, 48, @actor.atk.to_s)
    self.contents.draw_text(430, 28, 120, 48, @actor.pdef.to_s)
  end
  
  def refresh_equipment(item)
    refresh
    case item
    when RPG::Weapon
      if @actor.weapon != nil
        temp_atk = @actor.atk - @actor.weapon.atk + item.atk
      else
        temp_atk = @actor.atk + item.atk
      end
      self.contents.draw_text(230, 56, 120, 48, temp_atk.to_s)
    when RPG::Armor
      case item.kind
      when ARMOR_HEAD
        if @actor.armor1 != nil
          temp_pdef = @actor.pdef - @actor.armor1.pdef + item.pdef
        else
          temp_pdef = @actor.pdef + item.pdef
        end
      when ARMOR_BODY
        if @actor.armor2 != nil
          temp_pdef = @actor.pdef - @actor.armor2.pdef + item.pdef
        else
          temp_pdef = @actor.pdef + item.pdef
        end
      when ARMOR_HAND
        if @actor.armor3 != nil
          temp_pdef = @actor.pdef - @actor.armor3.pdef + item.pdef
        else
          temp_pdef = @actor.pdef + item.pdef
        end
      when ARMOR_FOOT
        if @actor.armor4 != nil
          temp_pdef = @actor.pdef - @actor.armor4.pdef + item.pdef
        else
          temp_pdef = @actor.pdef + item.pdef
        end
      when ARMOR_LEATHER
        if @actor.armor5 != nil
          temp_pdef = @actor.pdef - @actor.armor5.pdef + item.pdef
        else
          temp_pdef = @actor.pdef + item.pdef
        end
      end
      self.contents.draw_text(430, 56, 120, 48, temp_pdef.to_s)
    end
  end
  
  def refresh_actor(actor)
    @actor = actor
    refresh
  end
end