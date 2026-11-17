#==============================================================================
# ■ Scene_Name
#------------------------------------------------------------------------------
# 　处理名称输入画面的类。
#==============================================================================

class Scene_Name
  
  include MM_DataBase
  
  def initialize(actor)
    @actor = actor
  end
  
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    # 获取角色
    # 生成窗口
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_NAME_BACK)
    
    # 演奏标题 BGM
    Audio.bgm_play("Audio/BGM/" + MUSIC_NAME, 100, 100)
    # 停止演奏 ME、BGS
    Audio.me_stop
    Audio.bgs_stop
    
    @edit_window = Window_NameEdit.new(@actor, 4)
    @input_window = Window_NameInput.new
    for i in 0...40
      Graphics.update
    end
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新信息
      update
      # 如果画面切换就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    # 释放窗口
    @edit_window.dispose
    @input_window.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    # 刷新窗口
    @edit_window.update
    @input_window.update
    @sprite_back.update
    # 按下 B 键的情况下
    if Input.repeat?(Input::B)
      # 光标位置为 0 的情况下
      if @edit_window.index == 0
        return
      end
      # 演奏取消 SE
      # 删除文字
      @edit_window.back
      return
    end
    # 按下 C 键的情况下
    if Input.trigger?(Input::C)
      # 光标位置为 [确定] 的情况下
      if @input_window.character == nil
        case @input_window.index
        when 201
          # 光标位置为 0 的情况下
          if @edit_window.index == 0
            return
          end
          # 演奏取消 SE
          # 删除文字
          @edit_window.back
          return
        when 202
          @edit_window.add(" ")
          return
        when 203
          # 名称为空的情况下
          if @edit_window.name == ""
            # 还原为默认名称
            @edit_window.restore_default
            # 名称为空的情况下
            if @edit_window.name == ""
              # 演奏冻结 SE
              return
            end
            # 演奏确定 SE
            return
          end
          # 更改角色名称
          @actor.name = @edit_window.name
          # 演奏确定 SE
          # 切换到地图画面
          $scene = Scene_Map.new
          return
        end
      end
      # 光标位置为最大的情况下
      if @edit_window.index == 4
        # 演奏冻结 SE
        return
      end
      # 文字为空的情况下
      if @input_window.character == ""
        # 演奏冻结 SE
        return
      end
      # 演奏确定 SE
      # 添加文字
      @edit_window.add(@input_window.character)
      return
    end
  end
end