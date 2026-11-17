#==============================================================================
# ■ Game_BattleActionTank
#------------------------------------------------------------------------------
# 　处理行动 (战斗中的行动) 的类。这个类在 Game_Battler 类
# 的内部使用。
#==============================================================================

class Game_BattleActionTank
  
  include MM_System
  
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor :speed                    # 速度
  attr_accessor :kind                     # 种类 (主炮 / 副炮 / SE / 特殊炮彈/ 物品)
  attr_accessor :basic                    # 基本 (攻击 / 防御 / 保护 / 逃跑)
  attr_accessor :skill_id                 # 特技 ID
  attr_accessor :item_id                  # 物品 ID
  attr_accessor :target_index             # 对像索引
  attr_accessor :forcing                  # 强制标志
  attr_accessor :specialcannonball_id     # 特殊炮弹 ID
  attr_accessor :guard_taget              # 保护对象
  
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  def initialize
    clear
  end
  
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def clear
    @speed = 0
    @kind = BATTLE_MAIN_CANNON
    @basic = 1
    @item_id = 0
    @specialcannonball_id = 0
    @target_index = -1
    @guard_target = nil
    @forcing = false
  end
  
  #--------------------------------------------------------------------------
  # ● 己方单体使用判定
  #--------------------------------------------------------------------------
  def for_one_friend?
    # 种类为物品、效果范围是我方单体 (包含 HP 0) 的情况
    if @kind == 4 and [3, 5].include?($data_items[@item_id].scope)
      return true
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 己方单体用 (HP 0) 判定
  #--------------------------------------------------------------------------
  def for_one_friend_hp0?
    # 种类为物品、效果范围是我方单体 (HP 0) 的情况
    if @kind == 4 and [5].include?($data_items[@item_id].scope)
      return true
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 随机目标 (角色用)
  #--------------------------------------------------------------------------
  def decide_random_target_for_member
    # 效果范围的分支
    if for_one_friend_hp0?
      battler = $game_party.random_target_member_hp0
    elsif for_one_friend?
      battler = $game_party.random_target_member
    else
      battler = $game_troop.random_target_enemy
    end
    # 对像存在的话取得索引、
    # 对像不存在的场合下清除行动
    if battler != nil
      @target_index = battler.index
    else
      clear
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 随机目标 (敌人用)
  #--------------------------------------------------------------------------
  def decide_random_target_for_enemy
    # 效果范围的分支
    if for_one_friend_hp0?
      battler = $game_troop.random_target_enemy_hp0
    elsif for_one_friend?
      battler = $game_troop.random_target_enemy
    else
      battler = $game_party.random_target_member
    end
    # 对像存在的话取得索引、
    # 对像不存在的场合下清除行动
    if battler != nil
      @target_index = battler.index
    else
      clear
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 最后的目标 (角色用)
  #--------------------------------------------------------------------------
  def decide_last_target_for_member
    # 效果范围是己方单体以及行动者以外的敌人
    if @target_index == -1
      battler = nil
    elsif for_one_friend?
      battler = $game_party.members[@target_index]
    else
      battler = $game_troop.enemies[@target_index]
    end
    # 对像不存在的场合下清除行动
    if battler == nil or not battler.exist?
      clear
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 最后的目标 (敌人用)
  #--------------------------------------------------------------------------
  def decide_last_target_for_enemy
    # 效果范围是己方单体以敌人以外的角色
    if @target_index == -1
      battler = nil
    elsif for_one_friend?
      battler = $game_troop.enemies[@target_index]
    else
      battler = $game_party.members[@target_index]
    end
    # 对像不存在的场合下清除行动
    if battler == nil or not battler.exist?
      clear
    end
  end
end