class Scene_Machine

  def main_machine_password
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MACHINE_PASSWORD)
    @sprite_back.z = 8001
    
    @keyboard_window = Window_MachineCommonKeyboard.new
    @keyboard_window.visible = true
    @keyboard_window.active = true
    @keyboard_window.z = 8003
    
    @password_window = Window_MachinePasswordText.new($game_temp.machine_password.split(//).size)
    @password_window.visible = true
    @password_window.active = true
    @password_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update_password
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @keyboard_window.dispose
    @password_window.dispose
    
  end
  
  def update_password
    @keyboard_window.update
    @password_window.update
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if @keyboard_window.index == 12
        @password_window.back
        return
      elsif @keyboard_window.index == 14
        $game_temp.machine_password_result = (@password_window.password == $game_temp.machine_password)
        $scene = Scene_Map.new
        return
      elsif [3, 7, 13].include?(@keyboard_window.index)
        return
      else
        @password_window.add(@keyboard_window.character)
        return
      end
    end
    
#    if Input.trigger?(Input::B)
#      $game_system.se_play($data_system.cancel_se)
#      $game_temp.machine_password_result = false
#      $scene = Scene_Map.new
#      return
#    end
  end
end