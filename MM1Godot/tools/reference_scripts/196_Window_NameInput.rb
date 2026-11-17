#==============================================================================
# ■ Window_NameInput
#------------------------------------------------------------------------------
# 　输入名称的画面、文字选择窗口。
#==============================================================================

class Window_NameInput < Window_Base
  
  include MM_DataBase
  
  attr_accessor :index
  CHARACTER_TABLE =
  [
    "0", "重", "1", " ", "2",
    "C", "装", "D", " ", "E",
    "O", "机", "P", " ", "Q",
    "0", "兵", "1", " ", "2",
    "C", " ", "D", " ", "E",
    "O", " ", "P", " ", "Q",
    "Z", " ", "▲", " ", " ",
    "A", " ", "B", " ", "C",
    "J", " ", "K", " ", "L",
    "S", " ", "T", " ", "U",
    
    "3", " ", "4", " ", "5",
    "F", " ", "G", " ", "H",
    "R", " ", "S", " ", "T",
    "3", " ", "4", " ", "5",
    "F", " ", "G", " ", "H",
    "R", " ", "S", " ", "T",
    "0", "1", "2", "3", "4",
    "D", " ", "E", " ", "F",
    "M", " ", "N", " ", "O",
    "V", " ", "W", " ", "X",
    
    "6", " ", "7", " ", "8",
    "I", " ", "J", " ", "K",
    "U", " ", "V", " ", "W",
    "6", " ", "7", " ", "8",
    "I", " ", "J", " ", "K",
    "U", " ", "V", " ", "W",
    "5", "6", "7", "8", "9",
    "G", " ", "H", " ", "I",
    "P", " ", "Q", " ", "R",
    "Y", " ", "Z", " ", ".",
    
    "9", " ", "A", " ", "B",
    "L", " ", "M", " ", "N",
    "X", " ", "Y", " ", "Z",
    "9", " ", "A", " ", "B",
    "L", " ", "M", " ", "N",
    "X", " ", "Y", " ", "▲",
    ".", " ", "!", " ", "?",
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
    @sprite_select.bitmap = RPG::Cache.picture(PICTURE_NAME_SELECT)
    @index = 0
    refresh
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
  def refresh
    self.contents.clear
    for i in 0...CHARACTER_TABLE.size
      x = 32 + i / 5 / 10 * 142 + i % 5 * 20
      y = i / 5 % 10 * 32 - 10
      self.contents.font.size = 24
      self.contents.draw_text(x, y, 28, 36, CHARACTER_TABLE[i], 1)
    end
    #self.contents.draw_text(544, 9 * 32, 64, 32, "确定", 1)
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    # 光标位置在 [确定] 的情况下
    if @index >= CHARACTER_TABLE.size
      #self.cursor_rect.set(544, 9 * 32, 64, 32)
      case @index
      when 201
        @sprite_select.x = 480
        @sprite_select.y = 367
      when 202
        @sprite_select.x = 480
        @sprite_select.y = 367 + 32
      when 203
        @sprite_select.x = 480
        @sprite_select.y = 367 + 64
      end
    # 光标位置在 [确定] 以外的情况下
    else
      x = 32 + @index / 5 / 10 * 142 + @index % 5 * 20
      y = @index / 5 % 10 * 32 - 10
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
    if @index >= 200
      # 光标下
      if Input.repeat?(Input::DOWN)
        @index += 1
        if @index > 203 
          @index = 203
        end
      end
      # 光标上
      if Input.repeat?(Input::UP)
        if @index == 201
          @index = 184
        else
          @index -= 1
        end
      end
    # 光标位置在 [确定] 以外的情况下
    else
      # 按下方向键右的情况下
      if Input.repeat?(Input::RIGHT)
        # 按下状态不是重复的情况下、
        # 光标位置不在右端的情况下
        #if Input.trigger?(Input::RIGHT) or
        #   @index / 50 < 3 or @index % 5 < 4
          # 光标向右移动
          if @index % 5 < 4
            @index += 1
          else
            if @index > 150
              @index -= 154
            elsif @index > 134 && @index < 150
              @index -= 104
            else
              @index += 50 - 4
            end
          end
        end
        #end
      # 按下方向键左的情况下
      if Input.repeat?(Input::LEFT)
        # 按下状态不是重复的情况下、
        # 光标位置不在左端的情况下
        #if Input.trigger?(Input::LEFT) or
          # @index / 50 > 0 or @index % 5 > 0
          # 光标向右移动
          if @index % 5 > 0
            @index -= 1
          else
            if @index < 35
              @index += 154
            elsif @index >= 35 && @index < 50
              @index += 104
            else
              @index -= 50 - 4
            end
          end
        #end
      end
      # 按下方向键下的情况下
      if Input.repeat?(Input::DOWN)
        # 光标向下移动
        if !([180, 181, 182, 183, 184].include?(@index))
          if @index % 50 < 45
            @index += 5
          else
            #@index += 180 - 45
            @index = (50 * (@index / 50) + @index % 5)
          end
        else
          @index = 201
        end
      end
      # 按下方向键上的情况下
      if Input.repeat?(Input::UP)
        # 按下状态不是重复的情况下、
        # 光标位置不在上端的情况下
        #if Input.trigger?(Input::UP) or @index % 50 >= 5
          # 光标向上移动
          if @index % 50 >= 5
            @index -= 5
          else
            #@index += 180
            if @index >= 149 && @index <= 154
              @index += 30
            else
              @index = (50 * (@index / 50 + 1) - (5 - @index % 5))
            end
          end
        #end
      end
    end
    update_cursor_rect
  end
end