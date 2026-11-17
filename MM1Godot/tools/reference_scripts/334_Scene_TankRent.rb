class Scene_TankRent
  
  include MM_DataBase
  
  def main
    
    # 执行过渡
    Graphics.transition(0)
    
    @spriteset_map = Spriteset_Map.new
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_TANKRENT_BACK)
    @sprite_back.z = 8001
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8001
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @command_window = Window_TankRentCommand.new
    @command_window.z = 8002
    @command_window.visible = true
    @command_window.active = true
    
    @actor_select_window = Window_TankRentActorSelect.new
    @actor_select_window.z = 8002
    @actor_select_window.visible = false
    @actor_select_window.active = false
    
    @rent_tank_select_window = Window_TankRentRentTankSelect.new
    @rent_tank_select_window.z = 8005
    @rent_tank_select_window.visible = false
    @rent_tank_select_window.active = false
    
    @instrol_window = Window_TankRentInstrol.new
    @instrol_window.z = 8002
    @instrol_window.visible = false
    
    @tank_select_window = Window_TankRentTankSelect.new($game_temp.rent_tanks_id)
    @tank_select_window.z = 8002
    @tank_select_window.visible = false
    @tank_select_window.active = false
    
    @message_window = Window_Message.new
    
    $game_temp.message_text = "欢迎光临战车出租店！"
    loop do
      Graphics.update
      Input.update
      @message_window.update
      if @message_window.at_end
        break
      end
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
    @command_window.dispose
    @actor_select_window.dispose
    @rent_tank_select_window.dispose
    @instrol_window.dispose
    @tank_select_window.dispose
    @message_window.dispose
    @spriteset_map.dispose
    
    @sprite_gold.bitmap.dispose
    @sprite_gold.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
  end
  
  def update
    @command_window.update
    @actor_select_window.update
    @rent_tank_select_window.update
    @instrol_window.update
    @tank_select_window.update
    @spriteset_map.update
    
    if @spriteset_refresh == true
      @spriteset_map.dispose
      @spriteset_map = Spriteset_Map.new
      @spriteset_refresh = nil
      return
    end
    
    if @rent_tank_select_window.visible && @rent_tank_select_window.active
      update_tank_return
      return
    end
      
    if @tank_select_window.visible && @tank_select_window.active
      update_tank_select
      return
    end
    
    if @instrol_window.visible
      update_instrol
      return
    end
    
    if @command_window.visible && @command_window.active
      update_command
      return
    end
  end
  
  def update_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @message_window.terminate_message
      
      $game_temp.message_text = "是的。那再来吧！"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      40.times {Graphics.update}
      $scene = Scene_Map.new
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @command_window.result
      when TANKRENTCOMMAND_RENT
        
        @message_window.terminate_message      
        $game_temp.message_text = "我只有这样的战车。租哪辆？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @command_window.visible = false
        @command_window.active = false
        @tank_select_window.visible = true
        @tank_select_window.active = true
        return
        
      when TANKRENTCOMMAND_RETURN
        
        if $game_party.rent_tanks.size == 0
          @message_window.terminate_message
          $game_temp.message_text = "啊啦，不是没有借战车么。"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}  
          return
        end
        
        @message_window.terminate_message
        $game_temp.message_text = "不是已经还了吗？真没办法。是哪部车？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @command_window.active = false
        @rent_tank_select_window.visible = true
        @rent_tank_select_window.active = true
        return
        
      when TANKRENTCOMMAND_INSTROL
        
        @command_window.visible = false
        @command_window.active = false
        @instrol_window.visible = true
        return
        
      when TANKRENTCOMMAND_EXIT
        
        @message_window.terminate_message      
        $game_temp.message_text = "是的。那再来吧！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        $scene = Scene_Map.new
        return
        
      end
      
    end
  end
  
  def update_instrol
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @instrol_window.visible = false
      @command_window.visible = true
      @command_window.active = true
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @instrol_window.result
      when TANKRENTINSTROL_RULE
        
        @message_window.terminate_message
        $game_temp.message_text = "出租战车没钱也可以借用。但须缴纳使用战车期间的部分所得。"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        return
        
      when TANKRENTINSTROL_WARN
        
        @message_window.terminate_message
        $game_temp.message_text = "出租坦克的装备不能更改！出租战车的装甲和零件毁坏时，出租坦克丢下你以后会自动回到镇上来。"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        return
        
      end
    end
  end
  
  def update_tank_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @tank_select_window.visible = false
      @actor_select_window.visible = false
      @actor_select_window.active = false
      @command_window.visible = true
      @command_window.active = true
      return
    end
    
    if Input.trigger?(Input::C)
      
      if $game_party.rent_tanks.size == 3
        @message_window.terminate_message
        $game_temp.message_text = "不能借战车。你们借车总不还。旧战车不用了，要换新的吗？"
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
          @message_window.terminate_message
          $game_temp.message_text = "知道！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          for i in 0...$game_party.actors.size
            if $game_party.actors[i].tank != nil
              if $game_party.actors[i].tank.rent
                $game_party.remove_tank($game_party.members.index($game_party.actors[i].tank), $game_party.actors[i].tank.id)
                $game_party.actors[i].get_off
              end
            end
          end
          
          size = $game_party.rent_tanks.size
          for i in 0...size
            tank_ary = $game_map.tanks_position[$game_party.rent_tanks[i].id]
            if tank_ary == nil
              $game_map.tanks_position.delete($game_party.rent_tanks[i].id)
              next
            end
            #id    坐标  地图编号 文件名
            for event in $game_maps[tank_ary[2]].events.values
              if event.x == tank_ary[0]\
                && event.y == tank_ary[1]\
                && event.pages[0].graphic.character_name == tank_ary[3]
                break
              end
            end
            if $game_map.map_id == tank_ary[2]
              $game_map.delete_event(event.id)
            else
              $game_maps[tank_ary[2]].events.delete(event.id)
            end
            $game_tanks.delete($game_party.rent_tanks[i])
            $game_map.tanks_position.delete($game_party.rent_tanks[i])
          end
          
          $game_party.rent_tanks.clear
          @spriteset_map.update
          @tank_select_window.visible = false
          @command_window.visible = true
          @command_window.active = true
          return
        when RESULT_NO
          $game_temp.message_text = "再见！请再来！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          $scene = Scene_Map.new
          return
        end
      end
      
      @message_window.terminate_message
      $game_temp.message_text = "战车真漂亮，谁进车了？"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      40.times {Graphics.update}
      
      @actor_select_window.visible = true
      @actor_select_window.active = true
      @command_window.active = false
      loop do
        Graphics.update
        Input.update
        @actor_select_window.update
        if Input.trigger?(Input::C)
          break
        end
        if Input.trigger?(Input::B)
          @actor_select_window.visible = false
          @actor_select_window.active = false
          @command_window.active = true
          return
        end        
      end
      
      member_index = @actor_select_window.cursor_index
      actor = $game_party.actors[member_index]
      player = $game_players.players[member_index]
      rent_tank_data = @tank_select_window.get_tank_data
      rent_tank = Game_Tank.new(1)
      id = 9
      while $game_tanks.get_tank_by_id(id) != nil
        id += 1
      end
      rent_tank.reset_tank_data(rent_tank_data, id)
      $game_tanks[rent_tank.id] = rent_tank
      
      #先下車
      if actor.tank != nil
        $game_map.tanks_position[actor.tank.id] = [] if $game_map.tanks_position[actor.tank.id] == nil
        $game_map.tanks_position[actor.tank.id][0] = player.x
        $game_map.tanks_position[actor.tank.id][1] = player.y
        $game_map.tanks_position[actor.tank.id][2] = $game_map.map_id
        $game_map.tanks_position[actor.tank.id][3] = actor.tank.character_name
        $game_map.add_event(player.x, player.y,\
          actor.tank.character_name, actor.tank.character_name,\
          player.tank_event_id,\
          player.direction, true)
        player.tank_event_id = nil
        $game_party.remove_tank(member_index, actor.tank.id)
        actor.get_off
      end
      
      #再上車
      tank = rent_tank
      $game_party.rent_tanks.push(tank)
      player.tank_event_id = 200 + tank.id
      actor.get_on(tank)
      $game_party.add_tank(member_index, tank.id)
      @spriteset_map.update
      @rent_tank_select_window.refresh
      @message_window.terminate_message
      $game_temp.message_text = actor.name + "改乘出租战车。"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      40.times{Graphics.update}
      
      @message_window.terminate_message
      $game_temp.message_text = "借别的战车吗？"
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
        @actor_select_window.active = false
        return
      when RESULT_NO
        @tank_select_window.visible = false
        @actor_select_window.visible = false
        @actor_select_window.active = false
        @command_window.visible = true
        @command_window.active = true
        return
      end
    end    
  end
  
  def update_tank_return
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.decision_se)
      @command_window.active = true
      @rent_tank_select_window.active = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.cancel_se)
      rent_tank = $game_party.rent_tanks[@rent_tank_select_window.cursor_index]
      
      $game_party.rent_tanks.delete(rent_tank)
      if rent_tank.driver != nil
        $game_party.remove_tank($game_party.members.index(rent_tank), rent_tank.id)
        rent_tank.driver.get_off
        $game_tanks.delete(rent_tank)
        $game_tanks.delete(rent_tank)
        $game_party.rent_tanks.delete(rent_tank)
      else
        $game_tanks.delete(rent_tank)
      
        tank_ary = $game_map.tanks_position[rent_tank.id]
        #id    坐标  地图编号 文件名
        for event in $game_maps[tank_ary[2]].events.values
          if event.x == tank_ary[0]\
            && event.y == tank_ary[1]\
            && event.pages[0].graphic.character_name == tank_ary[3]
            break
          end
        end
        if $game_map.map_id == tank_ary[2]
          $game_map.delete_event(event.id)
        else
          $game_maps[tank_ary[2]].events.delete(event.id)
        end
        $game_tanks.delete(rent_tank)
        $game_party.rent_tanks.delete(rent_tank)
        $game_map.tanks_position.delete(rent_tank.id)
      end
      
      @spriteset_map.update
      @rent_tank_select_window.refresh
      @message_window.terminate_message
      $game_temp.message_text = "谢谢使用，欢迎再来借。"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      40.times{Graphics.update}
      @rent_tank_select_window.active = false
      @rent_tank_select_window.visible = false
      @command_window.active = true
      return
    end
  end
  
  def reload_spriteset
    @spriteset_refresh = true
  end
end