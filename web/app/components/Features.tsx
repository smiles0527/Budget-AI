"use client";

import { useRef, useEffect } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const features = [
  {
    icon: "photo_camera",
    title: "Snap",
    description: "Capture receipts instantly with your camera. No more manual entry.",
    gradient: "from-[#00c9ff] to-[#0df2a6]",
    glowColor: "rgba(0, 201, 255, 0.3)",
    iconColor: "text-neon-blue",
    borderColor: "#00c9ff",
    flyFrom: { x: -300, rotation: -20 },
  },
  {
    icon: "folder_open",
    title: "Categorize",
    description: "AI automatically identifies and sorts your expenses into smart budgets.",
    gradient: "from-[#a855f7] to-[#ff6bcb]",
    glowColor: "rgba(168, 85, 247, 0.3)",
    iconColor: "text-neon-purple",
    borderColor: "#a855f7",
    flyFrom: { x: 0, rotation: 0 },
  },
  {
    icon: "savings",
    title: "Save",
    description: "Visualize your spending habits clearly and watch your savings grow.",
    gradient: "from-[#0df2a6] to-[#00c9ff]",
    glowColor: "rgba(13, 242, 166, 0.3)",
    iconColor: "text-primary",
    borderColor: "#0df2a6",
    flyFrom: { x: 300, rotation: 20 },
  },
];

export default function Features() {
  const cardsRef = useRef<HTMLDivElement>(null);
  const headingRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!cardsRef.current) return;
    const cards = cardsRef.current.querySelectorAll(".feature-card");

    cards.forEach((card, i) => {
      // 3D flip reveal — cards rotate in from face-down
      gsap.fromTo(
        card,
        {
          rotateX: -90,
          y: 30,
          opacity: 0,
          transformPerspective: 800,
          transformOrigin: "center bottom",
        },
        {
          rotateX: 0,
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: card,
            start: "top 90%",
            end: "top 50%",
            scrub: 1,
          },
        }
      );

      // Icon continuous bounce
      const icon = card.querySelector(".feature-icon");
      if (icon) {
        gsap.to(icon, {
          y: -8,
          duration: 1.5,
          repeat: -1,
          yoyo: true,
          ease: "sine.inOut",
        });
      }
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  // Parallax heading
  useEffect(() => {
    if (!headingRef.current) return;
    gsap.fromTo(
      headingRef.current,
      { y: 40, opacity: 0 },
      {
        y: 0,
        opacity: 1,
        duration: 0.8,
        scrollTrigger: {
          trigger: headingRef.current,
          start: "top 85%",
          end: "+=300",
          scrub: 1,
        },
      }
    );
    return () => { ScrollTrigger.getAll().forEach((t) => t.kill()); };
  }, []);

  return (
    <section className="w-full max-w-5xl mb-20">
      <div ref={headingRef} className="text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          Core Features
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Three steps to <span className="gradient-text">financial clarity</span>
        </h2>
      </div>

      <div ref={cardsRef} className="grid grid-cols-1 md:grid-cols-3 gap-8" style={{ perspective: 1000 }}>
        {features.map((feature) => (
          <div
            key={feature.title}
            className="feature-card relative flex flex-col items-center text-center p-8 rounded-2xl glass border-gradient group cursor-default overflow-hidden"
          >
            {/* Neon glow background on hover */}
            <div
              className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl"
              style={{ background: `radial-gradient(circle at center, ${feature.glowColor}, transparent 70%)` }}
            />

            {/* Icon with gradient bg */}
            <motion.div
              whileHover={{ rotate: [0, -15, 15, -8, 0], scale: 1.15 }}
              transition={{ duration: 0.5 }}
              className={`feature-icon relative z-10 mb-6 w-20 h-20 rounded-2xl flex items-center justify-center bg-linear-to-br ${feature.gradient} shadow-lg`}
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
          </div>
        ))}
      </div>
    </section>
  );
}
