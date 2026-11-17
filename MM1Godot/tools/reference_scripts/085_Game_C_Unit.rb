class Game_C_Unit
  
  include MM_System
  
  attr_reader :id             #C装置ID
  attr_reader :name           #C装置名称
  attr_reader :weight         #重量
  attr_reader :pdef           #防御力
  attr_reader :price          #价格
  attr_reader :repair_price  #修理价格 0：小破 1：大破
  attr_reader :status
  attr_reader :status_guard      #屬性有效度
  attr_reader :transform_time
  attr_reader :rent
  attr_reader :transform_price
  
  def initialize(item_id)
    @id = item_id
    c_unit = $data_c_units[@id]
    @name = c_unit.name
    @weight = c_unit.weight
    @pdef = c_unit.pdef
    @price = c_unit.price
    @repair_price = c_unit.repair_price
    #@status_guard = c_unit.status_guard
    @transform_time = c_unit.transform_time.clone
    @status = EQUIP_NORMAL
    @rent = c_unit.rent
    @transform_price = c_unit.transform_price
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    c_unit = $data_c_units[@id]
    @name = c_unit.name
    @weight = c_unit.weight
    @pdef = c_unit.pdef
    @price = c_unit.price
    @repair_price = c_unit.repair_price
    #@status_guard = c_unit.status_guard
    @status = EQUIP_NORMAL
    @rent = c_unit.rent
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