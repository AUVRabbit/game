class Game_BattleSequenceSingle
  attr_accessor :battle_src        # 動作發出者
  attr_accessor :battle_tar        # 動作接受者
  attr_accessor :param             # 附加参数
  attr_accessor :ex_param          # 補充參數
  attr_accessor :action_ary        # 動畫數組
  attr_accessor :message           # 動作消息
  
  def initialize
    @battle_src = nil
    @battle_tar = nil
    @param = nil
    @ex_param = nil
    @animation_ary = []
    @message = ""
  end
end