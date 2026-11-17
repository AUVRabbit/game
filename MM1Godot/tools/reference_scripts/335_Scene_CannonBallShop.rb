class Scene_CannonBallShop
  
  include MM_DataBase
  include MM_System
  
  def main
    
    # 执行过渡
    Graphics.transition(0)
    
    $game_party.set_cpl_party
    
    @spriteset_map = Spriteset_Map.new
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_CANNONBALLSHOP_BACK)
    @sprite_back.z = 8002
        
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8003
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @sprite_sell_back = Sprite.new
    @sprite_sell_back.bitmap = RPG::Cache.picture(PICTURE_SPECIALCANNONBALL_BACK)
    @sprite_sell_back.z = 8003
    @sprite_sell_back.visible = false
    
    @command_window = Window_CannonBallShopCommand.new
    @command_window.z = 8002
    @command_window.active = true
    @command_window.visible = true
    
    @ball_type_window = Window_CannonBallShopTypeSelect.new
    @ball_type_window.z = 8002
    @ball_type_window.visible = false
    
    @buy_ball_window = Window_CannonBallShopBuyCannonBallSelect.new($game_temp.cannonball_list)
    @buy_ball_window.z = 8002
    @buy_ball_window.visible = false
    
    @tank_select_window = Window_CannonBallShopTankSelect.new
    @tank_select_window.z = 8002
    @tank_select_window.visible = false
    
    @cannon_type_window = Window_CannonBallShopCannonSelect.new
    @cannon_type_window.z = 8002
    @cannon_type_window.visible = false
    
    @status_window = Window_CannonBallShopStatus.new
    @status_window.z = 8002
    @status_window.visible = false
    
    @sell_ball_window = Window_CannonBallShopSellCannonBallSelect.new
    @sell_ball_window.z = 8002
    @sell_ball_window.visible = false
    
    @number_window = Window_CannonBallShopNumberInput.new
    @number_window.z = 8004
    @number_window.visible = false
    
    @message_window = Window_Message.new
    
    $game_temp.message_text = "这里是炮弹店。品种齐全。买一些吧！"
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
    @command_window.dispose
    @ball_type_window.dispose
    @sell_ball_window.dispose
    @tank_select_window.dispose
    @cannon_type_window.dispose
    @status_window.dispose
    @buy_ball_window.dispose
    
    @sprite_gold.bitmap.dispose
    @sprite_gold.dispose
    
    @spriteset_map.dispose
    
    @message_window.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_sell_back.bitmap.dispose
    @sprite_sell_back.dispose
    
    @number_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
    
    $game_party.recover_org_party
  end
  
  def update
        
    @command_window.update
    @ball_type_window.update
    @sell_ball_window.update
    #@tank_select_window.update
    @cannon_type_window.update
    @status_window.update
    @buy_ball_window.update
    @spriteset_map.update
    
    if @command_window.visible && @command_window.active
      update_command
      return
    end
    
    if @ball_type_window.visible
      update_ball_type_select
      return
    end
    
    if @sell_ball_window.visible
      update_ball_sell
      return
    end
        
    if @cannon_type_window.visible
      update_cannon_select
      return
    end
    
    if @buy_ball_window.visible
      update_buy_ball
      return
    end
  end
  
  def update_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @message_window.terminate_message
      
      $game_temp.message_text = "买炮弹的话请上这儿来！"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      40.times {Graphics.update}
      $scene = Scene_Map.new
    end
    
    if Input.trigger?(Input::C)
      case @command_window.result
      when CANNONBALLSHOP_BUY
        $game_system.se_play($data_system.cancel_se)
        @message_window.terminate_message
      
        $game_temp.message_text = "噢！买吗？买哪个呢？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @command_window.visible = false
        @command_window.active = false
        @ball_type_window.visible = true
        @ball_type_window.reset
        return
      when CANNONBALLSHOP_SELL
        $game_system.se_play($data_system.cancel_se)

        @message_window.terminate_message
      
        $game_temp.message_text = "卖哪辆战车上的特殊炮弹？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        @tank_select_window.visible = true
        @tank_select_window.active = true
        @tank_select_window.reset
        
        loop do
          Graphics.update
          Input.update
          @tank_select_window.update
          if Input.trigger?(Input::B)
            @command_window.visible = true
            @command_window.active = true
            @command_window.reset
            @tank_select_window.visible = false
            @tank_select_window.active = false
            return
          end
          if Input.trigger?(Input::C)
            break
          end
        end
        
        @tank = $game_party.tanks[@tank_select_window.cursor_index]
        
        if @tank.underpan.special_cannonball == {}
          @message_window.terminate_message
          $game_temp.message_text = @tank.name + "没有携带特殊炮弹！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          return
        end
        
        @status_window.refresh_tank(@tank)
        @sell_ball_window.refresh_tank(@tank)
        @status_window.visible = true
        @sell_ball_window.visible = true
        @sell_ball_window.reset
        @sprite_sell_back.visible = true
        @command_window.visible = false
        @command_window.active = false
        return
      when CANNONBALLSHOP_EXIT
        $game_system.se_play($data_system.cancel_se)
        @message_window.terminate_message
      
        $game_temp.message_text = "买炮弹的话请上这儿来！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        $scene = Scene_Map.new
      end
      return
    end
  end
  
  def update_ball_type_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @command_window.visible = true
      @command_window.active = true
      @command_window.reset
      @ball_type_window.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @ball_type_window.result
      when CANNONBALLSHOPCANNONBALLTYPE_NORMAL
        
        @message_window.terminate_message
      
        $game_temp.message_text = "补充哪辆战车？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        
        @tank_select_window.visible = true
        @tank_select_window.reset
        loop do
          Graphics.update
          Input.update
          @tank_select_window.update
          if Input.trigger?(Input::B)
            @tank_select_window.visible = false
            @tank_select_window.active = false
            @ball_type_window.visible = true
            @ball_type_window.reset
            return
          end
          if Input.trigger?(Input::C)
            break
          end
        end
        @tank = $game_party.tanks[@tank_select_window.cursor_index]
        @cannon_type_window.visible = true
        @cannon_type_window.reset
        @cannon_type_window.refresh_tank(@tank)
        @ball_type_window.visible = false
        return
        
      when CANNONBALLSHOPCANNONBALLTYPE_SPECIAL
        
        @message_window.terminate_message
      
        $game_temp.message_text = "请选一种您想要的。"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @buy_ball_window.visible = true
        @buy_ball_window.reset
        @ball_type_window.visible = false
        return
        
      when CANNONBALLSHOPCANNONBALLTYPE_EXIT
        $game_system.se_play($data_system.cancel_se)
        @command_window.visible = true
        @command_window.active = true
        @command_window.reset
        @ball_type_window.visible = false
        return
      end
      return
    end
  end
  
  def update_cannon_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      loop do
        Graphics.update
        Input.update
        @tank_select_window.update
        if Input.trigger?(Input::B)
          @cannon_type_window.visible = false
          @ball_type_window.visible = true
          @ball_type_window.reset
          return
        end
        
        if Input.trigger?(Input::C)
          @tank = $game_party.tanks[@tank_select_window.cursor_index]
          @cannon_type_window.refresh_tank(@tank)
          return
        end
      end
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      part = @cannon_type_window.get_part
      case part
      when CANNONBALLPOSITION_MAIN_CANNON
        equipment = @tank.main_cannon
      when CANNONBALLPOSITION_SUB_CANNON
        equipment = @tank.sub_cannon
      when CANNONBALLPOSITION_SE
        equipment = @tank.se
      end
      
      if !equipment.limited_quantity? || equipment.quantity_full?
        @message_window.terminate_message
        $game_temp.message_text = "那个不补充也可以！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times{Graphics.update}
        return
      else
        @message_window.terminate_message
        $game_temp.message_text = "要补充多少？"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @message_window.terminate_message
        
        @number_window.visible = true
        @number_window.refresh_tank(equipment, CANNONBALLDRAWTYPE_BUYNORMAL)
        num = 1
        case equipment.quantity - equipment.quantity_reality
        when 0..9
          num = 1
        when 10..99
          num = 2
        when 100..999
          num = 3
        end
        @number_window.set_number_window(num)
        loop do
          Graphics.update
          Input.update
          @number_window.update
          if Input.trigger?(Input::C)
            break
          end
        end
        number = @number_window.number
        @number_window.visible = false
        #价格
        if equipment.cannonball_price == 0
          price = 5 * number
        else
          price = equipment.cannonball_price * number
        end
        
        @message_window.terminate_message
        $game_temp.message_text = number.to_s + "枚需" + price.to_s + "G可以吗？"
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
          
          if $game_party.gold < price
            
            @message_window.terminate_message
            $game_temp.message_text = "没钱了？要买别的么？"
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
              @command_window.visible = true
              @command_window.active = true
              @command_window.reset
              @tank_select_window.visible = false
              @tank_select_window.active = false
              @cannon_type_window.visible = false
              return
            when RESULT_NO
              @message_window.terminate_message
              $game_temp.message_text = "买炮弹的话请上这儿来！"
              loop do
                Graphics.update
                Input.update
                @message_window.update
                if @message_window.at_end
                  break
                end
              end
              40.times {Graphics.update}
              $scene = Scene_Map.new
            end
            return
          end
          equipment.quantity_add(number)
          $game_party.lose_gold(price)
          refresh_gold_draw
          @message_window.terminate_message
          $game_temp.message_text = "瞧。补充好了！还要补充吗"
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
            
            @command_window.visible = true
            @command_window.active = true
            @command_window.reset
            @tank_select_window.visible = false
            @tank_select_window.active = false
            @cannon_type_window.visible = false
              
          when RESULT_NO
            
            @message_window.terminate_message
            $game_temp.message_text = "买炮弹的话请上这儿来！"
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
            40.times {Graphics.update}
            $scene = Scene_Map.new
          end            
        
        when RESULT_NO
          
          $game_system.se_play($data_system.cancel_se)
          @message_window.terminate_message
      
          $game_temp.message_text = "买炮弹的话请上这儿来！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          $scene = Scene_Map.new
          
        end
      end
      
    end
    
  end
  
  def update_buy_ball
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @buy_ball_window.visible = false
      @ball_type_window.visible = true
      @ball_type_window.reset
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @message_window.terminate_message
      $game_temp.message_text = "补充哪辆战车？"
      #@buy_ball_window.active = false
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      @tank_select_window.visible = true
      @tank_select_window.active = true
      @tank_select_window.reset
      
      @cannonball = @buy_ball_window.item
      
      loop do
        Graphics.update
        Input.update
        @tank_select_window.update
        if Input.trigger?(Input::B)
          @tank_select_window.visible = false
          @tank_select_window.active = false
          @command_window.active = true
          @command_window.visible = true
          @command_window.reset
          return
        end
        if Input.trigger?(Input::C)
          break
        end
      end
      
      @tank = $game_party.tanks[@tank_select_window.cursor_index]
      
      @message_window.terminate_message
      $game_temp.message_text = "要补充多少？"
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      @message_window.terminate_message
      @number_window.visible = true
      num = 1
      dec = @tank.underpan.special_cannonball_capacity - @tank.underpan.special_cannonball_relity_capacity
      case dec
      when 1..9
        num = 1
      when 10..99
        num = 2
      when 100..999
        num = 3
      end
      @number_window.set_number_window(num)
      @number_window.refresh_tank_special(@tank, CANNONBALLDRAWTYPE_BUYSPECIAL)
      
      loop do
        Graphics.update
        Input.update
        @number_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      
      @number_window.visible = false
      number = @number_window.number
      
      if number == 0
        @command_window.visible = true
        @command_window.active = true
        @command_window.reset
        @buy_ball_window.visible = false
        @tank_select_window.active = false
        @tank_select_window.visible = false
        return
      end
      
      #价格
      price = @cannonball.price * number
      @message_window.terminate_message
      $game_temp.message_text = number.to_s + "枚需" + price.to_s + "G可以吗？"
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
        
        if $game_party.gold < price
          
          @message_window.terminate_message
          $game_temp.message_text = "没钱了？要买别的么？"
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
            @buy_ball_window.visible = true
            @buy_ball_window.active = true
            @buy_ball_window.reset
            @tank_select_window.visible = false
            @tank_select_window.active = false
            @cannon_type_window.visible = false
            return
          when RESULT_NO
            @message_window.terminate_message
            $game_temp.message_text = "买炮弹的话请上这儿来！"
            loop do
              Graphics.update
              Input.update
              @message_window.update
              if @message_window.at_end
                break
              end
            end
            40.times {Graphics.update}
            $scene = Scene_Map.new
          end
          return
        end
        
        #equipment.quantity_add(number)
        @tank.underpan.special_cannonball_get(@cannonball.id, number)
        $game_party.lose_gold(price)
        refresh_gold_draw
        
        @message_window.terminate_message
        $game_temp.message_text = "瞧。补充好了！还要补充吗"
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
          
          @buy_ball_window.visible = true
          @buy_ball_window.active = true
          @buy_ball_window.reset
          @tank_select_window.visible = false
          @tank_select_window.active = false
          @cannon_type_window.visible = false
            
        when RESULT_NO
          
          @message_window.terminate_message
          $game_temp.message_text = "买炮弹的话请上这儿来！"
          loop do
            Graphics.update
            Input.update
            @message_window.update
            if @message_window.at_end
              break
            end
          end
          40.times {Graphics.update}
          $scene = Scene_Map.new
        end

      when RESULT_NO
        
        $game_system.se_play($data_system.cancel_se)
        @message_window.terminate_message
        
        $game_temp.message_text = "买炮弹的话请上这儿来！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        $scene = Scene_Map.new
        
      end
      return
    end
  end
  
  def update_ball_sell
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @sell_ball_window.visible = false
      @command_window.visible = true
      @command_window.active = true
      @command_window.reset
      @tank_select_window.visible = false
      @tank_select_window.active = false
      @sprite_sell_back.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @tank = $game_party.tanks[@tank_select_window.cursor_index]
      if @tank.underpan.special_cannonball == {}
        @message_window.terminate_message
        $game_temp.message_text = @tank.name + "没有携带特殊炮弹！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        @command_window.visible = true
        @command_window.active = true
        @command_window.reset
        @status_window.visible = false
        @sell_ball_window.visible = false
        @sprite_sell_back.visible = false
        @tank_select_window.visible = false
        @tank_select_window.active = false
        return
      end
      @status_window.visible = true
      @status_window.refresh_tank(@tank)
      @sell_ball_window.visible = true
      @sell_ball_window.reset
      @sell_ball_window.refresh_tank(@tank)
      @message_window.terminate_message
      $game_temp.message_text = "卖哪种？"
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
        @sell_ball_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      @message_window.terminate_message
      @cannonball = @sell_ball_window.get_cannonball
      
      num = 1
      n = @tank.underpan.special_cannonball[@cannonball]
      case n
      when 1..9
        num = 1
      when 10..99
        num = 2
      when 100..999
        num = 3
      end
      @number_window.set_number_window(num)
      @number_window.refresh_sell(@tank, @cannonball, CANNONBALLDRAWTYPE_SELL)
      @number_window.visible = true
      loop do
        Graphics.update
        Input.update
        @number_window.update
        if Input.trigger?(Input::C)
          break
        end
      end
      number = @number_window.number
      #价格
      @number_window.visible = false
      price = number * $data_specialcannonballs[@cannonball].price / 2
      @message_window.terminate_message
      $game_temp.message_text = number.to_s + "枚" + price.to_s + "卖么？"
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
      @yes_no_window.visible = false
      case result
      when RESULT_YES
        $game_party.gain_gold(price)
        refresh_gold_draw
        @tank.underpan.special_cannonball_throw(@cannonball, number)
        @sell_ball_window.refresh_tank(@tank)
        @status_window.refresh_tank(@tank)
        @message_window.terminate_message
        $game_temp.message_text = "好，买下了！还有要卖的么？"
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
          return
        when RESULT_NO
          @sprite_sell_back.visible = false
          @tank_select_window.visible = false
          @tank_select_window.active = false
          @sell_ball_window.visible = false
          @command_window.visible = true
          @command_window.active = true
          @command_window.reset
          return
        end
      when RESULT_NO
        @message_window.terminate_message
        
        $game_temp.message_text = "买炮弹的话请上这儿来！"
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        40.times {Graphics.update}
        $scene = Scene_Map.new
      end
      
      return
    end
  end
  
  def refresh_gold_draw
    @sprite_gold.bitmap.dispose
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
  end
  
end