class Game_Engine
  
  include MM_System
  
  attr_reader :id                #引擎ID
  attr_reader :name              #引擎名称
  attr_reader :price             #引擎价格
  attr_reader :repair_price     #引擎修理价格 0：小破 1：大破
  attr_reader :weight            #重量
  attr_reader :load              #载重
  attr_reader :pdef              #防御力
  attr_reader :status
  attr_reader :status_guard      #屬性有效度
  attr_reader :transform_information #改造信息
  attr_reader :rent
  
  def initialize(item_id)
    @id = item_id
    engine = $data_engines[@id]
    @name = engine.name
    @price = engine.price
    @repair_price = engine.repair_price
    @weight = engine.weight
    @load = engine.load
    @pdef = engine.pdef
    #@status_guard = engine.status_guard
    @status = EQUIP_NORMAL
    @transform_information = engine.transform_information
    @rent = engine.rent
  end
  
  #改造为
  def transform(item_id)
    @id = item_id
    engine = $data_engines[@id]
    @name = engine.name
    @price = engine.price
    @repair_price = engine.repair_price
    @weight = engine.weight
    @load = engine.load
    @pdef = engine.pdef
    #@status_guard = engine.status_guard
    @status = EQUIP_NORMAL
    @transform_information = engine.transform_information
    @rent = engine.rent
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
  
  #载重改造
  def load_change(value)
    @load = value
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