class Scene_EngineTransformShop
  
  include MM_DataBase
  include MM_System
  def main
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture( PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8000
    
    @tank_select_window = Window_SupplyShopTankSelect.new
    @tank_select_window.active = true
    @tank_select_window.visible = true
    @tank_select_window.z = 8002
    
    @spriteset_map = Spriteset_Map.new
    
    # 执行过渡
    Graphics.transition
    @message_window = Window_Message.new
    show_message("我是改造发动机。改造吗？")
    @result = show_yes_no_window
    case @result
    when RESULT_YES
      show_message("要改造哪辆战车的发动机？")
    when RESULT_NO
      $scene = Scene_Map.new
    end
    # 主循环
    loop do
      if $scene != self
        break
      end
      Graphics.update
      Input.update
      update
    end
    show_message("请再来", true)
    Graphics.freeze
    
    @spriteset_map.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @tank_select_window.dispose
    @message_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
  end
  
  def update
    @spriteset_map.update
    @tank_select_window.update
    if @tank_select_window.active
      update_tank_select
      return
    end
  end
  
  def update_tank_select
    if Input.trigger?(Input::C)
      @tank=$game_party.tanks[@tank_select_window.cursor_index]
      @Engine=@tank.engine
      #p @Engine.transform_information
      if @Engine.little_broken? || @Engine.big_broken?
        show_message("发动机坏了，不能改造，修好了再来吧！", true)
        $scene = Scene_Map.new
        return
      end
      if @Engine.transform_information == []
        show_message("什么。发动机的功率不能再提高了。", true)
        show_message("要改造哪辆战车的发动机？")
        return
      end
      if $game_party.gold < @Engine.transform_information[1]
        show_message("哎呀！你的钱不够啊。", true)
        return
      end
      show_message("那么"+@Engine.transform_information[1].to_s+"G，可以吗？")
      @result = show_yes_no_window
      case @result
      when RESULT_YES
        show_message("改装后无法还原。要改装"+@tank.name+"发动机吗？")
        @result = show_yes_no_window
        case @result
        when RESULT_YES
          $game_party.lose_gold(@Engine.transform_information[1])
          @Engine.transform(@Engine.transform_information[0])
          Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
          show_message("发动机改为"+@Engine.name+"改完后查一下数据。", true)
          show_message("别高兴过分了。别的发动机也改吗？")
          @result = show_yes_no_window
          case @result
          when RESULT_YES
            show_message("要改造哪辆战车的发动机？")
            return
          when RESULT_NO
            $scene = Scene_Map.new
            return
          end
        when RESULT_NO
          show_message("要改造哪辆战车的发动机？")
          return
          end
      when RESULT_NO
        show_message("攒够钱再来吧")
        return
      end
    end
    
    if Input.trigger?(Input::B)
      $scene = Scene_Map.new
      return
    end
    return
  end
    
  def show_message(msg, wait = false)
    @message_window.terminate_message
    $game_temp.message_text = msg
    loop do
      Graphics.update
      Input.update
      @message_window.update
      if @message_window.at_end
        break
      end
    end
    if wait == true
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end
    end
    return
  end
  
  def show_yes_no_window
    @yes_no_window = Window_YesOrNo.new
    loop do
      Graphics.update
      Input.update
      @yes_no_window.update
      if Input.trigger?(Input::B)
        @yes_no_window.visible = false
        return RESULT_NO
      end
      if Input.trigger?(Input::C)
        break
      end
    end
    @yes_no_window.visible = false
    return @yes_no_window.result
  end
  
end