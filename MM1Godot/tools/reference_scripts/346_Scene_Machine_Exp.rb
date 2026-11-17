class Scene_Machine
  
  def main_machine_exp
    
    @cursor_index = 0
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MACHINE_NEXTEXP)
    @sprite_back.z = 8001
    
    @sprite_text = Sprite.new
    @sprite_text.bitmap = Bitmap.new(640, 480)
    @sprite_text.z = 8001
    
    @sprite_cursor = Sprite.new
    @sprite_cursor.bitmap = RPG::Cache.picture(PICTURE_CURSOR_MAIN)
    @sprite_cursor.z = 8002
    
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      x = 180
      y = i * 24 + 120
      @sprite_text.bitmap.draw_text(x, y, 120, 48, actor.name)
      @sprite_text.bitmap.draw_text(x + 100, y, 120, 48, "L:")
      @sprite_text.bitmap.draw_text(x + 140, y, 120, 48, actor.level.to_s)
      @sprite_text.bitmap.draw_text(x + 240, y, 120, 48, actor.next_exp_s)
    end
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update_exp
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_text.bitmap.dispose
    @sprite_text.dispose
    
    @sprite_cursor.bitmap.dispose
    @sprite_cursor.dispose
  end
  
  def update_exp
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::LEFT)
      @cursor_index -= 1 if @cursor_index > 0
    end
    
    if Input.trigger?(Input::RIGHT)
      @cursor_index += 1 if @cursor_index < 3
    end    
    
    if Input.trigger?(Input::UP)
      @cursor_index -= 2 if @cursor_index > 1
    end
    
    if Input.trigger?(Input::DOWN)
      @cursor_index += 2 if @cursor_index < 2
    end
    
    @sprite_cursor.x = 95 + @cursor_index % 2 * 240
    @sprite_cursor.y = 325 + @cursor_index / 2 * 64
  end
end