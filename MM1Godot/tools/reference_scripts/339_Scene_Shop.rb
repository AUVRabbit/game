class Scene_Shop
  
  include MM_DataBase
  include MM_System
  
  def main
    
    $game_party.set_cpl_party
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_SHOP_MAINBACK)
    @sprite_back.z = 8001
    
    @sprite_name = Sprite.new
    case $game_temp.shop_type
    when SHOPTYPE_PEOPLEEQUIPMENT
      @sprite_name.bitmap = RPG::Cache.picture(PICTURE_SHOP_PEOPLEEQUIPMENTSHOPNAME)
    when SHOPTYPE_PEOPLEITEM
      @sprite_name.bitmap = RPG::Cache.picture(PICTURE_SHOP_PEOPLEITEMSHOPNAME)
    when SHOPTYPE_TANKEQUIPMENT
      @sprite_name.bitmap = RPG::Cache.picture(PICTURE_SHOP_TANKEQUIPMENTSHOPNAME)
    when SHOPTYPE_TANKITEM
      @sprite_name.bitmap = RPG::Cache.picture(PICTURE_SHOP_TANKITEMSHOPNAME)
    end
    @sprite_name.x = 16
    @sprite_name.y = 16
    @sprite_name.z = 8001
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8001
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @spriteset_map = Spriteset_Map.new
    
    if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
      @info_window = Window_ShopGoodInfo.new
      @info_window.visible = false
      @info_window.active = false
      @info_window.z = 8002
      @info_window.refresh_item($game_temp.shop_goods[0])
    end
    
    case $game_temp.shop_type
    when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_PEOPLEITEM
      @obj_select_window = Window_ShopPeopleSelect.new
    when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
      @obj_select_window = Window_ShopTankSelect.new
    end
    @obj_select_window.z = 8002
    
    @main_command_window = Window_ShopMainCommand.new
    @main_command_window.visible = true
    @main_command_window.active = true
    @main_command_window.z  = 8002
    
    @equipment_item_window = Window_ShopEquipmentAndItem.new
    @equipment_item_window.visible = false
    @equipment_item_window.active = false
    @equipment_item_window.z = 8002
    
    @buy_list_window = Window_ShopBuyGoodsList.new($game_temp.shop_goods)
    @buy_list_window.active = false
    @buy_list_window.visible = false
    @buy_list_window.z = 8002
    
    @sell_list_window = Window_ShopSellGoodsList.new
    @sell_list_window.active = false
    @sell_list_window.visible = false
    @sell_list_window.z = 8002
    
    # 执行过渡
    Graphics.transition
    
    @message_window = Window_Message.new
    
    case $game_temp.shop_type
    when SHOPTYPE_PEOPLEEQUIPMENT
      show_message("欢迎光临武器店。")
    when SHOPTYPE_PEOPLEITEM
      show_message("欢迎光临道具店。")
    when SHOPTYPE_TANKEQUIPMENT
      show_message("这里是零件店")
    when SHOPTYPE_TANKITEM
      show_message("战车零件店！")
    end
    
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
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_name.bitmap.dispose
    @sprite_name.dispose
    
    @spriteset_map.dispose
    
    @message_window.dispose
    
    @info_window.dispose if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
    @main_command_window.dispose
    @equipment_item_window.dispose
    @buy_list_window.dispose
    @sell_list_window.dispose
    @obj_select_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
    
    $game_party.recover_org_party
  end
  
  def update    
    @main_command_window.update
    @equipment_item_window.update
    @buy_list_window.update
    @sell_list_window.update
    @spriteset_map.update
    @info_window.update
    
    if @main_command_window.active
      update_command
      return
    end
    
    if @equipment_item_window.active
      update_equip_item
      return
    end
    
    if @buy_list_window.active
      update_buy
      return
    end
    
    if @sell_list_window.active
      update_sell
      return
    end
    
  end
  
  def update_command
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_message("请再来！", true)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @main_command_window.result
      when SHOPCOMMAND_BUY
        case $game_temp.shop_type
        when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_PEOPLEITEM, SHOPTYPE_TANKITEM
          show_message("买什么？")
        when SHOPTYPE_TANKEQUIPMENT
          show_message("买什么？", true)
          show_message("其它地方也有卖东西的。您去看看。")
        end
        @main_command_window.visible = false
        @main_command_window.active = false
        @main_command_window.reset
        @buy_list_window.visible = true
        @buy_list_window.active = true
        @info_window.visible = true if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
        @info_window.active = true if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
      when SHOPCOMMAND_SELL
        @main_command_window.visible = false
        @main_command_window.active = false
        @main_command_window.reset
        case $game_temp.shop_type
        when SHOPTYPE_PEOPLEEQUIPMENT
          show_message("谁在卖呢？")
        when SHOPTYPE_PEOPLEITEM
          show_message("哪位卖呢？")
        when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
          show_message("卖哪辆车的？")
        end
        @obj = obj_select
        @sell_list_window.refresh_obj(@obj, SHOPGOODTYPE_EQUIPMENT)
        @sell_list_window.visible = true
        @sell_list_window.active = false
        @equipment_item_window.active = true
        @equipment_item_window.visible = true
        return
      when SHOPCOMMAND_EXIT
        show_message("请再来！", true)
        $scene = Scene_Map.new
      end
    end
  end
  
  def update_buy
    
    if (Input.press?(Input::UP) || Input.trigger?(Input::DOWN)) && $game_temp.shop_type != SHOPTYPE_TANKITEM
      @info_window.refresh_item(@buy_list_window.good)
    end
    
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_continue_ask() do
        @main_command_window.visible = true
        @main_command_window.active = true
        @buy_list_window.active = false
        @buy_list_window.visible = false
        @buy_list_window.reset
        @info_window.visible = false  if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
        @info_window.active = false  if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
      end
      return
    end
    
    if Input.trigger?(Input::C)
      good = @buy_list_window.good
      case $game_temp.shop_type
      when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_PEOPLEITEM
        str = sprintf("是%s。收您%sG，可以吗？", good.name, good.price)
        show_message(str)
      when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
        str = sprintf("是%s。很好要收%sG。", good.name, good.price)
        show_message(str)
      end
      result = show_yes_no_window
      case result
      when RESULT_YES
        case $game_temp.shop_type
        when SHOPTYPE_PEOPLEEQUIPMENT
          show_message("钱正好。谁拿？")
        when SHOPTYPE_PEOPLEITEM
          show_message("谁拿呢？")
        when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
          show_message("装在哪个车上？")
        end
        @obj = obj_select do
          @main_command_window.visible = true
          @main_command_window.active = true
          @buy_list_window.active = false
          @buy_list_window.visible = false
          @buy_list_window.reset
        end
        return if @obj == nil
        #如果錢夠
        if $game_party.gold >= good.price
          result = select_load_target
          if result
            #如果超重（仅对于战车武器）
            if @obj.is_a?(Game_Tank)\
              && $game_temp.shop_type == SHOPTYPE_TANKEQUIPMENT\
              && @obj.load_reality + good.weight > @obj.load_max
              show_message("超重了。还要装吗？")
              result = show_yes_no_window
              case result
              when RESULT_YES
                str = sprintf("谢谢！%s全装好了！", @obj.name)
                show_message(str)
                case good
                when RPG::MainCannon
                  good_obj = Game_MainCannon.new(good.id)
                when RPG::SubCannon
                  good_obj = Game_SubCannon.new(good.id)
                when RPG::SE
                  good_obj = Game_SE.new(good.id)
                when RPG::C_Unit
                  good_obj = Game_C_Unit.new(good.id)
                when RPG::Engine
                  good_obj = Game_Engine.new(good.id)
                end
                @obj.gain_equipments(good_obj)
                $game_party.lose_gold(good.price)
                refresh_gold_draw
                return
              when RESULT_NO
                show_continue_ask() do
                  @main_command_window.visible = true
                  @main_command_window.active = true
                  @buy_list_window.active = false
                  @buy_list_window.visible = false
                  @info_window.visible = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
                  @info_window.active = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
                  @buy_list_window.reset
                end
                return
              end
            else
              if $game_temp.shop_type == SHOPTYPE_TANKEQUIPMENT\
                || $game_temp.shop_type == SHOPTYPE_PEOPLEEQUIPMENT
                result = select_load_target_another
                if result
                  case $game_temp.shop_type
                  when SHOPTYPE_PEOPLEEQUIPMENT
                    str = sprintf("好啊！%s！", @obj.name)
                    @obj.gain_equipments(good.clone)
                  when SHOPTYPE_TANKEQUIPMENT
                    str = sprintf("谢谢！%s全装好了！", @obj.name)
                    case good
                    when RPG::MainCannon
                      good_obj = Game_MainCannon.new(good.id)
                    when RPG::SubCannon
                      good_obj = Game_SubCannon.new(good.id)
                    when RPG::SE
                      good_obj = Game_SE.new(good.id)
                    when RPG::C_Unit
                      good_obj = Game_C_Unit.new(good.id)
                    when RPG::Engine
                      good_obj = Game_Engine.new(good.id)
                    end
                    @obj.gain_equipments(good_obj)
                  end
                  $game_party.lose_gold(good.price)
                  refresh_gold_draw
                  show_message(str)
                  return
                else
                  return
                end
              else
                case $game_temp.shop_type
                when SHOPTYPE_PEOPLEITEM
                  str = sprintf("好啊！%s！", @obj.name)
                  @obj.gain_item(good.clone)
                when SHOPTYPE_TANKITEM
                  str = sprintf("谢谢！%s全装好了！", @obj.name)
                  @obj.gain_item(good.clone)
                end
                $game_party.lose_gold(good.price)
                refresh_gold_draw
                show_message(str)                
                return
              end
            end
          else
            return
          end
        else
          show_message("唉呀！客人您的钱不够啊！", true)
          show_continue_ask() do
            @main_command_window.visible = true
            @main_command_window.active = true
            @buy_list_window.active = false
            @buy_list_window.visible = false
            @info_window.visible = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
            @info_window.active = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
            @buy_list_window.reset
          end
          return
        end
      when RESULT_NO
        case $game_temp.shop_type
        when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
          show_message("什么都不买。按B键！")
        when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_PEOPLEITEM
          show_message("若什么都不买。按B键！")
        end
        return
      end
    end
  end
  
  def update_equip_item
    if Input.trigger?(Input::B)
      @equipment_item_window.active = false
      $game_system.se_play($data_system.cancel_se)
      case $game_temp.shop_type
      when SHOPTYPE_PEOPLEEQUIPMENT
        show_message("谁在卖呢？")
      when SHOPTYPE_PEOPLEITEM
        show_message("哪位卖呢？")
      when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
        show_message("卖哪辆车的？")
      end
      @obj = obj_select do
        @equipment_item_window.visible = false
        @main_command_window.visible = true
        @main_command_window.active = true
        @sell_list_window.active = false
        @sell_list_window.visible = false
      end
      if @obj == nil
        return
      else
        @equipment_item_window.active = true
        return
      end
    end
    
    if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
      @sell_list_window.refresh_obj(@obj, @equipment_item_window.result)
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @equipment_item_window.active = false
      @sell_list_window.active = true
      return
    end
  end
  
  def update_sell
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equipment_item_window.active = true
      @sell_list_window.active = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      good = @sell_list_window.good
      if good == nil
        return
      end
      #如果賣不了
      if good.is_a?(RPG::Item)
        if !good.can_drop_sell
          case $game_temp.shop_type
          when SHOPTYPE_PEOPLEEQUIPMENT
            show_message("这个。啊！这个卖不了！")
          when SHOPTYPE_PEOPLEITEM
            show_message("那个东西取不出来！")
          when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
            show_message("呀……那不能卖！")
          end
          return
        else
          if good.type == ITEM_PEOPLE
            str = sprintf("是%s。%sG卖吗？", good.name, (good.price / 2).to_i)
          else
            str = sprintf("是%s。严重受损。%sG。可以吗？", good.name, (good.price / 2).to_i)
          end
          show_message(str)
          result = show_yes_no_window
          case result
          when RESULT_YES
            if good.type == ITEM_PEOPLE
              show_message("谢谢！")
            else
              show_message("谢谢！还有事吗？")
            end
            $game_party.gain_gold((good.price / 2).to_i)
            @obj.lose_item(@sell_list_window.cursor_index)
            @sell_list_window.refresh_obj(@obj, @equipment_item_window.result)
            return
          when RESULT_NO
            if good.type == ITEM_PEOPLE
              show_message("真遗憾！别的怎么办？")
            else
              show_message("还有要卖的东西吗？")
            end
            return
          end
        end
      else
        if @obj.is_a?(Game_Tank)
          if @obj.c_unit.equal?(good) || @obj.engine.equal?(good)
            show_message("这个部件不能卖！")
            return
          end
          
          if @obj.underpan.equal?(good)
            show_message("呀……那不能卖！")
            return
          end
          
          if @obj.main_cannon.equal?(good)\
            || @obj.sub_cannon.equal?(good)\
            || @obj.se.equal?(good)
            show_message("呀……那不能卖！")
            return
          end
          
          if good.price == 0
            show_message("呀……那不能卖！")
            return
          end
          
          str = sprintf("是%s。严重受损。%sG。可以吗？", good.name, (good.price / 2).to_i)
          show_message(str)
          result = show_yes_no_window
          case result
          when RESULT_YES
            if good.type == ITEM_PEOPLE
              show_message("谢谢！")
            else
              show_message("谢谢！还有事吗？")
            end
            $game_party.gain_gold((good.price / 2).to_i)
            @obj.lose_equipments(@sell_list_window.cursor_index)
            @sell_list_window.refresh_obj(@obj, @equipment_item_window.result)
            return
          when RESULT_NO
            if good.type == ITEM_PEOPLE
              show_message("真遗憾！别的怎么办？")
            else
              show_message("还有要卖的东西吗？")
            end
            return
          end
          
        else
          
          if good.price == 0
            case $game_temp.shop_type
            when SHOPTYPE_PEOPLEEQUIPMENT
              show_message("这个。啊！这个卖不了！")
            when SHOPTYPE_PEOPLEITEM
              show_message("那个东西取不出来！")
            end
            return
          end
          str = sprintf("是%s。%sG卖吗？", good.name, (good.price / 2).to_i)
          show_message(str)
          result = show_yes_no_window
          case result
          when RESULT_YES
            if good.equal?(@obj.weapon)
              @obj.equip(0, good)
            elsif good.equal?(@obj.armor1)
              @obj.equip(1, good)
            elsif good.equal?(@obj.armor2)
              @obj.equip(2, good)
            elsif good.equal?(@obj.armor3)
              @obj.equip(3, good)
            elsif good.equal?(@obj.armor4)
              @obj.equip(4, good)
            elsif good.equal?(@obj.armor5)
              @obj.equip(5, good)
            end
            $game_party.gain_gold((good.price / 2).to_i)
            @obj.lose_equipments(@sell_list_window.cursor_index)
            @sell_list_window.refresh_obj(@obj, @equipment_item_window.result)

            case $game_temp.shop_type
            when SHOPTYPE_PEOPLEEQUIPMENT
              show_message("谢谢！还有事吗？")
            when SHOPTYPE_PEOPLEITEM
              show_message("谢谢。还有别的事吗？")
            end
            return
          when RESULT_NO
            show_message("真遗憾！别的怎么办？")
            return
          end
        end
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
    show_message("还有事吗？")
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
  
  def obj_select
    @obj_select_window.active = true
    @obj_select_window.visible = true
    loop do
      Graphics.update
      Input.update
      @obj_select_window.update
      if Input.trigger?(Input::C)
        break
      end
      if Input.trigger?(Input::B)
        if block_given?
          yield
        end
        return nil
      end
    end
    @obj_select_window.active = false
    case $game_temp.shop_type
    when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_PEOPLEITEM
      return $game_party.actors[@obj_select_window.cursor_index]
    when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
      return $game_party.tanks[@obj_select_window.cursor_index]
    end
    @obj_select_window.reset
  end
  
  def select_load_target
    loop do
      Graphics.update
      Input.update
      result = false
      case $game_temp.shop_type
      when SHOPTYPE_PEOPLEEQUIPMENT, SHOPTYPE_TANKEQUIPMENT
        result = @obj.equipments_package_full?
      when SHOPTYPE_PEOPLEITEM, SHOPTYPE_TANKITEM
        result = @obj.items_package_full?
      end
      #如果没装满
      if !result
        return true
      end
      case $game_temp.shop_type
      when SHOPTYPE_PEOPLEEQUIPMENT
        str = sprintf("%s拿的东西满了！", @obj.name)
      when SHOPTYPE_PEOPLEITEM
        str = sprintf("%s拿的东西满满的！别人能拿吗？", @obj.name)
      when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
        str = sprintf("唉呀！%s不能再装了！别的车能装吗？", @obj.name)
      end
      show_message(str)
      result = show_yes_no_window
      case result
      when RESULT_YES
        case $game_temp.shop_type
        when SHOPTYPE_PEOPLEEQUIPMENT
          str = sprintf("钱正好。谁拿？")
        when SHOPTYPE_PEOPLEITEM
          str = sprintf("谁拿呢？")
        when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
          str = sprintf("装在哪个车上？")
        end
        @obj = obj_select do
          @main_command_window.visible = true
          @main_command_window.active = true
          @buy_list_window.active = false
          @buy_list_window.visible = false
          @buy_list_window.reset
        end
        return if @obj == nil
        next
      when RESULT_NO
        show_continue_ask() do
          @main_command_window.visible = true
          @main_command_window.active = true
          @buy_list_window.active = false
          @buy_list_window.visible = false
          @info_window.visible = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
          @info_window.active = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
          @buy_list_window.reset
        end
        return false
      end
      
    end
  end
  
  def select_load_target_another
    loop do
      Graphics.update
      Input.update
      good = @buy_list_window.good
      #如果不能用（仅限于战车和人类武器）
      result = false
      case $game_temp.shop_type
      when SHOPTYPE_PEOPLEEQUIPMENT
        result = @obj.equippable?(good)
      when SHOPTYPE_TANKEQUIPMENT
        case good
        when RPG::MainCannon
          result = @obj.equippable?(good, HOLE_MAIN_CANNON)
        when RPG::SubCannon
          result = @obj.equippable?(good, HOLE_SUB_CANNON)
        when RPG::SE
          result = @obj.equippable?(good, HOLE_SE)
        end
      end
      
      if result
        return true
      else
        case $game_temp.shop_type
        when SHOPTYPE_PEOPLEEQUIPMENT
          str = sprintf("%s不能用这个。还要吗？", @obj.name)
        when SHOPTYPE_TANKEQUIPMENT
          str = sprintf("%s。装备武器的口好像是敞开着。如果不改造底盘。不能使用。要改造吗？",\
          @obj.name)
        end
        show_message(str)
        result = show_yes_no_window
        case result
        when RESULT_YES
          #case $game_temp.shop_type
          #when SHOPTYPE_PEOPLEEQUIPMENT
          #  show_message("钱正好。谁拿？")
          #when SHOPTYPE_PEOPLEITEM
          #  show_message("谁拿呢？")
          #when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
          #  show_message("装在哪个车上？")
          #end
          #@obj = obj_select
          #next
          return true
        when RESULT_NO
          case $game_temp.shop_type
          when SHOPTYPE_PEOPLEEQUIPMENT
            show_message("钱正好。谁拿？")
          when SHOPTYPE_PEOPLEITEM
            show_message("谁拿呢？")
          when SHOPTYPE_TANKEQUIPMENT, SHOPTYPE_TANKITEM
            show_message("装在哪个车上？")
          end
          @obj = obj_select do
            @main_command_window.visible = true
            @main_command_window.active = true
            @buy_list_window.active = false
            @buy_list_window.visible = false
            @buy_list_window.reset
          end
          if @obj == nil
            return
          end
          next
          #show_continue_ask() do
          #  @main_command_window.visible = true
          #  @main_command_window.active = true
          #  @buy_list_window.active = false
          #  @buy_list_window.visible = false
          #  @buy_list_window.reset
          #end
          #return false
        end
        
        if Input.trigger?(Input::B)
          show_continue_ask() do
            @main_command_window.visible = true
            @main_command_window.active = true
            @buy_list_window.active = false
            @buy_list_window.visible = false
            @info_window.visible = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
            @info_window.active = false if $game_temp.shop_type != SHOPTYPE_TANKITEM && $game_temp.shop_type != SHOPTYPE_PEOPLEITEM
            @buy_list_window.reset
          end
          return false
        end
        
      end
    end
  end
  
  def refresh_gold_draw
    @sprite_gold.bitmap.dispose
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
  end

end