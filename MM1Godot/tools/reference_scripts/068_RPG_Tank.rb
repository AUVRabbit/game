#RPG模块追加

module RPG
  class Tank
    def initialize
      @id = 0
      @name = ""
      @character_name = ""
      @character_hue = 0
      @battler_name = ""
      @battler_hue = 0
      @rent = false
      @main_cannon_id = 0
      @sub_cannon_id = 0
      @se_id = 0
      @engine_id = 0
      @c_unit_id = 0
      @underpan_id = 0
    end
    attr_accessor :id                 #ID
    attr_accessor :name               #名称
    attr_accessor :character_name     #战车图片
    attr_accessor :character_hue      #战车图片色相
    attr_accessor :battler_name       #战斗图片
    attr_accessor :battler_hue        #战斗图片色相
    attr_accessor :rent               #是否为出租车
    attr_accessor :main_cannon_id     #主炮ID
    attr_accessor :sub_cannon_id      #副炮ID
    attr_accessor :se_id              #SE ID
    attr_accessor :engine_id          #引擎ID
    attr_accessor :c_unit_id          #C装置ID
    attr_accessor :underpan_id        #底盘ID
  end
end