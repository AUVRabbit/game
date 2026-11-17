module MM_DataBase  
  def make_main_cannons
    temp_ary = []
    for i in 0...DATA_MAIN_CANNON.size
      if DATA_MAIN_CANNON[i] != nil
        main_cannon = RPG::MainCannon.new
        main_cannon.id = DATA_MAIN_CANNON[i][0]
        main_cannon.name = DATA_MAIN_CANNON[i][1]
        main_cannon.animation1_id = DATA_MAIN_CANNON[i][2]
        main_cannon.animation2_id = DATA_MAIN_CANNON[i][3]
        main_cannon.animation3_id = DATA_MAIN_CANNON[i][4]
        main_cannon.quantity = DATA_MAIN_CANNON[i][5]
        main_cannon.atk = DATA_MAIN_CANNON[i][6]
        main_cannon.pdef = DATA_MAIN_CANNON[i][7]
        main_cannon.weight = DATA_MAIN_CANNON[i][8]
        main_cannon.repair_price = DATA_MAIN_CANNON[i][9]
        main_cannon.price = DATA_MAIN_CANNON[i][10]
      end
      temp_ary.push(main_cannon)
    end
    return temp_ary
  end
  
  def make_sub_cannons
    temp_ary = []
    for i in 0...DATA_SUB_CANNON.size
      if DATA_SUB_CANNON[i] != nil
        sub_cannon = RPG::SubCannon.new
        sub_cannon.id = DATA_SUB_CANNON[i][0]
        sub_cannon.name = DATA_SUB_CANNON[i][1]
        sub_cannon.animation1_id = DATA_SUB_CANNON[i][2]
        sub_cannon.animation2_id = DATA_SUB_CANNON[i][3]
        sub_cannon.animation3_id = DATA_SUB_CANNON[i][4]
        sub_cannon.quantity = DATA_SUB_CANNON[i][5]
        sub_cannon.atk = DATA_SUB_CANNON[i][6]
        sub_cannon.pdef = DATA_SUB_CANNON[i][7]
        sub_cannon.weight = DATA_SUB_CANNON[i][8]
        sub_cannon.repair_price = DATA_SUB_CANNON[i][9]
        sub_cannon.price = DATA_SUB_CANNON[i][10]
        sub_cannon.range_type = DATA_SUB_CANNON[i][11]
        sub_cannon.equip_position = DATA_SUB_CANNON[i][12]
      end
      temp_ary.push(sub_cannon)
    end
    return temp_ary
  end
  
  def make_ses
    temp_ary = []
    for i in 0...DATA_SE.size
      if DATA_SE[i] != nil
        se = RPG::SE.new
        se.id = DATA_SE[i][0]
        se.name = DATA_SE[i][1]
        se.animation1_id = DATA_SE[i][2]
        se.animation2_id = DATA_SE[i][3]
        se.animation3_id = DATA_SE[i][4]
        se.quantity = DATA_SE[i][5]
        se.atk = DATA_SE[i][6]
        se.pdef = DATA_SE[i][7]
        se.weight = DATA_SE[i][8]
        se.repair_price = DATA_SE[i][9]
        se.price = DATA_SE[i][10]
        se.range_type = DATA_SE[i][11]
        se.equip_position = DATA_SE[i][12]
      end
      temp_ary.push(se)
    end
    return temp_ary
  end
  
  def make_engines
    temp_ary = []
    for i in 0...DATA_ENGINE.size
      if  DATA_ENGINE[i] != nil
        engine = RPG::Engine.new
        engine.id = DATA_ENGINE[i][0]
        engine.name = DATA_ENGINE[i][1]
        engine.price = DATA_ENGINE[i][2]
        engine.repair_price = DATA_ENGINE[i][3]
        engine.weight = DATA_ENGINE[i][4]
        engine.load = DATA_ENGINE[i][5]
        engine.pdef = DATA_ENGINE[i][6]
      end
      temp_ary.push(engine)
    end
    return temp_ary
  end
  
  def make_c_units
    temp_ary = []
    for i in 0...DATA_C_UNIT.size
      if DATA_C_UNIT[i] != nil
        c_unit = RPG::C_Unit.new
        c_unit.id = DATA_C_UNIT[i][0]
        c_unit.name = DATA_C_UNIT[i][1]
        c_unit.price = DATA_C_UNIT[i][2]
        c_unit.repair_price = DATA_C_UNIT[i][3]
        c_unit.weight = DATA_C_UNIT[i][4]
        c_unit.pdef = DATA_C_UNIT[i][5]
      end
      temp_ary.push(c_unit)
    end
    return temp_ary
  end
  
  def make_underpans
    temp_ary = []
    for i in 0...DATA_UNDERPAN.size
      if DATA_UNDERPAN[i] != nil
        underpan = RPG::Underpan.new
        underpan.id = DATA_UNDERPAN[i][0]
        underpan.name = DATA_UNDERPAN[i][1]
        underpan.hole = DATA_UNDERPAN[i][2] 
        underpan.weight = DATA_UNDERPAN[i][3]
        underpan.special_cannonball = DATA_UNDERPAN[i][4]
        underpan.special_cannonball_capacity = DATA_UNDERPAN[i][5]
        underpan.status_guard = DATA_UNDERPAN[i][6]
        underpan.price = DATA_UNDERPAN[i][7]
        underpan.repair_price = DATA_UNDERPAN[i][8]
        underpan.pdef = DATA_UNDERPAN[i][9]
      end
      temp_ary.push(underpan)
    end
    return temp_ary
  end
  
  def make_tanks
    temp_ary = []
    for i in 0...DATA_TANK.size
      if DATA_TANK[i] != nil
        tank = RPG::Tank.new
        tank.id = DATA_TANK[i][0]
        tank.name = DATA_TANK[i][1]
        tank.character_name = DATA_TANK[i][2]
        tank.character_hue = DATA_TANK[i][3]
        tank.battler_name = DATA_TANK[i][4]
        tank.character_hue = DATA_TANK[i][5]
        tank.rent = DATA_TANK[i][6]
        tank.main_cannon_id = DATA_TANK[i][7]
        tank.sub_cannon_id = DATA_TANK[i][8]
        tank.se_id = DATA_TANK[i][9]
        tank.engine_id = DATA_TANK[i][10]
        tank.c_unit_id = DATA_TANK[i][11]
        tank.underpan_id = DATA_TANK[i][12]
      end
      temp_ary.push(tank)
    end
    return temp_ary
  end
  
  def make_specialcannonballs
    temp_ary = []
    for i in 0...DATA_SPECIAL_CANNONBALL.size
      if DATA_SPECIAL_CANNONBALL[i] != nil
        specialcannonball = RPG::SpecialCannonball.new
        specialcannonball.id = DATA_SPECIAL_CANNONBALL[i][0]
        specialcannonball.name = DATA_SPECIAL_CANNONBALL[i][1]
        specialcannonball.price = DATA_SPECIAL_CANNONBALL[i][2]
        specialcannonball.atk = DATA_SPECIAL_CANNONBALL[i][3]
        specialcannonball.state_id = DATA_SPECIAL_CANNONBALL[i][4]
      end
      temp_ary.push(specialcannonball)
    end
    return temp_ary
  end
  
  def make_actor_weapons
    temp_ary = []
    for i in 0...DATA_WEAPON.size
      if DATA_WEAPON[i ] != nil
        actor_weapon = RPG::Weapon.new
        actor_weapon.id = DATA_WEAPON[i][0]
        actor_weapon.name = DATA_WEAPON[i][1]
        actor_weapon.animation1_id = DATA_WEAPON[i][2]
        actor_weapon.animation2_id = DATA_WEAPON[i][3]
        actor_weapon.animation3_id = DATA_WEAPON[i][4]
        actor_weapon.price = DATA_WEAPON[i][5]
        actor_weapon.atk = DATA_WEAPON[i][6]
        actor_weapon.element_set = DATA_WEAPON[i][7]
        actor_weapon.can_equip_actors = DATA_WEAPON[i][8]
        actor_weapon.range_type = DATA_WEAPON[i][9]
      end
      temp_ary.push(actor_weapon)
    end
    return temp_ary
  end
  
  def make_actor_armors
    temp_ary = []
    for i in 0...DATA_ARMOR.size
      if DATA_ARMOR[i] != nil
        actor_armor = RPG::Armor.new
        actor_armor.id = DATA_ARMOR[i][0]
        actor_armor.name = DATA_ARMOR[i][1]
        actor_armor.kind = DATA_ARMOR[i][2]
        actor_armor.price = DATA_ARMOR[i][3]
        actor_armor.pdef = DATA_ARMOR[i][4]
        actor_armor.eva = DATA_ARMOR[i][5]
        actor_armor.guard_element_set = DATA_ARMOR[i][6]
        actor_armor.guard_state_set = DATA_ARMOR[i][7]
        actor_armor.can_equip_actors = DATA_ARMOR[i][8]
      end
      temp_ary.push(actor_armor)
    end
    return temp_ary
  end
  
  def make_actor_items
    temp_ary = []
    for i in 0...DATA_ACTOR_ITEM.size
      if DATA_ACTOR_ITEM[i] != nil
        actor_item = RPG::Item.new
        actor_item.menu_message = VOCAB_ACOTR_ITEM_MENU[i]
        actor_item.battle_message = VOCAB_ACOTR_ITEM_BATTLE[i]
        actor_item.type = 0
        actor_item.id = DATA_ACTOR_ITEM[i][0]
        actor_item.name = DATA_ACTOR_ITEM[i][1]
        actor_item.scope = DATA_ACTOR_ITEM[i][2]
        actor_item.occasion = DATA_ACTOR_ITEM[i][3]
        actor_item.animation1_id = DATA_ACTOR_ITEM[i][4]
        actor_item.animation2_id = DATA_ACTOR_ITEM[i][5]
        actor_item.animation3_id = DATA_ACTOR_ITEM[i][6]
        actor_item.common_event_id = DATA_ACTOR_ITEM[i][7]
        actor_item.price = DATA_ACTOR_ITEM[i][8]
        actor_item.consumable = DATA_ACTOR_ITEM[i][9]
        actor_item.hp_effect = DATA_ACTOR_ITEM[i][10]
        actor_item.atk_effect = DATA_ACTOR_ITEM[i][11]
        actor_item.eva_effect = DATA_ACTOR_ITEM[i][12]
        actor_item.element_set = DATA_ACTOR_ITEM[i][13]
        actor_item.plus_state_set = DATA_ACTOR_ITEM[i][14]
        actor_item.minus_state_set = DATA_ACTOR_ITEM[i][15]
      end
      temp_ary.push(actor_item)
    end
    return temp_ary
  end
  
  def make_tank_items
    temp_ary = []
    for i in 0...DATA_TANK_ITEM.size
      if DATA_TANK_ITEM[i] != nil
        tank_item = RPG::Item.new
        tank_item.menu_message = VOCAB_TANK_ITEM_MENU[i]
        tank_item.battle_message = VOCAB_TANK_ITEM_BATTLE[i]
        tank_item.type = 1
        tank_item.id = DATA_TANK_ITEM[i][0]
        tank_item.name = DATA_TANK_ITEM[i][1]
        tank_item.scope = DATA_TANK_ITEM[i][2]
        tank_item.occasion = DATA_TANK_ITEM[i][3]
        tank_item.common_event_id = DATA_TANK_ITEM[i][4]
        tank_item.price = DATA_TANK_ITEM[i][5]
        tank_item.consumable = DATA_TANK_ITEM[i][6]
        tank_item.hp_effect = DATA_TANK_ITEM[i][7]
        tank_item.hit_effect = DATA_TANK_ITEM[i][8]
        tank_item.element_set = DATA_TANK_ITEM[i][9]
        tank_item.plus_state_set = DATA_TANK_ITEM[i][10]
        tank_item.minus_state_set = DATA_TANK_ITEM[i][11]
      end
      temp_ary.push(tank_item)
    end
    return temp_ary
  end
end