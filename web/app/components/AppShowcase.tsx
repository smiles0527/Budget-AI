"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const screens = [
  {
    title: "Dashboard",
    description: "See all your spending at a glance with interactive charts",
    icon: "📊",
    color: "#0df2a6",
    mockContent: (
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-white/75 text-xs">Monthly Spending</span>
          <span className="text-primary text-xs font-bold">$1,247</span>
        </div>
        {/* Mini chart bars */}
        <div className="flex items-end gap-1.5 h-20">
          {[40, 65, 35, 80, 55, 70, 45, 90, 60, 75, 50, 85].map((h, i) => (
            <div
              key={i}
              className="flex-1 rounded-sm transition-all duration-300"
              style={{
                height: `${h}%`,
                background: `linear-gradient(180deg, ${i === 7 ? "#0df2a6" : "#0df2a640"} 0%, transparent 100%)`,
              }}
            />
          ))}
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div className="glass rounded-lg p-2">
            <div className="text-[10px] text-white/60">Food</div>
            <div className="text-sm font-bold text-primary">$342</div>
          </div>
          <div className="glass rounded-lg p-2">
            <div className="text-[10px] text-white/60">Transport</div>
            <div className="text-sm font-bold text-neon-blue">$128</div>
          </div>
        </div>
      </div>
    ),
  },
  {
    title: "Receipt Scan",
    description: "Snap a photo and AI does the rest in seconds",
    icon: "📸",
    color: "#00c9ff",
    mockContent: (
      <div className="space-y-3">
        <div className="glass rounded-xl p-3 border border-neon-blue/20">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-lg">🧾</span>
            <div>
              <div className="text-xs font-bold text-white/80">Chipotle</div>
              <div className="text-[10px] text-white/60">Feb 7, 2026</div>
            </div>
          </div>
          <div className="space-y-1.5">
            <div className="flex justify-between text-[10px]">
              <span className="text-white/70">Burrito Bowl</span>
              <span className="text-white/80">$10.95</span>
            </div>
            <div className="flex justify-between text-[10px]">
              <span className="text-white/70">Chips & Guac</span>
              <span className="text-white/80">$4.25</span>
            </div>
            <div className="border-t border-white/10 pt-1 flex justify-between text-xs">
              <span className="text-white/75 font-medium">Total</span>
              <span className="text-primary font-bold">$15.20</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2 glass rounded-lg px-3 py-2">
          <span className="material-symbols-outlined text-primary text-[16px]">check_circle</span>
          <span className="text-[10px] text-white/75">Auto-categorized as <span className="text-neon-blue font-bold">Dining</span></span>
        </div>
      </div>
    ),
  },
  {
    title: "Badges & Streaks",
    description: "Earn rewards for hitting your savings goals",
    icon: "🏆",
    color: "#a855f7",
    mockContent: (
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-white/75 text-xs">Your Badges</span>
          <span className="text-neon-purple text-xs font-bold">12 earned</span>
        </div>
        <div className="grid grid-cols-3 gap-2">
          {[
            { emoji: "🔥", label: "7-Day Streak" },
            { emoji: "💰", label: "First $100" },
            { emoji: "📸", label: "10 Scans" },
            { emoji: "🎯", label: "Budget Pro" },
            { emoji: "⚡", label: "Speed Scan" },
            { emoji: "🏅", label: "Top Saver" },
          ].map((b) => (
            <div key={b.label} className="glass rounded-lg p-2 text-center group hover:scale-105 transition-transform">
              <div className="text-2xl mb-0.5">{b.emoji}</div>
              <div className="text-[8px] text-white/60 leading-tight">{b.label}</div>
            </div>
          ))}
        </div>
        <div className="glass rounded-lg p-2 flex items-center gap-2">
          <div className="w-full bg-white/5 rounded-full h-2">
            <div className="h-2 rounded-full bg-gradient-to-r from-[#a855f7] to-[#ff6bcb]" style={{ width: "73%" }} />
          </div>
          <span className="text-[10px] text-neon-purple font-bold shrink-0">73%</span>
        </div>
      </div>
    ),
  },
];

export default function AppShowcase() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const heading = section.querySelector(".showcase-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { y: 80, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            end: "+=300",
            scrub: 1,
          },
        }
      );
    }

    // Phone mockups fly in from different directions
    const phones = section.querySelectorAll(".phone-mockup");
    const flyConfigs = [
      { x: -200, rotation: -12 },
      { y: 120, rotation: 0 },
      { x: 200, rotation: 12 },
    ];
    phones.forEach((phone, i) => {
      const cfg = flyConfigs[i];
      gsap.fromTo(
        phone,
        { x: cfg.x || 0, y: cfg.y || 80, rotation: cfg.rotation, opacity: 0, scale: 0.7 },
        {
          x: 0,
          y: 0,
          rotation: 0,
          opacity: 1,
          scale: 1,
          duration: 1.2,
          ease: "back.out(1.4)",
          scrollTrigger: {
            trigger: phone,
            start: "top 90%",
            end: "+=300",
            scrub: 1,
          },
        }
      );
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-6xl mb-32">
      <div className="showcase-heading text-center mb-14">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          📱 See It In Action
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Beautiful. <span className="gradient-text">Powerful.</span> Yours.
        </h2>
        <p className="text-white/70 mt-3 max-w-lg mx-auto">
          Designed for the way you actually spend money.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {screens.map((screen) => (
          <div key={screen.title} className="phone-mockup flex flex-col items-center">
            {/* Phone frame */}
            <div
              className="relative w-full max-w-[260px] rounded-[2rem] p-1 group"
              style={{
                background: `linear-gradient(135deg, ${screen.color}40, transparent 60%)`,
              }}
            >
              <div className="glass-strong rounded-[1.8rem] overflow-hidden">
                {/* Status bar */}
                <div className="flex items-center justify-between px-5 pt-3 pb-1">
                  <span className="text-[9px] text-white/50">9:41</span>
                  <div className="w-16 h-1 bg-white/10 rounded-full" />
                  <div className="flex gap-1">
                    <div className="w-3 h-1.5 bg-white/20 rounded-sm" />
                    <div className="w-1.5 h-1.5 bg-white/20 rounded-full" />
                  </div>
                </div>

                {/* Screen header */}
                <div className="px-5 pt-2 pb-3">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{screen.icon}</span>
                    <span className="text-sm font-bold text-white/90">{screen.title}</span>
                  </div>
                </div>

                {/* Mock content */}
                <div className="px-4 pb-6">{screen.mockContent}</div>
              </div>

              {/* Glow effect on hover */}
              <div
                className="absolute -inset-1 rounded-[2.2rem] opacity-0 group-hover:opacity-100 transition-opacity duration-500 -z-10 blur-xl"
                style={{
                  background: `radial-gradient(circle, ${screen.color}30, transparent)`,
                }}
              />
            </div>

            {/* Label */}
            <div className="mt-5 text-center">
              <h3 className="text-lg font-bold text-white/90">{screen.title}</h3>
              <p className="text-sm text-white/60 mt-1 max-w-[220px]">{screen.description}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
