import React, { useState, useEffect } from 'react';
import './LiveStats.css';

const StatItem = ({ label, endValue, suffix = '', duration = 2000 }) => {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let startTimestamp = null;
    const step = (timestamp) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);
      
      // easeOutExpo function for smooth deceleration
      const easeProgress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
      
      setCount(Math.floor(easeProgress * endValue));
      
      if (progress < 1) {
        window.requestAnimationFrame(step);
      }
    };
    
    // Slight delay for scroll reveal effect
    const timeoutId = setTimeout(() => {
      window.requestAnimationFrame(step);
    }, 500);

    return () => clearTimeout(timeoutId);
  }, [endValue, duration]);

  // Format number with commas
  const formattedCount = count.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  return (
    <div className="stat-item">
      <div className="stat-value neon-text">
        {formattedCount}{suffix}
      </div>
      <div className="stat-label">{label}</div>
    </div>
  );
};

const LiveStats = () => {
  return (
    <div className="live-stats-container">
      <StatItem label="Active Users" endValue={14205} />
      <StatItem label="Mods Injected" endValue={854921} suffix="+" />
      <StatItem label="Bans Recorded" endValue={0} />
    </div>
  );
};

export default LiveStats;
