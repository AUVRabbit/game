class Window_PluginList < Window_Selectable
  
  include MM_DataBase
  include PluginModule
  
  def initialize
    super(60, 124, 540, 320)
    self.back_opacity = 0
    self.opacity = 0
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 20
    @cursor.y = 350
    @cursor.z = 9999
    @keys = $game_plugins.getPluginRegistDataBase.keys
    @keys.sort!
    self.index = 0
    @cursor_index = 0
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
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    @item_max = @keys.size
    for i in 0...@keys.size
      name = @keys[i]
      x = 60
      y = 32 * i + 20
      self.contents.draw_text(x, y, 240, 64, $game_plugins.getRegistPluginByName(name).pluginName)
      self.contents.draw_text(x + 200, y, 240, 64, $game_plugins.getRegistPluginByName(name).state == PLUGINSTATE_ON ? "ON" : "OFF")
    end
    
  end
  
  def refresh_keys
    self.index = 0
    @keys = $game_plugins.getPluginRegistDataBase.keys
    @keys.sort!
  end
  
  def plugin
    return $game_plugins.getRegistPluginByName(@keys[self.index])
  end
  
  def shell_plugin
    return $game_plugins.getPluginByName(@keys[self.index])
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
    x = 100
    y = @index / @column_max * 32 - self.oy + 180
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