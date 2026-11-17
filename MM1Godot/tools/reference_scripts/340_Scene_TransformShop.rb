class Scene_TransformShop
  
  include MM_DataBase
  include MM_System
  
  def main
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_TRANSFORMSHOP_MAINBACK)
    @sprite_back.z = 8000
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8000
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @spriteset_map = Spriteset_Map.new
    
    @main_command_window = Window_TransfromMainCommand.new
    @main_command_window.visible =false
    @main_command_window.active = false
    @main_command_window.z = 8002
    
    @hole_command_window = Window_TransfromHoleSelect.new
    @hole_command_window.visible = false
    @hole_command_window.active = false
    @hole_command_window.z = 8002
    
    @tank_select_window = Window_SupplyShopTankSelect.new
    @tank_select_window.visible = false
    @tank_select_window.active = false
    @tank_select_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    @message_window = Window_Message.new
    show_message("我会改装车身底盘。", true)
    @main_command_window.visible =true
    show_message("你的战车也要改装吗？")
    @result = show_yes_no_window
    case @result
    when RESULT_YES
      @tank_select_window.active = true
      @tank_select_window.visible = true
      show_message("要改装哪辆战车\n赶紧决定吧！")
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
    show_message("要了解战车性能的话,请到我这儿来。", true)
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @sprite_gold.bitmap.dispose
    @sprite_gold.dispose
    
    @spriteset_map.dispose
    
    @main_command_window.dispose
    @tank_select_window.dispose
    @hole_command_window.dispose
    @message_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
  end
  
  def update
    @main_command_window.update
    @tank_select_window.update
    @hole_command_window.update
    
    @spriteset_map.update
    
    if @main_command_window.active
      update_main_command
      return
    end
    if @tank_select_window.active
      update_tank_select
      return
    end
    if @hole_command_window.active
      update_hole_select
      return
    end
  end
  
  def update_main_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_contiune
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @main_command_window.result
      when TRANSFROMSHOPMAINCOMMAND_MAGAZINE                  #弹仓扩大改造
        if( @tank.underpan.special_cannonball_capacity>=128)
          show_message("战车已经改装过了。\n再改装就坏了。\n别弄了！", true)
          return
        end
        @price=@tank.underpan.special_cannonball_capacity*8    #计算改造费
        if $game_party.gold < @price
          show_message("哎呀！你的钱不够啊")
          return
        end
        show_message(@tank.name+"扩大弹仓需要"+@price.to_s+"G.可以吗？")
        @result= show_yes_no_window
        case @result
        when RESULT_YES
          show_message("再问一次，这辆战车可无法还原了。\n行吗？")
          @result= show_yes_no_window
          case @result
          when RESULT_YES
            @load=@tank.load_max-@tank.load_reality   #判断改造后是否超重
            if(@load>=0.1)
              show_message("好吧，包在我身上。", true)
              @tank.underpan.weight_change(@tank.underpan.weight+0.1)
              @tank.underpan.special_cannonball_capacity_change(
              @tank.underpan.special_cannonball_capacity*2)
              Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
              $game_party.lose_gold(@price.to_i)
              refresh_gold_draw
              show_message(@tank.name+"弹仓扩大到"+
              @tank.underpan.special_cannonball_capacity.to_s+
              "底盘的重量增加了0.1t", true)
              show_message("改完了！\n好好爱惜吧！")
              refresh_gold_draw
              show_contiune
              return
            else
              show_message("嗯？"+@tank.name+"\n超过了"+(@load-0.1)+
              "t.加的太多了", true)
              showmessage("如想改装。\n车型要加大")
              show_contiune
              return
            end
          when RESULT_NO
            show_contiune
            return
          end
          when RESULT_NO
            show_contiune
            return
          end
          return
        when TRANSFROMSHOPMAINCOMMAND_DEFENSE             #防御改造
          if( @tank.underpan.pdef>=400)
            show_message("战车已经改装过了。\n再改装就坏了。\n别弄了！", true)
            return
          end
          @price=200                                      #改一次200G 
          if $game_party.gold < @price
            show_message("哎呀！你的钱不够啊")
            return
          end
          show_message(@tank.name+"的守备力\n增加10的话\n需要"+@price.to_s+".做吗？")
          @result= show_yes_no_window
          case @result
          when RESULT_YES
            show_message("再问一次，这辆战车可无法还原了。\n行吗？")
            @result= show_yes_no_window
            case @result
            when RESULT_YES
              @load=@tank.load_max-@tank.load_reality   #判断改造后是否超重
              if(@load>=0.1)                              #改一次重量增加0.1t                     
                show_message("好吧，包在我身上。", true)
                @tank.underpan.weight_change(@tank.underpan.weight+0.1)
                @tank.underpan.pdef_change(@tank.underpan.pdef+10)
                $game_party.lose_gold(@price.to_i)
                refresh_gold_draw
                Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
                show_message(@tank.name+"防御增加到"+
                @tank.underpan.pdef.to_s+"！底盘的重量增加了0.1t", true)
                show_message("改完了！\n好好爱惜吧！", true)
                refresh_gold_draw
                show_contiune
                return
              else
                show_message("嗯？"+@tank.name+"\n超过了"+(@load-0.1)+
                "t.加的太多了", true)
                showmessage("如想改装。\n车型要加大")
                show_contiune
                return
              end
            when RESULT_NO
              show_contiune
              return
            end
          when RESULT_NO
            show_contiune
          return
        end
        return
      when TRANSFROMSHOPMAINCOMMAND_OPENHOLE         #打洞
        show_message("哪个部位要打洞？")
        @main_command_window.visible =false
        @main_command_window.active = false
        @hole_command_window.visible = true
        @hole_command_window.active = true
        return
      when TRANSFROMSHOPMAINCOMMAND_EXIT
        show_message("请再来！")
        $scene = Scene_Map.new
        return
      end
    end
  end
  
  def update_hole_select                                    #打洞选择
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_message("要怎样改装车呢？")
      @main_command_window.visible =true
      @main_command_window.active = true
      @hole_command_window.visible =false
      @hole_command_window.active = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)   
      case @hole_command_window.result
      when TRANSFROMSHOPMAINHOLESELECT_MAIN_CANNON
        if @tank.underpan.hole[TRANSFROMSHOPMAINHOLESELECT_MAIN_CANNON]==true
          show_message("战车已改装过了。\n再改装就坏了。\n别弄了！", true)
          show_message("哪个部位要打洞。")
          return
        end
        show_message("要在主炮上打个洞吗?")
        @result= show_yes_no_window
        case @result
        when RESULT_YES
          @price=5000                                   #打洞5000G
          if $game_party.gold < @price
            show_message("哎呀！你的钱不够啊", true)
            return
          end 
          show_message("好啊！\n要"+@price.to_s+"G.可以吗？")
          @result= show_yes_no_window
          case @result
          when RESULT_YES
            show_message("再问一次，这辆战车可无法还原了。\n行吗？")
            @result= show_yes_no_window
            case @result
            when RESULT_YES
              @load=@tank.load_max-@tank.load_reality   #判断改造后是否超重
              if(@load>=0.5)                              #改一次重量增加0.5t                     
                show_message("好吧，包在我身上。", true)
                @tank.underpan.weight_change(@tank.underpan.weight+0.5)
                @tank.underpan.open_hole(TRANSFROMSHOPMAINHOLESELECT_MAIN_CANNON)
                $game_party.lose_gold(@price.to_i)
                refresh_gold_draw
                Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
                show_message(@tank.name+"可以装备主炮了底盘的重量增加了0.5t", true)
                show_message("改完了！\n好好爱惜吧！", true)
                refresh_gold_draw
                show_contiune
                return
              else
                show_message("嗯？"+@tank.name+"\n超过了"+(@load-0.5)+
                "t.加的太多了", true)
                showmessage("如想改装。\n车型要加大")
                show_contiune
                return
              end
         
            when RESULT_NO
              show_contiune
              return
            end
          when RESULT_NO
            show_contiune
            return
          end
        when RESULT_NO
          show_contiune
          return
        end
      when TRANSFROMSHOPMAINHOLESELECT_SUB_CANNON
        if @tank.underpan.hole[TRANSFROMSHOPMAINHOLESELECT_SUB_CANNON]==true
          show_message("战车已改装过了。\n再改装就坏了。\n别弄了！", true)
          show_message("哪个部位要打洞。")
          return
        end
        show_message("要在副炮上打个洞吗?")
        @result= show_yes_no_window
          case @result
          when RESULT_YES
            @price=5000                                   #打洞5000G
            if $game_party.gold < @price
              show_message("哎呀！你的钱不够啊")
              return
            end 
            show_message("好啊！\n要"+@price.to_s+"G.可以吗？")
            @result= show_yes_no_window
            case @result
            when RESULT_YES
              show_message("再问一次，这辆战车可无法还原了。\n行吗？")
              @result= show_yes_no_window
              case @result
              when RESULT_YES
                @load=@tank.load_max-@tank.load_reality   #判断改造后是否超重
                if(@load>=0.5)                              #改一次重量增加0.5t                     
                  show_message("好吧，包在我身上。", true)
                  @tank.underpan.weight_change(@tank.underpan.weight+0.5)
                  @tank.underpan.open_hole(TRANSFROMSHOPMAINHOLESELECT_SUB_CANNON)
                  $game_party.lose_gold(@price.to_i)
                  refresh_gold_draw
                  Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
                  show_message(@tank.name+"可以装备副炮了底盘的重量增加了0.5t", true)
                  show_message("改完了！\n好好爱惜吧！", true)
                  refresh_gold_draw
                  show_contiune
                  return
                else
                  show_message("嗯？"+@tank.name+"\n超过了"+(@load-0.5)+
                  "t.加的太多了", true)
                  showmessage("如想改装。\n车型要加大", true)
                  show_contiune
                  return
                end
         
              when RESULT_NO
                show_contiune
                return
              end
            when RESULT_NO
              show_contiune
              return
            end
          when RESULT_NO
            show_contiune
            return
          end
        when TRANSFROMSHOPMAINHOLESELECT_SE
          if @tank.underpan.hole[TRANSFROMSHOPMAINHOLESELECT_SE]==true
            show_message("战车已改装过了。\n再改装就坏了。\n别弄了！", true)
            show_message("哪个部位要打洞。")
            return
          end
          show_message("要在SE上打个洞吗?")
          @result= show_yes_no_window
          case @result
          when RESULT_YES
            @price=5000                                   #打洞5000G
            if $game_party.gold < @price
              show_message("哎呀！你的钱不够啊", true)
              return
            end 
            show_message("好啊！\n要"+@price.to_s+"G.可以吗？")
            @result= show_yes_no_window
            case @result
            when RESULT_YES
              show_message("再问一次，这辆战车可无法还原了。\n行吗？")
              @result= show_yes_no_window
              case @result
              when RESULT_YES
                @load=@tank.load_max-@tank.load_reality   #判断改造后是否超重
                if(@load>=0.5)                              #改一次重量增加0.5t                     
                  show_message("好吧，包在我身上。", true)
                  @tank.underpan.weight_change(@tank.underpan.weight+0.5)
                  @tank.underpan.open_hole(TRANSFROMSHOPMAINHOLESELECT_SE)
                  $game_party.lose_gold(@price.to_i)
                  refresh_gold_draw
                  Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
                  show_message(@tank.name+"可以装备SE了底盘的重量增加了0.5t", true)
                  show_message("改完了！\n好好爱惜吧！", true)
                  refresh_gold_draw
                  show_contiune
                  return
                else
                  show_message("嗯？"+@tank.name+"\n超过了"+(@load-0.5)+
                  "t.加的太多了", true)
                  showmessage("如想改装。\n车型要加大")
                  show_contiune
                  return
                end
        
              when RESULT_NO
                show_contiune
                return
              end
            when RESULT_NO
              show_contiune
              return
            end
          when RESULT_NO
            show_contiune
            return
          end
        when TRANSFROMSHOPMAINHOLESELECT_EXIT 
          show_message("要怎样改装车呢")
        return
      end
    end
  end
    
  def update_tank_select
    if Input.trigger?(Input::C)
      @tank=$game_party.tanks[@tank_select_window.cursor_index]
      show_message("是"+@tank.name+"吗？", true)
      show_message("要怎样改装车呢？")
      @main_command_window.active = true
      @main_command_window.visible = true
      @tank_select_window.active=false
    end
    
    if Input.trigger?(Input::B)
      $scene = Scene_Map.new
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
  
  def refresh_gold_draw
    @sprite_gold.bitmap.dispose
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
  end
  
  def show_contiune
    show_message("其他战车要改装吗？")
    @result= show_yes_no_window
    case @result
    when RESULT_YES
      @tank_select_window.active = true
      @tank_select_window.visible = true
      @main_command_window.active=false
      @main_command_window.visible=true
      @hole_command_window.visible =false
      @hole_command_window.active = false
      show_message("要改装哪辆战车\n赶紧决定吧！")
      return
    when RESULT_NO
      $scene = Scene_Map.new
      return
    end
  end
end