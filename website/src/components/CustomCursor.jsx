import React, { useEffect, useRef, useState } from 'react';
import './CustomCursor.css';

const CustomCursor = () => {
  const dotRef = useRef(null);
  const ringRef = useRef(null);
  const requestRef = useRef(null);
  
  const mousePosition = useRef({ x: window.innerWidth / 2, y: window.innerHeight / 2 });
  const ringPosition = useRef({ x: window.innerWidth / 2, y: window.innerHeight / 2 });

  const [isHovering, setIsHovering] = useState(false);
  const [isClicking, setIsClicking] = useState(false);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Animation loop for smooth tracking (Lerp)
    const animate = () => {
      // Linear interpolation for smooth trailing ring
      ringPosition.current.x += (mousePosition.current.x - ringPosition.current.x) * 0.25;
      ringPosition.current.y += (mousePosition.current.y - ringPosition.current.y) * 0.25;

      if (dotRef.current) {
        dotRef.current.style.transform = `translate3d(${mousePosition.current.x}px, ${mousePosition.current.y}px, 0) translate(-50%, -50%)`;
      }
      
      if (ringRef.current) {
        ringRef.current.style.transform = `translate3d(${ringPosition.current.x}px, ${ringPosition.current.y}px, 0) translate(-50%, -50%)`;
      }

      requestRef.current = requestAnimationFrame(animate);
    };
    
    requestRef.current = requestAnimationFrame(animate);
    
    return () => cancelAnimationFrame(requestRef.current);
  }, []);

  useEffect(() => {
    const updatePosition = (e) => {
      mousePosition.current = { x: e.clientX, y: e.clientY };
      if (!isVisible) setIsVisible(true);
    };

    const handleMouseOver = (e) => {
      if (
        e.target.tagName.toLowerCase() === 'button' ||
        e.target.tagName.toLowerCase() === 'a' ||
        e.target.closest('button') ||
        e.target.closest('a') ||
        e.target.classList.contains('clickable')
      ) {
        setIsHovering(true);
      } else {
        setIsHovering(false);
      }
    };

    const handleMouseDown = () => setIsClicking(true);
    const handleMouseUp = () => setIsClicking(false);
    const handleMouseLeave = () => setIsVisible(false);

    window.addEventListener('mousemove', updatePosition);
    window.addEventListener('mouseover', handleMouseOver);
    window.addEventListener('mousedown', handleMouseDown);
    window.addEventListener('mouseup', handleMouseUp);
    document.body.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      window.removeEventListener('mousemove', updatePosition);
      window.removeEventListener('mouseover', handleMouseOver);
      window.removeEventListener('mousedown', handleMouseDown);
      window.removeEventListener('mouseup', handleMouseUp);
      document.body.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [isVisible]);

  return (
    <>
      <div
        ref={dotRef}
        className={`custom-cursor-dot ${isHovering ? 'hovering' : ''} ${isClicking ? 'clicking' : ''} ${isVisible ? 'visible' : ''}`}
      />
      <div
        ref={ringRef}
        className={`custom-cursor-ring ${isHovering ? 'hovering' : ''} ${isClicking ? 'clicking' : ''} ${isVisible ? 'visible' : ''}`}
      />
    </>
  );
};

export default CustomCursor;
