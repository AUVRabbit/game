class Scene_RepairShop
  
  include MM_DataBase
  include MM_System
  
  def main
    
    $game_party.set_cpl_party
    
    # 执行过渡
    Graphics.transition(0)
    
    @spriteset_map = Spriteset_Map.new
    
    @broken_equipments_ary = $game_party.get_tank_broken_equipments
    
    #判断有无装备损坏
    if @broken_equipments_ary == []
      no_broken_pro
      return
    end
    
    #判斷是不是只有一輛戰車一個裝備損壞
    if @broken_equipments_ary.size == 1
      if @broken_equipments_ary[0][1].size == 1
        one_broken_pro
        return
      end
    end
    
    result = before_pro
    if !result
      return
    end
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_REPAIRSHOP_BACK)
    @sprite_back.z = 8003
    
    @list_window = Window_RepairShopList.new
    @list_window.active = false
    @list_window.z = 9999
    @command_window = Window_RepairShopCommand.new
    @command_window.active = true
    @command_window.z = 9999
    
    @message_window = Window_Message.new
    $game_temp.message_text = "要修理哪儿呢？"
    
    loop do
      Graphics.update
      Input.update
      @message_window.update
      if @message_window.at_end
        break
      end
    end
    
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面
      update
      # 如果切换画面就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    
    @message_window.dispose
    if @yes_no_window != nil
      if !@yes_no_window.disposed?
        @yes_no_window.dispose
      end
    end
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @list_window.dispose
    @command_window.dispose
    @spriteset_map.dispose
    
    $game_party.recover_org_party
  end
  
  def update
    @list_window.update
    @command_window.update
    @spriteset_map.update
    
    if @command_window.active
      update_command
      return
    end
    
    if @list_window.active
      update_list
      return
    end
    
  end
  
  def update_list
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      broken_equipments_ary = $game_party.get_tank_broken_equipments
      if broken_equipments_ary == []
        @message_window.terminate_message
        $game_temp.message_text = "若是修车的话，随时欢迎！"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        $scene = Scene_Map.new
        return
      end
      
      @message_window.terminate_message
      $game_temp.message_text = "坏了还不修吗？"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @yes_no_window = Window_YesOrNo.new
      
      loop do
        Graphics.update
        Input.update
        @yes_no_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      result = @yes_no_window.result
      case result
      when RESULT_YES
        @message_window.terminate_message
        $game_temp.message_text = "是吗？那就算了。"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        $scene = Scene_Map.new
        return
      when RESULT_NO
        @message_window.terminate_message
        $game_temp.message_text = "修哪儿呢？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @list_window.active = true
        @command_window.acitive = false
        return
      end
      
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      broken_equipments_ary = $game_party.get_tank_broken_equipments
      if broken_equipments_ary == []
        @message_window.terminate_message
        $game_temp.message_text = "若是修车的话，随时欢迎！"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        $scene = Scene_Map.new
        return
      end
      return unless @list_window.effective?
      equipment = @list_window.equipment
      repair_price = equipment.repair_price
      @message_window.terminate_message
      $game_temp.message_text = "修理的话，需要" + repair_price.to_s + "G，可以吗？"
      loop do
        Graphics.update
       Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @yes_no_window = Window_YesOrNo.new
      
      loop do
        Graphics.update
        Input.update
        @yes_no_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
      @yes_no_window.visible = false
      result = @yes_no_window.result
      case result
      when RESULT_YES
        
        if $game_party.gold >= repair_price
          
          @message_window.terminate_message
          $game_temp.message_text = "好吧！"
      
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
      
          loop do
            Graphics.update
            Input.update
            if Input.trigger?(Input::C)
              break
            end
          end
          
          $game_party.lose_gold(repair_price)
          Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
          equipment.repair
          
          @list_window.refresh
          @list_window.index = 0
          @message_window.terminate_message
          $game_temp.message_text = "好了，修完了！"
            
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          
          loop do
            Graphics.update
            Input.update
            if Input.trigger?(Input::C)
              break
            end
          end
          return
          
        else
          
          @message_window.terminate_message
          $game_temp.message_text = "你的钱不够啊！若是修车的话，随时欢迎！"
      
          loop do
            Graphics.update
            Input.update
              @message_window.update
            if @message_window.at_end
              break
            end
          end
      
          loop do
            Graphics.update
            Input.update
              if Input.trigger?(Input::C)
              break
            end
          end
          $scene = Scene_Map.new
          return       
          
        end
        
      when RESULT_NO
        @message_window.terminate_message
        $game_temp.message_text = "修哪儿呢？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @list_window.active = true
        @command_window.active = false
        @command_window.visible = false
        return
      end
      
    end
  end
  
  def update_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @message_window.terminate_message
      $game_temp.message_text = "是吗？那就算了。"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::C)
      result = @command_window.result
      case result
      when REPAIRSHOPCOMMAND_ALL
        @command_window.visible = false
        repair_price = 0
        for i in 0...@broken_equipments_ary.size
          tp_ary = @broken_equipments_ary[i][1]
          for j in 0...tp_ary.size
            repair_price += tp_ary[j].repair_price
          end
        end
        
        @message_window.terminate_message
        $game_temp.message_text = "全部修理好。需要" + repair_price.to_s + "G，可以吗？"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @yes_no_window = Window_YesOrNo.new
        loop do
          Graphics.update
          Input.update
          @yes_no_window.update
          if Input.trigger?(Input::C)
            break
          end
        end
        
        @yes_no_window.visible = false
        result = @yes_no_window.result
        
        case result
        when RESULT_YES
          
          @message_window.terminate_message
          $game_temp.message_text = "好吧！"
      
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
      
          loop do
            Graphics.update
            Input.update
            if Input.trigger?(Input::C)
              break
            end
          end
          
          #修理
          if $game_party.gold >= repair_price
            
            $game_party.lose_gold(repair_price)
            for i in 0...@broken_equipments_ary.size
              tp_ary = @broken_equipments_ary[i][1]
              for j in 0...tp_ary.size
                tp_ary[j].repair
              end
            end
            Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
            @list_window.refresh
            @message_window.terminate_message
            $game_temp.message_text = "好了，修完了！"
            
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
          
            loop do
              Graphics.update
              Input.update
              if Input.trigger?(Input::C)
                break
              end
            end
          
            @message_window.terminate_message
            $game_temp.message_text = "认真维护战车。才是延长寿命的秘诀！"
      
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
      
            loop do
              Graphics.update
              Input.update
              if Input.trigger?(Input::C)
                break
              end
            end
            $scene = Scene_Map.new
            return
          else
            @message_window.terminate_message
            $game_temp.message_text = "你的钱不够啊！若是修车的话，随时欢迎！"
      
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
      
            loop do
              Graphics.update
              Input.update
              if Input.trigger?(Input::C)
                break
              end
            end
            $scene = Scene_Map.new
            return       
          end
          
        when RESULT_NO
          @message_window.terminate_message
          $game_temp.message_text = "选择一下。然后再修？"
          
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          
          @yes_no_window = Window_YesOrNo.new
          
          loop do
            Graphics.update
            Input.update
            @yes_no_window.update
            if Input.trigger?(Input::C)
              break
            end
          end
          @yes_no_window.visible = false
          result = @yes_no_window.result
          case result
          when RESULT_YES
            @message_window.terminate_message
            $game_temp.message_text = "修哪儿呢？"
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
            
            @command_window.active = false
            @command_window.visible = false
            @list_window.active = true
            return
          when RESULT_NO
            @message_window.terminate_message
            $game_temp.message_text = "是吗？那就算了。"
            
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
      
            loop do
              Graphics.update
              Input.update
              if Input.trigger?(Input::C)
                break
              end
            end
            $scene = Scene_Map.new
            return
          end
        end
        
        
      when REPAIRSHOPCOMMAND_SINGLE
        @message_window.terminate_message
        $game_temp.message_text = "修哪儿呢？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        
        @command_window.active = false
        @command_window.visible = false
        @list_window.active = true
        return
      when REPAIRSHOPCOMMAND_EXIT
        @command_window.visible = false
        @message_window.terminate_message
        $game_temp.message_text = "是吗？那就算了。"
      
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            break
          end
        end
        $scene = Scene_Map.new
        return
      end
    end
    
  end
  
  def before_pro
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8000
    
    @message_window = Window_Message.new
    $game_temp.message_text = "这里是战车修理店。要修车吗？"
    
    loop do
      Graphics.update
      Input.update
      @message_window.update
      if @message_window.at_end
        break
      end
    end
    
    @yes_no_window = Window_YesOrNo.new
    loop do
      Graphics.update
      Input.update
      @yes_no_window.update
      if Input.trigger?(Input::C)
        break
      end
    end
    
    @yes_no_window.visible = false
    result = @yes_no_window.result
    case result
    when RESULT_YES
      @message_window.terminate_message
      $game_temp.message_text = "哪辆车坏了。给我看看！"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
      @message_window.terminate_message
      $game_temp.message_text = "坏的好厉害啊！"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end      
      @yes_no_window.dispose
      @message_window.dispose
      @sprite_back.bitmap.dispose
      @sprite_back.dispose
      
      return true
      
    when RESULT_NO
      @message_window.terminate_message
      $game_temp.message_text = "若是修车的话，随时欢迎！"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          break
        end
      end
    end
    
    @yes_no_window.dispose
    @message_window.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    $game_party.recover_org_party
    $scene = Scene_Map.new
    return false
  end
  
  def no_broken_pro
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8003
    @message_window = Window_Message.new
    @message_window.terminate_message
    $game_temp.message_text = "这里是战车修理店。要修车吗？"
    
    loop do
      Graphics.update
      Input.update
      @spriteset_map.update
      @message_window.update
      if @message_window.at_end
        break
      end
    end
    
    @yes_no_window = Window_YesOrNo.new
    loop do
      Graphics.update
      Input.update
      @spriteset_map.update
      @yes_no_window.update
      if Input.trigger?(Input::C)
        break
      end
    end
    result = @yes_no_window.result
    @yes_no_window.visible = false
    case result
    when RESULT_YES
      @message_window.terminate_message
      $game_temp.message_text = "哪辆车坏了。给我看看！"
    
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
    
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        if Input.trigger?(Input::C)
          break
        end
      end
    
      @message_window.terminate_message
      $game_temp.message_text = "坏的好厉害啊！呵呵，骗你的，你的战车很健康，安心去冒险吧！"
    
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
    
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        if Input.trigger?(Input::C)
          break
        end
      end
    when RESULT_NO
      @message_window.terminate_message
      $game_temp.message_text = "若是修车的话，随时欢迎！"
      
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        if Input.trigger?(Input::C)
          break
        end
      end
    end
    
    @yes_no_window.dispose
    @message_window.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    $game_party.recover_org_party
    $scene = Scene_Map.new
    return

  end
  
  def one_broken_pro
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_MENU_BACK)
    @sprite_back.y = 480 - @sprite_back.bitmap.height
    @sprite_back.z = 8000
    
    @message_window = Window_Message.new
    $game_temp.message_text = "这里是战车修理店。要修车吗？"
        
    loop do
      Graphics.update
      Input.update
      @message_window.update
      @spriteset_map.update
      if @message_window.at_end
        break
      end
    end
    
    @yes_no_window = Window_YesOrNo.new
    loop do
      Graphics.update
      Input.update
      @spriteset_map.update
      @yes_no_window.update
      if Input.trigger?(Input::C)
        break
      end
    end
    
    @yes_no_window.visible = false
    result = @yes_no_window.result
    case result
    when RESULT_YES
      @message_window.terminate_message
      $game_temp.message_text = "哪辆车坏了。给我看看！"
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
      tank = @broken_equipments_ary[0][0]
      equipment = @broken_equipments_ary[0][1][0]
      repair_price = equipment.repair_price
      @message_window.terminate_message
      $game_temp.message_text =\
        sprintf("是%s的%s。如果修理的话，需要%sG，可以吗？",\
          tank.name, equipment.name, repair_price)
          
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      @yes_no_window = Window_YesOrNo.new

      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        @yes_no_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
      @yes_no_window.visible = false
      result = @yes_no_window.result
      case result
      when RESULT_YES
        
        if $game_party.gold >= repair_price
          
          #Audio
          $game_party.lose_gold(repair_price)
          Audio.se_play("Audio/SE/" + SE_REPAIRE, 100, 100)
          equipment.repair
          
          @message_window.terminate_message
          $game_temp.message_text = "修理好了！以后要小心。"
          
          loop do
            Graphics.update
            Input.update
            @spriteset_map.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
      
          loop do
            Graphics.update
            Input.update
            @spriteset_map.update
            if Input.trigger?(Input::C)
              break
            end
          end
          $game_party.recover_org_party
          $scene = Scene_Map.new
        else
          
          @message_window.terminate_message
          $game_temp.message_text = "你的钱不够啊！若是修车的话，随时欢迎！"
          
          loop do
            Graphics.update
            Input.update
            @spriteset_map.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
      
          loop do
            Graphics.update
            Input.update
            @spriteset_map.update
            if Input.trigger?(Input::C)
              break
            end
          end
          $game_party.recover_org_party
          $scene = Scene_Map.new
        end
        
      when RESULT_NO
        
        @message_window.terminate_message
        $game_temp.message_text = "是的！若是修车的话，随时欢迎！"
      
        loop do
          Graphics.update
          Input.update
          @spriteset_map.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
      
        loop do
          Graphics.update
          Input.update
          @spriteset_map.update
          if Input.trigger?(Input::C)
            break
          end
        end
        $game_party.recover_org_party
        $scene = Scene_Map.new
      end
      
    when RESULT_NO
      @message_window.terminate_message
      $game_temp.message_text = "若是修车的话，随时欢迎！"
      
      loop do
        Graphics.update
        Input.update
        @message_window.update
        @spriteset_map.update
        if @message_window.at_end
          break
        end
      end
      
      loop do
        Graphics.update
        Input.update
        @spriteset_map.update
        if Input.trigger?(Input::C)
          break
        end
      end
      $game_party.recover_org_party
      $scene = Scene_Map.new
    end
    
    @yes_no_window.dispose if @yes_no_window != nil
    @message_window.dispose
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    return
  end
  
end