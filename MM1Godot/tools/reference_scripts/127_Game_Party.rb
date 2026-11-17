#==============================================================================
# ■ Game_Party
#------------------------------------------------------------------------------
# 　处理同伴的类。包含金钱以及物品的信息。本类的实例
# 请参考 $game_party。
#==============================================================================

class Game_Party
  include MM_DataBase
  include MM_System
  
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_reader   :actors                   # 角色
  attr_reader   :tanks                    # 战车
  attr_accessor :members                  # 成员
  attr_reader   :gold                     # 金钱
  attr_reader   :steps                    # 步数
  attr_reader   :tow_tank                 # 牵引战车
  attr_accessor :rent_tanks               # 出租戰車
  attr_reader   :trunk                    # 後備箱
  
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize
    # 建立角色序列
    @actors = []
    # 建立戰車序列
    @tanks = []
    # 建立隊伍序列
    @members = []
    # 初始化牵引战车
    @tow_tank = nil
    # 初始化出租戰車
    @rent_tanks = []
    # 初始化後備箱
    @trunk = []
    # 初始化金钱与步数
    @gold = 0
    @steps = 0
  end
  
  def trunk_add_item(item)
    @trunk.push(item) if item != nil
  end
  
  def trunk_remove_item(index)
    @trunk.delete_at(index)
  end
  
  def tank_equipments_broken?
    for tank in @tanks
      return true if tank.main_cannon.big_broken? || tank.main_cannon.little_broken?
      return true if tank.sub_cannon.big_broken? || tank.main_cannon.little_broken?
      return true if tank.se.status.big_broken? || tank.se.little_broken?
      return true if tank.engine.big_broken? || tank.main_cannon.little_broken?
      return true if tank.equipment.big_broken? || tank.main_cannon.little_broken?
    end
    return false
  end
  
  def get_tank_broken_equipments
    broken_equipments_ary = []
    for tank_index in 0...@tanks.size
      tank = @tanks[tank_index]
      now_tank = nil
      if tank.main_cannon.little_broken? || tank.main_cannon.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.main_cannon)
        #p tank.main_cannon.object_id
        #p broken_equipments_ary[broken_equipments_ary.size - 1][1].last.object_id
      end
      
      if tank.sub_cannon.little_broken? || tank.sub_cannon.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.sub_cannon)
      end
      
      if tank.se.little_broken? || tank.se.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.se)
      end
      
      if tank.engine.little_broken? || tank.engine.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.engine)
      end
      
      if tank.c_unit.little_broken? || tank.c_unit.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.c_unit)
      end
      
      if tank.underpan.little_broken? || tank.underpan.big_broken?
        if broken_equipments_ary[broken_equipments_ary.size] == nil && now_tank != tank
          now_tank = tank
          broken_equipments_ary[broken_equipments_ary.size] = []
          broken_equipments_ary[broken_equipments_ary.size - 1].push(tank)
          broken_equipments_ary[broken_equipments_ary.size - 1].push([])
        end
        broken_equipments_ary[broken_equipments_ary.size - 1][1].push(tank.underpan)
      end
    end
    return broken_equipments_ary
  end
  
  def set_cpl_party
    @members.push(@tow_tank) if @tow_tank != nil
  end
  
  def recover_org_party
    @members.delete(@tow_tank) if @tow_tank != nil
  end
  
  def tank_broken?
    if @tanks == []
      return false
    end
    
    for tank in $game_party.tanks
      if tank.engine != nil
        if tank.engine.big_broken? || tank.c_unit.big_broken?
          return true
        end
      else
        return true
      end
    end
    return false
  end
  
  def tank_overload?
    for tank in $game_party.tanks
      if tank.overload?
        return true
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 设置初期同伴
  #--------------------------------------------------------------------------
  def setup_starting_members
    @actors = []
    @members = []
    @tanks = []
    @tow_tank = nil
    for i in $data_system.party_members
      @actors.push($game_actors[i])
      @members.push($game_actors[i])
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 同伴成员的还原
  #--------------------------------------------------------------------------
  def refresh
    # 游戏数据载入后角色对像直接从 $game_actors
    # 分离。
    # 回避由于载入造成的角色再设置的问题。
    new_actors = []
    new_tanks = []
    new_members = []
    for i in 0...@actors.size
      if $data_actors[@actors[i].id] != nil
        new_actors.push($game_actors[@actors[i].id])
      end
    end
    for i in 0...@tanks.size
      if $data_tanks[@tanks[i].id] != nil
        new_tanks.push($game_tanks[@tanks[i].id])
      end
    end
    for i in 0...@members.size
      member = @members[i]
      case member
      when Game_Actor
        if $data_actors[@members[i].id] != nil
          new_members.push($game_actors[@members[i].id])
        end
      when Game_Tank
        if $data_tanks[@members[i].id] != nil
          new_members.push($game_tanks[@members[i].id])
        end
      end
    end
    @tow_tank = $game_tanks[@tow_tank.id] if @tow_tank != nil
    @actors = new_actors
    @tanks = new_tanks
    @members = new_members
  end
  
  #--------------------------------------------------------------------------
  # ● 获取最大等级
  #--------------------------------------------------------------------------
  def max_level
    # 同伴人数为 0 的情况下
    if @actors.size == 0
      return 0
    end
    # 初始化本地变量 level
    level = 0
    # 求得同伴的最大等级
    for actor in @actors
      if level < actor.level
        level = actor.level
      end
    end
    return level
  end
  
  #--------------------------------------------------------------------------
  # ● 加入同伴
  #     actor_id : 角色 ID
  #--------------------------------------------------------------------------
  def add_actor(actor_id)
    # 获取角色
    actor = $game_actors[actor_id]
    # 同伴人数未满 4 人、本角色不在队伍中的情况下
    if @members.size < 4 and not @actors.include?(actor)\
        and not @members.include?(actor)
      # 添加角色
      @actors.push(actor)
      @members.push(actor)
      # 还原主角
      $game_players.refresh
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 角色离开
  #     actor_id : 角色 ID
  #--------------------------------------------------------------------------
  def remove_actor(actor_id)
    # 删除角色
    @actors.delete($game_actors[actor_id])
    @members.delete($game_actors[actor_id])
    # 还原主角
    $game_players.refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 加入戰車
  #     tank_id : 战车 ID
  #--------------------------------------------------------------------------
  def add_tank(index, tank_id)
    # 获取角色
    tank = $game_tanks[tank_id]
    #p tank.id
    # 同伴人数未满 4 人、本角色不在队伍中的情况下
    if @members.size < 4 and not @tanks.include?(tank)\
        and not @members.include?(tank)
      # 添加角色
      @tanks.push(tank)
      @members[index] = tank
      #p index, @members[index].name
      # 还原主角
      $game_players.refresh
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 戰車离开
  #     tank_id : 角色 ID
  #--------------------------------------------------------------------------
  def remove_tank(index, tank_id)
    # 删除角色
    @tanks.delete($game_tanks[tank_id])
    @members[index] = $game_tanks[tank_id].driver
    # 还原主角
    $game_players.refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 加入牵引
  #     tank_id : 战车 ID
  #--------------------------------------------------------------------------
  def add_tow_tank(tank_id)
    @tow_tank = $game_tanks[tank_id] if $game_tanks[tank_id] != nil
    $game_players.refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 取消牵引
  #--------------------------------------------------------------------------
  def remove_tow_tank
    @tow_tank = nil
    $game_players.refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 乘降（大地图）
  #--------------------------------------------------------------------------
  def updown(member_index)
    #tanks_graphics = []
    actor = @actors[member_index]
    player = $game_players.players[member_index]
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
=begin
      for i in 0...DATA_TANK.size
        if DATA_TANK[i] != nil
          tanks_graphics.push(DATA_TANK[i][2])
        end
      end
      
      $game_map.add_event(player.x, player.y,\
        actor.tank.character_name, actor.tank.character_name,\
        player.tank_event_id,\
        player.direction, true)
      player.tank_event_id = nil
      
=end
      remove_tank(member_index, actor.tank.id)
      actor.get_off
      Audio.se_play("Audio/SE/" + SE_UPDOWN, 100, 100)
      $game_temp.message_text = actor.name + "下车！"
      return
    else
      for event in $game_map.events.values
        if event.x == player.x\
          && event.y == player.y
          tanks_keys = $game_map.tanks_position.keys.sort!
          for i in 0...tanks_keys.size
            tanks_ary = $game_map.tanks_position[tanks_keys[i]]
            if $game_map.map_id == tanks_ary[2]\
              && event.x == tanks_ary[0]\
              && event.y == tanks_ary[1]
              tank_id = tanks_keys[i]
              #p tank_id
              break
            end
          end
          if tank_id == nil
            $game_temp.message_text = "没有战车，无法乘降！"
            return
          end
          tank = $game_tanks[tank_id]
          #p tank_id + 1
          player.tank_event_id = 200 + tank_id
          $game_map.tanks_position.delete(tank_id)
          #p $game_map.tanks_position
=begin
          for i in 0...DATA_TANK.size
            if DATA_TANK[i] != nil
              tanks_graphics.push(DATA_TANK[i][2])
            end
          end
          character_name = event.character_name
          if tanks_graphics.include?(character_name)
            tank = $game_tanks[tanks_graphics.index(character_name) + 1]
            index = tanks_graphics.index(character_name)
            #index = $game_tanks.index(tank)
            player.tank_event_id = 1900 + index
=end
            actor.get_on(tank)
            add_tank(member_index, tank.id)
            $game_map.delete_event(event.id)
            Audio.se_play("Audio/SE/" + SE_UPDOWN, 100, 100)
            $game_temp.message_text = actor.name + "上车！"
            return
          #end
        end
      end
      $game_temp.message_text = "没有战车，无法乘降！"
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 乘降（战斗）
  #--------------------------------------------------------------------------
  def updown_in_battle(index)
    case $game_party.members[index]
    when Game_Actor
      $game_party.members[index] = $game_party.members[index].tank
    when Game_Tank
      $game_party.members[index] = $game_party.members[index].driver
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 增加金钱 (减少)
  #     n : 金额
  #--------------------------------------------------------------------------
  def gain_gold(n)
    @gold = [[@gold + n, 0].max, 9999999].min
  end
  
  #--------------------------------------------------------------------------
  # ● 减少金钱
  #     n : 金额
  #--------------------------------------------------------------------------
  def lose_gold(n)
    # 调用数值逆转 gain_gold 
    gain_gold(-n)
  end
  
  #--------------------------------------------------------------------------
  # ● 增加步数
  #--------------------------------------------------------------------------
  def increase_steps
    @steps = [@steps + 1, 9999999].min
  end
  
  #--------------------------------------------------------------------------
  # ● 判断物品可以使用
  #     item_id : 物品 ID
  #--------------------------------------------------------------------------
  def item_can_use?(item_id, user)
    case user
    when Game_Actor
      # 获取可以使用的时候
      occasion = $data_actor_items[item_id].occasion
    when Game_Tank
      occasion = $data_tank_items[item_id].occasion
    end
    # 战斗的情况
    if $game_temp.in_battle
      # 可以使用时为 0 (平时) 或者是 1 (战斗时) 可以使用
      return (occasion == 0 or occasion == 1 or occasion == 2 or occasion == 3)
    end
    # 可以使用时为 0 (平时) 或者是 2 (菜单时) 可以使用
    return (occasion == 0 or occasion == 2 or occasion == 3)
  end
  
  #--------------------------------------------------------------------------
  # ● 清除全体的行动
  #--------------------------------------------------------------------------
  def clear_actions
    # 清除全体同伴的行为
    for member in @members
      member.current_action.clear
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 可以输入命令的判定
  #--------------------------------------------------------------------------
  def inputable?
    # 如果一可以输入命令就返回 true
    for member in @members
      if member.inputable?
        return true
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 全灭判定
  #--------------------------------------------------------------------------
  def all_dead?
    # 同伴人数为 0 的情况下
    if $game_party.members.size == 0
      return false
    end
    # 同伴中无人 HP 在 0 以上
    for actor in @actors
      if actor.hp > 0
        return false
      end
    end
    # 全灭
    return true
  end
  
  #--------------------------------------------------------------------------
  # ● 检查连续伤害 (地图用)
  #--------------------------------------------------------------------------
  def check_map_slip_damage
    for member in @actors
      if member.hp > 0 and member.slip_damage?
        member.hp -= [member.maxhp / 100, 1].max
        if member.hp == 0
          $game_system.se_play($data_system.actor_collapse_se)
        end
        $game_screen.start_flash(Color.new(255,0,0,128), 4)
        $game_temp.gameover = $game_party.all_dead?
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 对像角色的随机确定
  #     hp0 : 限制为 HP 0 的角色
  #--------------------------------------------------------------------------
  def random_target_member(hp0 = false)
    # 初始化轮流
    roulette = []
    # 循环
    for member in @members
     case member
     when Game_Actor
        # 符合条件的场合
        if (not hp0 and member.exist?) or (hp0 and member.hp0?)
          # 获取角色职业的位置 [位置]
          position = $data_classes[member.class_id].position
          # 前卫的话 n = 4、中卫的话 n = 3、后卫的话 n = 2
          n = 4 - position
          # 添加角色的轮流 n 回
          n.times do
            roulette.push(member)
          end
        end
      when Game_Tank
        # 符合条件的场合
        if member.exist? or member.hp0?
          # 获取角色职业的位置 [位置]
          #position = $data_classes[member.class_id].position
          position = 2
          # 前卫的话 n = 4、中卫的话 n = 3、后卫的话 n = 2
          n = 4 - position
          # 添加角色的轮流 n 回
          n.times do
            roulette.push(member)
          end
        end
      end
    end
    # 轮流大小为 0 的情况
    if roulette.size == 0
      return nil
    end
    # 转轮盘赌，决定角色
    return roulette[rand(roulette.size)]
  end
  
  #--------------------------------------------------------------------------
  # ● 对像角色的随机确定 (HP 0)
  #--------------------------------------------------------------------------
  def random_target_member_hp0
    return random_target_member(true)
  end
  
  #--------------------------------------------------------------------------
  # ● 对像角色的顺序确定
  #     member_index : 角色索引
  #--------------------------------------------------------------------------
  def smooth_target_member(member_index)
    # 取得对像
    member = @members[member_index]
    # 对像存在的情况下
    if member != nil and member.exist?
      return member
    end
    # 循环
    for member in @members
      # 对像存在的情况下
      if member.exist?
        return member
      end
    end
  end
end
