"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";

export default function CursorGlow() {
  const glowRef = useRef<HTMLDivElement>(null);
  const trailRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const glow = glowRef.current;
    const trail = trailRef.current;
    if (!glow || !trail) return;

    const onMove = (e: MouseEvent) => {
      gsap.to(glow, {
        x: e.clientX - 200,
        y: e.clientY - 200,
        duration: 0.8,
        ease: "power2.out",
      });
      gsap.to(trail, {
        x: e.clientX - 10,
        y: e.clientY - 10,
        duration: 0.15,
        ease: "power1.out",
      });
    };

    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  return (
    <>
      {/* Large ambient glow */}
      <div
        ref={glowRef}
        className="fixed top-0 left-0 w-[400px] h-[400px] pointer-events-none z-[9990] opacity-20 hidden md:block"
        style={{
          background: "radial-gradient(circle, rgba(13,242,166,0.15) 0%, rgba(0,201,255,0.08) 40%, transparent 70%)",
          filter: "blur(40px)",
        }}
      />
      {/* Small bright dot */}
      <div
        ref={trailRef}
        className="fixed top-0 left-0 w-5 h-5 pointer-events-none z-[9991] rounded-full hidden md:block"
        style={{
          background: "radial-gradient(circle, rgba(13,242,166,0.8), transparent)",
          filter: "blur(2px)",
        }}
      />
    </>
  );
}
