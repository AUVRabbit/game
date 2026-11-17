module RPG
  class Weapon
    attr_accessor :range_type             # 范围
    attr_accessor :can_equip_actors       # 可装备对象 id数组
    attr_accessor :animation3_id
    
    alias :old_initialize :initialize
    def initialize
      old_initialize
      @range_type = 0
      @can_equip_actors = []
      @animation3_id = 0
    end
  end
end