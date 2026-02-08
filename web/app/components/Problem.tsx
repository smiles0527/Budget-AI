"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const painPoints = [
  {
    stat: "59%",
    label: "of Gen Z regularly overspend",
    icon: "trending_down",
    source: "Bank of America, 2023",
    color: "text-neon-pink",
  },
  {
    stat: "72%",
    label: "have tried to improve their finances",
    icon: "trending_up",
    source: "Deloitte, 2024",
    color: "text-primary",
  },
  {
    stat: "$53B+",
    label: "finance app market by 2033",
    icon: "show_chart",
    source: "18% CAGR growth",
    color: "text-neon-blue",
  },
];

const frustrations = [
  { icon: "grid_on", text: "Spreadsheets are boring" },
  { icon: "account_balance", text: "Bank apps are confusing" },
  { icon: "child_care", text: "Kid apps feel patronizing" },
  { icon: "schedule", text: "Manual entry takes forever" },
  { icon: "dashboard", text: "Too many features, not enough clarity" },
  { icon: "lock", text: "Don't want to link bank accounts" },
];

export default function Problem() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    // Heading — clip-path reveal wipe
    const heading = section.querySelector(".problem-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { clipPath: "inset(0 100% 0 0)", opacity: 0 },
        {
          clipPath: "inset(0 0% 0 0)",
          opacity: 1,
          duration: 1.2,
          ease: "power4.inOut",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            toggleActions: "restart none restart none",
          },
        }
      );
    }

    // Stat cards — blur-in with stagger
    const statCards = section.querySelectorAll(".stat-card");
    statCards.forEach((card, i) => {
      gsap.fromTo(
        card,
        { y: 40, opacity: 0, filter: "blur(12px)" },
        {
          y: 0,
          opacity: 1,
          filter: "blur(0px)",
          duration: 0.8,
          delay: i * 0.15,
          ease: "power2.out",
          scrollTrigger: {
            trigger: card,
            start: "top 90%",
            toggleActions: "restart none restart none",
          },
        }
      );
    });

    // Frustration pills — pop-in with elastic scale
    const pills = section.querySelectorAll(".frustration-pill");
    pills.forEach((pill, i) => {
      gsap.fromTo(
        pill,
        { scale: 0, opacity: 0 },
        {
          scale: 1,
          opacity: 1,
          duration: 0.6,
          delay: i * 0.06,
          ease: "elastic.out(1, 0.5)",
          scrollTrigger: {
            trigger: pill,
            start: "top 90%",
            toggleActions: "restart none restart none",
          },
        }
      );
    });

    // Bottom text flies up
    const bottom = section.querySelector(".problem-bottom");
    if (bottom) {
      gsap.fromTo(
        bottom,
        { y: 60, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: bottom,
            start: "top 90%",
            toggleActions: "restart none restart none",
          },
        }
      );
    }

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-6xl mb-20">
      {/* Heading */}
      <div className="problem-heading text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-pink text-glow-pink">
          The Problem
        </span>
        <h2 className="text-3xl md:text-5xl lg:text-6xl font-extrabold mt-3 leading-tight">
          Budgeting tools{" "}
          <span className="text-white/40 line-through decoration-neon-pink/40">work great</span>
          <br />
          <span className="gradient-text">weren&apos;t built for you.</span>
        </h2>
        <p className="text-white/70 mt-4 max-w-2xl mx-auto text-lg">
          You&apos;re not bad with money. The tools are just bad.
          Complex bank apps, kiddie finance games, or soul-crushing spreadsheets —
          none of them get it.
        </p>
      </div>

      {/* Two-column: stats left, frustrations right */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-10">
        {/* Left: Stat cards */}
        <div className="space-y-4">
          {painPoints.map((point) => (
            <div
              key={point.stat}
              className="stat-card glass border-gradient rounded-2xl p-5 flex items-center gap-5 group hover:scale-[1.02] transition-transform duration-300"
            >
              <span className={`material-symbols-outlined text-3xl ${point.color} shrink-0`}>{point.icon}</span>
              <div>
                <div className="flex items-baseline gap-2">
                  <span className="text-3xl md:text-4xl font-extrabold text-primary text-glow-primary">
                    {point.stat}
                  </span>
                  <span className="text-white/80 font-medium text-sm">{point.label}</span>
                </div>
                <p className="text-white/60 text-sm mt-1">{point.source}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Right: Frustration pills */}
        <div className="flex flex-col justify-center">
          <p className="text-white/60 text-sm font-bold uppercase tracking-widest mb-4">
            Sound familiar?
          </p>
          <div className="flex flex-wrap gap-2.5">
            {frustrations.map((item) => (
              <div
                key={item.text}
                className="frustration-pill glass border border-white/10 rounded-full px-5 py-2.5 flex items-center gap-2 hover:border-neon-pink/30 hover:bg-neon-pink/5 transition-all duration-300 cursor-default"
              >
                <span className="material-symbols-outlined text-white/60 text-[18px]">{item.icon}</span>
                <span className="text-white/75 text-sm font-medium">{item.text}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom hook */}
      <div className="problem-bottom text-center">
        <p className="text-2xl md:text-3xl font-bold">
          What if budgeting was as easy as{" "}
          <span className="gradient-text-fast">taking a photo?</span>
        </p>
      </div>
    </section>
  );
}
