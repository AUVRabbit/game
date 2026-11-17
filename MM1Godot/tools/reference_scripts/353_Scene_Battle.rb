class Scene_Battle
  
  include MM_System
  include MM_DataBase
  
  def main
    # 记录队伍
    $game_temp.message_type = MESSAGE_BATTLE
    $game_temp.members_in_battle = []
    $game_temp.members_in_battle = $game_party.members
    # 初始化战斗用的各种暂时数据
    $game_temp.in_battle = true
    $game_temp.battle_turn = 0
    $game_temp.battle_event_flags.clear
    $game_temp.battle_abort = false
    $game_temp.battle_main_phase = false
    $game_temp.battleback_name = $game_map.battleback_name
    $game_temp.forcing_battler = nil
    # 初始化战斗用事件解释器
    $game_system.battle_interpreter.setup(nil, 0)
    # 准备队伍
    @troop_id = $game_temp.battle_troop_id
    $game_troop.setup(@troop_id)
    @message_window = Window_Message.new
    # 生成活动块
    @spriteset = Spriteset_Battle.new
    # 初始化等待计数
    @wait_count = 0
    
    @status_window = Window_BattleStatus.new
    @status_window.z = 8003
    #@status_window.visible = false
    @dialog_window = Window_BattleDialog.new
    @dialog_window.visible = false
    @dialog_window.z = 8002
    @troop_window = Window_BattleTroopList.new
    @troop_window.visible = false
    @troop_window.z = 8002
    @people_command_window = Window_BattlePeopleCommand.new
    @people_command_window.z = 8002
    @tank_command_window = Window_BattleTankCommand.new
    @tank_command_window.visible = false
    @tank_command_window.z = 8002
    
    @dead_enemies = []
    
    @actors_escape = false
    
    # 执行过渡
    if $data_system.battle_transition == ""
      Graphics.transition(20)
    else
      Graphics.transition(40, "Graphics/Transitions/" +
        $data_system.battle_transition)
    end
      
    @battle_step = BATTLESTEP_COMMAND
    @target_index = 0
    
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面
      update
      # 如果画面切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 刷新地图
    $game_map.refresh
    # 准备过渡
    Graphics.freeze

    @status_window.dispose
    @dialog_window.dispose
    @troop_window.dispose
    @people_command_window.dispose
    @tank_command_window.dispose
    @message_window.dispose
    
    @item_window.dispose if @item_window != nil
    @equip_window.dispose if @equip_window != nil
    @help_window.dispose if @help_window != nil
    
    # 释放活动块
    @spriteset.dispose
    # 标题画面切换中的情况
    if $scene.is_a?(Scene_Title)
      # 淡入淡出画面
      Graphics.transition
      Graphics.freeze
    end
    # 战斗测试或者游戏结束以外的画面切换中的情况
    if $BTEST and not $scene.is_a?(Scene_Gameover)
      $scene = nil
    end
  end
  
  def update
    # 执行战斗事件中的情况下
    if $game_system.battle_interpreter.running?
      # 刷新解释器
      $game_system.battle_interpreter.update
      # 强制行动的战斗者不存在的情况下
      if $game_temp.forcing_battler == nil
        # 执行战斗事件结束的情况下
        unless $game_system.battle_interpreter.running?
          # 继续战斗的情况下、再执行战斗事件的设置
          unless judge
            setup_battle_event
          end
        end
        # 如果不是结束战斗回合的情况下
        if @phase != 5
          # 刷新状态窗口
          @status_window.refresh
        end
      end
    end
    # 系统 (计时器)、刷新画面
    $game_system.update
    $game_screen.update
    # 计时器为 0 的情况下
    if $game_system.timer_working and $game_system.timer == 0
      # 中断战斗
      $game_temp.battle_abort = true
    end
    # 处理过渡中的情况下
    if $game_temp.transition_processing
      # 清除处理过渡中标志
      $game_temp.transition_processing = false
      # 执行过渡
      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" +
          $game_temp.transition_name)
      end
    end
    
    @spriteset.update
    
#    $game_temp.battling = true
    case @battle_step
    when BATTLESTEP_COMMAND
      update_command
    when BATTLESTEP_BATTLE
      update_battle
    when BATTLESTEP_END
      update_end
    end
    
    # 显示信息窗口中的情况下
    #if $game_temp.message_window_showing
    #  return
    #end
    # 显示效果中的情况下
    if @spriteset.effect?
      return
    end
    # 游戏结束的情况下
    if $game_temp.gameover
      # 切换到游戏结束画面
      $scene = Scene_Gameover.new
      return
    end
    # 返回标题画面的情况下
    if $game_temp.to_title
      # 切换到标题画面
      $scene = Scene_Title.new
      return
    end
    # 中断战斗的情况下
    if $game_temp.battle_abort
      # 还原为战斗前的 BGM
      $game_system.bgm_play($game_temp.map_bgm)
      # 战斗结束
      battle_end(1)
      return
    end
    # 等待中的情况下
    if @wait_count > 0
      # 减少等待计数
      @wait_count -= 1
      return
    end
    # 强制行动的角色存在、
    # 并且战斗事件正在执行的情况下
    if $game_temp.forcing_battler == nil and
       $game_system.battle_interpreter.running?
      return
    end
    

    
  end
  
  #--------------------------------------------------------------------------
  # ● 胜负判定
  #--------------------------------------------------------------------------
  def judge
    if @actors_escape
      return true
    end
    # 全灭判定是真、并且同伴人数为 0 的情况下
    if $game_party.all_dead? or $game_party.members.size == 0
      # 允许失败的情况下
      if $game_temp.battle_can_lose
        # 还原为战斗开始前的 BGM
        $game_system.bgm_play($game_temp.map_bgm)
        # 战斗结束
        battle_end(2)
        # 返回 true
        return true
      end
      # 设置游戏结束标志
      $game_temp.gameover = true
      # 返回 true
      return true
    end
    # 如果存在任意 1 个敌人就返回 false
    #for enemy in $game_troop.enemies
    #  if enemy.exist?
    #    return false
    #  end
    #end
    if $game_troop.enemies != []
      return false
    end
    # 返回 true
    return true
  end
  
  #--------------------------------------------------------------------------
  # ● 战斗结束
  #     result : 結果 (0:胜利 1:失败 2:逃跑)
  #--------------------------------------------------------------------------
  def battle_end(result)
    # 清除战斗中标志
    $game_temp.in_battle = false
    # 清除全体同伴的行动
    $game_party.clear_actions
    # 解除战斗用状态
    for actor in $game_party.actors
      actor.remove_states_battle
    end
    # 清除敌人
    $game_troop.enemies.clear
    # 调用战斗返回
    if $game_temp.battle_proc != nil
      $game_temp.battle_proc.call(result)
      $game_temp.battle_proc = nil
    end
    $game_temp.message_type = MESSAGE_TALK
    # 切换到地图画面
    $scene = Scene_Map.new
  end
  
  #--------------------------------------------------------------------------
  # ● 设置战斗事件
  #--------------------------------------------------------------------------
  def setup_battle_event
    # 正在执行战斗事件的情况下
    if $game_system.battle_interpreter.running?
      return
    end
    # 搜索全部页的战斗事件
    for index in 0...$data_troops[@troop_id].pages.size
      # 获取事件页
      page = $data_troops[@troop_id].pages[index]
      # 事件条件可以参考 c
      c = page.condition
      # 没有指定任何条件的情况下转到下一页
      unless c.turn_valid or c.enemy_valid or
             c.actor_valid or c.switch_valid
        next
      end
      # 执行完毕的情况下转到下一页
      if $game_temp.battle_event_flags[index]
        next
      end
      # 确认回合条件
      if c.turn_valid
        n = $game_temp.battle_turn
        a = c.turn_a
        b = c.turn_b
        if (b == 0 and n != a) or
           (b > 0 and (n < 1 or n < a or n % b != a % b))
          next
        end
      end
      # 确认敌人条件
      if c.enemy_valid
        enemy = $game_troop.enemies[c.enemy_index]
        if enemy == nil or enemy.hp * 100.0 / enemy.maxhp > c.enemy_hp
          next
        end
      end
      # 确认角色条件
      if c.actor_valid
        actor = $game_actors[c.actor_id]
        if actor == nil or actor.hp * 100.0 / actor.maxhp > c.actor_hp
          next
        end
      end
      # 确认开关条件
      if c.switch_valid
        if $game_switches[c.switch_id] == false
          next
        end
      end
      # 设置事件
      $game_system.battle_interpreter.setup(page.list, 0)
      # 本页的范围是 [战斗] 或 [回合] 的情况下
      if page.span <= 1
        # 设置执行结束标志
        $game_temp.battle_event_flags[index] = true
      end
      return
    end
  end
end