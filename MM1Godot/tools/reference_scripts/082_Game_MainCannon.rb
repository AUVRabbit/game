class Game_MainCannon
  
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
  attr_reader :price
  attr_reader :status              #状态 0：正常 1：小破 2：大破
  attr_reader :quantity_reality    #当前弹仓数量
  attr_reader :status_guard        #屬性有效度
  attr_reader :transform_time
  attr_reader :rent
  attr_reader :cannonball_price
  attr_reader :transform_price
  
  def initialize(item_id)
    @id = item_id
    main_cannon = $data_main_cannons[@id]
    @name = main_cannon.name
    @animation1_id = main_cannon.animation1_id
    @animation2_id = main_cannon.animation2_id
    @animation3_id = main_cannon.animation3_id
    @quantity = main_cannon.quantity
    @quantity_reality = @quantity
    @atk = main_cannon.atk
    @pdef = main_cannon.pdef
    @weight = main_cannon.weight
    @repair_price = main_cannon.repair_price
    @price = main_cannon.price
    #@status_guard = main_cannon.status_guard
    @transform_time = main_cannon.transform_time.clone
    @status = EQUIP_NORMAL
    @rent = main_cannon.rent
    @cannonball_price = 0
    @transform_price = main_cannon.transform_price
  end
  
  def range_type
    return RANGE_SINGLE
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    main_cannons = $data_main_cannon[item_id]
    @name = main_cannon.name
    @animation1_id = main_cannon.animation1_id
    @animation2_id = main_cannon.animation2_id
    @animation3_id = main_cannon.animation3_id
    @quantity = main_cannon.quantity
    @atk = main_cannon.atk
    @pdef = main_cannon.pdef
    @weight = main_cannon.weight
    @repair_price = main_cannon.repair_price
    @price = main_cannon.price
    #@status_guard = main_cannon.status_guard
    @status = EQUIP_NORMAL
    @rent = main_cannon.rent
  end
  
  def limited_quantity?
    return true
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
  
  #是否弹仓为空
  def quantity_empty?
    return @quantity == 0 ? true : false
  end
  
  #是否弹仓已满
  def quantity_full?
    return @quantity == @quantity_reality ? true : false
  end
  
  #弹药消耗
  def quantity_use
    @quantity_reality -= 1
  end
  
  #扔掉弹药
  def quantity_throw(number)
    @quantity_reality = [@quantity_reality - number, 0].max
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