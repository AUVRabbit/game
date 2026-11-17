class Scene_SupplyShop
  
  include MM_DataBase
  include MM_System
  
  def main
    
    $game_party.set_cpl_party
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_SUPPLYSHOP_MAINBACK)
    @sprite_back.z = 8000
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8000
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @spriteset_map = Spriteset_Map.new
    
    @sprite_cannon_back = Sprite.new
    @sprite_cannon_back.bitmap = RPG::Cache.picture(PICTURE_SUPPLYSHOP_CANNONBALLSUPPLYBACK)
    @sprite_cannon_back.visible = false
    @sprite_cannon_back.z = 8001
    
    @main_command_window = Window_SupplyShopMainCommand.new
    @main_command_window.visible = true
    @main_command_window.active = true
    @main_command_window.z = 8002
    
    @type_command_window = Window_SupplyShopSupplyTypeSelection.new
    @type_command_window.visible = false
    @type_command_window.active = false
    @type_command_window.z = 8002
    
    @cannon_number_window = Window_SupplyShopCannonBallNumberSelect.new
    @cannon_number_window.visible = false
    @cannon_number_window.active = false
    @cannon_number_window.z = 8002
    
    @armour_number_window = Window_SupplyShopArmourNumberSelecion.new
    @armour_number_window.visible = false
    @armour_number_window.active = false
    @armour_number_window.z = 8002
    
    @cannon_select_window = Window_SupplyShopCannonBallSelect.new
    @cannon_select_window.visible = false
    @cannon_select_window.active = false
    @cannon_select_window.z = 8002
    
    @armour_command_window = Window_SupplyShopArmourSelection.new
    @armour_command_window.visible = false
    @armour_command_window.active = false
    @armour_command_window.z = 8002
    
    @tank_select_window = Window_SupplyShopTankSelect.new
    @tank_select_window.visible = false
    @tank_select_window.active = false
    @tank_select_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    
    @message_window = Window_Message.new
    
    show_message("欢迎光临战车店，补充什么？")
    
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
    
    @spriteset_map.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_cannon_back.bitmap.dispose
    @sprite_cannon_back.dispose
    
    @main_command_window.dispose
    @type_command_window.dispose
    @cannon_number_window.dispose
    @armour_number_window.dispose
    @cannon_select_window.dispose
    @armour_command_window.dispose
    @tank_select_window.dispose
    
    @message_window.dispose
    
    @yes_no_window.dispose if @yes_no_window != nil
    
    $game_party.recover_org_party
  end
  
  def update
    @main_command_window.update
    @type_command_window.update
    @cannon_select_window.update
    @armour_command_window.update
    @spriteset_map.update
    
    if @main_command_window.active
      update_main_command
      return
    end
    
    if @type_command_window.active
      update_type_command
      return
    end
    
    if @cannon_select_window.active
      update_cannon_select
      return
    end
    
    if @armour_command_window.active
      update_armour_command
      return
    end
  end
  
  def update_main_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_message("请再来！")
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @main_command_window.result
      when SUPPLYSHOPMAINCOMMAND_CANNON, SUPPLYSHOPMAINCOMMAND_ARMOUR
        @main_command_window.visible = false
        @main_command_window.active = false
        @type_command_window.visible = true
        @type_command_window.active = true
        @type_command_window.reset
      when SUPPLYSHOPMAINCOMMAND_EXIT
        show_message("请再来！")
        $scene = Scene_Map.new
      end
      return
    end
  end
  
  def update_type_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.decision_se)
      @main_command_window.visible = true
      @main_command_window.active = true
      @main_command_window.reset
      @type_command_window.visible = false
      @type_command_window.active = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @type_command_window.result
      when SUPPLYSHOPSUPPLYTYPE_ALL
        case @main_command_window.result
        when SUPPLYSHOPMAINCOMMAND_CANNON
          price = 0
          for tank in $game_party.tanks
            price += tank.cannonball_full_money
          end
          if price == 0
            show_message("已经装满了！")
            return
          else
            if price <= $game_party.gold
              str = "全部装满。合计为" + price.to_i.to_s + "G，行吗？"
              show_message(str)
              result = show_yes_no_window
              case result
              when RESULT_YES
                for tank in $game_party.tanks
                  tank.full_cannonball
                end
                $game_party.lose_gold(price.to_i)
                refresh_gold_draw
                show_message("弹药全部装满。检查完毕！", true)
                show_continue_ask() do 
                  @type_command_window.visible = false
                  @type_command_window.active = false
                  @main_command_window.visible = true
                  @main_command_window.active = true
                  @main_command_window.reset
                end
                return
              when RESULT_NO
                show_continue_ask() do 
                  @type_command_window.visible = false
                  @type_command_window.active = false
                  @main_command_window.visible = true
                  @main_command_window.active = true
                  @main_command_window.reset
                end
                return
              end
            else
              show_message("你的钱不够啊！", true)
              show_continue_ask() do 
                @type_command_window.visible = false
                @type_command_window.active = false
                @main_command_window.visible = true
                @main_command_window.active = true
                @main_command_window.reset
              end
              return
            end
            
          end
        when SUPPLYSHOPMAINCOMMAND_ARMOUR
          price = 0
          for tank in $game_party.tanks
            price += tank.armour_full_money
          end
          if price == 0
            show_message("已经装满了！")
            return
          else
            if price <= $game_party.gold
              str = "全部装满。合计为" + price.to_i.to_s + "G，行吗？"
              show_message(str)
              result = show_yes_no_window
              case result
              when RESULT_YES
                for tank in $game_party.tanks
                  tank.full_armour
                end
                $game_party.lose_gold(price.to_i)
                refresh_gold_draw
                show_continue_ask() do 
                  @type_command_window.visible = false
                  @type_command_window.active = false
                  @main_command_window.visible = true
                  @main_command_window.active = true
                  @main_command_window.reset
                end
                return
              when RESULT_NO
                show_continue_ask() do 
                  @type_command_window.visible = false
                  @type_command_window.active = false
                  @main_command_window.visible = true
                  @main_command_window.active = true
                  @main_command_window.reset
                end
                return
              end
            else
              show_message("你的钱不够啊！", true)
              show_continue_ask() do 
                @type_command_window.visible = false
                @type_command_window.active = false
                @main_command_window.visible = true
                @main_command_window.active = true
                @main_command_window.reset
              end
              return
            end
          end
        end
      when SUPPLYSHOPSUPPLYTYPE_PART
        case @main_command_window.result
        when SUPPLYSHOPMAINCOMMAND_CANNON
          show_message("要补充哪辆车的弹药？")
          @tank_select_window.visible = true
          @tank_select_window.active = true
          @tank = tank_select
          @type_command_window.visible = false
          @type_command_window.active = false
          @cannon_select_window.refresh_tank(@tank)
          @cannon_select_window.visible = true
          @cannon_select_window.active = true
          @main_command_window.reset
          @sprite_cannon_back.visible = true
          show_message("补充哪呢？")
          return
        when SUPPLYSHOPMAINCOMMAND_ARMOUR
          show_message("要补充哪辆车的装甲？")
          @tank_select_window.visible = true
          @tank_select_window.active = true
          @type_command_window.visible = false
          @type_command_window.active = false
          @tank = tank_select
          @armour_command_window.refresh_tank(@tank)
          @armour_command_window.visible = true
          @armour_command_window.active = true
          @armour_command_window.reset
          return
        end
      when SUPPLYSHOPSUPPLYTYPE_EXIT
        @main_command_window.visible = true
        @main_command_window.active = true
        @main_command_window.reset
        @type_command_window.visible = false
        @type_command_window.active = false
        return
      end
    end
  end
  
  def update_cannon_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.decision_se)
      show_message("是吗？还有别的事吗？")
      @cannon_select_window.visible = false
      @cannon_select_window.active = false
      @main_command_window.visible = true
      @main_command_window.active = true
      @main_command_window.reset
      @sprite_cannon_back.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      if @cannon_select_window.can_supply?
        count, price = @cannon_select_window.count_and_number
        str = sprintf("啊。一共%d枚%dG。可以吗？", count, price.to_i)
        show_message(str)
        result = show_yes_no_window
        case result
        when RESULT_YES
          if $game_party.gold >= price
            $game_party.lose_gold(price.to_i)
            refresh_gold_draw
            equipment = @cannon_select_window.equipment
            equipment.quantity_full
            show_message("装好了！", true)
            show_countinue_ask_cannonball
            return
          else
            show_message("你的钱不够啊！", true)
            show_continue_ask() do 
              @cannon_select_window.visible = false
              @cannon_select_window.active = false
              @main_command_window.active = true
              @main_command_window.visible = true
              @main_command_window.reset
              @sprite_cannon_back.visible = false
            end
            return
          end
        when RESULT_NO
          show_message("补充多少。要决定吗？")
          result = show_yes_no_window
          case result
          when RESULT_YES
            @message_window.terminate_message
            @cannon_number_window.visible = true
            @cannon_number_window.active = true
            equipment = @cannon_select_window.equipment
            case equipment.quantity - equipment.quantity_reality
            when 0...10
              num = 1
            when 10...99
              num = 2
            end
            @cannon_number_window.refresh_equipment(equipment)
            @cannon_number_window.set_number_window(num)
            loop do
              Graphics.update
              Input.update
              @cannon_number_window.update
              if Input.trigger?(Input::C)
                break
              end
            end
            @cannon_number_window.visible = false
            @cannon_number_window.active = false
            number = @cannon_number_window.number
            cannon_price = 0
            case equipment
            when Game_MainCannon
              cannon_price = 5 * number
            when Game_SubCannon, Game_SE
              cannon_price = equipment.price / 10 * number
            end
            if $game_party.gold >= cannon_price
              str = sprintf("%s枚。一共%sG。可以吗？", number, cannon_price.to_i)
              show_message(str)
              result = show_yes_no_window
              case result
              when RESULT_YES
                show_message("装好了！", true)
                equipment.quantity_add(number)
                $game_party.lose_gold(cannon_price.to_i)
                refresh_gold_draw
                @cannon_select_window.refresh
                show_countinue_ask_cannonball
                return
              when RESULT_NO
                show_message("是吗？还有别的事吗？")
                @cannon_select_window.visible = false
                @cannon_select_window.active = false
                @main_command_window.visible = true
                @main_command_window.active = true
                @main_command_window.reset
                @sprite_cannon_back.visible = false
                return
              end
            else
              show_message("你的钱不够啊！", true)
              show_continue_ask() do 
                @cannon_select_window.visible = false
                @cannon_select_window.active = false
                @main_command_window.visible = true
                @main_command_window.active = true
                @main_command_window.reset
                @sprite_cannon_back.visible = false
              end
              return
            end
          when RESULT_NO
            show_message("是吗？真遗憾。")
            return
          end
        end
      else
        show_message("那么就没有必要补充了。")
        return
      end
    end
  end
  
  def update_armour_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @armour_command_window.active = false
      @armour_command_window.visible = false
      @type_command_window.active = true
      @type_command_window.visible = true
      @type_command_window.reset
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @armour_command_window.result
      when SUPPLYSHOPSUPPLYSHOP_ALL
        price = @tank.armour_full_money
        show_message("装满。剩余载重量为0。可以吗？")
        result = show_yes_no_window
        case result
        when RESULT_YES
          if $game_party.gold >= price
            @tank.full_armour
            $game_party.lose_gold(price.to_i)
            refresh_gold_draw
            show_continue_ask() do 
              @armour_command_window.active = false
              @armour_command_window.visible = false
              @main_command_window.active = true
              @main_command_window.visible = true
              @main_command_window.reset
            end
          else
            show_message("你的钱不够啊！", true)
            show_continue_ask() do 
              @armour_command_window.active = false
              @armour_command_window.visible = false
              @main_command_window.active = true
              @main_command_window.visible = true
              @main_command_window.reset
            end
          end
          return
        when RESULT_NO
          show_message("是吗？还有别的事吗？")
          @armour_command_window.active = false
          @armour_command_window.visible = false
          @main_command_window.active = true
          @main_command_window.visible = true
          @main_command_window.reset
          return
        end
      when SUPPLYSHOPSUPPLYSHOP_INPUT
        @message_window.terminate_message
        @armour_number_window.active = true
        @armour_number_window.visible = true
        case @tank.maxhp - @tank.hp
        when 0...10
          num = 1
        when 10...100
          num = 2
        when 100...1000
          num = 3
        when 1000...10000
          num = 4
        end
          
        @armour_number_window.refresh_tank(@tank)
        @armour_number_window.set_number_window(num)
        loop do
          Graphics.update
          Input.update
          @armour_number_window.update
          if Input.trigger?(Input::C)
            break
          end
        end
        number = @armour_number_window.number
        @armour_number_window.active = false
        @armour_number_window.visible = false
        
        if number % 100 == 0
          armour_price = number / 100
        else
          armour_price = number / 100 + 1
        end
        str = armour_price.to_i.to_s + "G可以吗？"
        show_message(str)
        result = show_yes_no_window
        case result
        when RESULT_YES
          if $game_party.gold >= armour_price
            $game_party.lose_gold(armour_price.to_i)
            refresh_gold_draw
            @tank.hp += number
            show_continue_ask() do 
              @armour_command_window.active = false
              @armour_command_window.visible = false
              @main_command_window.visible = true
              @main_command_window.active = true
              @main_command_window.reset
            end
          else
            show_message("你的钱不够啊！", true)
            show_continue_ask() do 
              @armour_command_window.active = false
              @armour_command_window.visible = false
              @main_command_window.active = true
              @main_command_window.visible = true
              @main_command_window.reset
            end
          end
        else
          show_message("是吗？还有别的事吗？")
          @armour_command_window.active = false
          @armour_command_window.visible = false
          @main_command_window.active = true
          @main_command_window.visible = true
          @main_command_window.reset
          return
        end
        return
      when SUPPLYSHOPSUPPLYSHOP_EXIT
        @armour_command_window.active = false
        @armour_command_window.visible = false
        @type_command_window.active = true
        @type_command_window.visible = true
        @type_command_window.reset
        return
      end
    end
  end
  
  #辅助方法
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
      if Input.trigger?(Input::C)
        break
      end
    end
    @yes_no_window.visible = false
    return @yes_no_window.result
  end
  
  def show_continue_ask
    show_message("还需要补充吗？")
    result = show_yes_no_window
    case result
    when RESULT_YES
      yield
    when RESULT_NO
      show_message("请再来！", true)
      $scene = Scene_Map.new
    end
    return
  end
  
  def show_countinue_ask_cannonball
    show_message("还要补充别的吗？")
    result = show_yes_no_window
    case result
    when RESULT_YES
      show_message("补充哪呢？")
    when RESULT_NO
      @cannon_select_window.visible = false
      @cannon_select_window.active = false
      @main_command_window.visible = true
      @main_command_window.active = true
      @main_command_window.reset
      @sprite_cannon_back.visible = false
    end
    return
  end
  
  def tank_select
    loop do
      Graphics.update
      Input.update
      @tank_select_window.update
      if Input.trigger?(Input::C)
        break
      end
    end
    return $game_party.tanks[@tank_select_window.cursor_index]
  end
  
  def refresh_gold_draw
    @sprite_gold.bitmap.dispose
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
  end

end