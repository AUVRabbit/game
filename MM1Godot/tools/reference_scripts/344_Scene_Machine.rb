class Scene_Machine
  
  include MM_DataBase
  
  def main
    
    case $game_temp.machine_type
    when MACHINETYPE_LIFT
      main_machine_lift
    when MACHINETYPE_EXP
      main_machine_exp
    when MACHINETYPE_SWITCH
      main_machine_switch
    when MACHINETYPE_PASSWORD
      main_machine_password
    end
    
  end
end