class Scene_Load
  include MM_DataBase
  include MM_System
  
  def main
    
    @cursor_index = 0
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_LOAD_BACK)
    @sprite_back.z = 8001
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.z = 8002
    
    param_ary = get_param_ary
    
    @load_window = Window_LoadList.new(param_ary)
    @load_window.z = 8002
    @load_window.active = false
    @load_window.visible = true
        
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
    
    @load_window.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def update
    @load_window.update
    
    if @load_window.visible && @load_window.active
      update_load
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if @load_window.result == LOADCOMMAND_RESTART
        # 停止 BGM
        Audio.bgm_stop
        # 重置测量游戏时间用的画面计数器
        Graphics.frame_count = 0
        # 生成各种游戏对像
        $game_temp          = Game_Temp.new
        $game_system        = Game_System.new
        $game_switches      = Game_Switches.new
        $game_variables     = Game_Variables.new
        $game_self_switches = Game_SelfSwitches.new
        $game_screen        = Game_Screen.new
        $game_actors        = Game_Actors.new
        $game_tanks         = Game_Tanks.new
        $game_party         = Game_Party.new
        $game_troop         = Game_Troop.new
        $game_map           = Game_Map.new
        $game_players       = Game_Players.new
        $game_maps          = Game_Maps.new
    
        $game_plugins       = PluginManager.new
        
        $game_plugin_states = {}
        
        #插件注册
        PluginModule.registPlugins()
                
        # 设置初期同伴位置
        $game_party.setup_starting_members
        # 设置初期位置的地图
        $game_map.setup($data_system.start_map_id)
        # 主角向初期位置移动
    
        $game_players.reset
    
        $game_players.moveto($data_system.start_x, $data_system.start_y)
        # 刷新主角
        $game_players.refresh
        # 执行地图设置的 BGM 与 BGS 的自动切换
        $game_map.autoplay
        # 刷新地图 (执行并行事件)
        $game_map.update
        # 切换地图画面
        $scene = Scene_Name.new($game_party.actors[0])
        return
      else
        @load_window.active = true
      end
      return
    end
        
    if Input.trigger?(Input::LEFT)
      @cursor_index -= 1 if @cursor_index > 0
    end
    
    if Input.trigger?(Input::RIGHT)
      @cursor_index += 1 if @cursor_index < 3
    end    
    
    if Input.trigger?(Input::UP)
      @cursor_index -= 2 if @cursor_index > 1
    end
    
    if Input.trigger?(Input::DOWN)
      @cursor_index += 2 if @cursor_index < 2
    end
    
    @sprite_cursor.x = 95 + @cursor_index % 2 * 240
    @sprite_cursor.y = 325 + @cursor_index / 2 * 64
  end
  
  def get_param_ary
    param_ary = []
    for i in 0..1
      filename = "Save/" + make_filename(i)
      if FileTest.exist?(filename)
        file = File.open(filename, "r")
        param = Marshal.load(file)
        param_ary.push(param)
        file.close
      else
        param_ary.push(nil)
      end
    end
    return param_ary
  end
  
  def update_load
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @load_window.active = false
      return
    end
    
    if Input.trigger?(Input::C)
      tp_system = Game_System.new
      tp_system.se_play($data_system.decision_se)
      case @cursor_index
      when LOADCOMMAND_COUNTINUE
        return unless FileTest.exist?("Save/" + make_filename(@load_window.result))
        load_file(@load_window.result)
        # 还原 BGM、BGS
        $game_system.bgm_play($game_system.playing_bgm)
        $game_system.bgs_play($game_system.playing_bgs)
        # 刷新地图 (执行并行事件)
        $game_map.update
        # 切换到地图画面
        $scene = Scene_Map.new
        return
      when LOADCOMMAND_MOVE
        return if FileTest.exist?("Save/" + make_filename(@load_window.result))
        #打開 讀入 寫出 關閉 刪除
        file = File.open("Save/" + make_filename(@load_window.result == 0 ? 1 : 0), "r")
        
        # 读取描绘存档文件用的角色数据
        param_ary = Marshal.load(file)
        # 读取测量游戏时间用画面计数
        Graphics.frame_count = Marshal.load(file)
        # 读取各种游戏对像    
        $game_system        = Marshal.load(file)
        $game_switches      = Marshal.load(file)
        $game_variables     = Marshal.load(file)
        $game_self_switches = Marshal.load(file)
        $game_screen        = Marshal.load(file)
        $game_actors        = Marshal.load(file)
        $game_tanks         = Marshal.load(file)
        $game_party         = Marshal.load(file)
        $game_troop         = Marshal.load(file)
        $game_map           = Marshal.load(file)
        $game_players       = Marshal.load(file)
        $game_maps          = Marshal.load(file)
        
        $game_plugin_states = Marshal.load(file)
        
        #$game_plugins       = Marshal.load(file)
        file.close
        
        File.delete("Save/" + make_filename(@load_window.result == 0 ? 1 : 0))
        
        file = File.open("Save/" + make_filename(@load_window.result), "wb")
        
        Marshal.dump(param_ary, file)
        # 写入测量游戏时间用画面计数
        Marshal.dump(Graphics.frame_count, file)
        # 增加 1 次存档次数
        $game_system.save_count += 1
        # 保存魔法编号
        # (将编辑器保存的值以随机值替换)
        $game_system.magic_number = $data_system.magic_number
        # 写入各种游戏对像
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
        #Marshal.dump($game_plugins, file)
    
        file.close
        @load_window.refresh_param(get_param_ary)
        return
      when LOADCOMMAND_DELETE
        return unless FileTest.exist?("Save/" + make_filename(@load_window.result))
        File.delete("Save/" + make_filename(@load_window.result))
        @load_window.refresh_param(get_param_ary)
        return
      end
    end
    
  end
  
  def load_file(index)
    filename = make_filename(index)
    file = File.open("Save/" + filename, "r")
    # 读取描绘存档文件用的角色数据
    param_ary = Marshal.load(file)
    # 读取测量游戏时间用画面计数
    Graphics.frame_count = Marshal.load(file)
    # 读取各种游戏对像    
    $game_system        = Marshal.load(file)
    $game_switches      = Marshal.load(file)
    $game_variables     = Marshal.load(file)
    $game_self_switches = Marshal.load(file)
    $game_screen        = Marshal.load(file)
    $game_actors        = Marshal.load(file)
    $game_tanks         = Marshal.load(file)
    $game_party         = Marshal.load(file)
    $game_troop         = Marshal.load(file)
    $game_map           = Marshal.load(file)
    $game_players       = Marshal.load(file)
    $game_maps          = Marshal.load(file)
    
    $game_plugins       = PluginManager.new
    
    $game_plugin_states = Marshal.load(file)
    
    #插件注册
    PluginModule.registPlugins()
    
    #$game_plugins       = Marshal.load(file)
    
    # 魔法编号与保存时有差异的情况下
    # (加入编辑器的编辑过的数据)
    if $game_system.magic_number != $data_system.magic_number
      # 重新装载地图
      $game_map.setup($game_map.map_id)
      $game_players.center($game_players.head_player.x, $game_players.head_player.y)
    end
    # 刷新同伴成员
    $game_party.refresh
    
  end
  
  #--------------------------------------------------------------------------
  # ● 生成文件名
  #     file_index : 文件名的索引 (0～1)
  #--------------------------------------------------------------------------
  def make_filename(file_index)
    return "Save#{file_index + 1}.rxdata"
  end
  
end