/* 纸娃娃部件库 v2 - 形象生动版
   设计规范：Q版2.5头身 | 深色外描边2px | 左上光源 | 3层色阶 */

const PartsLibrary = {
  defaults: {
    skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6',
    hair: '#3d2a1f', hairShadow: '#2a1c13', hairHighlight: '#5c3d2c',
    eye: '#3b2416', eyeWhite: '#ffffff', eyeShine: '#ffe066',
    body: '#4a6fa5', bodyShadow: '#365380', bodyHighlight: '#6b8fc5',
    pants: '#2d3748', pantsShadow: '#1a202c', pantsHighlight: '#4a5568',
    boot: '#3d2817', bootShadow: '#2a1b0e', bootHighlight: '#5c3d2c',
    metal: '#c0c0c8', metalShadow: '#8a8a92', metalHighlight: '#e4e4ec',
    accent: '#e53e3e', accentShadow: '#c53030', accentHighlight: '#fc8181',
    gold: '#d4a017', goldShadow: '#a07a12', goldHighlight: '#f5d05e',
    outline: '#1a1a2e'
  },

  /* ========= 头部与面部 ========= */
  
  head: {
    basic: (c) => `
      <!-- 脸 -->
      <g class="head">
        <ellipse cx="100" cy="48" rx="26" ry="28" fill="${c.skin}" stroke="${c.outline}" stroke-width="2.2"/>
        <!-- 脸部阴影 -->
        <path d="M82,48 Q82,72 100,74 Q118,72 118,48 Q110,68 100,70 Q90,68 82,48 Z" fill="${c.skinShadow}" opacity="0.4"/>
        <!-- 耳朵 -->
        <ellipse cx="73" cy="50" rx="4" ry="6" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="127" cy="50" rx="4" ry="6" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M73,50 Q73,54 75,55" fill="none" stroke="${c.skinShadow}" stroke-width="1"/>
        <path d="M127,50 Q127,54 125,55" fill="none" stroke="${c.skinShadow}" stroke-width="1"/>
        <!-- 颈部 -->
        <path d="M90,74 L90,85 L110,85 L110,74 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <rect x="90" y="80" width="20" height="5" fill="${c.skinShadow}" opacity="0.5"/>
      </g>
    `,
    chubby: (c) => `
      <g class="head head-chubby">
        <circle cx="100" cy="50" r="30" fill="${c.skin}" stroke="${c.outline}" stroke-width="2.2"/>
        <path d="M75,55 Q75,75 100,77 Q125,75 125,55 Q115,72 100,74 Q85,72 75,55 Z" fill="${c.skinShadow}" opacity="0.4"/>
        <!-- 圆脸蛋 -->
        <ellipse cx="82" cy="60" rx="5" ry="3" fill="${c.skinShadow}" opacity="0.6"/>
        <ellipse cx="118" cy="60" rx="5" ry="3" fill="${c.skinShadow}" opacity="0.6"/>
        <ellipse cx="73" cy="52" rx="5" ry="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="127" cy="52" rx="5" ry="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M90,78 L90,90 L110,90 L110,78 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <rect x="90" y="83" width="20" height="7" fill="${c.skinShadow}" opacity="0.5"/>
      </g>
    `,
    sharp: (c) => `
      <g class="head head-sharp">
        <path d="M74,35 Q76,18 100,15 Q124,18 126,35 Q130,55 122,75 Q100,82 78,75 Q70,55 74,35 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="2.2"/>
        <path d="M76,50 Q78,72 100,74 Q122,72 124,50 Q115,68 100,70 Q85,68 76,50 Z" fill="${c.skinShadow}" opacity="0.4"/>
        <ellipse cx="73" cy="45" rx="4" ry="6" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="127" cy="45" rx="4" ry="6" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M90,75 L90,88 L110,88 L110,75 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <rect x="90" y="82" width="20" height="6" fill="${c.skinShadow}" opacity="0.5"/>
      </g>
    `,
    skull: (c) => `
      <g class="head head-skull">
        <ellipse cx="100" cy="48" rx="26" ry="28" fill="#e8e0d0" stroke="${c.outline}" stroke-width="2.2"/>
        <ellipse cx="100" cy="48" rx="22" ry="24" fill="#d4ccbc"/>
        <!-- 牙 -->
        <path d="M88,72 L90,78 L92,72 L94,78 L96,72 L98,78 L100,72 L102,78 L104,72 L106,78 L108,72 L110,78 L112,72 Z" fill="#e8e0d0" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 鼻孔 -->
        <ellipse cx="95" cy="58" rx="1.5" ry="2.5" fill="${c.outline}"/>
        <ellipse cx="105" cy="58" rx="1.5" ry="2.5" fill="${c.outline}"/>
        <!-- 裂缝 -->
        <path d="M92,25 L96,32 L94,38 L98,45" fill="none" stroke="${c.outline}" stroke-width="1"/>
        <!-- 没有耳朵和脖子 -->
      </g>
    `
  },

  face: {
    normal: (c) => `
      <g class="face">
        <!-- 眼睛 -->
        <ellipse cx="90" cy="48" rx="5" ry="6" fill="${c.eyeWhite}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="110" cy="48" rx="5" ry="6" fill="${c.eyeWhite}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="91" cy="49" rx="3" ry="4" fill="${c.eye}"/>
        <ellipse cx="111" cy="49" rx="3" ry="4" fill="${c.eye}"/>
        <circle cx="92" cy="47" r="1.2" fill="white"/>
        <circle cx="112" cy="47" r="1.2" fill="white"/>
        <!-- 腮红 -->
        <ellipse cx="82" cy="62" rx="5" ry="3" fill="#ffb3b3" opacity="0.7"/>
        <ellipse cx="118" cy="62" rx="5" ry="3" fill="#ffb3b3" opacity="0.7"/>
        <!-- 嘴巴 -->
        <path d="M94,65 Q100,70 106,65" fill="none" stroke="${c.outline}" stroke-width="1.5" stroke-linecap="round"/>
      </g>
    `,
    happy: (c) => `
      <g class="face face-happy">
        <!-- 弯眼 -->
        <path d="M84,47 Q90,41 96,47" fill="none" stroke="${c.eye}" stroke-width="2.5" stroke-linecap="round"/>
        <path d="M104,47 Q110,41 116,47" fill="none" stroke="${c.eye}" stroke-width="2.5" stroke-linecap="round"/>
        <!-- 大笑 -->
        <path d="M90,63 Q100,74 110,63" fill="#c44569" stroke="${c.outline}" stroke-width="1.8" stroke-linejoin="round"/>
        <path d="M94,63 Q100,68 106,63" fill="${c.skinShadow}" opacity="0.3"/>
        <!-- 腮红 -->
        <ellipse cx="80" cy="60" rx="6" ry="4" fill="#ff8f8f" opacity="0.8"/>
        <ellipse cx="120" cy="60" rx="6" ry="4" fill="#ff8f8f" opacity="0.8"/>
      </g>
    `,
    angry: (c) => `
      <g class="face face-angry">
        <!-- 怒眼 -->
        <path d="M83,44 L97,49" stroke="${c.eye}" stroke-width="3" stroke-linecap="round"/>
        <path d="M117,44 L103,49" stroke="${c.eye}" stroke-width="3" stroke-linecap="round"/>
        <ellipse cx="90" cy="51" rx="4" ry="3.5" fill="${c.eye}"/>
        <ellipse cx="110" cy="51" rx="4" ry="3.5" fill="${c.eye}"/>
        <circle cx="91" cy="49" r="1" fill="white"/>
        <circle cx="111" cy="49" r="1" fill="white"/>
        <!-- 皱眉线 -->
        <path d="M83,38 L97,42" stroke="${c.outline}" stroke-width="2"/>
        <path d="M117,38 L103,42" stroke="${c.outline}" stroke-width="2"/>
        <!-- 怒嘴 -->
        <path d="M92,68 Q100,63 108,68" fill="none" stroke="${c.outline}" stroke-width="2" stroke-linecap="round"/>
        <!-- 青筋 -->
        <path d="M78,58 L76,62 M78,60 L80,63" stroke="${c.accent}" stroke-width="1.5"/>
      </g>
    `,
    sleepy: (c) => `
      <g class="face face-sleepy">
        <path d="M84,48 L96,48" stroke="${c.outline}" stroke-width="2.5" stroke-linecap="round"/>
        <path d="M104,48 L116,48" stroke="${c.outline}" stroke-width="2.5" stroke-linecap="round"/>
        <path d="M92,64 Q100,66 108,64" fill="none" stroke="${c.outline}" stroke-width="1.5" stroke-linecap="round"/>
        <!-- Zzz -->
        <text x="125" y="38" font-size="12" fill="${c.outline}" font-family="sans-serif" font-style="italic">Z</text>
        <text x="130" y="30" font-size="10" fill="${c.outline}" font-family="sans-serif" font-style="italic">z</text>
      </g>
    `,
    monster: (c) => `
      <g class="face face-monster">
        <!-- 大眼 -->
        <ellipse cx="87" cy="48" rx="8" ry="9" fill="${c.eyeWhite}" stroke="${c.outline}" stroke-width="2"/>
        <ellipse cx="113" cy="48" rx="8" ry="9" fill="${c.eyeWhite}" stroke="${c.outline}" stroke-width="2"/>
        <ellipse cx="88" cy="50" rx="4" ry="6" fill="${c.accent}"/>
        <ellipse cx="114" cy="50" rx="4" ry="6" fill="${c.accent}"/>
        <ellipse cx="88" cy="51" rx="1.5" ry="3" fill="${c.outline}"/>
        <ellipse cx="114" cy="51" rx="1.5" ry="3" fill="${c.outline}"/>
        <circle cx="89" cy="47" r="1.5" fill="white"/>
        <circle cx="115" cy="47" r="1.5" fill="white"/>
        <!-- 獠牙嘴 -->
        <path d="M84,64 Q100,76 116,64 L114,72 L110,66 L106,72 L102,66 L98,72 L94,66 L90,72 L86,66 Z" fill="${c.outline}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 尖牙 -->
        <polygon points="90,68 92,74 94,68" fill="white"/>
        <polygon points="106,68 108,74 110,68" fill="white"/>
      </g>
    `,
    skeleton: (c) => `
      <g class="face face-skeleton">
        <!-- 空洞眼眶 -->
        <ellipse cx="90" cy="48" rx="6" ry="7" fill="${c.outline}"/>
        <ellipse cx="110" cy="48" rx="6" ry="7" fill="${c.outline}"/>
        <!-- 眼洞高光 -->
        <ellipse cx="92" cy="46" rx="2" ry="2" fill="#ff6b6b" opacity="0.8"/>
        <ellipse cx="112" cy="46" rx="2" ry="2" fill="#ff6b6b" opacity="0.8"/>
        <!-- 牙 -->
        <path d="M88,70 L90,76 L92,70 L94,76 L96,70 L98,76 L100,70 L102,76 L104,70 L106,76 L108,70 L110,76 L112,70" fill="white" stroke="${c.outline}" stroke-width="1"/>
      </g>
    `
  },

  /* ========= 发型 ========= */

  hair: {
    none: () => `<g></g>`,
    short: (c) => `
      <g class="hair hair-short">
        <path d="M73,40 Q70,15 100,10 Q130,15 127,40 Q130,32 120,25 Q115,18 100,16 Q85,18 80,25 Q70,32 73,40 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 阴影 -->
        <path d="M73,40 Q90,35 100,38 Q110,35 127,40 Q120,45 100,43 Q80,45 73,40 Z" fill="${c.hairShadow}" opacity="0.6"/>
        <!-- 高光 -->
        <path d="M85,20 Q95,14 105,16" fill="none" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
      </g>
    `,
    long: (c) => `
      <g class="hair hair-long">
        <!-- 后部长发 -->
        <path d="M72,40 Q68,80 60,120 Q58,145 68,160 Q80,148 82,120 Q82,95 80,70 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M128,40 Q132,80 140,120 Q142,145 132,160 Q120,148 118,120 Q118,95 120,70 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 顶部 -->
        <path d="M72,40 Q70,12 100,8 Q130,12 128,40 Q122,28 110,22 Q100,18 90,22 Q78,28 72,40 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 刘海 -->
        <path d="M78,35 Q90,28 100,32 Q110,28 122,35 Q118,40 100,38 Q82,40 78,35 Z" fill="${c.hair}"/>
        <!-- 头发纹理 -->
        <path d="M62,100 Q65,110 68,120" fill="none" stroke="${c.hairShadow}" stroke-width="1"/>
        <path d="M138,100 Q135,110 132,120" fill="none" stroke="${c.hairShadow}" stroke-width="1"/>
        <!-- 高光 -->
        <path d="M85,18 Q95,12 108,14" fill="none" stroke="${c.hairHighlight}" stroke-width="2.5" stroke-linecap="round"/>
      </g>
    `,
    ponytail: (c) => `
      <g class="hair hair-ponytail">
        <path d="M74,40 Q72,18 100,14 Q128,18 126,40 Q120,30 110,25 Q100,22 90,25 Q80,30 74,40 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 马尾 -->
        <path d="M126,35 Q145,40 148,70 Q150,95 140,115 Q132,100 130,75 Q128,55 126,35 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M138,60 Q142,75 138,95" fill="none" stroke="${c.hairShadow}" stroke-width="1"/>
        <path d="M88,20 Q98,14 108,16" fill="none" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
        <!-- 发带 -->
        <rect x="124" y="33" width="8" height="5" fill="${c.accent}" stroke="${c.outline}" stroke-width="1"/>
      </g>
    `,
    spiky: (c) => `
      <g class="hair hair-spiky">
        <path d="M72,40 L62,18 L72,28 L68,10 L82,22 L78,5 L90,18 L88,-2 L100,10 L100,-8 L108,10 L112,-2 L118,18 L122,5 L128,22 L132,10 L128,28 L138,18 L126,40 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 高光刺 -->
        <path d="M88,5 L90,15" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
        <path d="M108,5 L110,15" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
        <path d="M100,-8 L100,5" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
      </g>
    `,
    crown: (c) => `
      <g class="hair hair-crown">
        <path d="M74,40 Q72,18 100,14 Q128,18 126,40 Q120,30 110,25 Q100,22 90,25 Q80,30 74,40 Z" 
              fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M85,30 Q82,12 100,8 Q118,12 115,30 Q105,20 100,20 Q95,20 85,30 Z" 
              fill="${c.hairShadow}"/>
        <path d="M88,14 Q98,8 108,10" fill="none" stroke="${c.hairHighlight}" stroke-width="2" stroke-linecap="round"/>
        <!-- 王冠 -->
        <path d="M78,14 L84,-6 L92,6 L100,-10 L108,6 L116,-6 L122,14 Z" 
              fill="${c.gold}" stroke="${c.outline}" stroke-width="1.8"/>
        <circle cx="84" cy="2" r="2.5" fill="#ff4444" stroke="${c.outline}" stroke-width="1"/>
        <circle cx="100" cy="-6" r="3" fill="#44ff44" stroke="${c.outline}" stroke-width="1"/>
        <circle cx="116" cy="2" r="2.5" fill="#4444ff" stroke="${c.outline}" stroke-width="1"/>
      </g>
    `
  },

  /* ========= 躯干 ========= */

  body: {
    tunic: (c) => `
      <g class="body body-tunic">
        <!-- 主躯干 -->
        <path d="M82,88 Q76,110 74,145 Q74,165 88,168 L112,168 Q126,165 126,145 Q124,110 118,88 Q100,82 82,88 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 衣领 -->
        <path d="M88,88 Q100,95 112,88 Q108,98 100,100 Q92,98 88,88 Z" fill="${c.pants}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 阴影 -->
        <path d="M82,100 Q80,140 90,165 Q85,130 85,110 Z" fill="${c.bodyShadow}" opacity="0.5"/>
        <!-- 腰带 -->
        <rect x="72" y="148" width="56" height="8" fill="${c.pants}" stroke="${c.outline}" stroke-width="1.5"/>
        <rect x="95" y="146" width="10" height="12" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 高光 -->
        <path d="M108,100 Q112,130 110,150" fill="none" stroke="${c.bodyHighlight}" stroke-width="1.5" opacity="0.6"/>
      </g>
    `,
    armor: (c) => `
      <g class="body body-armor">
        <path d="M80,88 Q70,108 68,145 Q68,168 85,170 L115,170 Q132,168 132,145 Q130,108 120,88 Q100,80 80,88 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2.2"/>
        <!-- 胸甲中线 -->
        <path d="M100,90 L100,165" stroke="${c.outline}" stroke-width="2"/>
        <!-- 胸甲装饰 -->
        <path d="M88,100 L100,95 L112,100 L108,115 L100,120 L92,115 Z" 
              fill="${c.gold}" stroke="${c.outline}" stroke-width="1.8"/>
        <circle cx="100" cy="108" r="3" fill="${c.accent}" stroke="${c.outline}" stroke-width="1"/>
        <!-- 金属阴影 -->
        <path d="M70,100 Q68,140 72,165 L82,162 Q78,130 80,105 Z" fill="${c.metalShadow}"/>
        <!-- 金属高光 -->
        <path d="M90,95 L88,130" stroke="${c.metalHighlight}" stroke-width="2" opacity="0.7"/>
        <path d="M110,95 L112,130" stroke="${c.metalHighlight}" stroke-width="2" opacity="0.7"/>
        <!-- 肩甲 -->
        <path d="M60,85 Q50,90 48,105 Q55,115 70,110 L72,92 Z" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M140,85 Q150,90 152,105 Q145,115 130,110 L128,92 Z" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
      </g>
    `,
    robe: (c) => `
      <g class="body body-robe">
        <path d="M80,88 L62,150 L55,178 L145,178 L138,150 L120,88 Q100,82 80,88 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 腰带 -->
        <rect x="68" y="138" width="64" height="10" fill="${c.pants}" stroke="${c.outline}" stroke-width="1.5"/>
        <rect x="95" y="136" width="10" height="14" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 阴影 -->
        <path d="M75,100 Q68,150 62,175 L78,170 Q75,140 78,110 Z" fill="${c.bodyShadow}" opacity="0.5"/>
        <!-- 皱褶 -->
        <path d="M75,160 L70,178 M85,162 L82,178 M100,158 L100,178 M115,162 L118,178 M125,160 L130,178" 
              stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <!-- 高领 -->
        <path d="M86,88 Q100,95 114,88 Q110,102 100,102 Q90,102 86,88 Z" fill="${c.bodyShadow}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 纹样 -->
        <path d="M95,120 L100,112 L105,120 L100,128 Z" fill="${c.gold}" opacity="0.8"/>
        <path d="M90,135 L110,135" stroke="${c.gold}" stroke-width="1" opacity="0.6"/>
      </g>
    `,
    female: (c) => `
      <g class="body body-female">
        <path d="M84,88 Q78,110 76,135 Q78,155 88,160 L112,160 Q122,155 124,135 Q122,110 116,88 Q100,82 84,88 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 胸部 -->
        <path d="M86,98 Q92,115 100,112 Q108,115 114,98" fill="none" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="93" cy="107" rx="4" ry="5" fill="${c.bodyShadow}" opacity="0.4"/>
        <ellipse cx="107" cy="107" rx="4" ry="5" fill="${c.bodyShadow}" opacity="0.4"/>
        <!-- 裙子 -->
        <path d="M80,158 Q55,190 50,200 L150,200 Q145,190 120,158 Z" fill="${c.pants}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 裙子阴影 -->
        <path d="M60,190 Q75,200 90,195" fill="none" stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <!-- 蕾丝边 -->
        <path d="M50,200 L150,200" stroke="${c.gold}" stroke-width="1.5"/>
        <!-- 腰带 -->
        <rect x="78" y="148" width="44" height="6" fill="${c.gold}" stroke="${c.outline}" stroke-width="1"/>
      </g>
    `,
    monster: (c) => `
      <g class="body body-monster">
        <path d="M78,88 Q65,110 62,150 Q60,175 75,178 L125,178 Q140,175 138,150 Q135,110 122,88 Q100,80 78,88 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2.5"/>
        <!-- 鳞片 -->
        <path d="M82,105 Q100,98 118,105" fill="none" stroke="${c.outline}" stroke-width="1.2" opacity="0.6"/>
        <path d="M80,125 Q100,118 120,125" fill="none" stroke="${c.outline}" stroke-width="1.2" opacity="0.6"/>
        <path d="M82,145 Q100,138 118,145" fill="none" stroke="${c.outline}" stroke-width="1.2" opacity="0.6"/>
        <!-- 腹部 -->
        <ellipse cx="100" cy="140" rx="18" ry="25" fill="${c.bodyHighlight}" opacity="0.4"/>
        <!-- 尖刺 -->
        <path d="M88,82 L90,72 L92,82" fill="${c.outline}"/>
        <path d="M100,78 L102,68 L104,78" fill="${c.outline}"/>
        <path d="M110,82 L112,72 L114,82" fill="${c.outline}"/>
      </g>
    `
  },

  /* ========= 手臂 ========= */

  arms: {
    normal: (c) => `
      <g class="arm arm-l">
        <path d="M78,95 Q60,125 52,155 Q55,165 62,165 Q70,163 72,155 Q78,130 82,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 手 -->
        <circle cx="58" cy="160" r="9" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 阴影 -->
        <path d="M54,155 Q53,165 58,168 Q55,162 54,155 Z" fill="${c.skinShadow}"/>
        <path d="M75,110 Q65,140 60,155" fill="none" stroke="${c.bodyShadow}" stroke-width="1" opacity="0.5"/>
      </g>
      <g class="arm arm-r">
        <path d="M122,95 Q140,125 148,155 Q145,165 138,165 Q130,163 128,155 Q122,130 118,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <circle cx="142" cy="160" r="9" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M146,155 Q147,165 142,168 Q145,162 146,155 Z" fill="${c.skinShadow}"/>
        <path d="M125,110 Q135,140 140,155" fill="none" stroke="${c.bodyShadow}" stroke-width="1" opacity="0.5"/>
      </g>
    `,
    armored: (c) => `
      <g class="arm arm-l">
        <path d="M78,95 Q62,125 55,155 Q58,168 68,168 Q76,165 76,155 Q78,130 82,100 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 护手 -->
        <rect x="48" y="152" width="22" height="20" rx="3" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M48,160 L70,160" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 金属阴影 -->
        <path d="M60,100 Q55,130 52,155" fill="none" stroke="${c.metalShadow}" stroke-width="2" opacity="0.6"/>
        <!-- 金属高光 -->
        <path d="M72,100 Q68,130 66,150" fill="none" stroke="${c.metalHighlight}" stroke-width="1.5" opacity="0.5"/>
      </g>
      <g class="arm arm-r">
        <path d="M122,95 Q138,125 145,155 Q142,168 132,168 Q124,165 124,155 Q122,130 118,100 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <rect x="130" y="152" width="22" height="20" rx="3" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M130,160 L152,160" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M140,100 Q145,130 148,155" fill="none" stroke="${c.metalShadow}" stroke-width="2" opacity="0.6"/>
        <path d="M128,100 Q132,130 134,150" fill="none" stroke="${c.metalHighlight}" stroke-width="1.5" opacity="0.5"/>
      </g>
    `,
    robe: (c) => `
      <g class="arm arm-l">
        <path d="M78,95 Q60,130 45,165 Q48,178 58,178 Q68,175 65,165 Q72,135 82,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M48,155 Q50,170 58,175" fill="none" stroke="${c.bodyShadow}" stroke-width="1.5" opacity="0.5"/>
        <!-- 袖口 -->
        <path d="M43,165 Q48,175 58,175 Q65,175 62,165" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 手 -->
        <circle cx="53" cy="180" r="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.8"/>
      </g>
      <g class="arm arm-r">
        <path d="M122,95 Q140,130 155,165 Q152,178 142,178 Q132,175 135,165 Q128,135 118,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M152,155 Q150,170 142,175" fill="none" stroke="${c.bodyShadow}" stroke-width="1.5" opacity="0.5"/>
        <path d="M157,165 Q152,175 142,175 Q135,175 138,165" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
        <circle cx="147" cy="180" r="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.8"/>
      </g>
    `,
    claw: (c) => `
      <g class="arm arm-l">
        <path d="M78,95 Q60,125 52,155 Q55,168 62,168 Q70,165 72,155 Q78,130 82,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 爪子手 -->
        <path d="M50,155 Q45,175 52,178 Q62,175 58,155" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M48,175 L42,190 L46,185 L38,192 M54,178 L52,195 M60,175 L66,190 L62,185 L70,192" fill="none" stroke="${c.outline}" stroke-width="2.5"/>
      </g>
      <g class="arm arm-r">
        <path d="M122,95 Q140,125 148,155 Q145,168 138,168 Q130,165 128,155 Q122,130 118,100 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M150,155 Q155,175 148,178 Q138,175 142,155" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M152,175 L158,190 L154,185 L162,192 M146,178 L148,195 M140,175 L134,190 L138,185 L130,192" fill="none" stroke="${c.outline}" stroke-width="2.5"/>
      </g>
    `
  },

  /* ========= 腿部 ========= */

  legs: {
    pants: (c) => `
      <g class="leg leg-l">
        <path d="M82,168 Q78,210 78,255 L96,255 Q96,210 98,168 Z" 
              fill="${c.pants}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M78,175 Q76,215 77,250" fill="none" stroke="${c.pantsShadow}" stroke-width="2" opacity="0.6"/>
        <!-- 裤折 -->
        <path d="M85,200 L82,220 M92,200 L94,220" stroke="${c.outline}" stroke-width="0.8" opacity="0.3"/>
      </g>
      <g class="leg leg-r">
        <path d="M118,168 Q122,210 122,255 L104,255 Q104,210 102,168 Z" 
              fill="${c.pants}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M122,175 Q124,215 123,250" fill="none" stroke="${c.pantsShadow}" stroke-width="2" opacity="0.6"/>
        <path d="M115,200 L118,220 M108,200 L106,220" stroke="${c.outline}" stroke-width="0.8" opacity="0.3"/>
      </g>
    `,
    armor: (c) => `
      <g class="leg leg-l">
        <path d="M80,170 Q74,210 72,255 L98,255 Q98,210 98,170 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M74,180 Q72,220 74,255" fill="none" stroke="${c.metalShadow}" stroke-width="2" opacity="0.5"/>
        <!-- 金属板分割 -->
        <line x1="73" y1="195" x2="97" y2="195" stroke="${c.outline}" stroke-width="1.2"/>
        <line x1="73" y1="225" x2="97" y2="225" stroke="${c.outline}" stroke-width="1.2"/>
        <!-- 装饰钉 -->
        <circle cx="78" cy="195" r="2" fill="${c.gold}"/>
        <circle cx="92" cy="195" r="2" fill="${c.gold}"/>
      </g>
      <g class="leg leg-r">
        <path d="M120,170 Q126,210 128,255 L102,255 Q102,210 102,170 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M126,180 Q128,220 126,255" fill="none" stroke="${c.metalShadow}" stroke-width="2" opacity="0.5"/>
        <line x1="103" y1="195" x2="127" y2="195" stroke="${c.outline}" stroke-width="1.2"/>
        <line x1="103" y1="225" x2="127" y2="225" stroke="${c.outline}" stroke-width="1.2"/>
        <circle cx="108" cy="195" r="2" fill="${c.gold}"/>
        <circle cx="122" cy="195" r="2" fill="${c.gold}"/>
      </g>
    `,
    skirt: (c) => `
      <g class="leg leg-l">
        <path d="M84,170 Q82,200 82,240 L94,240 Q94,200 96,170 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.8"/>
      </g>
      <g class="leg leg-r">
        <path d="M116,170 Q118,200 118,240 L106,240 Q106,200 104,170 Z" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.8"/>
      </g>
      <g class="skirt">
        <path d="M78,165 Q52,210 45,240 L155,240 Q148,210 122,165 Q100,160 78,165 Z" 
              fill="${c.pants}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 裙褶 -->
        <path d="M70,175 Q55,215 48,238" fill="none" stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <path d="M85,170 Q82,210 78,238" fill="none" stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <path d="M115,170 Q118,210 122,238" fill="none" stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <path d="M130,175 Q145,215 152,238" fill="none" stroke="${c.outline}" stroke-width="0.8" opacity="0.4"/>
        <!-- 花边 -->
        <path d="M45,240 L155,240" stroke="${c.gold}" stroke-width="2"/>
      </g>
    `
  },

  /* ========= 鞋子 ========= */

  footwear: {
    boot: (c) => `
      <g class="shoe shoe-l">
        <rect x="76" y="245" width="22" height="18" rx="3" fill="${c.boot}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M74,260 Q74,268 87,270 Q100,268 100,260 L98,250 L76,250 Z" fill="${c.boot}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M78,248 L94,248 M78,255 L94,255" stroke="${c.bootShadow}" stroke-width="1.5"/>
        <!-- 鞋带孔 -->
        <circle cx="83" cy="250" r="1.2" fill="${c.outline}"/>
        <circle cx="90" cy="250" r="1.2" fill="${c.outline}"/>
        <circle cx="83" cy="256" r="1.2" fill="${c.outline}"/>
        <circle cx="90" cy="256" r="1.2" fill="${c.outline}"/>
      </g>
      <g class="shoe shoe-r">
        <rect x="102" y="245" width="22" height="18" rx="3" fill="${c.boot}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M126,260 Q126,268 113,270 Q100,268 100,260 L102,250 L124,250 Z" fill="${c.boot}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M106,248 L122,248 M106,255 L122,255" stroke="${c.bootShadow}" stroke-width="1.5"/>
        <circle cx="109" cy="250" r="1.2" fill="${c.outline}"/>
        <circle cx="116" cy="250" r="1.2" fill="${c.outline}"/>
        <circle cx="109" cy="256" r="1.2" fill="${c.outline}"/>
        <circle cx="116" cy="256" r="1.2" fill="${c.outline}"/>
      </g>
    `,
    sandal: (c) => `
      <g class="shoe shoe-l">
        <path d="M74,260 Q74,272 87,274 Q100,272 100,260 L98,254 L76,254 Z" fill="#d4a574" stroke="${c.outline}" stroke-width="2"/>
        <path d="M80,254 Q87,246 94,254" fill="none" stroke="${c.bootShadow}" stroke-width="2.5"/>
        <path d="M87,248 L87,258" fill="none" stroke="${c.bootShadow}" stroke-width="2"/>
      </g>
      <g class="shoe shoe-r">
        <path d="M126,260 Q126,272 113,274 Q100,272 100,260 L102,254 L124,254 Z" fill="#d4a574" stroke="${c.outline}" stroke-width="2"/>
        <path d="M120,254 Q113,246 106,254" fill="none" stroke="${c.bootShadow}" stroke-width="2.5"/>
        <path d="M113,248 L113,258" fill="none" stroke="${c.bootShadow}" stroke-width="2"/>
      </g>
    `,
    bare: (c) => `
      <g class="shoe shoe-l">
        <ellipse cx="87" cy="265" rx="14" ry="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 脚趾 -->
        <ellipse cx="76" cy="268" rx="3" ry="3" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="82" cy="270" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="88" cy="271" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="94" cy="270" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="98" cy="268" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
      </g>
      <g class="shoe shoe-r">
        <ellipse cx="113" cy="265" rx="14" ry="7" fill="${c.skin}" stroke="${c.outline}" stroke-width="2"/>
        <ellipse cx="124" cy="268" rx="3" ry="3" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="118" cy="270" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="112" cy="271" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="106" cy="270" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
        <ellipse cx="102" cy="268" rx="2.5" ry="2.5" fill="${c.skin}" stroke="${c.outline}" stroke-width="1.5"/>
      </g>
    `
  },

  /* ========= 武器 ========= */

  weapon: {
    none: () => `<g></g>`,
    sword: (c) => `
      <g class="weapon weapon-sword" transform="translate(148, 145) rotate(-20)">
        <!-- 剑身 -->
        <path d="M0,0 L4,-55 L8,-55 L12,0 Z" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M4,-55 L8,-55 L6,0" fill="${c.metalHighlight}"/>
        <path d="M0,-10 L12,-10" stroke="${c.outline}" stroke-width="1.5"/>
        <!-- 护手 -->
        <rect x="-10" y="-8" width="32" height="6" rx="1" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.8"/>
        <circle cx="-6" cy="-5" r="1.5" fill="${c.accent}"/>
        <circle cx="18" cy="-5" r="1.5" fill="${c.accent}"/>
        <!-- 剑柄 -->
        <rect x="1" y="-2" width="10" height="22" fill="${c.boot}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M2,0 L10,0 M2,6 L10,6 M2,12 L10,12 M2,18 L10,18" stroke="${c.outline}" stroke-width="0.8"/>
        <!-- 剑首 -->
        <circle cx="6" cy="22" r="5" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.8"/>
        <circle cx="6" cy="22" r="2" fill="${c.accent}" stroke="${c.outline}" stroke-width="1"/>
      </g>
    `,
    axe: (c) => `
      <g class="weapon weapon-axe" transform="translate(148, 145) rotate(-25)">
        <!-- 斧头 -->
        <path d="M8,-45 L35,-55 L30,-30 L35,-15 L8,-5 Z" fill="${c.metal}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M15,-48 L28,-53 L25,-35" fill="${c.metalHighlight}" opacity="0.8"/>
        <path d="M10,-15 L8,-5 L35,-15" fill="${c.metalShadow}"/>
        <!-- 握柄 -->
        <rect x="4" y="-5" width="8" height="45" fill="${c.boot}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M6,0 L10,0 M6,10 L10,10 M6,20 L10,20 M6,30 L10,30" stroke="${c.outline}" stroke-width="0.5"/>
        <rect x="2" y="38" width="12" height="6" rx="1" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
      </g>
    `,
    bow: (c) => `
      <g class="weapon weapon-bow" transform="translate(148, 160)">
        <path d="M-8,-40 Q-20,0 -8,40" fill="none" stroke="${c.boot}" stroke-width="5" stroke-linecap="round"/>
        <path d="M-8,-40 Q-12,0 -8,40" fill="none" stroke="${c.bootShadow}" stroke-width="3"/>
        <path d="M-8,-40 L-8,40" stroke="white" stroke-width="1.2" stroke-dasharray="2,2"/>
        <!-- 箭 -->
        <line x1="-12" y1="0" x2="20" y2="0" stroke="${c.boot}" stroke-width="1.8"/>
        <polygon points="20,0 14,-3 14,3" fill="${c.metal}" stroke="${c.outline}" stroke-width="1"/>
        <!-- 羽毛 -->
        <path d="M-12,0 L-18,-4 L-14,0 L-18,4 Z" fill="#ff6b6b"/>
      </g>
    `,
    staff: (c) => `
      <g class="weapon weapon-staff" transform="translate(148, 155) rotate(-10)">
        <!-- 法杖杆 -->
        <rect x="4" y="-50" width="6" height="75" fill="${c.boot}" stroke="${c.outline}" stroke-width="1.5"/>
        <path d="M4,-30 Q7,-35 10,-30 M4,-10 Q7,-15 10,-10 M4,10 Q7,5 10,10" fill="none" stroke="${c.bootShadow}" stroke-width="0.8"/>
        <!-- 水晶 -->
        <polygon points="7,-70 18,-55 7,-40 -4,-55" fill="${c.accent}" stroke="${c.outline}" stroke-width="1.8"/>
        <polygon points="7,-65 14,-55 7,-45" fill="white" opacity="0.4"/>
        <!-- 光晕 -->
        <circle cx="7" cy="-55" r="12" fill="${c.accent}" opacity="0.2"/>
        <!-- 底座 -->
        <rect x="2" y="25" width="10" height="5" rx="1" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
      </g>
    `,
    shield: (c) => `
      <g class="weapon weapon-shield" transform="translate(50, 148)">
        <path d="M-12,-18 L12,-18 L16,5 Q16,22 0,30 Q-16,22 -16,5 Z" 
              fill="${c.metal}" stroke="${c.outline}" stroke-width="2.2"/>
        <path d="M-10,-15 Q-14,0 -12,18 Q-6,-5 -8,-12 Z" fill="${c.metalShadow}" opacity="0.5"/>
        <!-- 十字纹 -->
        <path d="M0,-15 L0,25 M-12,5 L12,5" stroke="${c.gold}" stroke-width="3"/>
        <circle cx="0" cy="5" r="6" fill="${c.gold}" stroke="${c.outline}" stroke-width="1.5"/>
        <circle cx="0" cy="5" r="3" fill="${c.accent}"/>
        <!-- 铆钉 -->
        <circle cx="-10" cy="-14" r="1.5" fill="${c.outline}"/>
        <circle cx="10" cy="-14" r="1.5" fill="${c.outline}"/>
        <circle cx="-14" cy="15" r="1.5" fill="${c.outline}"/>
        <circle cx="14" cy="15" r="1.5" fill="${c.outline}"/>
      </g>
    `
  },

  /* ========= 特色标记物（翅膀/尾巴/犄角） ========= */

  extra: {
    none: () => `<g></g>`,
    wings: (c) => `
      <g class="extra extra-wings">
        <path d="M80,120 Q50,80 20,90 Q35,115 50,120 Q40,140 25,160 Q55,145 80,130 Z" 
              fill="${c.bodyShadow}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M120,120 Q150,80 180,90 Q165,115 150,120 Q160,140 175,160 Q145,145 120,130 Z" 
              fill="${c.bodyShadow}" stroke="${c.outline}" stroke-width="2"/>
        <!-- 骨架 -->
        <path d="M55,100 Q45,110 40,130 M65,110 Q55,120 50,140 M70,120 Q62,130 58,150" fill="none" stroke="${c.outline}" stroke-width="1.2"/>
        <path d="M145,100 Q155,110 160,130 M135,110 Q145,120 150,140 M130,120 Q138,130 142,150" fill="none" stroke="${c.outline}" stroke-width="1.2"/>
      </g>
    `,
    tail: (c) => `
      <g class="extra extra-tail">
        <path d="M110,175 Q145,195 155,235 Q158,260 148,270 Q140,265 138,245 Q135,220 120,185 Z" 
              fill="${c.body}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M140,210 Q148,235 148,255" fill="none" stroke="${c.bodyShadow}" stroke-width="1.5"/>
        <!-- 尾尖刺 -->
        <path d="M145,270 L150,280 L148,268 M152,272 L158,285 L153,270" fill="none" stroke="${c.outline}" stroke-width="2.5"/>
      </g>
    `,
    horns: (c) => `
      <g class="extra extra-horns">
        <path d="M82,20 Q65,5 68,-15 Q75,0 85,15 Z" fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M82,20 Q72,10 70,-10" fill="none" stroke="${c.outline}" stroke-width="1" opacity="0.6"/>
        <path d="M118,20 Q135,5 132,-15 Q125,0 115,15 Z" fill="${c.hair}" stroke="${c.outline}" stroke-width="2"/>
        <path d="M118,20 Q128,10 130,-10" fill="none" stroke="${c.outline}" stroke-width="1" opacity="0.6"/>
      </g>
    `
  }
};

// 部件类别配置（精简版）
const PartCategories = [
  { id: 'head', name: '脸型' },
  { id: 'face', name: '表情' },
  { id: 'hair', name: '发型' },
  { id: 'body', name: '上装' },
  { id: 'arms', name: '手臂' },
  { id: 'legs', name: '下装' },
  { id: 'footwear', name: '鞋子' },
  { id: 'weapon', name: '武器' },
  { id: 'extra', name: '特色' }
];

// 部件选项配置
const PartOptions = {
  head: [
    { id: 'basic', name: '标准' },
    { id: 'chubby', name: '圆脸' },
    { id: 'sharp', name: '尖脸' },
    { id: 'skull', name: '骷髅' }
  ],
  face: [
    { id: 'normal', name: '微笑' },
    { id: 'happy', name: '大笑' },
    { id: 'angry', name: '愤怒' },
    { id: 'sleepy', name: '困倦' },
    { id: 'monster', name: '怪物' },
    { id: 'skeleton', name: '骷髅' }
  ],
  hair: [
    { id: 'none', name: '无' },
    { id: 'short', name: '短发' },
    { id: 'long', name: '长发' },
    { id: 'ponytail', name: '马尾' },
    { id: 'spiky', name: '刺头' },
    { id: 'crown', name: '王冠' }
  ],
  body: [
    { id: 'tunic', name: '短袍' },
    { id: 'armor', name: '铠甲' },
    { id: 'robe', name: '长袍' },
    { id: 'female', name: '裙装' },
    { id: 'monster', name: '兽身' }
  ],
  arms: [
    { id: 'normal', name: '普通' },
    { id: 'armored', name: '铁臂' },
    { id: 'robe', name: '长袍袖' },
    { id: 'claw', name: '利爪' }
  ],
  legs: [
    { id: 'pants', name: '长裤' },
    { id: 'armor', name: '腿甲' },
    { id: 'skirt', name: '裙子' }
  ],
  footwear: [
    { id: 'boot', name: '靴子' },
    { id: 'sandal', name: '凉鞋' },
    { id: 'bare', name: '光脚' }
  ],
  weapon: [
    { id: 'none', name: '空手' },
    { id: 'sword', name: '剑' },
    { id: 'axe', name: '斧' },
    { id: 'bow', name: '弓' },
    { id: 'staff', name: '法杖' },
    { id: 'shield', name: '盾' }
  ],
  extra: [
    { id: 'none', name: '无' },
    { id: 'wings', name: '翅膀' },
    { id: 'tail', name: '尾巴' },
    { id: 'horns', name: '犄角' }
  ]
};

// 预设角色 - 每个都有独特形象
const Presets = {
  warrior: {
    name: '铁血战士',
    desc: '身披重甲、手持利剑的皇家卫士',
    icon: '⚔️',
    parts: { head: 'basic', face: 'angry', hair: 'short', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'boot', weapon: 'sword', extra: 'none' },
    colors: { skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6', hair: '#2a2a2a', hairShadow: '#1a1a1a', hairHighlight: '#444', eye: '#2c3e50', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#8b8fa3', bodyShadow: '#6b6f83', bodyHighlight: '#abafc3', pants: '#4a4e62', pantsShadow: '#2a2e42', pantsHighlight: '#6a6e82', boot: '#3d2817', bootShadow: '#2a1b0e', bootHighlight: '#5c3d2c', metal: '#c0c0c8', metalShadow: '#8a8a92', metalHighlight: '#e4e4ec', accent: '#c0392b', accentShadow: '#922b21', accentHighlight: '#e74c3c', gold: '#d4a017', goldShadow: '#a07a12', goldHighlight: '#f5d05e', outline: '#1a1a2e' }
  },
  mage: {
    name: '奥术法师',
    desc: '头戴王冠法杖施法的神秘法师',
    icon: '🧙',
    parts: { head: 'basic', face: 'normal', hair: 'crown', body: 'robe', arms: 'robe', legs: 'pants', footwear: 'sandal', weapon: 'staff', extra: 'none' },
    colors: { skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6', hair: '#6b3fa0', hairShadow: '#4a2a70', hairHighlight: '#8a5fc0', eye: '#9400d3', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#4a148c', bodyShadow: '#3a1070', bodyHighlight: '#6a34ac', pants: '#2a0a4a', pantsShadow: '#1a0530', pantsHighlight: '#4a1a6a', boot: '#654321', bootShadow: '#3d2817', bootHighlight: '#8a6341', metal: '#9b59b6', metalShadow: '#7d3c98', metalHighlight: '#bb8fce', accent: '#00d4ff', accentShadow: '#00a8cc', accentHighlight: '#4de0ff', gold: '#ffd700', goldShadow: '#c49f00', goldHighlight: '#ffe94d', outline: '#1a1a2e' }
  },
  archer: {
    name: '森林游侠',
    desc: '手持长弓的迅捷猎手',
    icon: '🏹',
    parts: { head: 'sharp', face: 'happy', hair: 'ponytail', body: 'tunic', arms: 'normal', legs: 'pants', footwear: 'boot', weapon: 'bow', extra: 'none' },
    colors: { skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6', hair: '#8b4513', hairShadow: '#654321', hairHighlight: '#a67c4a', eye: '#228b22', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#2d5a27', bodyShadow: '#1d3d18', bodyHighlight: '#4d7a47', pants: '#4a3728', pantsShadow: '#2a1d10', pantsHighlight: '#6a5748', boot: '#3d2817', bootShadow: '#2a1b0e', bootHighlight: '#5c3d2c', metal: '#a0a0a0', metalShadow: '#707070', metalHighlight: '#c0c0c0', accent: '#8b0000', accentShadow: '#600000', accentHighlight: '#b03030', gold: '#b8860b', goldShadow: '#8a6008', goldHighlight: '#d4aa2c', outline: '#1a1a2e' }
  },
  knight: {
    name: '圣光骑士',
    desc: '白金铠甲、手持长剑的圣殿骑士',
    icon: '🛡️',
    parts: { head: 'basic', face: 'normal', hair: 'short', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'boot', weapon: 'sword', extra: 'none' },
    colors: { skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6', hair: '#1a1a2e', hairShadow: '#0a0a1e', hairHighlight: '#333355', eye: '#1a3a5c', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#5dade2', bodyShadow: '#3a8dbb', bodyHighlight: '#7dcdf2', pants: '#1a3a5c', pantsShadow: '#0a2a4c', pantsHighlight: '#3a5a7c', boot: '#2a2a4a', bootShadow: '#1a1a2a', bootHighlight: '#4a4a6a', metal: '#e8e8f0', metalShadow: '#b0b0c0', metalHighlight: '#ffffff', accent: '#c0392b', accentShadow: '#922b21', accentHighlight: '#e74c3c', gold: '#ffd700', goldShadow: '#c49f00', goldHighlight: '#ffe94d', outline: '#1a1a2e' }
  },
  demon: {
    name: '深渊恶魔',
    desc: '生有犄角与翅膀的邪恶存在',
    icon: '😈',
    parts: { head: 'sharp', face: 'monster', hair: 'spiky', body: 'monster', arms: 'claw', legs: 'armor', footwear: 'boot', weapon: 'axe', extra: 'horns' },
    colors: { skin: '#8b0000', skinShadow: '#5c0000', skinHighlight: '#b03030', hair: '#1a0000', hairShadow: '#0a0000', hairHighlight: '#300000', eye: '#ffff00', eyeWhite: '#000', eyeShine: '#ff0000', body: '#8b0000', bodyShadow: '#5c0000', bodyHighlight: '#b03030', pants: '#1a0000', pantsShadow: '#0a0000', pantsHighlight: '#300000', boot: '#0a0a0a', bootShadow: '#000', bootHighlight: '#2a2a2a', metal: '#404040', metalShadow: '#202020', metalHighlight: '#606060', accent: '#ff4400', accentShadow: '#cc3300', accentHighlight: '#ff7733', gold: '#b8860b', goldShadow: '#8a6008', goldHighlight: '#d4aa2c', outline: '#000000' }
  },
  slime: {
    name: '果冻史莱姆',
    desc: 'Q弹可爱的软萌怪物',
    icon: '🟢',
    parts: { head: 'basic', face: 'happy', hair: 'none', body: 'monster', arms: 'normal', legs: 'pants', footwear: 'bare', weapon: 'none', extra: 'none' },
    colors: { skin: '#90ee90', skinShadow: '#70ce70', skinHighlight: '#b0ffb0', hair: '#2e7d32', hairShadow: '#1a5c1a', hairHighlight: '#4e9e52', eye: '#2c3e50', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#7ccd7c', bodyShadow: '#5cad5c', bodyHighlight: '#a0edc0', pants: '#5cad5c', pantsShadow: '#3c8d3c', pantsHighlight: '#7ccd7c', boot: '#5cad5c', bootShadow: '#3c8d3c', bootHighlight: '#7ccd7c', metal: '#c0c0c0', metalShadow: '#808080', metalHighlight: '#e0e0e0', accent: '#ff69b4', accentShadow: '#cc5490', accentHighlight: '#ff8bc8', gold: '#ffd700', goldShadow: '#c49f00', goldHighlight: '#ffe94d', outline: '#1a1a2e' }
  },
  knightess: {
    name: '玫瑰骑士',
    desc: '一袭粉甲的优雅女战士',
    icon: '🌸',
    parts: { head: 'basic', face: 'happy', hair: 'long', body: 'female', arms: 'normal', legs: 'skirt', footwear: 'boot', weapon: 'sword', extra: 'none' },
    colors: { skin: '#fce4c4', skinShadow: '#d9b790', skinHighlight: '#fff5e6', hair: '#d4a574', hairShadow: '#b08554', hairHighlight: '#f0c594', eye: '#8b4513', eyeWhite: '#fff', eyeShine: '#ffe066', body: '#ff69b4', bodyShadow: '#cc5490', bodyHighlight: '#ff8bc8', pants: '#ff1493', pantsShadow: '#cc1077', pantsHighlight: '#ff3ca8', boot: '#8b4513', bootShadow: '#654321', bootHighlight: '#a67c4a', metal: '#ffe4e1', metalShadow: '#ccb8b8', metalHighlight: '#ffffff', accent: '#ff1493', accentShadow: '#cc1077', accentHighlight: '#ff3ca8', gold: '#ffd700', goldShadow: '#c49f00', goldHighlight: '#ffe94d', outline: '#1a1a2e' }
  },
  skeleton: {
    name: '不死骷髅',
    desc: '亡灵军团的先锋战士',
    icon: '💀',
    parts: { head: 'skull', face: 'skeleton', hair: 'none', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'boot', weapon: 'axe', extra: 'wings' },
    colors: { skin: '#e8e0d0', skinShadow: '#b8b0a0', skinHighlight: '#fffaf0', hair: '#2a2a2a', hairShadow: '#1a1a1a', hairHighlight: '#444', eye: '#ff0000', eyeWhite: '#1a1a2e', eyeShine: '#ff4444', body: '#606060', bodyShadow: '#404040', bodyHighlight: '#808080', pants: '#404040', pantsShadow: '#202020', pantsHighlight: '#606060', boot: '#202020', bootShadow: '#101010', bootHighlight: '#404040', metal: '#808080', metalShadow: '#404040', metalHighlight: '#a0a0a0', accent: '#8b0000', accentShadow: '#5c0000', accentHighlight: '#b03030', gold: '#b8860b', goldShadow: '#8a6008', goldHighlight: '#d4aa2c', outline: '#000000' }
  }
};
