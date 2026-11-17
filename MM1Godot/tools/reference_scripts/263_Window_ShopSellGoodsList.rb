class Window_ShopSellGoodsList < Window_Base
  
  attr_reader :cursor_index
  
  include MM_System
  include MM_DataBase
  
  def initialize
    super(225, 15, 640, 160)
    self.back_opacity = 0
    self.opacity = 0
    @obj = nil
    @type = nil
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 250
    @cursor.y = self.y + 36
    @cursor.z = 9999
    @cursor_index = 0
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
  
  def active=(value)
    super
    @cursor.visible = value
  end
  
  def good
    case @type
    when SHOPGOODTYPE_EQUIPMENT
      return @obj.equipments[@cursor_index]
    when SHOPGOODTYPE_ITEM
      return @obj.items[@cursor_index]
    end
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    
    case @type
    when SHOPGOODTYPE_EQUIPMENT
      for i in 0...@obj.equipments.size
        equipment = @obj.equipments[i]
        x = 40 + i % 2 * 130
        y = -10 + i / 2 * 24
        self.contents.draw_text(x, y, 120, 64, equipment.name)
      end
    when SHOPGOODTYPE_ITEM
      for i in 0...@obj.items.size
        item = @obj.items[i]
        x = 40 + i % 2 * 130
        y = -10 + i / 2 * 24
        self.contents.draw_text(x, y, 120, 64, item.name)
      end
    end
  end
    
  def refresh_obj(obj, type)
    @cursor_index = 0
    @obj = obj
    @type = type
    refresh
  end
  
  def update
    super
    if self.active && self.visible
      case @type
      when SHOPGOODTYPE_EQUIPMENT
        selection_max = @obj.equipments.size
      when SHOPGOODTYPE_ITEM
        selection_max = @obj.items.size
      end
      if Input.trigger?(Input::LEFT)
        @cursor_index -= 1 if @cursor_index > 0
      end
      
      if Input.trigger?(Input::RIGHT)
        @cursor_index += 1 if @cursor_index < selection_max - 1
      end
      
      if Input.trigger?(Input::UP)
        @cursor_index -= 2 if @cursor_index > 1
      end
      
      if Input.trigger?(Input::DOWN)
        @cursor_index += 2 if @cursor_index + 2 < selection_max
      end
      
      @cursor.x = 250 + @cursor_index % 2 * 130
      @cursor.y = self.y + @cursor_index / 2 * 24 + 16
      return
    end
  end
end