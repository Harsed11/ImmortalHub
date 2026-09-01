import React from 'react';

const ScrollReveal = ({ children, className = '' }) => {
  return (
    <div className={`scroll-reveal-container ${className}`}>
      {children}
    </div>
  );
};

export default ScrollReveal;
