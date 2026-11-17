class Window_ShopGoodInfo < Window_Base
  
  include MM_DataBase
  include MM_System
  
  def initialize
    super(0, 0, 440, 380)
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 20
    @cursor.y = 350
    @cursor.z = 9999
    @item = nil
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    case @item
    when RPG::Weapon
      self.contents = RPG::Cache.picture(PICTURE_SHOP_PEOPLEEQUIPMENTINFOFORWEAPON)
      self.contents.draw_text(64, 48, 120, 48, @item.atk.to_s)
    when RPG::Armor
      self.contents = RPG::Cache.picture(PICTURE_SHOP_PEOPLEEQUIPMENTINFOFORARMOR)
      self.contents.draw_text(64, 48, 120, 48, @item.pdef.to_s)
    when RPG::MainCannon
      self.contents = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTINFOFORCANNON)
      self.contents.draw_text(12, 0, 120, 48, "主炮")
      self.contents.font.size = 18
      self.contents.draw_text(82, 26, 120, 48, @item.atk.to_s)
      self.contents.draw_text(80, 26 + 16, 120, 48, "ONE")
      self.contents.draw_text(82, 26 + 16 * 2, 120, 48, @item.pdef.to_s)
      self.contents.draw_text(82, 26 + 16 * 3, 120, 48, @item.quantity == 0 ? "※※※" : @item.quantity.to_s )
      self.contents.draw_text(122, 26 + 16 * 4, 120, 48, @item.weight.to_s)
    when RPG::SubCannon
      self.contents = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTINFOFORCANNON)
      self.contents.draw_text(12, 0, 120, 48, "副炮")
      self.contents.font.size = 14
      self.contents.draw_text(82, 26, 120, 48, @item.atk.to_s)
      case @item.range_type
      when RANGE_SINGLE
        self.contents.draw_text(80, 26 + 16, 120, 48, "ONE")
      when RANGE_GROUP
        self.contents.draw_text(80, 26 + 16, 120, 48, "GROUP")
      when RANGE_ALL
        self.contents.draw_text(80, 26 + 16, 120, 48, "ALL")
      end
      self.contents.draw_text(82, 26 + 16 * 2, 120, 48, @item.pdef.to_s)
      self.contents.draw_text(82, 26 + 16 * 3, 120, 48, @item.quantity == 0 ? "※※※" : @item.quantity.to_s )
      self.contents.draw_text(122, 26 + 16 * 4, 120, 48, @item.weight.to_s)
    when RPG::SE
      self.contents = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTINFOFORCANNON)
      self.contents.draw_text(12, 0, 120, 48, "SE")
      self.contents.font.size = 14
      self.contents.draw_text(28, 12, 120, 48, @item.atk.to_s)
      case @item.range_type
      when RANGE_SINGLE
        self.contents.draw_text(80, 26 + 16, 120, 48, "ONE")
      when RANGE_GROUP
        self.contents.draw_text(80, 26 + 16, 120, 48, "GROUP")
      when RANGE_ALL
        self.contents.draw_text(80, 26 + 16, 120, 48, "ALL")
      end
      self.contents.draw_text(82, 26 + 16 * 2, 120, 48, @item.pdef.to_s)
      self.contents.draw_text(82, 26 + 16 * 3, 120, 48, @item.quantity == 0 ? "※※※" : @item.quantity.to_s )
      self.contents.draw_text(122, 26 + 16 * 4, 120, 48, @item.weight.to_s)
    when RPG::Engine
      self.contents = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTINFOFORENGINE)
      self.contents.draw_texxt(12, 0, 120, 48, "发动机")
      self.contents.draw_text(82, 26 + 16 * 2, 120, 48, @item.load.to_s)
      self.contents.draw_text(82, 26 + 16 * 38, 120, 48, @item.pdef.to_s)
      self.contents.draw_text(122, 26 + 16 * 4, 120, 48, @item.weight.to_s)
    when RPG::C_Unit
      self.contents = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTINFOFORCUNIT)
      self.contents.draw_text(12, 0, 120, 48, "C装置")
      self.contents.font.size = 14
      self.contents.draw_text(82, 26 + 16 * 38, 120, 48, @item.pdef.to_s)
      self.contents.draw_text(122, 26 + 16 * 4, 120, 48, @item.weight.to_s)
    end
  end
  
  def refresh_item(item)
    @item = item
    refresh
  end
end