class Window_MusicBox < Window_Base
  include MM_DataBase
  
  attr_accessor :cursor_index
  
  def initialize(music_list)
    super(200, 300, 560, 200)
    self.back_opacity = 0
    self.opacity = 0
    self.z = 9999
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 200
    @cursor.y = 325
    @cursor.z = 9998
    @cursor_index = 0
    @music_list = music_list
    refresh
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
    for i in 0...@music_list.size
      music_ary = @music_list[i]
      self.contents.draw_text(20,25 * i,120, 48, music_ary[0])
    end
  end
  
  def update
    super
    if Input.trigger?(Input::DOWN)
      if @cursor_index < @music_list.size - 1
        @cursor_index += 1
      end
    end
    
    if Input.trigger?(Input::UP)
      if @cursor_index > 0
        @cursor_index -= 1
      end
    end
    
    @cursor.x = 200
    @cursor.y = 325 + 25 * @cursor_index
    
  end
end