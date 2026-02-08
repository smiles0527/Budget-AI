"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";

export default function ParticleField() {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!containerRef.current) return;
    const container = containerRef.current;
    const colors = ["#0df2a6", "#00c9ff", "#a855f7", "#ff6bcb"];

    // Floating particles — 80 of them
    for (let i = 0; i < 80; i++) {
      const particle = document.createElement("div");
      const size = Math.random() * 4 + 1;
      const color = colors[Math.floor(Math.random() * colors.length)];

      particle.style.cssText = `
        position: absolute;
        width: ${size}px;
        height: ${size}px;
        background: ${color};
        border-radius: 50%;
        left: ${Math.random() * 100}%;
        top: ${Math.random() * 100}%;
        opacity: 0;
        pointer-events: none;
        box-shadow: 0 0 ${size * 6}px ${color}60;
      `;
      container.appendChild(particle);

      gsap.to(particle, {
        opacity: Math.random() * 0.7 + 0.1,
        duration: Math.random() * 2 + 1,
        delay: Math.random() * 3,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
      });

      gsap.to(particle, {
        y: `random(-120, 120)`,
        x: `random(-60, 60)`,
        duration: Math.random() * 10 + 6,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: Math.random() * 2,
      });
    }

    // Shooting stars — periodic streaks
    const shootStar = () => {
      const star = document.createElement("div");
      const color = colors[Math.floor(Math.random() * colors.length)];
      const startX = Math.random() * window.innerWidth;
      const startY = Math.random() * window.innerHeight * 0.5;

      star.style.cssText = `
        position: absolute;
        width: 2px;
        height: 2px;
        background: ${color};
        border-radius: 50%;
        left: ${startX}px;
        top: ${startY}px;
        box-shadow: 0 0 6px ${color}, -20px -10px 4px ${color}80, -40px -20px 2px ${color}40;
        pointer-events: none;
      `;
      container.appendChild(star);

      gsap.to(star, {
        x: 300 + Math.random() * 200,
        y: 200 + Math.random() * 150,
        opacity: 0,
        duration: 0.8 + Math.random() * 0.5,
        ease: "power2.in",
        onComplete: () => star.remove(),
      });
    };

    const shootInterval = setInterval(shootStar, 2000 + Math.random() * 3000);

    // Larger floating orbs — 6 big ones
    for (let i = 0; i < 6; i++) {
      const orb = document.createElement("div");
      const orbSize = 60 + Math.random() * 80;
      const color = colors[Math.floor(Math.random() * colors.length)];

      orb.style.cssText = `
        position: absolute;
        width: ${orbSize}px;
        height: ${orbSize}px;
        background: radial-gradient(circle, ${color}15, transparent);
        border-radius: 50%;
        left: ${Math.random() * 100}%;
        top: ${Math.random() * 100}%;
        pointer-events: none;
        filter: blur(20px);
      `;
      container.appendChild(orb);

      gsap.to(orb, {
        y: `random(-150, 150)`,
        x: `random(-100, 100)`,
        scale: `random(0.5, 2)`,
        duration: 8 + Math.random() * 8,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: Math.random() * 4,
      });
    }

    return () => {
      clearInterval(shootInterval);
      container.innerHTML = "";
    };
  }, []);

  return (
    <div
      ref={containerRef}
      className="fixed inset-0 pointer-events-none z-0 overflow-hidden"
      aria-hidden="true"
    />
  );
}
