"use client";

import { motion } from "framer-motion";

const features = [
  {
    icon: "photo_camera",
    title: "Snap",
    description: "Capture receipts instantly with your camera. No more manual entry.",
    gradient: "from-[#00c9ff] to-[#0df2a6]",
    glowColor: "rgba(0, 201, 255, 0.3)",
    iconColor: "text-neon-blue",
    borderColor: "#00c9ff",
  },
  {
    icon: "folder_open",
    title: "Categorize",
    description: "AI automatically identifies and sorts your expenses into smart budgets.",
    gradient: "from-[#a855f7] to-[#ff6bcb]",
    glowColor: "rgba(168, 85, 247, 0.3)",
    iconColor: "text-neon-purple",
    borderColor: "#a855f7",
  },
  {
    icon: "savings",
    title: "Save",
    description: "Visualize your spending habits clearly and watch your savings grow.",
    gradient: "from-[#0df2a6] to-[#00c9ff]",
    glowColor: "rgba(13, 242, 166, 0.3)",
    iconColor: "text-primary",
    borderColor: "#0df2a6",
  },
];

export default function Features() {
  return (
    <section className="w-full max-w-5xl mb-20">
      <motion.div
        initial={{ y: 40, opacity: 0 }}
        whileInView={{ y: 0, opacity: 1 }}
        viewport={{ once: true, amount: 0.2 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="text-center mb-10"
      >
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          Core Features
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Three steps to <span className="gradient-text">financial clarity</span>
        </h2>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8" style={{ perspective: 1000 }}>
        {features.map((feature, i) => (
          <motion.div
            key={feature.title}
            initial={{ rotateX: -60, y: 30, opacity: 0 }}
            whileInView={{ rotateX: 0, y: 0, opacity: 1 }}
            viewport={{ once: true, amount: 0.2 }}
            transition={{ duration: 0.7, delay: i * 0.12, ease: "easeOut" }}
            style={{ transformPerspective: 800, transformOrigin: "center bottom" }}
            className="relative flex flex-col items-center text-center p-8 rounded-2xl glass border-gradient group cursor-default overflow-hidden"
          >
            {/* Neon glow background on hover */}
            <div
              className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"
              style={{ background: `radial-gradient(circle at center, ${feature.glowColor}, transparent 70%)` }}
            />

            {/* Icon with gradient bg + CSS bounce */}
            <motion.div
              whileHover={{ rotate: [0, -15, 15, -8, 0], scale: 1.15 }}
              transition={{ duration: 0.5 }}
              className={`relative z-10 mb-6 w-20 h-20 rounded-2xl flex items-center justify-center bg-linear-to-br ${feature.gradient} shadow-lg animate-icon-bounce`}
              style={{ boxShadow: `0 8px 40px ${feature.glowColor}` }}
            >
              <span className="material-symbols-outlined text-4xl text-white">
                {feature.icon}
              </span>
            </motion.div>

            <h3 className={`relative z-10 text-2xl font-extrabold mb-3 ${feature.iconColor} transition-colors duration-300`}>
              {feature.title}
            </h3>
            <p className="relative z-10 text-white/70 leading-relaxed text-sm">
              {feature.description}
            </p>

            {/* Bottom accent line */}
            <div
              className="absolute bottom-0 left-1/2 -translate-x-1/2 h-1 w-0 group-hover:w-full transition-all duration-700"
              style={{ background: `linear-gradient(90deg, transparent, ${feature.borderColor}, transparent)`, boxShadow: `0 0 15px ${feature.borderColor}` }}
            />
          </motion.div>
        ))}
      </div>
    </section>
  );
}
