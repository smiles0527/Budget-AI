"use client";

import { useRef, useEffect } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const audiences = [
  {
    icon: "school",
    title: "Universities & Colleges",
    description:
      "Integrate SnapBudget into financial literacy programs. Students learn real budgeting with real receipts — not hypotheticals.",
    features: ["Per-student licensing", "Admin dashboards", "Custom challenges"],
    color: "#0df2a6",
  },
  {
    icon: "family_restroom",
    title: "Parents & Families",
    description:
      "Give your teen the tools to manage their own money. No joint bank accounts needed — just a camera and a goal.",
    features: ["Safe & private", "No bank login", "Visible progress (badges)"],
    color: "#00c9ff",
  },
  {
    icon: "volunteer_activism",
    title: "Nonprofits & Programs",
    description:
      "Running a financial literacy workshop? SnapBudget fits right in. Track participant progress and engagement at scale.",
    features: ["Bulk licensing", "Engagement metrics", "Program integration"],
    color: "#a855f7",
  },
];

export default function ForSchools() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const heading = section.querySelector(".schools-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { y: 60, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            toggleActions: "restart none restart none",
          },
        }
      );
    }

    const cards = section.querySelectorAll(".school-card");
    cards.forEach((card, i) => {
      // Elastic spring from below
      gsap.fromTo(
        card,
        { y: 60, opacity: 0, scale: 0.9 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 1.2,
          delay: i * 0.15,
          ease: "elastic.out(1, 0.6)",
          scrollTrigger: {
            trigger: card,
            start: "top 90%",
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
      <div className="schools-heading text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-purple text-glow-purple">
          Beyond Consumers
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Built for learners.{" "}
          <span className="gradient-text">Trusted by educators.</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-2xl mx-auto">
          SnapBudget isn&apos;t just a consumer app. Schools, parents, and nonprofits use it to teach real financial skills.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {audiences.map((a) => (
          <div
            key={a.title}
            className="school-card glass border border-white/5 rounded-2xl p-7 flex flex-col hover:border-white/10 hover:-translate-y-2 transition-all duration-300 group"
          >
            <div
              className="w-14 h-14 rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform"
              style={{
                background: `linear-gradient(135deg, ${a.color}15, transparent)`,
                border: `1px solid ${a.color}25`,
              }}
            >
              <span className="material-symbols-outlined text-2xl" style={{ color: a.color }}>{a.icon}</span>
            </div>

            <h3 className="text-xl font-bold text-white/90 mb-2">{a.title}</h3>
            <p className="text-sm text-white/60 leading-relaxed mb-5 grow">
              {a.description}
            </p>

            <ul className="space-y-2">
              {a.features.map((f) => (
                <li key={f} className="flex items-center gap-2 text-sm">
                  <span
                    className="material-symbols-outlined text-[16px]"
                    style={{ color: a.color, textShadow: `0 0 8px ${a.color}50` }}
                  >
                    check_circle
                  </span>
                  <span className="text-white/75">{f}</span>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      {/* CTA for institutions */}
      <div className="mt-10 text-center">
        <motion.button
          whileHover={{ scale: 1.05, y: -3 }}
          whileTap={{ scale: 0.95 }}
          className="glass border border-primary/20 text-primary font-bold py-3.5 px-8 rounded-xl cursor-pointer hover:bg-primary/5 transition-colors"
        >
          <span className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">mail</span>
            Contact Us for Licensing
          </span>
        </motion.button>
      </div>
    </section>
  );
}
