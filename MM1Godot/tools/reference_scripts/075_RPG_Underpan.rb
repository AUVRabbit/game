#RPG模块追加

module RPG
  class Underpan
    def initialize
      @id = 0
      @name = ""
      @hole = [false, false, false]
      @weight = 0
      @special_cannonball_capacity = 0
      @special_cannonball = {}
      @status_guard = {}
      @price = 0
      @repair_price = [0, 0]
      @pdef = 0
      @rent = false
      @transform_price = []
    end
    attr_accessor :id                            #底盘ID
    attr_accessor :name                          #底盘名称
    attr_accessor :hole                          #底盘开洞 0：主炮 1：副炮 2：SE
    attr_accessor :weight                        #重量
    attr_accessor :special_cannonball_capacity   #特殊炮弹弹仓容量
    attr_accessor :special_cannonball            #特殊炮打弹仓
    attr_accessor :status_guard                  #特殊屬性有效度
    attr_accessor :price                         #价格
    attr_accessor :repair_price                 #修理价格 0：小破 1：大破
    attr_accessor :pdef                          #防御力
    attr_accessor :rent
    attr_accessor :transform_price
  end
end