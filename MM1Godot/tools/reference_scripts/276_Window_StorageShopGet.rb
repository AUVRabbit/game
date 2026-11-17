class Window_StorageShopGet < Window_Selectable
  include MM_DataBase
  
  def initialize
    super(15, 15, 640, 300)
    @trunk = $game_party.trunk
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 10
    @cursor.y = 25
    @cursor.z = 9999
    self.index = 0
    @cursor_index = 0
    self.active = true
    refresh
  end
  
  def index=(index)
    super(index)
    @cursor_index = index
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
  
  def reset
    self.index = 0
  end
  
  #--------------------------------------------------------------------------
  # ● 获取物品
  #--------------------------------------------------------------------------
  def item
    return @trunk[self.index]
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    
    # 如果项目数不是 0 就生成位图、描绘全部项目
    @item_max = @trunk.size
    if @item_max > 0
      self.contents = Bitmap.new(width - 32, row_max * 32)
      for i in 0...@item_max
        draw_item(i)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 描绘项目
  #     index : 项目编号
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @trunk[index]
    x = 4
    y = index * 32
    self.contents.draw_text(x + 28, y, 212, 32, item.name, 0)
    #self.contents.draw_text(x + 328, y, 212, 32, good.price.to_s + "G", 0)
    case item
    when Game_Engine, Game_C_Unit, Game_Engine
      if item.big_broken?
        str = "坏"
      elsif item.little_broken?
        str = "损"
      else
        str = "OK"
      end
      self.contents.draw_text(x + 128, y, 212, 32, str)
    when Game_MainCannon, Game_SubCannon, Game_SE
      if item.big_broken?
        str = "坏"
      elsif item.little_broken?
        str = "损"
      else
        str = "OK"
      end
      self.contents.draw_text(x + 128, y, 212, 32, str)
      if item.limited_quantity?
        self.contents.draw_text(x + 228, y, 212, 32, item.quantity_reality.to_s)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 更新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    if @index < 0
      @cursor.visible = false
      return
    end
    # 获取当前的行
    row = @index / @column_max
    # 当前行被显示开头行前面的情况下
    if row < self.top_row
      # 从当前行向开头行滚动
      self.top_row = row
    end
    # 当前行被显示末尾行之后的情况下
    if row > self.top_row + (self.page_row_max - 1)
      # 从当前行向末尾滚动
      self.top_row = row - (self.page_row_max - 1)
    end
    # 计算光标的宽度
    cursor_width = self.width / @column_max - 32
    # 计算光标坐标
    #x = @index % @column_max * (cursor_width + 32)
    #y = @index / @column_max * 32 - self.oy
    x = 10
    y = @index / @column_max * 32 - self.oy + 32
    # 更新光标矩形
    #self.cursor_rect.set(x, y, cursor_width, 32)
    @cursor.x = x
    @cursor.y = y
  end
  
  def update
    if self.visible && self.visible
      super
    end
  end
  
end