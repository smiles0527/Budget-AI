"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const trustPoints = [
  {
    icon: "lock_open",
    title: "No Bank Login Required",
    description:
      "Unlike Mint or YNAB, we never ask for your bank credentials. Your financial accounts stay completely separate.",
    color: "#0df2a6",
  },
  {
    icon: "enhanced_encryption",
    title: "AES-256 Encryption",
    description:
      "All data is encrypted at rest using bank-level AES-256 encryption. The same standard used by financial institutions worldwide.",
    color: "#00c9ff",
  },
  {
    icon: "vpn_lock",
    title: "TLS In Transit",
    description:
      "Every data transfer uses TLS encryption. Your receipt photos and spending data are never exposed in transit.",
    color: "#a855f7",
  },
  {
    icon: "visibility_off",
    title: "Privacy-First Model",
    description:
      "We never sell individual user data. Aggregate insights are anonymized. You own your data, always.",
    color: "#ff6bcb",
  },
  {
    icon: "delete_sweep",
    title: "One-Click Data Deletion",
    description:
      "Want out? Delete your entire account and all associated data instantly. No hoops, no waiting periods.",
    color: "#0df2a6",
  },
  {
    icon: "description",
    title: "Transparent Policies",
    description:
      "Our privacy policy is written in plain English, not legal jargon. We tell you exactly what we collect and why.",
    color: "#00c9ff",
  },
];

export default function Trust() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const heading = section.querySelector(".trust-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { y: 60, opacity: 0, scale: 0.95 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            toggleActions: "play reset play reset",
          },
        }
      );
    }

    const cards = section.querySelectorAll(".trust-card");
    cards.forEach((card, i) => {
      // Clip-path circle expand from icon corner
      gsap.fromTo(
        card,
        {
          clipPath: "circle(0% at 15% 15%)",
          opacity: 0,
        },
        {
          clipPath: "circle(150% at 15% 15%)",
          opacity: 1,
          duration: 1,
          delay: i * 0.1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: card,
            start: "top 92%",
            toggleActions: "play reset play reset",
          },
        }
      );
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-6xl mb-20">
      <div className="trust-heading text-center mb-8">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          Your Data Is Safe
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3 flex items-center justify-center gap-3">
          <span className="material-symbols-outlined text-primary text-4xl">shield</span>
          Security you can <span className="gradient-text ml-2">actually trust.</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-2xl mx-auto">
          We know Gen Z cares about privacy. That&apos;s why we built SnapBudget with bank-level security &mdash; without ever needing your bank login.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {trustPoints.map((point) => (
          <div
            key={point.title}
            className="trust-card glass border border-white/5 rounded-2xl p-6 hover:border-white/10 hover:-translate-y-1 transition-all duration-300 group"
          >
            <div
              className="w-12 h-12 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform"
              style={{
                background: `linear-gradient(135deg, ${point.color}15, transparent)`,
                border: `1px solid ${point.color}20`,
              }}
            >
              <span className="material-symbols-outlined text-2xl" style={{ color: point.color }}>{point.icon}</span>
            </div>
            <h3 className="text-lg font-bold text-white/85 mb-2">{point.title}</h3>
            <p className="text-sm text-white/60 leading-relaxed">{point.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
