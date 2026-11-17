class Scene_Battle
  
  def update_battle
    
    #先生成战斗结果，再播放动画（方便局域网对战的数据传送）
    case @battle_proccess
    when 0
      #初始化战斗
      init_battle
    when 1
      #准备战斗
      ready_for_battle
    when 2
      #获取战斗结果
      result_battle
    when 3
      #战斗（包括动画播放）
      do_battle
    when 4
      #结束一个战斗循环
      end_turn_battle
    end
    return
  end

  def init_battle
    # 回合数计数
    $game_temp.battle_turn += 1
    # 搜索全页的战斗事件
    for index in 0...$data_troops[@troop_id].pages.size
      # 获取事件页
      page = $data_troops[@troop_id].pages[index]
      # 本页的范围是 [回合] 的情况下
      if page.span == 1
        # 设置已经执行标志
        $game_temp.battle_event_flags[index] = false
      end
    end
    @active_battler = nil
    @people_command_window.visible = false
    @tank_command_window.visible = false
    @status_window.visible = false
    @dialog_window.visible = true
    # 设置主回合标志
    $game_temp.battle_main_phase = true
    # 生成敌人行动
    for enemy_ary in $game_troop.enemies
      for enemy in enemy_ary
        enemy.make_action
      end
    end
    
    # 生成行动顺序
    make_action_orders
    
    #初始化行动序列数组
    @battle_sequence = []
        
    # 移动到步骤 1
    @battle_proccess += 1
    return
  end
  
  def ready_for_battle
    # 强制行动的战斗者不存在的情况下
    if $game_temp.forcing_battler == nil
      # 设置战斗事件
      setup_battle_event
      # 执行战斗事件中的情况下
      if $game_system.battle_interpreter.running?
        return
      end
    end
    # 强制行动的战斗者存在的情况下
    if $game_temp.forcing_battler != nil
      # 在头部添加后移动
      @action_battlers.delete($game_temp.forcing_battler)
      @action_battlers.unshift($game_temp.forcing_battler)
    end
    # 初始化动画 ID 和公共事件 ID
    @animation1_id = 0
    @animation2_id = 0
    @animation3_id = 0
    @common_event_id = 0
    # 未行动的战斗者移动到序列的头部
    @active_battler = @action_battlers.shift
    # 如果已经在战斗之外的情况下
#    if @active_battler.index == nil
#      return
#    end
    #print @active_battlers if @active_battler == nil
    # 刷新状态窗口
    #@dialog_window.refresh
    #@status_window.refresh
    @battle_proccess += 1
    return
  end
  
  def result_battle
    # 如果不是强制行动
    
    if @active_battler == nil
      if @action_battlers == [] || @action_battlers == nil
        @battle_proccess += 1
        return
      else
        @battle_proccess = 1
        return
      end
    end

    if @active_battler.current_action != nil
      unless @active_battler.current_action.forcing
        # 限制为 [敌人为普通攻击] 或 [我方为普通攻击] 的情况下
        if @active_battler.restriction == 2 or @active_battler.restriction == 3
          # 设置行动为攻击
          @active_battler.current_action.kind = 0
          @active_battler.current_action.basic = 0
        end
        # 限制为 [不能行动] 的情况下
        if @active_battler.restriction == 4
          # 清除行动强制对像的战斗者
          $game_temp.forcing_battler = nil
          # 移至步骤 1
          @battle_proccess = 1
          return
        end
      end
    end
    # 清除对像战斗者
    @target_battlers = []
    make_status_result
    case @active_battler
    when Game_Actor
      case @active_battler.current_action.kind
      when BATTLEPEOPLEACTIONKIND_BASIC
        case @active_battler.current_action.basic
        when BATTLEPEOPLEACTIONBASIC_ATTACK
          make_people_attack_result
        when BATTLEPEOPLEACTIONBASIC_GUARD
          make_people_guard_result
        when BATTLEPEOPLEACTIONBASIC_PROTECT
          make_people_protect_result
        when BATTLEPEOPLEACTIONBASIC_ESCAPE
          make_people_escape_result
        end
      when BATTLEPEOPLEACTIONKIND_ITEM
        case @active_battler.current_action.basic
        when BATTLEPEOPLEACTIONBASIC_ATTACK
          make_people_item_attack_result
        when BATTLEPEOPLEACTIONBASIC_ITEM_SELF
          make_people_item_effect_result
        end
      end
    when Game_Tank
      case @active_battler.current_action.kind
      when BATTLETANKACTIONKIND_MAIN_CANNON
        make_tank_main_cannon_attack_result
      when BATTLETANKACTIONKIND_SUB_CANNON
        make_tank_sub_cannon_attack_result
      when BATTLETANKACTIONKIND_SE
        make_tank_se_attack_result
      when BATTLETANKACTIONKIND_SPECIALCANNONBALL
        make_tank_specialcannonball_attack_result
      when BATTLETANKACTIONKIND_ITEM
        case @active_battler.current_action.basic
        when BATTLETANKACTIONBASIC_ATTACK
          make_tank_item_battle_result
        when BATTLETANKACTIONBASIC_ITEM_SELF
          make_tank_item_effect_result
        when BATTLETANKACTIONBASIC_GUARD
          make_tank_guard_result
        when BATTLETANKACTIONBASIC_PROTECT
          make_tank_protect_result
        when BATTLETANKACTIONBASIC_ESCAPE
          make_tank_escape_result
        end
      end
    when Game_Enemy
      case @active_battler.current_action.kind
      when 0 # 基本
        case @active_battler.current_action.basic
        when 0 # 攻擊
          make_enemy_attack_result
        when 1 # 防禦
          make_enmey_guard_result
        when 2 # 逃跑
          make_enemy_escape_result
        when 3 # 什麼都不做
          make_enmey_nothing_result
        end
      when 1 # 特技
        make_enemy_skill_result
      end
    end
    if @action_battlers == []
      @battle_proccess += 1
    else
      @battle_proccess = 1
    end
    return
  end
  
  def do_battle
    #开始播放动画
    for i in 0...@battle_sequence.size
      battle_sequence_single = @battle_sequence.shift
      #先刷新狀態文本
      if battle_sequence_single.param == BATTLESEQUENCEPARAM_STATUS
        $game_temp.message_text = battle_sequcen_single.message
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @message_window.at_end = false
        loop do 
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        @message_window.terminate_message
        next
      end
      
      msg = battle_sequence_single.message
      
      #逃跑的情況下
      if battle_sequence_single.param == BATTLESEQUENCEPARAM_ESCAPE_SUCCESS\
        || battle_sequence_single.param == BATTLESEQUENCEPARAM_ESCAPE_FAILURE
        $game_temp.message_text = msg
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
        if battle_sequence_single.param == BATTLESEQUENCEPARAM_ESCAPE_SUCCESS
          case battle_sequence_single.battle_tar
          when Game_Actor
            @actors_escape = true
            @battle_proccess = 4
            return
          when Game_Tank
            @actors_escape = true
            @battle_proccess = 4
            return
          when Game_Enemy
            battle_sequence.battle_tar.escape
          end
        end
        next
      end
      
      #有结果信息的情况下
      if msg.include?("|")  
        msg_ary = msg.split(/\|/)
        now_msg = msg_ary[0]
        $game_temp.message_text = now_msg
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        #loop do
        #  Graphics.update
        #  Input.update
        #  if Input.trigger?(Input::C)
        #    break
        #  end
        #end
        @message_window.terminate_message
        
        #需要的内容
        animation1_id = battle_sequence_single.action_ary[0]
        animation2_id = battle_sequence_single.action_ary[1]
        animation3_id = battle_sequence_single.action_ary[2]
        
        scr_battle = battle_sequence_single.battle_src
        tar_battle_ary = battle_sequence_single.battle_tar
        
        #先播放我方动画
        if animation1_id != 0
          scr_battle.animation_id = animation1_id
          animation = $data_animations[animation1_id]
          frame_count = animation.frame_max
          (frame_count + 20).times {Graphics.update; scr_battle.battle_sprite.update}#@spriteset.update}
        else
          5.times {Graphics.update}
        end
        
        #再播放弹道动画（如果有）
        if animation2_id != 0
          sprite_animation = RPG::Sprite.new
          sprite_animation.bitmap = Bitmap.new(64, 64)
          sprite_animation.x = scr_battle.battle_sprite.x
          sprite_animation.y = scr_battle.battle_sprite.y
          sprite_animation.z = 9999
          animation = $data_animations[animation2_id]
          
          #多人攻击只取第一个为第一目标
          tar_battle = tar_battle_ary[0]
          #计算X、Y之差
          x_dec = scr_battle.battle_sprite.x - tar_battle.battle_sprite.x
          y_dec = scr_battle.battle_sprite.y - tar_battle.battle_sprite.y
        
          sprite_animation.loop_animation(animation)
          frame_count = animation.frame_max
          frame_count += 20
        
          loop do
            Graphics.update
            Input.update
            if frame_count <= 0
              break
            end
            sprite_animation.x -= x_dec / animation.frame_max
            sprite_animation.y -= y_dec / animation.frame_max
            frame_count -= 1
          end
          
          sprite_animation.loop_animation(nil)
        else
          5.times {Graphics.update}
        end
        
        #最后播放对方动画
        for i in 0...tar_battle_ary.size
          tar_battle = tar_battle_ary[i]
          if animation3_id != 0

            #tar_battle.animation_id = animation3_id
            animation = $data_animations[animation3_id]
            frame_count = animation.frame_max
            tar_battle.battle_sprite.loop_animation(animation)
            (frame_count + 20).times {Graphics.update; @spriteset.update}
            tar_battle.battle_sprite.loop_animation(nil)
            #@spriteset.update

            #@spriteset.update
          else
            5.times {Graphics.update}
          end
          #如果死掉
          
          if battle_sequence_single.param == BATTLESEQUENCEPARAM_UNDERPAN_BROKEN
            if battle_sequence_single.ex_param.include?(tar_battle)
              tar_battle.battle_sprite.can_change = true
              tar_battle.battle_sprite.update
              tar_battle.battle_sprite.can_change = false
            end
          end
          
          if tar_battle.dead?
            if battle_sequence_single.param == BATTLESEQUENCEPARAM_DEAD
              
              if battle_sequence_single.ex_param.include?(tar_battle)
              
                case tar_battle
                when Game_Actor
                  tar_battle.set_graphic(CHARACTER_DEADBODY, 0, BATTLER_DEADBODY, 0)
                  #@spriteset.update
                when Game_Enemy
                  @dead_enemies.push(tar_battle)
                  if DATA_ENEMY_BOSS.include?(tar_battle.id)
                    #如果是BOSS
                    sprite_mask = Sprite.new
                    sprite_mask.bitmap =\
                      Bitmap.new(tar_battle.battle_sprite.bitamp.width + 8, 5)
                    sprite_mask.bitmap.fill_rect(0, 0, sprite_mask.bitmap.width, 5, Color.new(0, 0, 0))
                    sprite_mask.x = tar_battle.battle_sprite.x - 4
                    sprite_mask.y = tar_battle.battle_sprite.y - 4
                    for i in 0...80
                      Graphics.update
                      sprite_mask.bitmap.height += (tar_battle.battle_sprite.bitamp.width + 8) / 80
                    end
                    tar_battle.battle_sprite.visible = false
                    #@spriteset.update
                  else
                    5.times do
                      3.times {Graphics.update}
                      tar_battle.battle_sprite.opacity -= 100
                      3.times {Graphics.update}
                      tar_battle.battle_sprite.opacity += 100
                    end
                    tar_battle.battle_sprite.visible = false
                    #tar_battle.battle_sprite.update
                    #@spriteset.update
                  end
                end
              end
            end
          end
        end
        
        for i in 1...msg_ary.size
          now_msg = "|" + msg_ary[i] + " | "
          
          for i in 0...$game_party.members.size
            member = $game_party.members[i]
            if now_msg.include?(member.name) && (now_msg.include?("损伤") || now_msg.include?("HP回复"))
              @dialog_window.refresh_actor(member)
              break
            end
          end
          
          #if /的攻击/ =~ now_msg
          #  next
          #end
          $game_temp.message_text = now_msg
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
=begin
          loop do
            Graphics.update
            Input.update
            if Input.trigger?(Input::C)
              break
            end
          end
=end
          @message_window.terminate_message
          if /全灭/ =~ now_msg
            @battle_proccess = 0
            @battle_step = BATTLESTEP_END
            return
          end
        end
        
      else
        
      #没结果信息的情况下
        now_msg = "|" + msg + "|"
        $game_temp.message_text = now_msg
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @message_window.terminate_message
=begin
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        
=end
      end
    end
    @dialog_window.refresh
    @status_window.refresh
    # 清除强制行动对像的战斗者
    $game_temp.forcing_battler = nil
    # 公共事件 ID 有效的情况下
    if @common_event_id > 0
      # 设置事件
      common_event = $data_common_events[@common_event_id]
      $game_system.battle_interpreter.setup(common_event.list, 0)
    end
    #$game_temp.battling = false
    @battle_proccess = 4
    return
  end
  
  def end_turn_battle
    #清除死掉对象
    size = $game_troop.enemies.size
    for j in 0...size
      enemy_ary = $game_troop.enemies[j]
      next if enemy_ary == nil
      for i in 0...enemy_ary.size
        enemy = enemy_ary[i]
        if enemy == nil
          enemy_ary.delete_at(i)
          next
        end
        if enemy.dead?
          enemy_ary.delete_at(i)
        end
        if enemy_ary == []
          $game_troop.enemies.delete_at(j)
        end
      end
    end

    @status_window.refresh
    @dialog_window.refresh
    @troop_window.refresh
    
    @battle_step = BATTLESTEP_END
    @battle_proccess = 0
    return
  end
  
  #--------------------------------------------------------------------------
  # ● 生成行动循序
  #--------------------------------------------------------------------------
  def make_action_orders
    # 初始化序列 @action_battlers
    @action_battlers = []
    # 生成敌人行动
    for enemy_ary in $game_troop.enemies
      for enemy in enemy_ary
        @action_battlers.push(enemy)
      end
    end
    # 添加角色到 @action_battlers 序列
    for actor in $game_party.members
      @action_battlers.push(actor)
    end
    # 确定全体的行动速度
    for battler in @action_battlers
      battler.make_action_speed
    end
    # 按照行动速度从大到小排列
    @action_battlers.sort! {|a,b|
      b.current_action.speed - a.current_action.speed }
  end
end