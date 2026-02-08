"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const floatingItems = [
  { emoji: "💸", x: "5%", y: "15%", size: "text-3xl", speed: 1.2 },
  { emoji: "🧾", x: "90%", y: "8%", size: "text-2xl", speed: 0.8 },
  { emoji: "📊", x: "15%", y: "35%", size: "text-4xl", speed: 1.5 },
  { emoji: "🏆", x: "85%", y: "30%", size: "text-3xl", speed: 1.0 },
  { emoji: "💰", x: "8%", y: "55%", size: "text-2xl", speed: 1.3 },
  { emoji: "🎯", x: "92%", y: "50%", size: "text-3xl", speed: 0.9 },
  { emoji: "🚀", x: "12%", y: "72%", size: "text-4xl", speed: 1.6 },
  { emoji: "⚡", x: "88%", y: "68%", size: "text-2xl", speed: 1.1 },
  { emoji: "💎", x: "6%", y: "88%", size: "text-3xl", speed: 0.7 },
  { emoji: "🔥", x: "94%", y: "85%", size: "text-3xl", speed: 1.4 },
  { emoji: "📱", x: "20%", y: "45%", size: "text-2xl", speed: 1.0 },
  { emoji: "✨", x: "80%", y: "42%", size: "text-4xl", speed: 1.2 },
  { emoji: "🪙", x: "3%", y: "95%", size: "text-2xl", speed: 0.6 },
  { emoji: "💳", x: "97%", y: "92%", size: "text-3xl", speed: 1.3 },
];

export default function FloatingIcons() {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!containerRef.current) return;
    const els = containerRef.current.querySelectorAll(".float-icon");

    els.forEach((el, i) => {
      const item = floatingItems[i];
      if (!item) return;

      // Parallax on scroll - move at different speeds
      gsap.to(el, {
        y: () => -window.innerHeight * item.speed * 0.3,
        ease: "none",
        scrollTrigger: {
          trigger: document.body,
          start: "top top",
          end: "bottom bottom",
          scrub: 1.5,
        },
      });

      // Gentle swaying
      gsap.to(el, {
        x: `random(-30, 30)`,
        rotation: `random(-15, 15)`,
        duration: 3 + i * 0.4,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: i * 0.3,
      });
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <div
      ref={containerRef}
      className="fixed inset-0 pointer-events-none z-[1] overflow-hidden"
      aria-hidden="true"
    >
      {floatingItems.map((item, i) => (
        <div
          key={i}
          className={`float-icon absolute ${item.size} opacity-[0.07] select-none`}
          style={{ left: item.x, top: item.y }}
        >
          {item.emoji}
        </div>
      ))}
    </div>
  );
}
