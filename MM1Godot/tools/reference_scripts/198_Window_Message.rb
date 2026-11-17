class Window_Message < Window_Base
  
  include MM_System
  include MM_DataBase
  
  attr_reader :at_end
  
  #--------------------------------------------------------------------------
  # ● 初始化状态
  #--------------------------------------------------------------------------
  def initialize
    super(80, 304, 440, 180)
    self.back_opacity = 0
    self.opacity = 0
    case $game_temp.message_type
    when MESSAGE_TALK
      self.x = 240
      self.y = 300
    when MESSAGE_MOVIE
      self.x = 80
      self.y = 304
    when MESSAGE_BATTLE
      self.x = 0
      self.y = 320
    end
    
    if $game_temp.in_battle
      self.x = 0
      self.y = 320
    end
    
    #描绘用Sprite
    @sprite_texts = []
    4.times do
      sprite = Sprite.new
      sprite.bitmap = Bitmap.new(640, 180)
      sprite.bitmap.font.size = 20
      sprite.z = 9999
      @sprite_texts.push(sprite)
    end
    
    @sprite_texts[0].x = self.x + 40 - 10
    @sprite_texts[0].y = self.y + 20
    
    @sprite_texts[1].x = self.x + 40 - 10
    @sprite_texts[1].y = self.y + 20 + 20
    
    @sprite_texts[2].x = self.x + 40 - 10
    @sprite_texts[2].y = self.y + 20 + 40
    
    @sprite_texts[3].x = self.x + 40 - 10
    @sprite_texts[3].y = self.y + 20 + 60
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.visible = false
    @sprite_cursor.z = 9999
    
    @sprite_dialog_wait = Sprite.new
    @sprite_dialog_wait.bitmap = RPG::Cache.picture(PICTURE_DIALOG_WAIT)
    @sprite_dialog_wait.visible = false
    @sprite_dialog_wait.z = 9999
    @sprite_dialog_wait.x = 380
    @sprite_dialog_wait.y = 440
    
    @sprite_dialog_movie = Sprite.new
    @sprite_dialog_movie.bitmap = RPG::Cache.picture(PICTURE_DIALOG_MOVIE)
    @sprite_dialog_movie.x= 0
    @sprite_dialog_movie.y = 310
    @sprite_dialog_movie.z = 9998
    @sprite_dialog_movie.visible = false
    
    self.contents = Bitmap.new(width - 32, height - 32)
    self.visible = false
    self.z = 9998
    @fade_in = false
    @fade_out = false
    @contents_showing = false
    @cursor_width = 0
    self.active = false
    #self.index = -1
  end
    
  #def visible=(value)
  #  super
    #@sprite_dialog_wait.visible = false if !@sprite_dialog_wait.disposed?
  #end
  
  def x=(value)
    super
    if @sprite_texts == nil
      return
    end
    @sprite_texts[0].x = self.x + 40 - 10
    @sprite_texts[0].y = self.y + 20
    
    @sprite_texts[1].x = self.x + 40 - 10
    @sprite_texts[1].y = self.y + 20 + 20
    
    @sprite_texts[2].x = self.x + 40 - 10
    @sprite_texts[2].y = self.y + 20 + 40
    
    @sprite_texts[3].x = self.x + 40 - 10
    @sprite_texts[3].y = self.y + 20 + 60
  end
  
  def y=(value)
    super
    if @sprite_texts == nil
      return
    end
    @sprite_texts[0].x = self.x + 40 - 10
    @sprite_texts[0].y = self.y + 20
    
    @sprite_texts[1].x = self.x + 40 - 10
    @sprite_texts[1].y = self.y + 20 + 20
    
    @sprite_texts[2].x = self.x + 40 - 10
    @sprite_texts[2].y = self.y + 20 + 40
    
    @sprite_texts[3].x = self.x + 40 - 10
    @sprite_texts[3].y = self.y + 20 + 60
  end
  
  def set_pos
    case $game_temp.message_type
    when MESSAGE_TALK
      self.x = 240
      self.y = 300
      if $game_temp.in_battle
        self.y += 20
      end
    when MESSAGE_MOVIE
      self.x = 80
      self.y = 330
    when MESSAGE_BATTLE
      self.x = 0
      self.y = 320
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    terminate_message
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
    
    @sprite_dialog_wait.bitmap.dispose
    @sprite_dialog_wait.dispose
    
    @sprite_dialog_movie.bitmap.dispose
    @sprite_dialog_movie.dispose
        
    @sprite_texts.each do |sprite|
      sprite.bitmap.dispose
      sprite.dispose
    end
    $game_temp.message_window_showing = false
    if @input_number_window != nil
      @input_number_window.dispose
    end
    super
  end
  
  #--------------------------------------------------------------------------
  # ● 处理信息结束
  #--------------------------------------------------------------------------
  def terminate_message
    self.active = false
    self.pause = false
#    self.index = -1
    self.contents.clear
    
    if $game_temp.message_type != MESSAGE_MOVIE
      @sprite_dialog_movie.visible = false
    end
        
    @sprite_cursor.visible = false if !@sprite_cursor.bitmap.disposed?
    
    @char_index = nil
    @str_ary = nil
    @str = nil
    @at_end = nil
    @selectable = nil

    if !$game_temp.in_battle || $game_temp.clear_message_battle
      @sprite_dialog_wait.visible = false if !@sprite_dialog_wait.bitmap.disposed?
    
      @sprite_texts.each do |sprite|
        sprite.bitmap.clear if !sprite.bitmap.disposed?
      end
      
      @now_draw_sprite = nil
      @now_draw_sprite_index = nil
    end
    
    # 清除显示中标志
    @contents_showing = false
    # 呼叫信息调用
    if $game_temp.message_proc != nil
      $game_temp.message_proc.call
    end
    # 清除文章、选择项、输入数值的相关变量
    $game_temp.message_text = nil
    $game_temp.message_proc = nil
    $game_temp.choice_start = 99
    $game_temp.choice_max = 0
    $game_temp.choice_cancel_type = 0
    $game_temp.choice_proc = nil
    $game_temp.num_input_start = 99
    $game_temp.num_input_variable_id = 0
    $game_temp.num_input_digits_max = 0
    $game_temp.clear_message_battle = false
    
    if !$scene.is_a?(Scene_Menu)
      Input.update
    end
    return
  end
    
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    super
    
    if $game_temp.message_type == MESSAGE_MOVIE
      @sprite_dialog_movie.visible = true
      set_pos
    elsif $game_temp.in_battle
      set_pos
    else
      @sprite_dialog_movie.visible = false
      set_pos
    end
    
    #優先考慮數字輸入窗口
    if $game_temp.num_input_variable_id > 0 && @input_number_window == nil
      $game_temp.message_window_showing = true
      digits_max = $game_temp.num_input_digits_max
      number = $game_variables[$game_temp.num_input_variable_id]
      @input_number_window = Window_InputNumber.new(digits_max)
      @input_number_window.visible = false
      @input_number_window.number = number
      @input_number_window.x = self.x + 96
      @input_number_window.y = self.y + 96
      return
    end
    
    if @selectable == true
      if Input.trigger?(Input::UP)
        if @select_index > 0
          @select_index -= 1
        end
      end
      if Input.trigger?(Input::DOWN)
        if @select_index < $game_temp.choice_max - 1
          @select_index += 1
        end
      end
      @sprite_cursor.y = @sprite_texts[@select_index + @start_position].y + 10
      #取消
      if Input.trigger?(Input::B)
        if $game_temp.choice_cancel_type > 0
          $game_system.se_play($data_system.cancel_se)
          $game_temp.choice_proc.call($game_temp.choice_cancel_type - 1)
          @selectable = nil
          terminate_message
        end
      end
      # 确定
      if Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        $game_temp.choice_proc.call(@select_index)
        @selectable = nil
        terminate_message
      end
      return
    end
    
    @char_index = 0 if @char_index == nil
    
    if $game_temp.message_text != nil
      $game_temp.message_text.chomp!
      @at_end = false if @at_end == nil
      
      $game_temp.message_window_showing = true
      @str = $game_temp.message_text
      #初始化
      @str_ary = @str.split(//m) if @str_ary == nil
      @str_ary.delete("\n")
      @now_draw_sprite = @sprite_texts[0] if @now_draw_sprite == nil
      @now_draw_sprite_index = 0 if @now_draw_sprite_index == nil
      
      #分割
      char = @str_ary[@char_index]
      
      case char
      when "\t"
        @output = true
        10.times {Graphics.update}
        #开始描绘选项
        #遍曆全部的選項，獲取選項文本，判斷需要清空的sprite的數量
        select_count = $game_temp.choice_max
        select_count -= 1
        select_ary = []
        str = ""
        while select_count >= -1
          if char == "\t"
            select_ary.push(str) if str != "\t" && str != ""
            str = ""
            select_count -= 1
          else
            str += char if char != nil
          end
          @char_index += 1
          char = @str_ary[@char_index]
        end
        #如果有剩餘Sprite
        row_num = @char_index / 7
        if 4 - (row_num % 4) >= $game_temp.choice_max
          #用倒數的sprite描繪
          drop_row_num = 4 - (row_num % 4)
          for i in 0...select_ary.size
            sprite = @sprite_texts[3 - (drop_row_num - i - 1)]
            sprite.bitmap.clear
            sprite.bitmap.draw_text(20, 0, 200, 48, select_ary[i])
          end
          #描繪完畢，進入輸入循環
          @sprite_cursor.visible = true
          @sprite_cursor.x = 250
          @start_position = row_num
          @sprite_cursor.y = @sprite_texts[drop_row_num].y + 10
          @select_index = 0
        else
          #倒過來描繪
          sub = $game_temp.choice_max - 4 - (row_num % 4)
          sub.times do
            sprite = @sprite_texts.shift
            sprite.y += 60
            for i in 0...3
              @sprite_texts[i].y -= 20
            end
            @sprite_texts.push(sprite)
          end
          for i in 0...select_ary.size
            sprite = @sprite_texts[4 - (select_ary.size - i)]
            sprite.bitmap.clear
            sprite.bitmap.draw_text(20, 0, 200, 48, select_ary[i])
          end
          @sprite_cursor.visible = true
          @sprite_cursor.x = 250
          @start_position = 4 - select_ary.size
          @sprite_cursor.y = @sprite_texts[4 - select_ary.size - 1].y + 10
          @select_index = 0
        end        
        @selectable = true
        return
      else
        if char == nil
          @at_end = true
          # 输入数值的情况下
          if @input_number_window != nil
            @input_number_window.visible = true if @input_number_window.visible == false
            @input_number_window.update
            if Input.trigger?(Input::C)
              $game_temp.message_window_showing = false
              $game_system.se_play($data_system.decision_se)
              $game_variables[$game_temp.num_input_variable_id] =
                @input_number_window.number
              $game_map.need_refresh = true
              # 释放输入数值窗口
              @input_number_window.dispose
              @input_number_window = nil
              terminate_message
            end
            return
          else
            if ($scene.is_a?(Scene_Map) || $scene.is_a?(Scene_Menu)) && $game_temp.force_message == false
              if Input.trigger?(Input::C)
                $game_temp.message_window_showing = false
                terminate_message
              end
            end
          end
          return
        end
        if char == "\n"
          @char_index += 1
          @output = nil
          return
        end
        #开始描绘文本
        
        #如果在戰鬥中
        if $game_temp.in_battle && !$game_temp.clear_message_battle
          if char == "|"
=begin
            loop do
              Graphics.update
              Input.update
              if Input.trigger?(Input::C)
                break
              end
            end
=end
            if @now_draw_sprite_index == 3
              @now_draw_sprite_index = 3
              #弹出栈顶
              temp_draw_sprite = @sprite_texts.shift
              temp_draw_sprite.bitmap.clear
              #移动到栈底
              @sprite_texts.push(temp_draw_sprite)
              @now_draw_sprite = temp_draw_sprite
              #循环
              @now_draw_sprite.y += 60
              for i in 0...3
                @sprite_texts[i].y -= 20
              end
              2.times {Graphics.update}
            else
              @now_draw_sprite_index += 1
              @now_draw_sprite = @sprite_texts[@now_draw_sprite_index]
              2.times {Graphics.update}
            end
            
            @char_x = 0#@now_draw_sprite.bitmap.text_size(char).width
            #@now_draw_sprite.bitmap.draw_text(@char_x, -10, 40, 64, char, 2)
            @char_index += 1
            return
          else
            if @char_x == nil
              @char_x = 0#@now_draw_sprite.bitmap.text_size(char).width
            else
              @char_x += @now_draw_sprite.bitmap.text_size(char).width
            end
            @now_draw_sprite.bitmap.draw_text(@char_x, -10, 40, 64, char, 2)
            @char_index += 1
            return
          end
          return
        end
        
        if @char_index % 7 == 0 && @char_index != 0
          #Sprite替换
          if @char_index / 7 >= 4
            if @char_index % 14 == 0
              if !Input.trigger?(Input::C)
                Graphics.update
                Input.update
                @sprite_dialog_wait.visible = true
                return
              else
                @sprite_dialog_wait.visible = false
              end
            end
            @now_draw_sprite_index = 3
            #弹出栈顶
            temp_draw_sprite = @sprite_texts.shift
            temp_draw_sprite.bitmap.clear
            #移动到栈底
            @sprite_texts.push(temp_draw_sprite)
            @now_draw_sprite = temp_draw_sprite
            #循环
            @now_draw_sprite.y += 60
            for i in 0...3
              @sprite_texts[i].y -= 20
            end
            2.times {Graphics.update}
=begin
            if @now_draw_sprite.bitmap.text_size(char).width < @now_draw_sprite.bitmap.text_size("我").width
              @char_x = (@char_index % 7) * @now_draw_sprite.bitmap.text_size(char).width * 2
            else
              @char_x = (@char_index % 7) * @now_draw_sprite.bitmap.text_size(char).width
            end
=end
            if @char_index % 7 == 0
              @char_x = @now_draw_sprite.bitmap.text_size(char).width
            else
              @char_x += @now_draw_sprite.bitmap.text_size(char).width
            end
            @now_draw_sprite.bitmap.draw_text(@char_x, -10, 40, 64, char, 2)
            @char_index += 1
          else
            @now_draw_sprite_index += 1 if @now_draw_sprite_index < 3
            @now_draw_sprite = @sprite_texts[@now_draw_sprite_index]
            if @char_index % 7 == 0
              @char_x = @now_draw_sprite.bitmap.text_size(char).width
            else
              @char_x += @now_draw_sprite.bitmap.text_size(char).width
            end
            2.times {Graphics.update}
            @now_draw_sprite.bitmap.draw_text(@char_x, -10, 40, 64, char, 2)
            @char_index += 1
          end
        else
          @now_draw_sprite = @sprite_texts[@now_draw_sprite_index]
          if @char_index % 7 == 0
            @char_x = @now_draw_sprite.bitmap.text_size(char).width
          else
            @char_x += @now_draw_sprite.bitmap.text_size(char).width
          end
          2.times {Graphics.update}
          @now_draw_sprite.bitmap.draw_text(@char_x, -10, 40, 64, char, 2)
          @char_index += 1
        end
      end
    end
  end
end