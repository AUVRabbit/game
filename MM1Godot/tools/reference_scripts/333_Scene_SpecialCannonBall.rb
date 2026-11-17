class Scene_SpecialCannonBall
  include MM_DataBase
  include MM_System
  def main
    $game_party.set_cpl_party
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_SPECIALCANNONBALL_BACK)
    
    @special_cannonball_status_window = Window_SpecialCannonBallStatus.new($game_party.tanks[0])
    
    @special_cannonball_window = Window_SpecialCannonBall.new($game_party.tanks[0])
    
    @target_select_window = Window_EquipPassTankTargetSelect.new
   
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面
      update
      # 如果切换画面就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @special_cannonball_window.dispose
    @special_cannonball_status_window.dispose
    @target_select_window.dispose
    
    $game_party.recover_org_party
  end
  
  def update
    @special_cannonball_window.update
    @special_cannonball_status_window.update
    @target_select_window.update
    if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
      tank = $game_party.tanks[@target_select_window.tank_index]
      @special_cannonball_window.refresh_tank(tank)
      @special_cannonball_status_window.refresh(tank)
      return
    end
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return
    end
  end
end