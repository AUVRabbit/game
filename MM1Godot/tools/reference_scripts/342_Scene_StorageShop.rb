class Scene_StorageShop
  
  include MM_DataBase
  include MM_System
  
  def main
    $game_party.set_cpl_party
    
    @spriteset_map = Spriteset_Map.new
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_STORAGESHOP_BACK)
    @sprite_back.z = 8001
    
    @sprite_get_back = Sprite.new
    @sprite_get_back.bitmap = RPG::Cache.picture(PICTURE_STORAGESHOP_GETBACK)
    @sprite_get_back.z = 8002
    @sprite_get_back.visible = false
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8001
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @main_command_window = Window_StorageShopCommand.new
    @main_command_window.visible = true
    @main_command_window.active = true
    @main_command_window.z = 8002
    
    @store_type_window = Window_StorageShopStoreType.new
    @store_type_window.visible = false
    @store_type_window.active = false
    @store_type_window.z = 8002
    
    @get_window = Window_StorageShopGet.new
    @get_window.visible = false
    @get_window.active = false
    @get_window.z = 8002
    
    @equipment_item_window = Window_StorageShopEquipmentAndItem.new
    @equipment_item_window.active = false
    @equipment_item_window.visible = false
    @equipment_item_window.z = 8002
    
    @store_list_window = Window_StorageShopItemsList.new
    @store_list_window.active = false
    @store_list_window.visible = false
    @store_list_window.z = 8002
    
    @people_select_window = Window_StorageShopPeopleSelect.new
    @people_select_window.active = false
    @people_select_window.visible = false
    @people_select_window.z = 8003
    
    @tank_select_window = Window_StorageShopTankSelect.new
    @tank_select_window.active = false
    @tank_select_window.visible = false
    @tank_select_window.z = 8003
    
    @obj_select = 0
    
    # 执行过渡
    Graphics.transition
    @message_window = Window_Message.new
    show_message("这里是勇士财产保管处！", true)
    show_message($game_party.actors[0].name + "。有什么事？")
    # 主循环
    loop do
      Graphics.update
      Input.update
      update
      if $scene != self
        break
      end
    end
    Graphics.freeze
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @sprite_gold.bitmap.dispose
    @sprite_gold.dispose
    
    @spriteset_map.dispose
    
    @main_command_window.dispose
    @store_type_window.dispose
    @get_window.dispose
    @equipment_item_window.dispose
    @store_list_window.dispose
    @people_select_window.dispose
    @tank_select_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
    
    @message_window.dispose
    
    $game_party.recover_org_party
  end
  
  def update
    @main_command_window.update
    @store_type_window.update
    @get_window.update
    @equipment_item_window.update
    @store_list_window.update
    @spriteset_map.update
    
    if @main_command_window.visible && @main_command_window.active
      update_command_window
      return
    end
    
    if @store_type_window.visible && @store_type_window.active
      update_store_type
      return
    end
    
    if @get_window.visible && @get_window.active
      update_get
      return
    end
    
    if @equipment_item_window.visible && @equipment_item_window.active
      update_equipment_item
      return
    end
    
    if @store_list_window.visible && @store_list_window.active
      update_store_list
      return
    end
  end
  
  def update_command_window
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      show_message("随时都能取，再见！", true)
      $scene = Scene_Map.new
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @main_command_window.result
      when STORAGESHOPCOMMAND_STORE
        @main_command_window.active = false
        @main_command_window.visible = false
        @main_command_window.reset
        @store_type_window.visible = true
        @store_type_window.active = true
        return
      when STORAGESHOPCOMMAND_GET
        @main_command_window.active = false
        @main_command_window.visible = false
        @main_command_window.reset
        @get_window.active = true
        @get_window.visible = true
        @get_window.refresh
        @sprite_get_back.visible = true
        return
      when STORAGESHOPCOMMAND_EXIT
        show_message("随时都能取，再见！", true)
        $scene = Scene_Map.new
      end
      return
    end
  end
  
  def update_store_type
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @main_command_window.active = true
      @main_command_window.visible = true
      @store_type_window.visible = false
      @store_type_window.active = false
      @store_type_window.reset
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.cancel_se)
      case @store_type_window.result
      when STORAGESHOPSTORETYPE_TANK
        if $game_party.tanks == []
          show_message("没有见到车……")
          @main_command_window.active = true
          @main_command_window.visible = true
          @store_type_window.visible = false
          @store_type_window.active = false
          @store_type_window.reset
          return
        end
        if @obj_select_window != nil
          @obj_select_window.active = false
          @obj_select_window.visible = false
        end
        show_message("是哪辆车？")
        @obj_select_window = @tank_select_window
        @obj_select = 1
        @obj = obj_select do
          @main_command_window.active = true
          @main_command_window.visible = true
          @store_type_window.visible = false
          @store_type_window.active = false
          @store_type_window.reset
        end
        return if @obj == nil
        @store_type_window.visible = false
        @store_type_window.active = false
        @store_type_window.reset
        @equipment_item_window.visible = true
        @equipment_item_window.active = true
        @store_list_window.refresh_obj(@obj, STORAGEITEMTYPE_EQUIPMENT)
        @store_list_window.visible = true
        @store_list_window.active = true
      when STORAGESHOPSTORETYPE_PEOPLE
        if @obj_select_window != nil
          @obj_select_window.active = false
          @obj_select_window.visible = false
        end
        show_message("是哪位的？")
        @obj_select_window = @people_select_window
        @obj_select = 0
        @obj = obj_select do
          @main_command_window.active = true
          @main_command_window.visible = true
          @store_type_window.visible = false
          @store_type_window.active = false
          @store_type_window.reset
        end
        return if @obj == nil
        @store_type_window.visible = false
        @store_type_window.active = false
        @store_type_window.reset
        @equipment_item_window.visible = true
        @equipment_item_window.active = true
        @store_list_window.refresh_obj(@obj, STORAGEITEMTYPE_EQUIPMENT)
        @store_list_window.visible = true
        @store_list_window.active = true
      when STORAGESHOPSTORETYPE_EXIT
        @main_command_window.active = true
        @main_command_window.visible = true
        @store_type_window.visible = false
        @store_type_window.active = false
        @store_type_window.reset
        @store_list_window.active = false
        @store_list_window.visible = false
        show_message("要取什么？")
      end
      return
    end
  end
    
  def update_equipment_item
    if Input.trigger?(Input::B)
      @equipment_item_window.active = false
      $game_system.se_play($data_system.cancel_se)
      case @store_type_window.result
      when STORAGESHOPSTORETYPE_PEOPLE
        show_message("是哪位的？")
      when STORAGESHOPSTORETYPE_TANK
        show_message("是哪辆车？")
      end
      @obj_select = 1
      @obj = obj_select do
        @equipment_item_window.visible = false
        @main_command_window.visible = true
        @main_command_window.active = true
        @store_list_window.active = false
        @store_list_window.visible = false
      end
      if @obj == nil
        @equipment_item_window.reset
        return
      else
        @equipment_item_window.active = true
        return
      end
    end
    
    if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
      @store_list_window.refresh_obj(@obj, @equipment_item_window.result)
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @equipment_item_window.active = false
      @equipment_item_window.reset
      @store_list_window.active = true
      show_message("要存在哪里？存哪个？")
      return
    end
  end
  
  def update_store_list
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @equipment_item_window.active = true
      @store_list_window.active = false
      show_message("存吗？")
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @item = @store_list_window.item
      return if @item == nil
      str = sprintf("存%s吗？", @item.name)
      show_message(str)
      result = show_yes_no_window
      case result
      when RESULT_YES
        if @item.is_a?(Game_Underpan)
          show_message("这个不能存！", true)
          @equipment_item_window.active = false
          @equipment_item_window.visible = false
          @equipment_item_window.reset
          @store_list_window.active = false
          @store_list_window.visible = false
          @main_command_window.visible = true
          @main_command_window.active = true
          return
        end
        case @item
        when RPG::Item
          $game_party.trunk_add_item(@item)
          @obj.lose_item(@store_list_window.cursor_index)
        when RPG::Weapon
          if @obj.weapon.equal?(@item)
            @obj.equip(0, @item)
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        when RPG::Armor
          have_equal = false
          kind = @item.kind + 1
          case @item.kind
          when ARMOR_HEAD
            have_equal = true if @obj.armor1.equal?(@item)
          when ARMOR_HAND
            have_equal = true if @obj.armor3.equal?(@item)
          when ARMOR_FOOT
            have_equal = true if @obj.armor4.equal?(@item)
          when ARMOR_LEATHER
            have_equal = true if @obj.armor5.equal?(@item)
          when ARMOR_BODY
            have_equal = true if @obj.armor2.equal?(@item)
          end
          if have_equal == true
            @obj.equip(kind, @item)
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        when Game_MainCannon
          if @obj.main_cannon.equal?(@item)
            @obj.equip(0, @item)
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        when Game_SubCannon
          if @obj.sub_cannon.equal?(@item)
            @obj.equip(1, @item)
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)            
        when Game_SE
          if @obj.se.equal?(@item)
            @obj.equip(2, @item)
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        when Game_C_Unit
          if @obj.c_unit.equal?(@item)
            show_message("取下那个就不能动了。可以吗？")
            result = show_yes_no_window
            case result
            when RESULT_YES
              @obj.equip(3, @item)
            when RESULT_NO
              show_message("还有别的事吗？", true)
              @equipment_item_window.active = false
              @equipment_item_window.visible = false
              @equipment_item_window.reset
              @store_list_window.active = false
              @store_list_window.visible = false
              @main_command_window.visible = true
              @main_command_window.active = true
              return
            end
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        when Game_Engine
          if @obj.engine.equal?(@item)
            show_message("取下那个就不能动了。可以吗？")
            result = show_yes_no_window
            case result
            when RESULT_YES
              @obj.equip(4, @item)
            when RESULT_NO
              show_message("还有别的事吗？", true)
              @equipment_item_window.active = false
              @equipment_item_window.visible = false
              @equipment_item_window.reset
              @store_list_window.active = false
              @store_list_window.visible = false
              @main_command_window.visible = true
              @main_command_window.active = true
              return
            end
          end
          $game_party.trunk_add_item(@item)
          @obj.lose_equipments(@store_list_window.cursor_index)
        end
        show_message("已经存好了。还有别的事吗？", true)
        @equipment_item_window.active = false
        @equipment_item_window.visible = false
        @equipment_item_window.reset
        @store_list_window.active = false
        @store_list_window.visible = false
        @main_command_window.visible = true
        @main_command_window.active = true
        return
      when RESULT_NO
        show_message("随时都能取，再见！", true)
        $scene = Scene_Map.new
        return
      end
    end
  end
  
  def update_get
    if Input.trigger?(Input::B)
      str = sprintf("%s有什么事", $game_party.actors[0].name)
      show_message(str)
      @main_command_window.active = true
      @main_command_window.visible = true
      @main_command_window.reset
      @get_window.active = false
      @get_window.visible = false
      @sprite_get_back.visible = false
      return
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      return if $game_party.trunk == []
      @item = @get_window.item
      if $game_party.tanks == [] &&\
        (@item.is_a?(Game_MainCannon) ||\
        @item.is_a?(Game_SubCannon) ||\
        @item.is_a?(Game_SE) ||\
        @item.is_a?(Game_Engine) ||\
        @item.is_a?(Game_C_Unit))
        show_message("没有见到车……")
        return
      end
      
      str = sprintf("是%s吗？", @item.name)
      show_message(str)
      result = show_yes_no_window
      case result
      when RESULT_YES
        
        loop do
          case @item
          when RPG::Item
            case @item.type
            when ITEM_TANK
              @obj_select_window = @tank_select_window
              show_message("装在哪辆车上？")
              @obj_select = 1
              @obj = obj_select
              if @obj == nil
                show_message("要取什么？")
                return
              else
                if @obj.items_package_full?
                  str = sprintf("%s已经装不下了。装在别车上吗？", @obj.name)
                  show_message(str)
                  result = show_yes_no_window
                  case result
                  when RESULT_YES
                    next
                  when RESULT_NO
                    show_message("要取什么？")
                    return
                  end
                else
                  str = sprintf("OK！%s装上%s！", @obj.name, @item.name)
                  show_message(str)
                  @obj.gain_item(@item)
                  $game_party.trunk_remove_item(@get_window.index)
                  @get_window.refresh
                  return
                end
              end
            when ITEM_PEOPLE
              show_message("谁拿呢？")
              @obj_select_window = @people_select_window
              @obj_select = 0
              @obj = obj_select
              if @obj == nil
                show_message("要取什么？")
                return
              else
                if @obj.items_package_full?
                  str = sprintf("%s已经不能拿了。别人能拿吗？", @obj.name)
                  show_message(str)
                  result = show_yes_no_window
                  case result
                  when RESULT_YES
                    next
                  when RESULT_NO
                    show_message("要取什么？")
                    return
                  end
                else
                  str = sprintf("OK！%s请收下%s！", @obj.name, @item.name)
                  show_message(str)
                  @obj.gain_item(@item)
                  $game_party.trunk_remove_item(@get_window.index)
                  @get_window.refresh
                  return
                end
              end
            end
          when RPG::Weapon, RPG::Armor
            show_message("谁拿呢？")
            @obj_select_window = @people_select_window
            @obj_select = 0
            @obj = obj_select
            if @obj == nil
              show_message("要取什么？")
              return
            else
              if @obj.equipments_package_full?
                str = sprintf("%s已经不能拿了。别人能拿吗？", @obj.name)
                show_message(str)
                result = show_yes_no_window
                case result
                when RESULT_YES
                  next
                when RESULT_NO
                  show_message("要取什么？")
                  return
                end
              else
                str = sprintf("OK！%s请收下%s！", @obj.name, @item.name)
                show_message(str)
                @obj.gain_equipments(@item)
                $game_party.trunk_remove_item(@get_window.index)
                @get_window.refresh
                return
              end
            end
          when Game_MainCannon, Game_SubCannon, Game_SE, Game_C_Unit, Game_Engine
            show_message("装在哪辆车上？")
            @obj_select_window = @tank_select_window
            @obj_select = 1
            @obj = obj_select
            if @obj == nil
              show_message("要取什么？")
              return
            else
              if @obj.equipments_package_full?
                str = sprintf("%s已经装不下了。装在别车上吗？", @obj.name)
                show_message(str)
                result = show_yes_no_window
                case result
                when RESULT_YES
                  next
                when RESULT_NO
                  show_message("要取什么？")
                  return
                end
              else
                str = sprintf("OK！%s装上%s！", @obj.name, @item.name)
                show_message(str)
                @obj.gain_equipments(@item)
                $game_party.trunk_remove_item(@get_window.index)
                @get_window.refresh
                return
              end
            end
          end
        end
        
        return
      when RESULT_NO
        show_message("要取什么？")
        return
      end
      return
    end
  end
  
  #辅助函数
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
    case @obj_select
    when 0
      return $game_party.actors[@obj_select_window.cursor_index]
    when 1
      return $game_party.tanks[@obj_select_window.cursor_index]
    end
    @obj_select_window.reset
  end
end