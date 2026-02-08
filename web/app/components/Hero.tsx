"use client";

import { motion } from "framer-motion";

export default function Hero() {
  return (
    <section className="w-full flex flex-col items-center text-center mt-12 md:mt-16 mb-8">
      <motion.h2
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="text-3xl md:text-5xl font-extrabold tracking-tight mb-4 leading-tight"
      >
        Meet <span className="text-primary">SnapBudget</span>
      </motion.h2>
      <motion.p
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="text-base md:text-lg text-text-muted dark:text-text-muted-dark max-w-2xl leading-relaxed"
      >
        The effortless way to track expenses. Snap a photo, let AI do the rest.
      </motion.p>
    </section>
  );
}
