class Window_EquipActor < Window_Base
  
  attr_accessor :cursor
  attr_reader   :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize(actor)
    super(24, 140, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    @actor = actor
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
    
    for i in 0...@actor.equipments.size
      equipment = @actor.equipments[i]
      bitmap = nil
      x = 80 + i % 2 * 280
      y = -10 + i / 2 * 24
      self.contents.draw_text(x, y, 120, 64, equipment.name)
      case equipment
      when RPG::Weapon
        if @actor.weapon.equal?(equipment)
          bitmap = RPG::Cache.icon(ICON_EQUIPMENT_WEAPON)
        else
          bitmap = Bitmap.new(32, 32)
        end
      when RPG::Armor
        case equipment.kind
        when ARMOR_HEAD
          if @actor.armor1.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_HEAD)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_BODY
          if @actor.armor2.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_BODY)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_HAND
          if @actor.armor3.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_HAND)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_FOOT
          if @actor.armor4.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_FOOT)
          else
            bitmap = Bitmap.new(32, 32)
          end
        when ARMOR_LEATHER
          if @actor.armor5.equal?(equipment)
            bitmap = RPG::Cache.icon(ICON_EQUIPMENT_LEATHER)
          else
            bitmap = Bitmap.new(32, 32)
          end
        end
      end
      if bitmap != nil
        rect = Rect.new(0, 0, bitmap.width, bitmap.height)
        self.contents.blt(x - 24, y + 18, bitmap, rect)
      end
    end
  end
    
  def refresh_actor(actor)
    @cursor_index = 0
    @actor = actor
    refresh
  end
  
  def update
    super
    if self.active
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < @actor.equipments.size - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < @actor.equipments.size
      end
            
      @cursor.x = 40 + @cursor_index % 2 * 280
      @cursor.y = 160 + @cursor_index / 2 * 24
      return
    end
  end
end