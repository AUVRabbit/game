#==============================================================================
# ■ Scene_Menu
#------------------------------------------------------------------------------
# 　处理菜单画面的类。
#==============================================================================

class Scene_Menu
  
  include MM_System
  include MM_DataBase
  
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    
    $game_party.set_cpl_party
    
    @spriteset = Spriteset_Map.new
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8000
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.z = 8002
    
    @index = 0
    
    @sprite_cursor.x = @index / 4 * 96
    @sprite_cursor.y = 320 + (@index % 4) * 34
    
    @status_window = Window_MenuStatus.new
    @status_window.z = 8002
    
    @updown_window = Window_MenuUpDown.new
    @updown_window.z = 8002
    
    @target_window = Window_StatusTargetSelect.new
    @target_window.z = 8002
    
    @item_select_window = Window_ItemSelect.new($game_party.actors[0])
    @item_select_window.visible = false
    @item_select_window.z = 8002
    
    @mode_select_window = Window_ModeSelect.new
    @mode_select_window.z = 8002
    
    @mode_data_window = Window_ModeData.new
    @mode_data_window.z = 8002
    
    @mode_moneybell_window = Window_ModeMoneyBell.new
    @mode_moneybell_window.z = 8002
    
    @wanted_list_window = Window_StrikedWantedPersonList.new
    @wanted_list_window.z = 8002
    @wanted_list_window.visible = false
    
    @message_window = Window_Message.new
    
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
    # 释放窗口
    @status_window.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @spriteset.dispose
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
    @message_window.dispose
    @updown_window.dispose
    @item_select_window.dispose
    @target_window.dispose
    @mode_select_window.dispose
    @mode_data_window.dispose
    @mode_moneybell_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
    #p 1
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    @message_window.update
    @spriteset.update
    @status_window.update
    @updown_window.update
    @target_window.update
    @item_select_window.update
    
    $game_players.update
    
    if @spriteset_refresh == true
      @spriteset.dispose
      @spriteset = Spriteset_Map.new
      @spriteset_refresh = nil
      return
    end
    
    # 按照地图、实例、主角的顺序刷新
    # (本更新顺序不会在满足事件的执行条件下成为给予角色瞬间移动
    #  的机会的重要因素)
    $game_map.update
    $game_system.map_interpreter.update
        
    $game_players.update
    # 系统 (计时器)、画面刷新
    $game_system.update
    $game_screen.update
    
    #if @all_index == false
    #  $game_party.recover_org_party
    #  $scene = Scene_Map.new
    #end
    
    # 显示信息窗口中的情况下
    if $game_temp.message_window_showing
      return
    end
    
    if @updown_window.active
      update_updown
      return
    end
    
    
    if @target_window.visible
      update_target_select
      return
    end
    
    if @item_select_window.visible
      update_item_select
      return
    end
    
    if @mode_select_window.visible
      update_mode_select
      return
    end
    
    if @mode_data_window.visible
      update_mode_data
      return
    end
    
    if @mode_moneybell_window.visible
      update_moneybell
      return
    end
    
    if Input.trigger?(Input::DOWN)
      $game_system.se_play($data_system.cursor_se)
      @index += 1
    end
    if Input.trigger?(Input::UP)
      $game_system.se_play($data_system.cursor_se)
      @index -= 1
    end
    if Input.trigger?(Input::LEFT)
      $game_system.se_play($data_system.cursor_se)
      @index -= 4
    end
    if Input.trigger?(Input::RIGHT)
      $game_system.se_play($data_system.cursor_se)
      @index += 4
    end
    
    @index = [[0, @index].max, 7].min
    @sprite_cursor.x = @index / 4 * 96
    @sprite_cursor.y = 320 + (@index % 4) * 34
    
    if Input.trigger?(Input::C)
      case @index
      #對話
      when 0
        $game_system.se_play($data_system.decision_se)
        if @status_window.visible == true
          @status_window.visible = false
          result = $game_players.check_event_trigger_there_dialog([0,1,2])
          if !result
            $game_temp.force_message = true
            @message_window.terminate_message
            $game_temp.message_text = "眼前没有人。"
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
                break
              end
            end
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            10.times {Graphics.update}
            $game_party.recover_org_party
            $game_temp.force_message = false
            $scene = Scene_Map.new
          end
        else
          if !$game_system.map_interpreter.running?
            $game_party.recover_org_party
            $scene = Scene_Map.new
          end
        end
        return
      #強度
      when 1
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Status.new
        return
      #裝備
      when 2
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Equip.new
      #調查
      when 3
        $game_temp.force_message = true
        $game_system.se_play($data_system.decision_se)
        if @status_window.visible == true
          @status_window.visible = false
          #先檢查拖車
          result = $game_players.check_tank
          head_player = $game_players.head_player
          if result
            for event in $game_map.events.values
              if event.x == head_player.x\
                && event.y == head_player.y
                tanks_keys = $game_map.tanks_position.keys.sort!
                for i in 0...tanks_keys.size
                  tanks_ary = $game_map.tanks_position[tanks_keys[i]]
                  if $game_map.map_id == tanks_ary[2]\
                    && event.x == tanks_ary[0]\
                    && event.y == tanks_ary[1]
                    tank_id = tanks_keys[i]
                    break
                  end
                end
                if $game_party.tow_tank == nil
                  #$game_party.add_tow_tank(tank_id)
                  tank = $game_tanks[tank_id]
                  @message_window.terminate_message
                  $game_temp.message_text = "发现" + tank.name + "!"
                  
                  if $game_party.tanks == []
                    $game_temp.message_text += "但是没有战车，无法牵引！"
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
                        break
                      end
                    end
                  else
                    $game_temp.message_text += "要牵引么？"
                    loop do
                      Graphics.update
                      Input.update
                      @message_window.update
                      if @message_window.at_end
                        break
                      end
                    end
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
                    result = @yes_no_window.result
                    case result
                    when RESULT_YES
                      
                      $game_party.add_tow_tank(tank_id)
                      $game_players.last_player.tank_event_id = 200 + tank_id
                      $game_map.tanks_position.delete(tank_id)
                      #$game_players.reset_players
                      $game_map.delete_event(event.id)
                      
                      @message_window.terminate_message
                      $game_temp.message_text = "牵引了" + tank.name + "！"
                      
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
                          break
                        end
                      end
                      
                    when RESULT_NO
                      @message_window.terminate_message
                      $game_temp.message_text = "仍没牵引！"
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
                          break
                        end
                      end
                      
                    end
                    $game_party.recover_org_party
                    $scene = Scene_Map.new
                    return
                  end
                  
                else
                  tank = $game_tanks[tank_id]
                  $game_temp.message_text = "发现" + tank.name + "!"
                  $game_temp.message_text += "但是已经牵引了" + $game_party.tow_tank.name + "要换么？"
                  
                  loop do
                    Graphics.update
                    Input.update
                    @message_window.update
                    if @message_window.at_end
                      break
                    end
                  end
                  @yes_no_window = Window_YesOrNo.new
                  loop do
                    Graphics.update
                    Input.update
                    @yes_no_window.update
                    if Input.trigger?(Input::C)
                      break
                    end
                  end
                  result = @yes_no_window.result
                  @yes_no_window.visible = false
                  case result
                  when RESULT_YES
                                          
                    tow_tank = $game_party.tow_tank
                    player = $game_players.last_player
                    $game_map.tanks_position[tow_tank.id] = [] if $game_map.tanks_position[tow_tank.id] == nil
                    $game_map.tanks_position[tow_tank.id][0] = player.x
                    $game_map.tanks_position[tow_tank.id][1] = player.y
                    $game_map.tanks_position[tow_tank.id][2] = $game_map.map_id
                    $game_map.tanks_position[tow_tank.id][3] = tow_tank.character_name
                    $game_map.add_event(player.x, player.y,\
                      tow_tank.character_name, tow_tank.character_name,\
                    player.tank_event_id,\
                    player.direction, true)
                    player.tank_event_id = nil
                    
                    $game_map.delete_event(event.id)
                    $game_party.remove_tow_tank
                    $game_party.add_tow_tank(tank.id)
                    #Audio.se_play("Audio/SE/" + SE_UPDOWN, 100, 100)
      
                    @message_window.terminate_message
                    $game_temp.message_text = "牵引了" + tank.name + "！"
                      
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
                        break
                      end
                    end
                      
                  when RESULT_NO
                    @message_window.terminate_message
                    $game_temp.message_text = "仍没牵引！"
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
                        break
                      end
                    end
                  end
                  $game_party.recover_org_party
                  $scene = Scene_Map.new
                  return
                end
                #Audio.se_play("Audio/SE/" + SE_UPDOWN, 100, 100)
              end
            end
          end
          
          #再觸發事件
          result = $game_players.check_event_trigger_here([0])
          if !result
            result = $game_players.check_event_trigger_there([0,1,2])
          end
          if !result
            @message_window.terminate_message
            $game_temp.message_text =\
              $game_party.actors[0].name + "检查了脚下，但是什么都没有发现。"
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
                break
              end
            end
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            10.times {Graphics.update}
            $game_party.recover_org_party
            $scene = Scene_Map.new
          end
        else
          if !$game_system.map_interpreter.running?
            $game_party.recover_org_party
            $scene = Scene_Map.new
          end
        end
        $game_temp.force_message = false
        return
      #乘降
      when 4
        $game_system.se_play($data_system.decision_se)
        @sprite_cursor.visible = false
        @updown_window.visible = true
        @updown_window.active = true
        @status_window.visible = false
        @status_window.active = false
        return
      #工具
      when 5
        $game_system.se_play($data_system.decision_se)
        @sprite_cursor.visible = false
        @target_window.visible = true
        @target_window.active = true
        @target_window.cursor.visible = true
        @status_window.visible = false
        @status_window.active = false
        return
      # 炮弹
      when 6
        if $game_party.tanks == []
          $game_temp.force_message = true
          @status_window.visible = false
          @sprite_cursor.visible = false
          @message_window.terminate_message
          $game_temp.message_text = "没带战车。"
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
              break
            end
          end
          @message_window.terminate_message
          $game_temp.message_window_showing = false
          10.times {Graphics.update}
          #$scene = Scene_Map.new
          @status_window.visible = true
          @sprite_cursor.visible = true
          $game_temp.force_message = false
          return
        end
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_SpecialCannonBall.new
        return
      # 模式
      when 7
        @mode_select_window.visible = true
        @status_window.visible = false
        @status_window.active = false
        @sprite_cursor.visible = false
        return
      end
    end
  
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $game_party.recover_org_party
      $scene = Scene_Map.new
      return
    end
  end
  
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (命令窗口被激活的情况下)
  #--------------------------------------------------------------------------
  def update_command
    # 按下 B 键的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      # 切换的地图画面
      $game_party.recover_org_party
      $scene = Scene_Map.new
      return
    end
    # 按下 C 键的情况下
    if Input.trigger?(Input::C)
      # 同伴人数为 0、存档、游戏结束以外的场合
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (状态窗口被激活的情况下)
  #--------------------------------------------------------------------------
  def update_status
    # 按下 B 键的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      @sprite_cursor.visible = true
      # 激活命令窗口
      @command_window.active = true
      @status_window.active = false
      @status_window.index = -1
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (乘降的情况下)
  #--------------------------------------------------------------------------
  def update_updown
=begin
    if @all_index != nil && @all_index != false
      if @all_index >= $game_party.actors.size - 1
        @all_index = false
        return
      end
      @all_index += 1
      $game_party.updown(@all_index)
      return
    end
=end
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @sprite_cursor.visible = true
      @status_window.active = false
      @status_window.visible = true
      @updown_window.active = false
      @updown_window.visible = false
      return
    end
    if Input.trigger?(Input::C)
      $game_temp.force_message = true
      $game_system.se_play($data_system.decision_se)
      if @updown_window.cursor_index == 0
        #@all_index = 0 if @all_index == nil
        @updown_window.visible = false
        @updown_window.cursor.visible = false
        for i in 0...$game_party.actors.size
          #$game_party.updown(@all_index)
          @message_window.terminate_message
          $game_party.updown(i)
          @spriteset.update
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
              break
            end
          end
        end
        
        $game_party.recover_org_party
        #$game_temp.force_message = false
        #$scene = Scene_Map.new
      else
        @updown_window.visible = false
        #@all_index = $game_party.actors.size if @all_index == nil
        @updown_window.cursor.visible = false
        @updown_window.visible = false
        @message_window.terminate_message
        
        $game_party.updown(@updown_window.cursor_index - 1)
        
        @spriteset.update
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
            break
          end
        end
        
        $game_party.recover_org_party
      end
      if $game_party.tow_tank != nil && $game_party.tanks == []
        tow_tank = $game_party.tow_tank
        player = $game_players.last_player
        $game_map.tanks_position[tow_tank.id] = [] if $game_map.tanks_position[tow_tank.id] == nil
        $game_map.tanks_position[tow_tank.id][0] = player.x
        $game_map.tanks_position[tow_tank.id][1] = player.y
        $game_map.tanks_position[tow_tank.id][2] = $game_map.map_id
        $game_map.tanks_position[tow_tank.id][3] = tow_tank.character_name
        $game_map.add_event(player.x, player.y,\
          tow_tank.character_name, tow_tank.character_name,\
        player.tank_event_id,\
        player.direction, true)
        player.tank_event_id = nil
        #player.set_member(nil)
        #$game_map.delete_event(event.id)
        $game_party.remove_tow_tank
        #$game_party.add_tow_tank(tank.id)
        @spriteset.update
      end
      
      $game_temp.force_message = false
      $scene = Scene_Map.new
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (对象選擇的情况下)
  #--------------------------------------------------------------------------
  def update_target_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @sprite_cursor.visible = true
      @target_window.active = false
      @target_window.visible = false
      @status_window.active = false
      @status_window.visible = true
      @target_window.cursor.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_temp.force_message = true
      $game_system.se_play($data_system.decision_se)
      @target_window.visible = false
      @target_window.active = false
      @target_window.cursor.visible = false
      case @target_window.now
      when TARGET_LEFT
        @obj = $game_party.actors[@target_window.actor_index]
      when TARGET_RIGHT
        @obj = $game_party.tanks[@target_window.tank_index]
      end
      if @obj.items == []
        @message_window.terminate_message
        $game_temp.message_text = "没有携带物品。"
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
            break
          end
        end
        @message_window.terminate_message
        $game_temp.message_window_showing = false
        10.times {Graphics.update}
        #$scene = Scene_Map.new
        @status_window.visible = true
        @sprite_cursor.visible = true
        return
      end
      @item_select_window.refresh_obj(@obj)
      @item_select_window.visible = true
      @item_select_window.active = true
      $game_temp.force_message = false
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (物品選擇的情况下)
  #--------------------------------------------------------------------------
  def update_item_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @target_window.active = true
      @target_window.visible = true
      @item_select_window.visible = false
      @item_select_window.active = false
      @target_window.cursor.visible = true
      return
    end
    
    if Input.trigger?(Input::C)
      $game_temp.force_message = true
      $game_system.se_play($data_system.decision_se)
      @item_select_window.visible = false
      @item_select_window.active = false
      @item_command_window = Window_ItemCommands.new
      @item_command_window.z = 8002
      loop do
        Graphics.update
        Input.update
        @item_command_window.update
        if Input.trigger?(Input::C)
          $game_system.se_play($data_system.decision_se)
          break
        end
        if Input.trigger?(Input::B)
          #@item_command_window.cursor.visible = false
          @item_command_window.active = false
          @item_command_window.visible = false
          @status_window.visible = true
          @sprite_cursor.visible = true
          $game_temp.force_message = false
          return
        end
      end
      @item_command_window.visible = false
      @item_command_window.active = false
      case @item_command_window.result
      when ITEMCOMMAND_USE
        item = @obj.items[@item_select_window.cursor_index]
        #时机
        #p item.occasion, item.scope
        case item.occasion
        #scope 
        #效果范围（0：无，1：敌单体，2：敵一組, 3：敌全体，4：己方单体, 5：己方全体，
        #6：己方单体（HP 0），7：己方全体（HP 0），8：使用者）。
        
        #occasion 
        #可能使用时（0：平时，1：战斗中，2：菜单中，3：不能使用）。
      
        # 平时/菜单中
        when 0, 2
          case item.scope
          when 0, 1, 2, 3
            @message_window.terminate_message
            $game_temp.message_text = sprintf(VOCAB_NOEFFECT, @obj.name, item.name)
            @item_select_window.active = false
            @item_select_window.visible = false
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
                break
              end
            end
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            10.times {Graphics.update}
            #$scene = Scene_Map.new
            @status_window.visible = true
            @sprite_cursor.visible = true
            $game_temp.force_message = false
            return
          when 4, 6
            case @obj
            when Game_Actor
              @target_select_window = Window_EquipPassActorTargetSelect.new
            when Game_Tank
              @target_select_window = Window_EquipPassTankTargetSelect.new
            end
            @target_select_window.z = 8002
            @target_select_window.visible = true
            @target_select_window.active = true
            @item_select_window.visible = false
            @item_select_window.active = false
            loop do
              Graphics.update
              Input.update
              @target_select_window.update
              if Input.trigger?(Input::C)
                break
              end
              if Input.trigger?(Input::B)
                @message_window.terminate_message
                @target_select_window.visible = false
                @target_select_window.active = false
                $game_temp.message_text = "还是没有使用。"
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
                    break
                  end
                end
                @message_window.terminate_message
                @item_select_window.visible = false
                @item_select_window.active = false
                @status_window.visible = true
                @sprite_cursor.visible = true
                $game_temp.force_message = false
                return
              end
            end
            @target_select_window.visible = false
            @target_select_window.active = false
            case @obj
            when Game_Actor
              target = $game_party.actors[@target_select_window.actor_index]
            when Game_Tank
              target = $game_party.tanks[@target_select_window.tank_index]
            end
            result, message = target.item_effect(item)
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            if item.menu_message[0] != ""
              if item.consumable 
                @obj.lose_item(@item_select_window.cursor_index)
              end
              @item_select_window.refresh
              $game_temp.message_text = message
            else
              $game_temp.message_text = sprintf(VOCAB_NOEFFECT, @obj.name, item.name)
            end
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
                break
              end
            end
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            10.times {Graphics.update}
            #$scene = Scene_Map.new
            @status_window.visible = true
            @sprite_cursor.visible = true
          when 5, 7
          
          when 8
            result, message = @obj.item_effect(item)
            
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            if item.menu_message[0] != ""
              if item.consumable
                @obj.lose_item(@item_select_window.cursor_index)
              end
              @item_select_window.refresh
              $game_temp.message_text = message
            else
              $game_temp.message_text = sprintf(VOCAB_NOEFFECT, @obj.name)
            end
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
                break
              end
            end
            @message_window.terminate_message
            $game_temp.message_window_showing = false
            10.times {Graphics.update}
            #$scene = Scene_Map.new
            @status_window.visible = true
            @sprite_cursor.visible = true
          end
        # 战斗中/不能使用
        when 1, 3
          @message_window.terminate_message
          $game_temp.message_text = sprintf(VOCAB_NOEFFECT, @obj.name, item.name)
          @item_select_window.active = false
          @item_select_window.visible = false
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
              break
            end
          end
          @message_window.terminate_message
          $game_temp.message_window_showing = false
          10.times {Graphics.update}
          #$scene = Scene_Map.new
          @status_window.visible = true
          @sprite_cursor.visible = true
          $game_temp.force_message = false
          return
        end
      when ITEMCOMMAND_PASS
        case @obj
        when Game_Actor
          @target_pass_window = Window_EquipPassActorTargetSelect.new
        when Game_Tank
          @target_pass_window = Window_EquipPassTankTargetSelect.new
        end
        @item_command_window.visible = false
        @item_command_window.active = false
        @target_pass_window.visible = true
        @target_pass_window.z = 8003
        loop do
          Graphics.update
          Input.update
          @target_pass_window.update
          if Input.trigger?(Input::C)
            break
          end
        end
        @target_pass_window.visible = false
        case @obj
        when Game_Actor
          target = $game_party.actors[@target_pass_window.actor_index]
        when Game_Tank
          target = $game_party.actors[@target_pass_window.tank_index]
        end
        if !target.item_package_full?
          item = @obj.items[@item_select_window.cursor_index]
          @message_window.terminate_message
          $game_temp.message_text = @obj.name + "把" + item.name + "交给了" +\
                                      target.name + "！"
          target.gain_item(item)
          @obj.lose_item(@item_select_window.cursor_index)
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
              break
            end
          end
          10.times {Graphics.update}
          @message_window.terminate_message
          $game_temp.message_window_showing = false
          #$scene = Scene_Map.new
          @target_window.visible = false
          @status_window.visible = true
          @sprite_cursor.visible = true
          $game_temp.force_message = false
          return
        else
          @message_window.terminate_message
          $game_temp.message_text = target.name + "已经不能再拿了！"
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
              break
            end
          end
          10.times {Graphics.update}
          @message_window.terminate_message
          $game_temp.message_window_showing = false
          #$scene = Scene_Map.new
          @target_window.visible = false
          @status_window.visible = true
          @sprite_cursor.visible = true
          $game_temp.force_message = false
          return
        end
      when ITEMCOMMAND_DROP
        item = @obj.items[@item_select_window.cursor_index]
        if item.can_drop_sell
          item = @obj.items[@item_select_window.cursor_index]
          $game_temp.message_text = "扔掉了" + item.name + "！"
          @obj.lose_item(@item_select_window.cursor_index)
          @item_select_window.refresh
        else
          $game_temp.message_text = "不能扔掉！"
        end
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
            break
          end
        end
        10.times {Graphics.update}
        @message_window.terminate_message
        $game_temp.message_window_showing = false
        #$scene = Scene_Map.new
        @status_window.visible = true
        @sprite_cursor.visible = true
        $game_temp.force_message = false
        return
      end
    end
  end
    
  #--------------------------------------------------------------------------
  # ● 刷新画面 (模式選擇的情况下)
  #--------------------------------------------------------------------------
  def update_mode_select
    @mode_select_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @mode_select_window.visible = false
      @status_window.visible = true
      @status_window.active = true
      @sprite_cursor.visible = true
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if @mode_select_window.cursor_index == MODE_DATA
        @mode_select_window.visible = false
        @mode_data_window.visible = true
      end
      if @mode_select_window.cursor_index == MODE_SOUND
        if $game_system.sound == true
          $game_system.bgm_stop
          $game_system.bgs_stop
        else
          $game_system.bgm_restore
          $game_system.bgs_restore
        end
      end
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (模式數據選擇的情况下)
  #--------------------------------------------------------------------------  
  def update_mode_data
    @mode_data_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @mode_select_window.visible = true
      @mode_data_window.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @mode_data_window.cursor_index
      when MODEDATA_BATTLEDATA
        
      when MODEDATA_EXP
        @mode_data_window.visible = false
        @wanted_list_window.visible = true
        loop do
          Graphics.update
          Input.update
          @wanted_list_window.update
          if Input.trigger?(Input::B)
            break
          end
        end
        @wanted_list_window.visible = false
        @mode_data_window.visible = true
      when MODEDATA_MONEYBELL
        @mode_moneybell_window.visible = true
        @mode_data_window.visible = false
      end
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面 (模式數據選擇的情况下)
  #--------------------------------------------------------------------------  
  def update_moneybell
    @mode_moneybell_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @mode_moneybell_window.visible = false
      @mode_data_window.visible = true
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      number = @mode_moneybell_window.number
      @mode_moneybell_window.visible = false
      @mode_data_window.visible = true
      $game_system.moneybell = number
      @mode_data_window.refresh
      return
    end
    
  end
  
  def reload_spriteset
    @spriteset_refresh = true
  end  
end