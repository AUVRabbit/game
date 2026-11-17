#==============================================================================
# ■ Game_Event
#------------------------------------------------------------------------------
# 　处理事件的类。条件判断、事件页的切换、并行处理、执行事件功能
# 在 Game_Map 类的内部使用。
#==============================================================================

class Game_Event < Game_Character
  attr_accessor :direction
  #--------------------------------------------------------------------------
  # ● 接触事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_touch(x, y)
    # 事件执行中的情况下
    if $game_system.map_interpreter.running?
      return
    end
    # 目标为 [与事件接触] 以及和主角坐标一致的情况下
    if @trigger == 2 and x == $game_players.head_player.x and y == $game_players.head_playery
      # 除跳跃中以外的情况、启动判定就是正面的事件
      if not jumping? and not over_trigger?
        start
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 自动事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_auto
    # 目标为 [与事件接触] 以及和主角坐标一致的情况下
    if @trigger == 2 and @x == $game_players.head_player.x and @y == $game_players.head_player.y
      # 除跳跃中以外的情况、启动判定就是同位置的事件
      if not jumping? and over_trigger?
        start
      end
    end
    # 目标是 [自动执行] 的情况下
    if @trigger == 3
      start
    end
  end
end
