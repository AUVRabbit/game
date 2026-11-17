class Interpreter  
  #--------------------------------------------------------------------------
  # ● 显示文章
  #--------------------------------------------------------------------------
  def command_101
    # 另外的文章已经设置过 message_text 的情况下
    if $game_temp.message_text != nil
      # 结束
      return false
    end
    # 设置信息结束后待机和返回调用标志
    @message_waiting = true
    $game_temp.message_proc = Proc.new { @message_waiting = false }
    # message_text 设置为 1 行
    $game_temp.message_text = @list[@index].parameters[0] + "\n"
    line_count = 1
    # 循环
    loop do
      # 下一个事件指令为文章两行以上的情况
      if @list[@index+1].code == 401
        # message_text 添加到第 2 行以下
        $game_temp.message_text += @list[@index+1].parameters[0] + "\n"
        line_count += 1
      # 事件指令不在文章两行以下的情况
      else
        # 下一个事件指令为显示选择项的情况下
        if @list[@index+1].code == 102
          # 如果选择项能收纳在画面里
          #if @list[@index+1].parameters[0].size <= 4 - line_count
            # 推进索引
            @index += 1
            # 设置选择项
            $game_temp.choice_start = line_count
            setup_choices(@list[@index].parameters)
          #end
        # 下一个事件指令为处理输入数值的情况下
        elsif @list[@index+1].code == 103
          # 如果数值输入窗口能收纳在画面里
          #if line_count < 4
            # 推进索引
            @index += 1
            # 设置输入数值
            $game_temp.num_input_start = line_count
            $game_temp.num_input_variable_id = @list[@index].parameters[0]
            $game_temp.num_input_digits_max = @list[@index].parameters[1]
          #end
        end
        # 继续
        return true
      end
      # 推进索引
      @index += 1
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 设置选择项
  #--------------------------------------------------------------------------
  def setup_choices(parameters)
    # choice_max 为设置选择项的项目数
    $game_temp.choice_max = parameters[0].size
    # message_text 为设置选择项
    for i in 0...parameters[0].size
      text = parameters[0][i]
      if i == 0
        $game_temp.message_text += "\t" + text + "\t"
      else
        $game_temp.message_text += text + "\t"
      end
    end
    # 设置取消的情况的处理
    $game_temp.choice_cancel_type = parameters[1]
    # 返回调用设置
    current_indent = @list[@index].indent
    $game_temp.choice_proc = Proc.new { |n| @branch[current_indent] = n }
  end
  
  alias :old_execute :execute_command
  def execute_command
    # 到达执行内容列表末尾的情况下
    if @index >= @list.size - 1
      # 时间结束
      command_end
      # 继续
      return true
    end
    @parameters = @list[@index].parameters
    if @list[@index].code == 108
      return command_108 #注释的用法
    end
    old_execute
  end
  
  def command_108
    analyse_str = ""
    analyse_str = @list[@index].parameters[0]
    loop do
      if @list[@index + 1].parameters[0] != 8
        analyse_str += @list[@index + 1].parameters[0]
        @index += 1
      else
        break
      end
    end
    str_ary = analyse_str.split(/\n/)
    str = ""
    for i in 0...str_ary.size
      str += str_ary[i]
    end
    str_ary = str.split(/;/)
    for i in 0...str_ary.size
      str = str_ary[i]
      next if str == "" || str == nil
      
      #商店处理
      if /\s*清空列表\s*/ =~ str || /\s*ClearList\s*/ =~ str
        $game_temp.shop_goods.clear
      elsif /人类武器\s*=\s*\[(.+)\]/ =~ str || /Weapon\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_weapons[i.to_i])
        end
      elsif /人类防具\s*=\s*\[(.+)\]/ =~ str || /Armor\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_armors[i.to_i])
        end
      elsif /人类道具\s*=\s*\[(.+)\]/ =~ str || /PeopleItem\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_actor_items[i.to_i])
        end
      elsif /战车道具\s*=\s*\[(.+)\]/ =~ str || /TankItem\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_tank_items[i.to_i])
        end
      elsif /主炮\s*=\s*\[(.+)\]/ =~ str || /MainCannon\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_main_cannons[i.to_i])
        end
      elsif /副炮\s*=\s*\[(.+)\]/ =~ str || /SubCannon\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_sub_cannons[i.to_i])
        end
      elsif /SE\s*=\s*\[(.+)\]/ =~ str || /SE\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_ses[i.to_i])
        end
      elsif /C装置\s*=\s*\[(.+)\]/ =~ str || /CUnit\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_c_units[i.to_i])
        end
      elsif /引擎\s*=\s*\[(.+)\]/ =~ str || /Engine\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.shop_goods.push($data_engines[i.to_i])
        end
        
      #出租店处理
      elsif /出租战车\s*=\s*(.+)/ =~ str || /RentTank\s*=\s*(.+)/ =~ str
        tp_str = $1
        $game_temp.rent_tanks_id = tp_str.to_i
      #勇士办事处
      elsif /通缉犯\s*=\s*\[(.+)\]/ =~ str || /WantedPerson\s*=\s*\[(.+)\]/ =~ str
        tp_str = $1
        list = tp_str.split(/,|，/)
        for i in list
          $game_temp.wanted_list.push(i.to_i)
        end
      #炮弹商店
      elsif /炮弹\s*=\s*(.+)/ =~ str || /Cannonball\s*=\s*(.+)/ =~ str
        tp_str = $1
        $game_temp.cannonball_list = tp_str.to_i
      #音乐盒
      elsif /音乐盒\s*=\s*(.+)/ =~ str || /MusicBox\s*=\s*(.+)/ =~ str
        tp_str = $1
        $game_temp.music_list = tp_str.to_i
      #初始密码
      elsif /密码\s*=\s*(.+)/ =~ str || /Password\s*=\s*(.+)/ =~ str
        tp_str = $1
        $game_temp.music_list = tp_str
      end

    end
    
    return true
  end
end