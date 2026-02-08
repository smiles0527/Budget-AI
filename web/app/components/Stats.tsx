"use client";

import { useRef, useEffect, useState } from "react";
import { motion, useInView } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const stats = [
  {
    value: 72,
    suffix: "%",
    prefix: "",
    label: "of Gen Z actively improving financial health",
    source: "Bank of America",
    icon: "trending_up",
    glow: "glow-primary",
    color: "text-primary",
    flyFrom: { x: -200, y: 60, rotation: -15 },
  },
  {
    value: 53,
    suffix: "B+",
    prefix: "$",
    label: "global finance app market by 2033",
    source: "Market Research",
    icon: "show_chart",
    glow: "glow-blue",
    color: "text-neon-blue",
    flyFrom: { x: 0, y: 120, rotation: 10 },
  },
  {
    value: 18,
    suffix: "%",
    prefix: "",
    label: "annual growth rate in finance apps",
    source: "Industry CAGR",
    icon: "rocket_launch",
    glow: "glow-purple",
    color: "text-neon-purple",
    flyFrom: { x: 0, y: 120, rotation: -10 },
  },
  {
    value: 59,
    suffix: "%",
    prefix: "",
    label: "of Gen Z struggle with overspending",
    source: "Consumer Study",
    icon: "warning",
    glow: "glow-pink",
    color: "text-neon-pink",
    flyFrom: { x: 200, y: 60, rotation: 15 },
  },
];

function CountUp({ value, prefix, suffix, color }: { value: number; prefix: string; suffix: string; color: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: false, margin: "-50px" });
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    if (!isInView) {
      setDisplay(0);
      return;
    }
    const obj = { val: 0 };
    gsap.to(obj, {
      val: value,
      duration: 2.5,
      ease: "power2.out",
      onUpdate: () => setDisplay(Math.round(obj.val)),
    });
  }, [isInView, value]);

  return (
    <span ref={ref} className={`text-5xl md:text-6xl font-extrabold ${color} tabular-nums`}>
      {prefix}{display}{suffix}
    </span>
  );
}

export default function Stats() {
  const sectionRef = useRef<HTMLElement>(null);
  const cardsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!cardsRef.current) return;
    const cards = cardsRef.current.querySelectorAll(".stat-card");

    cards.forEach((card, i) => {
      // Scale-bounce from center — unique to Stats
      gsap.fromTo(
        card,
        {
          scale: 0.3,
          opacity: 0,
        },
        {
          scale: 1,
          opacity: 1,
          duration: 0.7,
          delay: i * 0.1,
          ease: "back.out(2.5)",
          scrollTrigger: {
            trigger: card,
            start: "top 85%",
            end: "top 40%",
            toggleActions: "restart none restart none",
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
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: false }}
        transition={{ duration: 0.5 }}
        className="text-center mb-10"
      >
        <span className="text-xs font-bold uppercase tracking-widest text-primary text-glow-primary">
          The Opportunity
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Gen Z needs <span className="gradient-text">better money tools</span>
        </h2>
      </motion.div>

      <div ref={cardsRef} className="grid grid-cols-2 md:grid-cols-4 gap-5">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className={`stat-card relative flex flex-col items-center text-center p-6 rounded-2xl glass border-gradient group cursor-default transition-all duration-300 hover:${stat.glow}`}
          >
            {/* Background glow on hover */}
            <div className={`absolute inset-0 rounded-2xl ${stat.glow} opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />

            <span className={`material-symbols-outlined text-3xl ${stat.color} mb-3 relative z-10`}>
              {stat.icon}
            </span>
            <div className="relative z-10 mb-3">
              <CountUp value={stat.value} prefix={stat.prefix} suffix={stat.suffix} color={stat.color} />
            </div>
            <p className="text-xs text-white/70 leading-relaxed mb-2 relative z-10">
              {stat.label}
            </p>
            <span className="text-[11px] font-bold text-white/55 uppercase tracking-wider relative z-10">
              {stat.source}
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}
