import React, { useState, useEffect, useRef } from 'react';
import AntigravityParticles from './components/AntigravityParticles';
import LineSidebar from './components/LineSidebar';
import BorderGlow from './components/BorderGlow';
import CustomCursor from './components/CustomCursor';
import LiveStats from './components/LiveStats';
import ScrollReveal from './components/ScrollReveal';
import { playSound, toggleMute } from './utils/audio';
import aegisNeonImg from './assets/aegis_neon.jpg';
import heroesBannerImg from './assets/heroes_banner.jpg';
import './App.css';

// 3D Tilt Card Wrapper
const TiltCard = ({ children, className = '' }) => {
  const [style, setStyle] = useState({});
  const cardRef = useRef(null);

  const handleMouseMove = (e) => {
    const card = cardRef.current;
    if (!card) return;
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateX = ((y - centerY) / centerY) * -8;
    const rotateY = ((x - centerX) / centerX) * 8;

    setStyle({
      transform: `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale3d(1.02, 1.02, 1.02)`,
      transition: 'none',
      zIndex: 10,
    });
  };

  const handleMouseLeave = () => {
    setStyle({
      transform: 'perspective(1000px) rotateX(0) rotateY(0) scale3d(1, 1, 1)',
      transition: 'all 0.5s cubic-bezier(0.16, 1, 0.3, 1)',
      zIndex: 1,
    });
  };

  return (
    <div
      ref={cardRef}
      className={`tilt-card-wrapper ${className}`}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={style}
    >
      {children}
    </div>
  );
};

// Global reference for smooth scroll animation to allow clean cancellations
let scrollRafId = null;

const smoothScrollTo = (targetY, duration) => {
  if (scrollRafId) {
    cancelAnimationFrame(scrollRafId);
    scrollRafId = null;
  }

  const startY = window.pageYOffset;
  const distance = targetY - startY;
  if (Math.abs(distance) < 4) return;

  // Dynamic cinematic duration: longer distance = longer, smoother gliding time
  const calculatedDuration = duration || Math.min(Math.max(Math.abs(distance) * 0.45, 800), 1500);
  const startTime = performance.now();

  const step = (currentTime) => {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / calculatedDuration, 1);

    // easeInOutQuart: smooth acceleration and luxury deceleration
    const ease = progress < 0.5
      ? 8 * progress * progress * progress * progress
      : 1 - Math.pow(-2 * progress + 2, 4) / 2;

    window.scrollTo(0, startY + distance * ease);

    if (progress < 1) {
      scrollRafId = requestAnimationFrame(step);
    } else {
      scrollRafId = null;
    }
  };

  scrollRafId = requestAnimationFrame(step);
};

function App() {
  const [isMuted, setIsMuted] = useState(false);
  const [copied, setCopied] = useState(false);
  const [activeSection, setActiveSection] = useState(0);

  // Download Modal state
  const [showDownloadModal, setShowDownloadModal] = useState(false);

  // Cloud Loadout Builder state
  const [selectedHero, setSelectedHero] = useState('Juggernaut');
  const [equippedSlots, setEquippedSlots] = useState({
    Arcana: 'Bladeform Legacy (Origins of Faith)',
    Weapon: 'Dragon Sword of the Crimson Witness',
    Head: 'Visage of the Exiled Ronin',
    Announcer: 'Gabe Newell Mega-Kill Pack',
    Weather: 'Weather Aurora',
  });
  const [copiedCode, setCopiedCode] = useState(false);

  // Terminal state
  const [isInjecting, setIsInjecting] = useState(false);
  const [injectionLogs, setInjectionLogs] = useState([
    { text: '[SYSTEM] ImmortalHub Core VPK v1.1.0 initialized.', type: 'info' },
    { text: '[GSI] Listening for Dota 2 Game State Integration...', type: 'dim' },
    { text: '[STATUS] Engine ready. Click "Simulate VPK Injection" below to test hook.', type: 'accent' },
  ]);

  // Audio test state
  const [activeAudioIndex, setActiveAudioIndex] = useState(null);

  // FAQ open state
  const [openFaq, setOpenFaq] = useState(0);

  const sidebarItems = ['Overview', 'Showcase', 'Loadouts', 'Features', 'Console', 'FAQ', 'GitHub'];

  // Scroll Spy: dynamically highlight active section as user scrolls
  useEffect(() => {
    const sections = ['overview', 'showcase', 'loadouts', 'features', 'console', 'faq'];
    const handleScroll = () => {
      const scrollPosition = window.scrollY + 160;
      for (let i = sections.length - 1; i >= 0; i--) {
        const el = document.getElementById(sections[i]);
        if (el) {
          const top = el.offsetTop;
          if (scrollPosition >= top) {
            setActiveSection(i);
            break;
          }
        }
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleSidebarClick = (index, label) => {
    playSound('click');
    if (label === 'GitHub') {
      window.open('https://github.com/Harsed11/ImmortalHub', '_blank');
    } else {
      const idMap = {
        Overview: 'overview',
        Showcase: 'showcase',
        Loadouts: 'loadouts',
        Features: 'features',
        Console: 'console',
        FAQ: 'faq',
      };
      const elementId = idMap[label];
      const el = document.getElementById(elementId);
      if (el) {
        setActiveSection(index);
        const yOffset = -50;
        const targetY = Math.max(0, el.getBoundingClientRect().top + window.pageYOffset + yOffset);
        smoothScrollTo(targetY);
      }
    }
  };

  const handleRunInjection = () => {
    if (isInjecting) return;
    setIsInjecting(true);
    playSound('inject');

    const steps = [
      { text: '[PROCESS] Locating dota2.exe (x64) process space...', delay: 300, type: 'info' },
      { text: '[VPK] Initializing virtual VFS redirector (bypass pak01_dir)...', delay: 850, type: 'info' },
      { text: '[LOADOUT] Injecting full cosmetic Arcana & Immortal overrides...', delay: 1500, type: 'accent' },
      { text: '[SOUND] Activating Gabe Newell Announcer & custom kill sounds...', delay: 2100, type: 'info' },
      { text: '[GSI] Connected to live match state via port 3000 (0ms latency).', delay: 2700, type: 'accent' },
      { text: '[SUCCESS] INJECTION COMPLETE: All Arcanas active in-game!', delay: 3300, type: 'success' },
    ];

    setInjectionLogs([{ text: '[ACTION] Initializing live injection routine...', type: 'dim' }]);

    steps.forEach(({ text, delay, type }) => {
      setTimeout(() => {
        setInjectionLogs((prev) => [...prev, { text, type }]);
        playSound('click');
        if (type === 'success') {
          setIsInjecting(false);
          playSound('equip');
        }
      }, delay);
    });
  };

  const handleCopyCommand = () => {
    playSound('copy');
    navigator.clipboard.writeText('git clone https://github.com/Harsed11/ImmortalHub.git');
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const handleSoundToggle = () => {
    const newState = toggleMute();
    setIsMuted(newState);
    if (!newState) playSound('click');
  };

  const handlePlaySample = (type, index) => {
    setActiveAudioIndex(index);
    playSound(type);
    setTimeout(() => setActiveAudioIndex(null), 600);
  };

  return (
    <div className="app-wrapper">
      <CustomCursor />
      {/* Dense Antigravity Stardust Particle Field */}
      <AntigravityParticles />

      {/* Floating Sound Toggle */}
      <button className="sound-toggle-btn" onClick={handleSoundToggle} title="Toggle Sound FX">
        {isMuted ? '🔇 Sound: OFF' : '🔊 Sound: ON'}
      </button>

      <div className="layout-container">
        {/* Left Interactive Sidebar from React Bits - Pinned to screen edge */}
        <aside className="sidebar-container">
          <div
            className="sidebar-brand"
            onClick={() => {
              playSound('click');
              smoothScrollTo(0);
            }}
            style={{ cursor: 'pointer' }}
            title="Scroll to top"
          >
            <div className="brand-header-row">
              <img src={aegisNeonImg} alt="Aegis" className="brand-mini-aegis" />
              <div>
                <span className="brand-badge">VPK ENGINE</span>
                <h2 className="brand-logo">
                  Immortal<span className="neon-text">Hub</span>
                </h2>
              </div>
            </div>
          </div>

          <LineSidebar
            items={sidebarItems}
            accentColor="#00F0FF"
            textColor="#a0a0b0"
            markerColor="#2a2a35"
            active={activeSection}
            onItemClick={handleSidebarClick}
          />

          <div className="sidebar-footer">
            <div className="status-pill">
              <span className="status-dot"></span>
              <span>Dota 2 v7.38 Online</span>
            </div>
            <a
              href="https://github.com/Harsed11/ImmortalHub"
              target="_blank"
              rel="noreferrer"
              className="sidebar-repo-link"
              onClick={() => playSound('click')}
            >
              ★ Star on GitHub
            </a>
          </div>
        </aside>

        {/* Main Content Sections */}
        <main className="main-content">
          {/* Hero Section */}
          <ScrollReveal delay={0.1}>
            <section id="overview" className="hero-section">
            <div className="hero-grid">
              {/* Left Column: Copy & Actions */}
              <div className="hero-left-col fade-in-up">
                <div className="hero-eyebrow">
                  <span className="pulse-dot"></span>
                  <span className="eyebrow-text">NEXT-GEN DOTA 2 SKIN CHANGER</span>
                  <span className="pill-tag">VAC-SAFE</span>
                </div>

                <h1 className="hero-title">
                  All Arcanas.<br />
                  <span className="neon-text glow-pulse">Zero Latency.</span><br />
                  100% Free.
                </h1>

                <p className="hero-subtitle">
                  The ultimate skin changer for Dota 2. Built with native Game State Integration,
                  automatic VPK conflict cleaning, custom announcers, and instant in-game hotkeys.
                </p>

                <div className="hero-actions">
                  <button
                    className="btn-glitch"
                    onClick={() => {
                      playSound('click');
                      setShowDownloadModal(true);
                    }}
                  >
                    <span className="btn-icon">⚡</span> GET IMMORTALHUB
                  </button>

                  <button className="btn-clone" onClick={handleCopyCommand}>
                    <span className="btn-code-text">git clone ImmortalHub</span>
                    <span className="copy-tag">{copied ? '✓ COPIED' : 'COPY'}</span>
                  </button>
                </div>

                {/* Quick Stat Highlights */}
                <div className="hero-stats-row">
                  <div className="stat-box">
                    <span className="stat-number">0 ms</span>
                    <span className="stat-label">Injection Latency</span>
                  </div>
                  <div className="stat-divider"></div>
                  <div className="stat-box">
                    <span className="stat-number">124+</span>
                    <span className="stat-label">Heroes Supported</span>
                  </div>
                  <div className="stat-divider"></div>
                  <div className="stat-box">
                    <span className="stat-number">100%</span>
                    <span className="stat-label">Open Source</span>
                  </div>
                  <div className="stat-divider"></div>
                  <div className="stat-box">
                    <span className="stat-number">0 Ban</span>
                    <span className="stat-label">VAC-Safe GSI</span>
                  </div>
                </div>
              </div>

              {/* Right Column: Holographic Aegis Visual Card */}
              <div className="hero-right-col fade-in-up">
                <TiltCard>
                  <div className="hero-aegis-card">
                    <div className="aegis-image-container">
                      <img src={aegisNeonImg} alt="ImmortalHub Neon Aegis" className="hero-aegis-img" />
                      <div className="aegis-radial-glow"></div>
                    </div>
                    <div className="aegis-card-overlay">
                      <div className="overlay-badge">
                        <span className="live-ring"></span>
                        <span>IMMORTALHUB RUNTIME</span>
                      </div>
                      <h3 className="overlay-title">Aegis of Champions Edition</h3>
                      <p className="overlay-sub">
                        142+ Arcanas, 850+ Immortals, Weather Effects & Audio Packs Unlocked
                      </p>
                      <div className="overlay-tags">
                        <span>#Dota2</span>
                        <span>#VPK-Engine</span>
                        <span>#ClientSideOnly</span>
                      </div>
                    </div>
                  </div>
                </TiltCard>
              </div>
            </div>
            
            <LiveStats />
          </section>
          </ScrollReveal>

          {/* Marquee Ticker */}
          <div className="marquee-wrapper">
            <div className="marquee-content">
              <span>⚡ ALL ARCANAS UNLOCKED</span>
              <span>•</span>
              <span>🎮 ZERO LATENCY VPK HOOK</span>
              <span>•</span>
              <span>🛡️ AUTO MOD CONFLICT CLEANER</span>
              <span>•</span>
              <span>🔊 CUSTOM ANNOUNCERS & KILL SOUNDS</span>
              <span>•</span>
              <span>🌦️ WEATHER ASH, RAIN & AURORA</span>
              <span>•</span>
              <span>⚡ ALL ARCANAS UNLOCKED</span>
              <span>•</span>
              <span>🎮 ZERO LATENCY VPK HOOK</span>
              <span>•</span>
              <span>🛡️ AUTO MOD CONFLICT CLEANER</span>
              <span>•</span>
              <span>🔊 CUSTOM ANNOUNCERS & KILL SOUNDS</span>
              <span>•</span>
              <span>🌦️ WEATHER ASH, RAIN & AURORA</span>
            </div>
          </div>

          {/* Panoramic Visual Showcase Section */}
          <ScrollReveal delay={0.15}>
          <section id="showcase" className="showcase-section">
            <div className="section-header">
              <span className="section-badge">COSMETICS CATALOG</span>
              <h2 className="section-title">Battlefield Transformation</h2>
              <p className="section-desc">
                From Juggernaut's Bladeform Legacy to Phantom Assassin's Manifold Paradox and Invoker's Dark Artistry.
                Experience pristine custom models with full ambient spell particles.
              </p>
            </div>

            {/* Banner Showcase with Glass Overlays */}
            <div className="showcase-banner-card">
              <img
                src={heroesBannerImg}
                alt="Dota 2 Arcana Heroes Showcase"
                className="showcase-banner-img"
              />
              <div className="showcase-banner-gradient"></div>

              <div className="showcase-hero-highlights">
                <div className="hero-highlight-pill">
                  <span className="pill-dot blue"></span>
                  <div>
                    <strong>Juggernaut</strong>
                    <span>Bladeform Legacy Arcana</span>
                  </div>
                </div>

                <div className="hero-highlight-pill center">
                  <span className="pill-dot teal"></span>
                  <div>
                    <strong>Phantom Assassin</strong>
                    <span>Manifold Paradox Origins</span>
                  </div>
                </div>

                <div className="hero-highlight-pill">
                  <span className="pill-dot purple"></span>
                  <div>
                    <strong>Invoker</strong>
                    <span>Dark Artistry & Sunburst FX</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Interactive Audio Announcer Soundboard */}
            <div className="soundboard-card">
              <div className="soundboard-header">
                <div>
                  <span className="soundboard-badge">AUDIO ENGINE</span>
                  <h3 className="soundboard-title">Custom Announcer & Sound FX Tester</h3>
                </div>
                <span className="soundboard-hint">Click below to test in-game announcer triggers</span>
              </div>

              <div className="soundboard-grid">
                {[
                  { label: 'Gabe Newell Announcer', desc: 'Mega-Kill streak alert', sound: 'inject' },
                  { label: 'Deus Ex Kill Sound', desc: 'Ultra-Kill bass drop', sound: 'equip' },
                  { label: 'Rick & Morty Pack', desc: 'First Blood trigger line', sound: 'copy' },
                  { label: 'Immortal Level-Up', desc: 'Shimmering chord chime', sound: 'equip' },
                ].map((item, idx) => (
                  <button
                    key={idx}
                    className={`soundboard-btn ${activeAudioIndex === idx ? 'playing' : ''}`}
                    onClick={() => handlePlaySample(item.sound, idx)}
                  >
                    <span className="play-icon">{activeAudioIndex === idx ? '🔊' : '▶'}</span>
                    <div className="sound-meta">
                      <span className="sound-name">{item.label}</span>
                      <span className="sound-desc">{item.desc}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </section>
          </ScrollReveal>

          {/* Cloud Loadout Builder Section */}
          <ScrollReveal delay={0.15}>
          <section id="loadouts" className="loadouts-section">
            <div className="section-header">
              <span className="section-badge">CLOUD PRESETS</span>
              <h2 className="section-title">Cloud Loadout Generator</h2>
              <p className="section-desc">
                Select your hero cosmetics, generate a portable 6-character loadout code, and share your dream setup with friends or load it instantly in ImmortalHub.
              </p>
            </div>

            <div className="loadouts-builder-card">
              {/* Hero Selector Tabs */}
              <div className="builder-heroes-row">
                {[
                  { name: 'Juggernaut', role: 'Carry', icon: '⚔️' },
                  { name: 'Invoker', role: 'Mid', icon: '🔮' },
                  { name: 'Phantom Assassin', role: 'Carry', icon: '🗡️' },
                  { name: 'Shadow Fiend', role: 'Mid', icon: '💀' },
                ].map((hero) => (
                  <button
                    key={hero.name}
                    className={`builder-hero-tab ${selectedHero === hero.name ? 'active' : ''}`}
                    onClick={() => {
                      playSound('click');
                      setSelectedHero(hero.name);
                    }}
                  >
                    <span className="tab-hero-icon">{hero.icon}</span>
                    <div className="tab-hero-meta">
                      <span className="tab-hero-name">{hero.name}</span>
                      <span className="tab-hero-role">{hero.role}</span>
                    </div>
                  </button>
                ))}
              </div>

              {/* Equippable Slots Grid */}
              <div className="builder-slots-grid">
                {[
                  { slot: 'Arcana', item: selectedHero === 'Juggernaut' ? 'Bladeform Legacy (Origins of Faith)' : selectedHero === 'Invoker' ? 'Dark Artistry Prismatic' : selectedHero === 'Phantom Assassin' ? 'Manifold Paradox Origins' : 'Demon Eater of the Abysm', tag: 'MYTHICAL', free: '$35.99 FREE' },
                  { slot: 'Weapon', item: selectedHero === 'Juggernaut' ? 'Dragon Sword of Crimson Witness' : selectedHero === 'Invoker' ? 'Apex Magus Prismatic Crest' : selectedHero === 'Phantom Assassin' ? 'Scythe of Ice & Shadow' : 'Arms of Desolation (Immortal)', tag: 'IMMORTAL', free: '$140.00 FREE' },
                  { slot: 'Head / Armor', item: selectedHero === 'Juggernaut' ? 'Visage of the Exiled Ronin' : selectedHero === 'Invoker' ? 'Hair of the Dark Artistry' : selectedHero === 'Phantom Assassin' ? 'Creep Stalker Epaulets' : 'Crown of the Eternal Harvest', tag: 'IMMORTAL', free: '$85.00 FREE' },
                  { slot: 'Announcer', item: 'Gabe Newell Mega-Kill Pack', tag: 'AUDIO', free: '$9.99 FREE' },
                  { slot: 'Weather', item: 'Weather Aurora & Ash Pack', tag: 'TERRAIN', free: '$15.00 FREE' },
                ].map((item, idx) => (
                  <div key={idx} className="builder-slot-item">
                    <div className="slot-item-top">
                      <span className="slot-badge">{item.slot}</span>
                      <span className="slot-free-tag">{item.free}</span>
                    </div>
                    <span className="slot-item-name">{item.item}</span>
                    <div className="slot-status-active">
                      <span className="slot-dot"></span>
                      <span>ACTIVE IN CODE</span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Live Generated Share Code Bar */}
              <div className="builder-code-bar">
                <div className="code-bar-left">
                  <span className="code-label">PORTABLE LOADOUT CODE:</span>
                  <span className="code-value">
                    IH-{selectedHero.substring(0, 3).toUpperCase()}-ARC{selectedHero === 'Juggernaut' ? '7X' : selectedHero === 'Invoker' ? '9K' : selectedHero === 'Phantom Assassin' ? '4M' : '8D'}
                  </span>
                </div>
                <div className="code-bar-actions">
                  <button
                    className="btn-copy-code"
                    onClick={() => {
                      playSound('copy');
                      navigator.clipboard.writeText(`IH-${selectedHero.substring(0, 3).toUpperCase()}-ARC9X`);
                      setCopiedCode(true);
                      setTimeout(() => setCopiedCode(false), 2000);
                    }}
                  >
                    {copiedCode ? '✓ CODE COPIED' : '📋 COPY LOADOUT CODE'}
                  </button>
                  <div style={{ display: 'flex', gap: '12px' }}>
                    <button
                      className="btn-open-app"
                      onClick={() => {
                        playSound('click');
                        setShowDownloadModal(true);
                      }}
                    >
                      ⚡ GET IMMORTALHUB (.EXE)
                    </button>
                    <button
                      className="btn-open-app"
                      style={{ background: 'rgba(168, 85, 247, 0.2)', borderColor: 'var(--neon-violet)', color: '#E9D5FF' }}
                      onClick={() => {
                        playSound('click');
                        window.location.href = `immortalhub://loadout/IH-${selectedHero.substring(0, 3).toUpperCase()}-ARC9X`;
                      }}
                    >
                      🚀 LAUNCH IN APP
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </section>
          </ScrollReveal>

          {/* Features Section using React Bits BorderGlow */}
          <ScrollReveal delay={0.15}>
          <section id="features" className="features-section">
            <div className="section-header">
              <span className="section-badge">CORE CAPABILITIES</span>
              <h2 className="section-title">Engine Architecture</h2>
              <p className="section-desc">
                Engineered for competitive players who demand pure visual fidelity with zero lag and zero game bans.
              </p>
            </div>

            <div className="features-grid">
              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="185 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#00F0FF', '#B026FF', '#00FFAA']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-cyan">⚡</div>
                    <span className="feature-tag">0 FPS DROP</span>
                    <h3 className="feature-heading">Zero Latency Hook</h3>
                    <p className="feature-text">
                      Direct VPK redirection in memory. Does not render overlays or hook DirectX draw calls,
                      ensuring your frame times remain identical to pristine vanilla Dota 2.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>

              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="280 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#B026FF', '#00F0FF', '#00FFAA']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-purple">🛡️</div>
                    <span className="feature-tag">100% VAC-SAFE</span>
                    <h3 className="feature-heading">Game State Sync</h3>
                    <p className="feature-text">
                      Uses official Valve Game State Integration (GSI) JSON payloads to detect chosen heroes,
                      ward states, and match transitions without touching anti-cheat protected game memory.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>

              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="160 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#00FFAA', '#00F0FF', '#B026FF']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-green">🧹</div>
                    <span className="feature-tag">SMART CLEANUP</span>
                    <h3 className="feature-heading">Conflict Resolver</h3>
                    <p className="feature-text">
                      Automatically detects and purges broken outdated `.vmdl_c` overrides before applying fresh
                      mods, preventing blue-screen crashes and missing purple checkerboard textures.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>

              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="40 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#F59E0B', '#EF4444', '#00F0FF']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-gold">🔊</div>
                    <span className="feature-tag">AUDIO PACKS</span>
                    <h3 className="feature-heading">Custom Announcers</h3>
                    <p className="feature-text">
                      Swap default announcer lines with legendary packs: Gabe Newell, Rick & Morty, Deus Ex,
                      Dark Willow, and custom bass-boosted Mega-Kill sound triggers.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>

              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="200 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#00F0FF', '#3B82F6', '#B026FF']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-blue">☁️</div>
                    <span className="feature-tag">PORTABLE</span>
                    <h3 className="feature-heading">Cloud Loadouts</h3>
                    <p className="feature-text">
                      Export your favorite hero cosmetic combinations to a portable 6-character code. Share your
                      dream loadouts with friends or load them instantly on any PC.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>

              <TiltCard>
                <BorderGlow
                  edgeSensitivity={30}
                  glowColor="320 100 50"
                  backgroundColor="rgba(18, 15, 23, 0.45)"
                  borderRadius={24}
                  glowRadius={35}
                  glowIntensity={1.4}
                  colors={['#EC4899', '#8B5CF6', '#00F0FF']}
                  className="glass-feature-card"
                >
                  <div className="feature-card-body">
                    <div className="feature-icon-wrapper glow-pink">⌨️</div>
                    <span className="feature-tag">HOTKEY SWITCH</span>
                    <h3 className="feature-heading">Live In-Game Toggle</h3>
                    <p className="feature-text">
                      Press your assigned hotkey (default: `F7`) inside Dota 2 to swap skins in real time during
                      strategy time or in demo mode without restarting the game client.
                    </p>
                  </div>
                </BorderGlow>
              </TiltCard>
            </div>
          </section>
          </ScrollReveal>

          {/* Interactive Live VPK Terminal Console */}
          <ScrollReveal delay={0.15}>
          <section id="console" className="terminal-section">
            <div className="section-header">
              <span className="section-badge">INTERACTIVE CONSOLE</span>
              <h2 className="section-title">Live VPK Engine Terminal</h2>
              <p className="section-desc">
                Simulate how ImmortalHub seamlessly interfaces with Dota 2 game client processes in real time.
              </p>
            </div>

            <div className="cyber-terminal-card">
              <div className="terminal-topbar">
                <div className="terminal-dots">
                  <span className="tdot red"></span>
                  <span className="tdot yellow"></span>
                  <span className="tdot green"></span>
                </div>
                <span className="terminal-title">immortalhub_injector_x64.exe - Live Debug Stream</span>
                <span className="terminal-badge">PID: 14280</span>
              </div>

              <div className="terminal-log-window">
                {injectionLogs.map((log, idx) => (
                  <div key={idx} className={`terminal-line ${log.type}`}>
                    <span className="prompt-arrow">❯</span>
                    <span className="line-text">{log.text}</span>
                  </div>
                ))}
                {isInjecting && (
                  <div className="terminal-line pulsing">
                    <span className="prompt-arrow">❯</span>
                    <span className="line-text">Hooking memory sectors...</span>
                  </div>
                )}
              </div>

              <div className="terminal-actions-bar">
                <button
                  className={`btn-test-inject ${isInjecting ? 'loading' : ''}`}
                  onClick={handleRunInjection}
                  disabled={isInjecting}
                >
                  <span className="inject-icon">⚡</span>
                  {isInjecting ? 'INJECTING COSMETICS...' : 'SIMULATE VPK INJECTION'}
                </button>
                <span className="terminal-helper">
                  Click "Simulate VPK Injection" to test the real-time VFS hook and cosmetic overrides.
                </span>
              </div>
            </div>
          </section>
          </ScrollReveal>

          {/* Interactive FAQ Accordion */}
          <ScrollReveal delay={0.15}>
          <section id="faq" className="faq-section">
            <div className="section-header">
              <span className="section-badge">KNOWLEDGE BASE</span>
              <h2 className="section-title">Frequently Asked Questions</h2>
              <p className="section-desc">Everything you need to know about safety, installation, and cosmetics.</p>
            </div>

            <div className="faq-accordion">
              {[
                {
                  q: 'Is ImmortalHub safe from VAC bans?',
                  a: 'Yes. ImmortalHub does NOT inject malicious code into protected Dota 2 memory or alter server-side gameplay mechanics. It utilizes Valve’s official Game State Integration (GSI) and local client-side VPK texture redirection. Only you see your cosmetics.',
                },
                {
                  q: 'Do other players see my custom skins?',
                  a: 'No. Just like any skinchanger in CS2 or Dota 2, all models, arcanas, particle effects, and custom announcer sound packs are rendered locally on your PC. To other players, you appear in default skins.',
                },
                {
                  q: 'Will using custom Arcanas lower my game FPS?',
                  a: 'ImmortalHub introduces zero frame drops. Unlike bulky overlay software, our VPK engine mounts files directly through memory redirection with native rendering performance.',
                },
                {
                  q: 'How do I install ImmortalHub?',
                  a: 'Simply clone or download the release from our official GitHub repository, launch the executable, select your Steam Dota 2 directory, and select your desired skins!',
                },
              ].map((faq, index) => (
                <div
                  key={index}
                  className={`faq-card ${openFaq === index ? 'open' : ''}`}
                  onClick={() => {
                    playSound('click');
                    setOpenFaq(openFaq === index ? -1 : index);
                  }}
                >
                  <div className="faq-question-row">
                    <span className="faq-q-text">{faq.q}</span>
                    <span className="faq-toggle-icon">{openFaq === index ? '−' : '+'}</span>
                  </div>
                  {openFaq === index && (
                    <div className="faq-answer-row">
                      <p>{faq.a}</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </section>
          </ScrollReveal>

          {/* Bottom Call to Action Banner */}
          <section className="cta-banner">
            <div className="cta-inner">
              <span className="cta-badge">FREE & OPEN SOURCE</span>
              <h2 className="cta-heading">Ready to Experience Dota 2 in Full Arcana?</h2>
              <p className="cta-sub">
                No subscription. No registration. No hidden ads. Built by the community for the community.
              </p>
              <div className="cta-buttons">
                <button
                  className="btn-glitch"
                  onClick={() => {
                    playSound('click');
                    setShowDownloadModal(true);
                  }}
                >
                  DOWNLOAD IMMORTALHUB (.EXE)
                </button>
              </div>
            </div>
          </section>

          {/* Footer */}
          <footer className="app-footer">
            <div className="footer-left">
              <span className="footer-brand">
                Immortal<span className="neon-text">Hub</span>
              </span>
              <span className="footer-disclaimer">
                Dota 2 and Valve are trademarks of Valve Corporation. ImmortalHub is an open-source cosmetic tool
                not affiliated with Valve.
              </span>
            </div>
            <div className="footer-right">
              <a
                href="https://github.com/Harsed11/ImmortalHub"
                target="_blank"
                rel="noreferrer"
                className="footer-link"
                onClick={() => playSound('click')}
              >
                GitHub Repository
              </a>
              <span className="footer-dot">•</span>
              <a
                href="https://github.com/Harsed11/ImmortalHub/issues"
                target="_blank"
                rel="noreferrer"
                className="footer-link"
                onClick={() => playSound('click')}
              >
                Report Issue
              </a>
            </div>
          </footer>
        </main>
      </div>

      {/* Download Modal */}
      {showDownloadModal && (
        <div className="modal-overlay" onClick={() => setShowDownloadModal(false)}>
          <div className="modal-cyber-card" onClick={(e) => e.stopPropagation()}>
            <button
              className="modal-close-btn"
              onClick={() => {
                playSound('click');
                setShowDownloadModal(false);
              }}
            >
              ✕
            </button>

            <div className="modal-header">
              <span className="modal-badge">OFFICIAL RELEASE v1.1.0</span>
              <h2 className="modal-title">Get ImmortalHub for Windows</h2>
              <p className="modal-subtitle">
                Native Source 2 VPK redirector with real-time Game State Integration. Zero configuration needed.
              </p>
            </div>

            <div className="modal-download-actions">
              <a
                href="https://github.com/Harsed11/ImmortalHub/releases/latest"
                target="_blank"
                rel="noreferrer"
                className="modal-btn-primary"
                onClick={() => playSound('inject')}
              >
                <span className="btn-icon">⚡</span>
                <div className="btn-download-text">
                  <span className="btn-download-main">DOWNLOAD IMMORTALHUB (.EXE)</span>
                  <span className="btn-download-sub">v1.1.0 for Windows 10/11 64-bit (Portable)</span>
                </div>
              </a>

              <a
                href="https://github.com/Harsed11/ImmortalHub"
                target="_blank"
                rel="noreferrer"
                className="modal-btn-secondary"
                onClick={() => playSound('click')}
              >
                <span>📦 View Source on GitHub</span>
              </a>
            </div>

            <div className="modal-quickstart">
              <h4 className="quickstart-heading">🚀 3-STEP QUICKSTART:</h4>
              <div className="quickstart-steps">
                <div className="step-item">
                  <span className="step-num">1</span>
                  <span className="step-text">Download and launch <strong>ImmortalHub.exe</strong>.</span>
                </div>
                <div className="step-item">
                  <span className="step-num">2</span>
                  <span className="step-text">App auto-detects your Steam Dota 2 directory.</span>
                </div>
                <div className="step-item">
                  <span className="step-num">3</span>
                  <span className="step-text">Select any Arcana, Terrain, or Weather effect and launch!</span>
                </div>
              </div>
            </div>

            <div className="modal-footer-info">
              <span className="vac-badge">🛡️ VAC-Safe: Memory VFS Redirection Only (0 DirectX hooks)</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
