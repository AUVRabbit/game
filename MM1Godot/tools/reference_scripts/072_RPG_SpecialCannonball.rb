# RPG模块追加

module RPG
  class SpecialCannonball
    def initialize
      @id = 0
      @name = ""
      @price = 0
      @atk = 0
      @state_id = 0
      @battle_message = ""
    end
    attr_accessor :id             #炮弹ID
    attr_accessor :name           #炮弹名称
    attr_accessor :price          #价格
    attr_accessor :atk            #攻击力
    attr_accessor :state_id       #附加状态ID
    attr_accessor :battle_message
  end
end