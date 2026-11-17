class Scene_Save
  
  include MM_DataBase
  include MM_System
  
  def main
    
    @message_window = Window_Message.new
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8001
    
    @save_file_select_window = Window_SaveFileSelect.new(get_param_ary)
    @save_file_select_window.active = false
    @save_file_select_window.visible = false
    @save_file_select_window.z = 8003
    
    @spriteset_map = Spriteset_Map.new
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @message_window.dispose
    @save_file_select_window.dispose
    
    @yes_no_window.dispose if @yes_no_window != nil
    
    @spriteset_map.dispose
  end
  
  def get_param_ary
    param_ary = []
    for i in 0..1
      filename = "Save/" + make_filename(i)
      if FileTest.exist?(filename)
        file = File.open(filename, "r")
        param = Marshal.load(file)
        param_ary.push(param[0])
        file.close
      else
        param_ary.push(nil)
      end
    end
    return param_ary
  end
  
  def update
    
    show_message("这里是探险家们战斗记录的中心。", true)
    show_message("是否存游戏？")
    result = show_yes_no_window
    case result
    when RESULT_YES
      if $game_system.have_saved
        index = $game_system.self_file_index
      else
        show_message("存入哪里？")
        @save_file_select_window.visible = true
        @save_file_select_window.active = true
        loop do
          Graphics.update
          Input.update
          @save_file_select_window.update
          if Input.trigger?(Input::C)
            break
          end
        end
        @save_file_select_window.active = false
        @save_file_select_window.visible = false
        index = @save_file_select_window.result
        $game_system.self_file_index = index
        $game_system.have_saved = true
      end
      show_message("吱…吱…", true)
      save_file(index)
      show_message("存储完毕，要继续游戏吗？")
      result = show_yes_no_window
      case result
      when RESULT_NO
        show_message("按RESET键或是把开关关了。", true)
        show_message("晚安，可爱的勇士。", true)
        update_end
        return
      when RESULT_YES
        show_message("请慢走，小心点。")
        $scene = Scene_Map.new
        return
      end
    when RESULT_NO
      show_message("游戏结束的时候，在这里做一下记录。", true)
      show_message("要不然就白辛苦了。", true)
      $scene = Scene_Map.new
      return
    end
  end
  
  def save_file(file_index)
    filename = make_filename(file_index)
    file = File.open("Save/" + filename, "wb")
    # 生成描绘存档文件用的角色图形
    #characters = []
    #for i in 0...$game_party.actors.size
    #  actor = $game_party.actors[i]
    #  characters.push([actor.character_name, actor.character_hue])
    #end
    # 写入描绘存档文件用的角色数据
    #Marshal.dump(characters, file)
    
    param_ary = [$game_party.actors[0].name, $game_party.actors[0].level]
    
    Marshal.dump(param_ary, file)
    # 写入测量游戏时间用画面计数
    Marshal.dump(Graphics.frame_count, file)
    # 增加 1 次存档次数
    $game_system.save_count += 1
    # 保存魔法编号
    # (将编辑器保存的值以随机值替换)
    $game_system.magic_number = $data_system.magic_number
    # 写入各种游戏对像
    Marshal.dump($game_plugin_states)
    Marshal.dump($game_system, file)
    Marshal.dump($game_switches, file)
    Marshal.dump($game_variables, file)
    Marshal.dump($game_self_switches, file)
    Marshal.dump($game_screen, file)
    Marshal.dump($game_actors, file)
    Marshal.dump($game_tanks, file)
    Marshal.dump($game_party, file)
    Marshal.dump($game_troop, file)
    Marshal.dump($game_map, file)
    Marshal.dump($game_players, file)
    Marshal.dump($game_maps, file)
    
    Marshal.dump($game_plugin_states, file)
    
    file.close
  end
  
  def update_end
    Audio.bgm_stop
    Audio.bgs_stop
    @sprite_end_back = Sprite.new
    @sprite_end_back.bitmap = RPG::Cache.picture(PICTURE_RESETOREND)
    @sprite_end_back.z = 9999
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      @sprite_end_back.update
      if Input.trigger?(Input::C)
        break
      end
    end
    @sprite_end_back.bitmap.dispose
    @sprite_end_back.dispose
    $scene = nil
    return
  end
  
  def make_filename(file_index)
    return "Save#{file_index + 1}.rxdata"
  end
  
  def show_yes_no_window
    @yes_no_window = Window_YesOrNo.new
    loop do
      Graphics.update
      Input.update
      @yes_no_window.update
      if Input.trigger?(Input::C)
        break
      end
    end
    @yes_no_window.visible = false
    return @yes_no_window.result
  end
  
  def show_message(msg, wait = false)
    @message_window.terminate_message
    $game_temp.message_text = msg
    loop do
      Graphics.update
      Input.update
      @message_window.update
      if @message_window.at_end
        break
      end
    end
    if wait == true
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
    end
    
    return
    
  end
  
end