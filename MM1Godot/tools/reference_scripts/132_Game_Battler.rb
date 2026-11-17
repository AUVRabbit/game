#==============================================================================
# ■ Game_Battler (分割定义 1)
#------------------------------------------------------------------------------
# 　处理战斗者的类。这个类作为 Game_Actor 类与 Game_Enemy 类的
# 超级类来使用。
#==============================================================================

class Game_Battler
  
  attr_accessor :battle_sprite            # 战斗精灵映射
  attr_accessor :hit_ex                   #命中率加成
  
  include MM_System
  include MM_DataBase
  
  alias :old_initialize :initialize
  def initialize
    old_initialize
    @hit_ex = false
  end
  
  #--------------------------------------------------------------------------
  # ● 应用连续伤害效果
  #--------------------------------------------------------------------------
  def slip_damage_effect
    # 设置伤害
    self.damage = self.maxhp / 10
    # 分散
    if self.damage.abs > 0
      amp = [self.damage.abs * 15 / 100, 1].max
      self.damage += rand(amp+1) + rand(amp+1) - amp
    end
    # HP 的伤害减法运算
    self.damage = Integer(self.damage.roundf(0))
    self.damage = [self.damage, 0].max
    self.hp -= self.damage
    # 过程结束
    str = self.name + sprintf("受到了 %s 的伤害！", self.damage)
    return true, str
  end
  
  #--------------------------------------------------------------------------
  # ● 状态自然解除 (回合改变时调用)
  #--------------------------------------------------------------------------
  def remove_states_auto
    str = ""
    for i in @states_turn.keys.clone
      if @states_turn[i] > 0
        @states_turn[i] -= 1
      elsif rand(100) < $data_states[i].auto_release_prob
        remove_state(i)
        str += "|" if str != ""
        str += sprintf($data_states[i].battle_message_disappear, self.name)
      end
    end
    return str
  end
  
  #--------------------------------------------------------------------------
  # ● 状态攻击解除 (受到物理伤害时调用)
  #--------------------------------------------------------------------------
  def remove_states_shock
    str = ""
    for i in @states.clone
      if rand(100) < $data_states[i].shock_release_prob
        remove_state(i)
        str += "|" if str != ""
        str += sprintf($data_states[i].battle_message_disappear, self.name)
      end
    end
    return str
  end
  
  #--------------------------------------------------------------------------
  # ● 获取命中率
  #--------------------------------------------------------------------------
  def hit
    n = 100
    for i in @states
      n *= $data_states[i].hit_rate / 100.0
    end
    #上升
    if @hit_ex
      n *= 1.2
    end
    return [Integer(n), 100].min
  end
  
  #--------------------------------------------------------------------------
  # ● 应用通常攻击效果
  #     attacker : 攻击者 (battler)
  #--------------------------------------------------------------------------
  def attack_effect(attacker, attacker_weapon = nil)
    case attacker
    when Game_Enemy
      case self
      when Game_Actor
        # 清除会心一击标志
        self.critical = false
        # 第一命中判定
        hit_result = (rand(100) < attacker.hit - self.battle_level * rand(1.0) - 5)
        # 命中的情况下
        if hit_result == true
          # 计算基本伤害
          atk = [attacker.atk - self.pdef / 2, 0].max
          self.damage = atk * (20 + attacker.str) / 20
          self.damage -= self.battle_level * rand(2.0) * 0.8
          
          # 属性修正
          self.damage *= elements_correct(attacker.element_set)
          self.damage /= 100
          
          # 伤害符号正确的情况下
          if self.damage > 0
            # 会心一击修正
            if rand(100) < 4 * attacker.dex / self.agi
              self.damage *= 2
              self.critical = true
            end
            # 防御修正
            if self.guarding?
              self.damage /= 2
            end
          end
          # 分散
          if self.damage.abs > 0
            amp = [self.damage.abs * 15 / 100, 1].max
            self.damage += rand(amp+1) + rand(amp+1) - amp
          end
          # 第二命中判定
          eva = 8 * self.agi / attacker.dex + self.eva
          hit = self.damage < 0 ? 100 : 100 - eva
          hit = self.cant_evade? ? 100 : hit
          hit_result = (rand(100) < hit)
        end
        # 命中的情况下
        if hit_result == true
          # 状态冲击解除
          state_str = remove_states_shock
          # HP 的伤害计算
          self.damage = Integer(self.damage.roundf(0))
          self.damage = [self.damage, 0].max
          self.hp -= self.damage
          # 状态变化
          @state_changed = false
          states_plus(attacker.plus_state_set)
          states_minus(attacker.minus_state_set)
        # Miss 的情况下
        else
          # 伤害设置为 "Miss"
          self.damage = "Miss"
          # 清除会心一击标志
          self.critical = false
        end
        # 过程结束
        if self.damage == "Miss"
          str = sprintf(VOCAB_BATTLE_NOEFFECTIVE_NORMAL, attacker.name)
        else
          tp_str = attacker.battle_message
          str = ""
          if self.critical
            str = "打空了！|"
          end
          if tp_str[0] == ""
            str += sprintf(VOCAB_BATTLE_EFFECTIVE_NORMAL, attacker.name, self.name, self.damage)
          else
            str += sprintf(str[0], attacker.name, self.name, self.damage)
          end
          if self.hp <= 0
            str += "| " + self.name + "死了！"
          else
            str += state_str if state_str != nil
          end
        end
        return true, str
        
      when Game_Tank
        # 清除会心一击标志
        self.critical = false
        # 第一命中判定
        hit_result = (rand(100) < attacker.hit - self.driver.driver_level * rand(2.0) - 10)
        # 命中的情况下
        if hit_result == true
          # 计算基本伤害
          atk = [attacker.atk - self.pdef / 2, 0].max
          self.damage = atk * (20 + attacker.str) / 20
          # 属性修正
          self.damage *= elements_correct(attacker.element_set)
          self.damage /= 100
          # 伤害符号正确的情况下
          if self.damage > 0
            # 会心一击修正
            if rand(100) < 4 * attacker.dex / self.driver.driver_level * 2
              self.damage *= 2
              self.critical = true
            end
            # 防御修正
            if self.guarding?
              self.damage /= 2
            end
          end
          # 分散
          if self.damage.abs > 0
            amp = [self.damage.abs * 15 / 100, 1].max
            self.damage += rand(amp+1) + rand(amp+1) - amp
          end
          # 第二命中判定
          eva = 8 * self.driver.driver_level / (rand(5.0) + 1) * self.pdef / attacker.dex + self.eva
          hit = self.damage < 0 ? 100 : 100 - eva
          hit = self.cant_evade? ? 100 : hit
          hit_result = (rand(100) < hit)
        end
        # 命中的情况下
        if hit_result == true
          # 状态冲击解除
          state_str = remove_states_shock
          # HP 的伤害计算
          self.damage = Integer(self.damage.roundf(0))
          self.damage = [self.damage, 0].max
          self.hp -= self.damage
          # 状态变化
          @state_changed = false
          states_plus(attacker.plus_state_set)
          states_minus(attacker.minus_state_set)
        # Miss 的情况下
        else
          # 伤害设置为 "Miss"
          self.damage = "Miss"
          # 清除会心一击标志
          self.critical = false
        end
        # 过程结束
        if self.damage == "Miss"
          str = sprintf(VOCAB_BATTLE_NOEFFECTIVE_NORMAL, attacker.name)
        else
          tp_str = attacker.battle_message
          str = ""
          if self.critical
            str += "打空了！|"
          end
          if tp_str[0] == ""
            str += sprintf(VOCAB_BATTLE_EFFECTIVE_NORMAL, attacker.name, self.name, self.damage)
          else
            str += sprintf(str[0], attacker.name, self.name, self.damage)
          end
        end
        
        #损坏判定
        
        if hit_result
          #如果装甲打完了的话，先考虑底盘损坏与否
          underpan_broken = false
          
          if self.hp <= 0
            #如果戰車是出租戰車
            if self.rent
              #直接彈出
              str += " | 出租车把" + self.driver.name + "扔掉，自己跑掉了！"
              $game_party.updown_in_battle($game_party.members.index(self))
              underpan_broken = true
            else
              #計算底盤損壞概率
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                #損壞
                self.underpan.big_broken
                str += " | 底盘大破，" + self.driver.name + "从战车上跳下来！"
                $game_party.updown_in_battle($game_party.members.index(self))
                underpan_broken = true
              end
            end
            #再考虑其它部件是否损坏
            if underpan_broken
              r = 6
            else
              r = rand(5)
            end
            case r
            # 主炮
            when 1
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                if self.main_cannon.normal?
                  self.main_cannon.little_broken
                  str += " | 主炮损坏了！"
                elsif self.main_cannon.little_broken?
                  self.main_cannon.big_broken
                  str += " | 主炮大破！"
                end
              end
            # 副炮
            when 2
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                if self.main_cannon.normal?
                  self.main_cannon.little_broken
                  str += " | 副炮损坏了！"
                elsif self.main_cannon.little_broken?
                  self.main_cannon.big_broken
                  str += " | 副炮大破！"
                end
              end
            # SE
            when 3
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                if self.main_cannon.normal?
                  self.main_cannon.little_broken
                  str += " | SE损坏了！"
                elsif self.main_cannon.little_broken?
                  self.main_cannon.big_broken
                  str += " | SE大破！"
                end
              end
            # C装置
            when 4
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                if self.main_cannon.normal?
                  self.main_cannon.little_broken
                  str += " | C装置损坏了！"
                elsif self.main_cannon.little_broken?
                  self.main_cannon.big_broken
                  str += " | C装置大破！"
                end
              end
            # 引擎
            when 5
              r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
              if r <= 2
                if self.main_cannon.normal?
                  self.main_cannon.little_broken
                  str += " | 引擎损坏了！"
                elsif self.main_cannon.little_broken?
                  self.main_cannon.big_broken
                  str += " | 引擎大破！"
                end
              end
            end
          end
        else
          str += state_str if state_str != nil
        end
        underpan_broken = false if underpan_broken == nil
        return true, str, underpan_broken
      end
      
    when Game_Actor
      # 清除会心一击标志
      self.critical = false
      # 第一命中判定
      hit_result = (rand(100) < attacker.hit + attacker.agi * rand(0.5) - self.agi / 10)
      # 命中的情况下
      if hit_result == true
        # 计算基本伤害
        atk = [attacker.atk - self.pdef / 2, 0].max
        self.damage = atk * (20 + attacker.str) / 20
        
        self.damage += attacker.battle_level * rand(2) * attacker.atk - self.pdef / 3 * self.agi / 5
        
        # 属性修正
        self.damage *= elements_correct(attacker.element_set)
        self.damage /= 100
        
        # 伤害符号正确的情况下
        if self.damage > 0
          # 会心一击修正
          if rand(100) < 4 * attacker.dex / self.agi
            self.damage *= 2
            self.damage += attacker.battle_level * rand(1.0) * 2
            self.critical = true
          end
          # 防御修正
          if self.guarding?
            self.damage /= 2
          end
        end
        # 分散
        if self.damage.abs > 0
          amp = [self.damage.abs * 15 / 100, 1].max
          self.damage += rand(amp+1) + rand(amp+1) - amp
        end
        # 第二命中判定
        eva = 8 * self.agi / attacker.dex + self.eva
        hit = self.damage < 0 ? 100 : 100 - eva
        hit = self.cant_evade? ? 100 : hit
        hit_result = (rand(100) < hit)
      end
      # 命中的情况下
      if hit_result == true
        # 状态冲击解除
        state_str = remove_states_shock
        # HP 的伤害计算
        self.damage = Integer(self.damage.roundf(0))
        self.damage = [self.damage, 0].max
        self.hp -= self.damage
        # 状态变化
        @state_changed = false
        states_plus(attacker.plus_state_set)
        states_minus(attacker.minus_state_set)
      # Miss 的情况下
      else
        # 伤害设置为 "Miss"
        self.damage = "Miss"
        # 清除会心一击标志
        self.critical = false
      end
      # 过程结束
      if self.damage == "Miss"
        str = sprintf(VOCAB_BATTLE_NOEFFECTIVE_NORMAL, attacker.name)
      else
        #tp_str = attacker.battle_message
        str = ""
        str += sprintf(VOCAB_BATTLE_EFFECTIVE_NORMAL, attacker.name, self.name, self.damage)
        if self.critical
          str = "间不容发！|"
        end
        str += ""
        #if tp_str[0] == ""
        #else
        #  str += sprintf(str[0], attacker.name, self.name, self.damage)
        #end
      end
      if self.hp <= 0
        str += "| 打倒了" + self.name + "！"
      else
        str += state_str if state_str != nil
      end
      return true, str

    when Game_Tank
      # 清除会心一击标志
      self.critical = false
      # 第一命中判定
      hit_result = (rand(100) < attacker.hit)
      # 命中的情况下
      if hit_result == true
        # 计算基本伤害
        case attacker.current_action.kind
        when BATTLETANKACTIONKIND_MAIN_CANNON
          atk = [attacker.main_cannon.atk - self.pdef / 2, 0].max
        when BATTLETANKACTIONKIND_SUB_CANNON
          atk = [attacker.sub_cannon.atk - self.pdef / 2, 0].max
        when BATTLETANKACTIONKIND_SE
          atk = [attacker.se.atk - self.pdef / 2, 0].max
        #when BATTLE_SPECIAL_CANNONBALL
          #atk = [$data_specialcannonballs[attacker.current_action.specialcannonball_id].atk - self.pdef / 2, 0].max
        end
        self.damage = attacker.driver.driver_level * rand(4.0) * attacker.driver.driver_level * rand(4.0) / 40 * attacker.atk - self.pdef / 3 * self.agi / 5
        # 属性修正
        self.damage *= elements_correct(attacker.element_set)
        self.damage /= 100
        # 伤害符号正确的情况下
        if self.damage > 0
          # 会心一击修正
          if rand(100) < 4 * attacker.driver.driver_level * rand(4.0) / self.agi
            self.damage *= 2
            self.damage += attacker.driver.driver_level * rand(1.0) / 5 * attacker.atk
            self.critical = true
          end
          # 防御修正
          if self.guarding?
            self.damage /= 2
          end
        end
        # 分散
        if self.damage.abs > 0
          amp = [self.damage.abs * 15 / 100, 1].max
          self.damage += rand(amp+1) + rand(amp+1) - amp
        end
        # 第二命中判定
        eva = 8 * self.agi / attacker.driver.driver_level * rand(4) + self.eva
        hit = self.damage < 0 ? 100 : 100 - eva
        hit = self.cant_evade? ? 100 : hit
        hit_result = (rand(100) < hit)
      end
      # 命中的情况下
      if hit_result == true
        # 状态冲击解除
        state_str = remove_states_shock
        # HP 的伤害计算
        self.damage = Integer(self.damage.roundf(0))
        self.damage = [self.damage, 0].max
        self.hp -= self.damage
        # 状态变化
        @state_changed = false
        states_plus(attacker.plus_state_set)
        states_minus(attacker.minus_state_set)
      # Miss 的情况下
      else
        # 伤害设置为 "Miss"
        self.damage = "Miss"
        # 清除会心一击标志
        self.critical = false
      end
      # 过程结束
      if self.damage == "Miss"
        str = sprintf(VOCAB_BATTLE_NOEFFECTIVE_NORMAL, attacker.name)
      else
        #tp_str = attacker.battle_message
        str = ""
        str += sprintf(VOCAB_BATTLE_EFFECTIVE_NORMAL, attacker.name, self.name, self.damage)
        if self.critical
          str = "间不容发！|"
        end
        #if tp_str[0] == ""
        #else
        #  str += sprintf(str[0], attacker.name, self.name, self.damage)
        #end
      end
      if self.hp <= 0
        str += "| 打倒了" + self.name + "！"
      else
        str += state_str if state_str != nil
      end
      return true, str
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 应用特技效果
  #     user  : 特技的使用者 (battler)
  #     skill : 特技
  #--------------------------------------------------------------------------
  def skill_effect(user, skill)
    # 清除会心一击标志
    self.critical = false
    # 特技的效果范围是 HP 1 以上的己方、自己的 HP 为 0、
    # 或者特技的效果范围是 HP 0 的己方、自己的 HP 为 1 以上的情况下
    if ((skill.scope == 3 or skill.scope == 4) and self.hp == 0) or
       ((skill.scope == 5 or skill.scope == 6) and self.hp >= 1)
      # 过程结束
      str = sprintf(VOCAB_NOEFFECT, self.name, item.name)
      return false, str
    end
    # 清除有效标志
    effective = false
    # 公共事件 ID 是有效的情况下,设置为有效标志
    effective |= skill.common_event_id > 0
    # 第一命中判定
    hit = skill.hit
    if skill.atk_f > 0
      hit *= user.hit / 100
    end
    hit_result = (rand(100) < hit)
    # 不确定的特技的情况下设置为有效标志
    effective |= hit < 100
    # 命中的情况下
    if hit_result == true
      # 计算威力
      power = skill.power + user.atk * skill.atk_f / 100
      if power > 0
        power -= self.pdef * skill.pdef_f / 200
        power -= self.mdef * skill.mdef_f / 200
        power = [power, 0].max
      end
      # 计算倍率
      rate = 20
      rate += (user.str * skill.str_f / 100)
      rate += (user.dex * skill.dex_f / 100)
      rate += (user.agi * skill.agi_f / 100)
      rate += (user.int * skill.int_f / 100)
      # 计算基本伤害
      self.damage = power * rate / 20
      # 属性修正
      self.damage *= elements_correct(skill.element_set)
      self.damage /= 100
      # 伤害符号正确的情况下
      if self.damage > 0
        # 防御修正
        if self.guarding?
          self.damage /= 2
        end
      end
      # 分散
      if skill.variance > 0 and self.damage.abs > 0
        amp = [self.damage.abs * skill.variance / 100, 1].max
        self.damage += rand(amp+1) + rand(amp+1) - amp
      end
      # 第二命中判定
      eva = 8 * self.agi / user.dex + self.eva
      hit = self.damage < 0 ? 100 : 100 - eva * skill.eva_f / 100
      hit = self.cant_evade? ? 100 : hit
      hit_result = (rand(100) < hit)
      # 不确定的特技的情况下设置为有效标志
      effective |= hit < 100
    end
    # 命中的情况下
    if hit_result == true
      # 威力 0 以外的物理攻击的情况下
      if skill.power != 0 and skill.atk_f > 0
        # 状态冲击解除
        state_str = remove_states_shock
        # 设置有效标志
        effective = true
      end
      # HP 的伤害减法运算
      last_hp = self.hp
      
      case self
      when Game_Actor
        self.damage -= self.battle_level * rand(0.5) * self.pdef * rand(0.4) * 0.8
      when Game_Tank
        self.damage -= self.driver.driver_level * rand(0.5) * self.pdef * rand(0.8) * 0.8
      end
      
      self.damage = Integer(self.damage.roundf(0))
      self.damage = [self.damage, 0].max
      self.hp -= self.damage
      effective |= self.hp != last_hp
      # 状态变化
      @state_changed = false
      effective |= states_plus(skill.plus_state_set)
      effective |= states_minus(skill.minus_state_set)
      # 威力为 0 的场合
      if skill.power == 0
        # 伤害设置为空的字串
        self.damage = ""
        # 状态没有变化的情况下
        unless @state_changed
          # 伤害设置为 "Miss"
          self.damage = "Miss"
        end
      end
    # Miss 的情况下
    else
      # 伤害设置为 "Miss"
      self.damage = "Miss"
    end
    # 不在战斗中的情况下
    unless $game_temp.in_battle
      # 伤害设置为 nil
      self.damage = nil
    end
    # 过程结束
    if self.damage == "Miss"
      str = sprintf(VOCAB_BATTLE_NOEFFECTIVE_NORMAL, user.name)
    else
      tp_str = skill.battle_message
      str = ""
      if self.critical
        str = "打空了！|"
      end
      if tp_str[0] == ""
        str += sprintf(VOCAB_BATTLE_EFFECTIVE_NORMAL, user.name, self.name, self.damage)
      else
        str += sprintf(str[0], user.name, self.name, self.damage)
      end
    end
    
    case self
    when Game_Actor
      if hit_result
        str += "| " + self.name + "死了！"
      end
    when Game_Tank
      if hit_result
        underpan_broken = false
        #如果装甲打完了的话，先考虑底盘损坏与否
        if self.hp <= 0
          #如果戰車是出租戰車
          if self.rent
            #直接彈出
            str += " | 出租车把" + self.driver.name + "扔掉，自己跑掉了！"
            $game_party.updown_in_battle($game_party.members.index(self))
            underpan_broken = true
          else
            #計算底盤損壞概率
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 5
              #損壞
              self.underpan.big_broken
              str += " | 底盘大破，" + self.driver.name + "从战车上跳下来！"
              $game_party.updown_in_battle($game_party.members.index(self))
              underpan_broken = true
            end
          end
          #再考虑其它部件是否损坏
          if underpan_broken
            r = 6
          else
            r = rand(5)
          end
          case r
          # 主炮
          when 1
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 2
              if self.main_cannon.normal?
                self.main_cannon.little_broken
                str += " | 主炮损坏了！"
              elsif self.main_cannon.little_broken?
                self.main_cannon.big_broken
                str += " | 主炮大破！"
              end
            end
          # 副炮
          when 2
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 2
              if self.main_cannon.normal?
                self.main_cannon.little_broken
                str += " | 副炮损坏了！"
              elsif self.main_cannon.little_broken?
                self.main_cannon.big_broken
                str += " | 副炮大破！"
              end
            end
          # SE
          when 3
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 2
              if self.main_cannon.normal?
                self.main_cannon.little_broken
                str += " | SE损坏了！"
              elsif self.main_cannon.little_broken?
                self.main_cannon.big_broken
                str += " | SE大破！"
              end
            end
          # C装置
          when 4
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 2
              if self.main_cannon.normal?
                self.main_cannon.little_broken
                str += " | C装置损坏了！"
              elsif self.main_cannon.little_broken?
                self.main_cannon.big_broken
                str += " | C装置大破！"
              end
            end
          # 引擎
          when 5
            r = 5 + (attacker.atk - self.pdef) / 10 * rand(2)
            if r <= 2
              if self.main_cannon.normal?
                self.main_cannon.little_broken
                str += " | 引擎损坏了！"
              elsif self.main_cannon.little_broken?
                self.main_cannon.big_broken
                str += " | 引擎大破！"
              end
            end
          end
        end
      end
    end
    underpan_broken = false if underpan_broken == nil
    return effective, str, underpan_broken
  end
  
  #--------------------------------------------------------------------------
  # ● 应用物品效果
  #     item : 物品
  #--------------------------------------------------------------------------
  def item_effect(item, scr_target = nil)
    if item.scope == 0 || item.occasion == 2 || item.occasion == 3
      str = sprintf(VOCAB_NOEFFECT, self.name, item.name)
      return false, str
    end
    # 清除会心一击标志
    self.critical = false
    # 物品的效果范围是 HP 1 以上的己方、自己的 HP 为 0、
    # 或者物品的效果范围是 HP 0 的己方、自己的 HP 为 1 以上的情况下
    if ((item.scope == 3 or item.scope == 4) and self.hp == 0) or
       ((item.scope == 5 or item.scope == 6) and self.hp >= 1)
      # 过程结束
      str = sprintf(VOCAB_NOEFFECT, self.name, item.name)
      return false, str
    end
#Actor : [id, 名稱, 對象, 時機, 動畫1, 動畫2, 動畫3, 公共事件id, 價格, 是否消耗, 
# hp影響, 攻擊力影響, 迴避力影響, 屬性, 附加狀態, 解除狀態]
    # 清除有效标志
    effective = false
    other_effective = false
    # 公共事件 ID 是有效的情况下,设置为有效标志
    effective |= item.common_event_id > 0
    case item.type
    #人类道具时
    when ITEM_PEOPLE
      #如果對HP有影響
      #效果范围（0：无，1：敌单体，2：敵一組, 3：敌全体，4：己方单体, 5：己方全体，
      #6：己方单体（HP 0），7：己方全体（HP 0），8：使用者）。
      if item.hp_effect != 0
        if [4, 5, 6, 7, 8].include?(item.scope)
          effect_hp = [[self.maxhp - self.hp, item.hp_effect].min, 0].max
          self.hp += effect_hp
          other_effective = true
        else
          # 清除会心一击标志
          self.critical = false
          # 第一命中判定
          hit_result = (rand(100) < scr_target.hit + scr_target.agi * rand(0.5) - self.agi / 10)
          # 命中的情况下
          if hit_result == true
            # 计算基本伤害
            atk = [item.atk - self.pdef / 2, 0].max
            #self.damage = atk * (20 + scr_target.str) / 20
        
            #self.damage += attacker.battle_level * rand(2) * attacker.atk - self.pdef / 3 * self.agi / 5
        
            # 属性修正
            self.damage *= elements_correct(item.element_set)
            self.damage /= 100
        
            # 伤害符号正确的情况下
            if self.damage > 0
              # 会心一击修正
              if rand(100) < 4 * scr_target.dex / self.agi
                self.damage *= 2
                #self.damage += attacker.battle_level * rand(0.0, 1.0) * 2
                self.critical = true
              end
              # 防御修正
              if self.guarding?
                self.damage /= 2
              end
            end
            # 分散
            if self.damage.abs > 0
              amp = [self.damage.abs * 15 / 100, 1].max
              self.damage += rand(amp+1) + rand(amp+1) - amp
            end
            # 第二命中判定
            eva = 8 * self.agi / scr_target.dex + self.eva
            hit = self.damage < 0 ? 100 : 100 - eva
            hit = self.cant_evade? ? 100 : hit
            hit_result = (rand(100) < hit)
          end
          # 命中的情况下
          if hit_result == true
            other_effective = true
            # 状态冲击解除
            state_str = remove_states_shock
            # HP 的伤害计算
            self.damage = Integer(self.damage.roundf(0))
            self.damage = [self.damage, 0].max
            self.hp -= self.damage
            # 状态变化
            @state_changed = false
            states_plus(item.plus_state_set)
            states_minus(item.minus_state_set)
          # Miss 的情况下
          else
            # 伤害设置为 "Miss"
            self.damage = "Miss"
            # 清除会心一击标志
            self.critical = false
          end
          # 过程结束
        end
      end
      #如果對攻擊力有影響
      if item.atk_effect != 0
        self.atk *= item.atk_effect
        other_effective = true
      end
      #如果對迴避力有影響
      if item.eva_effect != 0
        self.eva *= item.eva_effect
        other_effective = true
      end
    #战车道具时
#Tank :  [id, 名稱, 對象, 時機, 公共事件id, 價格, 是否消耗, hp影响, 命中率影響, 
# 屬性, 附加狀態, 解除狀態]  
    when ITEM_TANK
      #如果影響HP
      if item.hp_effect != 0
        if [4, 5, 6, 7, 8].include?(item.scope)
          effect_hp = [[self.maxhp - self.hp, item.hp_effect].min, 0].max
          self.hp += effect_hp
          other_effective = true
        end
      end
      #如果影響命中率
      if item.hit_effect != 0
        self.hit_ex == true
        other_effective = true
      end
    end
    # 状态变化
    @state_changed = false
    effective |= states_plus(item.plus_state_set)
    effective |= states_minus(item.minus_state_set)

    # HP 回复率与回复量为 0 的情况下
    if item.recover_hp_rate == 0 and item.recover_hp == 0
      # 设置伤害为空的字符串
      self.damage = ""
      # SP 回复率与回复量为 0、能力上升值无效的情况下
      if item.recover_sp_rate == 0 and item.recover_sp == 0 and
          (item.parameter_type == 0 or item.parameter_points == 0)
        # 状态没有变化的情况下
        unless @state_changed
          # 伤害设置为 "Miss"
          self.damage = "Miss"
        end
      end
    end
    # 不在战斗中的情况下
    unless $game_temp.in_battle
      # 伤害设置为 nil
      self.damage = nil
    end
    
    #處理信息
    if $game_temp.in_battle
      str_ary = item.battle_message
    else
      str_ary = item.menu_message
    end
    
    str = ""
    if self.critical
      str = "间不容发！|"
    end
    
    case str_ary[1]
    when "u"
      str += sprintf(str_ary[0], self.name)
    when "uun"
      str += sprintf(str_ary[0], self.name, self.name, effect_hp.to_s)
    when "utn"
      str += sprintf(str_ary[0], scr_target.name, self.name, self.damage.to_s)
    when "uu"
      str += sprintf(str_ary[0], scr_target.name, self.name)
    end
    
    if !effective && !other_effective
      str = sprintf(VOCAB_NOEFFECT, self.name, item.name)
    end
    
    if self.is_a?(Game_Enemy)
      if self.hp <= 0
        str += "| 打倒了" + self.name + "！"
      else
        str += state_str if state_str != nil
      end
    end
    
    # 过程结束
    return effective, str
  end
  
  def special_cannonball_effect(attacker, cannonball_id)
    cannonball = $data_specialcannonballs[cannonball_id]
    if cannonball.atk == SPECIALCANNONBALL_ATKTYPE_NOATK
      @state_changed = false
      states_plus([cannonball.state_id])
      str = sprintf(cannonball.battle_message[0], self.name)
      return true, str
    end
    
    # 清除会心一击标志
    self.critical = false
    # 清除有效标志
    effective = false
    
    # 第一命中判定
    hit_result = (rand(100) < attacker.hit + attacker.agi * rand(0.5) - self.agi / 10)
    # 命中的情况下
    if hit_result == true
      # 计算基本伤害
      atk = [attacker.atk - self.pdef / 2, 0].max
      #self.damage = atk * (20 + scr_target.str) / 20
        
      #self.damage += attacker.battle_level * rand(2) * attacker.atk - self.pdef / 3 * self.agi / 5
        
      # 属性修正
      self.damage *= elements_correct(item.element_set)
      self.damage /= 100
        
      # 伤害符号正确的情况下
      if self.damage > 0
        # 会心一击修正
        if rand(100) < 4 * attacker.dex / self.agi
          self.damage *= 2
          #self.damage += attacker.battle_level * rand(0.0, 1.0) * 2
          self.critical = true
        end
        # 防御修正
        if self.guarding?
          self.damage /= 2
        end
      end
      # 分散
      if self.damage.abs > 0
        amp = [self.damage.abs * 15 / 100, 1].max
        self.damage += rand(amp+1) + rand(amp+1) - amp
      end
      # 第二命中判定
      eva = 8 * self.agi / attacker.dex + self.eva
      hit = self.damage < 0 ? 100 : 100 - eva
      hit = self.cant_evade? ? 100 : hit
      hit_result = (rand(100) < hit)
    end
    # 命中的情况下
    if hit_result == true
      # 状态冲击解除
      state_str = remove_states_shock
      # HP 的伤害计算
      self.damage = Integer(self.damage.roundf(0))
      self.damage = [self.damage, 0].max
      self.hp -= self.damage
      # 状态变化
      @state_changed = false
      states_plus([cannonball.state_id])
      #states_plus(item.plus_state_set)
      #states_minus(item.minus_state_set)
      # Miss 的情况下
    else
      # 伤害设置为 "Miss"
      self.damage = "Miss"
      # 清除会心一击标志
      self.critical = false
    end
    
    if hit_result
      str = ""
      if self.critical
        str = "间不容发！|"
      end
      str += self.name + "受到了" + self.damage.to_s + "的伤害！"
    else
      str += "没有打中！"
    end
    
    if self.is_a?(Game_Enemy)
      if self.hp <= 0
        str += "| 打倒了" + self.name + "！"
      else
        str += state_str if state_str != nil
      end
    end
    return
  end
end