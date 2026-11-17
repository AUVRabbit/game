class Window_SupplyShopCannonBallSelect < Window_Base
  
  include MM_DataBase
  
  attr_reader :cursor_index
  
  def initialize
    super(20, 5, 540, 320)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 20
    @cursor.y = 20
    @cursor.z = 9999
    @cursor_index = 0
    @tank = nil
    @equip_ary = []
  end
  
  def dispose
    super
    @cursor.bitmap.dispose
    @cursor.dispose
  end
  
  def visible=(value)
    super
    @cursor.visible = value
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    count = 0
    if @tank.main_cannon != nil
      self.contents.draw_text(40, 24 * 0, 240, 48, "主炮")
      self.contents.draw_text(120 + 40, 24 * 0, 240, 48, "…" + @tank.main_cannon.name)
      self.contents.draw_text(120 + 40 * 2, 24 * count, 240, 48, "…")
      if @tank.main_cannon.limited_quantity?
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48,\
          @tank.main_cannon.quantity_reality.to_s + "/" + @tank.main_cannon.quantity.to_s)
      else
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48, "∞")
      end
      count += 1
    end
    if @tank.sub_cannon != nil
      self.contents.draw_text(40, 24 * count, 240, 48, "副炮")
      self.contents.draw_text(120 + 40, 24 * count, 240, 48, "…" + @tank.sub_cannon.name)
      self.contents.draw_text(120 * 2 + 40, 24 * count, 240, 48, "…")
      if @tank.sub_cannon.limited_quantity?
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48,\
          @tank.sub_cannon.quantity_reality.to_s + "/" + @tank.sub_cannon.quantity.to_s)
      else
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48, "∞")
      end
      count += 1
    end
    if @tank.se != nil
      self.contents.draw_text(40, 24 * count, 240, 48, "SE")
      self.contents.draw_text(120 + 40, 24 * count, 240, 48, "…" + @tank.se.name)
      self.contents.draw_text(120 * 2 + 40, 24 * count, 240, 48, "…")
      if @tank.main_cannon.limited_quantity?
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48,\
          @tank.se.quantity_reality.to_s + "/" + @tank.se.quantity.to_s)
      else
        self.contents.draw_text(120 * 2 + 64 + 40, 24 * count, 240, 48, "∞")
      end
    end
  end
  
  def equipment
    return @equip_ary[@cursor_index]
  end
  
  def count_and_number
    equip = @equip_ary[@cursor_index]
    count = equip.quantity - equip.quantity_reality
    case equip
    when Game_MainCannon
      price = count * 5
    when Game_SubCannon, Game_SE
      price = count * equip.price / 10
    end
    return count, price
  end
  
  def can_supply?
    if @equip_ary[@cursor_index].limited_quantity?
      if @equip_ary[@cursor_index].quantity_full?
        return false
      else
        return true
      end
    else
      return false
    end
  end
  
  def refresh_tank(tank)
    @tank = tank
    @equip_ary.clear
    @equip_ary.push(@tank.main_cannon) if @tank.main_cannon != nil
    @equip_ary.push(@tank.sub_cannon) if @tank.sub_cannon != nil
    @equip_ary.push(@tank.se) if @tank.se != nil
    refresh
  end
  
  def update
    super
    if self.active && self.visible
      
      if Input.trigger?(Input::DOWN)
        if @cursor_index < @equip_ary.size - 1
          @cursor_index += 1
        end
      end
      
      if Input.trigger?(Input::UP)
        if @cursor_index > 0
          @cursor_index -= 1
        end
      end
      
      @cursor.y = 20 + @cursor_index * 24
    end
  end
end