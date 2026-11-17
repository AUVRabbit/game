#==============================================================================
# ■ Game_Temp
#------------------------------------------------------------------------------
# 　在没有存档的情况下，处理临时数据的类。这个类的实例请参考
# $game_temp 。
#==============================================================================

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor :message_type              # 信息类型
  attr_accessor :members_in_battle         # 战斗临时对象序列
  attr_accessor :clear_message_battle
  attr_accessor :rent_tanks_id
  attr_accessor :cannonball_list
  attr_accessor :music_list
  attr_accessor :players_pos
  attr_accessor :temp_movie_message
  attr_accessor :force_message
  attr_accessor :wanted_list
  attr_accessor :shop_type
  attr_accessor :shop_goods
  attr_accessor :machine_type
  attr_accessor :machine_lift_floor_count
  attr_accessor :machine_lift_floor_result
  attr_accessor :machine_switch_result
  attr_accessor :machine_password
  attr_accessor :machine_password_result
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  alias :old_initialize :initialize
  def initialize
    old_initialize
    @message_type = 0
    @members_in_battle = []
    @clear_message_battle = false
    @rent_tanks_id = 0
    @cannonball_list = 0
    @music_list = 0
    @players_pos = []
    @temp_movie_message = false
    @force_message = false
    @wanted_list = []
    @shop_type = 0
    @shop_goods = []
    @machine_type = 0
    @machine_lift_floor_count = 0
    @machine_lift_floor_result = 0
    @machine_switch_result = false
    @machine_password = ""
    @machine_password_result = false
  end
end