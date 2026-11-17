module RPG
  class State
    alias :old_initialize :initialize
    def initialize
      old_initialize
      @battle_message_effect = ""
      @battle_message_disappear = ""
      @battle_message_diaappear_short = ""
    end
    
    attr_accessor :battle_message_effect
    attr_accessor :battle_message_disappear
    attr_accessor :battle_message_diaappear_short
  end
end