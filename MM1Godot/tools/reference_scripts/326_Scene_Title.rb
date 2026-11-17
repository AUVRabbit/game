#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　处理标题画面的类。
#==============================================================================

class Scene_Title
  
  include MM_DataBase
  
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    # 战斗测试的情况下
    if $BTEST
      battle_test
      return
    end
    # 载入数据库
    $data_actors        = load_data("Data/Actors.rxdata")
    $data_classes       = load_data("Data/Classes.rxdata")
    $data_skills        = load_data("Data/Skills.rxdata")
    #$data_items         = load_data("Data/Items.rxdata")
    #$data_weapons       = load_data("Data/Weapons.rxdata")
    #$data_armors        = load_data("Data/Armors.rxdata")
    $data_enemies       = load_data("Data/Enemies.rxdata")
    $data_troops        = load_data("Data/Troops.rxdata")
    $data_states        = load_data("Data/States.rxdata")
    $data_animations    = load_data("Data/Animations.rxdata")
    $data_tilesets      = load_data("Data/Tilesets.rxdata")
    $data_common_events = load_data("Data/CommonEvents.rxdata")
    $data_system        = load_data("Data/System.rxdata")
    #actor.battle_level = 0
    #actor.fix_level = 0
    #actor.driver_level = 0
    #actor.armor5_id = 0
    #actor.armor5_fix = false
    for i in 0...$data_actors.size
      if DATA_ACTOR_START_EQUIPMENTS[i] != nil && $data_actors[i] != nil
        $data_actors[i].weapon_id = DATA_ACTOR_START_EQUIPMENTS[i][0]
        $data_actors[i].armor1_id = DATA_ACTOR_START_EQUIPMENTS[i][1]
        $data_actors[i].armor2_id = DATA_ACTOR_START_EQUIPMENTS[i][2]
        $data_actors[i].armor3_id = DATA_ACTOR_START_EQUIPMENTS[i][3]
        $data_actors[i].armor4_id = DATA_ACTOR_START_EQUIPMENTS[i][4]
        $data_actors[i].armor5_id = DATA_ACTOR_START_EQUIPMENTS[i][5]
      end
    end
    for i in 0...$data_enemies.size
      if VOCAB_BATTLE_ENEMY[i] != nil && $data_enemies[i] != nil
        $data_enemies[i].battle_message = VOCAB_BATTLE_ENEMY[i]
        if DATA_ENEMY_ANIMATION[i] != nil
          $data_enemies[i].animation1_id = DATA_ENEMY_ANIMATION[i][0]
          $data_enemies[i].animation2_id = DATA_ENEMY_ANIMATION[i][1]
          $data_enemies[i].animation3_id = DATA_ENEMY_ANIMATION[i][2]
        else
          $data_enemies[i].animation3_id = 0
        end
      end
    end
    for i in 0...$data_skills.size
      if VOCAB_BATTLE_SKILL[i] != nil && $data_skills[i] != nil
        $data_skills[i].battle_message = VOCAB_BATTLE_SKILL[i]
      end
    end
    
    for i in 0...$data_states.size
      if VOCAB_STATUS[i] != nil && $data_states[i] != nil
        $data_states[i].battle_message_effect = VOCAB_STATUS[i][0]
        $data_states[i].battle_message_disappear = VOCAB_STATUS[i][1]
        $data_states[i].battle_message_diaappear_short = VOCAB_STATUS[i][2]
      end
    end
            
=begin    
    $data_items.each do |item|
      if item != nil
        item.type = 0
        item.price = 0
        item.can_drop_sell = true
      end
    end
=end
    #新數據庫
    $data_tanks              = make_tanks
    $data_main_cannons       = make_main_cannons
    $data_sub_cannons        = make_sub_cannons
    $data_ses                = make_ses
    $data_engines            = make_engines
    $data_c_units            = make_c_units
    $data_underpans          = make_underpans
    $data_specialcannonballs = make_specialcannonballs
    $data_actor_items = make_actor_items
    $data_tank_items = make_tank_items
    $data_weapons = make_actor_weapons
    $data_armors = make_actor_armors
    
    for i in 0...$data_specialcannonballs.size
      if VOCAB_BATTLE_CANNONBALL[i] != nil && $data_states[i] != nil
        $data_specialcannonballs[i].battle_message = VOCAB_BATTLE_CANNONBALL
      end
    end
    
    for i in 0...$data_main_cannons.size
      if  DATA_MAIN_CANNON_TIME[i] != nil && $data_main_cannons[i] != nil
        $data_main_cannons[i].transform_time = DATA_MAIN_CANNON_TIME[i]
      end
      if DATA_MAIN_CANNON_PRICE[i] != nil && $data_main_cannons[i] != nil
        $data_main_cannons[i].transform_price = DATA_MAIN_CANNON_PRICE[i]
      end
    end
    
    for i in 0...$data_sub_cannons.size
      if  DATA_MAIN_CANNON_TIME[i] != nil && $data_sub_cannons[i] != nil
        $data_sub_cannons[i].transform_time = DATA_SUB_CANNON_TIME[i]
      end
      if DATA_SUB_CANNON_CANNONBALL_PRICE[i] != nil && $data_sub_cannons[i] != nil
        $data_sub_cannons[i].cannonball_price = DATA_SUB_CANNON_CANNONBALL_PRICE[i]
      end
      if DATA_SUB_CANNON_PRICE[i] != nil && $data_sub_cannons[i] != nil
        $data_sub_cannons[i].transform_price = DATA_SUB_CANNON_PRICE[i]
      end
    end
    
    for i in 0...$data_ses.size
      if  DATA_SE_TIME[i] != nil && $data_ses[i] != nil
        $data_ses[i].transform_time = DATA_SE_TIME[i]
      end
      if DATA_SE_CANNONBALL_PRICE[i] != nil && $data_ses[i] != nil
        $data_ses[i].cannonball_price = DATA_SE_CANNONBALL_PRICE[i]
      end
      if DATA_SE_PRICE[i] != nil && $data_ses[i] != nil
        $data_ses[i].transform_price = DATA_SE_PRICE[i]
      end
    end
    
    for i in 0...$data_c_units.size
      if  DATA_MAIN_CANNON_TIME[i] != nil && $data_c_units[i] != nil
        $data_c_units[i].transform_time = DATA_C_UNIT_TIME[i]
      end
      if DATA_C_UNIT_PRICE[i] != nil && $data_c_units[i] != nil
        $data_c_units[i].transform_price = DATA_MAIN_CANNON_PRICE[i]
      end
    end
    
    for i in 0...$data_engines.size
      if DATA_ENGINETRANSFORM[i] != nil && $data_engines[i] != nil
        $data_engines[i].transform_information = DATA_ENGINETRANSFORM[i]
      end
    end
    
    # 生成系统对像
    $game_system = Game_System.new
    
    unless $DEBUG
    
    Graphics.transition(20)
    
    @sprite_piripiri_logo = Sprite.new
    @sprite_piripiri_logo.bitmap = RPG::Cache.picture(PICTURE_GAME_PIRIPIRILOGO)
    @sprite_piripiri_logo.opacity = 0
    
    for i in 0...30
      Graphics.update
      Input.update
      @sprite_piripiri_logo.opacity += (255 / 30)
    end
    
    for i in 0...30
      Graphics.update
      Input.update
    end
    
    Audio.se_play("Audio/SE/" + SE_PIRIPIRI, 100, 100)
    
    for i in 0...120
      Graphics.update
      Input.update
    end
    
    for i in 0...30
      Graphics.update
      Input.update
      @sprite_piripiri_logo.opacity -= (255 / 30)
    end
    
    for i in 0...30
      Graphics.update
      Input.update
    end
    
    # 演奏标题 BGM
    $game_system.bgm_play($data_system.title_bgm)
    # 停止演奏 ME、BGS
    Audio.me_stop
    Audio.bgs_stop
    
    skip = false
    
    @sprite_back = Sprite.new
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_GAME_HEADER_CT)
    @sprite_back.opacity = 0

    #淡入
    if !skip
      for i in 0...30
        Input.update
        Graphics.update
        @sprite_back.opacity += (255 / 30)
        if Input.trigger?(Input::C)
          40.times {Graphics.update}
          @sprite_back.opacity = 255
          skip = true
          break
        end
      end
    else
      @sprite_back.opacity = 255
    end
    
    #跳出
    if !skip
      for i in 0...80
        Input.update
        Graphics.update
        if Input.trigger?(Input::C)
          40.times {Graphics.update}
          skip = true
          break
        end
      end
    end
    
    #淡出
    if !skip
      for i in 0...30
        Input.update
        Graphics.update
        @sprite_back.opacity -= (255 / 30)
        if Input.trigger?(Input::C)
          @sprite_back.opacity = 255
          40.times {Graphics.update}
          skip = true
          break
        end
      end
    else
      @sprite_back.opacity = 255
    end
    
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_GAME_HEADER_BLACK_BACK)
    @sprite_title = Sprite.new
    @sprite_title.bitmap = RPG::Cache.picture(PICTURE_GAME_HEADER_TITLE)
    @sprite_title.opacity = 0
    @sprite_title.y = 300
    @sprite_title.x = 72
    
    #停頓
    if !skip
      for i in 0...60
        Input.update
        Graphics.update
        @sprite_title.opacity += (255 / 60)
        if Input.trigger?(Input::C)
          20.times {Graphics.update}
          @sprite_title.opacity = 255
          skip = true
          break
        end
      end
    else
      @sprite_title.opacity = 255
    end
    
    #移動
    if !skip
      for i in 0...180
        Input.update
        Graphics.update
        @sprite_title.y -= 1
        if Input.trigger?(Input::C)
          20.times {Graphics.update}
          @sprite_title.y -= 180
          skip = true
          break
        end
      end
    else
      @sprite_title.y -= 180
    end
    
    #停頓
    if !skip
      for i in 0...40
        Input.update
        Graphics.update
        if Input.trigger?(Input::C)
          20.times {Graphics.update}
          skip = true
          break
        end
      end
    end
    
    @sprite_back.bitmap = RPG::Cache.picture(PICTURE_GAME_HEADER_BACK)
    @sprite_back.opacity = 0
    
    #停頓
    if !skip
      for i in 0...40
        Input.update
        Graphics.update
        @sprite_back.opacity += (255 / 40)
        if Input.trigger?(Input::C)
          20.times {Graphics.update}
          @sprite_back.opacity = 255
          skip = true
          break
        end
      end
    else
      @sprite_back.opacity = 255
    end
    
    @sprite_push = Sprite.new
    @sprite_push.bitmap = RPG::Cache.picture(PICTURE_GAME_HEADER_PUSH)
    @sprite_push.y = 320
    @sprite_push.x = 155
    @sprite_push.opacity = 0
    
    #停頓
    if !skip
      for i in 0...40
        Graphics.update
        @sprite_push.opacity += (255 / 40)
        if Input.trigger?(Input::C)
          20.times {Graphics.update}
          @sprite_push.opacity = 255
          skip = true
          break
        end
      end
    else
      @sprite_push.opacity = 255
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
      # 如果画面被切换就中断循环
      if $scene != self
        break
      end
    end
    # 装备过渡
    Graphics.freeze
    # 释放标题图形
    unless $DEBUG
    @sprite_back.bitmap.dispose
    @sprite_back.dispose
    @sprite_title.bitmap.dispose
    @sprite_title.dispose
    @sprite_push.bitmap.dispose
    @sprite_push.dispose
    @sprite_piripiri_logo.bitmap.dispose
    @sprite_piripiri_logo.dispose
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    if Input.trigger?(Input::C)
      # 判定继续的有效性
      # 存档文件一个也不存在的时候也调查
      # 有効为 @continue_enabled 为 true、无效为 false
      @continue_enabled = false
      for i in 0..1
        if FileTest.exist?("Save/Save#{i+1}.rxdata")
          @continue_enabled = true
        end
      end
      if @continue_enabled == true
        $scene = Scene_Load.new
      else
        command_new_game
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 命令 : 新游戏
  #--------------------------------------------------------------------------
  def command_new_game
    # 演奏确定 SE
    $game_system.se_play($data_system.decision_se)
    # 停止 BGM
    Audio.bgm_stop
    # 重置测量游戏时间用的画面计数器
    Graphics.frame_count = 0
    # 生成各种游戏对像
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $game_switches      = Game_Switches.new
    $game_variables     = Game_Variables.new
    $game_self_switches = Game_SelfSwitches.new
    $game_screen        = Game_Screen.new
    $game_actors        = Game_Actors.new
    $game_tanks         = Game_Tanks.new
    $game_party         = Game_Party.new
    $game_troop         = Game_Troop.new
    $game_map           = Game_Map.new
    $game_players       = Game_Players.new
    $game_maps          = Game_Maps.new
    
    $game_plugins       = PluginManager.new
    
    $game_plugin_states = {}
    
    #插件注册
    PluginModule.registPlugins()
    
    # 设置初期同伴位置
    $game_party.setup_starting_members
    # 设置初期位置的地图
    $game_map.setup($data_system.start_map_id)
    # 主角向初期位置移动
    
    $game_players.reset
    
    $game_players.moveto($data_system.start_x, $data_system.start_y)
    # 刷新主角
    $game_players.refresh
    # 执行地图设置的 BGM 与 BGS 的自动切换
    $game_map.autoplay
    # 刷新地图 (执行并行事件)
    $game_map.update
    # 切换地图画面
    $scene = Scene_Name.new($game_party.actors[0])
    #$scene = Scene_Map.new
  end
  
  #--------------------------------------------------------------------------
  # ● 命令 : 继续
  #--------------------------------------------------------------------------
  def command_continue
    # 继续无效的情况下
    unless @continue_enabled
      # 演奏无效 SE
      $game_system.se_play($data_system.buzzer_se)
      return
    end
    # 演奏确定 SE
    $game_system.se_play($data_system.decision_se)
    # 切换到读档画面
    $scene = Scene_Load.new
  end
  
  #--------------------------------------------------------------------------
  # ● 战斗测试（失效）
  #--------------------------------------------------------------------------
  def battle_test
    # 载入数据库 (战斗测试用)
    $data_actors        = load_data("Data/BT_Actors.rxdata")
    $data_classes       = load_data("Data/BT_Classes.rxdata")
    $data_skills        = load_data("Data/BT_Skills.rxdata")
    $data_items         = load_data("Data/BT_Items.rxdata")
    $data_weapons       = load_data("Data/BT_Weapons.rxdata")
    $data_armors        = load_data("Data/BT_Armors.rxdata")
    $data_enemies       = load_data("Data/BT_Enemies.rxdata")
    $data_troops        = load_data("Data/BT_Troops.rxdata")
    $data_states        = load_data("Data/BT_States.rxdata")
    $data_animations    = load_data("Data/BT_Animations.rxdata")
    $data_tilesets      = load_data("Data/BT_Tilesets.rxdata")
    $data_common_events = load_data("Data/BT_CommonEvents.rxdata")
    $data_system        = load_data("Data/BT_System.rxdata")
    # 重置测量游戏时间用的画面计数器
    Graphics.frame_count = 0
    # 生成各种游戏对像
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $game_switches      = Game_Switches.new
    $game_variables     = Game_Variables.new
    $game_self_switches = Game_SelfSwitches.new
    $game_screen        = Game_Screen.new
    $game_actors        = Game_Actors.new
    $game_party         = Game_Party.new
    $game_troop         = Game_Troop.new
    $game_map           = Game_Map.new
    $game_player        = Game_Player.new
    # 设置战斗测试用同伴
    $game_party.setup_battle_test_members
    # 设置队伍 ID、可以逃走标志、战斗背景
    $game_temp.battle_troop_id = $data_system.test_troop_id
    $game_temp.battle_can_escape = true
    $game_map.battleback_name = $data_system.battleback_name
    # 演奏战斗开始 BGM
    $game_system.se_play($data_system.battle_start_se)
    # 演奏战斗 BGM
    $game_system.bgm_play($game_system.battle_bgm)
    # 切换到战斗画面
    $scene = Scene_Battle.new
  end
end