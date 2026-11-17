class Scene_Battle
    
  def update_end    
    # 判定胜败
    if !judge
      # 胜利或者失败的情况下 : 过程结束
      @status_window.visible = true
      $game_temp.clear_message_battle = true
      @message_window.terminate_message
      @message_window.visible = false
      @dialog_window.visible = false
      @target_index = 0
      @battle_proccess = 0
      @battle_step = BATTLESTEP_COMMAND
      return
    end
    
    if @actors_escape
      # 清除全体同伴的行动
      $game_party.clear_actions
      # 解除战斗用状态
      for actor in $game_party.actors
        actor.remove_states_battle
        actor.hit_ex = false
      end
      for tank in $game_party.tanks
        tank.remove_states_battle
      end
      # 清除敌人
      $game_troop.enemies.clear
      # 调用战斗返回
      if $game_temp.battle_proc != nil
        $game_temp.battle_proc.call(2)
        $game_temp.battle_proc = nil
      end
      
      @message_window.terminate_message
      # 清除战斗中标志
      $game_temp.in_battle = false
      $game_party.members = $game_temp.members_in_battle
      $game_temp.members_in_battle = []
      $game_system.bgm_play($game_temp.map_bgm)
      $game_temp.messaeg_type = MESSAGE_TALK
      $scene = Scene_Map.new
      return
    end
    
    if $game_party.all_dead?
      # 清除战斗中标志
      # 清除全体同伴的行动
      $game_party.clear_actions
      # 解除战斗用状态
      for actor in $game_party.actors
        actor.remove_states_battle
        actor.hit_ex = false
      end
      for tank in $game_party.tanks
        tank.remove_states_battle
      end

      # 清除敌人
      $game_troop.enemies.clear
      # 调用战斗返回
      if $game_temp.battle_proc != nil
        $game_temp.battle_proc.call(1)
        $game_temp.battle_proc = nil
      end
      $game_party.members = $game_temp.members_in_battle
      $game_temp.members_in_battle = []
      Audio.me_play(ME_ALL_DEAD, 100, 100)
      $game_temp.in_battle = false
      #$game_system.bgm_play($game_temp.map_bgm)
      $game_temp.messaeg_type = MESSAGE_TALK
      $scene = Scene_Map.new
      return
      
    else
      # 清除战斗中标志
      # 清除全体同伴的行动
      $game_party.clear_actions
      # 解除战斗用状态
      for actor in $game_party.actors
        actor.remove_states_battle
        actor.hit_ex = false
      end
      for tank in $game_party.tanks
        tank.remove_states_battle
      end

      # 清除敌人
      $game_troop.enemies.clear
      # 调用战斗返回
      if $game_temp.battle_proc != nil
        $game_temp.battle_proc.call(0)
        $game_temp.battle_proc = nil
      end
      @message_window.terminate_message
      $game_party.members = $game_temp.members_in_battle
      $game_temp.members_in_battle = []
      # 演奏战斗结束 ME
      $game_system.me_play($game_system.battle_end_me)
      # 还原为战斗开始前的 BGM
      # 初始化 EXP、金钱、宝物
      exp = 0
      gold = 0
      treasures = []
      # 循环
      #troop = $data_troops[$game_temp.battle_troop_id]
      for enemy in @dead_enemies #$game_troop.enemies
        # 敌人不是隐藏状态的情况下
        unless enemy.hidden
          # 获得 EXP、增加金钱
          exp += enemy.exp
          gold += enemy.gold
          # 出现宝物判定
          if rand(100) < enemy.treasure_prob
            if enemy.item_id > 0
              treasures.push($data_items[enemy.item_id])
            end
            if enemy.weapon_id > 0
              treasures.push($data_weapons[enemy.weapon_id])
            end
            if enemy.armor_id > 0
              treasures.push($data_armors[enemy.armor_id])
            end
          end
        end
      end
      
      have_wanted = false
      for i in 0...@dead_enemies.size
        if DATA_ENEMY_BOSS.keys.include?(@dead_enemies[i].id)
          $game_map.wanted_person_strike(@dead_enemies[i].id, $game_party.actors[0].level)
          have_wanted = true
          break
        end
      end
      if have_wanted
        Audio.me_play(ME_WANTED_BROKE, 100, 100)
      else
        Audio.me_play(ME_BATTLE_FINISH, 100, 100)
      end
      
      str = ""
      str += "打倒了敌人，获得了 " + gold.to_s + "G | "
      str += "获得了经验值 " + exp.to_s + "！|"
      
      $game_temp.message_text = str
      loop do
        Graphics.update
        Input.update
        @message_window.update
        if @message_window.at_end
          break
        end
      end
      
      # 限制宝物数为 6 个
      treasures = treasures[0..5]
      # 获得 EXP
      for i in 0...$game_party.actors.size
        str = ""
        actor = $game_party.actors[i]
        if actor.cant_get_exp? == false
          for i in 1..exp
            last_level = actor.level
            last_str = actor.str
            last_dex = actor.dex
            last_agi = actor.agi
            last_int = actor.int
            last_battle_level = actor.battle_level
            last_driver_level = actor.driver_level
            last_fix_level = actor.fix_level
            last_hp = actor.hp
            actor.exp += 1
            if actor.level > last_level
              str += "| " + actor.name + " 升级了！"
              str += "强度提高" + (actor.str - last_str).to_s + " ！| "
              str += "智力提高" + (actor.dex - last_dex).to_s + " ！| "
              str += "速度提高" + (actor.agi - last_agi).to_s + " ！| "
              str += "体力提高" + (actor.int - last_int).to_s + " ！| "
              str += "战斗LV提高" + (actor.battle_level - last_battle_level).to_s + " ！| "
              str += "驾驶LV提高" + (actor.driver_level - last_driver_level).to_s + " ！| "
              str += "修理LV提高" + (actor.fix_level - last_fix_level).to_s + " ！| "
              str += "HP提高" + (actor.hp - last_hp).to_s + " ！"
              
              Audio.me_play(ME_LEVEL_UP, 100, 100)
              
              $game_temp.message_text = str
              loop do
                Graphics.update
                Input.update
                @message_window.update
                if @message_window.at_end
                  break
                end
              end
              str = ""
              
            end
          end
          
        end
      end
      
      str = ""
      
      # 获得金钱
      $game_party.gain_gold(gold)
      # 获得宝物
      for item in treasures
        str += "| " + item.name + "入手了！"
        case item
        when RPG::Item
          #$game_party.gain_item(item.id, 1)
          if item.type == ITEM_PEOPLE
            for i in 0...$game_party.actors.size
              actor = $game_party.actors[i]
              if actor.items.size < 8
                break
              end
            end
            if actor.items.size < 8
              actor.gain_item(item.clone)
              next
            else
              str += "| 但是都拿不下了，只得丢掉。"
              next
            end
          else
            for i in 0...$game_party.tanks.size
              tank = $game_party.tanks[i]
              if tank.items.size < 8
                break
              end
            end
            if tank.items.size < 8
              tank.gain_item(item.clone)
              next
            else
              str += "| 但是都拿不下了，只得丢掉。"
              next
            end
          end
        when RPG::Weapon
          #$game_party.gain_weapon(item.id, 1)
          for i in 0...$game_party.actors.size
            actor = $game_party.actors[i]
            if actor.items.size < 8
              break
            end
          end
          if actor.items.size < 8
            actor.gain_equipments(item.clone)
            next
          else
            str += "| 但是都拿不下了，只得丢掉。"
            next
          end
        when RPG::Armor
          #$game_party.gain_armor(item.id, 1)
          for i in 0...$game_party.actors.size
            actor = $game_party.actors[i]
            if actor.equipments.size < 8
              break
            end
          end
          if actor.items.size < 8
            actor.gain_equipments(item.clone)
            next
          else
            str += "| 但是都拿不下了，只得丢掉。"
            next
          end
        when Game_Main_Cannon, Game_Sub_Cannon, Game_SE, Game_Engine, Game_C_Unit
          for i in 0...$game_party.tanks.size
            tank = $game_party.tanks[i]
            if tank.equipments.size < 8
              break
            end
          end
          if tank.equipments.size < 8
            tank.gain_equipments(item.clone)
            next
          else
            str += "| 但是都拿不下了，只得丢掉。"
            next
          end
        end
        
        Audio.me_play(ME_FIND_OUT, 100, 100)
              
        $game_temp.message_text = str
        loop do
          Graphics.update
          Input.update
          @message_window.update
          if @message_window.at_end
            break
          end
        end
        str = ""
        
      end
    end
    
    $game_temp.message_text = str
    
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
    
    while FmodSoundSystem.me_is_playing == 1
      Graphics.update
    end
    
    $game_temp.in_battle = false
    
    # 还原为战斗开始前的 BGM
    $game_system.bgm_play($game_temp.map_bgm)
    $game_temp.messaeg_type = MESSAGE_TALK
    $scene = Scene_Map.new
    return
  end
end