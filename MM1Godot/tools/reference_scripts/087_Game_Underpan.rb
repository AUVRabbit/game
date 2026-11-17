class Game_Underpan
  
  include MM_System
  
  attr_reader :id                            #底盘ID
  attr_reader :name                          #底盘名称
  attr_reader :hole                          #底盘开洞 0：主炮 1：副炮 2：SE
  attr_reader :weight                        #重量
  attr_reader :special_cannonball_capacity   #特殊炮弹弹仓容量
  attr_reader :special_cannonball            #特殊炮打弹仓
  attr_reader :price                         #价格
  attr_reader :repair_price                 #修理价格 0：小破 1：大破
  attr_reader :pdef                          #防御力
  attr_reader :status                        #状态
  attr_reader :status_guard                  #屬性有效度
  attr_reader :rent
  
  def initialize(item_id)
    @id = item_id
    underpan = $data_underpans[@id]
    @name = underpan.name
    @hole = underpan.hole
    @weight = underpan.weight
    @special_cannonball_capacity = underpan.special_cannonball_capacity
    @special_cannonball = underpan.special_cannonball
    @price = underpan.price
    @repair_price = underpan.repair_price
    @pdef = underpan.pdef
    @status_guard = underpan.status_guard.clone
    @status = EQUIP_NORMAL
    @rent = underpan.rent
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    underpan = $data_underpans[@id]
    @name = underpan.name
    @hole = underpan.hole
    @weight = underpan.weight
    @special_cannonball_capacity = underpan.special_cannonball_capacity
    @special_cannonball = underpan.speciall_cannonball
    @price = underpan.price
    @repair_price = underpan.repair_price
    @pdef = underpan.pdef
    @status_guard = underpan.status_guard.clone
    @status = EQUIP_NORMAL
    @rent = underpan.rent
  end
  
  def normal?
    return @status == EQUIP_NORMAL ? true : false
  end
  
  def big_broken?
    return @status == EQUIP_BIG_BROKEN ? true : false
  end
  
  def little_broken?
    return @status == EQUIP_LITTLE_BROKEN ? true : false
  end
  
  def hole_opened?(position)
    return @hole[position] == true
  end
  
  #开洞
  def open_hole(position)
    @hole[position] = true
  end
  
  #實際彈藥數
  def special_cannonball_relity_capacity
    special_cannonball_capacity_relity = 0
    for key in @special_cannonball.keys
      special_cannonball_capacity_relity += @special_cannonball[key]
    end
    return special_cannonball_capacity_relity
  end
  
  #得到特殊炮彈
  def special_cannonball_get(cannon_id, number)
    @special_cannonball[cannon_id] = 0 if @special_cannonball[cannon_id] == nil
    @special_cannonball[cannon_id] += number
  end
  
  #消耗特殊炮弹
  def special_cannonball_use(cannon_id)
    @special_cannonball[cannon_id] -= 1
    if @special_cannonball[cannon_id] <= 0
      @special_cannonball.delete(cannon_id)
    end
  end
  
  #扔掉特殊炮弹
  def special_cannonball_throw(cannon_id, number)
    cannon = @special_cannonball[cannon_id]
    cannon = [cannon - number, 0].max
    @special_cannonball[cannon_id] = cannon
    if @special_cannonball[cannon_id] <= 0
      @special_cannonball.delete(cannon_id)
    end
  end
  
  #弹仓容量改造
  def special_cannonball_capacity_change(value)
    @special_cannonball_capacity = value
  end
  
  #防御力改造
  def pdef_change(value)
    @pdef = value
  end
  
  #重量改变
  def weight_change(value)
    @weight = value
  end
  
  #修理价格
  def repair_price
    if @status == 0
      return 0
    end
    return @repair_price[@status - 1]
  end
  
  #修理价格
  def repair_price
    if @status == EQUIP_NORMAL
      return 0
    end
    return @repair_price[@status - 1]
  end
  
  #修理
  def repair
    @status = EQUIP_NORMAL
  end
    
  #小破
  def little_broken
    @status = EQUIP_LITTLE_BROKEN
  end
  
  #大破
  def big_broken
    @status = EQUIP_BIG_BROKEN
  end
end