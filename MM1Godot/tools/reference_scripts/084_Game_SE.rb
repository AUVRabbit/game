class Game_SE
  
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
  attr_reader :quantity_reality
  attr_reader :status
  attr_reader :status_guard      #屬性有效度
  attr_reader :transform_time
  attr_reader :rent
  attr_reader :cannonball_price
  attr_reader :transform_price
  
  def initialize(item_id)
    @id = item_id
    se = $data_ses[@id]
    @name = se.name
    @animation1_id = se.animation1_id
    @animation2_id = se.animation2_id
    @animation3_id = se.animation3_id
    @quantity = se.quantity
    @quantity_reality = @quantity
    @atk = se.atk
    @pdef = se.pdef
    @weight = se.weight
    @repair_price = se.repair_price
    @range_type = se.range_type
    @price = se.price
    @equip_position = se.equip_position
    #@status_guard = se.status_guard
    @transform_time = se.transform_time.clone
    @status = EQUIP_NORMAL
    @cannonball_price = se.cannonball_price
    @rent = se.rent
    @transform_price = se.transform_price
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    se = $data_ses[@id]
    @name = se.name
    @animation1_id = se.animation1_id
    @animation2_id = se.animation2_id
    @animation3_id = se.animation3_id
    @quantity = se.quantity
    @atk = se.atk
    @pdef = se.pdef
    @weight = se.weight
    @repair_price = se.repair_price
    @range_type = se.range_type
    @price = se.price
    @equip_position = se.equip_position
    #@status_guard = se.status_guard
    @status = EQUIP_NORMAL
    @rent = se.rent
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
  
  def limited_quantity?
    return true
  end
  
  #是否弹仓为空
  def quantity_empty?
    return @quantity == 0 ? true : false
  end
  
  #弹药消耗
  def quantity_use
    @quantity_reality -= 1
  end
  
  #是否弹仓已满
  def quantity_full?
    return @quantity == @quantity_reality ? true : false
  end
  
  #扔掉弹药
  def quantity_throw(number)
    @quantity_reality = [@quantity - number, 0].max
  end
  
  #得到彈藥
  def quantity_add(number)
    @quantity_reality = [@quantity_reality + number, @quantity].min
  end
  
  #充滿
  def quantity_full
    @quantity_reality = @quantity
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
  
  #修理
  def repair
    @status = EQUIP_NORMAL
  end
  
  #充满
  def replenish
    @quantity_reality = @quantity
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