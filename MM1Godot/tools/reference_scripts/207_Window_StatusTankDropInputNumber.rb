#==============================================================================
# ■ Window_StatusTankDropInputNumber
#------------------------------------------------------------------------------
# 　信息窗口内部使用、输入数值的窗口。
#==============================================================================

class Window_StatusTankDropInputNumber < Window_Base
  
  include MM_DataBase
  
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     digits_max : 位数
  #--------------------------------------------------------------------------
  def initialize(number)
    @orig_number = number
    @number = number
    case number
    when 0...10
      num_size = 1
    when 10...100
      num_size = 2
    when 100...1000
      num_size = 3
    when 1000...10000
      num_size = 4
    when 10000...100000
      num_size = 5
    end
    @digits_max = num_size
    #@number = 0
    # 从数字的幅度计算(假定与 0～9 等幅)光标的幅度
    dummy_bitmap = Bitmap.new(32, 32)
    @cursor_width = dummy_bitmap.text_size("0").width + 8
    dummy_bitmap.dispose
    super(0, 0, @cursor_width * @digits_max + 32, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.z = 9998
    self.opacity = 0
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_DIALOG_NUMBER_UP_INPUT)
    @sprite_cursor.z = 9999
    
    @index = 0
    refresh
    update_cursor_rect
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def visible=(value)
    super
    @sprite_cursor.visible = value
  end
  
  #--------------------------------------------------------------------------
  # ● 取得数值
  #--------------------------------------------------------------------------
  def number
    return @number.to_i
  end
  
  #--------------------------------------------------------------------------
  # ● 设置数值
  #     number : 新的数值
  #--------------------------------------------------------------------------
  def number=(number)
    @number = [[number, 0].max, 10 ** @digits_max - 1].min
    refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 更新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    @sprite_cursor.x = self.x + @index * @cursor_width + 15
    @sprite_cursor.y = self.y + 15
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    super
    # 按下方向键上与下的情况下
    if Input.repeat?(Input::UP) or Input.repeat?(Input::DOWN)
      $game_system.se_play($data_system.cursor_se)
      # 取得现在位置的数字位数
      place = 10 ** (@digits_max - 1 - @index)
      n = @number / place % 10
      @number -= n * place
      # 上为 +1、下为 -1
      n = (n + 1) % 10 if Input.repeat?(Input::UP)
      n = (n + 9) % 10 if Input.repeat?(Input::DOWN)
      # 再次设置现在位的数字
      @number += n * place
      if @number > @orig_number
        @number = @orig_number
      end
      refresh
    end
    # 光标右
    if Input.repeat?(Input::RIGHT)
      if @digits_max >= 2
        $game_system.se_play($data_system.cursor_se)
        @index = (@index + 1) % @digits_max
      end
    end
    # 光标左
    if Input.repeat?(Input::LEFT)
      if @digits_max >= 2
        $game_system.se_play($data_system.cursor_se)
        @index = (@index + @digits_max - 1) % @digits_max
      end
    end
    update_cursor_rect
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    s = sprintf("%0*d", @digits_max, @number)
    for i in 0...@digits_max
      self.contents.draw_text(i * @cursor_width + 4, 0, 32, 32, s[i,1])
    end
  end
end