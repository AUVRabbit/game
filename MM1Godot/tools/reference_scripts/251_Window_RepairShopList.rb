class Window_RepairShopList < Window_Selectable
  
  include MM_DataBase
  
  def initialize
    super(84, 20, 560, 400)
    self.opacity = 0
    self.back_opacity  = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 56
    @cursor.y = 32
    @cursor.z = 9999
    self.index = 0
    self.active = true
    refresh
  end
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    #self.contents = Bitmap.new(width - 32, height - 32)
    set_data
    draw_selection
  end
  
  def effective?
    return !@limited_selection.include?(self.index)
  end
  
  def equipment
    return @equipments_ary[self.index]
  end
  
  def set_data
    @broken_equipments_ary = $game_party.get_tank_broken_equipments
    @equipments_ary = []
    @data = []
    @limited_selection = []
    for i in 0...@broken_equipments_ary.size
#      p @broken_equipments_ary if @broken_equipments_ary[i] == nil
      all_ary = @broken_equipments_ary[i]
      tank = all_ary[0]
      @limited_selection.push(@data.size)
      str = tank.id.to_s + "." + tank.name
      @data.push(str)
      @equipments_ary.push(nil)
      equipments_ary = all_ary[1]
      for equipment in equipments_ary
        str = "    "
        str += equipment.name
        str += "    "
        str += equipment.big_broken? ? "损" : "坏"
        @data.push(str)
        @equipments_ary.push(equipment)
      end
    end
  end
  
  def draw_selection
    @item_max = @data.size
    self.contents = Bitmap.new(width - 32, row_max * 32)
    for i in 0...@data.size
      x = 24
      y = i * 24
      self.contents.draw_text(x, y, 480, 48, @data[i])
    end
  end
  
  def refresh_data
    set_data
    refresh
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
    x = 56
    y = @index / @column_max * 24 - self.oy + 40
    # 更新光标矩形
    #self.cursor_rect.set(x, y, cursor_width, 32)
    @cursor.x = x
    @cursor.y = y
  end
  
  def update
    if self.active
      super
    end
  end
  
end