"use client";

import { motion } from "framer-motion";

const features = [
  {
    icon: "photo_camera",
    title: "Snap",
    description: "Capture receipts instantly with your camera. No more manual entry.",
  },
  {
    icon: "folder_open",
    title: "Categorize",
    description: "AI automatically identifies and sorts your expenses into smart budgets.",
  },
  {
    icon: "savings",
    title: "Save",
    description: "Visualize your spending habits clearly and watch your savings grow.",
  },
];

export default function Features() {
  return (
    <section className="w-full max-w-4xl grid grid-cols-1 md:grid-cols-3 gap-12 md:gap-8 mb-20">
      {features.map((feature, index) => (
        <motion.div
          key={feature.title}
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 + index * 0.1 }}
          className="flex flex-col items-center text-center group"
        >
          <div className="mb-6 p-4 rounded-full bg-primary/10 dark:bg-primary/5 text-primary group-hover:bg-primary group-hover:text-white transition-all duration-300">
            <span className="material-symbols-outlined text-4xl">{feature.icon}</span>
          </div>
          <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
          <p className="text-text-muted dark:text-text-muted-dark leading-relaxed">
            {feature.description}
          </p>
        </motion.div>
      ))}
    </section>
  );
}
