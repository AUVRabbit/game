class Scene_Plugin
  
  include MM_DataBase
  include MM_System
  include PluginModule
  
  def main
    
    $game_plugins.refreshPlugins()
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_PLUGIN_BACK)
    
    @list_window = Window_PluginList.new
    @list_window.active = true
    
    @info_window = Window_PluginInfo.new
    
    @info_window.refresh_plugin(@list_window.plugin)
    @immenu_window = Window_IMMenu.new(["停止", "删除"])
    @immenu_window.x = 200
    @immenu_window.y = 150
    @immenu_window.visible = false
    @immenu_window.active = false
    
    @immsg_window = Window_IMMessage.new("正在启动中，请稍候。")
    @immsg_window.x = 100
    @immsg_window.y = 150
    @immsg_window.visible = false
    @immsg_window.active = false
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新信息
      update
      # 如果画面切换就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @immenu_window.dispose
    @immsg_window.dispose
    
    @info_window.dispose
    @list_window.dispose
  end
  
  def update
    @info_window.update
    @list_window.update
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::UP)\
      || Input.trigger?(Input::DOWN)
      @info_window.refresh_plugin(@list_window.plugin)
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if $game_plugins.getPluginRegistDataBase().size == 0
        return
      end
        
      @plugin = @list_window.plugin
      if @plugin.state == PLUGINSTATE_ON
        @immenu_window.reset_menulist(["停止", "卸载"])
      elsif @plugin.state == PLUGINSTATE_OFF
        @immenu_window.reset_menulist(["启动", "卸载"])
      end
      @immenu_window.visible = true
      @immenu_window.active = true
      result = @immenu_window.enter_menu_pro
      case result
      when IMEMENU_EXIT
        @immenu_window.visible = false
        @immenu_window.active = false
        @immenu_window.reset_cursor
        return
      when 1
        @immenu_window.visible = false
        @immenu_window.active = false
        case @plugin.state
        when PLUGINSTATE_ON
          @immsg_window.visible = true
          @immsg_window.active = true
          @immsg_window.reset_message("正在停止插件，请等待……")
          result = @immsg_window.enter_msg_pro(60) do
            @plugin.setState(PLUGINSTATE_OFF)
            @list_window.shell_plugin.recover()
          end
          @immsg_window.reset_message("插件成功停止！")
          @immsg_window.enter_msg_pro
          @immsg_window.visible = false
          @immsg_window.active = false
          @info_window.refresh_plugin(@list_window.plugin)
          @list_window.refresh
        when PLUGINSTATE_OFF
          @immsg_window.visible = true
          @immsg_window.active = true
          @immsg_window.reset_message("正在启动插件，请等待……")
          result = @immsg_window.enter_msg_pro(60) do
            @plugin.setState(PLUGINSTATE_ON)
            @list_window.shell_plugin.main()
          end
          @immsg_window.reset_message("插件成功启动！")
          @immsg_window.enter_msg_pro
          @immsg_window.visible = false
          @immsg_window.active = false
          @info_window.refresh_plugin(@list_window.plugin)
          @list_window.refresh
        end
      when 2
        @immenu_window.visible = false
        @immenu_window.active = false
        case @plugin.state
        when PLUGINSTATE_ON
          @immsg_window.visible = true
          @immsg_window.active = true
          @immsg_window.reset_message("正在停止插件，请等待……")
          result = @immsg_window.enter_msg_pro(60) do
            @plugin.setState(PLUGINSTATE_OFF)
            @list_window.shell_plugin.recover()
          end
          @immsg_window.reset_message("插件成功停止！")
          @immsg_window.enter_msg_pro(60)
          @info_window.refresh_plugin(@list_window.plugin)
          @list_window.refresh
          
          @immsg_window.reset_message("正在卸载插件，请等待……")
          @delete_result = false
          result = @immsg_window.enter_msg_pro(60) do
            folder_path = @plugin.iniFilePath
            begin
              @delete_result = delete_dir(folder_path.gsub(/\/set\.ini/, ""))
            rescue
              @delete_result = false
            end
          end
          
          if @delete_result == false
            @immsg_window.reset_message("插件卸载失败，您可以尝试手动在目录下删除。")
            @immsg_window.enter_msg_pro
          else
            @immsg_window.reset_message("插件卸载成功！")
            @immsg_window.enter_msg_pro
          end
          
        when PLUGINSTATE_OFF
          @immsg_window.reset_message("正在卸载插件，请等待……")
          @delete_result = false
          result = @immsg_window.enter_msg_pro(60) do
            folder_path = @plugin.iniFilePath
            begin
              @delete_result = delete_dir(folder_path.gsub(/\/set\.ini/, ""))
            rescue
              @delete_result = false
            end
          end
          
          if @delete_result == false
            @immsg_window.reset_message("插件卸载失败，您可以尝试手动在目录下删除。")
            @immsg_window.enter_msg_pro
          else
            @immsg_window.reset_message("插件卸载成功！")
            @immsg_window.enter_msg_pro
          end
          
        end
        
        @immsg_window.visible = false
        @immsg_window.active = false
        @immenu_window.reset_cursor
        
        $game_plugins.refreshPlugins()
        @list_window.refresh_keys
        @list_window.refresh
        @info_window.refresh_plugin(@list_window.plugin)
      end
    end
    
  end
  
  
  def delete_dir(file_path)
    if File.directory?(file_path)
      Dir.foreach(file_path) do |file|
        if file != "." and file != ".."
          delete_dir(file_path + "/" + file)
        end
      end
      Dir.rmdir(file_path)
    else
      File.delete(file_path)
    end
  end
  
end