module RPG
  class Armor
    attr_accessor :can_equip_actors #可装备对象 id数组
    
    alias :old_initialize :initialize
    def initialize
      old_initialize
      @can_equip_actors = []
    end
  end
end