/* 纸娃娃生成器 v2 - 主应用 */

const State = {
  preset: 'warrior',
  parts: {},
  colors: {},
  pose: 'idle',
  animate: true,
  animSpeed: 1,
  flipH: false,
  scale: 1
};

// 姿态定义（含关键帧动画）
const Poses = {
  idle:  { name:'站立', frames:[{}] },
  walk:  { name:'行走', frames:[
    { leg_l:{r:-15}, leg_r:{r:10}, arm_l:{r:10}, arm_r:{r:-10} },
    { leg_l:{r:0},   leg_r:{r:0},  arm_l:{r:0},  arm_r:{r:0} },
    { leg_l:{r:10},  leg_r:{r:-15},arm_l:{r:-10},arm_r:{r:10} },
    { leg_l:{r:0},   leg_r:{r:0},  arm_l:{r:0},  arm_r:{r:0} }
  ], duration: 0.5 },
  run:   { name:'奔跑', frames:[
    { leg_l:{r:-30,ty:2}, leg_r:{r:20,ty:-2}, arm_l:{r:25}, arm_r:{r:-25}, body:{r:5} },
    { leg_l:{r:10,ty:4},  leg_r:{r:-25,ty:-3},arm_l:{r:-20},arm_r:{r:20}, body:{r:3} },
    { leg_l:{r:20,ty:-2}, leg_r:{r:-30,ty:2},  arm_l:{r:-25},arm_r:{r:25}, body:{r:-2} },
    { leg_l:{r:-25,ty:-3},leg_r:{r:10,ty:4},  arm_l:{r:20}, arm_r:{r:-20}, body:{r:2} }
  ], duration: 0.35 },
  attack:{ name:'攻击', frames:[
    { arm_r:{r:-30,ty:5},  body:{r:5},  leg_l:{r:-5}, leg_r:{r:5} },
    { arm_r:{r:60,ty:-12}, body:{r:-10},leg_l:{r:15},leg_r:{r:-10} },
    { arm_r:{r:30,ty:-5},  body:{r:-5}, leg_l:{r:10},leg_r:{r:-5} },
    { arm_r:{r:0},         body:{r:0},  leg_l:{r:0},  leg_r:{r:0} }
  ], duration: 0.4 },
  hit:   { name:'受击', frames:[
    { body:{r:12}, arm_l:{r:30}, arm_r:{r:-30}, head:{r:15} },
    { body:{r:5},  arm_l:{r:15}, arm_r:{r:-15}, head:{r:8} },
    { body:{r:-3}, arm_l:{r:-5}, arm_r:{r:5},   head:{r:-5} },
    { body:{r:0},  arm_l:{r:0},  arm_r:{r:0},   head:{r:0} }
  ], duration: 0.3 },
  jump:  { name:'跳跃', frames:[
    { leg_l:{r:20,ty:5},  leg_r:{r:-20,ty:5},  body:{ty:3},  arm_l:{r:20}, arm_r:{r:-20} },
    { leg_l:{r:-10,ty:-3},leg_r:{r:10,ty:-3},  body:{ty:-8}, arm_l:{r:-30},arm_r:{r:30} },
    { leg_l:{r:-30,ty:-8},leg_r:{r:30,ty:-8},  body:{ty:-15},arm_l:{r:-50},arm_r:{r:50} },
    { leg_l:{r:-15,ty:-3},leg_r:{r:15,ty:-3},  body:{ty:-5}, arm_l:{r:-20},arm_r:{r:20} }
  ], duration: 0.5 }
};

// 初始化
document.addEventListener('DOMContentLoaded', () => {
  buildPresets();
  buildPoseBar();
  buildPoseSelect();
  buildColorsPanel();
  buildPartSelectors();
  bindEvents();
  applyPreset('warrior');
});

/* ========== UI 构建 ========== */

function buildPresets() {
  const el = document.getElementById('presets-list');
  el.innerHTML = '<h3>✨ 预设角色</h3>';
  Object.entries(Presets).forEach(([key, p]) => {
    const div = document.createElement('div');
    div.className = 'preset-card';
    div.dataset.preset = key;
    div.innerHTML = `
      <div class="preset-emoji">${p.icon}</div>
      <div class="preset-name">${p.name}</div>
      <div class="preset-desc">${p.desc}</div>
    `;
    div.addEventListener('click', () => applyPreset(key));
    el.appendChild(div);
  });
}

function buildPoseBar() {
  const el = document.getElementById('pose-bar');
  el.innerHTML = '';
  Object.entries(Poses).forEach(([key, p]) => {
    const chip = document.createElement('div');
    chip.className = 'pose-chip' + (key === State.pose ? ' active' : '');
    chip.textContent = p.name;
    chip.dataset.pose = key;
    chip.addEventListener('click', () => setPose(key));
    el.appendChild(chip);
  });
}

function buildPoseSelect() {
  const el = document.getElementById('pose-select');
  el.innerHTML = '';
  Object.entries(Poses).forEach(([key, p]) => {
    const btn = document.createElement('div');
    btn.className = 'pose-btn' + (key === State.pose ? ' active' : '');
    btn.textContent = p.name;
    btn.dataset.pose = key;
    btn.addEventListener('click', () => setPose(key));
    el.appendChild(btn);
  });
}

function buildColorsPanel() {
  const el = document.getElementById('colors-panel');
  el.innerHTML = '';
  const colorKeys = [
    ['skin','皮肤'],['hair','头发'],['eye','眼睛'],
    ['body','上衣'],['pants','下装'],['metal','金属'],
    ['accent','点缀'],['gold','金色']
  ];
  colorKeys.forEach(([key, label]) => {
    const row = document.createElement('div');
    row.className = 'color-row';
    row.innerHTML = `<label>${label}</label><input type="color" data-key="${key}" value="${State.colors[key] || '#888'}">`;
    const input = row.querySelector('input');
    input.addEventListener('input', (e) => {
      State.colors[key] = e.target.value;
      applyColorShades();
      render();
    });
    el.appendChild(row);
  });
}

function buildPartSelectors() {
  const el = document.getElementById('current-parts');
  el.innerHTML = '';
  PartCategories.forEach(cat => {
    const section = document.createElement('div');
    section.style.marginBottom = '12px';
    
    const title = document.createElement('div');
    title.className = 'section-title';
    const currentId = State.parts[cat.id];
    const currentName = (PartOptions[cat.id] || []).find(o => o.id === currentId)?.name || '-';
    title.innerHTML = `<span>${cat.name}</span><span class="curr">${currentName}</span>`;
    section.appendChild(title);

    const grid = document.createElement('div');
    grid.className = 'options-grid';
    (PartOptions[cat.id] || []).forEach(opt => {
      const div = document.createElement('div');
      div.className = 'opt' + (currentId === opt.id ? ' active' : '');
      div.dataset.cat = cat.id;
      div.dataset.opt = opt.id;
      div.innerHTML = `<svg viewBox="0 0 100 100">${renderPartSvg(cat.id, opt.id, 0)}</svg><div class="opt-label">${opt.name}</div>`;
      div.addEventListener('click', () => {
        State.parts[cat.id] = opt.id;
        render();
        buildPartSelectors();
      });
      grid.appendChild(div);
    });
    section.appendChild(grid);
    el.appendChild(section);
  });
}

function bindEvents() {
  document.getElementById('anim-toggle').addEventListener('change', (e) => {
    State.animate = e.target.checked;
    render();
  });
  document.getElementById('anim-speed').addEventListener('input', (e) => {
    State.animSpeed = parseFloat(e.target.value);
    render();
  });
  document.getElementById('flip-h').addEventListener('change', (e) => {
    State.flipH = e.target.checked;
    render();
  });
  document.getElementById('scale').addEventListener('input', (e) => {
    State.scale = parseFloat(e.target.value);
    render();
  });
  document.getElementById('btn-random-colors').addEventListener('click', () => {
    randomizeColors();
  });
  document.getElementById('btn-random').addEventListener('click', () => {
    const keys = Object.keys(Presets);
    applyPreset(keys[Math.floor(Math.random() * keys.length)]);
    randomizeColors();
  });
  document.getElementById('btn-export-png').addEventListener('click', exportPNG);
  document.getElementById('btn-export-svg').addEventListener('click', exportSVG);
}

/* ========== 状态操作 ========== */

function applyPreset(key) {
  State.preset = key;
  const p = Presets[key];
  State.parts = { ...p.parts };
  State.colors = { ...p.colors };
  
  document.querySelectorAll('.preset-card').forEach(c => {
    c.classList.toggle('active', c.dataset.preset === key);
  });
  
  render();
  buildPartSelectors();
  buildColorsPanel();
}

function setPose(key) {
  State.pose = key;
  document.querySelectorAll('.pose-chip').forEach(c => c.classList.toggle('active', c.dataset.pose === key));
  document.querySelectorAll('.pose-btn').forEach(b => b.classList.toggle('active', b.dataset.pose === key));
  render();
}

/* ========== 颜色处理 ========== */

function applyColorShades() {
  // 基于基础色生成阴影/高光
  const shadeMap = {
    skin: { shade:'skinShadow', highlight:'skinHighlight' },
    hair: { shade:'hairShadow', highlight:'hairHighlight' },
    eye: {},
    body: { shade:'bodyShadow', highlight:'bodyHighlight' },
    pants: { shade:'pantsShadow', highlight:'pantsHighlight' },
    boot: { shade:'bootShadow', highlight:'bootHighlight' },
    metal: { shade:'metalShadow', highlight:'metalHighlight' },
    accent: { shade:'accentShadow', highlight:'accentHighlight' },
    gold: { shade:'goldShadow', highlight:'goldHighlight' }
  };
  Object.entries(shadeMap).forEach(([base, shades]) => {
    if (State.colors[base] && shades.shade && shades.highlight) {
      State.colors[shades.shade] = darken(State.colors[base], 0.25);
      State.colors[shades.highlight] = lighten(State.colors[base], 0.25);
    }
  });
}

function darken(hex, amount) {
  const c = hexToRgb(hex);
  return rgbToHex(
    Math.round(c.r * (1-amount)),
    Math.round(c.g * (1-amount)),
    Math.round(c.b * (1-amount))
  );
}
function lighten(hex, amount) {
  const c = hexToRgb(hex);
  return rgbToHex(
    Math.round(c.r + (255-c.r) * amount),
    Math.round(c.g + (255-c.g) * amount),
    Math.round(c.b + (255-c.b) * amount)
  );
}
function hexToRgb(hex) {
  const h = hex.replace('#','');
  return {
    r: parseInt(h.substr(0,2),16),
    g: parseInt(h.substr(2,2),16),
    b: parseInt(h.substr(4,2),16)
  };
}
function rgbToHex(r,g,b) {
  return '#' + [r,g,b].map(x => Math.max(0,Math.min(255,x)).toString(16).padStart(2,'0')).join('');
}

function randomizeColors() {
  const keys = ['skin','hair','eye','body','pants','metal','accent','gold'];
  keys.forEach(k => {
    State.colors[k] = randomHex();
  });
  applyColorShades();
  buildColorsPanel();
  render();
}

function randomHex() {
  const h = Math.floor(Math.random() * 360);
  const s = 50 + Math.floor(Math.random() * 30);
  const l = 40 + Math.floor(Math.random() * 30);
  // HSL转HEX
  const a = s/100 * Math.min(l/100, 1-l/100);
  const f = n => {
    const k = (n + h/30) % 12;
    const color = l/100 - a * Math.max(Math.min(k-3, 9-k, 1), -1);
    return Math.round(255*color).toString(16).padStart(2,'0');
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

/* ========== 渲染 ========== */

// 部件到部位名的映射（用于姿态动画）
const PartBoneMap = {
  arms: { normal:{ arm_l:'arm-l', arm_r:'arm-r' }, armored:{ arm_l:'arm-l', arm_r:'arm-r' }, robe:{ arm_l:'arm-l', arm_r:'arm-r' }, claw:{ arm_l:'arm-l', arm_r:'arm-r' } },
  legs: { pants:{ leg_l:'leg-l', leg_r:'leg-r' }, armor:{ leg_l:'leg-l', leg_r:'leg-r' }, skirt:{ leg_l:'leg-l', leg_r:'leg-r' } }
};

function render() {
  const svg = document.getElementById('char-svg');
  svg.innerHTML = '';

  const c = State.colors;
  const order = ['extra','body','arms','legs','footwear','weapon','head','face','hair'];

  order.forEach(cat => {
    const partId = State.parts[cat];
    if (!partId || partId === 'none') return;
    const gen = PartsLibrary[cat]?.[partId];
    if (!gen) return;

    const wrapper = document.createElement('g');
    wrapper.innerHTML = gen(c);
    // 为所有 <g> 元素根据 class 添加 bone 标识
    wrapper.querySelectorAll('g').forEach(g => {
      const cls = g.className.baseVal || g.className || '';
      if (typeof cls === 'string') {
        if (cls.includes('arm-l')) g.classList.add('bone-arm_l');
        if (cls.includes('arm-r')) g.classList.add('bone-arm_r');
        if (cls.includes('leg-l')) g.classList.add('bone-leg_l');
        if (cls.includes('leg-r')) g.classList.add('bone-leg_r');
        if (cls.includes('body')) g.classList.add('bone-body');
        if (cls.includes('head')) g.classList.add('bone-head');
      }
    });
    while (wrapper.firstElementChild) svg.appendChild(wrapper.firstElementChild);
  });

  // 应用整体变换
  const scale = State.scale * (State.flipH ? -1 : 1);
  const mainGroup = document.createElement('g');
  const children = [...svg.children];
  children.forEach(ch => mainGroup.appendChild(ch));
  svg.appendChild(mainGroup);
  mainGroup.setAttribute('transform', `translate(100,150) scale(${scale},${State.scale}) translate(-100,-150)`);

  // 设置CSS变量动画
  applyPoseToSvg(svg);
}

function applyPoseToSvg(svg) {
  const pose = Poses[State.pose];
  if (!pose || !State.animate || !pose.frames || pose.frames.length <= 1) {
    // 清除动画
    const styleTag = document.getElementById('pose-anim');
    if (styleTag) styleTag.textContent = '';
    return;
  }

  const duration = (pose.duration || 0.5) / State.animSpeed;
  const frames = pose.frames;
  const boneClasses = ['arm_l','arm_r','leg_l','leg_r','body','head'];

  let css = '';
  boneClasses.forEach(bone => {
    css += `@keyframes anim-${bone} {\n`;
    frames.forEach((frame, i) => {
      const pct = (i / (frames.length - 1)) * 100;
      const t = frame[bone];
      let transform = '';
      if (t) {
        if (t.r) transform += `rotate(${t.r}deg) `;
        if (t.tx) transform += `translateX(${t.tx}px) `;
        if (t.ty) transform += `translateY(${t.ty}px) `;
      }
      css += `  ${pct}% { transform: ${transform.trim() || 'none'}; }\n`;
    });
    css += '}\n';
  });

  let styleTag = document.getElementById('pose-anim');
  if (!styleTag) {
    styleTag = document.createElement('style');
    styleTag.id = 'pose-anim';
    document.head.appendChild(styleTag);
  }
  styleTag.textContent = css;

  // 为每个骨骼应用动画
  boneClasses.forEach(bone => {
    const els = svg.querySelectorAll(`.bone-${bone}`);
    els.forEach(el => {
      el.style.transformOrigin = 'center bottom';
      el.style.transformBox = 'fill-box';
      el.style.animation = `anim-${bone} ${duration}s ease-in-out infinite`;
    });
  });
}

// 缩略图渲染（用于选项卡片）
function renderPartSvg(cat, partId, scale) {
  const gen = PartsLibrary[cat]?.[partId];
  if (!gen) return '';
  const colors = { ...PartsLibrary.defaults, ...Presets.warrior.colors };
  return gen(colors);
}

/* ========== 导出 ========== */

function exportSVG() {
  const svg = document.getElementById('char-svg');
  // 先停止动画
  const els = svg.querySelectorAll('[style*="animation"]');
  const prevStyles = [];
  els.forEach(el => { prevStyles.push(el.style.cssText); el.style.animation = 'none'; });
  
  const svgEl = svg.cloneNode(true);
  // 移除 style attribute 动画
  svgEl.querySelectorAll('[style*="animation"]').forEach(el => el.style.animation = 'none');
  
  const data = new XMLSerializer().serializeToString(svgEl);
  const blob = new Blob([data], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = `doll-${State.preset}-${Date.now()}.svg`;
  a.click();
  URL.revokeObjectURL(url);
  
  // 恢复动画
  els.forEach((el, i) => { el.style.cssText = prevStyles[i]; });
}

function exportPNG() {
  const svg = document.getElementById('char-svg');
  const svgEl = svg.cloneNode(true);
  svgEl.querySelectorAll('[style*="animation"]').forEach(el => el.style.animation = 'none');
  
  const data = new XMLSerializer().serializeToString(svgEl);
  const blob = new Blob([data], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  
  const img = new Image();
  img.onload = () => {
    const canvas = document.createElement('canvas');
    const scale = 3;
    canvas.width = 200 * scale;
    canvas.height = 300 * scale;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.scale(scale, scale);
    ctx.drawImage(img, 0, 0);
    
    canvas.toBlob((b) => {
      const pngUrl = URL.createObjectURL(b);
      const a = document.createElement('a');
      a.href = pngUrl; a.download = `doll-${State.preset}-${Date.now()}.png`;
      a.click();
      URL.revokeObjectURL(pngUrl);
      URL.revokeObjectURL(url);
    }, 'image/png');
  };
  img.src = url;
}
