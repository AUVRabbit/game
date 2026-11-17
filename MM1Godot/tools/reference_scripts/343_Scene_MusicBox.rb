class Scene_MusicBox
  
  include MM_DataBase
  
  def main
    @sprite = Sprite.new
    @sprite.bitmap = RPG::Cache.picture(PICTURE_MUSICBOX)
    @music_list = DATA_MUSICLIST[$game_temp.music_list]
    @music_list_window = Window_MusicBox.new(@music_list)
    # 执行过渡
    Graphics.transition(20)
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面情报
      update
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    @sprite.bitmap.dispose
    @sprite.dispose
    @music_list_window.dispose
  end
  
  def update
    @music_list_window.update
    if Input.trigger?(Input::C)
      Audio.bgm_play("Audio/BGM/" + @music_list[@music_list_window.cursor_index][1], 100, 100)
      return
    end
    
    # 按下 B 键的情况下
    if Input.trigger?(Input::B)
      # 切換到地圖畫面
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
    end
  end
end