/* 纸娃娃部件库 - SVG部件定义 */

const PartsLibrary = {
  categories: [
    { id: 'head', name: '头部', icon: '👤' },
    { id: 'hair', name: '发型', icon: '💇' },
    { id: 'face', name: '面部', icon: '😊' },
    { id: 'body', name: '躯干', icon: '👕' },
    { id: 'arms', name: '手臂', icon: '💪' },
    { id: 'legs', name: '腿部', icon: '🦵' },
    { id: 'footwear', name: '鞋子', icon: '👟' },
    { id: 'weapon', name: '武器', icon: '⚔️' },
    { id: 'accessory', name: '饰品', icon: '🎀' },
    { id: 'monster', name: '怪物特征', icon: '👹' }
  ],

  defaults: {
    skinColor: '#f4c2a1',
    hairColor: '#4a3728',
    eyeColor: '#2c3e50',
    bodyColor: '#3b82f6',
    pantsColor: '#1e3a5f',
    shoeColor: '#2d2d2d',
    weaponColor: '#c0c0c0',
    accessoryColor: '#ffd700'
  },

  head: {
    basic: (c) => `<g class="part-group head-basic"><ellipse cx="100" cy="45" rx="25" ry="28" fill="${c.skinColor}" stroke="#00000033" stroke-width="1"/><rect x="93" y="70" width="14" height="10" fill="${c.skinColor}"/></g>`,
    round: (c) => `<g class="part-group head-round"><circle cx="100" cy="45" r="28" fill="${c.skinColor}" stroke="#00000033" stroke-width="1"/><rect x="93" y="70" width="14" height="10" fill="${c.skinColor}"/></g>`,
    angular: (c) => `<g class="part-group head-angular"><polygon points="75,50 85,20 115,20 125,50 120,72 80,72" fill="${c.skinColor}" stroke="#00000033" stroke-width="1"/><rect x="93" y="70" width="14" height="10" fill="${c.skinColor}"/></g>`,
    monster: (c) => `<g class="part-group head-monster"><ellipse cx="100" cy="48" rx="30" ry="26" fill="${c.skinColor}" stroke="#00000044" stroke-width="1.5"/><polygon points="80,22 78,5 88,18" fill="#2d2d2d"/><polygon points="120,22 122,5 112,18" fill="#2d2d2d"/><rect x="92" y="72" width="16" height="12" fill="${c.skinColor}"/></g>`,
    monster_horned: (c) => `<g class="part-group head-horned"><ellipse cx="100" cy="50" rx="28" ry="25" fill="${c.skinColor}" stroke="#00000044" stroke-width="1.5"/><path d="M78,25 Q60,0 70,-5 Q75,15 82,22" fill="${c.hairColor}" stroke="#2d1f15" stroke-width="1"/><path d="M122,25 Q140,0 130,-5 Q125,15 118,22" fill="${c.hairColor}" stroke="#2d1f15" stroke-width="1"/><rect x="92" y="72" width="16" height="12" fill="${c.skinColor}"/></g>`
  },

  hair: {
    none: () => `<g></g>`,
    short: (c) => `<g class="part-group hair-short"><path d="M75,45 Q75,18 100,15 Q125,18 125,45 L123,35 Q100,28 77,35 Z" fill="${c.hairColor}"/></g>`,
    long: (c) => `<g class="part-group hair-long"><path d="M72,45 Q72,15 100,12 Q128,15 128,45 L130,85 Q120,75 115,60 Q100,55 85,60 Q80,75 70,85 Z" fill="${c.hairColor}"/></g>`,
    ponytail: (c) => `<g class="part-group hair-ponytail"><path d="M75,45 Q75,18 100,15 Q125,18 125,45 L123,38 Q100,32 77,38 Z" fill="${c.hairColor}"/><path d="M125,42 Q145,55 135,90 Q128,70 122,50 Z" fill="${c.hairColor}"/></g>`,
    spiky: (c) => `<g class="part-group hair-spiky"><path d="M75,45 L72,12 L82,30 L88,8 L95,28 L100,5 L105,28 L112,8 L118,30 L128,12 L125,45 Z" fill="${c.hairColor}"/></g>`,
    bald: () => `<g class="part-group hair-bald"><ellipse cx="100" cy="42" rx="22" ry="18" fill="#d4b896" opacity="0.5"/></g>`,
    mohawk: (c) => `<g class="part-group hair-mohawk"><rect x="96" y="8" width="8" height="30" fill="${c.hairColor}" rx="2"/><ellipse cx="100" cy="10" rx="12" ry="6" fill="${c.hairColor}"/></g>`,
    monster_fur: (c) => `<g class="part-group hair-fur"><path d="M73,30 L65,20 L75,28 L72,15 L80,25 L78,12 L88,22 L85,8 L95,20 L100,5 L105,20 L115,8 L112,22 L122,12 L120,25 L128,15 L125,28 L135,20 L127,30 L127,45 Q100,35 73,45 Z" fill="${c.hairColor}"/></g>`
  },

  face: {
    normal: (c) => `<g class="part-group face-normal"><ellipse cx="92" cy="45" rx="3" ry="4" fill="white"/><ellipse cx="108" cy="45" rx="3" ry="4" fill="white"/><circle cx="92" cy="46" r="2" fill="${c.eyeColor}"/><circle cx="108" cy="46" r="2" fill="${c.eyeColor}"/><circle cx="92.5" cy="45" r="0.7" fill="white"/><circle cx="108.5" cy="45" r="0.7" fill="white"/><path d="M95,58 Q100,62 105,58" fill="none" stroke="#8b4513" stroke-width="1.2"/><path d="M87,38 Q92,36 97,38" fill="none" stroke="${c.hairColor}" stroke-width="1.2"/><path d="M103,38 Q108,36 113,38" fill="none" stroke="${c.hairColor}" stroke-width="1.2"/></g>`,
    happy: (c) => `<g class="part-group face-happy"><path d="M87,44 Q92,40 97,44" fill="none" stroke="${c.eyeColor}" stroke-width="1.5"/><path d="M103,44 Q108,40 113,44" fill="none" stroke="${c.eyeColor}" stroke-width="1.5"/><path d="M93,56 Q100,66 107,56" fill="#ff9999" stroke="#8b4513" stroke-width="1"/></g>`,
    angry: (c) => `<g class="part-group face-angry"><ellipse cx="92" cy="46" rx="2.5" ry="3" fill="${c.eyeColor}"/><ellipse cx="108" cy="46" rx="2.5" ry="3" fill="${c.eyeColor}"/><path d="M85,38 L97,42" stroke="${c.hairColor}" stroke-width="2"/><path d="M115,38 L103,42" stroke="${c.hairColor}" stroke-width="2"/><path d="M95,60 Q100,56 105,60" fill="none" stroke="#8b4513" stroke-width="1.5"/></g>`,
    sad: (c) => `<g class="part-group face-sad"><ellipse cx="92" cy="46" rx="2.5" ry="3" fill="${c.eyeColor}"/><ellipse cx="108" cy="46" rx="2.5" ry="3" fill="${c.eyeColor}"/><path d="M88,40 Q92,42 96,40" fill="none" stroke="${c.hairColor}" stroke-width="1.2"/><path d="M104,40 Q108,42 112,40" fill="none" stroke="${c.hairColor}" stroke-width="1.2"/><path d="M93,62 Q100,56 107,62" fill="none" stroke="#8b4513" stroke-width="1.2"/></g>`,
    monster: () => `<g class="part-group face-monster"><ellipse cx="90" cy="45" rx="6" ry="7" fill="#ff4444"/><ellipse cx="110" cy="45" rx="6" ry="7" fill="#ff4444"/><ellipse cx="90" cy="45" rx="2" ry="5" fill="black"/><ellipse cx="110" cy="45" rx="2" ry="5" fill="black"/><path d="M88,58 L90,66 L92,58" fill="white" stroke="#ccc" stroke-width="0.5"/><path d="M108,58 L110,66 L112,58" fill="white" stroke="#ccc" stroke-width="0.5"/><path d="M85,58 Q100,62 115,58 L112,60 Q100,64 88,60 Z" fill="#4a0000"/></g>`,
    robot: () => `<g class="part-group face-robot"><rect x="85" y="40" width="12" height="8" rx="2" fill="#00ffff" opacity="0.8"/><rect x="103" y="40" width="12" height="8" rx="2" fill="#00ffff" opacity="0.8"/><rect x="88" y="43" width="6" height="2" fill="white"/><rect x="106" y="43" width="6" height="2" fill="white"/><rect x="90" y="58" width="20" height="6" fill="#333" rx="1"/><line x1="93" y1="58" x2="93" y2="64" stroke="#666" stroke-width="0.5"/><line x1="97" y1="58" x2="97" y2="64" stroke="#666" stroke-width="0.5"/><line x1="103" y1="58" x2="103" y2="64" stroke="#666" stroke-width="0.5"/><line x1="107" y1="58" x2="107" y2="64" stroke="#666" stroke-width="0.5"/></g>`
  },

  body: {
    basic: (c) => `<g class="part-group body-basic"><path d="M82,80 L78,130 Q78,140 85,142 L115,142 Q122,140 122,130 L118,80 Z" fill="${c.bodyColor}" stroke="#00000033" stroke-width="1"/><path d="M82,80 Q100,78 118,80 L120,85 Q100,83 80,85 Z" fill="${c.bodyColor}" opacity="0.9"/></g>`,
    muscular: (c) => `<g class="part-group body-muscular"><path d="M78,82 L72,135 Q72,148 85,150 L115,150 Q128,148 128,135 L122,82 Q110,75 100,78 Q90,75 78,82 Z" fill="${c.bodyColor}" stroke="#00000044" stroke-width="1"/><line x1="100" y1="100" x2="100" y2="140" stroke="#00000022" stroke-width="1"/><path d="M88,115 L112,115 M88,130 L112,130" stroke="#00000022" stroke-width="0.8"/></g>`,
    robe: (c) => `<g class="part-group body-robe"><path d="M78,80 L65,160 L60,175 L140,175 L135,160 L122,80 Q100,75 78,80 Z" fill="${c.bodyColor}" stroke="#00000033" stroke-width="1"/><rect x="72" y="135" width="56" height="8" fill="${c.accessoryColor}"/><rect x="96" y="133" width="8" height="12" fill="#8b6914" stroke="#5a4510" stroke-width="0.5"/></g>`,
    armor: (c) => `<g class="part-group body-armor"><path d="M78,82 L72,135 Q72,148 85,150 L115,150 Q128,148 128,135 L122,82 Q110,75 100,78 Q90,75 78,82 Z" fill="#71797E" stroke="#404040" stroke-width="1.5"/><path d="M85,90 L100,85 L115,90 L110,110 L100,115 L90,110 Z" fill="${c.accessoryColor}" opacity="0.6"/><circle cx="100" cy="100" r="5" fill="${c.accessoryColor}"/><path d="M78,125 L122,125 M78,140 L122,140" stroke="#404040" stroke-width="1"/></g>`,
    tunic: (c) => `<g class="part-group body-tunic"><path d="M82,80 L75,155 Q75,160 85,162 L115,162 Q125,160 125,155 L118,80 Q100,78 82,80 Z" fill="${c.bodyColor}" stroke="#00000033" stroke-width="1"/><path d="M82,80 Q100,78 118,80 L120,95 Q100,93 80,95 Z" fill="${c.bodyColor}" opacity="0.85"/><rect x="78" y="140" width="44" height="5" fill="${c.accessoryColor}"/></g>`,
    monster_body: (c) => `<g class="part-group body-monster"><path d="M78,80 Q70,110 68,160 Q68,170 80,172 L120,172 Q132,170 132,160 Q130,110 122,80 Q100,75 78,80 Z" fill="${c.bodyColor}" stroke="#00000044" stroke-width="1.5"/><path d="M85,100 Q100,95 115,100 M85,115 Q100,110 115,115 M85,130 Q100,125 115,130 M85,145 Q100,140 115,145" fill="none" stroke="#00000033" stroke-width="1"/></g>`
  },

  arms: {
    basic: (c) => `<g class="part-group l-arm"><path d="M78,85 Q60,110 55,140 Q55,150 62,150 Q70,148 72,140 Q78,115 82,95 Z" fill="${c.bodyColor}" stroke="#00000033" stroke-width="1"/><circle cx="58" cy="148" r="8" fill="${c.skinColor}"/></g><g class="part-group r-arm"><path d="M122,85 Q140,110 145,140 Q145,150 138,150 Q130,148 128,140 Q122,115 118,95 Z" fill="${c.bodyColor}" stroke="#00000033" stroke-width="1"/><circle cx="142" cy="148" r="8" fill="${c.skinColor}"/></g>`,
    muscular: (c) => `<g class="part-group l-arm"><path d="M78,85 Q52,115 48,145 Q48,158 58,158 Q70,155 72,142 Q78,115 82,95 Z" fill="${c.bodyColor}" stroke="#00000044" stroke-width="1"/><circle cx="53" cy="155" r="10" fill="${c.skinColor}"/></g><g class="part-group r-arm"><path d="M122,85 Q148,115 152,145 Q152,158 142,158 Q130,155 128,142 Q122,115 118,95 Z" fill="${c.bodyColor}" stroke="#00000044" stroke-width="1"/><circle cx="147" cy="155" r="10" fill="${c.skinColor}"/></g>`,
    armored: (c) => `<g class="part-group l-arm"><path d="M78,85 Q55,110 50,140 Q50,152 60,152 Q72,150 72,140 Q78,115 82,95 Z" fill="#71797E" stroke="#404040" stroke-width="1.5"/><circle cx="55" cy="150" r="9" fill="#505050" stroke="#404040" stroke-width="1"/><rect x="72" y="90" width="10" height="4" fill="${c.accessoryColor}"/></g><g class="part-group r-arm"><path d="M122,85 Q145,110 150,140 Q150,152 140,152 Q128,150 128,140 Q122,115 118,95 Z" fill="#71797E" stroke="#404040" stroke-width="1.5"/><circle cx="145" cy="150" r="9" fill="#505050" stroke="#404040" stroke-width="1"/><rect x="118" y="90" width="10" height="4" fill="${c.accessoryColor}"/></g>`,
    claw: (c) => `<g class="part-group l-arm"><path d="M78,85 Q55,110 52,140 Q52,152 60,152 Q72,150 72,140 Q78,115 82,95 Z" fill="${c.skinColor}" stroke="#00000033" stroke-width="1"/><path d="M50,145 L45,155 L48,150 L42,158 M55,148 L50,160 L53,155" fill="none" stroke="#333" stroke-width="2"/></g><g class="part-group r-arm"><path d="M122,85 Q145,110 148,140 Q148,152 140,152 Q128,150 128,140 Q122,115 118,95 Z" fill="${c.skinColor}" stroke="#00000033" stroke-width="1"/><path d="M150,145 L155,155 L152,150 L158,158 M145,148 L150,160 L147,155" fill="none" stroke="#333" stroke-width="2"/></g>`
  },

  legs: {
    pants: (c) => `<g class="part-group l-leg"><path d="M85,142 Q82,200 80,250 L92,250 Q94,200 97,142 Z" fill="${c.pantsColor}" stroke="#00000033" stroke-width="1"/></g><g class="part-group r-leg"><path d="M115,142 Q118,200 120,250 L108,250 Q106,200 103,142 Z" fill="${c.pantsColor}" stroke="#00000033" stroke-width="1"/></g>`,
    armor: (c) => `<g class="part-group l-leg"><path d="M83,142 Q78,200 76,252 L94,252 Q96,200 97,142 Z" fill="#71797E" stroke="#404040" stroke-width="1.5"/><path d="M80,170 L98,170" stroke="${c.accessoryColor}" stroke-width="1.5"/></g><g class="part-group r-leg"><path d="M117,142 Q122,200 124,252 L106,252 Q104,200 103,142 Z" fill="#71797E" stroke="#404040" stroke-width="1.5"/><path d="M102,170 L120,170" stroke="${c.accessoryColor}" stroke-width="1.5"/></g>`,
    boot: (c) => `<g class="part-group l-leg"><path d="M85,142 Q82,200 80,245 L92,245 Q94,200 97,142 Z" fill="${c.pantsColor}" stroke="#00000033" stroke-width="1"/></g><g class="part-group r-leg"><path d="M115,142 Q118,200 120,245 L108,245 Q106,200 103,142 Z" fill="${c.pantsColor}" stroke="#00000033" stroke-width="1"/></g>`,
    skirt: (c) => `<g class="part-group l-leg"><path d="M85,142 Q82,200 80,245 L92,245 Q94,200 97,142 Z" fill="${c.skinColor}" stroke="#00000022" stroke-width="0.5"/></g><g class="part-group r-leg"><path d="M115,142 Q118,200 120,245 L108,245 Q106,200 103,142 Z" fill="${c.skinColor}" stroke="#00000022" stroke-width="0.5"/></g><g class="part-group skirt"><path d="M75,142 Q60,200 55,230 L145,230 Q140,200 125,142 Q100,138 75,142 Z" fill="${c.pantsColor}" stroke="#00000033" stroke-width="1"/></g>`,
    monster_leg: (c) => `<g class="part-group l-leg"><path d="M83,142 Q75,200 72,255 L96,255 Q98,200 97,142 Z" fill="${c.skinColor}" stroke="#00000044" stroke-width="1.5"/><path d="M72,255 L68,265 L75,260 L70,268" fill="none" stroke="#333" stroke-width="2"/></g><g class="part-group r-leg"><path d="M117,142 Q125,200 128,255 L104,255 Q102,200 103,142 Z" fill="${c.skinColor}" stroke="#00000044" stroke-width="1.5"/><path d="M128,255 L132,265 L125,260 L130,268" fill="none" stroke="#333" stroke-width="2"/></g>`
  },

  footwear: {
    basic: (c) => `<g class="part-group l-shoe"><path d="M78,248 Q76,255 80,258 L94,258 Q96,255 96,248 Z" fill="${c.shoeColor}" stroke="#00000044" stroke-width="1"/><ellipse cx="87" cy="260" rx="14" ry="4" fill="${c.shoeColor}"/></g><g class="part-group r-shoe"><path d="M122,248 Q124,255 120,258 L106,258 Q104,255 104,248 Z" fill="${c.shoeColor}" stroke="#00000044" stroke-width="1"/><ellipse cx="113" cy="260" rx="14" ry="4" fill="${c.shoeColor}"/></g>`,
    boot: (c) => `<g class="part-group l-shoe"><rect x="78" y="235" width="18" height="22" fill="${c.shoeColor}" stroke="#00000044" stroke-width="1" rx="2"/><ellipse cx="87" cy="260" rx="16" ry="5" fill="${c.shoeColor}"/></g><g class="part-group r-shoe"><rect x="104" y="235" width="18" height="22" fill="${c.shoeColor}" stroke="#00000044" stroke-width="1" rx="2"/><ellipse cx="113" cy="260" rx="16" ry="5" fill="${c.shoeColor}"/></g>`,
    sandal: () => `<g class="part-group l-shoe"><ellipse cx="87" cy="258" rx="14" ry="4" fill="#d4a574"/><path d="M78,256 Q87,250 96,256" fill="none" stroke="#8b4513" stroke-width="2"/></g><g class="part-group r-shoe"><ellipse cx="113" cy="258" rx="14" ry="4" fill="#d4a574"/><path d="M104,256 Q113,250 122,256" fill="none" stroke="#8b4513" stroke-width="2"/></g>`,
    claw: (c) => `<g class="part-group l-shoe"><ellipse cx="87" cy="258" rx="14" ry="5" fill="${c.skinColor}"/><path d="M76,260 L72,270 M82,262 L80,272 M92,262 L94,272 M98,260 L102,270" fill="none" stroke="#333" stroke-width="2"/></g><g class="part-group r-shoe"><ellipse cx="113" cy="258" rx="14" ry="5" fill="${c.skinColor}"/><path d="M102,260 L98,270 M108,262 L110,272 M118,262 L116,272 M124,260 L128,270" fill="none" stroke="#333" stroke-width="2"/></g>`
  },

  weapon: {
    none: () => `<g></g>`,
    sword: (c) => `<g class="part-group weapon-sword" transform="translate(142, 150) rotate(-15)"><path d="M0,0 L3,-50 L7,-50 L10,0" fill="${c.weaponColor}" stroke="#888" stroke-width="0.5"/><rect x="-6" y="-2" width="22" height="4" fill="#8b4513"/><rect x="0" y="2" width="10" height="18" fill="#654321"/><circle cx="5" cy="22" r="4" fill="${c.accessoryColor}"/></g>`,
    axe: (c) => `<g class="part-group weapon-axe" transform="translate(142, 150) rotate(-20)"><path d="M5,-40 L30,-50 L25,-35 L30,-20 L5,-10 Z" fill="${c.weaponColor}" stroke="#555" stroke-width="1"/><rect x="3" y="-10" width="4" height="30" fill="#654321"/></g>`,
    bow: (c) => `<g class="part-group weapon-bow" transform="translate(142, 150)"><path d="M-5,-30 Q-15,0 -5,30" fill="none" stroke="#8b4513" stroke-width="3"/><line x1="-5" y1="-30" x2="-5" y2="30" stroke="#ddd" stroke-width="0.8"/><line x1="-10" y1="5" x2="20" y2="5" stroke="#654321" stroke-width="1.5"/><polygon points="20,5 15,2 15,8" fill="${c.weaponColor}"/></g>`,
    staff: (c) => `<g class="part-group weapon-staff" transform="translate(142, 150) rotate(-10)"><rect x="3" y="-40" width="4" height="70" fill="#654321"/><circle cx="5" cy="-45" r="10" fill="none" stroke="${c.accessoryColor}" stroke-width="2"/><circle cx="5" cy="-45" r="5" fill="${c.accessoryColor}" opacity="0.8"/></g>`,
    shield: (c) => `<g class="part-group weapon-shield" transform="translate(50, 150)"><path d="M-8,-15 L8,-15 L12,5 Q12,20 0,25 Q-12,20 -12,5 Z" fill="${c.weaponColor}" stroke="#333" stroke-width="1.5"/><path d="M0,-10 L0,18 M-8,4 L8,4" stroke="${c.accessoryColor}" stroke-width="1"/></g>`,
    dagger: (c) => `<g class="part-group weapon-dagger" transform="translate(142, 150) rotate(-30)"><path d="M0,0 L2,-25 L6,-25 L8,0" fill="${c.weaponColor}"/><rect x="-3" y="0" width="14" height="3" fill="#8b4513"/><rect x="2" y="3" width="4" height="10" fill="#654321"/></g>`,
    claw: (c) => `<g class="part-group weapon-claw" transform="translate(58, 148)"><path d="M-5,0 L-3,-20 M0,0 L0,-25 M5,0 L3,-20" fill="none" stroke="${c.weaponColor}" stroke-width="2"/></g>`
  },

  accessory: {
    none: () => `<g></g>`,
    hat: (c) => `<g class="part-group accessory-hat"><ellipse cx="100" cy="15" rx="35" ry="6" fill="#654321"/><path d="M75,15 Q75,-15 100,-18 Q125,-15 125,15 Z" fill="#8b4513" stroke="#5a3510" stroke-width="1"/><rect x="75" y="10" width="50" height="6" fill="${c.accessoryColor}"/></g>`,
    crown: (c) => `<g class="part-group accessory-crown"><path d="M75,15 L80,0 L88,12 L100,-5 L112,12 L120,0 L125,15 L75,15 Z" fill="${c.accessoryColor}" stroke="#b8860b" stroke-width="1"/><circle cx="100" cy="5" r="3" fill="red"/><circle cx="85" cy="10" r="2" fill="blue"/><circle cx="115" cy="10" r="2" fill="green"/></g>`,
    glasses: () => `<g class="part-group accessory-glasses"><circle cx="92" cy="45" r="8" fill="none" stroke="#333" stroke-width="1.5"/><circle cx="108" cy="45" r="8" fill="none" stroke="#333" stroke-width="1.5"/><line x1="100" y1="45" x2="100" y2="45" stroke="#333" stroke-width="1.5"/></g>`,
    scarf: (c) => `<g class="part-group accessory-scarf"><path d="M80,78 Q100,75 120,78 L118,90 Q100,88 82,90 Z" fill="${c.accessoryColor}" stroke="#00000033" stroke-width="1"/><path d="M115,85 Q120,100 118,120 L112,118 Q114,100 110,88 Z" fill="${c.accessoryColor}" opacity="0.9"/></g>`,
    belt: (c) => `<g class="part-group accessory-belt"><rect x="75" y="135" width="50" height="6" fill="#654321"/><rect x="96" y="133" width="8" height="10" fill="${c.accessoryColor}" stroke="#8b6914" stroke-width="0.5"/></g>`,
    earrings: (c) => `<g class="part-group accessory-earrings"><circle cx="75" cy="50" r="3" fill="${c.accessoryColor}"/><circle cx="125" cy="50" r="3" fill="${c.accessoryColor}"/></g>`
  },

  monster: {
    none: () => `<g></g>`,
    wings: () => `<g class="part-group monster-wings"><path d="M80,100 Q50,60 20,80 Q40,100 60,110 Q40,130 25,150 Q55,130 80,120 Z" fill="#4a4a6a" stroke="#2a2a4a" stroke-width="1"/><path d="M120,100 Q150,60 180,80 Q160,100 140,110 Q160,130 175,150 Q145,130 120,120 Z" fill="#4a4a6a" stroke="#2a2a4a" stroke-width="1"/></g>`,
    tail: (c) => `<g class="part-group monster-tail"><path d="M110,160 Q140,180 150,220 Q155,240 145,250 Q135,240 130,220 Q125,200 115,175 Z" fill="${c.skinColor}" stroke="#00000044" stroke-width="1"/></g>`,
    horns: (c) => `<g class="part-group monster-horns"><path d="M82,20 Q70,0 72,-10 Q80,5 85,18" fill="${c.hairColor}"/><path d="M118,20 Q130,0 128,-10 Q120,5 115,18" fill="${c.hairColor}"/></g>`,
    shell: () => `<g class="part-group monster-shell"><path d="M75,90 Q55,110 60,140 Q65,160 100,160 Q135,160 140,140 Q145,110 125,90 Q100,80 75,90 Z" fill="#8b4513" stroke="#5a3010" stroke-width="1"/></g>`
  }
};

const PartOptions = {
  head: [
    { id: 'basic', name: '基础' },
    { id: 'round', name: '圆脸' },
    { id: 'angular', name: '方脸' },
    { id: 'monster', name: '怪物头' },
    { id: 'monster_horned', name: '角怪' }
  ],
  hair: [
    { id: 'none', name: '无' },
    { id: 'short', name: '短发' },
    { id: 'long', name: '长发' },
    { id: 'ponytail', name: '马尾' },
    { id: 'spiky', name: '刺猬头' },
    { id: 'bald', name: '光头' },
    { id: 'mohawk', name: '莫西干' },
    { id: 'monster_fur', name: '兽毛' }
  ],
  face: [
    { id: 'normal', name: '普通' },
    { id: 'happy', name: '开心' },
    { id: 'angry', name: '愤怒' },
    { id: 'sad', name: '悲伤' },
    { id: 'monster', name: '怪物脸' },
    { id: 'robot', name: '机器人' }
  ],
  body: [
    { id: 'basic', name: '基础' },
    { id: 'muscular', name: '肌肉' },
    { id: 'robe', name: '长袍' },
    { id: 'armor', name: '铠甲' },
    { id: 'tunic', name: '束腰外衣' },
    { id: 'monster_body', name: '怪物身' }
  ],
  arms: [
    { id: 'basic', name: '基础' },
    { id: 'muscular', name: '肌肉手臂' },
    { id: 'armored', name: '铁臂' },
    { id: 'claw', name: '利爪' }
  ],
  legs: [
    { id: 'pants', name: '长裤' },
    { id: 'armor', name: '腿甲' },
    { id: 'boot', name: '长靴裤' },
    { id: 'skirt', name: '裙子' },
    { id: 'monster_leg', name: '怪物腿' }
  ],
  footwear: [
    { id: 'basic', name: '基础鞋' },
    { id: 'boot', name: '靴子' },
    { id: 'sandal', name: '凉鞋' },
    { id: 'claw', name: '爪足' }
  ],
  weapon: [
    { id: 'none', name: '无' },
    { id: 'sword', name: '剑' },
    { id: 'axe', name: '斧' },
    { id: 'bow', name: '弓' },
    { id: 'staff', name: '法杖' },
    { id: 'shield', name: '盾' },
    { id: 'dagger', name: '匕首' },
    { id: 'claw', name: '拳爪' }
  ],
  accessory: [
    { id: 'none', name: '无' },
    { id: 'hat', name: '帽子' },
    { id: 'crown', name: '皇冠' },
    { id: 'glasses', name: '眼镜' },
    { id: 'scarf', name: '围巾' },
    { id: 'belt', name: '腰带' },
    { id: 'earrings', name: '耳环' }
  ],
  monster: [
    { id: 'none', name: '无' },
    { id: 'wings', name: '翅膀' },
    { id: 'tail', name: '尾巴' },
    { id: 'horns', name: '犄角' },
    { id: 'shell', name: '甲壳' }
  ]
};

const Presets = {
  warrior: {
    name: '战士',
    icon: '⚔️',
    parts: { head: 'basic', hair: 'short', face: 'angry', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'boot', weapon: 'sword', accessory: 'none', monster: 'none' },
    colors: { skinColor: '#f4c2a1', hairColor: '#4a3728', eyeColor: '#8b4513', bodyColor: '#71797E', pantsColor: '#5a5a5a', shoeColor: '#2d2d2d', weaponColor: '#c0c0c0', accessoryColor: '#ffd700' }
  },
  mage: {
    name: '法师',
    icon: '🧙',
    parts: { head: 'basic', hair: 'long', face: 'normal', body: 'robe', arms: 'basic', legs: 'boot', footwear: 'sandal', weapon: 'staff', accessory: 'hat', monster: 'none' },
    colors: { skinColor: '#f4c2a1', hairColor: '#6b4423', eyeColor: '#9400d3', bodyColor: '#4b0082', pantsColor: '#2d1b4e', shoeColor: '#654321', weaponColor: '#8b4513', accessoryColor: '#00bfff' }
  },
  archer: {
    name: '弓箭手',
    icon: '🏹',
    parts: { head: 'basic', hair: 'ponytail', face: 'happy', body: 'tunic', arms: 'basic', legs: 'pants', footwear: 'boot', weapon: 'bow', accessory: 'none', monster: 'none' },
    colors: { skinColor: '#f4c2a1', hairColor: '#8b4513', eyeColor: '#228b22', bodyColor: '#228b22', pantsColor: '#654321', shoeColor: '#3d2817', weaponColor: '#8b4513', accessoryColor: '#8b4513' }
  },
  knight: {
    name: '骑士',
    icon: '🛡️',
    parts: { head: 'basic', hair: 'short', face: 'normal', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'boot', weapon: 'sword', accessory: 'crown', monster: 'none' },
    colors: { skinColor: '#f4c2a1', hairColor: '#4a3728', eyeColor: '#2c3e50', bodyColor: '#a0a0a0', pantsColor: '#808080', shoeColor: '#333333', weaponColor: '#d0d0d0', accessoryColor: '#ffd700' }
  },
  slime: {
    name: '史莱姆',
    icon: '🟢',
    parts: { head: 'monster', hair: 'none', face: 'monster', body: 'monster_body', arms: 'claw', legs: 'monster_leg', footwear: 'claw', weapon: 'none', accessory: 'none', monster: 'tail' },
    colors: { skinColor: '#4caf50', hairColor: '#2e7d32', eyeColor: '#ff4444', bodyColor: '#66bb6a', pantsColor: '#388e3c', shoeColor: '#1b5e20', weaponColor: '#888', accessoryColor: '#ff9800' }
  },
  demon: {
    name: '恶魔',
    icon: '😈',
    parts: { head: 'monster_horned', hair: 'spiky', face: 'monster', body: 'muscular', arms: 'muscular', legs: 'pants', footwear: 'boot', weapon: 'axe', accessory: 'none', monster: 'wings' },
    colors: { skinColor: '#c62828', hairColor: '#1a1a1a', eyeColor: '#ff0000', bodyColor: '#8b0000', pantsColor: '#1a1a1a', shoeColor: '#000000', weaponColor: '#8b4513', accessoryColor: '#ff6600' }
  },
  robot: {
    name: '机器人',
    icon: '🤖',
    parts: { head: 'angular', hair: 'none', face: 'robot', body: 'armor', arms: 'armored', legs: 'armor', footwear: 'basic', weapon: 'claw', accessory: 'glasses', monster: 'none' },
    colors: { skinColor: '#71797E', hairColor: '#404040', eyeColor: '#00ffff', bodyColor: '#a0a0a0', pantsColor: '#606060', shoeColor: '#303030', weaponColor: '#c0c0c0', accessoryColor: '#00ffff' }
  },
  ghost: {
    name: '幽灵',
    icon: '👻',
    parts: { head: 'round', hair: 'long', face: 'sad', body: 'robe', arms: 'basic', legs: 'pants', footwear: 'sandal', weapon: 'none', accessory: 'scarf', monster: 'none' },
    colors: { skinColor: '#e0e0ff', hairColor: '#b0b0d0', eyeColor: '#0000ff', bodyColor: '#c0c0ff', pantsColor: '#a0a0d0', shoeColor: '#8080a0', weaponColor: '#aaa', accessoryColor: '#e0e0ff' }
  }
};
