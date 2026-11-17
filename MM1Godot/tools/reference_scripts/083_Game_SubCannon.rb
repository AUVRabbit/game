class Game_SubCannon
  
  include MM_System
  
  attr_reader :id
  attr_reader :name
  attr_reader :animation1_id
  attr_reader :animation2_id
  attr_reader :animation3_id
  attr_reader :quantity
  attr_reader :atk
  attr_reader :pdef
  attr_reader :weight
  attr_reader :repair_price
  attr_reader :price
  attr_reader :range_type
  attr_reader :equip_position
  attr_reader :status            #状态 0：正常 1：小破 2：大破
  attr_reader :quantity_reality  #当前弹仓数量，quantity为0的话本属性无效
  attr_reader :status_guard      #屬性有效度
  attr_reader :transform_time
  attr_reader :rent
  attr_reader :cannonball_price
  attr_reader :transform_price
  
  def initialize(item_id)
    @id = item_id
    sub_cannon = $data_sub_cannons[@id]
    @name = sub_cannon.name
    @animation1_id = sub_cannon.animation1_id
    @animation2_id = sub_cannon.animation2_id
    @animation3_id = sub_cannon.animation3_id
    @quantity = sub_cannon.quantity
    @quantity_reality = @quantity
    @atk = sub_cannon.atk
    @pdef = sub_cannon.pdef
    @weight = sub_cannon.weight
    @repair_price = sub_cannon.repair_price
    @range_type = sub_cannon.range_type
    @price = sub_cannon.price
    @equip_position = sub_cannon.equip_position
    @transform_time = sub_cannon.transform_time.clone
    #@status_guard = sub_cannon.status_guard
    @status = EQUIP_NORMAL
    @cannonball_price = sub_cannon.cannonball_price
    @rent = sub_cannon.rent
    @transform_price = sub_cannon.transform_price
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    sub_cannon = $data_sub_cannons[@id]
    @name = sub_cannon.name
    @animation1_id = sub_cannon.animation1_id
    @animation2_id = sub_cannon.animation2_id
    @animation3_id = sub_cannon.animation3_id
    @quantity = sub_cannon.quantity
    @atk = sub_cannon.atk
    @pdef = sub_cannon.pdef
    @weight = sub_cannon.weight
    @repair_price = sub_cannon.repair_price
    @range_type = sub_cannon.range_type
    @price = sub_cannon.price
    @equip_position = sub_cannon.equip_position
    #@status_guard = sub_cannon.status_guard
    @status = EQUIP_NORMAL
    @rent = sub_cannon.rent
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
  
  #是否无限弹药
  def limited_quantity?
    return @quantity == LIMITED ? false : true
  end
  
  #是否弹仓为空
  def quantity_empty?
    if limited_quantity?
      return @quantity_reality == LIMITED ? false : true
    end
    return false
  end
  
  #是否弹仓已满
  def quantity_full?
    return @quantity == @quantity_reality ? true : false
  end
  
  #弹药消耗
  def quantity_use
    if limited_quantity?
      @quantity_reality -= 1
    end
  end
  
  #扔掉弹药
  def quantity_throw(number)
    if limited_quantity?
      @quantity = [@quantity - number, 0].max
    end
  end
  
  #得到彈藥
  def quantity_add(number)
    if limitied_quantity?
      @quantity_reality = [@quantity_reality + number, @quantity].min
    end
  end
  
  #攻击力改造
  def atk_change(value)
    @atk = value
  end
  
  #守备力改造
  def pdef_change(value)
    @pdef = value
  end
  
  #重量改变
  def weight_change(value)
    @weight = value
  end
  
  #价格改变
  def price_change(value)
    @price = value
  end
  
  #修理价格
  def repair_price
    if @status == EQUIP_NORMAL
      return 0
    end
    return @repair_price[@status - 1]
  end
  
  #充满
  def replenish
    if limited_quantity?
      @quantity_reality = @quantity
    end
  end
  
  #充滿
  def quantity_full
    @quantity_reality = @quantity
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