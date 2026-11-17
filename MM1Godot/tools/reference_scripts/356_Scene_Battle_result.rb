class Scene_Battle
  
  def escape_ready(side)
    # 计算敌人速度的平均值
    enemies_agi = 0
    enemies_number = 0
    for enemy_ary in $game_troop.enemies
      for enemy in enemy_ary
        if enemy.exist?
          enemies_agi += enemy.agi
          enemies_number += 1
        end
      end
    end
    if enemies_number > 0
      enemies_agi /= enemies_number
    end
    # 计算角色速度的平均值
    actors_agi = 0
    actors_number = 0
    for actor in $game_party.actors
      if actor.exist?
        actors_agi += actor.agi
        actors_number += 1
      end
    end
    if actors_number > 0
      actors_agi /= actors_number
    end
    # 逃跑成功判定
    if side == ESCAPESIDE_ACTOR
      success = rand(100) < 50 * actors_agi / enemies_agi
    elsif side == ESCAPESIDE_ENEMY
      success = rand(100) < 50 * enemies_agi / actors_agi
    end
    # 成功逃跑的情况下
    return success
  end
  
  def make_status_result
    all_str = ""
    for i in 0...@active_battler.states.size
      status = @active_battler.status[i]
      str = status.battle_message_effect
      str = sprintf(str, @active_battler.name)
      all_str += "|" if all_str != ""
      all_str += str
    end
    # 连续伤害
    if @active_battler.hp > 0 and @active_battler.slip_damage?
      result, str = @active_battler.slip_damage_effect
      all_str += "|" if all_str != ""
      all_str += str
      #@active_battler.damage_pop = true
    end
    
    # 自然解除状态
    str = @active_battler.remove_states_auto
    all_str += "|" if all_str != ""
    all_str += str
    
    if all_str != ""
      battle_sequence_single = Game_BattleSequenceSingle.new
      battle_sequence_single.message = all_str
      battle_sequence_single.param = BATTLESEQUENCEPARAM_STATUS
      @battle_sequence.push(battle_sequence_single)
    end    
    return
  end
  
  def make_people_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.animation1_id
    @animation2_id = @active_battler.animation2_id
    @animation3_id = @active_battler.animation3_id
    if @active_battler.restriction == 3
      target = $game_party.random_target_member
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    elsif @active_battler.restriction == 2
      target = $game_troop.random_target_enemy
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    else
      index = @active_battler.current_action.target_index
      target = $game_troop.smooth_target_enemy(index)
      # 如果武器可以攻击一组
      if @active_battler.weapon.range_type == RANGE_GROUP
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      elsif @active_battler.weapon.range_type == RANGE_ALL
        @target_battlers = []
        for enemy_ary in $game_troop.enemies
          for enemy in enemy_ary
            @target_battlers.push(enemy)
          end
        end
      else
        @target_battlers = [target] if !target.is_a?(Array)
      end
    end
    # 应用通常攻击效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result, msg = target.attack_effect(@active_battler)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_people_guard_result
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|在防御！|"
    battle_sequence_single.param = BATTLESEQUENCEPARAM_GUARD
    @battle_sequence.push(battle_sequence_single)
    #防御
    return
  end
  
  def make_people_protect_result
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|在保护同伴！|"
    battle_sequence_single.param = BATTLESEQUENCEPARAM_PROTECT
    @battle_sequence.push(battle_sequence_single)
    #保护
    return
  end
  
  def make_people_escape_result
    result = escape_ready(ESCAPESIDE_ACTOR)
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_tar = @active_battler
    if result == true
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_SUCCESS
      battle_sequence_single.message = @active_battler.name + "|逃走了！|"
    else
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_FAILURE
      battle_sequence_single.message = @active_battler.name + "|逃走了！|但是被怪物包围了！|"
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_people_item_attack_result
    # 获取物品
    @item = $data_items[@active_battler.current_action.item_id]
    # 因为物品耗尽而无法使用的情况下
    unless $game_party.item_can_use?(@item.id, @active_battler)
      # 移至步骤 1
      @battle_proccess = 1
      battle_sequence_single = Game_BattleSequenceSingle.new
      battle_sequence_single.message = sprintf(VOCAB_NOEFFECT, @active_battler.name, item.name)
      @battle_sequence.push(battle_sequence_single)
      return
    end
    # 消耗品的情况下
    if @item.consumable
      # 使用的物品减 1
      @active_battler.lose_item(@item_window.cursor_index)
    end
    # 设置动画 ID
    @animation1_id = @item.animation1_id
    @animation2_id = @item.animation2_id
    @animation3_id = @item.animation3_id
    # 设置公共事件 ID
    @common_event_id = @item.common_event_id
    # 确定对像
    index = @active_battler.current_action.target_index
    target = $game_party.smooth_target_actor(index)
    # 设置对像侧战斗者
    set_target_battlers(@item.scope)
    # 应用物品效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.item_effect(@item, @active_battler)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_people_item_effect_result
    # 获取物品
    @item = $data_actor_items[@active_battler.current_action.item_id]
    # 因为物品耗尽而无法使用的情况下
    unless $game_party.item_can_use?(@item.id, @active_battler)
      # 移至步骤 1
      @battle_proccess = 1
      return
    end
    # 消耗品的情况下
    if @item.consumable
      # 使用的物品减 1
      @active_battler.lose_item(@item_window.cursor_index)
    end
    # 设置动画 ID
    @animation1_id = @item.animation1_id
    @animation2_id = @item.animation2_id
    @animation3_id = @item.animation3_id
    # 设置公共事件 ID
    @common_event_id = @item.common_event_id
    # 确定对像
    index = @active_battler.current_action.target_index
    target = $game_party.smooth_target_actor(index)
    # 设置对像侧战斗者
    set_target_battlers(@item.scope)
    # 应用物品效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.item_effect(@item, @active_battler)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_tank_main_cannon_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.main_cannon.animation1_id
    @animation2_id = @active_battler.main_cannon.animation2_id
    @animation3_id = @active_battler.main_cannon.animation3_id
    if @active_battler.main_cannon.limited_quantity?
      @active_battler.main_cannon.quantity_use
    end
    if @active_battler.restriction == 3
      target = $game_party.random_target_member
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    elsif @active_battler.restriction == 2
      target = $game_troop.random_target_enemy
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    else
      index = @active_battler.current_action.target_index
      target = $game_troop.smooth_target_enemy(index)
      # 如果武器可以攻击一组
      if @active_battler.main_cannon.range_type == RANGE_GROUP
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      elsif @active_battler.main_cannon.range_type == RANGE_ALL
        @target_battlers = []
        for enemy_ary in $game_troop.enemies
          for enemy in enemy_ary
            @target_battlers.push(enemy)
          end
        end
      else
        @target_battlers = [target]
      end
    end
    # 设置对像方的战斗者序列
    @target_battlers = [target]
    # 应用通常攻击效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.attack_effect(@active_battler, @active_battler.main_cannon)
      
      battle_sequence_single.message += "| " + msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_tank_sub_cannon_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.sub_cannon.animation1_id
    @animation2_id = @active_battler.sub_cannon.animation2_id
    @animation3_id = @active_battler.sub_cannon.animation3_id
    if @active_battler.sub_cannon.limited_quantity?
      @active_battler.sub_cannon.quantity_use
    end

    if @active_battler.restriction == 3
      target = $game_party.random_target_member
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    elsif @active_battler.restriction == 2
      target = $game_troop.random_target_enemy
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    else
      index = @active_battler.current_action.target_index
      target = $game_troop.smooth_target_enemy(index)
      # 如果武器可以攻击一组
      if @active_battler.sub_cannon.range_type == RANGE_GROUP
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      elsif @active_battler.sub_cannon.range_type == RANGE_ALL
        @target_battlers = []
        for enemy_ary in $game_troop.enemies
          for enemy in enemy_ary
            @target_battlers.push(enemy)
          end
        end
      else
        @target_battlers = [target]
      end
    end
    # 设置对像方的战斗者序列
    @target_battlers = [target]
    # 应用通常攻击效果    
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.attack_effect(@active_battler, @active_battler.sub_cannon)
      
      battle_sequence_single.message += "| " + msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_tank_se_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.se.animation1_id
    @animation2_id = @active_battler.se.animation2_id
    @animation3_id = @active_battler.se.animation3_id
    if @active_battler.se.limited_quantity?
      @active_battler.se.quantity_use
    end
    if @active_battler.restriction == 3
      target = $game_party.random_target_member
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    elsif @active_battler.restriction == 2
      target = $game_troop.random_target_enemy
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    else
      index = @active_battler.current_action.target_index
      target = $game_troop.smooth_target_enemy(index)
      # 如果武器可以攻击一组
      if @active_battler.se.range_type == RANGE_GROUP
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      elsif @active_battler.se.range_type == RANGE_ALL
        @target_battlers = []
        for enemy_ary in $game_troop.enemies
          for enemy in enemy_ary
            @target_battlers.push(enemy)
          end
        end
      else
        @target_battlers = [target]
      end
    end
    # 设置对像方的战斗者序列
    @target_battlers = [target]
    # 应用通常攻击效果    
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.attack_effect(@active_battler, @active_battler.se)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_tank_specialcannonball_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.main_cannon.animation1_id
    @animation2_id = @active_battler.main_cannon.animation2_id
    @animation3_id = @active_battler.main_cannon.animation3_id
    @active_battler.underpan.special_cannonball_use(@active_battler.current_action.specialcannonball_id)
    if @active_battler.restriction == 3
      target = $game_party.random_target_member
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    elsif @active_battler.restriction == 2
      target = $game_troop.random_target_enemy
      # 设置对像方的战斗者序列
      @target_battlers = [target]
    else
      index = @active_battler.current_action.target_index
      target = $game_troop.smooth_target_enemy(index)
      # 如果武器可以攻击一组
      if @active_battler.main_cannon.range_type == RANGE_GROUP
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      elsif @active_battler.main_cannon.range_type == RANGE_ALL
        @target_battlers = []
        for enemy_ary in $game_troop.enemies
          for enemy in enemy_ary
            @target_battlers.push(enemy)
          end
        end
      else
        @target_battlers = [target]
      end
    end
    # 设置对像方的战斗者序列
    @target_battlers = [target]
    # 应用通常攻击效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.special_cannonball_effect(@active_battler, @active_battler.current_action.specialcannonball_id)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)

    return
  end
  
  def make_tank_item_battle_result
    # 获取物品
    @item = $data_items[@active_battler.current_action.item_id]
    # 因为物品耗尽而无法使用的情况下
    unless $game_party.item_can_use?(@item.id, @active_battler)
      # 移至步骤 1
      @battle_proccess = 1
      return
    end
    # 消耗品的情况下
    if @item.consumable
      # 使用的物品减 1
      @active_battler.lose_item(@item_window.cusor_index)
    end
    # 设置动画 ID
    @animation1_id = @item.animation1_id
    @animation2_id = @item.animation2_id
    @animation3_id = @item.animation3_id
    # 设置公共事件 ID
    @common_event_id = @item.common_event_id
    # 确定对像
    index = @active_battler.current_action.target_index
    target = $game_party.smooth_target_actor(index)
    # 设置对像侧战斗者
    set_target_battlers(@item.scope)
    # 应用物品效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.item_effect(@item, @active_battler)
      
      battle_sequence_single.message += "| " + msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end
      
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_tank_item_effect_result
    # 获取物品
    @item = $data_tank_items[@active_battler.current_action.item_id]
    # 因为物品耗尽而无法使用的情况下
    unless $game_party.item_can_use?(@item.id, @active_battler)
      # 移至步骤 1
      @battle_proccess = 1
      return
    end
    # 消耗品的情况下
    if @item.consumable
      # 使用的物品减 1
      @active_battler.lose_item(@item_window.cusor_index)
    end
    # 设置动画 ID
    @animation1_id = @item.animation1_id
    @animation2_id = @item.animation2_id
    @animation3_id = @item.animation3_id
    # 设置公共事件 ID
    @common_event_id = @item.common_event_id
    # 确定对像
    index = @active_battler.current_action.target_index
    target = $game_party.smooth_target_actor(index)
    # 设置对像侧战斗者
    set_target_battlers(@item.scope)
    # 应用物品效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.item_effect(@item)
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      
      if target.dead?
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_DEAD
        end
        if battle_sequence_single.ex_param == nil
          battle_sequence_single.ex_param = []
          battle_sequence_single.ex_param.push(target)
        else
          battle_sequence_single.ex_param.push(target)
        end
      end

      
    end
    @battle_sequence.push(battle_sequence_single)

  end
  
  def make_tank_guard_result
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|在防御！|"
    battle_sequence_single.param = BATTLESEQUENCEPARAM_GUARD
    @battle_sequence.push(battle_sequence_single)
    #防御
    return
  end
  
  def make_tank_protect_result
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|在保护同伴！|"
    battle_sequence_single.param = BATTLESEQUENCEPARAM_PROTECT
    @battle_sequence.push(battle_sequence_single)
    #保护
    return
  end
  
  def make_tank_escape_result
    #逃跑
    result = escape_ready(ESCAPESIDE_ACTOR)
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_tar = @active_battler
    if result == true
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_SUCCESS
      battle_sequence_single.message = @active_battler.name + "|逃走了！|"
    else
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_FAILURE
      battle_sequence_single.message = @active_battler.name + "|逃走了！|但是被怪物包围了！|"
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_enemy_attack_result
    # 设置攻击 ID
    @animation1_id = @active_battler.animation1_id
    @animation2_id = @active_battler.animation2_id
    @animation3_id = @active_battler.animation3_id
    # 行动方的战斗者是敌人的情况下
    if @active_battler.is_a?(Game_Enemy)
      if @active_battler.restriction == 3
        target = $game_troop.random_target_enemy
      elsif @active_battler.restriction == 2
        target = $game_party.random_target_member
      else
        index = @active_battler.current_action.target_index
        target = $game_party.smooth_target_member(index)
      end
    end
    # 设置对像方的战斗者序列
    @target_battlers = [target]
    # 应用通常攻击效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg, underpan_broken = target.attack_effect(@active_battler)
      
      if underpan_broken
        if battle_sequence_single.param == nil
          battle_sequence_single.param = BATTLESEQUENCEPARAM_UNDERPAN_BROKEN
          if battle_sequence_single.ex_param == nil
            battle_sequence_single.ex_param = []
            target.battle_sprite.can_change = false
            battle_sequence_single.ex_param.push(target)
          else
            target.battle_sprite.can_change = false
            battle_sequence_single.ex_param.push(target)
          end
        end
      end
      
      battle_sequence_single.message += " | " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      #如果全灭
      if $game_party.all_dead?
        battle_sequence_single.message += " | " + "队伍全灭了！"
      end
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_enmey_guard_result
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|在防御！|"
    battle_sequence_single.param = BATTLESEQUENCEPARAM_GUARD
    @battle_sequence.push(battle_sequence_single)
    #防御
    return
  end
  
  def make_enemy_escape_result
    result = @active_battler.escape_ready(ESCAPESIDE_ENEMY)
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_tar = @active_battler
    if result == true
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_SUCCESS
      battle_sequence_single.message = @active_battler.name + "|逃走了！|"
    else
      battle_sequence_single.param = BATTLESEQUENCEPARAM_ESCAPE_FAILURE
      battle_sequence_single.message = @active_battler.name + "|逃走了！|但是失败了！|"
    end
    @battle_sequence.push(battle_sequence_single)
    return
  end
  
  def make_enmey_nothing_result
    # 清除强制行动对像的战斗者
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.message = @active_battler.name + "|什么都不做！|"
    @battle_sequence.push(battle_sequence_single)
    $game_temp.forcing_battler = nil
    return
  end
  
  def make_enemy_skill_result
    # 获取特技
    @skill = $data_skills[@active_battler.current_action.skill_id]
    # 如果不是强制行动
    unless @active_battler.current_action.forcing
      # 因为 SP 耗尽而无法使用的情况下
      unless @active_battler.skill_can_use?(@skill.id)
        # 清除强制行动对像的战斗者
        $game_temp.forcing_battler = nil
        # 移至步骤 1
        @battle_proccess = 1
        return
      end
    end
    # 消耗 SP
    @active_battler.sp -= @skill.sp_cost
    # 刷新状态窗口
    @status_window.refresh
    @dialog_window.refresh
    # 设置动画 ID
    @animation1_id = @skill.animation1_id
    @animation2_id = @skill.animation2_id
    @animation3_id = @skill.animation3_id
    # 设置公共事件 ID
    @common_event_id = @skill.common_event_id
    # 设置对像侧战斗者
    set_target_battlers(@skill.scope)
    # 应用特技效果
    battle_sequence_single = Game_BattleSequenceSingle.new
    battle_sequence_single.battle_src = @active_battler
    battle_sequence_single.battle_tar = @target_battlers
    battle_sequence_single.action_ary = [@animation1_id, @animation2_id, @animation3_id]
    for target in @target_battlers
      result,msg = target.skill_effect(@active_battler, @skill)
      battle_sequence_single.message += "| " if battle_sequence_single.message != ""
      battle_sequence_single.message += msg
      #如果全灭
      if $game_party.all_dead?
        battle_sequence_single.message += " | " + "队伍全灭了！|"
      end
    end
    @battle_sequence.push(battle_sequence_single)

    return
  end
  
  #--------------------------------------------------------------------------
  # ● 设置物品或特技对像方的战斗者
  #     scope : 特技或者是物品的范围
  #--------------------------------------------------------------------------
  def set_target_battlers(scope)
    # 行动方的战斗者是敌人的情况下
    if @active_battler.is_a?(Game_Enemy)
      # 效果范围分支
      case scope
      when 1  # 敌单体
        index = @active_battler.current_action.target_index
        @target_battlers.push($game_party.smooth_target_actor(index))
      when 2  # 敌全体
        for actor in $game_party.actors
          if actor.exist?
            @target_battlers.push(actor)
          end
        end
      when 3  # 我方单体
        index = @active_battler.current_action.target_index
        @target_battlers.push($game_troop.smooth_target_enemy(index))
        @target_battlers.push(@active_battler)
      when 4  # 我方全体
        for enemy in $game_troop.enemies
          if enemy.exist?
            @target_battlers.push(enemy)
          end
        end
      when 5  # 我方单体 (HP 0) 
        index = @active_battler.current_action.target_index
        enemy = $game_troop.enemies[index]
        if enemy != nil and enemy.hp0?
          @target_battlers.push(enemy)
        end
      when 6  # 我方全体 (HP 0) 
        for enemy in $game_troop.enemies
          if enemy != nil and enemy.hp0?
            @target_battlers.push(enemy)
          end
        end
      when 7  # 使用者
        @target_battlers.push(@active_battler)
      end
    end
    # 行动方的战斗者是角色的情况下
    
=begin
scope 
效果范围（0：无，1：敌单体，2：敵一組, 3：敌全体，4：己方单体， 5：己方全体，
6：己方单体（HP 0），7：己方全体（HP 0），8：使用者）。

occasion 
可能使用时（0：平时，1：战斗中，2：菜单中，3：不能使用）。
=end

    if @active_battler.is_a?(Game_Actor)
      # 效果范围分支
      case scope
      when 0  # 無效
        @target_battlers.push(@active_battler)
      when 1  # 敌单体
        index = @active_battler.current_action.target_index
        @target_battlers.push($game_troop.smooth_target_enemy(index))
      when 2  # 敌一组
        @target_battlers = $game_troop.enemies[@active_battler.current_action.target_index]
      when 3  # 敌全体
        for enemy in $game_troop.enemies
          if enemy.exist?
            @target_battlers.push(enemy)
          end
        end
      when 4  # 我方单体
        #index = @active_battler.current_action.target_index
        #@target_battlers.push($game_party.smooth_target_actor(index))
        @target_battlers.push(@active_battler)
      when 5  # 我方全体
        for actor in $game_party.actors
          if actor.exist?
            @target_battlers.push(actor)
          end
        end
      when 6  # 我方单体 (HP 0) 
        index = @active_battler.current_action.target_index
        actor = $game_party.actors[index]
        if actor != nil and actor.hp0?
          @target_battlers.push(actor)
        end
      when 7  # 我方全体 (HP 0) 
        for actor in $game_party.actors
          if actor != nil and actor.hp0?
            @target_battlers.push(actor)
          end
        end
      when 8  # 使用者
        @target_battlers.push(@active_battler)
      end
    end
  end
end