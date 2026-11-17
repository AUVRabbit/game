#RPG模块追加

module RPG
  class Item
    alias  :old_initialize :initialize
    def initialize
      old_initialize
      @type = 0
      @price = 0
      @can_drop_sell = true
      @vacab = ["", ""]
      @animation3_id = 0
      @hp_effect = 0
      @hit_effect = 0
      @eva_effect = 0
      @atk_effect = 0
      @menu_message = ["", ""]
      @battle_message = ["", ""]
    end
    
    attr_accessor :type            #类型 0：人类道具 1：战车道具
    attr_accessor :price           #价格
    attr_accessor :can_drop_sell   #可否被扔掉 & 卖掉 true：可以 false：不能
    attr_accessor :vacab           #用语 分场合 0：平时 1：战斗
    attr_accessor :animation3_id
    attr_accessor :hp_effect
    attr_accessor :hit_effect
    attr_accessor :eva_effect
    attr_accessor :atk_effect
    attr_accessor :menu_message
    attr_accessor :battle_message
  end
end