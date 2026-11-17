class Window_IMMessage < Window_Base
  
  include MM_DataBase
  include MM_System
  
  def initialize(message, message_type = nil)
    super(0, 0, 440, 480)
    @message = message
    @message_type = message_type
    self.opacity = 255
    self.back_opacity = 255
    refresh
  end
  
  def refresh
    self.height = (@message.split(//).size / 20 + 1) * 24 + 48
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    str_ary = []
    str = ""
    msg_ary = @message.split(//)
    if @message.size > 20
      for i in 0...msg_ary.size
        str += msg_ary[i]
        if i % 20 == 0 && i != 0
          str_ary.push(str)
          str = ""
        end
      end
      if str != ""
        str_ary.push(str)
      end
    end
    for i in 0...str_ary.size
      y = i * 24
      self.contents.draw_text(16, y, 420, 32, str_ary[i], 1)
    end
  end
  
  def enter_msg_pro(auto_time = 0)
    if block_given?
      yield
    end
    if auto_time != 0
      for i in 0...auto_time
        Input.update
        Graphics.update
      end
      return
    end
    loop do
      Graphics.update
      Input.update
      update
      if Input.trigger?(Input::C)
        return IMMSG_EXIT
      end
    end
  end
  
  def reset_message(msg, msg_type = nil)
    @message = msg
    @message_type = msg_type
    refresh
  end
  
  def update
    super
  end
end