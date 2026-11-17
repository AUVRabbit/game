#==============================================================================
# ■ Game_Players
#------------------------------------------------------------------------------
# 　处理地圖角色的类。事件启动的判定、以及地图的滚动等功能。
# 本类的实例请参考 $game_player。
#==============================================================================

class Game_Players# < Game_Character
  
  attr_reader :players
  
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  CENTER_X = (320 - 16) * 4   # 画面中央的 X 坐标 * 4
  CENTER_Y = (240 - 16) * 4   # 画面中央的 Y 坐标 * 4
    
  def initialize
    @players = []
    #$game_party.members.each do |member|
    #  @players.push(Game_Player.new(member))
    #end
    for i in 0..2
      @players.push(Game_Player.new($game_party.members[i]))
    end
    #if $game_party.tow_tank != nil
      @players.push(Game_Player.new($game_party.tow_tank))
    #end
    refresh
  end
  
  def head_player
    return @players[0]
  end
  
  def last_player
    return @players.last
  end
  
  def reset
    @players.clear
    
    $game_party.members.each do |member|
      @players.push(Game_Player.new(member))
    end
    
    #if $game_party.tow_tank != nil
    @players[3] = Game_Player.new($game_party.tow_tank)
    #end
    refresh
  end
  
  def reset_players
    $game_temp.players_pos = []
    @players.each do |player|
      $game_temp.players_pos.push([player.x, player.y, player.direction])
    end
    
    @players = []
    
    $game_party.members.each do |member|
      @players.push(Game_Player.new(member))
    end
    
    if $game_party.tow_tank != nil
      @players.push(Game_Player.new($game_party.tow_tank))
    end
    refresh
  end
  
  #--------------------------------------------------------------------------
  # ● 可以通行判定
  #     x : X 坐标
  #     y : Y 坐标
  #     d : 方向 (0,2,4,6,8)  ※ 0 = 全方向不能通行的情况判定 (跳跃用)
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    # 求得新的坐标
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    # 坐标在地图外的情况下
    unless $game_map.valid?(new_x, new_y)
      # 不能通行
      return false
    end
    # 调试模式为 ON 并且 按下 CTRL 键的情况下
    if $DEBUG and Input.press?(Input::CTRL)
      # 可以通行
      return true
    end
    super
  end
  
  #--------------------------------------------------------------------------
  # ● 以画面中央为基准设置地图的显示位置
  #--------------------------------------------------------------------------
  def center(x, y)
    max_x = ($game_map.width - 20) * 128
    max_y = ($game_map.height - 15) * 128
    $game_map.display_x = [0, [@players[0].x * 128 - CENTER_X, max_x].min].max
    $game_map.display_y = [0, [@players[0].y * 128 - CENTER_Y, max_y].min].max
  end
  
  #--------------------------------------------------------------------------
  # ● 向指定的位置移动
  #     x : X 坐标
  #     y : Y 坐标
  #--------------------------------------------------------------------------
  def moveto(x, y)
    @players.each do |player|
      player.moveto(x, y)
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 增加步数
  #--------------------------------------------------------------------------
  def increase_steps
    @players[0].increase_steps
  end
  
  #--------------------------------------------------------------------------
  # ● 获取遇敌计数
  #--------------------------------------------------------------------------
  def encounter_count
    return @players[0].encounter_count
  end
  
  #--------------------------------------------------------------------------
  # ● 生成遇敌计数
  #--------------------------------------------------------------------------
  def make_encounter_count
    @players[0].make_encounter_count
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    for i in 0...@players.size
      @players[i].refresh($game_party.members[i])
    end
      
    if $game_party.tow_tank != nil
      @players[3].set_member($game_party.tow_tank)
      @players[3].refresh($game_party.tow_tank)
    else
      @players[3].set_member(nil)
      @players[3].refresh(nil)
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 同位置的事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_here(triggers)
    @players[0].check_event_trigger_here(triggers)
  end

  #--------------------------------------------------------------------------
  # ● 檢查戰車
  #--------------------------------------------------------------------------
  def check_tank
    @players[0].check_tank
  end
  
  #--------------------------------------------------------------------------
  # ● 正面事件的启动判定（對話）
  #--------------------------------------------------------------------------
  def check_event_trigger_there_dialog(triggers)
    @players[0].check_event_trigger_there_dialog(triggers)
  end
  
  #--------------------------------------------------------------------------
  # ● 正面事件的启动判定（調查）
  #--------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    @players[0].check_event_trigger_there(triggers)
  end
  
  #--------------------------------------------------------------------------
  # ● 接触事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_touch(x, y)
    @players[0].check_event_trigger_touch(x, y)
  end
  
  #--------------------------------------------------------------------------
  # ● 画面更新
  #--------------------------------------------------------------------------
  def update
    @players.each do |player|
      player.update
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 移动中判定
  #--------------------------------------------------------------------------
  def moving?
    @players[0].moving?
  end

  #--------------------------------------------------------------------------
  # ● 矫正姿势
  #--------------------------------------------------------------------------
  def straighten
    @players[0].straighten
  end
end