#==============================================================================
# ■ Game_Tanks
#------------------------------------------------------------------------------
# 　处理戰車排列的类。本类的实例请参考
#  $game_tanks。
#==============================================================================

class Game_Tanks
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize
    @data = []
  end
  
  #--------------------------------------------------------------------------
  # ● 获取角色
  #     tank_id : 戰車 ID
  #--------------------------------------------------------------------------
  def [](tank_id)
    if tank_id > 999# or $data_tanks[tank_id] == nil
      return nil
    end
    if @data[tank_id] == nil# && $data_tanks[tank_id] != nil
      @data[tank_id] = Game_Tank.new(tank_id)
    end
    return @data[tank_id]
  end
  
  def []=(tank_id, value)
    @data[tank_id] = value
  end
  
  def get_tank_by_id(tank_id)
    return @data[tank_id]
  end
    
  def index(tank)
    return @data.index(tank)
  end
  
  def size
    return @data.size
  end
    
  def delete(value)
    @data.delete(value)
  end
end