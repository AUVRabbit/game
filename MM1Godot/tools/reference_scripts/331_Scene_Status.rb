class Scene_Status
  
  include MM_System
  include MM_DataBase
  
  def main
    
    $game_party.set_cpl_party
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_STATUS_BACK)
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(240, 48)
    @sprite_gold.bitmap.font.size = 28
    @sprite_gold.bitmap.draw_text(0, 0, 240, 48, $game_party.gold.to_i.to_s)
    @sprite_gold.x = 330
    @sprite_gold.y = 410
    
    @cursor = Sprite.new
    @cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @cursor.x = 240
    @cursor.y = 310
    
    @index = 0
    
    @actor_status_window = Window_StatusActor.new
    @tank_status_window = Window_StatusTank.new
    @target_select_window = Window_StatusTargetSelect.new
    @actor_status_look_window = Window_StatusActorLook.new($game_party.actors[0])
        
    if $game_party.tanks != []
      @tank_status_look_window = Window_StatusTankLook.new($game_party.tanks[0])
      @tank_status_look_window.set_sprite_visible(false)
      @tank_status_drop_window = Window_StatusTankDrop.new($game_party.tanks[0])
      @tank_status_tank_target_window = Window_StatusTankTargetSelect.new
    
      @message_window = Window_Message.new
      @message_window.z = 9999
      
      @sprite_drop_back = Sprite.new
      @sprite_drop_back.bitmap = RPG::Cache.picture(PICTURE_DIALOG_BACKUP)
      @sprite_drop_back.visible = false
      @sprite_drop_back.x = @message_window.x
      @sprite_drop_back.y = @message_window.y + 8
      @sprite_drop_back.z = 9997
    end
    
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
    @actor_status_window.dispose
    @tank_status_window.dispose
    @target_select_window.dispose
    @actor_status_look_window.dispose
    
    if $game_party.tanks != []
      
      @tank_status_look_window.dispose
      @tank_status_drop_window.dispose
      @tank_status_tank_target_window.dispose
    
      @window_yes_no.dispose if @window_yes_no != nil
      @message_window.dispose
      
      @sprite_drop_back.bitmap.dispose
      @sprite_drop_back.dispose
    end
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_gold.dispose
    @sprite_gold.bitmap.dispose
    @cursor.bitmap.dispose
    @cursor.dispose
    
  end
  
  def update
    @actor_status_window.update
    @tank_status_window.update
    @target_select_window.update
    @actor_status_look_window.update
    if $game_party.tanks != []
      @tank_status_look_window.update
      @tank_status_drop_window.update
      @tank_status_tank_target_window.update
      @message_window.update
    end
    
    if $game_party.tanks != []
      if @tank_status_tank_target_window.visible == true
        update_status_tank_target
        return
      end
    end
    
    if $game_party.tanks != []
      if @tank_status_drop_window.visible == true
        update_status_drop
        return
      end
    end
    
    if @target_select_window.visible == true
      update_target_select
      return
    end
    
    if @actor_status_look_window.visible == true
      update_actor_look
      return
    end
    
    if $game_party.tanks != []
      if @tank_status_look_window.visible == true
        update_tank_look
        return
      end
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $game_party.recover_org_party
      $scene = Scene_Map.new
      return
    end

    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @index
      when 0
        @cursor.visible = false
        @target_select_window.cursor.visible = true
        @target_select_window.visible = true
      when 1
        if $game_party.tanks == []
          return
        end
        @cursor.visible = false
        @tank_status_tank_target_window.cursor.visible = true
        @tank_status_tank_target_window.visible = true
      when 2
      end
      return
    end
    
    if Input.trigger?(Input::DOWN)
      if @index < 2
        $game_system.se_play($data_system.cursor_se)
        @index += 1
      end
    end
    
    if Input.trigger?(Input::UP)
      if @index > 0
        $game_system.se_play($data_system.cursor_se)
        @index -= 1
      end
    end
    
    @cursor.y = 310 + @index * 36
  end
  
  # 状态查看对象选择
  def update_target_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @cursor.visible = true
      @target_select_window.visible = false
      @target_select_window.cursor.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if @target_select_window.now == TARGET_LEFT
        @target_select_window.visible = false 
        @target_select_window.cursor.visible = false
        actor = $game_party.actors[@target_select_window.actor_index]
        @actor_status_look_window.refresh_people(actor)
        @actor_status_look_window.visible = true
        @sprite_back.visible = false
      elsif @target_select_window.now == TARGET_RIGHT
        @target_select_window.visible = false 
        @target_select_window.cursor.visible = false
        tank = $game_party.tanks[@target_select_window.tank_index]
        @tank_status_look_window.refresh_tank(tank)
        @tank_status_look_window.visible = true
        @sprite_back.visible = false
        @tank_status_look_window.set_sprite_visible(true)
      end
      return
    end
  end
  
  # 角色查看
  def update_actor_look
    if Input.trigger?(Input::B)
        $game_system.se_play($data_system.cancel_se)
        @target_select_window.visible = true
        @target_select_window.cursor.visible = true
        @actor_status_look_window.visible = false
        @sprite_back.visible = true
      return
    end
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      actors = $game_party.actors
      if actors.index(@actor_status_look_window.actor) < actors.size - 1
        actor = actors[actors.index(@actor_status_look_window.actor) + 1]
        @actor_status_look_window.refresh_people(actor)
      else
        actor = actors[0]
        @actor_status_look_window.refresh_people(actor)
      end
      return
    end
  end
  
  # 战车查看
  def update_tank_look
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @target_select_window.visible = true
      @target_select_window.cursor.visible = true
      @tank_status_look_window.visible = false
      @tank_status_look_window.set_sprite_visible(false)
      @sprite_back.visible = true
      return
    end
  end
  
  # 拆装甲战车选择
  def update_status_tank_target
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @cursor.visible = true
      @tank_status_tank_target_window.visible = false
      @tank_status_tank_target_window.cursor.visible = false
      return
    end
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @tank_status_tank_target_window.visible = false
      @tank_status_tank_target_window.cursor.visible = false
      tank = $game_party.tanks[@tank_status_tank_target_window.tank_index]
      @tank_status_drop_window.refresh_tank(tank)
      @tank_status_drop_window.visible = true
    end
    return
  end
  
  # 拆装甲
  def update_status_drop
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @tank_status_tank_target_window.cursor.visible = true
      @tank_status_tank_target_window.visible = true
      @tank_status_drop_window.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @tank_status_drop_window.visible = false
      @sprite_drop_back.visible = true
      $game_temp.message_text =\
        "装甲瓦片拆下" + @tank_status_drop_window.drop_number.to_s + "可以吗？"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @window_yes_no.contents.dispose if @window_yes_no != nil
      @window_yes_no = Window_YesOrNo.new
      @window_yes_no.z = 9999
      
      loop do
        Input.update
        Graphics.update
        @window_yes_no.update
        if Input.trigger?(Input::C)
          @result = @window_yes_no.result
          Input.update
          break
        end
      end
      
      @message_window.terminate_message
      
      case @result
      when RESULT_YES
        $game_temp.message_text =\
          "扔掉了" + @tank_status_drop_window.drop_number.to_s + "装甲瓦片！"
      when RESULT_NO
        $game_temp.message_text = "停止！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            @tank_status_tank_target_window.refresh
            @tank_status_window.refresh
            40.times {Graphics.update}
            @message_window.terminate_message      
            @sprite_drop_back.visible = false
            @tank_status_tank_target_window.cursor.visible = true
            @tank_status_tank_target_window.visible = true
            @tank_status_drop_window.visible = false
            break
          end
        end
        return
      end
      
      tank = $game_party.tanks[@tank_status_tank_target_window.tank_index]
      tank.hp -= @tank_status_drop_window.drop_number
      
      @window_yes_no.visible = false
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          @message_window.terminate_message
          break
        end
      end
      
      @tank_status_tank_target_window.refresh
      
      @tank_status_window.refresh
      
      @sprite_drop_back.visible = false
      @tank_status_tank_target_window.cursor.visible = true
      @tank_status_tank_target_window.visible = true
      @tank_status_drop_window.visible = false
      return
    end
  end
end