"use client";

import { useState, useEffect, useRef } from "react";
import { motion, useInView } from "framer-motion";

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
  },
];

function CountUp({ value, prefix, suffix, color }: { value: number; prefix: string; suffix: string; color: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-50px" });
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    if (!isInView) {
      setDisplay(0);
      return;
    }
    const duration = 2500;
    const start = performance.now();
    let raf: number;
    const tick = (now: number) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // ease-out quad
      const eased = 1 - (1 - progress) * (1 - progress);
      setDisplay(Math.round(eased * value));
      if (progress < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [isInView, value]);

  return (
    <span ref={ref} className={`text-5xl md:text-6xl font-extrabold ${color} tabular-nums`}>
      {prefix}{display}{suffix}
    </span>
  );
}

export default function Stats() {
  return (
    <section className="w-full max-w-6xl mb-20">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, amount: 0.2 }}
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

      <div className="grid grid-cols-2 md:grid-cols-4 gap-5">
        {stats.map((stat, i) => (
          <motion.div
            key={stat.label}
            initial={{ scale: 0.3, opacity: 0 }}
            whileInView={{ scale: 1, opacity: 1 }}
            viewport={{ once: true, amount: 0.15 }}
            transition={{ type: "spring", stiffness: 180, damping: 14, delay: i * 0.08 }}
            className={`relative flex flex-col items-center text-center p-6 rounded-2xl glass border-gradient group cursor-default transition-all duration-300 hover:${stat.glow}`}
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
          </motion.div>
        ))}
      </div>
    </section>
  );
}
