#==============================================================================
# ■ Game_Character (分割定义 1)
#------------------------------------------------------------------------------
# 　处理角色的类。本类作为 Game_Player 类与 Game_Event
# 类的超级类使用。
#==============================================================================

class Game_Character
  attr_accessor   :x                        # 地图 X 坐标 (理论坐标)
  attr_accessor   :y                        # 地图 Y 坐标 (理论坐标)
  attr_accessor   :direction
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
    # 坐标在地图以外的情况
    unless $game_map.valid?(new_x, new_y)
      # 不能通行
      return false
    end
    # 穿透是 ON 的情况下
    if @through
      # 可以通行
      return true
    end
    # 移动者的元件无法来到指定方向的情况下
    unless $game_map.passable?(x, y, d, self)
      # 通行不可
      return false
    end
    # 从指定方向不能进入到移动处的元件的情况下
    unless $game_map.passable?(new_x, new_y, 10 - d)
      # 不能通行
      return false
    end
    # 循环全部事件
    for event in $game_map.events.values
      # 事件坐标于移动目标坐标一致的情况下
      if event.x == new_x and event.y == new_y
        # 穿透为 ON
        unless event.through
          # 自己就是事件的情况下
          if self != $game_players.head_player
            # 不能通行
            return false
          end
          # 自己是主角、对方的图形是角色的情况下
          if event.character_name != ""
            # 不能通行
            return false
          end
        end
      end
    end
    # 主角的坐标与移动目标坐标一致的情况下
    if $game_players.head_player.x == new_x and $game_players.head_player == new_y
      # 穿透为 ON
      unless $game_players.head_player.through
        # 自己的图形是角色的情况下
        if @character_name != ""
          # 不能通行
          return false
        end
      end
    end
    # 可以通行
    return true
  end
end