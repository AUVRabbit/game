class Scene_WantedOffice
  
  include MM_System
  include MM_DataBase
  
  def main
    
    # 执行过渡
    Graphics.transition(0)
    
    @sprite_gold = Sprite.new
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.x = 75
    @sprite_gold.y = 140
    @sprite_gold.z = 8003
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_WANTED_BACK)
    @sprite_back.z = 8002
    
    @command_window = Window_WantedCommand.new
    @command_window.z = 8003
    
    @list_window = Window_WantedList.new($game_temp.wanted_list)
    @list_window.visible = false
    @list_window.z = 8003
    
    @message_window = Window_Message.new
    
    @spriteset_map = Spriteset_Map.new
    
    $game_temp.message_text = "欢迎光临。勇士办事处！"
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
    
    @sprite_gold.bitmap.dispose
    @sprite_gold.dispose
    
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    
    @spriteset_map.dispose
    
    @command_window.dispose
    @list_window.dispose
    @message_window.dispose
    @yes_no_window.dispose if @yes_no_window != nil
    
  end
  
  def update
    
    @spriteset_map.update
    @command_window.update
    @list_window.update
    
    if @command_window.visible
      update_select
      return
    end
    
    if @list_window.visible
      update_list
      return
    end
    
  end
  
  def update_select
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @message_window.terminate_message
      $game_temp.message_text = "请您再来！"
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
    end
    
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      case @command_window.result
      when WANTEDCOMMAND_LISTEN
        @command_window.visible = false
        @list_window.visible = true
        @list_window.index = 0
        return
      when WANTEDCOMMAND_AWARD
        @command_window.visible = false
        @list_window.visible = true
        @list_window.index = 0
        return
      when WANTEDCOMMAND_EXIT
        @message_window.terminate_message
        $game_temp.message_text = "请您再来！"
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
        
        $scene =Scene_Map.new
        return
      end
    end
  end
  
  def update_list
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @command_window.reset
      @list_window.visible = false
      @command_window.visible = true
      return
    end
    
    if Input.trigger?(Input::C)
      
      wanted_id = @list_window.wanted_id
      
      case @command_window.result
      when WANTEDCOMMAND_LISTEN
        
        if $game_map.wanted_person_striked?(wanted_id)
          @message_window.terminate_message
          $game_temp.message_text = "继续捉拿#{$data_enemies[wanted_id].name}是了不起的大大事！为了人类的安宁仍需努力。"
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
        else
          wanted_msg = DATA_ENEMY_BOSS_INFO[wanted_id]
          @message_window.terminate_message
          $game_temp.message_text = wanted_msg
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
          
        end
        
      when WANTEDCOMMAND_AWARD
        
        wanted_id_keys = $game_map.wanted_persons.keys.sort
        first = false
        for wanted_id in wanted_id_keys
          if $game_map.wanted_person_striked?(wanted_id) && !$game_map.wanted_person_awarded?(wanted_id)
            
            @message_window.terminate_message
            if !first
              $game_temp.message_text =\
                "成功了#{$game_party.actors[0].name}！"
              first = true
            else
              $game_temp.message_text =\
                "哎？说什么？你把#{$data_enemies[wanted_id].name}干掉了？"
            end
            
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
            $game_temp.message_text =\
              "消灭#{$data_enemies[wanted_id].name}的赏金是#{$game_map.wanted_persons[wanted_id][0].to_s}，您领走吗？"
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
              $game_party.gain_gold($game_map.wanted_persons[wanted_id][0])
              $game_map.wanted_person_award(wanted_id)
              
              refresh_gold_draw
              
              @message_window.terminate_message
              
              $game_temp.message_text =\
                "这样一来世上就可以太平了，您的事迹也会在镇子里传开！"
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
              
            when RESULT_NO
              @message_window.terminate_message
              
              $game_temp.message_text =\
                "那么先存在这里。这么多钱请尽快取走！"
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
            $scene = Scene_Map.new
            return
          end
        end
        
        if !first
          @message_window.terminate_message
          $game_temp.message_text = "就连最好的勇士这次也大伤脑筋，不要着急，慢慢来吧。"
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
        $scene = Scene_Map.new
        return
      end
      
    end
    
  end
  
  def refresh_gold_draw
    @sprite_gold.bitmap.dispose
    @sprite_gold.bitmap = Bitmap.new(120, 48)
    @sprite_gold.bitmap.draw_text(0, 0, 120, 48, $game_party.gold.to_s)
  end
end