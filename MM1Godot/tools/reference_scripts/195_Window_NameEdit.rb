#==============================================================================
# ■ Window_NameEdit
#------------------------------------------------------------------------------
# 　名称输入画面、编辑名称的窗口。
#==============================================================================

class Window_NameEdit < Window_Base
  
  include MM_DataBase
  
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_reader   :name                     # 名称
  attr_accessor :index                    # 光标位置
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     actor    : 角色
  #     max_char : 最大字数
  #--------------------------------------------------------------------------
  def initialize(actor, max_char)
    super(0, 0, 640, 128)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_NAME)
    
    @actor = actor
    @name = actor.name
    @max_char = max_char
    # 控制名字在最大字数以内
    name_array = @name.split(//)[0...@max_char]
    @name = ""
    for i in 0...name_array.size
      @name += name_array[i]
    end
    @default_name = @name
    @index = name_array.size
    refresh
    update_cursor_rect
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def name
    return @name.strip
  end
  
  #--------------------------------------------------------------------------
  # ● 还原为默认的名称
  #--------------------------------------------------------------------------
  def restore_default
    @name = @default_name
    @index = @name.split(//).size
    refresh
    update_cursor_rect
  end
  
  #--------------------------------------------------------------------------
  # ● 添加文字
  #     character : 要添加的文字
  #--------------------------------------------------------------------------
  def add(character)
    if @index < @max_char and character != ""
      @name += character
      @index += 1
      refresh
      update_cursor_rect
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 删除文字
  #--------------------------------------------------------------------------
  def back
    if @index > 0
      # 删除一个字
      name_array = @name.split(//)
      @name = ""
      for i in 0...name_array.size-1
        @name += name_array[i]
      end
      @index -= 1
      refresh
      update_cursor_rect
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    # 描绘名称
    name_array = @name.split(//)
    for i in 0...@max_char
      c = name_array[i]
      if c == nil
        c = "＿"
      end
      x = 320 - @max_char * 14 + i * 28 - 60
      self.contents.draw_text(x, 48, 56, 32, c, 1)
    end
    # 描绘图形
    if @actor.is_a?(Game_Tank)
      draw_actor_graphic(@actor, 320 - @max_char * 14 - 32, 80)
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    x = 320 - @max_char * 14 + @index * 28 - 52
    
    if @index == 0
      x = 320 - 1 * 14 + @index * 28 - 52
    else
      @sprite_cursor.x = x
      @sprite_cursor.y = 85
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_cursor_rect
  end
end