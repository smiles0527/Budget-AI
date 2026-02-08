"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const steps = [
  {
    number: "01",
    icon: "photo_camera",
    title: "Snap a Receipt",
    description:
      "Take a photo of any receipt or purchase. Our OCR tech reads it in under 5 seconds — no manual entry needed.",
    accent: "#00c9ff",
    glowColor: "rgba(0, 201, 255, 0.25)",
    textColor: "text-neon-blue",
  },
  {
    number: "02",
    icon: "smart_toy",
    title: "AI Categorizes It",
    description:
      "Machine learning automatically identifies the merchant, total, and category — groceries, dining, transport, and more.",
    accent: "#a855f7",
    glowColor: "rgba(168, 85, 247, 0.25)",
    textColor: "text-neon-purple",
  },
  {
    number: "03",
    icon: "bar_chart",
    title: "See Your Dashboard",
    description:
      "Interactive charts show daily, weekly, and monthly breakdowns. Set budgets per category and track them in real time.",
    accent: "#0df2a6",
    glowColor: "rgba(13, 242, 166, 0.25)",
    textColor: "text-primary",
  },
  {
    number: "04",
    icon: "emoji_events",
    title: "Earn & Share Badges",
    description:
      "Hit savings goals, build streaks, and unlock progress badges — like Duolingo, but for your wallet.",
    accent: "#ff6bcb",
    glowColor: "rgba(255, 107, 203, 0.25)",
    textColor: "text-neon-pink",
  },
];

export default function HowItWorks() {
  const sectionRef = useRef<HTMLElement>(null);
  const timelineRef = useRef<HTMLDivElement>(null);
  const lineRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!timelineRef.current || !lineRef.current) return;

    // Animate the horizontal connecting line growing — triggered, not scrubbed
    gsap.fromTo(
      lineRef.current,
      { scaleX: 0 },
      {
        scaleX: 1,
        duration: 1.5,
        ease: "power2.out",
        scrollTrigger: {
          trigger: timelineRef.current,
          start: "top 75%",
          toggleActions: "play reset play reset",
        },
      }
    );

    // Cards cascade in with blur-to-sharp + stagger
    const cards = timelineRef.current.querySelectorAll(".step-card");
    cards.forEach((card, i) => {
      gsap.fromTo(
        card,
        {
          y: 50,
          opacity: 0,
          scale: 0.85,
          filter: "blur(8px)",
        },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          filter: "blur(0px)",
          duration: 0.8,
          delay: i * 0.15,
          ease: "power2.out",
          scrollTrigger: {
            trigger: card,
            start: "top 90%",
            end: "top 50%",
            toggleActions: "play reset play reset",
          },
        }
      );

      // Spin the step number on enter
      const number = card.querySelector(".step-number");
      if (number) {
        gsap.fromTo(
          number,
          { scale: 0, rotation: -180 },
          {
            scale: 1,
            rotation: 0,
            duration: 0.8,
            ease: "back.out(2)",
            scrollTrigger: {
              trigger: card,
              start: "top 80%",
              toggleActions: "play reset play reset",
            },
          }
        );
      }
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-6xl mb-20">
      <div className="text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-purple text-glow-purple">
          How It Works
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          From receipt to insight in <span className="gradient-text">seconds</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-xl mx-auto">
          No spreadsheets. No bank logins. Just snap, and SnapBudget handles the rest.
        </p>
      </div>

      <div ref={timelineRef} className="relative">
        {/* Horizontal glowing line (desktop) */}
        <div
          ref={lineRef}
          className="absolute top-6 left-0 right-0 h-0.5 origin-left hidden md:block z-0"
          style={{
            background: "linear-gradient(90deg, #00c9ff, #a855f7, #0df2a6, #ff6bcb)",
            boxShadow: "0 0 15px rgba(13,242,166,0.4), 0 0 30px rgba(168,85,247,0.2)",
            transform: "scaleX(0)",
          }}
        />

        <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
          {steps.map((step) => (
            <div key={step.number} className="step-card relative flex flex-col items-center text-center group">
              {/* Step number circle */}
              <div
                className="step-number relative z-10 w-12 h-12 rounded-full flex items-center justify-center text-sm font-extrabold mb-5 shrink-0"
                style={{
                  background: step.accent,
                  boxShadow: `0 0 20px ${step.accent}60, 0 0 40px ${step.accent}30`,
                  color: "#050a09",
                }}
              >
                {step.number}
              </div>

              {/* Card */}
              <div className="relative p-5 rounded-2xl glass border-gradient overflow-hidden cursor-default w-full grow">
                {/* Hover glow */}
                <div
                  className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                  style={{ background: `radial-gradient(circle at center top, ${step.glowColor}, transparent 60%)` }}
                />

                <div className="relative z-10 flex flex-col items-center">
                  {/* Icon */}
                  <div
                    className="shrink-0 w-12 h-12 rounded-xl flex items-center justify-center mb-3"
                    style={{
                      background: `${step.accent}15`,
                      boxShadow: `0 0 25px ${step.glowColor}`,
                    }}
                  >
                    <span className={`material-symbols-outlined text-2xl ${step.textColor}`}>{step.icon}</span>
                  </div>

                  <h3 className={`text-base font-bold mb-1.5 ${step.textColor}`}>{step.title}</h3>
                  <p className="text-xs text-white/60 leading-relaxed">{step.description}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
