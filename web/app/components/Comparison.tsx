"use client";

import { motion } from "framer-motion";

interface Competitor {
  name: string;
  audience: string;
  pros: string[];
  cons: string[];
  icon: string;
}
const competitors: Competitor[] = [
  {
    name: "Mint / YNAB",
    audience: "Adults 30+",
    icon: "account_balance",
    pros: ["Full bank sync", "Detailed reports"],
    cons: ["Overwhelming UI", "Requires bank login", "Not built for Gen Z"],
  },
  {
    name: "Greenlight / BusyKid",
    audience: "Kids & families",
    icon: "child_care",
    pros: ["Parental controls", "Kid-friendly design"],
    cons: ["Feels patronizing for teens", "Family-focused, not independent", "No receipt scanning"],
  },
  {
    name: "Spreadsheets",
    audience: "DIY budgeters",
    icon: "grid_on",
    pros: ["Fully customizable", "Free"],
    cons: ["Manual data entry", "Zero fun factor", "No insights or automation"],
  },
];

const snapFeatures = [
  { label: "No bank login required", icon: "lock_open" },
  { label: "AI receipt scanning", icon: "photo_camera" },
  { label: "Gamified with badges", icon: "emoji_events" },
  { label: "Built for ages 15–25", icon: "bolt" },
  { label: "Privacy-first design", icon: "shield" },
  { label: "Fun, not boring", icon: "sports_esports" },
];

export default function Comparison() {
  return (
    <section className="w-full max-w-6xl mb-20">
      <motion.div
        initial={{ y: 60, opacity: 0 }}
        whileInView={{ y: 0, opacity: 1 }}
        viewport={{ once: false, amount: 0.3 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="text-center mb-10"
      >
        <span className="text-xs font-bold uppercase tracking-widest text-neon-purple text-glow-purple">
          Why Us?
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          The competition <span className="gradient-text">isn&apos;t competing.</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-2xl mx-auto">
          Other tools were built for different people. SnapBudget was built for <span className="text-white/80 font-semibold">you</span>.
        </p>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Left: Competitor cards */}
        <div className="space-y-4">
          {competitors.map((comp, i) => (
            <motion.div
              key={comp.name}
              initial={{ clipPath: "inset(0 100% 0 0)", opacity: 0 }}
              whileInView={{ clipPath: "inset(0 0% 0 0)", opacity: 1 }}
              viewport={{ once: false, amount: 0.3 }}
              transition={{ duration: 0.7, delay: i * 0.1, ease: "easeOut" }}
              className="glass border border-white/5 rounded-2xl p-6 hover:border-neon-pink/20 transition-colors duration-300"
            >
              <div className="flex items-center gap-3 mb-4">
                <span className="material-symbols-outlined text-3xl text-white/60">{comp.icon}</span>
                <div>
                  <h3 className="text-lg font-bold text-white/80">{comp.name}</h3>
                  <p className="text-xs text-white/50">Target: {comp.audience}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-xs text-white/60 uppercase tracking-wider font-bold mb-2">Pros</p>
                  {comp.pros.map((p) => (
                    <div key={p} className="flex items-start gap-1.5 mb-1.5">
                      <span className="text-primary text-xs mt-0.5">+</span>
                      <span className="text-xs text-white/70">{p}</span>
                    </div>
                  ))}
                </div>
                <div>
                  <p className="text-xs text-white/60 uppercase tracking-wider font-bold mb-2">Cons</p>
                  {comp.cons.map((c) => (
                    <div key={c} className="flex items-start gap-1.5 mb-1.5">
                      <span className="text-neon-pink text-xs mt-0.5">−</span>
                      <span className="text-xs text-white/60">{c}</span>
                    </div>
                  ))}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Right: SnapBudget card */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0, filter: "blur(8px)" }}
          whileInView={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className="glass-strong border-gradient glow-primary rounded-2xl p-8 flex flex-col justify-center relative overflow-hidden"
        >
          {/* Background glow */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#0df2a6]/8 to-[#00c9ff]/5 pointer-events-none" />

          <div className="relative z-10">
            <div className="flex items-center gap-3 mb-2">
              <span className="material-symbols-outlined text-4xl text-primary">photo_camera</span>
              <div>
                <h3 className="text-2xl font-extrabold gradient-text-fast">SnapBudget</h3>
                <p className="text-xs text-primary/60">Target: Gen Z &amp; Young Adults</p>
              </div>
            </div>

            <p className="text-white/70 text-sm mb-6">
              The only budgeting app designed from scratch for young, independent users. No bank logins. No complexity. Just snap, track, and grow.
            </p>

            <div className="grid grid-cols-2 gap-3">
              {snapFeatures.map((f) => (
                <div
                  key={f.label}
                  className="flex items-center gap-2 glass rounded-xl px-3 py-2.5 border border-primary/10 hover:border-primary/30 transition-colors duration-300"
                >
                  <span className="material-symbols-outlined text-primary text-[18px]">{f.icon}</span>
                  <span className="text-xs text-white/80 font-medium">{f.label}</span>
                </div>
              ))}
            </div>

            <div className="mt-6 flex items-center gap-2 text-primary text-sm font-bold">
              <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
              This is the app that should&apos;ve existed years ago.
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
