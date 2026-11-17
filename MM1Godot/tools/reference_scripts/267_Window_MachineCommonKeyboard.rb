class Window_MachineCommonKeyboard < Window_Base
  
  include MM_DataBase
  
  attr_accessor :index
  CHARACTER_TABLE =
  [
    "1", "2",  "3", "击",
    "4", "5",  "6", "※",
    "7", "8",  "9", "0",
  ]
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize
    super(0, 128, 640, 352)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    @sprite_select = Sprite.new
    @sprite_select.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_select.z = 9999
    @index = 0
    #refresh
    update_cursor_rect
  end
  
  #--------------------------------------------------------------------------
  # ● 获取文字
  #--------------------------------------------------------------------------
  def character
    return CHARACTER_TABLE[@index]
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  #def refresh
  #  self.contents.clear
  #  for i in 0...CHARACTER_TABLE.size
  #    x = 32 + i / 5 / 10 * 142 + i % 5 * 20
  #    y = i / 5 % 10 * 32 - 10
  #    self.contents.font.size = 24
  #    self.contents.draw_text(x, y, 28, 36, CHARACTER_TABLE[i], 1)
  #  end
    #self.contents.draw_text(544, 9 * 32, 64, 32, "确定", 1)
  #end
  
  def dispose
    super
    @sprite_select.bitmap.dispose
    @sprite_select.dispose
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    # 光标位置在 [确定] 的情况下
    if @index >= CHARACTER_TABLE.size
      #self.cursor_rect.set(544, 9 * 32, 64, 32)
      case @index
      when 12
        @sprite_select.x = 340
        @sprite_select.y = 320
      when 13
        @sprite_select.x = 340
        @sprite_select.y = 320 + 54
      when 14
        @sprite_select.x = 340
        @sprite_select.y = 320 + 108
      end
    # 光标位置在 [确定] 以外的情况下
    else
      x = 32 + @index / 4 / 10 * 142 + @index % 4 * 60 + 16
      y = @index / 4 % 10 * 54 - 10 + 180
      @sprite_select.x = x + 20
      @sprite_select.y = y + self.y + 17
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    super
    # 光标位置在 [确定] 的情况下
    if @index >= 12
      # 光标下
      if Input.repeat?(Input::DOWN)
        @index += 1
        if @index > 14
          @index = 14
        end
      end
      # 光标上
      if Input.repeat?(Input::UP)
        @index -= 1
        if @index < 12
          @index = 12
        end
      end
      if Input.trigger?(Input::LEFT)
        @index = 11 if @index == 14
        @index = 7 if @index == 13
        @index = 3 if @index == 12
      end
        
    # 光标位置在 [确定] 以外的情况下
    else
      # 按下方向键右的情况下
      if Input.repeat?(Input::RIGHT)
        # 按下状态不是重复的情况下、
        # 光标位置不在右端的情况下
        # 光标向右移动
        if @index % 4 < 3
          @index += 1
        else
          @index = 14 if @index == 11
          @index = 13 if @index == 7
          @index = 12 if @index == 3
        end
      end
      if Input.repeat?(Input::LEFT)
        if @index % 4 > 0
          @index -= 1
        end
      end
      # 按下方向键下的情况下
      if Input.repeat?(Input::DOWN)
        # 光标向下移动
        if @index < 8
          @index += 4
        end
      end
      # 按下方向键上的情况下
      if Input.repeat?(Input::UP)
        # 按下状态不是重复的情况下、
        # 光标位置不在上端的情况下
        # 光标向上移动
        if @index > 3
          @index -= 4
        end
      end
    end
    update_cursor_rect
  end
end