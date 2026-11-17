#RPG模块追加

module RPG
  class SE
    def initialize
      @id = 0                                  #副炮ID
      @name = ""                               #副炮名称
      @animation1_id = 0                       #发射时我方动画
      @animation2_id = 0                       #弹道动画
      @animation3_id = 0                       #发射后敌方动画
      @quantity = 0                            #弹药数量
      @atk = 0                                 #攻击力
      @pdef = 0                                #防御力
      @weight = 0                              #重量
      @repair_price = [0, 0]                  #修理价格 0：小破 1：大破
      @price = 0                               #价格
      @range_type = 0                          #攻击范围 0：一体 1：一组 2：全体
      @equip_position = [false, false, false]  #可装备位置 0：主炮 1：副炮 2：SE
      @transform_time = []                     #改造次數
      @rent = false
      @cannonball_price = 0
      @transform_price
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :animation3_id
    attr_accessor :quantity
    attr_accessor :atk
    attr_accessor :pdef
    attr_accessor :weight
    attr_accessor :repair_price
    attr_accessor :price
    attr_accessor :range_type
    attr_accessor :equip_position
    attr_accessor :transform_time
    attr_accessor :rent
    attr_accessor :cannonball_price
    attr_accessor :transform_price
  end
end