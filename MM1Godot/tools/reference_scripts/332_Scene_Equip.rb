class Scene_Equip
  
  include MM_DataBase
  include MM_System
  
  def main
    
    $game_party.set_cpl_party
    
    @command = EQUIPCOMMAND_EQUIP
    
    @equip_status_actor_window = Window_EquipStatusActor.new($game_party.actors[0])
    @equip_actor_window = Window_EquipActor.new($game_party.actors[0])
    @equip_actor_window.active = false
    
    if $game_party.tanks != []
      @equip_status_tank_window = Window_EquipStatusTank.new($game_party.tanks[0])
      @equip_tank_window = Window_EquipTank.new($game_party.tanks[0])
      @equip_status_tank_window.visible = false
      @equip_tank_window.visible = false
      @equip_tank_window.active = false
    
      @equip_load_window = Window_EquipTankLoad.new
      @equip_load_window.z = 9999
    end
      
    @target_window = Window_StatusTargetSelect.new
    @target_window.visible = true
    @target_window.cursor.visible = true
    
    @equip_commands_window = Window_EquipCommands.new
    @equip_commands_window.visible = false
    @equip_commands_window.active = false
    
    @message_window = Window_Message.new
    @message_window.z = 9999
    
    @sprite_message_back = Sprite.new
    @sprite_message_back.bitmap = RPG::Cache.picture(PICTURE_DIALOG_BACKUP)
    @sprite_message_back.visible = false
    @sprite_message_back.x = @message_window.x
    @sprite_message_back.y = @message_window.y + 8
    @sprite_message_back.z = 9997
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_ACTOR)
    
    
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
    
    @equip_status_actor_window.dispose
    @equip_actor_window.dispose
    
    if $game_party.tanks != []
      @equip_tank_window.dispose
      @equip_status_tank_window.dispose
      @equip_load_window.dispose
    end
      
    @target_window.dispose
    
    @equip_commands_window.dispose
    
    @type_window.dispose if @type_window != nil
    @actor_select_window.dispose if @actor_select_window != nil
    
    @message_window.dispose
    @sprite_message_back.bitmap.dispose
    @sprite_message_back.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
  end
  
  def update
    @target_window.update
    @equip_commands_window.update
    
    if @equip_actor_window.active
      case @command
      when EQUIPCOMMAND_EQUIP
        update_actor_equip
      when EQUIPCOMMAND_PASS
        update_actor_pass
      when EQUIPCOMMAND_DROP
        update_actor_drop
      end
      return
    end
    if $game_party.tanks != []
      if @equip_tank_window.active
        case @command
        when EQUIPCOMMAND_EQUIP
          update_tank_equip
        when EQUIPCOMMAND_PASS
          update_tank_pass
        when EQUIPCOMMAND_DROP
          update_tank_drop
        end
        return
      end
    end
    if @equip_commands_window.active
      update_equip_commands_window
      return
    end
    
    if Input.trigger?(Input::C) then      $game_system.se_play($data_system.decision_se)
      @equip_commands_window.visible = true
      @equip_commands_window.active = true
      @target_window.visible = false
      @target_window.cursor.visible = false
      return
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return
    end
    
    case @target_window.now
    when TARGET_LEFT
      @sprite_back.bitmap.dispose
      @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_ACTOR)
      @actor = $game_party.actors[@target_window.actor_index]
      @equip_status_actor_window.refresh_actor(@actor)
      @equip_actor_window.refresh_actor(@actor)
      @equip_actor_window.visible = true
      @equip_status_actor_window.visible = true
      if $game_party.tanks != []
        @equip_tank_window.visible = false
        @equip_status_tank_window.visible = false
      end
    when TARGET_RIGHT
      @sprite_back.bitmap.dispose
      @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
      @tank = $game_party.tanks[@target_window.tank_index]
      @equip_status_tank_window.refresh_tank(@tank)
      @equip_tank_window.refresh_tank(@tank)
      @equip_actor_window.visible = false
      @equip_status_actor_window.visible = false
      @equip_tank_window.visible = true
      @equip_status_tank_window.visible = true
    end
  end
  
  # 指令
  def update_equip_commands_window
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_commands_window.visible = false
      @equip_commands_window.active = false
      @target_window.visible = true
      @target_window.cursor.visible = true
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @target_window.now
      when TARGET_LEFT
        if @actor.equipments == []
          @equip_commands_window.active = false
          @sprite_message_back.visible = true
          $game_temp.message_text = "没有携带装备物。"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          @sprite_message_back.visible = false
          @message_window.terminate_message
          @equip_commands_window.active = true
          return
        end
        @equip_actor_window.active = true
      when TARGET_RIGHT
        if @tank.equipments == []
          @equip_commands_window.active = false
          @sprite_message_back.visible = true
          $game_temp.message_text = "没有携带装备物。"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          @sprite_message_back.visible = false
          @message_window.terminate_message
          @equip_commands_window.active = true
          return
        end
        @equip_tank_window.active = true
      end
      @equip_commands_window.active = false
      case @equip_commands_window.result
      when EQUIPCOMMAND_EQUIP
        @command = EQUIPCOMMAND_EQUIP
      when EQUIPCOMMAND_PASS
        @command = EQUIPCOMMAND_PASS
      when EQUIPCOMMAND_DROP
        @command = EQUIPCOMMAND_DROP
      end
      return
    end
  end
  
  # 角色
  def update_actor_equip
    @equip_actor_window.update
    @equip_status_actor_window.update
    equipment = @actor.equipments[@equip_actor_window.cursor_index]
    @equip_status_actor_window.refresh_equipment(equipment)
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_actor_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @message_window.terminate_message
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @sprite_message_back.visible = true
      if @actor.equippable?(equipment)
        case equipment
        when RPG::Weapon
          kind = 0
        when RPG::Armor
          kind = equipment.kind + 1
        end
        result = @actor.equip(kind, equipment)
        @message_window.terminate_message
        if result == EQUIPRESULT_PICK
          $game_temp.message_text = "装备了 " + equipment.name + "！"
        elsif result == EQUIPRESULT_DROP
          $game_temp.message_text = "取下了 " + equipment.name + "！"
        end
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_actor_window.refresh
      else
        @message_window.terminate_message
        $game_temp.message_text = "不能装备" + equipment.name + "！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_actor_window.refresh
      end
    end
  end
  
  # 战车
  def update_tank_equip    
    @equip_tank_window.update
    @equip_status_tank_window.update
    
    equipment = @tank.equipments[@equip_tank_window.cursor_index]
    @equip_status_tank_window.refresh_equipment(equipment)
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_tank_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @type_window.visible = false if @type_window != nil
      @message_window.terminate_message
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @sprite_message_back.visible = true
      if @tank.rent
        @message_window.terminate_message
        $game_temp.message_text = "不能取下出租车的装备！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        return
      end
      case equipment
      when Game_MainCannon, Game_SubCannon, Game_SE
        @message_window.terminate_message
        @type_window.visible = false if @type_window != nil
        if @tank.main_cannon.equal?(equipment)
          @message_window.terminate_message
          @tank.equip(0, equipment)
          $game_temp.message_text = "取下了" + equipment.name + "！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          @equip_tank_window.refresh
        elsif @tank.sub_cannon.equal?(equipment)
          @message_window.terminate_message
          @tank.equip(1, equipment)
          $game_temp.message_text = "取下了" + equipment.name + "！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          @equip_tank_window.refresh
        elsif @tank.se.equal?(equipment)
          @message_window.terminate_message
          @tank.equip(2, equipment)
          $game_temp.message_text = "取下了" + equipment.name + "！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          @equip_tank_window.refresh
        else
          @type_window = Window_EquipmentTypeTank.new(@tank, equipment)
          @type_window.z = 9999
          loop do
            @type_window.update
            Graphics.update
            Input.update
            if Input.trigger?(Input::C)
              break
            end
            if Input.trigger?(Input::B)
              @type_window.sprite_cursor.visible = false
              return
            end
          end
          if @tank.equippable?(@type_window.position, equipment)
            case @type_window.position
            when EQUIPTYPE_MAIN_CANNON
              kind = 0
            when EQUIPTYPE_SUB_CANNON
              kind = 1
            when EQUIPTYPE_SE
              kind = 2
            end
            @tank.equip(kind, equipment)
            @equip_tank_window.refresh
            @type_window.refresh
          else
            @message_window.terminate_message
            $game_temp.message_text = "没有开洞，无法装备！"
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
            @message_window.terminate_message
            @sprite_message_back.visible = false
          end
        end
      when Game_Engine, Game_C_Unit
        @type_window.visible = false if @type_window != nil
        if equipment.is_a?(Game_Engine)
          kind = 4
        elsif equipment.is_a?(Game_C_Unit)
          kind = 3
        end
        result = @tank.equip(kind, equipment)
        @message_window.terminate_message
        if result == EQUIPRESULT_PICK
          $game_temp.message_text = "装备了" + equipment.name + "！"
        elsif result == EQUIPRESULT_DROP
          $game_temp.message_text = "取下了" + equipment.name + "就不能动！"
        end
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_tank_window.refresh
      when Game_Underpan
        @type_window.visible = false if @type_window != nil
        @message_window.terminate_message
        $game_temp.message_text = "不能取下底盘！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      end
    end
  end
  
  # 人类
  def update_actor_pass
    @equip_actor_window.update
    @equip_status_actor_window.update
    equipment = @actor.equipments[@equip_actor_window.cursor_index]
    @equip_status_actor_window.refresh_equipment(equipment)
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_actor_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @message_window.terminate_message
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @actor_select_window.contents.dispose if @actor_select_window != nil
      @actor_select_window = Window_EquipPassActorTargetSelect.new
      @actor_select_window.z = 9000

      sprite_temp = Sprite.new
      sprite_temp.bitmap = Bitmap.new(120, 64)
      sprite_temp.z = 9999
      sprite_temp.x = @actor_select_window.x
      sprite_temp.y = @actor_select_window.y
      sprite_temp.bitmap.draw_text(30, 0, 120, 64, equipment.name)
      
      @actor_select_window.visible = true
      loop do
        @actor_select_window.update
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
        if Input.trigger?(Input::B)
          @equip_actor_window.active = false
          @equip_commands_window.active = true
          @sprite_message_back.visible = false if @sprite_message_back.visible
          @message_window.terminate_message
          @actor_select_window.visible = false
          sprite_temp.bitmap.dispose
          sprite_temp.dispose
          return
        end
      end
      target = $game_party.actors[@actor_select_window.actor_index]
      @sprite_message_back.visible = true
      if target.equipments_package_full?
        $game_temp.message_text = target.name.to_s + "不能再拿！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            if Input.trigger?(Input::C)
              break
            end
          end
        end
        @actor_select_window.visible = false
        sprite_temp.bitmap.dispose
        sprite_temp.dispose
        @equip_actor_window.refresh
        @equip_status_actor_window.refresh
        40.times {Graphics.update}
        @equip_actor_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
        @message_window.terminate_message
        return
      end
      $game_temp.message_text = @actor.name + "把" +\
        equipment.name + "交给了" + target.name + "！"
      @actor_select_window.visible = false
      sprite_temp.bitmap.dispose
      sprite_temp.dispose
      target.gain_equipments(equipment)
      @actor.lose_equipments(@equip_actor_window.cursor_index)  
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      @equip_actor_window.refresh
      @equip_status_actor_window.refresh
      40.times {Graphics.update}
      @equip_actor_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @message_window.terminate_message
      return
    end
  end
  
  # 战车
  def update_tank_pass
    
    @sprite_back.bitmap.dispose
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_PASS)
    
    @equip_tank_window.update
    @equip_status_tank_window.visible = false if @equip_status_tank_window.visible
    
    equipment = @tank.equipments[@equip_tank_window.cursor_index]
    @equip_load_window.visible = true
    @equip_load_window.refresh_data(@tank, equipment)
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_tank_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @equip_status_tank_window.visible = true
      @message_window.terminate_message
      @equip_status_tank_window.visible = true
      @equip_load_window.visible = false
      @sprite_back.bitmap.dispose
      @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
      return
    end
    
    if Input.trigger?(Input::C)
      
      $game_system.se_play($data_system.decision_se)
      
      if equipment.rent
        @message_window.terminate_message
        $game_temp.message_text = "不能取下出租车的装备！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        return
      end
      
      @tank_select_window.contents.dispose if @tank_select_window != nil
      @tank_select_window = Window_EquipPassTankTargetSelect.new
      @tank_select_window.z = 9000
      @tank_select_window.visible = true
      loop do
        @tank_select_window.update
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
        if Input.trigger?(Input::B)
          @equip_tank_window.active = false
          @equip_commands_window.active = true
          @sprite_message_back.visible = false if @sprite_message_back.visible
          @equip_status_tank_window.visible = true
          @message_window.terminate_message
          @tank_select_window.visible = false
          @equip_status_tank_window.visible = true
          @equip_load_window.visible = false
          @sprite_back.bitmap.dispose
          @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
          return
        end
      end
      @sprite_message_back.visible = true
      target = $game_party.tanks[@tank_select_window.tank_index]
      case equipment
      when Game_Engine
        if @tank.engine.equal?(equipment) || @tank.engine == nil
          @tank_select_window.visible = false
          $game_temp.message_text = "停止！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              40.times {Graphics.update}
              @equip_tank_window.active = false
              @equip_commands_window.active = true
              @sprite_message_back.visible = false if @sprite_message_back.visible
              @equip_status_tank_window.visible = true
              @tank_select_window.visible = false
              @message_window.terminate_message
              @equip_status_tank_window.visible = true
              @equip_load_window.visible = false
              @sprite_back.bitmap.dispose
              @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
              break
            end
          end
          return
        else
          $game_temp.message_text = @tank.name + "把" +\
            equipment.name + "转给了" + target.name + "！"
        end
      when Game_C_Unit
        @tank_select_window.visible = false
        if @tank.c_unit.equal?(equipment) || @tank.c_unit == nil
          $game_temp.message_text = "停止！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              40.times {Graphics.update}
              @equip_tank_window.active = false
              @equip_commands_window.active = true
              @sprite_message_back.visible = false if @sprite_message_back.visible
              @equip_status_tank_window.visible = true
              @message_window.terminate_message
              @tank_select_window.visible = false
              @equip_status_tank_window.visible = true
              @equip_load_window.visible = false
              @sprite_back.bitmap.dispose
              @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
              break
            end
          end
          return
        else
          $game_temp.message_text = @tank.name + "把" +\
            equipment.name + "转给了" + target.name + "！"
        end
      when Game_Underpan
        @tank_select_window.visible = false
        $game_temp.message_text = "停止！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            40.times {Graphics.update}
            @equip_tank_window.active = false
            @equip_commands_window.active = true
            @sprite_message_back.visible = false if @sprite_message_back.visible
            @equip_status_tank_window.visible = true
            @message_window.terminate_message
            @tank_select_window.visible = false
            @equip_status_tank_window.visible = true
            @equip_load_window.visible = false
            @sprite_back.bitmap.dispose
            @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
            break
          end
        end
        return
      else
        $game_temp.message_text = @tank.name + "把" +\
          equipment.name + "转给了" + target.name + "！"
      end
      @tank_select_window.visible = false
      if target.equipments_package_full?
        $game_temp.message_text = "不能再装了！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_tank_window.refresh
        @equip_status_tank_window.refresh
        40.times {Graphics.update}
        @equip_tank_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
        @equip_status_tank_window.visible = true
        @equip_status_tank_window.visible = true
        @equip_load_window.visible = false
        @sprite_back.bitmap.dispose
        @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
        @message_window.terminate_message
        return
      end
      target.gain_equipments(equipment)
      @tank.lose_equipments(@equip_tank_window.cursor_index)  
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      @equip_tank_window.refresh
      @equip_status_tank_window.refresh
      40.times {Graphics.update}
      @equip_tank_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @equip_status_tank_window.visible = true
      @equip_status_tank_window.visible = true
      @equip_load_window.visible = false
      @sprite_back.bitmap.dispose
      @sprite_back.bitmap = RPG::Cache.picture(PICTURE_EQUIP_BACK_TANK_NORMAL)
      @message_window.terminate_message
      return
    end
  end
  
  # 人類
  def update_actor_drop
    @equip_actor_window.update
    @equip_status_actor_window.update
    equipment = @actor.equipments[@equip_actor_window.cursor_index]
    @equip_status_actor_window.refresh_equipment(equipment)
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_actor_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @message_window.terminate_message
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @sprite_message_back.visible = true
      
      $game_temp.message_text = "要扔" + equipment.name + "吗？"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @select_window.contents.dispose if @select_window != nil
      @select_window = Window_YesOrNo.new
      @select_window.z = 9999
      
      loop do
        Graphics.update
        Input.update
        @select_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      result = @select_window.result
      @select_window.visible = false
      case result
      when RESULT_YES
        @message_window.terminate_message
        
        $game_temp.message_text = "扔掉了" + equipment.name + "！"
        @actor.lose_equipments(@equip_actor_window.cursor_index)
        
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_actor_window.refresh
        @equip_status_actor_window.refresh
        40.times {Graphics.update}
        @message_window.terminate_message
        @equip_actor_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
      when RESULT_NO
        @message_window.terminate_message
        
        $game_temp.message_text = "无法扔掉！"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @message_window.terminate_message
        @equip_actor_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
      end
      return
    end
  end
  
  #戰車
  def update_tank_drop
    @equip_tank_window.update
    @equip_status_tank_window.update
    
    equipment = @tank.equipments[@equip_tank_window.cursor_index]
    @equip_status_tank_window.refresh_equipment(equipment)

    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equip_tank_window.active = false
      @equip_commands_window.active = true
      @sprite_message_back.visible = false if @sprite_message_back.visible
      @message_window.terminate_message
      return
    end
    
    if Input.trigger?(Input::C)
      
      $game_system.se_play($data_system.decision_se)
      @sprite_message_back.visible = true
      
      if equipment.rent
        @message_window.terminate_message
        $game_temp.message_text = "不能取下出租车的装备！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        return
      end
      
      $game_temp.message_text = "要扔" + equipment.name + "吗？"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @select_window.contents.dispose if @select_window != nil
      @select_window = Window_YesOrNo.new
      @select_window.z = 9999
      
      loop do
        Graphics.update
        Input.update
        @select_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      result = @select_window.result
      @select_window.visible = false
      case result
      when RESULT_YES
        @message_window.terminate_message
        if equipment.is_a?(Game_Underpan)
          $game_temp.message_text = "扔掉" + equipment.name + "不算什么！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          @message_window.terminate_message
          @equip_tank_window.active = false
          @equip_commands_window.active = true
          @sprite_message_back.visible = false if @sprite_message_back.visible
          return
        end
        
        $game_temp.message_text = "扔掉了" + equipment.name + "！"
        @tank.lose_equipments(@equip_tank_window.cursor_index)
        
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @equip_tank_window.refresh
        @equip_status_tank_window.refresh
        40.times {Graphics.update}
        @message_window.terminate_message
        @equip_tank_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
      when RESULT_NO
        @message_window.terminate_message
        
        $game_temp.message_text = "无法扔掉！"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @message_window.terminate_message
        @equip_tank_window.active = false
        @equip_commands_window.active = true
        @sprite_message_back.visible = false if @sprite_message_back.visible
      end
      return
    end
  end
end