class Scene_Machine
  
  def main_machine_switch
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MACHINE_OPENCLOSESWITCH)
    @sprite_back.z = 8001
  
    @keyboard_window = Window_MachineCommonKeyboard.new
    @keyboard_window.visible = true
    @keyboard_window.active = true
    @keyboard_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update_switche
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @keyboard_window.dispose
  end
  
  def update_switch
    @keyboard_window.update
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      $game_temp.machine_switch_result = (@keyboard_window.index == 12)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return
    end
    
  end
end