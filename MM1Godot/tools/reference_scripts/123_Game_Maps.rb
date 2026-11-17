class Game_Maps
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize
    @data = {}
    for id in 0..2000
      string = sprintf("Data/Map%03d.rxdata", id)
      if FileTest.exist?(string) 
        @data[id] = load_data(string)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取地图
  #     map_id : 地图 ID
  #--------------------------------------------------------------------------
  def [](map_id)
    if map_id > 2000 or @data[map_id] == nil
      return nil
    end
    if @data[map_id] != nil
      return @data[map_id]
    end
  end
  
  def save(map_id,obj)
    @data[map_id] = obj
  end  
end