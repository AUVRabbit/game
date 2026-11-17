#RPG模块追加

module RPG
  class Actor
    alias :old_initialize :initialize
    def initialize
      old_initialize
      @battle_level = 1
      @fix_level = 1
      @driver_level = 1
      @armor5_id = 0
      @armor5_fix = false
    end
    
    attr_accessor :battle_level  #戰鬥等級
    attr_accessor :fix_level     #修理等级
    attr_accessor :driver_level  #驾驶等级
    attr_accessor :armor5_id     #皮甲ID
    attr_accessor :armor5_fix    #皮甲固定
  end
end