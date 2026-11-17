# RPG模块追加

module RPG
  class C_Unit
    def initialize
      @id = 0
      @name = ""
      @weight = 0
      @pdef = 0
      @price = 0
      @repair_price = [0, 0]
      @transform_time = []
      @rent = false
      @transform_price = []
    end
    attr_accessor :id             #C装置ID
    attr_accessor :name           #C装置名称
    attr_accessor :weight         #重量
    attr_accessor :pdef           #防御力
    attr_accessor :price          #价格
    attr_accessor :repair_price  #修理价格 0：小破 1：大破
    attr_accessor :transform_time #改造次數
    attr_accessor :rent
    attr_accessor :transform_price
  end
end