"use client";

import { motion } from "framer-motion";

export default function CTA() {
  return (
    <section className="w-full max-w-5xl mb-20" style={{ perspective: 1400 }}>
      <motion.div
        initial={{ scale: 0.7, opacity: 0, filter: "blur(10px)" }}
        whileInView={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
        viewport={{ once: false, amount: 0.3 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="relative overflow-hidden rounded-3xl p-10 md:p-16 text-center"
        style={{ background: "linear-gradient(135deg, rgba(13,242,166,0.15) 0%, rgba(0,201,255,0.1) 50%, rgba(168,85,247,0.15) 100%)", border: "1px solid rgba(13,242,166,0.2)" }}
      >
        {/* Animated floating orbs — CSS animations */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-6 left-10 w-48 h-48 rounded-full opacity-25 animate-float-1" style={{ background: "radial-gradient(circle, #0df2a6, transparent)" }} />
          <div className="absolute bottom-8 right-12 w-64 h-64 rounded-full opacity-20 animate-float-2" style={{ background: "radial-gradient(circle, #00c9ff, transparent)" }} />
          <div className="absolute top-1/2 left-1/3 w-36 h-36 rounded-full opacity-25 animate-float-3" style={{ background: "radial-gradient(circle, #a855f7, transparent)" }} />
          <div className="absolute top-1/4 right-1/4 w-28 h-28 rounded-full opacity-30 animate-float-1" style={{ background: "radial-gradient(circle, #ff6bcb, transparent)", animationDelay: "1s" }} />
          <div className="absolute bottom-1/3 left-[16%] w-40 h-40 rounded-full opacity-20 animate-float-2" style={{ background: "radial-gradient(circle, #0df2a6, transparent)", animationDelay: "0.5s" }} />
          <div className="absolute top-10 right-1/3 w-24 h-24 rounded-full opacity-25 animate-float-3" style={{ background: "radial-gradient(circle, #00c9ff, transparent)", animationDelay: "1.5s" }} />
        </div>

        <div className="relative z-10">
          <motion.span
            initial={{ y: -20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            viewport={{ once: false, amount: 0.5 }}
            transition={{ duration: 0.5, delay: 0.15 }}
            className="inline-flex items-center gap-2 glass text-primary text-xs font-bold px-6 py-2.5 rounded-full mb-8"
          >
            <span className="material-symbols-outlined text-[16px]">rocket_launch</span>
            Built for Gen Z & Young Professionals
          </motion.span>

          <motion.h2
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            viewport={{ once: false, amount: 0.5 }}
            transition={{ duration: 0.5, delay: 0.25 }}
            className="text-4xl md:text-6xl font-extrabold mb-5 leading-tight"
          >
            <span className="gradient-text-fast neon-flicker">Take control</span> of your money.
            <br />
            Start snapping today.
          </motion.h2>

          <motion.p
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            viewport={{ once: false, amount: 0.5 }}
            transition={{ duration: 0.5, delay: 0.35 }}
            className="text-white/70 max-w-xl mx-auto mb-10 leading-relaxed text-lg"
          >
            Join the movement of young people who are finally making budgeting simple, visual, and actually fun. No bank logins. No spreadsheets. Just you and your receipts.
          </motion.p>

          <motion.div
            initial={{ y: 20, opacity: 0, scale: 0.95 }}
            whileInView={{ y: 0, opacity: 1, scale: 1 }}
            viewport={{ once: false, amount: 0.5 }}
            transition={{ type: "spring", stiffness: 200, damping: 18, delay: 0.45 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-5"
          >
            <motion.button
              whileHover={{ scale: 1.08, y: -4 }}
              whileTap={{ scale: 0.95 }}
              className="bg-linear-to-r from-[#0df2a6] to-[#00c9ff] text-black font-bold py-5 px-12 rounded-xl flex items-center gap-2.5 cursor-pointer text-lg"
              style={{ boxShadow: "0 0 30px rgba(13,242,166,0.4), 0 0 60px rgba(13,242,166,0.15)" }}
            >
              <span className="material-symbols-outlined text-[22px]">download</span>
              Download for iOS
            </motion.button>
            <motion.button
              whileHover={{ scale: 1.08, y: -4 }}
              whileTap={{ scale: 0.95 }}
              className="glass text-white font-semibold py-5 px-12 rounded-xl border border-white/10 hover:border-primary/40 transition-colors cursor-pointer text-lg"
            >
              Learn More
            </motion.button>
          </motion.div>

          <motion.p
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: false, amount: 0.5 }}
            transition={{ duration: 0.4, delay: 0.6 }}
            className="text-white/60 text-sm mt-10"
          >
            Free to start. No credit card required.
          </motion.p>
        </div>
      </motion.div>
    </section>
  );
}
