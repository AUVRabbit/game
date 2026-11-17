#==============================================================================
# ■ Game_Actor
#------------------------------------------------------------------------------
# 　处理角色的类。本类在 Game_Actors 类 ($game_actors)
# 的内部使用、Game_Party 类请参考 ($game_party) 。
#==============================================================================

class Game_Actor < Game_Battler
  
  include MM_System
  
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_reader   :name                     # 名称
  attr_reader   :character_name           # 角色 文件名
  attr_reader   :character_hue            # 角色 色相
  attr_reader   :class_id                 # 职业 ID
  attr_reader   :weapon                   # 武器 ID
  attr_reader   :armor1                   # 头防具 ID
  attr_reader   :armor2                   # 身体防具 ID
  attr_reader   :armor3                   # 手防具 ID
  attr_reader   :armor4                   # 足防具 ID
  attr_reader   :armor5                   # 皮甲 ID
  attr_reader   :level                    # 等级
  attr_reader   :exp                      # EXP
  attr_reader   :items                    # 物品
  attr_reader   :equipments               # 武器
  attr_reader   :battle_level             # 戰鬥等級
  attr_reader   :fix_level                # 修理等级
  attr_reader   :driver_level             # 驾驶等级
  attr_reader   :tank                     # 乘具
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     actor_id : 角色 ID
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    super()
    setup(actor_id)
  end
  
  #--------------------------------------------------------------------------
  # ● 设置
  #     actor_id : 角色 ID
  #--------------------------------------------------------------------------
  def setup(actor_id)
    actor = $data_actors[actor_id]
    @actor_id = actor_id
    @name = actor.name
    @character_name = actor.character_name
    @character_hue = actor.character_hue
    @battler_name = actor.battler_name
    @battler_hue = actor.battler_hue
    @class_id = actor.class_id
    @weapon = $data_weapons[actor.weapon_id].clone if actor.weapon_id != 0
    @armor1 = $data_armors[actor.armor1_id].clone if actor.armor1_id != 0
    @armor2 = $data_armors[actor.armor2_id].clone if actor.armor2_id != 0
    @armor3 = $data_armors[actor.armor3_id].clone if actor.armor3_id != 0
    @armor4 = $data_armors[actor.armor4_id].clone if actor.armor4_id != 0
    @armor5 = $data_armors[actor.armor5_id].clone if actor.armor5_id != 0
    
    @equipments = []
    @items = []
    
    for equipment in [@weapon, @armor1, @armor2, @armor3, @armor4, @armor5]
      if equipment != nil
        @equipments.push(equipment)
      end
    end
    
    @plus_atk = 0
    @plus_pdef = 0
    @plus_hp = 0
    
    @level = actor.initial_level
    @exp_list = Array.new(101)
    make_exp_list
    @exp = @exp_list[@level]
    @skills = []
    @hp = maxhp
    @states = []
    @states_turn = {}
    @battle_level = 1
    @fix_level = 1
    @driver_level = 1
  end
  
  def battle_level_up
  end
  
  def fix_level_up
  end
  
  def driver_level_up
  end
  
  def equipments_package_full?
    return @equipments.size >= 8 ? true : false
  end
  
  def gain_equipments(item)
    @equipments.push(item)
  end
  
  def lose_equipments(index)
    item = @equipments[index]
    if @weapon.equal?(item)
      @weapon = nil
    elsif @armor1.equal?(item)
      @armor1 = nil
    elsif @armor2.equal?(item)
      @armor2 = nil
    elsif @armor3.equal?(item)
      @armor3 = nil
    elsif @armor4.equal?(item)
      @armor4 = nil
    elsif @armor5.equal?(item)
      @armor5 = nil
    end
      
    @equipments.delete_at(index)
  end
  
  def items_package_full?
    return @items.size >= 8 ? true : false
  end
  
  def gain_item(item)
    @items.push(item)
  end
  
  def lose_item(index)
    @items.delete_at(index)
  end
  
  def get_on(tank)
    @tank = tank
    @tank.set_driver(self)
  end
  
  def get_off
    @tank.set_driver(nil)
    @tank = nil
  end
  
  #--------------------------------------------------------------------------
  # ● 获取角色 ID 
  #--------------------------------------------------------------------------
  def id
    return @actor_id
  end
  
  #--------------------------------------------------------------------------
  # ● 获取索引
  #--------------------------------------------------------------------------
  def index
    return $game_party.actors.index(self)
  end
  
  #--------------------------------------------------------------------------
  # ● 计算 EXP
  #--------------------------------------------------------------------------
  def make_exp_list
    actor = $data_actors[@actor_id]
    @exp_list[1] = 0
    pow_i = 2.4 + actor.exp_inflation / 100.0
    for i in 2..100
      if i > actor.final_level
        @exp_list[i] = 0
      else
        n = actor.exp_basis * ((i + 3) ** pow_i) / (5 ** pow_i)
        @exp_list[i] = @exp_list[i-1] + Integer(n)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 取得属性修正值
  #     element_id : 属性 ID
  #--------------------------------------------------------------------------
  def element_rate(element_id)
    # 获取对应属性有效度的数值
    table = [0,200,150,100,50,0,-100]
    result = table[$data_classes[@class_id].element_ranks[element_id]]
    # 防具能防御本属性的情况下效果减半
    for armor in [@armor1, @armor2, @armor3, @armor4, @armor5]
      if armor != nil and armor.guard_element_set.include?(element_id)
        result /= 2
      end
    end
    # 状态能防御本属性的情况下效果减半
    for i in @states
      if $data_states[i].guard_element_set.include?(element_id)
        result /= 2
      end
    end
    # 过程结束
    return result
  end
  
  #--------------------------------------------------------------------------
  # ● 获取属性有效度
  #--------------------------------------------------------------------------
  def state_ranks
    return $data_classes[@class_id].state_ranks
  end
  
  #--------------------------------------------------------------------------
  # ● 判定防御属性
  #     state_id : 属性 ID
  #--------------------------------------------------------------------------
  def state_guard?(state_id)
    for armor in [@armor1, @armor2, @armor3, @armor4, @armor5]
      if armor != nil
        if armor.guard_state_set.include?(state_id)
          return true
        end
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击属性
  #--------------------------------------------------------------------------
  def element_set
    return @weapon != nil ? @weapon.element_set : []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击状态变化 (+)
  #--------------------------------------------------------------------------
  def plus_state_set
    return @weapon != nil ? @weapon.plus_state_set : []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击状态变化 (-)
  #--------------------------------------------------------------------------
  def minus_state_set
    return @weapon != nil ? @weapon.minus_state_set : []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取 MaxHP
  #--------------------------------------------------------------------------
  def maxhp
    return $data_actors[@actor_id].parameters[0, @level] + @plus_hp
  end
  
  #--------------------------------------------------------------------------
  # ● 获取力量（強度）
  #--------------------------------------------------------------------------
  def str
    n = $data_actors[@actor_id].parameters[2, @level]
    return [[n, 1].max, 999].min
  end
  
  #--------------------------------------------------------------------------
  # ● 获取灵巧（智力）
  #--------------------------------------------------------------------------
  def dex
    n = $data_actors[@actor_id].parameters[3, @level]
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # ● 获取速度（速度）
  #--------------------------------------------------------------------------
  def agi
    n = $data_actors[@actor_id].parameters[4, @level]
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # ● 获取魔力（體力）
  #--------------------------------------------------------------------------
  def int
    n = $data_actors[@actor_id].parameters[5, @level]
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # ● 获取基本攻击力
  #--------------------------------------------------------------------------
  def atk
    weapon = @weapon
    return weapon != nil ? weapon.atk  + @plus_atk : @plus_atk
  end
  
  #--------------------------------------------------------------------------
  # ● 获取物理防御
  #--------------------------------------------------------------------------
  def pdef
    pdef1 = @armor1 != nil ? @armor1.pdef : 0
    pdef2 = @armor2 != nil ? @armor2.pdef : 0
    pdef3 = @armor3 != nil ? @armor3.pdef : 0
    pdef4 = @armor4 != nil ? @armor4.pdef : 0
    pdef5 = @armor5 != nil ? @armor5.pdef : 0
    return pdef1 + pdef2 + pdef3 + pdef4 + pdef5 + @plus_pdef
  end

  #--------------------------------------------------------------------------
  # ● 获取回避修正
  #--------------------------------------------------------------------------
  def eva
    eva1 = @armor1 != nil ? @armor1.eva : 0
    eva2 = @armor2 != nil ? @armor2.eva : 0
    eva3 = @armor3 != nil ? @armor3.eva : 0
    eva4 = @armor4 != nil ? @armor4.eva : 0
    eva5 = @armor5 != nil ? @armor5.eva : 0
    return eva1 + eva2 + eva3 + eva4 + eva5
  end
  
  #--------------------------------------------------------------------------
  # ● 普通攻击 获取攻击方动画 ID
  #--------------------------------------------------------------------------
  def animation1_id
    return @weapon != nil ? @weapon.animation1_id : 0
  end
  
  #--------------------------------------------------------------------------
  # ● 普通攻击 获取彈道动画 ID
  #--------------------------------------------------------------------------
  def animation2_id
    return @weapon != nil ? @weapon.animation2_id : 0
  end
  
  #--------------------------------------------------------------------------
  # ● 普通攻击 获取对像方动画 ID
  #--------------------------------------------------------------------------
  def animation3_id
    return @weapon != nil ? @weapon.animation3_id : 0
  end
  
  #--------------------------------------------------------------------------
  # ● 获取职业名
  #--------------------------------------------------------------------------
  def class_name
    return $data_classes[@class_id].name
  end
  
  #--------------------------------------------------------------------------
  # ● 获取 EXP 字符串
  #--------------------------------------------------------------------------
  def exp_s
    return @exp_list[@level+1] > 0 ? @exp.to_s : "-------"
  end
  
  #--------------------------------------------------------------------------
  # ● 获取下一等级的 EXP 字符串
  #--------------------------------------------------------------------------
  def next_exp_s
    return @exp_list[@level+1] > 0 ? @exp_list[@level+1].to_s : "-------"
  end
  
  #--------------------------------------------------------------------------
  # ● 获取离下一等级还需的 EXP 字符串
  #--------------------------------------------------------------------------
  def next_rest_exp_s
    return @exp_list[@level+1] > 0 ?
      (@exp_list[@level+1] - @exp).to_s : "-------"
  end
  
  #--------------------------------------------------------------------------
  # ● 装备固定判定
  #     equip_type : 装备类型
  #--------------------------------------------------------------------------
  def equip_fix?(equip_type)
    case equip_type
    when 0  # 武器
      return $data_actors[@actor_id].weapon_fix
    when 1  # 头
      return $data_actors[@actor_id].armor1_fix
    when 2  # 身体
      return $data_actors[@actor_id].armor2_fix
    when 3  # 手
      return $data_actors[@actor_id].armor3_fix
    when 4  # 足
      return $data_actors[@actor_id].armor4_fix
    when 5  # 皮甲
      return $data_actors[@actor_id].armor5_fix
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 变更装备
  #     equip_type : 装备类型
  #     id    : 武器 or 防具 ID  (0 为解除装备)
  #--------------------------------------------------------------------------
  def equip(equip_type, equipment)
    case equip_type
    when 0  # 武器
      if equipment.equal?(@weapon)
        @weapon = nil
        return EQUIPRESULT_DROP
      else
        @weapon = equipment
        return EQUIPRESULT_PICK
      end
    when 1  # 头
      if equipment.equal?(@armor1)
        @armor1 = nil
        return EQUIPRESULT_DROP
      else
        @armor1 = equipment
        return EQUIPRESULT_PICK
      end
    when 2  # 身体
      if equipment.equal?(@armor2)
        @armor2 = nil
        return EQUIPRESULT_DROP
      else
        @armor2 = equipment
        return EQUIPRESULT_PICK
      end
    when 3  # 手
      if equipment.equal?(@armor3)
        @armor3 = nil
        return EQUIPRESULT_DROP
      else
        @armor3 = equipment
        return EQUIPRESULT_PICK
      end
    when 4  # 足
      if equipment.equal?(@armor4)
        @armor4 = nil
        return EQUIPRESULT_DROP
      else
        @armor4 = equipment
        return EQUIPRESULT_PICK
      end
    when 5  # 皮甲
      if equipment.equal?(@armor5)
        @armor5 = nil
        return EQUIPRESULT_DROP
      else
        @armor5 = equipment
        return EQUIPRESULT_PICK
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 可以装备判定
  #     item : 物品
  #--------------------------------------------------------------------------
  def equippable?(item)
    # 武器的情况
    if item.is_a?(RPG::Weapon)
      # 包含当前的职业可以装备武器的场合
      #if $data_classes[@class_id].weapon_set.include?(item.id)
      if item.can_equip_actors.include?(self.id)
        return true
      end
    end
    # 防具的情况
    if item.is_a?(RPG::Armor)
      # 不包含当前的职业可以装备武器的场合
      #if $data_classes[@class_id].armor_set.include?(item.id)
      if item.can_equip_actors.include?(self.id)
        return true
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 更改 EXP
  #     exp : 新的 EXP
  #--------------------------------------------------------------------------
  def exp=(exp)
    @exp = [[exp, 9999999].min, 0].max
    # 升级
    while @exp >= @exp_list[@level+1] and @exp_list[@level+1] > 0
      @level += 1
      @plus_atk += @str * rand(0.0, 1.0)
      @plus_pdef += @str * rand(0.0, 1.0)
      @plus_hp += @int * rand(0.0, 1.0)
    end
    # 降级
    while @exp < @exp_list[@level]
      @level -= 1
    end
    # 修正当前的 HP 与 SP 超过最大值
    @hp = [@hp, self.maxhp].min
  end
  
  #--------------------------------------------------------------------------
  # ● 更改等级
  #     level : 新的等级
  #--------------------------------------------------------------------------
  def level=(level)
    # 检查上下限
    level = [[level, $data_actors[@actor_id].final_level].min, 1].max
    # 更改 EXP
    self.exp = @exp_list[level]
  end
  
  #--------------------------------------------------------------------------
  # ● 更改名称
  #     name : 新的名称
  #--------------------------------------------------------------------------
  def name=(name)
    @name = name
  end
  
  #--------------------------------------------------------------------------
  # ● 更改图形
  #     character_name : 新的角色 文件名
  #     character_hue  : 新的角色 色相
  #     battler_name   : 新的战斗者 文件名
  #     battler_hue    : 新的战斗者 色相
  #--------------------------------------------------------------------------
  def set_graphic(character_name, character_hue, battler_name, battler_hue)
    @character_name = character_name
    @character_hue = character_hue
    @battler_name = battler_name
    @battler_hue = battler_hue
  end
  
  #--------------------------------------------------------------------------
  # ● 取得战斗画面的 X 坐标
  #--------------------------------------------------------------------------
  def screen_x
    # 返回计算后的队伍 X 坐标的排列顺序
    if self.index != nil
      return self.index * 160 + 80
    else
      return 0
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 取得战斗画面的 Y 坐标
  #--------------------------------------------------------------------------
  def screen_y
    return 464
  end
  
  #--------------------------------------------------------------------------
  # ● 取得战斗画面的 Z 坐标
  #--------------------------------------------------------------------------
  def screen_z
    # 返回计算后的队伍 Z 坐标的排列顺序
    if self.index != nil
      return 4 - self.index
    else
      return 0
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 全回复
  #--------------------------------------------------------------------------
  def recover_all
    @hp = maxhp
    for i in @states.clone
      remove_state(i)
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 附加状态
  #     state_id : 状态 ID
  #     force    : 强制附加标志 (处理自动状态时使用)
  #--------------------------------------------------------------------------
  def add_state(state_id, force = false)
    # 无效状态的情况下
    if $data_states[state_id] == nil
      # 过程结束
      return
    end
    # 无法强制附加的情况下
    unless force
      # 已存在的状态循环
      for i in @states
        # 新的状态和已经存在的状态 (-) 同时包含的情况下、
        # 本状态不包含变化为新状态的状态变化 (-) 
        # (ex : 战斗不能与附加中毒同时存在的场合)
        if $data_states[i].minus_state_set.include?(state_id) and
           not $data_states[state_id].minus_state_set.include?(i)
          # 过程结束
          return
        end
      end
    end
    # 无法附加本状态的情况下
    unless state?(state_id)
      # 状态 ID 追加到 @states 序列中
      #@states.clear
      @states.push(state_id)
      # 选项 [当作 HP 0 的状态] 有效的情况下
      if $data_states[state_id].zero_hp
        # HP 更改为 0
        @hp = 0
      end
      # 所有状态的循环
      for i in 1...$data_states.size
        # 状态变化 (+) 处理
        if $data_states[state_id].plus_state_set.include?(i)
          add_state(i)
        end
        # 状态变化 (-) 处理
        if $data_states[state_id].minus_state_set.include?(i)
          remove_state(i)
        end
      end
      # 按比例大的排序 (值相等的情况下按照强度排序)
      @states.sort! do |a, b|
        state_a = $data_states[a]
        state_b = $data_states[b]
        if state_a.rating > state_b.rating
          -1
        elsif state_a.rating < state_b.rating
          +1
        elsif state_a.restriction > state_b.restriction
          -1
        elsif state_a.restriction < state_b.restriction
          +1
        else
          a <=> b
        end
      end
    end
    # 强制附加的场合
    if force
      # 设置为自然解除的最低回数 -1 (无效)
      @states_turn[state_id] = -1
    end
    # 不能强制附加的场合
    unless  @states_turn[state_id] == -1
      # 设置为自然解除的最低回数
      @states_turn[state_id] = $data_states[state_id].hold_turn
    end
    # 无法行动的场合
    unless movable?
      # 清除行动
      @current_action.clear
    end
    # 检查 HP 及 SP 的最大值
    @hp = [@hp, self.maxhp].min
  end
  
  #--------------------------------------------------------------------------
  # ● 解除状态
  #     state_id : 状态 ID
  #     force    : 强制解除标志 (处理自动状态时使用)
  #--------------------------------------------------------------------------
  def remove_state(state_id, force = false)
    # 无法附加本状态的情况下
    if state?(state_id)
      # 被强制附加的状态、并不是强制解除的情况下
      if @states_turn[state_id] == -1 and not force
        # 过程结束
        return
      end
      # 现在的 HP 为 0 当作选项 [当作 HP 0 的状态]有效的场合
      if @hp == 0 and $data_states[state_id].zero_hp
        # 判断是否有另外的 [当作 HP 0 的状态]状态
        zero_hp = false
        for i in @states
          if i != state_id and $data_states[i].zero_hp
            zero_hp = true
          end
        end
        # 如果可以解除战斗不能、将 HP 更改为 1
        if zero_hp == false
          @hp = 1
        end
      end
      # 将状态 ID 从 @states 队列和 @states_turn hash 中删除 
      @states.delete(state_id)
      @states_turn.delete(state_id)
    end
    # 检查 HP 及 SP 的最大值
    @hp = [@hp, self.maxhp].min
  end
end