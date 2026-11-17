class Window_MachinePasswordText < Window_Base
  include MM_DataBase
  
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor :index                    # 光标位置
  
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize(max_char)
    super(80, 90, 640, 128)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 0
    self.opacity = 0
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_DIALOG_NUMBER_DOWN_INPUT)
    @sprite_cursor.z = 9999
    
    @password = ""
    @max_char = max_char
    # 控制名字在最大字数以内
    @default_password = @password
    @index = 0
    refresh
    update_cursor_rect
  end
  
  def dispose
    super
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def password
    return @password.strip
  end
  
  #--------------------------------------------------------------------------
  # ● 还原为默认的名称
  #--------------------------------------------------------------------------
  def restore_default
    @password = @default_password
    @index = @password.split(//).size
    refresh
    update_cursor_rect
  end
  
  #--------------------------------------------------------------------------
  # ● 添加文字
  #     character : 要添加的文字
  #--------------------------------------------------------------------------
  def add(character)
    if @index < @max_char and character != ""
      @password += character
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
      password_array = @password.split(//)
      @password = ""
      for i in 0...password_array.size-1
        @password += password_array[i]
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
    password_array = @password.split(//)
    for i in 0...@max_char
      c = password_array[i]
      if c == nil
        c = "※"
      end
      x = 320 - @max_char * 14 + i * 28 - 60
      self.contents.draw_text(x, 48, 56, 32, c, 1)
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    x = self.x + 320 - @max_char * 14 + @index * 28 - 52
    
    if @index == 0
      x = self.x + 320 - @max_char * 14 + 1 * 28 - 52
      @sprite_cursor.x = x
      @sprite_cursor.y = 200
    else
      @sprite_cursor.x = x
      @sprite_cursor.y = 200
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