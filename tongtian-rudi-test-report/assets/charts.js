(function() {
  var style = getComputedStyle(document.documentElement);
  var accent = style.getPropertyValue('--accent').trim();
  var accent2 = style.getPropertyValue('--accent2').trim();
  var ink = style.getPropertyValue('--ink').trim();
  var muted = style.getPropertyValue('--muted').trim();
  var rule = style.getPropertyValue('--rule').trim();
  var bg2 = style.getPropertyValue('--bg2').trim();

  // --- Chart: 冒烟测试结果 ---
  var chart1 = echarts.init(document.getElementById('chart-smoke'), null, { renderer: 'svg' });
  chart1.setOption({
    tooltip: { appendToBody: true },
    animation: false,
    series: [{
      type: 'gauge',
      startAngle: 200,
      endAngle: -20,
      min: 0,
      max: 44,
      radius: '90%',
      progress: { show: true, width: 18, itemStyle: { color: accent } },
      axisLine: { lineStyle: { width: 18, color: [[1, rule]] } },
      pointer: { show: false },
      axisTick: { show: false },
      splitLine: { show: false },
      axisLabel: { show: false },
      title: { offsetCenter: [0, '80%'], fontSize: 14, color: muted },
      detail: {
        offsetCenter: [0, '5%'],
        fontSize: 52,
        fontWeight: 'bold',
        color: accent,
        formatter: '{value}'
      },
      data: [{ value: 44, name: '通过 / 总计' }]
    }]
  });
  window.addEventListener('resize', function() { chart1.resize(); });

  // --- Chart: 测试模块覆盖 ---
  var chart2 = echarts.init(document.getElementById('chart-modules'), null, { renderer: 'svg' });
  var moduleData = [
    { name: '场景/新游戏', value: 4, items: ['主世界', '队伍', '金币', '初始物资'] },
    { name: '战斗系统', value: 3, items: ['普攻', '技能释放', '冲刺冷却'] },
    { name: '经济闭环', value: 3, items: ['配方查询', '合成', '资源采集'] },
    { name: '建造系统', value: 2, items: ['放置建筑', '拆除建筑'] },
    { name: 'UI状态', value: 2, items: ['背包暂停', '关闭恢复'] },
    { name: '存档读写', value: 2, items: ['写入', '读档恢复'] },
    { name: '职业系统', value: 3, items: ['Q/P切换', '祭坛解锁', '法师弹道'] },
    { name: 'NPC/任务', value: 2, items: ['对话打开', '接取任务'] },
    { name: '朋克改造', value: 8, items: ['部件加载', '安装', '卸下', '风格判定', '属性生效', '职业专属', '风格匹配', '存档恢复'] },
    { name: '塔层/Roguelike', value: 5, items: ['进入1层', '机关开门', 'Roguelike激活', '进入2层', '进入深渊-1'] }
  ];
  chart2.setOption({
    tooltip: { appendToBody: true, formatter: function(p) {
      var data = moduleData[p.dataIndex];
      return '<strong>' + data.name + '</strong><br/>覆盖: ' + data.items.join('、');
    }},
    animation: false,
    grid: { left: 110, right: 30, top: 30, bottom: 30 },
    xAxis: { type: 'value', min: 0, max: 10, splitLine: { lineStyle: { color: rule } }, axisLabel: { color: muted }, axisLine: { show: false }, axisTick: { show: false } },
    yAxis: { type: 'category', data: moduleData.map(function(d){ return d.name; }).reverse(), axisLabel: { color: ink, fontWeight: 500 }, axisLine: { show: false }, axisTick: { show: false } },
    series: [{
      type: 'bar',
      data: moduleData.map(function(d){ return d.value; }).reverse(),
      itemStyle: { color: accent, borderRadius: [0, 4, 4, 0] },
      label: { show: true, position: 'right', color: ink, fontWeight: 'bold' },
      barWidth: 18
    }]
  });
  window.addEventListener('resize', function() { chart2.resize(); });

  // --- Chart: 数据资源统计 ---
  var chart3 = echarts.init(document.getElementById('chart-data'), null, { renderer: 'svg' });
  chart3.setOption({
    tooltip: { appendToBody: true },
    animation: false,
    legend: { bottom: 0, textStyle: { color: muted } },
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      avoidLabelOverlap: true,
      itemStyle: { borderColor: bg2, borderWidth: 2, borderRadius: 4 },
      label: { color: ink },
      labelLine: { lineStyle: { color: rule } },
      data: [
        { value: 25, name: '物品', itemStyle: { color: accent } },
        { value: 12, name: '职业', itemStyle: { color: accent2 } },
        { value: 15, name: '配方', itemStyle: { color: '#8a6bbf' } },
        { value: 3, name: '任务', itemStyle: { color: '#c87a3a' } },
        { value: 3, name: '对话', itemStyle: { color: '#4ad6ff' } },
        { value: 20, name: '朋克部件', itemStyle: { color: '#7a2f3f' } }
      ]
    }]
  });
  window.addEventListener('resize', function() { chart3.resize(); });

  // --- Chart: 测试时间线 ---
  var chart4 = echarts.init(document.getElementById('chart-timeline'), null, { renderer: 'svg' });
  var timelineData = [
    ['环境准备', '项目校验', '运行 validate_project.py', '0 错误 0 警告', 'success'],
    ['引擎版本', '版本确认', 'Godot 4.7.2.stable', '版本匹配', 'success'],
    ['冒烟测试', '44项用例', '无头模式运行', '44/44 PASS', 'success'],
    ['数据层', '文件结构', 'JSON 可解析', '全部加载成功', 'success'],
    ['缓存修复', '编辑器重建', '清理 .godot/ 缓存', '脚本解析恢复', 'warning']
  ];
  chart4.setOption({
    tooltip: { appendToBody: true, trigger: 'axis' },
    animation: false,
    grid: { left: 0, right: 0, top: 20, bottom: 60, containLabel: true },
    xAxis: { type: 'category', data: timelineData.map(function(d){ return d[0]; }), axisLabel: { color: ink, fontWeight: 'bold' }, axisLine: { lineStyle: { color: rule } }, axisTick: { show: false } },
    yAxis: { show: false },
    series: [{
      type: 'scatter',
      symbolSize: 20,
      data: timelineData.map(function(d){
        return { value: [d[0], 0], itemStyle: { color: d[4] === 'success' ? accent : '#c87a3a' } };
      }),
      label: {
        show: true,
        position: 'bottom',
        formatter: function(p){ var d = timelineData[p.dataIndex]; return d[2] + '\n' + d[3]; },
        color: muted,
        fontSize: 11,
        lineHeight: 14
      }
    }]
  });
  window.addEventListener('resize', function() { chart4.resize(); });
})();
