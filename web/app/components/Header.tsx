"use client";

import { useState } from "react";
import Link from "next/link";
import { motion, useMotionValueEvent, useScroll } from "framer-motion";

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, "change", (latest) => {
    setScrolled(latest > 20);
  });

  return (
    <motion.header
      initial={{ y: -80, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6, ease: "easeOut" }}
      className={`w-full px-6 md:px-12 flex items-center justify-between z-50 sticky top-0 transition-all duration-500 ${
        scrolled
          ? "py-3 md:py-4 glass-strong shadow-lg shadow-primary/5"
          : "py-4 md:py-6 bg-transparent"
      }`}
    >
      <div className="flex items-center gap-3">
        <motion.div
          whileHover={{ rotate: [0, -15, 15, -10, 0], scale: 1.2 }}
          transition={{ duration: 0.5 }}
          className="text-primary text-glow-primary"
        >
          <span className="material-symbols-outlined text-3xl">account_balance_wallet</span>
        </motion.div>
        <h1 className="text-lg md:text-xl font-bold tracking-tight">
          <span className="gradient-text">SnapBudget</span>
          <span className="font-normal text-white/60 ml-1.5 hidden sm:inline">
            Smart Expense Tracking
          </span>
        </h1>
      </div>
      <div className="flex items-center gap-3">
        <motion.div whileHover={{ scale: 1.08, y: -2 }} whileTap={{ scale: 0.95 }}>
          <Link
            href="/showcase"
            className="inline-flex items-center gap-2 px-4 py-2.5 glass text-white/80 rounded-full font-medium text-sm border border-white/10 hover:border-neon-purple/30 hover:text-neon-purple transition-all duration-300"
          >
            <span className="material-symbols-outlined text-[18px]">phone_iphone</span>
            <span className="hidden sm:inline">Showcase</span>
          </Link>
        </motion.div>
        <motion.div whileHover={{ scale: 1.08, y: -2 }} whileTap={{ scale: 0.95 }}>
          <Link
            href="#slideshow"
            className="inline-flex items-center gap-2 px-4 py-2.5 glass text-white/80 rounded-full font-medium text-sm border border-white/10 hover:border-primary/30 hover:text-primary transition-all duration-300"
          >
            <span className="material-symbols-outlined text-[18px]">slideshow</span>
            <span className="hidden sm:inline">Slideshow</span>
          </Link>
        </motion.div>
        <motion.div whileHover={{ scale: 1.08, y: -2 }} whileTap={{ scale: 0.95 }}>
          <Link
            href="#"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-black rounded-full font-bold text-sm glow-primary hover:glow-primary-strong transition-all duration-300"
          >
            <span className="material-symbols-outlined text-[20px]">download</span>
            <span className="hidden sm:inline">Download App</span>
            <span className="sm:hidden">Get App</span>
          </Link>
        </motion.div>
      </div>
    </motion.header>
  );
}
