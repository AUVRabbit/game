#==============================================================================
# ■ Game_Player
#------------------------------------------------------------------------------
# 　处理主角的类。事件启动的判定、以及地图的滚动等功能。
# 本类的实例请参考 $game_player。
#==============================================================================

class Game_Player < Game_Character
  
  include MM_System
  
  attr_accessor   :last_x
  attr_accessor   :last_y
  attr_accessor   :tank_event_id
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  CENTER_X = (320 - 16) * 4   # 画面中央的 X 坐标 * 4
  CENTER_Y = (240 - 16) * 4   # 画面中央的 Y 坐标 * 4
  
  def set_member(member)
    @member = member
  end
  
  alias :old_initialize :initialize
  def initialize(member)
    old_initialize
    @member = member
    @last_real_x = 0
    @last_real_y = 0
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
    $game_map.display_x = [0, [x * 128 - CENTER_X, max_x].min].max
    $game_map.display_y = [0, [y * 128 - CENTER_Y, max_y].min].max
  end
  
  #--------------------------------------------------------------------------
  # ● 向指定的位置移动
  #     x : X 坐标
  #     y : Y 坐标
  #--------------------------------------------------------------------------
  def moveto(x, y)
    super
    # 自连接
    center(x, y)
    # 生成遇敌计数
    make_encounter_count
  end
  
  #--------------------------------------------------------------------------
  # ● 增加步数
  #--------------------------------------------------------------------------
  def increase_steps
    super
    # 不是强制移动路线的场合
    unless @move_route_forcing
      # 增加步数
      $game_party.increase_steps
      # 步数是偶数的情况下
      if $game_party.steps % 2 == 0
        # 检查连续伤害
        $game_party.check_map_slip_damage
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 获取遇敌计数
  #--------------------------------------------------------------------------
  def encounter_count
    return @encounter_count
  end
  
  #--------------------------------------------------------------------------
  # ● 生成遇敌计数
  #--------------------------------------------------------------------------
  def make_encounter_count
    # 两种颜色震动的图像
    if $game_map.map_id != 0
      n = $game_map.encounter_step
      @encounter_count = rand(n) + rand(n) + 1
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh(member = nil)
    @member = member if member != nil
    # 同伴人数为 0 的情况下
    if @member == nil
      # 清除角色的文件名及对像
      @character_name = ""
      @character_hue = 0
      # 分支结束
      return
    end
    # 获取角色
    member = @member
    # 设置角色的文件名及对像
    @character_name = member.character_name
    @character_hue = member.character_hue
    # 初始化不透明度和合成方式
    @opacity = 255
    @blend_type = 0
  end
  
  #--------------------------------------------------------------------------
  # ● 同位置的事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_here(triggers)
    result = false
    # 事件执行中的情况下
    if $game_system.map_interpreter.running?
      return result
    end
    # 全部事件的循环
    for event in $game_map.events.values
      # 事件坐标与目标一致的情况下
      if event.x == @x and event.y == @y and triggers.include?(event.trigger)
        # 跳跃中以外的情况下、启动判定是同位置的事件
        if not event.jumping? and event.over_trigger?
          event.start
          result = true
        end
      end
    end
    return result
  end
  
  def check_tank
    player = $game_players.head_player
    for event in $game_map.events.values
      if event.x == player.x\
        && event.y == player.y
        tanks_keys = $game_map.tanks_position.keys.sort!
        for i in 0...tanks_keys.size
          tanks_ary = $game_map.tanks_position[tanks_keys[i]]
          if $game_map.map_id == tanks_ary[2]\
            && event.x == tanks_ary[0]\
            && event.y == tanks_ary[1]
            tank_id = tanks_keys[i]
            break
          end
        end
        if tank_id == nil
          return nil
        end
        return true
      end
    end

  end
  
  #對話
  def check_event_trigger_there_dialog(triggers)
    result = false
    # 事件执行中的情况下
    if $game_system.map_interpreter.running?
      return result
    end
    # 计算正面坐标
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    # 全部事件的循环
    for event in $game_map.events.values
      # 事件坐标与目标一致的情况下
      if event.x == new_x and event.y == new_y and
         triggers.include?(event.trigger)
        # 跳跃中以外的情况下、启动判定是正面的事件
        if /dg\s.+/ =~ event.event.name
          if not event.jumping? and not event.over_trigger?
            event.start
            result = true
          end
        end
      end
    end
    # 找不到符合条件的事件的情况下
    if result == false
      # 正面的元件是计数器的情况下
      if $game_map.counter?(new_x, new_y)
        # 计算 1 元件里侧的坐标
        new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
        new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
        # 全事件的循环
        for event in $game_map.events.values
          # 事件坐标与目标一致的情况下
          if event.x == new_x and event.y == new_y and
             triggers.include?(event.trigger)
            # 跳跃中以外的情况下、启动判定是正面的事件
            if /dg\s.+/ =~ event.event.name
              if not event.jumping? and not event.over_trigger?
                event.start
                result = true
              end
            end
          end
        end
      end
    end
    return result
  end
  
  #--------------------------------------------------------------------------
  # ● 正面事件的启动判定（调查）
  #--------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    result = false
    # 事件执行中的情况下
    if $game_system.map_interpreter.running?
      return result
    end
    # 计算正面坐标
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    # 全部事件的循环
    for event in $game_map.events.values
      # 事件坐标与目标一致的情况下
      if event.x == new_x and event.y == new_y and
         triggers.include?(event.trigger)
        # 跳跃中以外的情况下、启动判定是正面的事件
        unless /dg\s.+/ =~ event.event.name
          if not event.jumping? and not event.over_trigger?
            event.start
            result = true
          end
        end
      end
    end
    # 找不到符合条件的事件的情况下
    if result == false
      # 正面的元件是计数器的情况下
      if $game_map.counter?(new_x, new_y)
        # 计算 1 元件里侧的坐标
        new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
        new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
        # 全事件的循环
        for event in $game_map.events.values
          # 事件坐标与目标一致的情况下
          if event.x == new_x and event.y == new_y and
             triggers.include?(event.trigger)
            # 跳跃中以外的情况下、启动判定是正面的事件
            if not event.jumping? and not event.over_trigger?
              unless /dg\s.+/ =~ event.event.name
                event.start
                result = true
              end
            end
          end
        end
      end
    end
    return result
  end
  
  #--------------------------------------------------------------------------
  # ● 接触事件启动判定
  #--------------------------------------------------------------------------
  def check_event_trigger_touch(x, y)
    result = false
    # 事件执行中的情况下
    if $game_system.map_interpreter.running?
      return result
    end
    # 全事件的循环
    for event in $game_map.events.values
      # 事件坐标与目标一致的情况下
      if event.x == x and event.y == y and [1,2].include?(event.trigger)
        # 跳跃中以外的情况下、启动判定是正面的事件
        unless /dg\s.+/ =~ event.event.name
          if not event.jumping? and not event.over_trigger?
            event.start
            result = true
          end
        end
      end
    end
    return result
  end

  #--------------------------------------------------------------------------
  # ● 画面更新
  #--------------------------------------------------------------------------
  def update
    if $scene.is_a?(Scene_Menu)
      return
    end
    if self == $game_players.head_player
      # 本地变量记录移动信息
      last_moving = moving?
      # 移动中、事件执行中、强制移动路线中、
      # 信息窗口一个也不显示的时候
      unless moving? or $game_system.map_interpreter.running? or
             @move_route_forcing or $game_temp.message_window_showing
        # 如果方向键被按下、主角就朝那个方向移动
        # 判斷戰車有無損壞情況
        case Input.dir4
        when 2
          if $game_party.tank_broken?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          elsif $game_party.tank_overload?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          else
            move_down
          end
        when 4
          if $game_party.tank_broken?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          elsif $game_party.tank_overload?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          else
            move_left
          end
        when 6
          if $game_party.tank_broken?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          elsif $game_party.tank_overload?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          else
            move_right
          end
        when 8
          if $game_party.tank_broken?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          elsif $game_party.tank_overload?
            $game_temp.temp_movie_message = true
            $game_temp.message_type = MESSAGE_MOVIE
            $game_temp.message_text = "不能动了，请检查强度。"
          else
            move_up
          end
        end
      end
      # 本地变量记忆坐标
    
      @last_x = self.x
      @last_y = self.y
      
      last_real_x = @real_x
      last_real_y = @real_y
      super
      # 角色向下移动、画面上的位置在中央下方的情况下
      if @real_y > last_real_y and @real_y - $game_map.display_y > CENTER_Y
        # 画面向下卷动
        $game_map.scroll_down(@real_y - last_real_y)
      end
      # 角色向左移动、画面上的位置在中央左方的情况下
      if @real_x < last_real_x and @real_x - $game_map.display_x < CENTER_X
        # 画面向左卷动
        $game_map.scroll_left(last_real_x - @real_x)
      end
      # 角色向右移动、画面上的位置在中央右方的情况下
      if @real_x > last_real_x and @real_x - $game_map.display_x > CENTER_X
        # 画面向右卷动
        $game_map.scroll_right(@real_x - last_real_x)
      end
      # 角色向上移动、画面上的位置在中央上方的情况下
      if @real_y < last_real_y and @real_y - $game_map.display_y < CENTER_Y
        # 画面向上卷动
        $game_map.scroll_up(last_real_y - @real_y)
      end
      # 不在移动中的情况下
      unless moving?
        # 上次主角移动中的情况
        if last_moving
          # 与同位置的事件接触就判定为事件启动
          result = check_event_trigger_here([1,2])
          # 没有可以启动的事件的情况下
          if result == false
            # 调试模式为 ON 并且按下 CTRL 键的情况下除外
            unless $DEBUG and Input.press?(Input::CTRL)
              # 遇敌计数下降
              if @encounter_count > 0
                @encounter_count -= 1
              end
            end
          end
        end
      end
    else
      super
    end
  end

  #--------------------------------------------------------------------------
  # ● 向下移动
  #     turn_enabled : 本场地位置更改许可标志
  #--------------------------------------------------------------------------
  def move_down(turn_enabled = true)
    next_actor = $game_players.players[$game_players.players.index(self) + 1]
    if next_actor == nil
      if $game_party.tow_tank != nil && $game_players.players.index(self) < 3
        next_actor = $game_players.players[3]
      end
    end
    # 面向下
    if turn_enabled
      turn_down
    end
    # 可以通行的场合
    if self == $game_players.head_player
      if passable?(@x, @y, 2)
        # 面向下
        turn_down
        # 更新坐标
        @y += 1
        # 增加步数
        increase_steps
      # 不能通行的情况下
      else
        # 接触事件的启动判定
        check_event_trigger_touch(@x, @y+1)
      end
    else
      # 面向下
      turn_down
      # 更新坐标
      @y += 1
    end
    if next_actor != nil
      if next_actor.x == self.x && next_actor.y - self.y == -2
        #对下一个角色的影响
        next_actor.move_down
      end
      
      x = next_actor.x - self.x
      y = next_actor.y - self.y
      
      case [x, y]
      when [1, 1]
        next_actor.move_right
      when [-1, 1]
        next_actor.move_left
      when [1, -1]
        next_actor.move_left
      when [-1, -1]
        next_actor.move_right
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 向左移动
  #     turn_enabled : 本场地位置更改许可标志
  #--------------------------------------------------------------------------
  def move_left(turn_enabled = true)
    next_actor = $game_players.players[$game_players.players.index(self) + 1]
    if next_actor == nil
      if $game_party.tow_tank != nil && $game_players.players.index(self) < 3
        next_actor = $game_players.players[3]
      end
    end
    # 面向左
    if turn_enabled
      turn_left
    end
    # 可以通行的情况下
    if self == $game_players.head_player
      if passable?(@x, @y, 4)
        # 面向左
        turn_left
        # 更新坐标
        @x -= 1
        # 增加步数
        increase_steps
      # 不能通行的情况下
      else
        # 接触事件的启动判定
        check_event_trigger_touch(@x-1, @y)
      end
    else
      # 面向左
      turn_left
        # 更新坐标
      @x -= 1
    end
    
    if next_actor != nil
      if next_actor.y == self.y && next_actor.x - self.x == 2
        next_actor.move_left
      end
      
      x = next_actor.x - self.x
      y = next_actor.y - self.y
      
      case [x, y]
      when [1, 1]
        next_actor.move_up
      when [-1, 1]
        next_actor.move_down
      when [1, -1]
        next_actor.move_down
      when [-1, -1]
        next_actor.move_up
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 向右移动
  #     turn_enabled : 本场地位置更改许可标志
  #--------------------------------------------------------------------------
  def move_right(turn_enabled = true)
    next_actor = $game_players.players[$game_players.players.index(self) + 1]
    if next_actor == nil
      if $game_party.tow_tank != nil && $game_players.players.index(self) < 3
        next_actor = $game_players.players[3]
      end
    end
    # 面向右
    if turn_enabled
      turn_right
    end
    # 可以通行的场合
    if self == $game_players.head_player
      if passable?(@x, @y, 6)
        # 面向右
        turn_right
        # 更新坐标
        @x += 1
        # 增加步数
        increase_steps
      # 不能通行的情况下
      else
        # 接触事件的启动判定
        check_event_trigger_touch(@x+1, @y)
      end
    else
      # 面向右
      turn_right
      # 更新坐标
      @x += 1      
    end
    
    if next_actor != nil
      if next_actor.y == self.y && next_actor.x - self.x == -2
        next_actor.move_right
      end
      
      x = next_actor.x - self.x
      y = next_actor.y - self.y
      
      case [x, y]
      when [1, 1]
        next_actor.move_down
      when [-1, 1]
        next_actor.move_up
      when [1, -1]
        next_actor.move_up
      when [-1, -1]
        next_actor.move_down
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 向上移动
  #     turn_enabled : 本场地位置更改许可标志
  #--------------------------------------------------------------------------
  def move_up(turn_enabled = true)
    next_actor = $game_players.players[$game_players.players.index(self) + 1]
    if next_actor == nil
      if $game_party.tow_tank != nil && $game_players.players.index(self) < 3
        next_actor = $game_players.players[3]
      end
    end
    # 面向上
    if turn_enabled
      turn_up
    end
    # 可以通行的情况下
    if self == $game_players.head_player
      if passable?(@x, @y, 8)
        # 面向上
        turn_up
        # 更新坐标
        @y -= 1
        # 歩数増加
        increase_steps
      # 不能通行的情况下
      else
        # 接触事件的启动判定
        check_event_trigger_touch(@x, @y-1)
      end
    else
      # 面向上
      turn_up
      # 更新坐标
      @y -= 1      
    end
    
    if next_actor != nil
      if next_actor.x == self.x && next_actor.y - self.y == 2
        next_actor.move_up
      end
      
      x = next_actor.x - self.x
      y = next_actor.y - self.y
      
      case [x, y]
      when [1, 1]
        next_actor.move_left
      when [-1, 1]
        next_actor.move_right
      when [1, -1]
        next_actor.move_right
      when [-1, -1]
        next_actor.move_left
      end
    end
  end
end