class Scene_Battle
    
  def update_command
    
    if @troop_window.visible
      update_troop_select
      return
    end
    
    if @item_window != nil
      if @item_window.visible 
        update_item_select
        return
      end
    end
    
    if @equip_window != nil
      if @equip_window.visible
        update_equip_select
        return
      end
    end
    
    if @special_cannonball_window != nil
      if @special_cannonball_window.visible
        update_special_cannonnball_select
        return
      end
    end
    
    if @help_window != nil
      if @help_window.visible
        update_help
        return
      end
    end
    
    @active_battler = $game_party.members[@target_index]
    if !@active_battler.movable?
      if @target_index < $game_party.members.size - 1
        @target_index += 1
      else
        @battle_step += 1
        @battle_proccess = 0
        @help_window.visible = false
        @status_window.visible = true
      end
      return
    end
    case @active_battler
    when Game_Actor
      @people_command_window.visible = true
      @tank_command_window.visible = false
      @people_command_window.set_text(@active_battler.name)
      @people_command_window.update
    when Game_Tank
      if !@active_battler.driver.movable?
        if @target_index < $game_party.members.size - 1
          @target_index += 1
        else
          @battle_step += 1
          @battle_proccess = 0
          @status_window.visible = true
        end
        return
      end
      @people_command_window.visible = false
      @tank_command_window.visible = true
      @tank_command_window.set_text(@active_battler.name)
      @tank_command_window.update
    end
    
    if Input.trigger?(Input::C)
      case @active_battler
      when Game_Actor
        case @people_command_window.cursor_index
        when BATTLECOMMANDPEOPLE_BATTLE
          @active_battler.current_action.kind = BATTLEPEOPLEACTIONKIND_BASIC
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_ATTACK
          @people_command_window.set_text(@active_battler.weapon == nil ? "徒手" : @active_battler.weapon.name)
          @status_window.visible = false
          @troop_window.visible = true
        when BATTLECOMMANDPEOPLE_ITEM
          if @active_battler.items.size == 0
            @status_window.visible = false
            $game_temp.clear_message_battle = true
            $game_temp.message_type = MESSAGE_TALK
            @message_window.set_pos
            $game_temp.message_text = "没有携带物品！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @message_window.set_pos
            @status_window.visible = true
            return
          end
          @active_battler.current_action.kind = BATTLEPEOPLEACTIONKIND_ITEM
          @item_window = Window_ItemSelect.new(@active_battler)
          @item_window.z = 8003
          @status_window.visible = false
        when BATTLECOMMANDPEOPLE_EQUIP
          @equip_window = Window_BattleEquip.new(@active_battler)
          @equip_window.z = 8003
          @status_window.visible = false
        when BATTLECOMMANDPEOPLE_HELP
          @help_window = Window_BattleHelp.new
          @help_window.z = 8003
          @status_window.visible = false
        end
      when Game_Tank
        case @tank_command_window.cursor_index
        when BATTLECOMMANDTANK_MAIN_CANNON
          if @active_battler.main_cannon == nil
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有装备主炮！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            
            return
          end
          
          if @active_battler.main_cannon.limited_quantity?
            if @active_battler.main_cannon.quantity_empty?
              @status_window.visible = false
              $game_temp.message_type = MESSAGE_TALK
              $game_temp.clear_message_battle = true
              @message_window.set_pos
              $game_temp.message_text = "弹仓为空！"
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
              $game_temp.message_type = MESSAGE_BATTLE
              @status_window.visible = true

              return
            end
          end
          
          if @active_battler.main_cannon.big_broken?
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "主炮损坏，无法攻击！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            return
            
          end
          
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_MAIN_CANNON
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ATTACK
          @tank_command_window.set_text(@active_battler.main_cannon.limited_quantity?\
            ? "弹仓  " + @active_battler.main_cannon.quantity_reality.to_s\
            : @active_battler.main_cannon.name)
          @status_window.visible = false
          @troop_window.visible = true
          return
        when BATTLECOMMANDTANK_ITEM
          if @active_battler.items.size == 0
            @status_window.visible = false
            $game_temp.clear_message_battle = true
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有携带物品！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @message_window.set_pos
            @status_window.visible = true
            return
          end
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_ITEM
          @item_window = Window_ItemSelect.new(@active_battler)
          @status_window.visible = false
          return
        when BATTLECOMMANDTANK_SUB_CANNON
          
          if @active_battler.sub_cannon == nil
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有装备副炮！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            
            return
          end
          
          if @active_battler.sub_cannon.limited_quantity?
            if @active_battler.sub_cannon.quantity_empty?
              @status_window.visible = false
              $game_temp.message_type = MESSAGE_TALK
              $game_temp.clear_message_battle = true
              @message_window.set_pos
              $game_temp.message_text = "弹仓为空！"
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
              $game_temp.message_type = MESSAGE_BATTLE
              @status_window.visible = true

              return
            end
          end
          
          if @active_battler.sub_cannon.big_broken?
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "副炮损坏，无法攻击！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            return
            
          end
          
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_SUB_CANNON
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ATTACK
          @tank_command_window.set_text(@active_battler.sub_cannon.limited_quantity?\
            ? "弹仓  " + @active_battler.sub_cannon.quantity_reality.to_s\
            : @active_battler.sub_cannon.name)
          @status_window.visible = false
          @troop_window.visible = true
          return
        when BATTLECOMMANDTANK_SPECIAL_CANNONBALL
          
          if @active_battler.main_cannon == nil
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有装备主炮！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            
            return
          end
          
          if @active_battler.underpan.special_cannonball == {}
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有特殊炮弹！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            
            return
          end
          
          if @active_battler.main_cannon.big_broken?
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "主炮损坏，无法攻击！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            return
            
          end
          
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_SPECIALCANNONBALL
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ATTACK
          @special_cannonball_window = Window_BattleSpecialCannonBall.new(@active_battler)
          @status_window.visible = false
          return
        when BATTLECOMMANDTANK_SE
          
          if @active_battler.se == nil
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "没有装备SE！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            
            return
          end
          
          if @active_battler.se.limited_quantity?
            if @active_battler.se.quantity_empty?
              @status_window.visible = false
              $game_temp.message_type = MESSAGE_TALK
              $game_temp.clear_message_battle = true
              @message_window.set_pos
              $game_temp.message_text = "弹仓为空！"
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
              $game_temp.message_type = MESSAGE_BATTLE
              @status_window.visible = true

              return
            end
          end
          
          if @active_battler.se.big_broken?
            
            @status_window.visible = false
            $game_temp.message_type = MESSAGE_TALK
            $game_temp.clear_message_battle = true
            @message_window.set_pos
            $game_temp.message_text = "SE损坏，无法攻击！"
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
            $game_temp.message_type = MESSAGE_BATTLE
            @status_window.visible = true
            return
            
          end
          
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_SE
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ATTACK
          @tank_command_window.set_text(@active_battler.se.limited_quantity?\
            ? "弹仓  " + @active_battler.se.quantity_reality.to_s\
            : @active_battler.se.name)
          @status_window.visible = false
          @troop_window.visible = true
          return
        when BATTLECOMMANDTANK_HELP
          @help_window = Window_BattleHelp.new
          @help_window.z = 8003
          @status_window.visible = false
          return
        end
      end
    end
    
    if Input.trigger?(Input::B)
      if @target_index > 0
        @target_index -= 1
        return
      end
    end
  end
  
  def update_troop_select
    @troop_window.update
    if Input.trigger?(Input::C)
      @active_battler.current_action.target_index = @troop_window.cursor_index
      if !(@target_index < $game_party.members.size - 1)
        @battle_step += 1
        @battle_proccess = 0
        @troop_window.visible = false
        @status_window.visible = true
        return
      end
      @target_index += 1
      while $game_party.members[@target_index].dead?\
        || ($game_party.members[@target_index].is_a?(Game_Actor)\
        ? !$game_party.members[@target_index].movable?\
        : !$game_party.members[@target_index].driver.movable?)
        if @target_index < $game_party.members.size - 1
          @target_index += 1
        else
          @battle_step += 1
          @battle_proccess = 0
          @troop_window.visible = false
          @status_window.visible = true
          return
        end
      end
      @troop_window.visible = false
      case @active_battler.current_action.kind
      when BATTLETANKACTIONKIND_ITEM
        @item_window.visible = true
      when BATTLETANKACTIONKIND_SPECIALCANNONBALL
        @special_cannonball.visible = true
      else
        @status_window.visible = true
      end
      return
    end
    
    if Input.trigger?(Input::B)
      @troop_window.visible = false
      @status_window.visible = true
      return
    end
  end
  
  def update_item_select
    @item_window.update
    if Input.trigger?(Input::C)
      item = @active_battler.items[@item_window.cursor_index]
      @active_battler.current_action.item_id = item.id
      case item.scope
=begin
效果范围（0：无，1：敌单体，2：敵一組, 3：敌全体，4：己方单体， 5：己方全体，
6：己方单体（HP 0），7：己方全体（HP 0），8：使用者）。
=end
      when 0, 4, 5, 6, 7, 8
        case @active_battler
        when Game_Actor
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_ITEM_SELF
        when Game_Tank
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ITEM_SELF
        end
        @item_window.visible = false
        @status_window.visible = true
        if !(@target_index < $game_party.members.size - 1)
          @battle_step += 1
          @battle_proccess = 0
          return
        end
        @target_index += 1
        while $game_party.members[@target_index].dead?\
        || ($game_party.members[@target_index].is_a?(Game_Actor)\
        ? !$game_party.members[@target_index].movable?\
        : !$game_party.members[@target_index].driver.movable?)
          if @target_index < $game_party.members.size - 1
            @target_index += 1
          else
            @battle_step += 1
            @battle_proccess = 0
            return
          end
        end
        return
      when 1, 2, 3
        case @active_battler
        when Game_Actor
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_ATTACK
        when Game_Tank
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ATTACK
        end
        @item_window.visible = false
        @troop_window.visible = true
        return
      end
    end
    
    if Input.trigger?(Input::B)
      @item_window.visible = false
      @status_window.visible = true
      return
    end
  end
  
  def update_equip_select
    @equip_window.update
    if Input.trigger?(Input::C)
      @equip_window.visible = false
      equipment = @active_battler.equipments[@equip_window.cursor_index]
      $game_temp.message_type = MESSAGE_TALK
      @message_window.set_pos
      $game_temp.clear_message_battle = true
      if !@active_battler.equippable?(equipment)
        $game_temp.message_text = "不能装备" + equipment.name + "！"
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
        $game_temp.message_type = MESSAGE_BATTLE
        @message_window.set_pos
        @status_window.visible = true
        return
      end
      $game_temp.message_type = MESSAGE_TALK
      @message_window.set_pos
      $game_temp.clear_message_battle = true
      case equipment
      when RPG::Weapon
        kind = 0
      when RPG::Armor
        kind = equipment.kind + 1
      end
      result = @active_battler.equip(kind, equipment)
      case result
      when EQUIPRESULT_DROP
        $game_temp.message_text = "取下了" + equipment.name + "！"
      when EQUIPRESULT_PICK
        $game_temp.message_text = "装备了" + equipment.name + "！"
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
      $game_temp.message_type = MESSAGE_BATTLE
      @message_window.set_pos
      @status_window.visible = true
      return
    end
    
    if Input.trigger?(Input::B)
      @equip_window.visible = false
      @status_window.visible = true
      return
    end
  end
  
  def update_special_cannonnball_select
    @special_cannonball_window.update
    @tank_command_window.set_text(\
      "弹仓  " +  @active_battler.underpan.special_cannonball[@special_cannonball_window.get_cannonball.id].to_s)
    if Input.trigger?(Input::C)
      cannonball = @special_cannonball_window.get_cannonball
      @active_battler.current.specialcannonball_id = cannonball.id
      @troop_window.visible = true
      @special_cannonball_window.visible = false
      return
    end
    
    if Input.trigger?(Input::B)
      @special_cannonball_window.visible = false
      @status_window.visible = true
      return
    end
  end
  
  def update_help
    @help_window.update
    if Input.trigger?(Input::C)
      case @help_window.cursor_index
      when BATTLEHELP_UPDOWN
        @help_window.visible = false
        $game_temp.message_type = MESSAGE_TALK
        @message_window.set_pos
        $game_temp.clear_message_battle = true
        case @active_battler
        when Game_Tank
          $game_temp.message_text = "下车！"
          index = $game_party.members.index(@active_battler)
          $game_party.updown_in_battle(index)
        when Game_Actor
          if @active_battler.tank == nil
            $game_temp.message_text = "附近没有车！"
          elsif @active_battler.tank.underpan.big_broken
            $game_temp.message_text = "附近没有车！"
          else
            $game_temp.message_text = "上车！"
            index = $game_party.members.index(@active_battler)
            $game_party.updown_in_battle(index)
          end
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
        $game_temp.message_type = MESSAGE_BATTLE
        @message_window.set_pos
        @status_window.visible = true
        return
      when BATTLEHELP_STATUS
        @status_window.visible = false
        $game_temp.message_type = MESSAGE_TALK
        @message_window.set_pos
        case @active_battler
        when Game_Actor
          actor = @active_battler
          tank = @active_battler.tank
        when Game_Tank
          actor = @active_battler.driver
          tank = @active_battler
        end
        actor_str = ""
        actor_str += actor.name + " | "
        for i in 0...actor.states.size
          actor_str += $data_states[actor.states[i]].name + "|"
        end
        if tank != nil
          tank_str = ""
          tank_str += tank.name + " | "
          for i in 0...tank.states.size
            tank_str += $data_states[tank.states[i]].name + "|"
          end
          if tank.states == []
            tank_str = tank.name + "| 正常！|"
          end
        end
        if actor.states == []
          actor_str = actor.name + "| 正常！|"
        end
        if tank_str != nil
          str = actor_str + tank_str
        else
          str = actor_str
        end
        
        @help_window.visible = false
        $game_temp.message_type = MESSAGE_TALK
        @message_window.set_pos
        $game_temp.message_text = str
        
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
        $game_temp.clear_message_battle = true
        @message_window.terminate_message
        $game_temp.message_type = MESSAGE_BATTLE
        @message_window.set_pos
        @status_window.visible = true
      when BATTLEHELP_ESCAPE
        case @active_battler
        when Game_Actor
          @active_battler.current_action.kind = BATTLEPEOPLEACTIONKIND_BASIC
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_ESCAPE
        when Game_Tank
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_ITEM
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_ESCAPE
        end
        
        if !(@target_index < $game_party.members.size - 1)
          @battle_step += 1
          @battle_proccess = 0
          @help_window.visible = false
          @status_window.visible = true
          return
        end
        @target_index += 1
        while $game_party.members[@target_index].dead?\
        || ($game_party.members[@target_index].is_a?(Game_Actor)\
        ? !$game_party.members[@target_index].movable?\
        : !$game_party.members[@target_index].driver.movable?)
          if @target_index < $game_party.members.size - 1
            @target_index += 1
          else
            @battle_step += 1
            @battle_proccess = 0
            @help_window.visible = false
            @status_window.visible = true
            return
          end
        end
      when BATTLEHELP_GUARD
        case @active_battler
        when Game_Actor
          @active_battler.current_action.kind = BATTLEPEOPLEACTIONKIND_BASIC
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_GUARD
        when Game_Tank
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_ITEM
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_GUARD
        end
        
        if !(@target_index < $game_party.members.size - 1)
          @battle_step += 1
          @battle_proccess = 0
          @help_window.visible = false
          @status_window.visible = true
          return
        end
        @target_index += 1
        while $game_party.members[@target_index].dead?\
        || ($game_party.members[@target_index].is_a?(Game_Actor)\
        ? !$game_party.members[@target_index].movable?\
        : !$game_party.members[@target_index].driver.movable?)
          if @target_index < $game_party.members.size - 1
            @target_index += 1
          else
            @battle_step += 1
            @battle_proccess = 0
            @help_window.visible = false
            @status_window.visible = true
            return
          end
        end
      when BATTLEHELP_PROTECT
        case @active_battler
        when Game_Actor
          @active_battler.current_action.kind = BATTLEPEOPLEACTIONKIND_BASIC
          @active_battler.current_action.basic = BATTLEPEOPLEACTIONBASIC_PROTECT
        when Game_Tank
          @active_battler.current_action.kind = BATTLETANKACTIONKIND_ITEM
          @active_battler.current_action.basic = BATTLETANKACTIONBASIC_PROTECT
        end
        
        if !(@target_index < $game_party.members.size - 1)
          @battle_step += 1
          @battle_proccess = 0
          @help_window.visible = false
          @status_window.visible = true
          return
        end
        @target_index += 1
        while $game_party.members[@target_index].dead?\
        || ($game_party.members[@target_index].is_a?(Game_Actor)\
        ? !$game_party.members[@target_index].movable?\
        : !$game_party.members[@target_index].driver.movable?)
          if @target_index < $game_party.members.size - 1
            @target_index += 1
          else
            @battle_step += 1
            @battle_proccess = 0
            @help_window.visible = false
            @status_window.visible = true
            return
          end
        end
      end
      @help_window.visible = false
      @status_window.visible = true
      return
    end
    
    if Input.trigger?(Input::B)
      @help_window.visible = false
      @status_window.visible = true
      return
    end
  end
end