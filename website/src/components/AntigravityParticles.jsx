import React, { useEffect, useRef } from 'react';

/**
 * Ultimate Dota 2 Arcana & Cyber Hologram Background Engine
 *
 * Designed for maximum visual impact ("четкий фон"):
 * 1. Interactive Ambient Cursor Spotlight (smooth chromatic aura following the mouse)
 * 2. Subtle Isometric Cyber Grid with cursor proximity illumination
 * 3. Ethereal Arcana Mana Embers with organic turbulence, glowing halos & upward drift
 * 4. Multi-layered 3D Depth (soft ambient bokeh orbs + sharp glowing starlight sparks)
 * 5. Kinetic Click Shockwaves with chromatic neon rings
 * 6. 120 FPS high-performance Canvas 2D engine
 */
const AntigravityParticles = () => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let animationFrameId;

    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    // Cursor tracking with smooth spring physics
    const mouse = {
      x: width * 0.5,
      y: height * 0.4,
      targetX: width * 0.5,
      targetY: height * 0.4,
      vx: 0,
      vy: 0,
      isHovered: false,
    };

    // Click shockwaves
    const shockwaves = [];

    const handleResize = () => {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
      initEmbers();
      initGrid();
    };

    const handleMouseMove = (e) => {
      mouse.targetX = e.clientX;
      mouse.targetY = e.clientY;
      mouse.isHovered = true;
    };

    const handleMouseLeave = () => {
      mouse.isHovered = false;
      mouse.targetX = width * 0.5;
      mouse.targetY = height * 0.4;
    };

    const handleClick = (e) => {
      shockwaves.push({
        x: e.clientX,
        y: e.clientY,
        radius: 10,
        maxRadius: 420,
        speed: 16,
        alpha: 1.0,
      });

      // Scatter nearby embers outward powerfully
      for (let i = 0; i < embers.length; i++) {
        const p = embers[i];
        const dx = p.x - e.clientX;
        const dy = p.y - e.clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 320 && dist > 0) {
          const force = (1 - dist / 320) * 26;
          p.vx += (dx / dist) * force;
          p.vy += (dy / dist) * force;
        }
      }
    };

    window.addEventListener('resize', handleResize);
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseleave', handleMouseLeave);
    window.addEventListener('click', handleClick);

    // Curated Arcana Mana & Aegis Palette
    const palette = [
      { r: 0, g: 240, b: 255 },    // Radiant Cyan
      { r: 56, g: 189, b: 248 },   // Frost Ice Blue
      { r: 168, g: 85, b: 247 },   // Invoker Arcana Violet
      { r: 192, g: 132, b: 252 },  // Ethereal Lavender
      { r: 251, g: 191, b: 36 },   // Aegis of Champions Gold
      { r: 255, g: 255, b: 255 },  // Pure Celestial Spark
    ];

    // 1. Subtle High-Tech Cyber Grid Points
    const GRID_SIZE = 54;
    let gridPoints = [];

    const initGrid = () => {
      gridPoints = [];
      const cols = Math.ceil(width / GRID_SIZE) + 1;
      const rows = Math.ceil(height / GRID_SIZE) + 1;

      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          gridPoints.push({
            x: c * GRID_SIZE,
            y: r * GRID_SIZE,
            baseAlpha: 0.04,
          });
        }
      }
    };

    // 2. Arcana Mana Embers & Stardust (160 organic particles with depth)
    let embers = [];
    const EMBER_COUNT = Math.min(Math.floor((width * height) / 8000), 220);

    const initEmbers = () => {
      embers = [];
      for (let i = 0; i < EMBER_COUNT; i++) {
        const color = palette[Math.floor(Math.random() * palette.length)];
        const layer = Math.random(); // 0: far background, 1: foreground

        // Larger orbs in background (soft bokeh), sharp sparks in foreground
        const size = layer > 0.8
          ? Math.random() * 3.5 + 2.5
          : layer > 0.4
          ? Math.random() * 2.0 + 1.2
          : Math.random() * 1.2 + 0.8;

        const x = Math.random() * width;
        const y = Math.random() * height;

        // Gentle upward and drifting velocity (like magical fireflies / embers)
        const vx = (Math.random() - 0.5) * 0.4;
        const vy = -(Math.random() * 0.6 + 0.15) * (layer + 0.5);

        embers.push({
          x,
          y,
          vx,
          vy,
          baseVx: vx,
          baseVy: vy,
          size,
          baseSize: size,
          color,
          layer,
          alpha: Math.random() * 0.5 + 0.2,
          baseAlpha: Math.random() * 0.5 + 0.2,
          pulseSpeed: Math.random() * 0.03 + 0.015,
          pulsePhase: Math.random() * Math.PI * 2,
          hasHalo: layer > 0.75,
        });
      }
    };

    initGrid();
    initEmbers();

    const startTime = performance.now();

    // Render loop
    const render = (now) => {
      const time = (now - startTime) * 0.001;

      // Smooth cursor spring interpolation
      mouse.x += (mouse.targetX - mouse.x) * 0.08;
      mouse.y += (mouse.targetY - mouse.y) * 0.08;

      ctx.clearRect(0, 0, width, height);

      // --- LAYER 1: Interactive Cursor Ambient Spotlight ---
      const spotlightRadius = Math.max(width * 0.4, 450);
      const spotlight = ctx.createRadialGradient(
        mouse.x,
        mouse.y,
        0,
        mouse.x,
        mouse.y,
        spotlightRadius
      );
      spotlight.addColorStop(0, 'rgba(0, 240, 255, 0.09)');
      spotlight.addColorStop(0.35, 'rgba(168, 85, 247, 0.05)');
      spotlight.addColorStop(0.75, 'rgba(10, 15, 30, 0.02)');
      spotlight.addColorStop(1, 'rgba(0, 0, 0, 0)');

      ctx.fillStyle = spotlight;
      ctx.fillRect(0, 0, width, height);

      // --- LAYER 2: Subtle High-Tech Cyber Grid ---
      ctx.lineWidth = 1;
      for (let i = 0; i < gridPoints.length; i++) {
        const pt = gridPoints[i];
        const dx = pt.x - mouse.x;
        const dy = pt.y - mouse.y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        // Grid nodes light up near cursor
        if (dist < 280) {
          const proximity = (1 - dist / 280);
          const alpha = pt.baseAlpha + proximity * 0.35;

          // Crosshair node
          ctx.strokeStyle = `rgba(0, 240, 255, ${alpha})`;
          ctx.beginPath();
          ctx.moveTo(pt.x - 3, pt.y);
          ctx.lineTo(pt.x + 3, pt.y);
          ctx.moveTo(pt.x, pt.y - 3);
          ctx.lineTo(pt.x, pt.y + 3);
          ctx.stroke();

          // Connected fine grid lines near cursor
          if (proximity > 0.4) {
            ctx.strokeStyle = `rgba(0, 240, 255, ${proximity * 0.1})`;
            ctx.beginPath();
            ctx.moveTo(pt.x, pt.y);
            ctx.lineTo(pt.x + GRID_SIZE, pt.y);
            ctx.lineTo(pt.x, pt.y + GRID_SIZE);
            ctx.stroke();
          }
        } else {
          // Resting faint dot
          ctx.fillStyle = `rgba(255, 255, 255, ${pt.baseAlpha})`;
          ctx.fillRect(pt.x - 0.75, pt.y - 0.75, 1.5, 1.5);
        }
      }

      // --- LAYER 3: Shockwaves ---
      ctx.globalCompositeOperation = 'lighter'; // Additive blending for crisp glow

      for (let s = shockwaves.length - 1; s >= 0; s--) {
        const sw = shockwaves[s];
        sw.radius += sw.speed;
        sw.alpha *= 0.94;

        // Double laser shockwave ring
        ctx.save();
        ctx.beginPath();
        ctx.arc(sw.x, sw.y, sw.radius, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(0, 240, 255, ${sw.alpha * 0.8})`;
        ctx.lineWidth = 2;
        ctx.shadowBlur = 20;
        ctx.shadowColor = '#00F0FF';
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(sw.x, sw.y, Math.max(0, sw.radius - 12), 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(168, 85, 247, ${sw.alpha * 0.5})`;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        ctx.restore();

        if (sw.alpha < 0.02 || sw.radius > sw.maxRadius) {
          shockwaves.splice(s, 1);
        }
      }

      // --- LAYER 4: Ethereal Arcana Mana Embers ---
      for (let i = 0; i < embers.length; i++) {
        const p = embers[i];

        // Cursor interactive physics: gentle magnetic swirl & push
        const dx = p.x - mouse.x;
        const dy = p.y - mouse.y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < 220 && dist > 0) {
          const factor = (1 - dist / 220);
          // Push slightly away so cursor clears its center, with tangential swirl
          p.vx += (dx / dist) * factor * 0.8;
          p.vy += (dy / dist) * factor * 0.8;

          // Tangential swirl (cosmic whirlpool)
          p.vx += (-dy / dist) * factor * 0.6;
          p.vy += (dx / dist) * factor * 0.6;

          p.alpha = Math.min(1, p.baseAlpha + factor * 0.5);
          p.size = p.baseSize * (1 + factor * 0.8);
        } else {
          p.alpha = p.baseAlpha;
          p.size = p.baseSize;
        }

        // Natural drag back to upward floating
        p.vx = p.vx * 0.94 + p.baseVx * 0.06;
        p.vy = p.vy * 0.94 + p.baseVy * 0.06;

        // Wave turbulence (organic drift)
        p.x += p.vx + Math.sin(time * 1.5 + p.pulsePhase) * 0.35;
        p.y += p.vy;

        // Wrap around boundaries (float upward and re-emerge at the bottom)
        if (p.y < -30) {
          p.y = height + 20;
          p.x = Math.random() * width;
        }
        if (p.x < -30) p.x = width + 20;
        else if (p.x > width + 30) p.x = -20;

        // Gentle breathing pulse
        p.pulsePhase += p.pulseSpeed;
        const finalAlpha = Math.max(0.08, Math.min(1, p.alpha + Math.sin(p.pulsePhase) * 0.15));

        // Draw glowing ember particle
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(${p.color.r}, ${p.color.g}, ${p.color.b}, ${finalAlpha})`;
        ctx.fill();

        // Soft outer luminous aura for prominent embers
        if (p.hasHalo || p.size > 2.2) {
          const haloSize = p.size * 3.2;
          ctx.beginPath();
          ctx.arc(p.x, p.y, haloSize, 0, Math.PI * 2);
          ctx.fillStyle = `rgba(${p.color.r}, ${p.color.g}, ${p.color.b}, ${finalAlpha * 0.22})`;
          ctx.fill();
        }
      }

      ctx.globalCompositeOperation = 'source-over'; // Reset blend mode

      animationFrameId = requestAnimationFrame(render);
    };

    animationFrameId = requestAnimationFrame(render);

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseleave', handleMouseLeave);
      window.removeEventListener('click', handleClick);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100vw',
        height: '100vh',
        pointerEvents: 'none',
        zIndex: 1,
      }}
    />
  );
};

export default AntigravityParticles;
