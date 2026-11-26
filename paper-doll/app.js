/* ============================================
   纸娃娃生成器 - 主应用逻辑
   ============================================ */

// 应用状态
const State = {
  parts: {
    head: 'basic',
    hair: 'short',
    face: 'normal',
    body: 'basic',
    arms: 'basic',
    legs: 'pants',
    footwear: 'basic',
    weapon: 'none',
    accessory: 'none',
    monster: 'none'
  },
  colors: { ...PartsLibrary.defaults },
  pose: 'idle',
  animate: true,
  animSpeed: 1,
  flipH: false,
  scale: 1,
  posX: 0,
  posY: 0,
  currentFrame: 0,
  activeCategory: 'head',
  animFrame: null
};

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
  initCategories();
  initColorControls();
  initPresets();
  initPartOptions();
  initEventListeners();
  initPosePreviews();
  renderCharacter();
  updateTimeline();
});

/* ============================================
   UI初始化
   ============================================ */

function initCategories() {
  const container = document.getElementById('body-categories');
  container.innerHTML = '';
  
  PartsLibrary.categories.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = 'category-btn' + (cat.id === State.activeCategory ? ' active' : '');
    btn.innerHTML = `<span class="category-icon">${cat.icon}</span><span>${cat.name}</span>`;
    btn.dataset.category = cat.id;
    btn.addEventListener('click', () => {
      State.activeCategory = cat.id;
      initPartOptions();
      // 更新按钮状态
      container.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
    container.appendChild(btn);
  });
}

function initColorControls() {
  const container = document.getElementById('color-controls');
  const colorLabels = {
    skinColor: '皮肤颜色',
    hairColor: '头发/兽毛',
    eyeColor: '眼睛颜色',
    bodyColor: '上衣/躯干',
    pantsColor: '裤子/下装',
    shoeColor: '鞋子',
    weaponColor: '武器',
    accessoryColor: '饰品/金属'
  };
  
  container.innerHTML = '';
  Object.keys(colorLabels).forEach(key => {
    const row = document.createElement('div');
    row.className = 'color-row';
    row.innerHTML = `
      <label>${colorLabels[key]}</label>
      <input type="color" value="${State.colors[key]}" data-color="${key}">
    `;
    row.querySelector('input').addEventListener('input', (e) => {
      State.colors[key] = e.target.value;
      renderCharacter();
    });
    container.appendChild(row);
  });
}

function initPresets() {
  const container = document.getElementById('presets-grid');
  container.innerHTML = '';
  
  Object.entries(Presets).forEach(([key, preset]) => {
    const card = document.createElement('div');
    card.className = 'preset-card';
    card.innerHTML = `
      <div class="preset-icon">${preset.icon}</div>
      <div class="preset-name">${preset.name}</div>
    `;
    card.addEventListener('click', () => applyPreset(key));
    container.appendChild(card);
  });
}

function initPartOptions() {
  const container = document.getElementById('part-options');
  const title = document.getElementById('detail-title');
  const category = State.activeCategory;
  
  const catInfo = PartsLibrary.categories.find(c => c.id === category);
  title.textContent = `${catInfo.icon} ${catInfo.name}`;
  
  const options = PartOptions[category] || [];
  container.innerHTML = '';
  
  options.forEach(opt => {
    const card = document.createElement('div');
    card.className = 'option-card' + (State.parts[category] === opt.id ? ' selected' : '');
    card.innerHTML = `
      ${generatePartThumbnail(category, opt.id)}
      <span class="option-name">${opt.name}</span>
    `;
    card.addEventListener('click', () => {
      State.parts[category] = opt.id;
      initPartOptions(); // 刷新选中状态
      renderCharacter();
      updateTimeline();
    });
    container.appendChild(card);
  });
}

function generatePartThumbnail(category, partId) {
  const generator = PartsLibrary[category] && PartsLibrary[category][partId];
  if (!generator) return '<span style="color:#666">—</span>';
  
  // 为缩略图使用简化的颜色
  const colors = { ...PartsLibrary.defaults };
  
  let content = '';
  try {
    content = generator(colors);
  } catch(e) {
    content = '';
  }
  
  return `<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
    ${content}
  </svg>`;
}

/* ============================================
   事件监听
   ============================================ */

function initEventListeners() {
  // 角色类型切换
  document.getElementById('character-type').addEventListener('change', (e) => {
    if (e.target.value === 'monster') {
      // 切换到怪物预设
      applyPreset('slime');
    } else {
      applyPreset('warrior');
    }
  });
  
  // 姿态选择
  document.getElementById('pose-type').addEventListener('change', (e) => {
    State.pose = e.target.value;
    renderCharacter();
    updateTimeline();
    updatePoseIndicator();
  });
  
  // 动画开关
  document.getElementById('animate-toggle').addEventListener('change', (e) => {
    State.animate = e.target.checked;
    renderCharacter();
  });
  
  // 动画速度
  document.getElementById('anim-speed').addEventListener('input', (e) => {
    State.animSpeed = parseFloat(e.target.value);
    renderCharacter();
  });
  
  // 水平翻转
  document.getElementById('flip-h').addEventListener('change', (e) => {
    State.flipH = e.target.checked;
    renderCharacter();
  });
  
  // 缩放
  document.getElementById('scale').addEventListener('input', (e) => {
    State.scale = parseFloat(e.target.value);
    renderCharacter();
  });
  
  // 位置
  document.getElementById('pos-x').addEventListener('input', (e) => {
    State.posX = parseInt(e.target.value);
    renderCharacter();
  });
  
  document.getElementById('pos-y').addEventListener('input', (e) => {
    State.posY = parseInt(e.target.value);
    renderCharacter();
  });
  
  // 随机颜色
  document.getElementById('btn-random-colors').addEventListener('click', randomizeColors);
  
  // 随机生成
  document.getElementById('btn-random').addEventListener('click', randomizeCharacter);
  
  // 重置
  document.getElementById('btn-reset').addEventListener('click', resetCharacter);
  
  // 导出PNG
  document.getElementById('btn-export-png').addEventListener('click', exportPNG);
  
  // 导出SVG
  document.getElementById('btn-export-svg').addEventListener('click', exportSVG);
  
  // 帧控制
  document.getElementById('btn-prev-frame').addEventListener('click', () => {
    const pose = PoseSystem.poses[State.pose];
    if (pose && pose.keyframes) {
      State.currentFrame = (State.currentFrame - 1 + pose.keyframes.frames.length) % pose.keyframes.frames.length;
      renderCharacter();
      updateFrameInfo();
      updateTimeline();
    }
  });
  
  document.getElementById('btn-next-frame').addEventListener('click', () => {
    const pose = PoseSystem.poses[State.pose];
    if (pose && pose.keyframes) {
      State.currentFrame = (State.currentFrame + 1) % pose.keyframes.frames.length;
      renderCharacter();
      updateFrameInfo();
      updateTimeline();
    }
  });
}

/* ============================================
   角色渲染
   ============================================ */

function renderCharacter() {
  const svg = document.getElementById('character-svg');
  svg.innerHTML = '';
  
  // 构建部件顺序（从后到前）
  const renderOrder = ['monster', 'body', 'legs', 'footwear', 'arms', 'weapon', 'accessory', 'head', 'face', 'hair'];
  
  // 根据部位生成SVG
  renderOrder.forEach(category => {
    const partId = State.parts[category];
    const generator = PartsLibrary[category] && PartsLibrary[category][partId];
    if (!generator || partId === 'none') return;
    
    const svgContent = generator(State.colors);
    const wrapper = document.createElement('g');
    wrapper.innerHTML = svgContent;
    // 提取内部的group（它们带有class）
    while (wrapper.firstElementChild) {
      svg.appendChild(wrapper.firstElementChild);
    }
  });
  
  // 应用姿态变换
  applyPoseTransforms();
  
  // 应用整体变换（缩放、翻转、位置）
  const transformGroup = document.createElement('g');
  let scaleX = State.flipH ? -State.scale : State.scale;
  
  // 将整个SVG内容包裹在变换组中
  const children = [...svg.children];
  children.forEach(child => transformGroup.appendChild(child));
  svg.appendChild(transformGroup);
  
  // 重置位置（viewBox是200x300，所以中心是100,150）
  transformGroup.setAttribute('transform', 
    `translate(${100 + State.posX}, ${150 + State.posY}) scale(${scaleX}, ${State.scale}) translate(-100, -150)`);
  
  // 添加动画类
  svg.classList.toggle('animate', State.animate && PoseSystem.poses[State.pose]?.keyframes);
  
  // 应用动画速度
  if (State.animate && PoseSystem.poses[State.pose]?.keyframes) {
    applyAnimation();
  }
}

function applyPoseTransforms() {
  const svg = document.getElementById('character-svg');
  const pose = PoseSystem.poses[State.pose];
  
  if (!pose || !pose.keyframes || State.animate) return;
  
  // 单帧模式 - 应用当前帧的变换
  const frameData = PoseSystem.getFrameData(State.pose, State.currentFrame);
  
  svg.querySelectorAll('.part-group').forEach(group => {
    const classNames = group.className.baseVal || '';
    let transform = '';
    
    // 检查类名是否匹配关键帧中的部件名
    Object.keys(frameData).forEach(partName => {
      if (classNames.includes(partName)) {
        const data = frameData[partName];
        if (data.rotate) transform += `rotate(${data.rotate}deg) `;
        if (data.tx) transform += `translateX(${data.tx}px) `;
        if (data.ty) transform += `translateY(${data.ty}px) `;
      }
    });
    
    if (transform) {
      group.setAttribute('transform', transform.trim());
    }
  });
}

function applyAnimation() {
  const pose = PoseSystem.poses[State.pose];
  if (!pose || !pose.keyframes) return;
  
  const duration = pose.keyframes.duration / State.animSpeed;
  
  // 为每个部件应用CSS动画
  document.querySelectorAll('#character-svg .part-group').forEach(group => {
    const classNames = group.className.baseVal || '';
    
    // 查找匹配的关键帧
    let matchedAnim = null;
    Object.keys(pose.keyframes.frames[0]).forEach(partName => {
      if (classNames.includes(partName)) {
        matchedAnim = partName;
      }
    });
    
    if (matchedAnim) {
      const keyframeData = generateInlineKeyframes(pose.keyframes, matchedAnim);
      group.style.animation = `${keyframeData.name} ${duration}s ease-in-out infinite`;
    } else {
      group.style.animation = 'none';
    }
  });
}

function generateInlineKeyframes(keyframes, partName) {
  const frames = keyframes.frames;
  const animName = `anim-${partName}-${Date.now()}-${Math.random().toString(36).substr(2,5)}`;
  
  let css = `@keyframes ${animName} {\n`;
  frames.forEach((frame, i) => {
    const pct = (i / (frames.length - 1)) * 100;
    const data = frame[partName] || {};
    let transform = '';
    if (data.rotate) transform += `rotate(${data.rotate}deg) `;
    if (data.tx) transform += `translateX(${data.tx}px) `;
    if (data.ty) transform += `translateY(${data.ty}px) `;
    if (!transform) transform = 'none';
    css += `  ${pct}% { transform: ${transform.trim()}; }\n`;
  });
  css += '}';
  
  // 注入到style标签
  let styleTag = document.getElementById('dynamic-keyframes');
  if (!styleTag) {
    styleTag = document.createElement('style');
    styleTag.id = 'dynamic-keyframes';
    document.head.appendChild(styleTag);
  }
  styleTag.textContent += css;
  
  return { name: animName };
}

/* ============================================
   姿态指示和预览
   ============================================ */

function updatePoseIndicator() {
  const indicator = document.getElementById('pose-indicator');
  const pose = PoseSystem.poses[State.pose];
  if (pose) {
    indicator.innerHTML = `<span class="pose-icon">${pose.icon}</span><span class="pose-name">${pose.name}</span>`;
  }
}

function initPosePreviews() {
  const container = document.getElementById('pose-preview-row');
  container.querySelectorAll('.preview-item').forEach(item => {
    item.addEventListener('click', () => {
      const pose = item.dataset.pose;
      State.pose = pose;
      document.getElementById('pose-type').value = pose;
      updatePoseIndicator();
      // 更新选中状态
      container.querySelectorAll('.preview-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      renderCharacter();
      updateTimeline();
    });
  });
}

/* ============================================
   时间轴
   ============================================ */

function updateTimeline() {
  const container = document.getElementById('timeline-frames');
  const frameInfo = document.getElementById('frame-info');
  const pose = PoseSystem.poses[State.pose];
  
  container.innerHTML = '';
  
  if (!pose || !pose.keyframes) {
    frameInfo.textContent = '无动画';
    return;
  }
  
  const frames = pose.keyframes.frames;
  frameInfo.textContent = `帧 ${State.currentFrame + 1} / ${frames.length}`;
  
  frames.forEach((_, i) => {
    const frameDiv = document.createElement('div');
    frameDiv.className = 'timeline-frame' + (i === State.currentFrame ? ' active' : '');
    
    // 生成该帧的简化SVG预览
    const colors = { ...PartsLibrary.defaults };
    let content = '';
    
    // 简化预览：只显示身体和四肢
    content += PartsLibrary.body.basic(colors);
    content += PartsLibrary.legs.pants(colors);
    content += PartsLibrary.arms.basic(colors);
    content += PartsLibrary.head.basic(colors);
    
    const frameData = frames[i];
    let transforms = '';
    Object.keys(frameData).forEach(part => {
      const data = frameData[part];
      if (data.rotate) transforms += ` ${part} { transform: rotate(${data.rotate}deg); }`;
    });
    
    frameDiv.innerHTML = `<svg viewBox="0 0 200 300">${content}</svg>`;
    frameDiv.addEventListener('click', () => {
      State.currentFrame = i;
      document.getElementById('animate-toggle').checked = false;
      State.animate = false;
      renderCharacter();
      updateTimeline();
      updateFrameInfo();
    });
    container.appendChild(frameDiv);
  });
}

function updateFrameInfo() {
  const frameInfo = document.getElementById('frame-info');
  const pose = PoseSystem.poses[State.pose];
  if (pose && pose.keyframes) {
    frameInfo.textContent = `帧 ${State.currentFrame + 1} / ${pose.keyframes.frames.length}`;
  }
}

/* ============================================
   预设和随机
   ============================================ */

function applyPreset(presetKey) {
  const preset = Presets[presetKey];
  if (!preset) return;
  
  State.parts = { ...preset.parts };
  State.colors = { ...preset.colors };
  
  // 更新UI
  initColorControls();
  initPartOptions();
  renderCharacter();
  updateTimeline();
}

function randomizeCharacter() {
  const categories = Object.keys(PartsLibrary).filter(k => k !== 'defaults');
  
  categories.forEach(cat => {
    const options = PartOptions[cat];
    if (options && options.length > 0) {
      const randomOption = options[Math.floor(Math.random() * options.length)];
      State.parts[cat] = randomOption.id;
    }
  });
  
  randomizeColors();
  renderCharacter();
  initPartOptions();
}

function randomizeColors() {
  const colorKeys = Object.keys(State.colors);
  colorKeys.forEach(key => {
    if (Math.random() > 0.3) {
      State.colors[key] = randomColor();
    }
  });
  
  // 更新UI颜色选择器
  document.querySelectorAll('#color-controls input[type="color"]').forEach(input => {
    input.value = State.colors[input.dataset.color];
  });
  
  renderCharacter();
}

function randomColor() {
  const hue = Math.floor(Math.random() * 360);
  const saturation = Math.floor(Math.random() * 40) + 30;
  const lightness = Math.floor(Math.random() * 30) + 40;
  
  // HSL转HEX
  return hslToHex(hue, saturation, lightness);
}

function hslToHex(h, s, l) {
  s /= 100;
  l /= 100;
  const a = s * Math.min(l, 1 - l);
  const f = n => {
    const k = (n + h / 30) % 12;
    const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
    return Math.round(255 * color).toString(16).padStart(2, '0');
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

function resetCharacter() {
  State.parts = {
    head: 'basic', hair: 'short', face: 'normal', body: 'basic',
    arms: 'basic', legs: 'pants', footwear: 'basic', weapon: 'none',
    accessory: 'none', monster: 'none'
  };
  State.colors = { ...PartsLibrary.defaults };
  State.pose = 'idle';
  State.scale = 1;
  State.posX = 0;
  State.posY = 0;
  State.flipH = false;
  State.animate = true;
  State.animSpeed = 1;
  State.currentFrame = 0;
  
  // 更新UI
  document.getElementById('pose-type').value = 'idle';
  document.getElementById('animate-toggle').checked = true;
  document.getElementById('anim-speed').value = 1;
  document.getElementById('flip-h').checked = false;
  document.getElementById('scale').value = 1;
  document.getElementById('pos-x').value = 0;
  document.getElementById('pos-y').value = 0;
  
  initColorControls();
  initPartOptions();
  updatePoseIndicator();
  renderCharacter();
  updateTimeline();
}

/* ============================================
   导出功能
   ============================================ */

function exportSVG() {
  const svg = document.getElementById('character-svg');
  const svgData = new XMLSerializer().serializeToString(svg);
  const blob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  
  const a = document.createElement('a');
  a.href = url;
  a.download = `character-${State.parts.head}-${State.parts.body}-${Date.now()}.svg`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function exportPNG() {
  const svg = document.getElementById('character-svg');
  const svgData = new XMLSerializer().serializeToString(svg);
  
  const img = new Image();
  const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(svgBlob);
  
  img.onload = () => {
    const canvas = document.createElement('canvas');
    const scale = 3; // 高清导出
    canvas.width = 200 * scale;
    canvas.height = 300 * scale;
    
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.scale(scale, scale);
    ctx.drawImage(img, 0, 0);
    
    canvas.toBlob((blob) => {
      const pngUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = pngUrl;
      a.download = `character-${State.parts.head}-${State.parts.body}-${Date.now()}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(pngUrl);
      URL.revokeObjectURL(url);
    }, 'image/png');
  };
  
  img.src = url;
}

/* ============================================
   初始化
   ============================================ */

// 默认应用战士预设并更新指示器
updatePoseIndicator();
