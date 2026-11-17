class Window_CannonBallShopBuyCannonBallSelect < Window_Selectable
  
  include MM_DataBase
  
  attr_accessor :cursor_index
  
  def initialize(cannonball_list)
    super(225, 15, 640, 160)
    @cannonball_list = cannonball_list
    self.opacity = 0
    self.back_opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 225
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
    return @cannonball_ary[self.index]
  end
  
  #----------1----------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    id_ary = DATA_SPECIAL_CANNONBALL_LIST[@cannonball_list]
    @cannonball_ary = []
    for id in id_ary
      @cannonball_ary.push($data_specialcannonballs[id])
    end
    # 如果项目数不是 0 就生成位图、描绘全部项目
    @item_max = @cannonball_ary.size
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
    cannonball = @cannonball_ary[index]
    x = 4
    y = index * 32
    self.contents.draw_text(x + 28, y, 212, 32, cannonball.name, 0)
    self.contents.draw_text(x + 240, y, 88, 32, cannonball.price.to_s, 2)
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
    x = 230
    y = @index / @column_max * 32 - self.oy + 32
    # 更新光标矩形
    #self.cursor_rect.set(x, y, cursor_width, 32)
    @cursor.x = x
    @cursor.y = y
  end
  
  def update
    if self.visible
      super
    end
  end
  
end