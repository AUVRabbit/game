class Scene_Machine
  
  def main_machine_lift
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MACHINE_LIFT)
    @sprite_back.z = 8001
    
    @lift_window = Window_MachineLift.new($game_temp.machine_lift_floor_count)
    @lift_window.visible = true
    @lift_window.active = true
    @lift_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update_lift
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @lift_window.dispose
  end
  
  def update_lift
    @lift_window.update
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      $game_temp.machine_lift_floor_result = @lift_window.result
      $scene = Scene_Map.enwe
      return
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $game_temp.machine_lift_floor_result = nil
      $scene = Scene_Map.enwe
      return
    end
  end
end