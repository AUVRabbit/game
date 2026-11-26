/* ============================================
   姿态与动画系统
   ============================================ */

const PoseSystem = {
  // 姿态定义 - 每个姿态包含各部件的变换
  poses: {
    idle: {
      name: '站立',
      icon: '🧍',
      description: '静止站立姿态',
      // 各部件的变换
      transforms: {
        'l-leg': { rotate: 0, tx: 0, ty: 0 },
        'r-leg': { rotate: 0, tx: 0, ty: 0 },
        'l-arm': { rotate: 0, tx: 0, ty: 0 },
        'r-arm': { rotate: 0, tx: 0, ty: 0 },
        'head': { rotate: 0, tx: 0, ty: 0 }
      },
      // 动画关键帧 (用于行走等循环动画)
      keyframes: null
    },

    walk: {
      name: '行走',
      icon: '🚶',
      description: '行走循环动画',
      transforms: {
        'l-leg': { rotate: 0, tx: 0, ty: 0 },
        'r-leg': { rotate: 0, tx: 0, ty: 0 },
        'l-arm': { rotate: -5, tx: 0, ty: 0 },
        'r-arm': { rotate: 5, tx: 0, ty: 0 },
        'head': { rotate: 0, tx: 0, ty: 0 }
      },
      keyframes: {
        duration: 0.6,
        frames: [
          // 左腿前，右腿后
          { 'l-leg': { rotate: -15 }, 'r-leg': { rotate: 10 }, 'l-arm': { rotate: 10 }, 'r-arm': { rotate: -10 } },
          // 中间
          { 'l-leg': { rotate: 0 }, 'r-leg': { rotate: 0 }, 'l-arm': { rotate: 0 }, 'r-arm': { rotate: 0 } },
          // 右腿前，左腿后
          { 'l-leg': { rotate: 10 }, 'r-leg': { rotate: -15 }, 'l-arm': { rotate: -10 }, 'r-arm': { rotate: 10 } },
          // 中间
          { 'l-leg': { rotate: 0 }, 'r-leg': { rotate: 0 }, 'l-arm': { rotate: 0 }, 'r-arm': { rotate: 0 } }
        ]
      }
    },

    run: {
      name: '奔跑',
      icon: '🏃',
      description: '奔跑循环动画',
      transforms: {
        'l-leg': { rotate: 0, tx: 0, ty: 0 },
        'r-leg': { rotate: 0, tx: 0, ty: 0 },
        'l-arm': { rotate: -20, tx: 0, ty: 0 },
        'r-arm': { rotate: 20, tx: 0, ty: 0 },
        'body': { rotate: 5 },
        'head': { rotate: 0, tx: 0, ty: -2 }
      },
      keyframes: {
        duration: 0.35,
        frames: [
          { 'l-leg': { rotate: -30, ty: 3 }, 'r-leg': { rotate: 20, ty: -2 }, 'l-arm': { rotate: 30 }, 'r-arm': { rotate: -30 } },
          { 'l-leg': { rotate: 10, ty: 5 }, 'r-leg': { rotate: -25, ty: -3 }, 'l-arm': { rotate: -20 }, 'r-arm': { rotate: 20 } },
          { 'l-leg': { rotate: 20, ty: -2 }, 'r-leg': { rotate: -30, ty: 3 }, 'l-arm': { rotate: -30 }, 'r-arm': { rotate: 30 } },
          { 'l-leg': { rotate: -25, ty: -3 }, 'r-leg': { rotate: 10, ty: 5 }, 'l-arm': { rotate: 20 }, 'r-arm': { rotate: -20 } }
        ]
      }
    },

    attack: {
      name: '攻击',
      icon: '⚔️',
      description: '挥砍攻击姿态',
      transforms: {
        'l-leg': { rotate: 10, tx: 0, ty: 0 },
        'r-leg': { rotate: -15, tx: 0, ty: 0 },
        'l-arm': { rotate: -20, tx: 0, ty: 0 },
        'r-arm': { rotate: 45, tx: 0, ty: -10 },
        'body': { rotate: -5, tx: 0, ty: 0 },
        'head': { rotate: -5, tx: 0, ty: 0 }
      },
      keyframes: {
        duration: 0.4,
        frames: [
          // 准备
          { 'r-arm': { rotate: -30, ty: 5 }, 'body': { rotate: 5 }, 'l-leg': { rotate: -5 }, 'r-leg': { rotate: 5 } },
          // 挥击
          { 'r-arm': { rotate: 60, ty: -15 }, 'body': { rotate: -10 }, 'l-leg': { rotate: 15 }, 'r-leg': { rotate: -10 } },
          // 收势
          { 'r-arm': { rotate: 20, ty: 0 }, 'body': { rotate: 0 }, 'l-leg': { rotate: 5 }, 'r-leg': { rotate: -5 } },
          // 恢复
          { 'r-arm': { rotate: 0 }, 'body': { rotate: 0 }, 'l-leg': { rotate: 0 }, 'r-leg': { rotate: 0 } }
        ]
      }
    },

    hit: {
      name: '受击',
      icon: '💥',
      description: '被击中姿态',
      transforms: {
        'l-leg': { rotate: 5, tx: 0, ty: 0 },
        'r-leg': { rotate: -5, tx: 0, ty: 0 },
        'l-arm': { rotate: 25, tx: 0, ty: 0 },
        'r-arm': { rotate: -25, tx: 0, ty: 0 },
        'body': { rotate: 8, tx: 0, ty: 0 },
        'head': { rotate: 15, tx: 0, ty: 0 }
      },
      keyframes: {
        duration: 0.3,
        frames: [
          { 'body': { rotate: 15 }, 'head': { rotate: 20 }, 'l-arm': { rotate: 35 }, 'r-arm': { rotate: -35 } },
          { 'body': { rotate: 5 }, 'head': { rotate: 10 }, 'l-arm': { rotate: 15 }, 'r-arm': { rotate: -15 } },
          { 'body': { rotate: -3 }, 'head': { rotate: -5 }, 'l-arm': { rotate: -5 }, 'r-arm': { rotate: 5 } },
          { 'body': { rotate: 0 }, 'head': { rotate: 0 }, 'l-arm': { rotate: 0 }, 'r-arm': { rotate: 0 } }
        ]
      }
    },

    jump: {
      name: '跳跃',
      icon: '⬆️',
      description: '跳跃姿态',
      transforms: {
        'l-leg': { rotate: -20, tx: 0, ty: -5 },
        'r-leg': { rotate: 20, tx: 0, ty: -5 },
        'l-arm': { rotate: -45, tx: 0, ty: -5 },
        'r-arm': { rotate: 45, tx: 0, ty: -5 },
        'body': { rotate: 0, tx: 0, ty: -10 },
        'head': { rotate: 0, tx: 0, ty: 0 }
      },
      keyframes: {
        duration: 0.5,
        frames: [
          // 蹲踞准备
          { 'l-leg': { rotate: 25, ty: 8 }, 'r-leg': { rotate: -25, ty: 8 }, 'l-arm': { rotate: 20 }, 'r-arm': { rotate: -20 }, 'body': { ty: 5 } },
          // 起跳
          { 'l-leg': { rotate: -10, ty: -3 }, 'r-leg': { rotate: 10, ty: -3 }, 'l-arm': { rotate: -30 }, 'r-arm': { rotate: 30 }, 'body': { ty: -5 } },
          // 最高点
          { 'l-leg': { rotate: -30, ty: -8 }, 'r-leg': { rotate: 30, ty: -8 }, 'l-arm': { rotate: -50 }, 'r-arm': { rotate: 50 }, 'body': { ty: -15 } },
          // 下落
          { 'l-leg': { rotate: -15, ty: 0 }, 'r-leg': { rotate: 15, ty: 0 }, 'l-arm': { rotate: -20 }, 'r-arm': { rotate: 20 }, 'body': { ty: -5 } }
        ]
      }
    },

    interact: {
      name: '交互',
      icon: '🤝',
      description: '与物体交互姿态',
      transforms: {
        'l-leg': { rotate: 0, tx: 0, ty: 0 },
        'r-leg': { rotate: 0, tx: 0, ty: 0 },
        'l-arm': { rotate: -30, tx: 0, ty: 5 },
        'r-arm': { rotate: 30, tx: 0, ty: 5 },
        'body': { rotate: 5, tx: 0, ty: 0 },
        'head': { rotate: 5, tx: 0, ty: 0 }
      },
      keyframes: {
        duration: 0.8,
        frames: [
          { 'l-arm': { rotate: -20, ty: 0 }, 'r-arm': { rotate: 20, ty: 0 }, 'body': { rotate: 3 }, 'head': { rotate: 3 } },
          { 'l-arm': { rotate: -40, ty: 8 }, 'r-arm': { rotate: 40, ty: 8 }, 'body': { rotate: 8 }, 'head': { rotate: 8 } },
          { 'l-arm': { rotate: -30, ty: 5 }, 'r-arm': { rotate: 30, ty: 5 }, 'body': { rotate: 5 }, 'head': { rotate: 5 } },
          { 'l-arm': { rotate: -20, ty: 0 }, 'r-arm': { rotate: 20, ty: 0 }, 'body': { rotate: 3 }, 'head': { rotate: 3 } }
        ]
      }
    },

    cast: {
      name: '施法',
      icon: '✨',
      description: '施放魔法姿态',
      transforms: {
        'l-leg': { rotate: 0, tx: 0, ty: 0 },
        'r-leg': { rotate: 0, tx: 0, ty: 0 },
        'l-arm': { rotate: -45, tx: -5, ty: -5 },
        'r-arm': { rotate: 45, tx: 5, ty: -5 },
        'body': { rotate: 0, tx: 0, ty: 0 },
        'head': { rotate: 0, tx: 0, ty: -3 }
      },
      keyframes: {
        duration: 1.0,
        frames: [
          { 'l-arm': { rotate: -20, ty: 0 }, 'r-arm': { rotate: 20, ty: 0 }, 'head': { rotate: 0, ty: 0 } },
          { 'l-arm': { rotate: -55, ty: -10 }, 'r-arm': { rotate: 55, ty: -10 }, 'head': { rotate: 0, ty: -8 } },
          { 'l-arm': { rotate: -50, ty: -8 }, 'r-arm': { rotate: 50, ty: -8 }, 'head': { rotate: 0, ty: -5 } },
          { 'l-arm': { rotate: -30, ty: 0 }, 'r-arm': { rotate: 30, ty: 0 }, 'head': { rotate: 0, ty: 0 } }
        ]
      }
    }
  },

  // 获取指定姿态的变换CSS
  getPoseTransform(poseId, partClass) {
    const pose = this.poses[poseId];
    if (!pose) return '';
    
    const transform = pose.transforms[partClass];
    if (!transform) return '';
    
    let css = '';
    if (transform.rotate) css += `rotate(${transform.rotate}deg) `;
    if (transform.tx) css += `translateX(${transform.tx}px) `;
    if (transform.ty) css += `translateY(${transform.ty}px) `;
    
    return css.trim();
  },

  // 获取帧数据
  getFrameData(poseId, frameIndex) {
    const pose = this.poses[poseId];
    if (!pose || !pose.keyframes) return pose ? pose.transforms : {};
    
    return pose.keyframes.frames[frameIndex] || pose.transforms;
  },

  // 生成CSS动画关键帧
  generateCSSKeyframes(poseId) {
    const pose = this.poses[poseId];
    if (!pose || !pose.keyframes) return null;
    
    const frames = pose.keyframes.frames;
    const duration = pose.keyframes.duration;
    
    let css = '';
    
    // 为每个有动画的部件生成关键帧
    const animatedParts = new Set();
    frames.forEach(frame => {
      Object.keys(frame).forEach(part => animatedParts.add(part));
    });
    
    animatedParts.forEach(part => {
      css += `@keyframes ${poseId}-${part.replace(/[^a-z]/gi, '')} {\n`;
      
      frames.forEach((frame, i) => {
        const percentage = (i / (frames.length - 1)) * 100;
        const transform = frame[part] || {};
        let transformStr = '';
        
        if (transform.rotate) transformStr += `rotate(${transform.rotate}deg) `;
        if (transform.tx) transformStr += `translateX(${transform.tx}px) `;
        if (transform.ty) transformStr += `translateY(${transform.ty}px) `;
        
        if (!transformStr) transformStr = 'none';
        
        css += `  ${percentage}% { transform: ${transformStr.trim()}; }\n`;
      });
      
      css += `}\n`;
    });
    
    return { css, duration, animatedParts: [...animatedParts] };
  }
};

// 多方向姿态（上下左右四方向）
const DirectionalPoses = {
  // 行走的四方向帧
  walk_directions: {
    down: {
      frames: [
        { lLeg: { rotate: -10 }, rLeg: { rotate: 10 }, lArm: { rotate: 8 }, rArm: { rotate: -8 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } },
        { lLeg: { rotate: 10 }, rLeg: { rotate: -10 }, lArm: { rotate: -8 }, rArm: { rotate: 8 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } }
      ]
    },
    up: {
      frames: [
        { lLeg: { rotate: -8 }, rLeg: { rotate: 8 }, lArm: { rotate: -8 }, rArm: { rotate: 8 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } },
        { lLeg: { rotate: 8 }, rLeg: { rotate: -8 }, lArm: { rotate: 8 }, rArm: { rotate: -8 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } }
      ]
    },
    left: {
      frames: [
        { lLeg: { rotate: -12 }, rLeg: { rotate: 12 }, lArm: { rotate: 5 }, rArm: { rotate: -5 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } },
        { lLeg: { rotate: 12 }, rLeg: { rotate: -12 }, lArm: { rotate: -5 }, rArm: { rotate: 5 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } }
      ]
    },
    right: {
      frames: [
        { lLeg: { rotate: -12 }, rLeg: { rotate: 12 }, lArm: { rotate: -5 }, rArm: { rotate: 5 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } },
        { lLeg: { rotate: 12 }, rLeg: { rotate: -12 }, lArm: { rotate: 5 }, rArm: { rotate: -5 } },
        { lLeg: { rotate: 0 }, rLeg: { rotate: 0 }, lArm: { rotate: 0 }, rArm: { rotate: 0 } }
      ]
    }
  }
};
