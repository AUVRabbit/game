#RPG模块追加

module RPG
  class Engine
    def initialize
      @id = 0
      @name = 0
      @price = 0
      @repair_price = [0, 0]
      @weight = 0
      @load = 0
      @pdef = 0
      @transform_information = []
      @rent = false
      @transform_price = []
    end
    attr_accessor :id                #引擎ID
    attr_accessor :name              #引擎名称
    attr_accessor :price             #引擎价格
    attr_accessor :repair_price     #引擎修理价格 0：小破 1：大破
    attr_accessor :weight            #重量
    attr_accessor :load              #载重
    attr_accessor :pdef              #防御力
    attr_accessor :transform_information #改造信息
    attr_accessor :rent
    attr_accessor :transform_price
  end
end