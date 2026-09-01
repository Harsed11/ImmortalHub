import React, { useState, useEffect } from 'react';
import LineSidebar from './components/LineSidebar';
import BorderGlow from './components/BorderGlow';
import LiveStats from './components/LiveStats';
import ScrollReveal from './components/ScrollReveal';
import { playSound, toggleMute } from './utils/audio';

// Real Application Screenshots
import screenDashboard from './assets/screen_dashboard.png';
import screenHeroes from './assets/screen_heroes.png';
import screenLoadout from './assets/screen_loadout.png';
import screenCollections from './assets/screen_collections.png';
import aegisNeonImg from './assets/aegis_neon.jpg';
import './App.css';

// 3D Tilt Card Wrapper
const TiltCard = ({ children, className = '' }) => {
  const [style, setStyle] = useState({});

  const handleMouseMove = (e) => {
    const card = e.currentTarget;
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateX = ((y - centerY) / centerY) * -6;
    const rotateY = ((x - centerX) / centerX) * 6;

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
      className={`tilt-card-wrapper ${className}`}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={style}
    >
      {children}
    </div>
  );
};

// Smooth scroll helper
let scrollRafId = null;
const smoothScrollTo = (targetY, duration) => {
  if (scrollRafId) {
    cancelAnimationFrame(scrollRafId);
    scrollRafId = null;
  }

  const startY = window.pageYOffset;
  const distance = targetY - startY;
  if (Math.abs(distance) < 4) return;

  const calculatedDuration = duration || Math.min(Math.max(Math.abs(distance) * 0.45, 800), 1400);
  const startTime = performance.now();

  const step = (currentTime) => {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / calculatedDuration, 1);

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
  const [activeSection, setActiveSection] = useState(0);
  const [showDownloadModal, setShowDownloadModal] = useState(false);

  // App Screenshot Gallery Active Tab
  const [activeGalleryTab, setActiveGalleryTab] = useState(0);

  // FAQ accordion state
  const [openFaq, setOpenFaq] = useState(0);

  const galleryScreens = [
    {
      id: 'dashboard',
      title: 'Main Dashboard',
      badge: 'OVERVIEW & STATUS',
      desc: 'Central command center with real-time Dota 2 game status, recently installed mods, and quick loadout access.',
      image: screenDashboard,
    },
    {
      id: 'heroes',
      title: 'Hero Studio',
      badge: '127 HEROES & ARCANAS',
      desc: 'Visual trading-card hero browser filtered by Dota 2 roles (Pos 1–5) and primary attributes (STR, AGI, INT, UNI).',
      image: screenHeroes,
    },
    {
      id: 'loadout',
      title: 'Active Loadout Manager',
      badge: 'ONE-CLICK CONTROL',
      desc: 'Strictly aligned baseline table with real-time active indicators, individual mod toggling, and batch uninstaller.',
      image: screenLoadout,
    },
    {
      id: 'collections',
      title: 'Collections Vault',
      badge: 'ATMOSPHERE & SHADERS',
      desc: 'Explore custom weather effects, map terrains, high-FPS foliage, versus screens, and audio packs.',
      image: screenCollections,
    },
  ];

  const sidebarItems = ['Overview', 'App Preview', 'Architecture', 'FAQ', 'GitHub'];

  // Scroll Spy: highlight active section as user scrolls
  useEffect(() => {
    const sections = ['overview', 'app-preview', 'architecture', 'faq'];
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
        'App Preview': 'app-preview',
        Architecture: 'architecture',
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

  const handleSoundToggle = () => {
    const newState = toggleMute();
    setIsMuted(newState);
    if (!newState) playSound('click');
  };

  return (
    <div className="app-wrapper">
      {/* Pitch-Black Clean Background with Minimal Subtle Warm Depth */}
      <div className="ambient-background">
        <div className="ambient-grid-overlay"></div>
      </div>

      {/* Floating Sound Toggle */}
      <button className="sound-toggle-btn" onClick={handleSoundToggle} title="Toggle Sound FX">
        {isMuted ? '🔇 Sound: OFF' : '🔊 Sound: ON'}
      </button>

      <div className="layout-container">
        {/* Left Truly Fixed/Static Sidebar (Never disappears on scroll) */}
        <aside className="sidebar-container">
          <div
            className="sidebar-brand"
            onClick={() => {
              playSound('click');
              smoothScrollTo(0);
            }}
            title="Scroll to top"
          >
            <div className="brand-header-row">
              <img src={aegisNeonImg} alt="Aegis" className="brand-mini-aegis" />
              <div>
                <span className="brand-badge">VPK ENGINE</span>
                <h2 className="brand-logo">
                  IMMORTAL <span className="accent-red-text">HUB</span>
                </h2>
              </div>
            </div>
          </div>

          <LineSidebar
            items={sidebarItems}
            accentColor="#E23B3B"
            textColor="#94a3b8"
            markerColor="#262838"
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

        {/* Main Content Area */}
        <main className="main-content">
          {/* ═══════════════════════════════════════════════════════════
              1. GRAND CENTERED HERO SECTION
          ═══════════════════════════════════════════════════════════ */}
          <ScrollReveal>
            <section id="overview" className="hero-section hero-centered-layout">
              <div className="hero-centered-inner">
                {/* Eyebrow Badge */}
                <div className="hero-eyebrow fade-in-up">
                  <span className="pulse-dot"></span>
                  <span className="eyebrow-text">NEXT-GEN DOTA 2 VPK ENGINE</span>
                  <span className="pill-tag">100% VAC-SAFE</span>
                </div>

                {/* Grand Centered Project Title */}
                <h1 className="hero-grand-title fade-in-up">
                  IMMORTAL <span className="accent-red-text glow-crimson">HUB</span>
                </h1>

                {/* Subtitle Value Proposition */}
                <p className="hero-grand-subtitle fade-in-up">
                  All Arcanas, Immortals, custom sound packs, and high-FPS terrains unlocked locally with zero latency and zero risk.
                </p>

                {/* Centered CTA Buttons */}
                <div className="hero-cta-row fade-in-up">
                  <button
                    className="btn-primary-action"
                    onClick={() => {
                      playSound('click');
                      setShowDownloadModal(true);
                    }}
                  >
                    <span className="btn-icon">⚡</span>
                    <span>DOWNLOAD FOR WINDOWS</span>
                  </button>

                  <a
                    href="https://github.com/Harsed11/ImmortalHub"
                    target="_blank"
                    rel="noreferrer"
                    className="btn-secondary-action"
                    onClick={() => playSound('click')}
                  >
                    <span>★ GITHUB REPO</span>
                  </a>
                </div>

                {/* Signature 3D Aegis of Champions Edition Card (Crimson Ember Edition) */}
                <div className="hero-aegis-centered-container fade-in-up">
                  <TiltCard>
                    <div className="hero-aegis-card">
                      <div className="aegis-image-container">
                        <img src={aegisNeonImg} alt="ImmortalHub Aegis of Champions" className="hero-aegis-img" />
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
                          <span>#Source2VPK</span>
                          <span>#ClientSideOnly</span>
                        </div>
                      </div>
                    </div>
                  </TiltCard>
                </div>

                {/* Live Real-Time Platform Stats */}
                <LiveStats />
              </div>
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

          {/* ═══════════════════════════════════════════════════════════
              2. REAL APP SCREENSHOTS SHOWCASE GALLERY
          ═══════════════════════════════════════════════════════════ */}
          <ScrollReveal>
            <section id="app-preview" className="app-gallery-section">
              <div className="section-header">
                <span className="section-badge">DESKTOP CLIENT UI</span>
                <h2 className="section-title">Experience the New Desktop App</h2>
                <p className="section-desc">
                  Built natively in Qt 6 Quick & Python with gaming-grade responsive design, hardware-accelerated transitions, and pro tournament loadouts.
                </p>
              </div>

              {/* Gallery Category Selector Tabs */}
              <div className="gallery-tabs-row">
                {galleryScreens.map((screen, idx) => (
                  <button
                    key={screen.id}
                    className={`gallery-tab-btn ${activeGalleryTab === idx ? 'active' : ''}`}
                    onClick={() => {
                      playSound('click');
                      setActiveGalleryTab(idx);
                    }}
                  >
                    <span className="tab-title">{screen.title}</span>
                  </button>
                ))}
              </div>

              {/* Active Screenshot Display Frame */}
              <div className="gallery-preview-frame">
                <div className="frame-header-bar">
                  <div className="frame-dots">
                    <span className="frame-dot red"></span>
                    <span className="frame-dot yellow"></span>
                    <span className="frame-dot green"></span>
                  </div>
                  <span className="frame-title">
                    ImmortalHub v1.3.1 — {galleryScreens[activeGalleryTab].title}
                  </span>
                  <span className="frame-badge">
                    {galleryScreens[activeGalleryTab].badge}
                  </span>
                </div>

                <div className="frame-image-container">
                  <img
                    src={galleryScreens[activeGalleryTab].image}
                    alt={galleryScreens[activeGalleryTab].title}
                    className="frame-screenshot-img"
                  />
                  <div className="frame-image-caption">
                    <p>{galleryScreens[activeGalleryTab].desc}</p>
                  </div>
                </div>
              </div>
            </section>
          </ScrollReveal>

          {/* ═══════════════════════════════════════════════════════════
              3. CORE ARCHITECTURE & CAPABILITIES
          ═══════════════════════════════════════════════════════════ */}
          <ScrollReveal>
            <section id="architecture" className="features-section">
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
                    glowColor="0 90 55"
                    backgroundColor="rgba(18, 18, 26, 0.95)"
                    borderRadius={20}
                    glowRadius={30}
                    glowIntensity={1.3}
                    colors={['#E23B3B', '#FF6B6B', '#10B981']}
                    className="glass-feature-card"
                  >
                    <div className="feature-card-body">
                      <div className="feature-icon-wrapper glow-red">⚡</div>
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
                    glowColor="150 90 50"
                    backgroundColor="rgba(18, 18, 26, 0.95)"
                    borderRadius={20}
                    glowRadius={30}
                    glowIntensity={1.3}
                    colors={['#10B981', '#059669', '#E23B3B']}
                    className="glass-feature-card"
                  >
                    <div className="feature-card-body">
                      <div className="feature-icon-wrapper glow-green">🛡️</div>
                      <span className="feature-tag">100% VAC-SAFE</span>
                      <h3 className="feature-heading">Game State Sync</h3>
                      <p className="feature-text">
                        Uses official Valve Game State Integration (GSI) JSON payloads on port 39888 to detect chosen heroes
                        and match transitions without touching anti-cheat protected game memory.
                      </p>
                    </div>
                  </BorderGlow>
                </TiltCard>

                <TiltCard>
                  <BorderGlow
                    edgeSensitivity={30}
                    glowColor="35 90 50"
                    backgroundColor="rgba(18, 18, 26, 0.95)"
                    borderRadius={20}
                    glowRadius={30}
                    glowIntensity={1.3}
                    colors={['#F59E0B', '#E23B3B', '#10B981']}
                    className="glass-feature-card"
                  >
                    <div className="feature-card-body">
                      <div className="feature-icon-wrapper glow-gold">🧹</div>
                      <span className="feature-tag">SMART CLEANUP</span>
                      <h3 className="feature-heading">Conflict Resolver</h3>
                      <p className="feature-text">
                        Automatically detects and purges broken outdated <code>.vmdl_c</code> overrides before applying fresh
                        mods, preventing blue-screen crashes and missing purple checkerboard textures.
                      </p>
                    </div>
                  </BorderGlow>
                </TiltCard>

                <TiltCard>
                  <BorderGlow
                    edgeSensitivity={30}
                    glowColor="0 85 50"
                    backgroundColor="rgba(18, 18, 26, 0.95)"
                    borderRadius={20}
                    glowRadius={30}
                    glowIntensity={1.3}
                    colors={['#E23B3B', '#F59E0B', '#10B981']}
                    className="glass-feature-card"
                  >
                    <div className="feature-card-body">
                      <div className="feature-icon-wrapper glow-red">🔊</div>
                      <span className="feature-tag">AUDIO PACKS</span>
                      <h3 className="feature-heading">Custom Announcers</h3>
                      <p className="feature-text">
                        Swap default announcer lines with legendary packs: Gabe Newell, Rick & Morty, Deus Ex,
                        Dark Willow, and custom bass-boosted Mega-Kill sound triggers.
                      </p>
                    </div>
                  </BorderGlow>
                </TiltCard>
              </div>
            </section>
          </ScrollReveal>

          {/* ═══════════════════════════════════════════════════════════
              4. FAQ SECTION
          ═══════════════════════════════════════════════════════════ */}
          <ScrollReveal>
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
                    a: 'Simply download the latest release from our official GitHub repository, launch the executable, select your Steam Dota 2 directory, and equip your desired skins in 1 click!',
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

          {/* ═══════════════════════════════════════════════════════════
              5. CALL TO ACTION BANNER
          ═══════════════════════════════════════════════════════════ */}
          <section className="cta-banner">
            <div className="cta-inner">
              <span className="cta-badge">FREE & OPEN SOURCE</span>
              <h2 className="cta-heading">Ready to Experience Dota 2 in Full Arcana?</h2>
              <p className="cta-sub">
                No subscription. No registration. No hidden ads. Built by the community for the community.
              </p>
              <div className="cta-buttons">
                <button
                  className="btn-primary-action"
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

          {/* ═══════════════════════════════════════════════════════════
              6. FOOTER
          ═══════════════════════════════════════════════════════════ */}
          <footer className="app-footer">
            <div className="footer-left">
              <span className="footer-brand">
                IMMORTAL <span className="accent-red-text">HUB</span>
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

      {/* ═══════════════════════════════════════════════════════════
          7. DOWNLOAD MODAL
      ═══════════════════════════════════════════════════════════ */}
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
              <span className="modal-badge">OFFICIAL RELEASE v1.3.1</span>
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
                  <span className="btn-download-sub">v1.3.1 for Windows 10/11 64-bit (Portable)</span>
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
