class Game_Tank < Game_Battler
  
  include MM_System
  
  attr_reader :name                  #名稱
  attr_reader :character_name        #角色 文件名
  attr_reader :character_hue         #角色 色相
  attr_reader :driver                #當前駕駛者
  attr_reader :main_cannon           #當前主炮对象
  attr_reader :sub_cannon            #當前副炮对象
  attr_reader :se                    #當前SE 对象
  attr_reader :c_unit                #當前C裝置对象
  attr_reader :engine                #當前引擎对象
  attr_reader :underpan              #当前底盘对象
  attr_reader :items                 #當前戰車物品 Array
  attr_reader :equipments            #当前战车装备 Array
  attr_reader :rent                  #當前戰車是否出租
  def initialize(tank_id)
    super()
    setup(tank_id)
  end
  
  def setup(tank_id)
    tank = $data_tanks[tank_id]
    @character_name = tank.character_name
    @character_hue = tank.character_hue
    @battler_name = tank.battler_name
    @battler_hue = tank.battler_hue
    @name = tank.name
    @tank_id = tank.id
    @driver = nil
    @main_cannon =\
    tank.main_cannon_id == 0 ? nil : Game_MainCannon.new(tank.main_cannon_id)
    @sub_cannon =\
    tank.sub_cannon_id == 0 ? nil : Game_SubCannon.new(tank.sub_cannon_id)
    @se =\
    tank.se_id == 0 ? nil : Game_SE.new(tank.se_id)
    @c_unit =\
    tank.c_unit_id == 0 ? nil : Game_C_Unit.new(tank.c_unit_id)
    @engine =\
    tank.engine_id == 0 ? nil : Game_Engine.new(tank.engine_id)
    @underpan =\
    tank.underpan_id == 0 ? nil : Game_Underpan.new(tank.underpan_id)
    
    @items = []
    @equipments = []
    for equipment in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if equipment != nil
        @equipments.push(equipment)
      end
    end
    
    @rent = tank.rent
    @atk = 0
    @pdef = 0
  end
  
  def reset_tank_data(data_ary, id)
    #id, 名称, 行走图名称, 行走图色相, 战斗图名称， 战斗图色相， 是否出租, 主炮id, 副炮id, seid, 引擎id, c装置id, 底盘id
    #tank = $data_tanks[tank_id]
    @character_name = data_ary[2]
    @character_hue = data_ary[3]
    @battler_name = data_ary[4]
    @battler_hue = data_ary[5]
    @name = data_ary[1]
    @tank_id = id #data_ary[0] + 8
    #while($game_tanks.get_tank_by_id(@tank_id) != nil)
    #  @tank_id += 1
    #end
    #p data_ary[0], $game_tanks.size, @tank_id
    @driver = nil
    @main_cannon =\
    data_ary[7]== 0 ? nil : Game_MainCannon.new(data_ary[7])
    @sub_cannon =\
    data_ary[8] == 0 ? nil : Game_SubCannon.new(data_ary[8])
    @se =\
    data_ary[9] == 0 ? nil : Game_SE.new(data_ary[9])
    @c_unit =\
    data_ary[10] == 0 ? nil : Game_C_Unit.new(data_ary[10])
    @engine =\
    data_ary[11] == 0 ? nil : Game_Engine.new(data_ary[11])
    @underpan =\
    data_ary[12] == 0 ? nil : Game_Underpan.new(data_ary[12])
    
    @items = []
    @equipments = []
    for equipment in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if equipment != nil
        @equipments.push(equipment)
      end
    end
    
    @rent = data_ary[6]
    @atk = 0
    @pdef = 0
  end
  
  def dead?
    return (self.underpan.big_broken? and not @immortal)
  end
  
  def id
    return @tank_id
  end
  
  def index
    return $game_party.tanks.index(self)
  end
  
  def equipments_package_full?
    return @equipments.size >= 8 ? true : false
  end
  
  def gain_equipments(item)
    @equipments.push(item)
  end
  
  def lose_equipments(index)
    item = @equipments[index]
    if @main_cannon.equal?(item)
      @main_cannon = nil
    elsif @sub_cannon.equal?(item)
      @sub_cannon = nil
    elsif @se.equal?(item)
      @se = nil
    elsif @engine.equal?(item)
      @engine = nil
    elsif @c_unit.equal?(item)
      @c_unit = nil
    elsif @underpan.equal?(item)
      @underpan = nil
    end
    @equipments.delete_at(index)
  end
  
  def items_package_full?
    return @items.size >= 8 ? true : false
  end
  
  def overload?
    return load_max < load_reality ? true : false
  end
  
  def gain_item(item)
    @items.push(item)
  end
  
  def lose_item(index)
    @items.delete_at(index)
  end
    
  def load_max
    return @engine.load
  end
  
  def load_reality
    load = 0
    #for armor in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
    #  load += armor.weight if armor != nil
    #end
    for item in @equipments
      load += item.weight
    end
    load += @hp / 100
    return load
  end
  
  def set_driver(driver)
    @driver = driver
  end
  
  def get_speciall_cannonball(sepcial_cannonball, num)
    if @underpan.special_cannonball[sepcial_cannonball] == nil
      @underpan.special_cannonball[sepcial_cannonball] = num
    else
      @underpan.special_cannonball[sepcial_cannonball] += num
    end
  end
  
  def armour_full_money
    if (self.maxhp - self.hp) % 100 == 0
      price = (self.maxhp - self.hp) / 100
    else
      price = (self.maxhp - self.hp) / 100 + 1
    end
    return price
  end
  
  def cannonball_full_money
    price = 0
    if @main_cannon != nil
      price += (@main_cannon.quantity - @main_cannon.quantity_reality) * 5
    end
    
    if @sub_cannon != nil
      price += (@sub_cannon.quantity - @sub_cannon.quantity_reality) * @sub_cannon.price / 10
    end
    
    if @se != nil
      price += (@se.quantity - @se.quantity_reality) * @se.price / 10
    end
    return price
  end
  
  def full_armour
    self.hp = self.maxhp
  end
  
  def full_cannonball
    if @main_cannon != nil
      @main_cannon.quantity_full
    end
    
    if @sub_cannon != nil
      @sub_cannon.quantity_full
    end
    
    if @se != nil
      @se.quantity_full
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 取得属性修正值
  #     element_id : 属性 ID
  #--------------------------------------------------------------------------
  def element_rate(element_id)
    # 获取对应属性有效度的数值
    table = [0,200,150,100,50,0,-100]
    result = table[@underpan.status_guard[element_id]]
    # 防具能防御本属性的情况下效果减半
    for armor in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if armor != nil and armor.status_guard.include?(element_id)
        result /= 2
      end
    end
    # 状态能防御本属性的情况下效果减半
    for i in @states
      if armor.status_guard.include?(element_id)
        result /= 2
      end
    end
    # 过程结束
    return result
  end
  
  #--------------------------------------------------------------------------
  # ● 判定防御属性
  #     state_id : 属性 ID
  #--------------------------------------------------------------------------
  def state_guard?(state_id)
    for armor in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if armor != nil
        if armor.status_guard.include?(state_id)
          return true
        end
      end
    end
    return false
  end

  #--------------------------------------------------------------------------
  # ● 获取 MaxHP
  #--------------------------------------------------------------------------
  def maxhp
    weight = 0
    for armor in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if armor != nil
        weight += armor.weight
      end
    end
    maxhp = (@engine.load - weight) * 100
    return [maxhp, 0].max
  end
  
  #--------------------------------------------------------------------------
  # ● 获取物理防御
  #--------------------------------------------------------------------------
  def pdef
    pdef = 0
    for armor in [@main_cannon, @sub_cannon, @se, @c_unit, @engine, @underpan]
      if armor != nil
        pdef += armor.pdef
      end
    end
    return pdef
  end
  
  #--------------------------------------------------------------------------
  # ● 变更装备
  #     equip_type : 装备类型
  #     id    : 武器 or 防具 ID  (0 为解除装备)
  #--------------------------------------------------------------------------
  def equip(equip_type, equipment)
    case equip_type
    when 0  # 主炮
      if @main_cannon.equal?(equipment)
        @main_cannon = nil
        return EQUIPRESULT_DROP
      else
        @main_cannon = equipment
        return EQUIPRESULT_PICK
      end
    when 1  # 副炮
      if @sub_cannon.equal?(equipment)
        @sub_cannon = nil
        return EQUIPRESULT_DROP
      else
        @sub_cannon = equipment
        return EQUIPRESULT_PICK
      end
    when 2  # SE
      if @se.equal?(equipment)
        @se = nil
        return EQUIPRESULT_DROP
      else
        @se = equipment
        return EQUIPRESULT_PICK
      end
    when 3  # C裝置
      if @c_unit.equal?(equipment)
        @c_unit = nil
        return EQUIPRESULT_DROP
      else
        @c_unit = equipment
        return EQUIPRESULT_PICK
      end
    when 4  # 引擎
      if @engine.equal?(equipment)
        @engine = nil
        return EQUIPRESULT_DROP
      else
        @engine = equipment
        return EQUIPRESULT_PICK
      end
    when 5  # 底盤
      if @underpan.equal?(equipment)
        @underpan = nil
        return EQUIPRESULT_DROP
      else
        @underpan = equipment
        return EQUIPRESULT_PICK
      end
    end    
  end
  
  #--------------------------------------------------------------------------
  # ● 可以装备判定
  #     item : 物品
  #--------------------------------------------------------------------------
  def equippable?(item, position)
    case item
    when RPG::MainCannon, RPG::SubCannon, RPG::SE
      #p @underpan.hole[position]
      return @underpan.hole[position]
    else
      return true
    end
    return false
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
  # ● 确定动作速度
  #--------------------------------------------------------------------------
  def make_action_speed
    @current_action.speed = @driver.agi + rand(10 + agi / 4)
  end
  
  #--------------------------------------------------------------------------
  # ● 战斗不能判定
  #--------------------------------------------------------------------------
  def broken?
    return (@hp == 0 && @underpan.big_broken?)
  end
  
  #--------------------------------------------------------------------------
  # ● 存在判定
  #--------------------------------------------------------------------------
  def exist?
    return (@underpan.status != EQUIP_BIG_BROKEN)
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
  
  #--------------------------------------------------------------------------
  # ● 获取力量
  #--------------------------------------------------------------------------
  def str
    return 0
  end
  #--------------------------------------------------------------------------
  # ● 获取灵巧
  #--------------------------------------------------------------------------
  def dex
    return 0
  end
  #--------------------------------------------------------------------------
  # ● 获取速度
  #--------------------------------------------------------------------------
  def agi
    return 0
  end
  #--------------------------------------------------------------------------
  # ● 获取魔力
  #--------------------------------------------------------------------------
  def int
   return 0
  end
 
  #--------------------------------------------------------------------------
  # ● 获取攻击力
  #--------------------------------------------------------------------------
  def atk
    return 0
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击属性
  #--------------------------------------------------------------------------
  def element_set
    return []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击状态变化 (+)
  #--------------------------------------------------------------------------
  def plus_state_set
    #weapon = $data_weapons[@weapon_id]
    return []#weapon != nil ? weapon.plus_state_set : []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取普通攻击状态变化 (-)
  #--------------------------------------------------------------------------
  def minus_state_set
    return []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取基本回避修正
  #--------------------------------------------------------------------------
  def base_eva
    return 0
  end
end