module RPG
  class Skill
    alias :old_initialize :initialize
    def initialize
      initialize
      @battle_message = ["", ""]
      @animation3_id = 0
    end
    
    attr_accessor :battle_message
    attr_accessor :animation3_id
  end
end