module MM_DataBase
  
  DATA_INITIALIZE_TANKPOSITION = {
    #id    坐标  地图编号 文件名
    1 =>   [8, 6, 1, "Tank_1"],
    2 =>   [8, 7, 1, "Tank_2"],
    3 =>   [8, 8, 1, "Tank_3"],
    4 =>   [6, 6, 1, "Tank_4"],
    5 =>   [6, 7, 1, "Tank_5"],
    6 =>   [6, 8, 1, "Tank_6"],
    7 =>   [4, 7, 1, "Tank_7"],
    8 =>   [4, 8, 1, "Tank_8"],
  }
  
  DATA_RENT_TANK = [
  nil,
  [1,  "R-轻型坦克",  "Tank_1",  0,    "Tank1.png", 0, true, 1,   1,   1,  1,  1, 1],
  [2,  "R-吉普车",    "Tank_2",  0,    "Tank2.png", 0, true, 1,   1,   1,  1,  1, 2],
  [3,  "R-救护车",    "Tank_3",  0,    "Tank3.png", 0, true, 1,   1,   1,  1,  1, 3],
  [4,  "R-装甲车",    "Tank_4",  0,    "Tank4.png", 0, true, 1,   1,   1,  1,  1, 4],
  [5,  "R-野战坦克",    "Tank_5",  0,    "Tank5.png", 0, true, 1,   1,   1,  1,  1, 5],
  [6,  "R-中型坦克",    "Tank_6",  0,    "Tank6.png", 0, true, 1,   1,   1,  1,  1, 6],
  [7,  "R-红狼战车",    "Tank_7",  0,    "Tank7.png", 0, true, 1,   1,   1,  1,  1, 7],
  [8,  "R-重型坦克",    "Tank_8",  0,    "Tank8.png", 0, true, 1,   1,   1,  1,  1, 8],
  ]
  
  DATA_RENT_TANK_LIST = {
  # 編號  出租戰車id
  1 => [1, 2],
  2 => [1, 2, 3]
  }
  
  DATA_SPECIAL_CANNONBALL_LIST = {
  # 编号  炮弹id
  1 => [1, 2, 3, 4, 5]
  }
  
  DATA_SUB_CANNON_CANNONBALL_PRICE = {
  1 => 0,
  }
  
  DATA_SE_CANNONBALL_PRICE = {
  # 编号  价格
  1 => 20,
  2 => 30
  }
  
end